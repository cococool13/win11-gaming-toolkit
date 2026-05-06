# ============================================================
# Disable Spectre / Meltdown Mitigations (Performance Trade-off)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/3 Spectre Meltdown.ps1
#
# TIER: Security Trade-off
# Spectre v1/v2 and Meltdown are real CPU side-channel attacks.
# Microsoft's mitigations cost a measurable amount of CPU
# performance, especially on older Intel chips. Disabling them
# matters for benchmarks and competitive game frame times, but
# also makes the CPU vulnerable to documented attacks.
# ============================================================
# Sets:
#   FeatureSettingsOverride     = 3   (disable mitigations)
#   FeatureSettingsOverrideMask = 3   (apply override)
# at HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management
#
# Both go through Set-TrackedRegistry so REVERT-EVERYTHING and
# the matching enable script can restore from the manifest.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Spectre / Meltdown Mitigations"
UI-Header -Title "Disable Spectre / Meltdown Mitigations" -Subtitle "Security Trade-off — performance over CPU side-channel safety"
UI-RequireAdmin -ScriptName "Disable Spectre/Meltdown"
UI-Confirm -Message "This is a Security Trade-off step." -Warnings @(
    "Spectre / Meltdown are real attacks against CPU speculative execution.",
    "Disabling mitigations is appropriate for isolated gaming-only PCs only.",
    "Do NOT disable on machines that handle sensitive data or run untrusted code."
)

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

UI-Step -Label "FeatureSettingsOverride = 3" -Action {
    Set-ToolkitRegistryValue -Id "reg:FeatureSettingsOverride" -Path $path -Name "FeatureSettingsOverride" -Value 3 -Type "DWord" -Tier "Security Trade-off" -Step "spectre-meltdown"
    Add-ToolkitStepResult -Key "reg:FeatureSettingsOverride" -Tier "Security Trade-off" -Status "applied" -Reason "Spectre/Meltdown mitigations override applied"
}
UI-Step -Label "FeatureSettingsOverrideMask = 3" -Action {
    Set-ToolkitRegistryValue -Id "reg:FeatureSettingsOverrideMask" -Path $path -Name "FeatureSettingsOverrideMask" -Value 3 -Type "DWord" -Tier "Security Trade-off" -Step "spectre-meltdown"
    Add-ToolkitStepResult -Key "reg:FeatureSettingsOverrideMask" -Tier "Security Trade-off" -Status "applied" -Reason "Spectre/Meltdown mitigations override mask applied"
}

UI-Summary -DoneMessage "Spectre/Meltdown mitigations disabled" -Details @(
    "A reboot is required for the kernel to apply the new feature flags.",
    "Verify with Get-SpeculationControlSettings or PowerShell module SpeculationControl."
) -RevertHint "Run enable-spectre-meltdown.ps1 in this folder, or REVERT-EVERYTHING.ps1."
UI-Exit
