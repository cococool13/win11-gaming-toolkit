<#
.SYNOPSIS
    Read-only audit of Message-Signaled Interrupts (MSI) mode for
    every present GPU, network adapter, and NVMe storage controller.

.DESCRIPTION
    MSI-X / MSI lets a device deliver interrupts via posted writes to
    the CPU's local APIC instead of legacy line-based IRQs. The
    practical wins for latency-sensitive systems:
      - Lower interrupt-service latency (no IRQ-sharing arbitration)
      - Better DPC distribution across cores (vs single-CPU line IRQ)
      - Less contention on shared interrupt lines

    Every modern PCIe device supports MSI; whether Windows USES MSI
    is controlled per-device by the registry value:
        HKLM\SYSTEM\CurrentControlSet\Enum\<InstanceId>\
          Device Parameters\Interrupt Management\
          MessageSignaledInterruptProperties\MSISupported
        0 = line-based interrupts (fallback)
        1 = MSI mode preferred (the usual factory default for modern HW)

    This script ENUMERATES the current state — pure read, no writes.
    Use it to:
      - Confirm a fresh install has MSI on for every expected device
      - Spot a driver update that silently reverted MSI to line mode
      - Establish a baseline before opting in to enable-msi-mode.ps1
        (which exists for the GPU class)

    Audit-first design: the toolkit's mutator for MSI mode (the existing
    6 gpu/enable-msi-mode.ps1 pair) is opt-in by device class. A
    bulk-mutate utility for NICs and NVMe is a separate piece of work
    behind a system-restore-point gate; this is the prerequisite read.

    Output: grouped by class (GPU → Net → NVMe), each row showing
    FriendlyName / InstanceId / VID:DEV / MSI state / Notes.

    -AsObject emits [PSCustomObject] records for pipeline use:
        check-msi-mode -AsObject | Where-Object MsiMode -EQ 'Line'

.PARAMETER AsObject
    Pipeline output mode. Emits records with Category, FriendlyName,
    InstanceId, Vid, Did, MsiMode, RawValue, Notes.

.NOTES
    Tier: Safe (read-only)
    Anti-cheat impact: NONE. Pure PnP / registry enumeration; no kernel
        hooks, no device state change, no scheduler change. BattlEye /
        EAC don't inspect MSI configuration registry values.
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/introduction-to-message-signaled-interrupts
      https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/enabling-message-signaled-interrupts-in-the-registry

    # CROSS-PLATFORM-NOTE
    # Windows-only (Get-PnpDevice + HKLM:\ paths). Returns @() on
    # non-Windows so callers can foreach without a $null guard.
#>
[CmdletBinding()]
param(
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'MSI Mode Audit' -Subtitle 'Read-only per-device interrupt mode'
    UI-Note -Message '[SKIP] Get-PnpDevice unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

# Class-name mapping. SCSIAdapter is the class for NVMe + SATA AHCI;
# we filter the friendly name later to keep only NVMe rows. Net is
# the broad NIC class (USB NICs, virtual adapters, etc. all included
# so the user sees the full picture even if some don't matter for
# their workload).
$classes = @(
    @{ Category = 'GPU'; PnpClass = 'Display' }
    @{ Category = 'Net'; PnpClass = 'Net' }
    @{ Category = 'NVMe'; PnpClass = 'SCSIAdapter'; FriendlyNameMatch = 'NVMe|NVM Express' }
)

function Get-MsiModeForDevice {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][object]$Device)

    $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Device.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    $val = (Get-ItemProperty -Path $msiPath -Name 'MSISupported' -ErrorAction SilentlyContinue).MSISupported

    $mode = if ($null -eq $val) {
        'Default'  # Key absent = driver default applies
    } elseif ($val -eq 1) {
        'MSI'
    } elseif ($val -eq 0) {
        'Line'
    } else {
        "Unknown($val)"
    }

    $notes = switch ($mode) {
        'MSI' { 'OK — MSI mode preferred (typical for modern PCIe devices).' }
        'Line' { 'WARN — line-based IRQs. Higher latency potential; consider MSI.' }
        'Default' { 'No registry override — driver default applies (usually MSI on modern HW).' }
        default { 'Unexpected MSISupported value — verify with regedit.' }
    }

    return @{
        Mode = $mode
        Raw = $val
        Notes = $notes
    }
}

function Get-DevicePciIds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$InstanceId)

    # NOTE: $devVid / $devDid — NOT $vid / $did / $pid. $pid would
    # shadow the PowerShell automatic variable per CLAUDE.md gotcha.
    $devVid = ''
    $devDid = ''
    if ($InstanceId -match 'VEN_([0-9A-Fa-f]{4})') { $devVid = $matches[1].ToUpper() }
    if ($InstanceId -match 'DEV_([0-9A-Fa-f]{4})') { $devDid = $matches[1].ToUpper() }
    return @{ Vid = $devVid; Did = $devDid }
}

$records = @()
foreach ($cls in $classes) {
    $devices = @(Get-PnpDevice -PresentOnly -Class $cls.PnpClass -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq 'OK' })
    if ($cls.FriendlyNameMatch) {
        $devices = @($devices | Where-Object { $_.FriendlyName -match $cls.FriendlyNameMatch })
    }
    foreach ($d in $devices) {
        $msi = Get-MsiModeForDevice -Device $d
        $ids = Get-DevicePciIds -InstanceId $d.InstanceId
        $records += [PSCustomObject]@{
            Category = $cls.Category
            FriendlyName = $d.FriendlyName
            InstanceId = $d.InstanceId
            Vid = $ids.Vid
            Did = $ids.Did
            MsiMode = $msi.Mode
            RawValue = $msi.Raw
            Notes = $msi.Notes
        }
    }
}

if ($AsObject) {
    return $records
}

UI-Header -Title 'MSI Mode Audit' -Subtitle 'Read-only per-device interrupt mode'

if ($records.Count -eq 0) {
    UI-Note -Message 'No present devices matched (GPU / Net / NVMe).' -Color $script:UI_Warning
    return
}

UI-KeyValue -Label 'Devices' -Value "$($records.Count) audited"
Write-Host ''

foreach ($category in @('GPU', 'Net', 'NVMe')) {
    $subset = @($records | Where-Object Category -EQ $category)
    if ($subset.Count -eq 0) { continue }
    Write-Host "  $($category):" -ForegroundColor Cyan
    foreach ($r in $subset) {
        Write-Host "    - $($r.FriendlyName)" -ForegroundColor White
        Write-Host "        VID/DEV: $($r.Vid)/$($r.Did)" -ForegroundColor Gray
        $color = switch ($r.MsiMode) {
            'MSI' { $script:UI_Success }
            'Line' { $script:UI_Warning }
            'Default' { $script:UI_Info }
            default { $script:UI_Error }
        }
        Write-Host "        MSI mode: $($r.MsiMode)" -ForegroundColor $color
        Write-Host "        $($r.Notes)" -ForegroundColor DarkGray
    }
    Write-Host ''
}

Write-Host '  Read-only audit. To CHANGE MSI mode for a device class,' -ForegroundColor DarkGray
Write-Host '  use 6 gpu/enable-msi-mode.ps1 (GPU) — bulk-mutate utility' -ForegroundColor DarkGray
Write-Host '  for Net + NVMe is queued behind a System-Restore-point gate.' -ForegroundColor DarkGray
Write-Host ''
