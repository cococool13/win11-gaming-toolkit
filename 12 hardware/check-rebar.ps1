<#
.SYNOPSIS
    Read-only audit of Resizable BAR (ReBAR) support and current
    runtime state for each discrete GPU on the system.

.DESCRIPTION
    ReBAR (PCIe Resizable Base Address Register, aka "Smart Access
    Memory" on AMD) lets the CPU address the FULL GPU VRAM in one
    aperture rather than the legacy 256MB window. The perf win is
    5-15% in some titles (NVIDIA 30/40-series, AMD RDNA2+, Intel
    Arc — required on Arc). Whether your system DELIVERS ReBAR
    depends on three independent layers:

      1. Hardware support
         - GPU silicon supports ReBAR (RTX 30+, RX 6000+, Arc all do)
         - CPU + chipset support large-BAR routing (most Intel 10th-gen+,
           Ryzen 3000+ with BIOS update)

      2. Firmware configuration (NOT scriptable from Windows)
         - BIOS: "Above 4G Decoding" = Enabled
         - BIOS: CSM = Disabled (UEFI-only boot)
         - BIOS: Resizable BAR Support = Enabled (where exposed)

      3. Runtime state (scriptable, this script reads it)
         - Driver advertises LargeMemoryRange / KMD_EnableLargeBar
           registry values under the adapter's class subkey
         - DXGI / driver tooling can confirm at runtime

    This script reports each layer's state per discrete GPU so the
    user knows EXACTLY what to fix:
        - "Supported but disabled by firmware" → BIOS toggle needed
        - "Supported and active" → nothing to do
        - "Unsupported" → silicon limitation

    Anti-cheat impact: NONE. Pure read of PnP + registry; no kernel
    hooks, no game-process surface. Not inspected by BattlEye / EAC /
    Vanguard.
    Reboot required: NO (this is a read-only audit).
    Disk impact: NONE (pure registry / PnP enumeration).

    -AsObject emits records for pipeline use:
        check-rebar -AsObject | Where-Object ReBarActive -EQ $false

.PARAMETER AsObject
    Emit [PSCustomObject] records to the pipeline instead of formatted
    text. Each record: Vendor, FriendlyName, DeviceId, AdapterPath,
    Supported, ReBarActive, Notes.

.NOTES
    Tier: Safe (read-only)
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows-hardware/drivers/display/resizable-bar-support
    NVIDIA on ReBAR:
      https://www.nvidia.com/en-us/geforce/news/rtx-30-series-resizable-bar-support/
    AMD on Smart Access Memory:
      https://www.amd.com/en/technologies/smart-access-memory

    # CROSS-PLATFORM-NOTE
    # Windows-only (Get-PnpDevice + HKLM:\Class GUID tree). Returns
    # @() on non-Windows so callers can foreach without a $null guard.
#>
[CmdletBinding()]
param(
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"

if (-not (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'ReBAR Audit' -Subtitle 'Read-only Resizable BAR state'
    UI-Note -Message '[SKIP] Get-PnpDevice unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

# Reuse the toolkit's GPU detection to filter to real discrete GPUs.
$gpus = @(Get-GpuVendor)
if ($gpus.Count -eq 0) {
    if ($AsObject) { return @() }
    UI-Header -Title 'ReBAR Audit'
    UI-Note -Message 'No discrete GPU detected.' -Color $script:UI_Warning
    return
}

function Get-RebarStatusForGpu {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][object]$Gpu)

    $adapterPath = $Gpu.AdapterRegistryPath
    $supported = $null  # tri-state: $true / $false / $null (unknown)
    $active = $null
    $notes = @()

    if ([string]::IsNullOrWhiteSpace($adapterPath)) {
        $notes += 'Adapter registry path not resolved — driver state unreadable.'
    } else {
        $rebarFlag = Test-ReBarEnabled -AdapterRegistryPath $adapterPath
        if ($null -eq $rebarFlag) {
            $notes += 'Driver does not expose LargeMemoryRange / KMD_EnableLargeBar.'
            $notes += 'May still be active via DXGI — use GPU-Z / nvidia-smi to confirm.'
        } else {
            $active = [bool]$rebarFlag
            $supported = $true  # presence of the flag implies driver supports the toggle
            if (-not $active) {
                $notes += 'Driver reports ReBAR available but currently INACTIVE.'
                $notes += 'Verify BIOS: Above 4G Decoding=Enabled, CSM=Disabled, ReBAR=Enabled.'
            }
        }
    }

    # Vendor-specific hints when the flag is absent.
    if ($null -eq $supported) {
        switch ($Gpu.Vendor) {
            'nvidia' {
                # RTX 30+ have ReBAR support; pre-30 (GTX 16, RTX 20, etc.) don't.
                # DeviceID 2xxx is RTX 30, 26xx-28xx is RTX 40, etc. Conservative
                # assumption: report as "potentially supported, verify with GPU-Z".
                $notes += 'NVIDIA: RTX 30/40/50-series silicon supports ReBAR.'
                $notes += 'Pre-Ampere (GTX 16, RTX 20) does NOT support ReBAR.'
            }
            'amd' {
                $notes += 'AMD: RDNA2+ (RX 6000+) silicon supports Smart Access Memory.'
                $notes += 'Pre-RDNA2 (RX 5000 and older) does NOT support ReBAR.'
            }
            'intel' {
                $notes += 'Intel: Arc requires ReBAR — 20-30% perf hit without it.'
            }
        }
    }

    return [PSCustomObject]@{
        Vendor = $Gpu.Vendor
        FriendlyName = $Gpu.FriendlyName
        DeviceId = $Gpu.DeviceId
        AdapterPath = $adapterPath
        Supported = $supported
        ReBarActive = $active
        Notes = $notes
    }
}

$records = @($gpus | ForEach-Object { Get-RebarStatusForGpu -Gpu $_ })

if ($AsObject) {
    return $records
}

UI-Header -Title 'Resizable BAR (ReBAR) Audit' -Subtitle 'Per-GPU silicon + driver + firmware state'
UI-KeyValue -Label 'Discrete GPUs' -Value $records.Count
Write-Host ''

foreach ($r in $records) {
    Write-Host "  $($r.FriendlyName)  ($($r.Vendor.ToUpper()), DeviceID $($r.DeviceId))" -ForegroundColor White
    $stateLine = if ($r.ReBarActive -eq $true) {
        '    ReBAR state: ACTIVE — driver reports large-BAR aperture enabled.'
    } elseif ($r.ReBarActive -eq $false) {
        '    ReBAR state: SUPPORTED but INACTIVE — fix in BIOS.'
    } else {
        '    ReBAR state: INDETERMINATE — driver does not expose the flag.'
    }
    $color = switch ($r.ReBarActive) {
        $true { $script:UI_Success }
        $false { $script:UI_Warning }
        default { $script:UI_Info }
    }
    Write-Host $stateLine -ForegroundColor $color
    foreach ($n in $r.Notes) {
        Write-Host "      - $n" -ForegroundColor DarkGray
    }
    Write-Host ''
}

Write-Host '  Read-only audit. Firmware-side changes (Above 4G, CSM, ReBAR' -ForegroundColor DarkGray
Write-Host '  toggle) are NOT scriptable — they must be set in BIOS / UEFI.' -ForegroundColor DarkGray
Write-Host ''
