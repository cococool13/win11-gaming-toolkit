# ============================================================
# Disable Offline Files / Sync Center
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate - 8 Advanced/18 Start Search Shell Mobsync.ps1
# Service reference: https://learn.microsoft.com/en-us/answers/questions/cbd4ce40-1d10-4f42-99db-6da77f6038f5/offline-files-service-cscservice-fails-with-the
# ============================================================
# Sync Center uses the Offline Files service, CscService. `mobsync`
# is the client executable name, not the service name.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Offline Files"
UI-Header -Title "Disable Offline Files" -Subtitle "CscService / Sync Center"
UI-RequireAdmin -ScriptName "Disable Offline Files"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$serviceName = "CscService"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $service) {
    UI-Skip -Label "Offline Files service" -Reason "CscService is not installed on this edition"
    Add-ToolkitStepResult -Key "service:$serviceName" -Tier "Advanced" -Status "skipped" -Reason "CscService not found"
    UI-Exit
    exit 0
}

UI-Step -Label "Disable CscService startup" -Action {
    Set-ToolkitServiceStartMode -Name $serviceName -Mode "disabled" -Tier "Advanced" -Step "services-mobsync"
    Add-ToolkitStepResult -Key "service:$serviceName" -Tier "Advanced" -Status "applied" -Reason "Offline Files disabled"
}

UI-Step -Label "Stop CscService" -Action {
    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
}

UI-Summary -DoneMessage "Offline Files disabled" -Details @(
    "Network files marked 'Always available offline' will no longer sync locally.",
    "Run mobsync-enable.bat or REVERT-EVERYTHING.ps1 to restore the prior startup mode."
)
UI-Exit
