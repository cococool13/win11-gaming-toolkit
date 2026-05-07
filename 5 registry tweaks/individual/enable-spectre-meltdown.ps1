# ============================================================
# Re-enable Spectre / Meltdown Mitigations
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores the CPU side-channel mitigations from the manifest.
# Falls back to removing the override values so Windows uses
# its inbox defaults (which on supported CPUs is to mitigate).
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Re-enable Spectre / Meltdown Mitigations"
UI-Header -Title "Re-enable Spectre / Meltdown Mitigations" -Subtitle "Restore safe defaults"
UI-RequireAdmin -ScriptName "Enable Spectre/Meltdown mitigations"

UI-ResetCounters
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

UI-Step -Label "Restoring FeatureSettingsOverride" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:FeatureSettingsOverride")) {
        Remove-ItemProperty -Path $path -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
    }
}
UI-Step -Label "Restoring FeatureSettingsOverrideMask" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:FeatureSettingsOverrideMask")) {
        Remove-ItemProperty -Path $path -Name "FeatureSettingsOverrideMask" -ErrorAction SilentlyContinue
    }
}

UI-Summary -DoneMessage "Spectre/Meltdown mitigations restored" -Details @(
    "Reboot for the kernel to re-arm mitigations."
)
UI-Exit
