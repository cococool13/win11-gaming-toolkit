# ============================================================
# Disable Windows Update Service (Permanent)
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Permanently disables the Windows Update service so updates
# never download or install automatically. The service will
# stay disabled across reboots.
#
# IMPORTANT: You should manually check for updates periodically
# (monthly is recommended) by running enable-windows-update.ps1,
# installing updates, then running this script again.
#
# Must be run as Administrator.
# To revert: run enable-windows-update.ps1
# ============================================================

$Host.UI.RawUI.WindowTitle = "Disable Windows Update"

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  DISABLING WINDOWS UPDATE (PERMANENT)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# 1. Stop the service
Write-Host "  Stopping Windows Update service..." -NoNewline
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Write-Host " Done" -ForegroundColor Green

# 2. Disable the service
Write-Host "  Disabling Windows Update service..." -NoNewline
sc.exe config wuauserv start= disabled 2>&1 | Out-Null
Write-Host " Done" -ForegroundColor Green

# 3. Stop and disable related services
Write-Host "  Disabling Update Orchestrator..." -NoNewline
Stop-Service -Name UsoSvc -Force -ErrorAction SilentlyContinue
sc.exe config UsoSvc start= disabled 2>&1 | Out-Null
Write-Host " Done" -ForegroundColor Green

Write-Host "  Disabling Delivery Optimization..." -NoNewline
Stop-Service -Name DoSvc -Force -ErrorAction SilentlyContinue
sc.exe config DoSvc start= disabled 2>&1 | Out-Null
Write-Host " Done" -ForegroundColor Green

Write-Host "  Disabling Windows Update Medic Service..." -NoNewline
# WaaSMedicSvc is protected — use registry to disable
$medicPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
if (Test-Path $medicPath) {
    Set-ItemProperty $medicPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
    # Verify the write actually succeeded (this key is ACL-protected on newer Win11 builds)
    $result = (Get-ItemProperty $medicPath -Name "Start" -ErrorAction SilentlyContinue).Start
    if ($result -ne 4) {
        Write-Host " WARNING" -ForegroundColor Yellow
        Write-Host "    WaaSMedicSvc could not be disabled (protected on this Windows version)." -ForegroundColor Yellow
        Write-Host "    Windows may automatically re-enable Windows Update." -ForegroundColor Yellow
    } else {
        Write-Host " Done" -ForegroundColor Green
    }
} else {
    Write-Host " Skipped (service not found)" -ForegroundColor Gray
}

# 4. Set Group Policy to disable automatic updates
Write-Host "  Setting Group Policy: no auto-download..." -NoNewline
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
Set-ItemProperty $auPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
Write-Host " Done" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  WINDOWS UPDATE DISABLED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Updates will NOT download or install automatically." -ForegroundColor White
Write-Host ""
Write-Host "  RECOMMENDATION: Check for updates manually once a month." -ForegroundColor Yellow
Write-Host "  Run enable-windows-update.ps1 to re-enable when ready." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
