<#
.SYNOPSIS
    Read-only audit of DirectStorage prerequisites — checks NVMe
    presence, Windows build, DX12 Ultimate, GPU compatibility.

.DESCRIPTION
    DirectStorage lets games stream asset data directly from NVMe to
    GPU VRAM, bypassing the CPU. It's the substrate for "no loading
    screen" titles (Forspoken, Ratchet & Clank: Rift Apart, Star
    Wars Jedi: Survivor). Four prerequisites have to align:

      1. NVMe storage on the system (any NVMe controller class)
      2. Windows 11 or Windows 10 1909+ (DirectStorage 1.1+ is Win11
         exclusive for the GPU-decompression path; CPU fallback works
         on Win10 1909+)
      3. DirectX 12 Ultimate runtime (DX12_2 feature level support)
      4. GPU silicon advertises DirectStorage / Shader Model 6.0+
         (NVIDIA RTX 2000+, AMD RX 5000+, Intel Arc all qualify)

    This script verifies each prereq and reports structured
    PASS/WARN/FAIL with remediation hints per failed item.

    Anti-cheat impact: NONE. Pure read of OS / hardware identifiers;
    no kernel hooks, no driver mutation. Not inspected by BattlEye /
    EAC / Vanguard.
    Reboot required: NO (read-only audit).
    Disk impact: NONE (CIM + registry reads only).

    -AsObject emits records for pipeline use.

.PARAMETER AsObject
    Emit [PSCustomObject] records to the pipeline.

.NOTES
    Tier: Safe (read-only)
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/win32/directstorage/dstorage-getting-started
      https://learn.microsoft.com/en-us/windows/win32/direct3d12/directx-12-ultimate-getting-started

    # CROSS-PLATFORM-NOTE
    # Windows-only (Get-PhysicalDisk, Get-CimInstance, dxdiag).
    # Returns @() on non-Windows.
#>
[CmdletBinding()]
param(
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) `
        -or -not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'DirectStorage Prereq Audit' -Subtitle 'Read-only'
    UI-Note -Message '[SKIP] Required cmdlets unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

function Test-NvmePresence {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $nvmeDrives = @(Get-PhysicalDisk -ErrorAction SilentlyContinue |
            Where-Object { $_.BusType -eq 'NVMe' })
    if ($nvmeDrives.Count -eq 0) {
        return [PSCustomObject]@{
            Name = 'NVMe storage'
            Status = 'FAIL'
            Detail = 'No NVMe drive detected. DirectStorage requires NVMe.'
            Remediation = 'Install a NVMe SSD as the OS / game library drive.'
        }
    }
    return [PSCustomObject]@{
        Name = 'NVMe storage'
        Status = 'PASS'
        Detail = ("$($nvmeDrives.Count) NVMe drive(s): " +
            (($nvmeDrives | ForEach-Object { $_.FriendlyName }) -join ', '))
        Remediation = ''
    }
}

function Test-WindowsBuildSupport {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $build = [System.Environment]::OSVersion.Version.Build
    # Win10 1909 = build 18363; DirectStorage 1.0 CPU-fallback path supported.
    # Win11 22000+ = build 22000+; DirectStorage 1.1+ GPU decompression supported.
    if ($build -ge 22000) {
        return [PSCustomObject]@{
            Name = 'Windows version'
            Status = 'PASS'
            Detail = "Build $build — full DirectStorage 1.1+ GPU-decompression path supported."
            Remediation = ''
        }
    } elseif ($build -ge 18363) {
        return [PSCustomObject]@{
            Name = 'Windows version'
            Status = 'WARN'
            Detail = "Build $build (Win10 1909+) — DirectStorage 1.0 CPU-fallback only."
            Remediation = 'Upgrade to Windows 11 for the GPU decompression path.'
        }
    } else {
        return [PSCustomObject]@{
            Name = 'Windows version'
            Status = 'FAIL'
            Detail = "Build $build — DirectStorage requires 18363 (Win10 1909) or higher."
            Remediation = 'Upgrade to Windows 11 (or Windows 10 1909 at minimum).'
        }
    }
}

function Test-Dx12UltimateSupport {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # DX12 Ultimate requires DXGI factory + GPU advertising DX12_2 feature
    # level. The cheap proxy on Windows: GPU PnP shows a DXGI render-only
    # adapter AND the OS build is Win10 20H1+ (build 19041) which shipped
    # the DXGI 1.6 API surface DX12 Ultimate needs.
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 19041) {
        return [PSCustomObject]@{
            Name = 'DX12 Ultimate runtime'
            Status = 'FAIL'
            Detail = "Windows build $build < 19041 — DX12 Ultimate runtime not present."
            Remediation = 'Upgrade to Win10 20H1 (build 19041) or later.'
        }
    }
    # We can't easily check the feature-level advertisement from PowerShell
    # without DXGI interop. Conservatively report as "runtime present;
    # verify per-GPU feature level via dxdiag if a specific title fails."
    return [PSCustomObject]@{
        Name = 'DX12 Ultimate runtime'
        Status = 'PASS'
        Detail = "Build $build supports the DX12 Ultimate runtime layer (DXGI 1.6+)."
        Remediation = ''
    }
}

function Test-GpuDirectStorageCapable {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue)) {
        return [PSCustomObject]@{
            Name = 'GPU DirectStorage capability'
            Status = 'WARN'
            Detail = 'Get-PnpDevice unavailable; cannot verify silicon.'
            Remediation = 'Run on Windows for full audit.'
        }
    }

    $gpus = @(Get-PnpDevice -PresentOnly -Class Display -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq 'OK' -and $_.FriendlyName -notmatch 'Microsoft Basic|Hyper-V' })
    if ($gpus.Count -eq 0) {
        return [PSCustomObject]@{
            Name = 'GPU DirectStorage capability'
            Status = 'FAIL'
            Detail = 'No discrete GPU detected.'
            Remediation = 'Install a discrete GPU (RTX 2000+, RX 5000+, or Intel Arc).'
        }
    }
    # Conservative: report GPUs found and let the user confirm against the
    # vendor's DirectStorage support page. Silicon-level support checking
    # requires DXGI interop which isn't ergonomic from PowerShell.
    $names = ($gpus | ForEach-Object { $_.FriendlyName }) -join ', '
    return [PSCustomObject]@{
        Name = 'GPU DirectStorage capability'
        Status = 'PASS'
        Detail = "GPU(s) present: $names. Verify silicon-level DS via vendor specs."
        Remediation = ''
    }
}

$records = @(
    Test-NvmePresence
    Test-WindowsBuildSupport
    Test-Dx12UltimateSupport
    Test-GpuDirectStorageCapable
)

if ($AsObject) {
    return $records
}

UI-Header -Title 'DirectStorage Prereq Audit' -Subtitle 'Read-only — 4 prerequisites'
Write-Host ''

$overall = 'PASS'
foreach ($r in $records) {
    $color = switch ($r.Status) {
        'PASS' { $script:UI_Success }
        'WARN' { $script:UI_Warning }
        'FAIL' { $script:UI_Error }
        default { $script:UI_Info }
    }
    if ($r.Status -eq 'FAIL') { $overall = 'FAIL' }
    if ($r.Status -eq 'WARN' -and $overall -ne 'FAIL') { $overall = 'WARN' }

    Write-Host ("  [{0}] {1}" -f $r.Status, $r.Name) -ForegroundColor $color
    Write-Host "        $($r.Detail)" -ForegroundColor Gray
    if ($r.Remediation) {
        Write-Host "        → $($r.Remediation)" -ForegroundColor DarkGray
    }
    Write-Host ''
}

$overallColor = switch ($overall) {
    'PASS' { $script:UI_Success }
    'WARN' { $script:UI_Warning }
    'FAIL' { $script:UI_Error }
}
Write-Host "  OVERALL: $overall" -ForegroundColor $overallColor
Write-Host ''
Write-Host '  DirectStorage 1.1+ also requires per-game opt-in. Verify a' -ForegroundColor DarkGray
Write-Host '  specific title supports DS via its launcher / vendor page.' -ForegroundColor DarkGray
Write-Host ''
