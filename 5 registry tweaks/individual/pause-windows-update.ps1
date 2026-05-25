# ============================================================
# Pause Windows Update for N Days
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 3 Setup/12 Updates Pause.ps1
# Copyright FR33THY (MIT)
# ============================================================
# Tier: Advanced
#
# Softer alternative to disable-windows-update.ps1: tells Windows
# Update to pause for a configurable number of days. The service
# stays installed and functional — it just won't scan or download
# during the pause window. After the window expires, Windows checks
# normally again.
#
# Best for users who want a few weeks of clean gaming without
# committing to the permanent-disable path (which has the
# WaaSMedicSvc DACL gotcha on Win11 24H2+).
#
# -Days defaults to 7 (the Windows UI minimum). Microsoft caps the
# pause at 35 days regardless of what you pass; the script clamps
# to [1, 35].
#
# Pair: resume-windows-update.ps1
# Must be run as Administrator.
#
# Anti-cheat impact: NONE — WindowsUpdate flight-settings registry
# values; no kernel hooks, no scheduler change.
# ============================================================

param(
    [int]$Days = 7
)

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title "Pause Windows Update" -Subtitle "$Days days (clamped to 1-35)"
UI-RequireAdmin -ScriptName "Pause Windows Update"

if ($Days -lt 1) { $Days = 1 }
if ($Days -gt 35) { $Days = 35 }

Initialize-ToolkitState | Out-Null

$now = Get-Date
$resumeUtc = $now.ToUniversalTime().AddDays($Days)
# Microsoft expects ISO 8601 with "Z"
$resumeStr = $resumeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
$pausedStr = $now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

Write-Host "  Pausing until $resumeStr (UTC)..." -ForegroundColor Yellow

Set-ToolkitRegistryValue -Id "reg:WuFlightSettingsMaxPauseDays" `
    -Path $uxPath -Name "FlightSettingsMaxPauseDays" -Value 35 -Type "DWord" `
    -Tier "Advanced" -Step "windows-update-pause"
Set-ToolkitRegistryValue -Id "reg:WuPauseUpdatesExpiryTime" `
    -Path $uxPath -Name "PauseUpdatesExpiryTime" -Value $resumeStr -Type "String" `
    -Tier "Advanced" -Step "windows-update-pause"
Set-ToolkitRegistryValue -Id "reg:WuPauseFeatureUpdatesEndTime" `
    -Path $uxPath -Name "PauseFeatureUpdatesEndTime" -Value $resumeStr -Type "String" `
    -Tier "Advanced" -Step "windows-update-pause"
Set-ToolkitRegistryValue -Id "reg:WuPauseQualityUpdatesEndTime" `
    -Path $uxPath -Name "PauseQualityUpdatesEndTime" -Value $resumeStr -Type "String" `
    -Tier "Advanced" -Step "windows-update-pause"
Set-ToolkitRegistryValue -Id "reg:WuPauseFeatureUpdatesStartTime" `
    -Path $uxPath -Name "PauseFeatureUpdatesStartTime" -Value $pausedStr -Type "String" `
    -Tier "Advanced" -Step "windows-update-pause"
Set-ToolkitRegistryValue -Id "reg:WuPauseQualityUpdatesStartTime" `
    -Path $uxPath -Name "PauseQualityUpdatesStartTime" -Value $pausedStr -Type "String" `
    -Tier "Advanced" -Step "windows-update-pause"

Add-ToolkitStepResult -Key "windows-update-pause" -Tier "Advanced" -Status "applied" `
    -Reason "Paused $Days days (resume $resumeStr)"

Write-Host ""
Write-Host "  [DONE] Windows Update paused until $resumeStr (UTC)." -ForegroundColor Green
Write-Host "  Resume early: run resume-windows-update.ps1." -ForegroundColor Gray
Read-Host "Press Enter to exit"
