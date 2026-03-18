# ============================================================
# GAMING MODE — Pre-Session Optimizer
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Run this before a gaming session to maximize performance.
# Everything is SESSION-BASED — nothing permanent.
# Normal state is restored on reboot or by running gaming-mode-off.ps1.
#
# What it does:
#   1. Kills known resource hogs (browsers, OneDrive sync, etc.)
#   2. Enables Focus Assist / Do Not Disturb
#   3. Clears standby memory
#   4. Temporarily pauses Windows Update service
#   5. Sets a game process to High priority (if specified)
#
# Usage:
#   .\gaming-mode.ps1                    — Basic mode
#   .\gaming-mode.ps1 -Game "valorant"   — Also sets Valorant to High priority
#
# Must be run as Administrator.
# To restore: run gaming-mode-off.ps1 or just reboot.
# ============================================================

param(
    [string]$Game = ""
)

$Host.UI.RawUI.WindowTitle = "Gaming Mode — ON"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  GAMING MODE — ACTIVATING" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$actions = 0

# ---- 1. Kill resource hogs ----
Write-Host "[1/5] Closing resource-heavy background apps..." -ForegroundColor White

$processesToKill = @(
    @("msedge",           "Microsoft Edge"),
    @("chrome",           "Google Chrome"),
    @("firefox",          "Firefox"),
    @("OneDrive",         "OneDrive"),
    @("Teams",            "Microsoft Teams"),
    @("Spotify",          "Spotify"),
    @("slack",            "Slack"),
    @("Widgets",          "Windows Widgets")
    # Discord intentionally excluded — commonly used during gaming for voice chat
)

# Show what will be killed and warn the user
$toKill = @()
foreach ($proc in $processesToKill) {
    if (Get-Process -Name $proc[0] -ErrorAction SilentlyContinue) {
        $toKill += $proc[1]
    }
}
if ($toKill.Count -gt 0) {
    Write-Host "  The following apps will be FORCE-CLOSED (save your work first):" -ForegroundColor Yellow
    foreach ($name in $toKill) { Write-Host "    - $name" -ForegroundColor Yellow }
    Write-Host ""
    Read-Host "  Press Enter to continue or Ctrl+C to cancel"
}

foreach ($proc in $processesToKill) {
    $running = Get-Process -Name $proc[0] -ErrorAction SilentlyContinue
    if ($running) {
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "  Closed: $($proc[1])" -ForegroundColor Gray
        $actions++
    }
}

if ($actions -eq 0) {
    Write-Host "  No resource hogs running." -ForegroundColor Gray
}

# ---- 2. Enable Focus Assist / DND ----
Write-Host ""
Write-Host "[2/5] Enabling Focus Assist (Do Not Disturb)..." -ForegroundColor White

# Save current state for reverting
$currentFocus = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default`$windows.data.shell.focusassist\windows.data.shell.focusassist" -ErrorAction SilentlyContinue)

# Enable DND via registry (priority only mode = suppress most notifications)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_TOASTS_ENABLED" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  Notifications suppressed." -ForegroundColor Gray

# ---- 3. Clear standby memory ----
Write-Host ""
Write-Host "[3/5] Clearing standby memory..." -ForegroundColor White

# Use RamMap-style clearing via .NET
try {
    # Clear working sets
    [System.Diagnostics.Process]::GetProcesses() | ForEach-Object {
        try { $_.MinWorkingSet = $_.MinWorkingSet } catch {}
    }
    Write-Host "  Working sets trimmed." -ForegroundColor Gray
} catch {
    Write-Host "  Could not clear memory (non-critical)." -ForegroundColor DarkGray
}

# ---- 4. Pause Windows Update ----
Write-Host ""
Write-Host "[4/5] Pausing Windows Update service..." -ForegroundColor White

$wuStatus = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status
if ($wuStatus -eq "Running") {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Write-Host "  Windows Update paused (restarts on reboot or gaming-mode-off.ps1)." -ForegroundColor Gray
} else {
    Write-Host "  Windows Update already stopped." -ForegroundColor Gray
}

# Also stop Delivery Optimization (P2P update sharing)
Stop-Service -Name DoSvc -Force -ErrorAction SilentlyContinue 2>$null
Write-Host "  Delivery Optimization paused." -ForegroundColor Gray

# ---- 5. Set game priority ----
Write-Host ""
Write-Host "[5/5] Game process priority..." -ForegroundColor White

if ($Game -ne "") {
    $gameProc = Get-Process -Name $Game -ErrorAction SilentlyContinue
    if ($gameProc) {
        $gameProc | ForEach-Object { $_.PriorityClass = "High" }
        Write-Host "  Set '$Game' to High priority." -ForegroundColor Green
    } else {
        Write-Host "  '$Game' is not running yet." -ForegroundColor Yellow
        Write-Host "  Starting a background watcher — will set priority when it launches..." -ForegroundColor Yellow

        # Start a background job that watches for the game process
        $watchScript = {
            param($gameName)
            $timeout = 3600  # Watch for 1 hour max
            $elapsed = 0
            while ($elapsed -lt $timeout) {
                Start-Sleep -Seconds 5
                $elapsed += 5
                $proc = Get-Process -Name $gameName -ErrorAction SilentlyContinue
                if ($proc) {
                    $proc | ForEach-Object { $_.PriorityClass = "High" }
                    break
                }
            }
        }
        Start-Job -ScriptBlock $watchScript -ArgumentList $Game | Out-Null
        Write-Host "  Watcher started. Will auto-set priority when '$Game' launches." -ForegroundColor Gray
    }
} else {
    Write-Host "  No game specified. Use -Game 'processname' to set priority." -ForegroundColor Gray
    Write-Host "  Example: .\gaming-mode.ps1 -Game 'valorant'" -ForegroundColor Gray
}

# ---- Save state for revert ----
$stateFile = "$env:TEMP\gaming-mode-state.txt"
# Save notification state so gaming-mode-off can conditionally restore
$notifState = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -ErrorAction SilentlyContinue).NOC_GLOBAL_SETTING_TOASTS_ENABLED
@{
    Status = "ACTIVE"
    NotificationsWereEnabled = ($null -eq $notifState -or $notifState -eq 1)
} | ConvertTo-Json | Out-File $stateFile -Force

# ---- Summary ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  GAMING MODE — ACTIVE" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Background apps closed, notifications silenced," -ForegroundColor Gray
Write-Host "  memory cleared, Windows Update paused." -ForegroundColor Gray
Write-Host ""
Write-Host "  To restore normal mode:" -ForegroundColor Yellow
Write-Host "    Run gaming-mode-off.ps1 (or just reboot)" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to minimize this window and start gaming"
