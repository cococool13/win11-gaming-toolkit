<#
.SYNOPSIS
    Restore Cortana to its pre-toolkit AllowCortana state captured by
    disable-cortana.ps1.

.DESCRIPTION
    Tries Restore-ToolkitRegistryValue against the manifest entry. If
    no entry exists, removes the AllowCortana override so Cortana
    follows the SKU / build default.

    Anti-cheat impact: NONE — pair-symmetric.
    Reboot required: NO — applies on next sign-in.
    Disk impact: NONE.

.NOTES
    Tier: Safe (restores default)
    Pair: disable-cortana.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable Cortana'
UI-Header -Title 'Restore Cortana' -Subtitle 'Remove AllowCortana override'
UI-RequireAdmin -ScriptName 'Enable Cortana'

Initialize-ToolkitState | Out-Null

$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'

if (-not $PSCmdlet.ShouldProcess("$path\AllowCortana", 'Restore from manifest or remove override')) {
    UI-Skip -Label 'Restore AllowCortana' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Restoring AllowCortana' -Action {
    if (-not (Restore-ToolkitRegistryValue -Id 'reg:AllowCortana')) {
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name 'AllowCortana' -ErrorAction SilentlyContinue
        }
    }
}

UI-Summary -DoneMessage 'Cortana restored to default'
UI-Exit
