# ============================================================
# Disable MSI Mode (Manifest-Driven Revert)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Advanced (reverts an Advanced-tier write)
#
# Pair with: enable-msi-mode.ps1
# Restores MSISupported to the pre-toolkit value for every device
# (GPU + tracked NVMe) recorded in state.registry by enable-msi-mode.ps1.
# Ids: gpu-msi:*
#
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Disable MSI Mode" -Subtitle "Manifest-driven restore"
UI-RequireAdmin -ScriptName "Disable MSI Mode"

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
        if ($id -like "gpu-msi:*") {
            UI-Step -Label "Restoring $id" -Action {
                Restore-ToolkitRegistryValue -Id $id | Out-Null
            }
            $restored++
        }
    }
}

if ($restored -eq 0) {
    UI-Note -Message "No MSI Mode entries found in manifest. Either enable-msi-mode.ps1 was never run, or the manifest was wiped." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-msi-revert" -Tier "Advanced" -Status "skipped" -Reason "No manifest entries"
} else {
    Add-ToolkitStepResult -Key "gpu-msi-revert" -Tier "Advanced" -Status "applied" -Reason "Restored $restored MSI Mode entries"
}

UI-Summary -DoneMessage "MSI Mode reverted" -Details @(
    "Reboot for the driver to release MSI interrupt assignments."
)
UI-Exit
