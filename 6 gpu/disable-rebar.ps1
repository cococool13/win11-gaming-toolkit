# ============================================================
# Disable ReBAR Override (Manifest-Driven Revert)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Safe (restores pre-toolkit BAR exposure)
#
# Pair with: force-rebar.ps1
# Restores HwUMAEnable on every discrete GPU recorded in
# state.registry under reg:GpuHwUMAEnable:*.
#
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Disable ReBAR Override" -Subtitle "Manifest-driven restore"
UI-RequireAdmin -ScriptName "Disable ReBAR override"

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
        if ($id -like "reg:GpuHwUMAEnable:*") {
            UI-Step -Label "Restoring $id" -Action {
                Restore-ToolkitRegistryValue -Id $id | Out-Null
            }
            $restored++
        }
    }
}

if ($restored -eq 0) {
    UI-Note -Message "No ReBAR entries in manifest. Either force-rebar.ps1 was never run, or the manifest was wiped." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-rebar-revert" -Tier "Safe" -Status "skipped" -Reason "No manifest entries"
} else {
    Add-ToolkitStepResult -Key "gpu-rebar-revert" -Tier "Safe" -Status "applied" -Reason "Restored $restored ReBAR entries"
}

UI-Summary -DoneMessage "ReBAR override removed" -Details @(
    "Reboot for the change to take effect."
)
UI-Exit
