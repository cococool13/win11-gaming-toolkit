# ============================================================
# Enable Multiplane Overlay (MPO) — revert path for disable-mpo.ps1
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores prior MPO state from the manifest if it was captured.
# Falls back to removing the OverlayTestMode value (Windows then
# uses its driver-default behavior).
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Enable Multiplane Overlay"
UI-Header -Title "Enable Multiplane Overlay (MPO)" -Subtitle "Restore default DWM behavior"
UI-RequireAdmin -ScriptName "Enable MPO"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

UI-Step -Label "Restoring DWM OverlayTestMode" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:DwmOverlayTestMode")) {
        # No manifest entry — remove the value so Windows uses its driver default.
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -ErrorAction SilentlyContinue
    }
}

UI-Summary -DoneMessage "MPO restored" -Details @(
    "Reboot for the change to take effect."
)
UI-Exit
