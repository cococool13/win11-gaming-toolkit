# ============================================================
# Restore Offline Files / Sync Center
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores the CscService startup mode captured by
# mobsync-disable.ps1. If no manifest entry exists, falls back to
# Manual startup, which is the conservative non-running default.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Restore Offline Files"
UI-Header -Title "Restore Offline Files" -Subtitle "CscService / Sync Center"
UI-RequireAdmin -ScriptName "Restore Offline Files"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$serviceName = "CscService"

UI-Step -Label "Restore CscService startup" -Action {
    if (-not (Restore-ToolkitServiceStartMode -Name $serviceName)) {
        sc.exe config $serviceName start= demand 2>&1 | Out-Null
    }
}

UI-Summary -DoneMessage "Offline Files restored" -Details @(
    "Reboot if Sync Center does not immediately show Offline Files options."
)
UI-Exit
