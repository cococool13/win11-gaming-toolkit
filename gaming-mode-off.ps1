# ============================================================
# GAMING MODE OFF — Restore Normal State
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Undoes everything gaming-mode.ps1 changed:
#   - Re-enables notifications
#   - Restarts Windows Update service
#   - Restarts Delivery Optimization
#
# Does NOT re-open closed apps (browser, Discord, etc.)
# — those will start normally next time you open them.
#
# Must be run as Administrator.
# ============================================================

$Host.UI.RawUI.WindowTitle = "Gaming Mode — OFF"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GAMING MODE — DEACTIVATING" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ---- Read saved state ----
$stateFile = "$env:TEMP\gaming-mode-state.txt"
$savedState = $null
if (Test-Path $stateFile) {
    try { $savedState = Get-Content $stateFile -Raw | ConvertFrom-Json } catch {}
}

# ---- 1. Re-enable notifications (only if they were enabled before gaming mode) ----
Write-Host "[1/3] Re-enabling notifications..." -ForegroundColor White
if ($null -eq $savedState -or $savedState.NotificationsWereEnabled -eq $true) {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_TOASTS_ENABLED" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    Write-Host "  Notifications restored." -ForegroundColor Green
} else {
    Write-Host "  Notifications were already disabled before gaming mode — skipping." -ForegroundColor Gray
}

# ---- 2. Restart Windows Update ----
Write-Host ""
Write-Host "[2/3] Restarting Windows Update service..." -ForegroundColor White
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Write-Host "  Windows Update service started." -ForegroundColor Green

# ---- 3. Restart Delivery Optimization ----
Write-Host ""
Write-Host "[3/3] Restarting Delivery Optimization..." -ForegroundColor White
Start-Service -Name DoSvc -ErrorAction SilentlyContinue
Write-Host "  Delivery Optimization started." -ForegroundColor Green

# ---- Kill any background priority watcher jobs ----
Get-Job | Where-Object { $_.State -eq "Running" } | Stop-Job -ErrorAction SilentlyContinue
Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue

# ---- Clean up state file ----
$stateFile = "$env:TEMP\gaming-mode-state.txt"
Remove-Item $stateFile -Force -ErrorAction SilentlyContinue

# ---- Summary ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GAMING MODE — OFF" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Normal mode restored:" -ForegroundColor Gray
Write-Host "    - Notifications re-enabled" -ForegroundColor Gray
Write-Host "    - Windows Update running" -ForegroundColor Gray
Write-Host "    - Delivery Optimization running" -ForegroundColor Gray
Write-Host ""
Write-Host "  Note: Closed apps (browser, Discord, etc.) were not" -ForegroundColor Gray
Write-Host "  restarted — open them manually as needed." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
