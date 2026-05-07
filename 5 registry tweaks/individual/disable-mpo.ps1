# ============================================================
# Disable Multiplane Overlay (MPO)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/11 Mpo.ps1
# ============================================================
# MPO is a DWM optimization that hands display planes directly
# to the GPU. On some hardware / driver combinations it causes
# stuttering, flicker on HDR displays, or black-screen flashes
# during video playback.
#
# OverlayTestMode = 5 forces MPO off across DWM. This is the
# documented Microsoft override for diagnostics.
#
# Tracked via Set-TrackedRegistry. Revert path: enable-mpo.ps1
# or REVERT-EVERYTHING.ps1.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Multiplane Overlay"
UI-Header -Title "Disable Multiplane Overlay (MPO)" -Subtitle "DWM OverlayTestMode = 5"
UI-RequireAdmin -ScriptName "Disable MPO"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

UI-Step -Label "Disabling MPO via DWM OverlayTestMode" -Action {
    Set-ToolkitRegistryValue `
        -Id "reg:DwmOverlayTestMode" `
        -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" `
        -Name "OverlayTestMode" `
        -Value 5 -Type "DWord" `
        -Tier "Advanced" -Step "dwm-mpo"
    Add-ToolkitStepResult -Key "reg:DwmOverlayTestMode" -Tier "Advanced" -Status "applied" -Reason "MPO disabled via OverlayTestMode=5"
}

UI-Summary -DoneMessage "MPO disabled" -Details @(
    "Reboot or restart the graphics driver for the change to take effect.",
    "If video playback or HDR behaves worse after this, run enable-mpo.ps1."
) -RevertHint "Run enable-mpo.ps1 in this folder, or REVERT-EVERYTHING.ps1."
UI-Exit
