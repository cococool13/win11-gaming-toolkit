<#
.SYNOPSIS
    Uninstall NVIDIA display driver packages via pnputil.

.DESCRIPTION
    Counterpart to install-nvidia.ps1. Removes every installed driver
    package whose publisher matches NVIDIA. After this runs the system
    falls back to Microsoft Basic Display Adapter (MBDA) until a fresh
    driver is installed.

    Each pnputil /delete-driver call is gated by
    $PSCmdlet.ShouldProcess via lib/gpu-uninstall.ps1 so -WhatIf
    previews the deletion plan without modifying the system.

    For a TRULY clean state (registry leftovers, NVIDIA Container
    services, Telemetry containers), use DduManual.ps1 in Safe Mode
    AFTER this script. Order:
        1. uninstall-nvidia.ps1  (this script — removes the driver
           packages so DDU has less to chase)
        2. Reboot to Safe Mode
        3. DduManual.ps1         (full nuclear scrub)

.NOTES
    Tier: Advanced (driver removal; system in MBDA until reinstall)
    Pair: install-nvidia.ps1
    Must be run as Administrator.

    # CROSS-PLATFORM-NOTE
    # Windows-only (pnputil). Lib helper returns @() on non-Windows.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ''
    Write-Host '  [ERROR] uninstall-nvidia.ps1 must be run as Administrator.' -ForegroundColor Red
    Write-Host ''
    exit 1
}

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\gpu-uninstall.ps1"

# Audit-trail: log this script invocation to the toolkit log dir.
Write-ToolkitScriptStart

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  Uninstall NVIDIA Driver (pnputil)' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

# Surface the deletion plan first via -WhatIf-equivalent enumeration
# so the user can see what will go before -Confirm if they invoked it.
# $pkgMatches not $matches — $matches is a PowerShell automatic
# variable populated by the -match operator.
$pkgMatches = Get-InstalledGpuDriverPackages -Vendor 'nvidia'
if (-not $pkgMatches -or $pkgMatches.Count -eq 0) {
    Write-Host '  No installed NVIDIA driver packages found.' -ForegroundColor Gray
    Write-Host '  Nothing to do.'
    exit 0
}
Write-Host "  Found $($pkgMatches.Count) NVIDIA driver package(s):" -ForegroundColor Yellow
foreach ($m in $pkgMatches) {
    Write-Host "    - $($m.InfName)  ($($m.OriginalName), v$($m.Version))" -ForegroundColor Gray
}
Write-Host ''

$result = Uninstall-GpuDriverByPublisher -Vendor 'nvidia'

Write-Host ''
if ($PSCmdlet.ShouldProcess('summary', 'report')) {
    Write-Host "  Removed: $($result.Removed)" -ForegroundColor Green
    if ($result.Failed.Count -gt 0) {
        Write-Host "  Failed:  $($result.Failed.Count)" -ForegroundColor Yellow
        foreach ($f in $result.Failed) {
            Write-Host "    - $($f.Inf): $($f.Reason)" -ForegroundColor DarkYellow
        }
    }
}

Add-ToolkitStepResult -Key 'gpu-uninstall-nvidia' -Tier 'Advanced' -Status 'applied' `
    -Reason "Removed $($result.Removed) NVIDIA driver package(s) via pnputil"

Write-Host ''
Write-Host '  Recommended next step:' -ForegroundColor Yellow
Write-Host '    Boot to Safe Mode and run DduManual.ps1 for a fully clean state' -ForegroundColor Gray
Write-Host '    (removes NVIDIA Container services, telemetry, registry leftovers).' -ForegroundColor Gray
Write-Host ''
