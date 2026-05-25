# ============================================================
# Revert NVIDIA GPU P0 Power State (Manifest-Driven)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Advanced (reverts an Advanced-tier write)
#
# Pair with: force-p0-state.ps1
# Restores PerfLevelSrc and DisableDynamicPstate to their pre-toolkit
# values for every NVIDIA GPU recorded in state.registry by
# force-p0-state.ps1. Ids: reg:NvPerfLevelSrc:* and
# reg:NvDisableDynamicPstate:*.
#
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title "Revert NVIDIA P0 State" -Subtitle "Manifest-driven restore"
UI-RequireAdmin -ScriptName "Revert NVIDIA P0 State"

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
        if ($id -like "reg:NvPerfLevelSrc:*" -or $id -like "reg:NvDisableDynamicPstate:*") {
            UI-Step -Label "Restoring $id" -Action {
                if (Restore-ToolkitRegistryValue -Id $id) {
                    $script:NvP0Restored = $true
                }
            }
            $restored++
        }
    }
}

if ($restored -eq 0) {
    UI-Note -Message "No NVIDIA P0 entries found in manifest. Either force-p0-state.ps1 was never run, or the manifest was wiped." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-p0-state-revert" -Tier "Advanced" -Status "skipped" -Reason "No manifest entries"
} else {
    Add-ToolkitStepResult -Key "gpu-p0-state-revert" -Tier "Advanced" -Status "applied" -Reason "Restored $restored NVIDIA P0 registry entries"
}

UI-Summary -DoneMessage "P0 state reverted" -Details @(
    "Reboot for the driver to pick up the restored keys."
)
UI-Exit
