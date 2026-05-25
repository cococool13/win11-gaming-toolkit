# ============================================================
# Disable Windows Update Service (Permanent)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Security Trade-off
#
# Permanently disables the Windows Update service so updates
# never download or install automatically. The service will
# stay disabled across reboots.
#
# IMPORTANT: You should manually check for updates periodically
# (monthly is recommended) by running enable-windows-update.ps1,
# installing updates, then running this script again.
#
# ANTI-CHEAT: Suppressing Windows Update also stalls anti-cheat
# and driver updates that some titles (BattlEye/EAC + ROG Ally /
# Steam Deck Windows installs) ship through WU. Plan to enable
# manually each month and re-check affected games after.
#
# Must be run as Administrator.
# To revert: run enable-windows-update.ps1
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Windows Update"

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# CURSOR-AUDIT #9 fix: ensure the manifest exists so Set-ToolkitServiceStartMode
# and Set-ToolkitRegistryValue can capture before-state for revert.
Initialize-ToolkitState | Out-Null
$stepName = "windows-update"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  DISABLING WINDOWS UPDATE (PERMANENT)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# 1. wuauserv — tracked
Write-Host "  Disabling Windows Update service (wuauserv)..." -NoNewline
try {
    Set-ToolkitServiceStartMode -Name "wuauserv" -Mode "disabled" -Tier "Security Trade-off" -Step $stepName
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. UsoSvc — tracked
Write-Host "  Disabling Update Orchestrator (UsoSvc)..." -NoNewline
try {
    Set-ToolkitServiceStartMode -Name "UsoSvc" -Mode "disabled" -Tier "Security Trade-off" -Step $stepName
    Stop-Service -Name UsoSvc -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. DoSvc — tracked
Write-Host "  Disabling Delivery Optimization (DoSvc)..." -NoNewline
try {
    Set-ToolkitServiceStartMode -Name "DoSvc" -Mode "disabled" -Tier "Security Trade-off" -Step $stepName
    Stop-Service -Name DoSvc -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. WaaSMedicSvc — tracked via registry (service is protected from sc.exe
# changes on Win11 24H2+ via DACL on the key; Set-ToolkitRegistryValue
# routes the write through the manifest so revert can flip it back).
Write-Host "  Disabling Windows Update Medic Service..." -NoNewline
$medicPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
if (Test-Path $medicPath) {
    try {
        Set-ToolkitRegistryValue -Id "reg:WaaSMedicSvcStart" -Path $medicPath -Name "Start" `
            -Value 4 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
        # Verify the write actually succeeded (DACL-protected on 24H2+)
        $result = (Get-ItemProperty $medicPath -Name "Start" -ErrorAction SilentlyContinue).Start
        if ($result -ne 4) {
            Write-Host " WARNING" -ForegroundColor Yellow
            Write-Host "    WaaSMedicSvc could not be disabled (DACL-protected on this Windows version)." -ForegroundColor Yellow
            Write-Host "    Windows may automatically re-enable Windows Update." -ForegroundColor Yellow
            Write-Host "    See GUIDE.md Troubleshooting for the takeown / icacls recovery path." -ForegroundColor Yellow
        } else {
            Write-Host " Done" -ForegroundColor Green
        }
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host " Skipped (service not found)" -ForegroundColor Gray
}

# 5. Group Policy NoAutoUpdate — tracked
Write-Host "  Setting Group Policy: no auto-download..." -NoNewline
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
try {
    Set-ToolkitRegistryValue -Id "reg:NoAutoUpdate" -Path $auPath -Name "NoAutoUpdate" `
        -Value 1 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "applied" `
    -Reason "Windows Update permanently disabled (services + AU policy)"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  WINDOWS UPDATE DISABLED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Updates will NOT download or install automatically." -ForegroundColor White
Write-Host ""
Write-Host "  RECOMMENDATION: Check for updates manually once a month." -ForegroundColor Yellow
Write-Host "  Run enable-windows-update.ps1 (or REVERT-EVERYTHING.ps1) to re-enable." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
