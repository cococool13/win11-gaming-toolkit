# ============================================================
# Enable Windows Update Service (Revert)
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Re-enables the Windows Update service and all related services.
# Run this when you want to check for and install updates.
#
# Must be run as Administrator.
# ============================================================

$Host.UI.RawUI.WindowTitle = "Enable Windows Update"

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  RE-ENABLING WINDOWS UPDATE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Re-enable services
Write-Host "  Enabling Windows Update service..." -NoNewline
sc.exe config wuauserv start= demand 2>&1 | Out-Null
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Write-Host " Done" -ForegroundColor Green

Write-Host "  Enabling Update Orchestrator..." -NoNewline
sc.exe config UsoSvc start= demand 2>&1 | Out-Null
Start-Service -Name UsoSvc -ErrorAction SilentlyContinue
Write-Host " Done" -ForegroundColor Green

Write-Host "  Enabling Delivery Optimization..." -NoNewline
sc.exe config DoSvc start= auto 2>&1 | Out-Null
Start-Service -Name DoSvc -ErrorAction SilentlyContinue
Write-Host " Done" -ForegroundColor Green

Write-Host "  Enabling Windows Update Medic Service..." -NoNewline
$medicPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
if (Test-Path $medicPath) {
    Set-ItemProperty $medicPath -Name "Start" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
}
Write-Host " Done" -ForegroundColor Green

# 2. Remove Group Policy override
Write-Host "  Removing Group Policy override..." -NoNewline
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (Test-Path $auPath) {
    Remove-ItemProperty $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
}
Write-Host " Done" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  WINDOWS UPDATE RE-ENABLED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Go to Settings > Windows Update to check for updates." -ForegroundColor White
Write-Host "  After updating, run disable-windows-update.ps1 to disable again." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
