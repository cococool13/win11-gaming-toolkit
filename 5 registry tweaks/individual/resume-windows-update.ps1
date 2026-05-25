# ============================================================
# Resume Windows Update (cancel pause)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Safe (restores OS default)
#
# Pair with: pause-windows-update.ps1
# Restores every reg:WuPause* / reg:WuFlightSettings* entry from the
# manifest. Falls back to direct Remove-ItemProperty so re-running on
# a tree without manifest entries still resumes WU.
#
# Must be run as Administrator.
#
# Anti-cheat impact: NONE — WindowsUpdate flight-settings registry
# values; no kernel hooks, no scheduler change.
# Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
# Disk impact: NONE — registry-only write; no on-disk file creation.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title "Resume Windows Update" -Subtitle "Cancel any active pause"
UI-RequireAdmin -ScriptName "Resume Windows Update"

Initialize-ToolkitState | Out-Null
$state = Get-ToolkitState

$restored = 0
if ($state -and $state.PSObject.Properties["registry"] -and $state.registry) {
    $regKeys = @()
    if ($state.registry -is [hashtable]) {
        $regKeys = @($state.registry.Keys)
    } else {
        $regKeys = @($state.registry.PSObject.Properties.Name)
    }
    foreach ($id in $regKeys) {
        if ($id -like "reg:Wu*") {
            UI-Step -Label "Restoring $id" -Action {
                Restore-ToolkitRegistryValue -Id $id | Out-Null
            }
            $restored++
        }
    }
}

# Defaults fallback: blind-remove pause values regardless
$uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
if (Test-Path $uxPath) {
    foreach ($name in @(
            "PauseUpdatesExpiryTime",
            "PauseFeatureUpdatesEndTime", "PauseFeatureUpdatesStartTime",
            "PauseQualityUpdatesEndTime", "PauseQualityUpdatesStartTime"
        )) {
        Remove-ItemProperty -Path $uxPath -Name $name -ErrorAction SilentlyContinue
    }
}

Add-ToolkitStepResult -Key "windows-update-pause-revert" -Tier "Safe" -Status "applied" `
    -Reason "Windows Update pause cleared ($restored manifest entries restored)"

Write-Host ""
Write-Host "  [DONE] Windows Update will resume on the next check (typically within minutes)." -ForegroundColor Green
Read-Host "Press Enter to exit"
