<#
.SYNOPSIS
    Re-enable Windows Update services (wuauserv, UsoSvc, DoSvc,
    WaaSMedicSvc) and remove the NoAutoUpdate Group Policy override.

.DESCRIPTION
    Pairs with disable-windows-update.ps1. Sets each service start mode
    via sc.exe config, then starts the service. Each step is gated by
    $PSCmdlet.ShouldProcess so -WhatIf previews without modifying
    service state.

    Service start-mode targets:
      wuauserv      → demand (matches Windows default for the user-initiated flow)
      UsoSvc        → demand
      DoSvc         → auto (delivery optimization is auto-start by default)
      WaaSMedicSvc  → Start=3 (manual) via direct registry — see Get-Help
                      for why this is registry not sc.exe (DACL block on 24H2+).

.NOTES
    Tier: Safe (restores OS update path)
    Pair: disable-windows-update.ps1
    Anti-cheat impact: NONE (restores the OS update path; the
        suppression had indirect impact via missed anti-cheat
        version updates — re-enabling clears that risk).
    Must be run as Administrator.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

$Host.UI.RawUI.WindowTitle = "Enable Windows Update"

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Dot-source the toolkit-state lib so Write-ToolkitScriptStart (and any
# manifest helpers a future enhancement might need) are defined.
. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  RE-ENABLING WINDOWS UPDATE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Re-enable services — data-driven loop so adding a fifth service is a
# 1-line array push, not a 4-line block copy. Each iteration gates the
# write via $PSCmdlet.ShouldProcess for -WhatIf support.
$services = @(
    @{ Name = 'wuauserv'; StartMode = 'demand'; Label = 'Windows Update service' }
    @{ Name = 'UsoSvc'; StartMode = 'demand'; Label = 'Update Orchestrator' }
    @{ Name = 'DoSvc'; StartMode = 'auto'; Label = 'Delivery Optimization' }
)
foreach ($svc in $services) {
    Write-Host "  Enabling $($svc.Label)..." -NoNewline
    if (-not $PSCmdlet.ShouldProcess("Service '$($svc.Name)' (start=$($svc.StartMode))", "sc.exe config + Start-Service")) {
        Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
        continue
    }
    sc.exe config $svc.Name start= $svc.StartMode 2>&1 | Out-Null
    Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
}

# WaaSMedicSvc needs direct registry write — on 24H2+ the DACL blocks
# `sc.exe config WaaSMedicSvc start= demand` even from SYSTEM.
Write-Host "  Enabling Windows Update Medic Service..." -NoNewline
$medicPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
if ($PSCmdlet.ShouldProcess("$medicPath\Start = 3 (Manual)", "Set-ItemProperty")) {
    if (Test-Path $medicPath) {
        Set-ItemProperty $medicPath -Name "Start" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Host " Done" -ForegroundColor Green
} else {
    Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
}

# Remove Group Policy override
Write-Host "  Removing Group Policy override..." -NoNewline
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if ($PSCmdlet.ShouldProcess("$auPath\NoAutoUpdate", "Remove-ItemProperty")) {
    if (Test-Path $auPath) {
        Remove-ItemProperty $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    }
    Write-Host " Done" -ForegroundColor Green
} else {
    Write-Host " Skipped (-WhatIf)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  WINDOWS UPDATE RE-ENABLED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Go to Settings > Windows Update to check for updates." -ForegroundColor White
Write-Host "  After updating, run disable-windows-update.ps1 to disable again." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
