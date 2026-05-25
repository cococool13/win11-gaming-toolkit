# ============================================================
# Revert Intel Hidden Settings (Manifest-Driven)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Advanced (reverts an Advanced-tier write)
#
# Pair with: configure-intel.ps1
# Restores every intel:* manifest entry written by configure-intel.ps1
# to its pre-toolkit value. Examples: intel:VSyncControl, intel:HwSchMode,
# intel:PowerPlanProfile, intel:FramePacing, etc.
#
# Must be run as Administrator.
# ============================================================

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  [ERROR] revert-intel.ps1 must be run as Administrator." -ForegroundColor Red
    Write-Host ""
    exit 1
}

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title "Revert Intel Settings" -Subtitle "Manifest-driven restore"

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
        if ($id -like "intel:*") {
            UI-Step -Label "Restoring $id" -Action {
                Restore-ToolkitRegistryValue -Id $id | Out-Null
            }
            $restored++
        }
    }
}

if ($restored -eq 0) {
    UI-Note -Message "No Intel settings found in manifest. Either configure-intel.ps1 was never run, or the manifest was wiped." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-intel-settings-revert" -Tier "Advanced" -Status "skipped" -Reason "No manifest entries"
} else {
    Add-ToolkitStepResult -Key "gpu-intel-settings-revert" -Tier "Advanced" -Status "applied" -Reason "Restored $restored Intel settings"
}

UI-Summary -DoneMessage "Intel settings reverted" -Details @(
    "Reboot for the Intel driver to pick up the restored keys."
)
UI-Exit
