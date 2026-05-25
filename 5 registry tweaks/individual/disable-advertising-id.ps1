<#
.SYNOPSIS
    Disable the per-user Advertising ID via the documented
    AdvertisingInfo\Enabled = 0 setting.

.DESCRIPTION
    Sets HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo
    Enabled = 0. Apps that respect the Advertising ID policy (most
    UWP / Store apps do; some classic Win32 apps don't) will stop
    receiving the user's per-device advertising identifier.

    Anti-cheat impact: NONE — HKCU policy value, no kernel hooks,
    no game-process surface.
    Reboot required: NO — picks up on next app launch.
    Disk impact: NONE.

.NOTES
    Tier: Safe
    Pair: enable-advertising-id.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/uwp/monetize/about-the-advertising-identifier
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable Advertising ID'
UI-Header -Title 'Disable Advertising ID' -Subtitle 'AdvertisingInfo\Enabled = 0'
UI-RequireAdmin -ScriptName 'Disable Advertising ID'

Initialize-ToolkitState | Out-Null

if (-not $PSCmdlet.ShouldProcess('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled', 'Set 0')) {
    UI-Skip -Label 'Disable Advertising ID' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Writing Enabled = 0 (tracked)' -Action {
    Set-ToolkitRegistryValue -Id 'reg:AdvertisingIdEnabled' `
        -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' `
        -Name 'Enabled' -Value 0 -Type 'DWord' `
        -Tier 'Safe' -Step 'advertising-id'
}

UI-Summary -DoneMessage 'Advertising ID disabled' -RevertHint 'Run enable-advertising-id.ps1.'
UI-Exit
