<#
.SYNOPSIS
    Uninstall AMD display driver packages via pnputil.

.DESCRIPTION
    Counterpart to install-amd.ps1. Removes every installed driver
    package whose publisher matches Advanced Micro Devices or bare
    AMD. After this runs the system falls back to Microsoft Basic
    Display Adapter (MBDA) until a fresh driver is installed.

    Each pnputil /delete-driver call is gated by
    $PSCmdlet.ShouldProcess via lib/gpu-uninstall.ps1 so -WhatIf
    previews the deletion plan without modifying the system.

    For a TRULY clean state (Radeon Software, registry leftovers, AMD
    Crash Defender), use AMD Cleanup Utility (separate download) OR
    DduManual.ps1 in Safe Mode AFTER this script.

.NOTES
    Tier: Advanced (driver removal; system in MBDA until reinstall)
    Pair: install-amd.ps1
    Must be run as Administrator.

    # CROSS-PLATFORM-NOTE
    # Windows-only (pnputil). Lib helper returns @() on non-Windows.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ''
    Write-Host '  [ERROR] uninstall-amd.ps1 must be run as Administrator.' -ForegroundColor Red
    Write-Host ''
    exit 1
}

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\gpu-uninstall.ps1"

Write-ToolkitScriptStart

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  Uninstall AMD Driver (pnputil)' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

# $pkgMatches not $matches — $matches is a PowerShell automatic
# variable populated by the -match operator.
$pkgMatches = Get-InstalledGpuDriverPackages -Vendor 'amd'
if (-not $pkgMatches -or $pkgMatches.Count -eq 0) {
    Write-Host '  No installed AMD driver packages found.' -ForegroundColor Gray
    Write-Host '  Nothing to do.'
    exit 0
}
Write-Host "  Found $($pkgMatches.Count) AMD driver package(s):" -ForegroundColor Yellow
foreach ($m in $pkgMatches) {
    Write-Host "    - $($m.InfName)  ($($m.OriginalName), v$($m.Version))" -ForegroundColor Gray
}
Write-Host ''

$result = Uninstall-GpuDriverByPublisher -Vendor 'amd'

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

Add-ToolkitStepResult -Key 'gpu-uninstall-amd' -Tier 'Advanced' -Status 'applied' `
    -Reason "Removed $($result.Removed) AMD driver package(s) via pnputil"

Write-Host ''
Write-Host '  Recommended next step:' -ForegroundColor Yellow
Write-Host '    Boot to Safe Mode and run DduManual.ps1 (or AMD Cleanup' -ForegroundColor Gray
Write-Host '    Utility) for a fully clean state — removes Radeon Software,' -ForegroundColor Gray
Write-Host '    AMD Crash Defender, and registry leftovers.' -ForegroundColor Gray
Write-Host ''
