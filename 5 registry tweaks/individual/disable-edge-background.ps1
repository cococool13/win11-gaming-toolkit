# ============================================================
# Disable Microsoft Edge Background Mode and Startup Boost
# Windows 11 Gaming Optimization Guide
# Sources:
#   https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/startupboostenabled
#   https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/backgroundmodeenabled
# ============================================================
# Applies Chromium Edge machine policies that stop Edge from
# pre-launching at sign-in and continuing background work after
# the browser is closed.
#
# Tracked via toolkit-state so the prior policy state can be
# restored exactly by enable-edge-background.ps1 or full revert.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Edge Background Mode"
UI-Header -Title "Disable Edge Background Mode" -Subtitle "Startup Boost and background mode policies"
UI-RequireAdmin -ScriptName "Disable Edge Background Mode"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

UI-Step -Label "Disable Edge Startup Boost" -Action {
    Set-ToolkitRegistryValue `
        -Id "reg:EdgeStartupBoostEnabled" `
        -Path $edgePolicyPath `
        -Name "StartupBoostEnabled" `
        -Value 0 -Type "DWord" `
        -Tier "Safe" -Step "edge-background"
    Add-ToolkitStepResult -Key "reg:EdgeStartupBoostEnabled" -Tier "Safe" -Status "applied" -Reason "Edge Startup Boost disabled"
}

UI-Step -Label "Disable Edge background mode" -Action {
    Set-ToolkitRegistryValue `
        -Id "reg:EdgeBackgroundModeEnabled" `
        -Path $edgePolicyPath `
        -Name "BackgroundModeEnabled" `
        -Value 0 -Type "DWord" `
        -Tier "Safe" -Step "edge-background"
    Add-ToolkitStepResult -Key "reg:EdgeBackgroundModeEnabled" -Tier "Safe" -Status "applied" -Reason "Edge background mode disabled"
}

UI-Summary -DoneMessage "Edge background policies applied" -Details @(
    "Close and reopen Edge for policy changes to settle.",
    "Edge may cold-start more slowly, but it will stop preloading at sign-in."
) -RevertHint "Run enable-edge-background.ps1 in this folder, or REVERT-EVERYTHING.ps1."
UI-Exit
