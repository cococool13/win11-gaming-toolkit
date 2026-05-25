<#
.SYNOPSIS
    Disable DWM Multiplane Overlay (MPO) via OverlayTestMode = 5 on
    Windows builds that support the override (WDDM 2.7+, build 18363+).

.DESCRIPTION
    MPO is a DWM optimization that hands individual display planes
    directly to the GPU compositor instead of routing every frame
    through DWM's RGBA composition path. The benefit (lower latency
    on video playback) is real, but on some hardware/driver combos it
    causes:
      - Stuttering or microhitches in fullscreen games
      - Flicker on HDR displays
      - Black-screen flashes during video playback
      - Frame-pacing artifacts with VRR + windowed games

    OverlayTestMode = 5 is the documented Microsoft override for
    forcing MPO off across DWM (used by their support engineers when
    diagnosing display issues). It's the cleanest disable path.

    *** WDDM VERSION GATE ***
    OverlayTestMode is honored starting at WDDM 2.7 (Windows 10
    1909 / build 18363). On earlier builds the value is silently
    ignored — applying it on, say, Win10 1809 produces no diagnostic
    output, no error, and no effect. Setting a manifest entry for
    a no-op would be misleading, so this script fails CLOSED below
    18363 with an explicit "your build doesn't support this" message
    instead of writing a registry key that will never be honored.

    Before/after metric: open Settings → Display → Graphics →
    Advanced and look for "Hardware-accelerated GPU scheduling"
    presence (companion feature, not the same as MPO but on the same
    page). After this script + reboot, DxDiag → Display tab should
    show "Plane Count: 1" instead of the GPU's plane count.

    Anti-cheat impact: NONE. OverlayTestMode is a DWM diagnostic
    flag; no kernel hooks, no kernel mode driver state. Safe on
    R6 Siege / Valorant / EAC / BE.

.NOTES
    Tier: Advanced (changes display compositor behavior; reversible
    via enable-mpo.ps1 or REVERT-EVERYTHING.ps1)
    Pair: enable-mpo.ps1
    Source: FR33THYFR33THY/Ultimate — 8 Advanced/11 Mpo.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows-hardware/drivers/display/wddm-2-7-features
      https://learn.microsoft.com/en-us/windows/win32/dwm/registry-mpo
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Multiplane Overlay"
UI-Header -Title "Disable Multiplane Overlay (MPO)" -Subtitle "DWM OverlayTestMode = 5 (WDDM 2.7+ only)"
UI-RequireAdmin -ScriptName "Disable MPO"

# WDDM gate — fail closed on builds older than 1909 (build 18363)
# where OverlayTestMode is silently ignored. Don't write a manifest
# entry for a registry value that won't be honored.
$buildNumber = [System.Environment]::OSVersion.Version.Build
$WddmMinBuild = 18363  # Windows 10 1909 — first build with WDDM 2.7 OverlayTestMode honored
if ($buildNumber -lt $WddmMinBuild) {
    UI-Note -Message "[GATE] OverlayTestMode is silently ignored on Windows build $buildNumber." -Color $script:UI_Error
    UI-Note -Message "       Minimum: Windows 10 build $WddmMinBuild (1909) for WDDM 2.7 honoring."
    UI-Note -Message "       No registry write performed. Upgrade Windows or use vendor driver options."
    UI-Exit
    exit 1
}

Initialize-ToolkitState | Out-Null
UI-ResetCounters

# Hoisted ShouldProcess — see canonical pattern in mmagent refactor.
if (-not $PSCmdlet.ShouldProcess("HKLM:\SOFTWARE\Microsoft\Windows\Dwm\OverlayTestMode", "Set to 5 (force MPO off)")) {
    UI-Skip -Label "Disabling MPO via DWM OverlayTestMode" -Reason "-WhatIf preview"
    UI-Exit
    exit 0
}

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
