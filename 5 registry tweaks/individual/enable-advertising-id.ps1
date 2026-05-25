<#
.SYNOPSIS
    Restore the Advertising ID to its pre-toolkit Enabled state
    captured by disable-advertising-id.ps1.

.DESCRIPTION
    Anti-cheat impact: NONE — pair-symmetric.
    Reboot required: NO — picks up on next app launch.
    Disk impact: NONE.

.NOTES
    Tier: Safe (restores default)
    Pair: disable-advertising-id.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable Advertising ID'
UI-Header -Title 'Restore Advertising ID' -Subtitle 'Remove Enabled override'
UI-RequireAdmin -ScriptName 'Enable Advertising ID'

Initialize-ToolkitState | Out-Null

$path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'

if (-not $PSCmdlet.ShouldProcess("$path\Enabled", 'Restore or remove')) {
    UI-Skip -Label 'Restore Advertising ID' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Restoring AdvertisingInfo\Enabled' -Action {
    if (-not (Restore-ToolkitRegistryValue -Id 'reg:AdvertisingIdEnabled')) {
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name 'Enabled' -ErrorAction SilentlyContinue
        }
    }
}

UI-Summary -DoneMessage 'Advertising ID restored to default'
UI-Exit
