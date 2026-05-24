# ============================================================
# Revert AMD ULPS Disable (Manifest-Driven)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Advanced (reverts an Advanced-tier write)
#
# Pair with: configure-amd-ulps.ps1
# Restores EnableUlps to the pre-toolkit value for every AMD GPU
# recorded in state.registry. Id: reg:AmdEnableUlps:*
#
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Revert AMD ULPS" -Subtitle "Manifest-driven restore"
UI-RequireAdmin -ScriptName "Revert AMD ULPS"

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
        if ($id -like "reg:AmdEnableUlps:*") {
            UI-Step -Label "Restoring $id" -Action {
                Restore-ToolkitRegistryValue -Id $id | Out-Null
            }
            $restored++
        }
    }
}

if ($restored -eq 0) {
    UI-Note -Message "No AMD ULPS entries found in manifest. Either configure-amd-ulps.ps1 was never run, or the manifest was wiped." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-amd-ulps-revert" -Tier "Advanced" -Status "skipped" -Reason "No manifest entries"
} else {
    Add-ToolkitStepResult -Key "gpu-amd-ulps-revert" -Tier "Advanced" -Status "applied" -Reason "Restored $restored AMD ULPS entries"
}

UI-Summary -DoneMessage "AMD ULPS reverted" -Details @(
    "Reboot for the driver to re-apply Ultra Low Power State behavior."
)
UI-Exit
