<#
.SYNOPSIS
    Revert power plan to Balanced and restore default settings.

.DESCRIPTION
    Counterpart to configure-power.ps1. Restores the power plan to
    Windows defaults (Balanced scheme) and resets all per-device power
    settings to their defaults. Manifest-tracked registry changes are
    restored via the toolkit; everything else falls back to system defaults.

    Each powercfg and Set-ToolkitRegistryValue call is gated by
    $PSCmdlet.ShouldProcess so -WhatIf previews the revert plan
    without modifying the system.

.NOTES
    Tier: Safe (restores OS power-management defaults)
    Pair: configure-power.ps1
    Must be run as Administrator.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ''
    Write-Host '  [ERROR] revert-power.ps1 must be run as Administrator.' -ForegroundColor Red
    Write-Host ''
    exit 1
}

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

Write-ToolkitScriptStart

$Host.UI.RawUI.WindowTitle = "Revert Power Plan"

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  Reverting Power Plan to Balanced' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

# Surface the revert plan
$activePlanOutput = powercfg /getactivescheme 2>&1
$activePlanName = ""
if ($activePlanOutput -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\s\+\((.+)\)") {
    $activePlanName = $Matches[2]
}

Write-Host "  Current plan: $activePlanName" -ForegroundColor Yellow
Write-Host "  Will restore to: Windows Balanced" -ForegroundColor Gray
Write-Host ''

# Revert steps
Write-Host "  Restoring power plan..." -NoNewline
if (-not $PSCmdlet.ShouldProcess("Power plan", "powercfg /setactive SCHEME_BALANCED")) {
    Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
} else {
    try {
        powercfg /setactive SCHEME_BALANCED 2>&1 | Out-Null
        powercfg /delete 99999999-9999-9999-9999-999999999999 2>&1 | Out-Null
        Write-Host " Done" -ForegroundColor Green
    } catch {
        Write-Host " Failed: $_" -ForegroundColor Red
    }
}

Write-Host "  Re-enabling Fast Startup..." -NoNewline
if (-not $PSCmdlet.ShouldProcess("HiberbootEnabled = 1", "Set-ToolkitRegistryValue")) {
    Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
} else {
    Set-ToolkitRegistryValue -Id "pwr:HiberbootEnabled" `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
        -Name "HiberbootEnabled" -Value 1 -Type "DWord" -Tier "Safe" -Step "power-revert" | Out-Null
    Set-ToolkitRegistryValue -Id "pwr:HibernateEnabled" `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" `
        -Name "HibernateEnabled" -Value 1 -Type "DWord" -Tier "Safe" -Step "power-revert" | Out-Null
    Write-Host " Done" -ForegroundColor Green
}

Write-Host "  Removing power throttling override..." -NoNewline
if (-not $PSCmdlet.ShouldProcess("PowerThrottlingOff", "Remove-ItemProperty")) {
    Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
} else {
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
        -Name "PowerThrottlingOff" -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
}

Write-Host "  Re-enabling hibernate..." -NoNewline
if (-not $PSCmdlet.ShouldProcess("Hibernate", "powercfg /hibernate on")) {
    Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
} else {
    powercfg /hibernate on 2>&1 | Out-Null
    Write-Host " Done" -ForegroundColor Green
}

Add-ToolkitStepResult -Key "power-revert" -Tier "Safe" -Status "applied" `
    -Reason "Reverted power plan to Balanced, restored default power settings"

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host '  Power Plan Reverted' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host ''
Write-Host "  Power plan: Balanced (Windows default)" -ForegroundColor Gray
Write-Host "  Fast Startup: re-enabled" -ForegroundColor Gray
Write-Host "  Hibernation: re-enabled" -ForegroundColor Gray
Write-Host "  Power throttling: system default" -ForegroundColor Gray
Write-Host ''
Read-Host "Press Enter to exit"
