# ============================================================
# Restore Microsoft Edge Background Mode and Startup Boost Policies
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores the prior Edge policy state captured by
# disable-edge-background.ps1. If no manifest entry exists, removes
# the policy values so Edge returns to its default behavior.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Restore Edge Background Mode"
UI-Header -Title "Restore Edge Background Mode" -Subtitle "Remove toolkit Edge policies"
UI-RequireAdmin -ScriptName "Restore Edge Background Mode"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

UI-Step -Label "Restore Edge Startup Boost policy" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:EdgeStartupBoostEnabled")) {
        Remove-ItemProperty -Path $edgePolicyPath -Name "StartupBoostEnabled" -ErrorAction SilentlyContinue
    }
}

UI-Step -Label "Restore Edge background mode policy" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:EdgeBackgroundModeEnabled")) {
        Remove-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue
    }
}

UI-Summary -DoneMessage "Edge background policies restored" -Details @(
    "Close and reopen Edge for policy changes to settle."
)
UI-Exit
