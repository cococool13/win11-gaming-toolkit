<#
.SYNOPSIS
    Restore CEIPEnable to its pre-toolkit value captured by
    disable-ceip.ps1.

.DESCRIPTION
    Tries Restore-ToolkitRegistryValue. If no manifest entry exists,
    removes the override so Windows uses its default (CEIP off-by-
    default on most modern client SKUs, on for some Server SKUs).

.NOTES
    Tier: Safe (returns to OS default CEIP state)
    Anti-cheat impact: NONE — SQMClient legacy diagnostic path; not
        inspected by anti-cheat layers.
    Pair: disable-ceip.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable CEIP'
UI-Header -Title 'Restore CEIPEnable value' -Subtitle 'Return to SKU default'
UI-RequireAdmin -ScriptName 'Enable CEIP'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$path = 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows'

if (-not $PSCmdlet.ShouldProcess("$path\CEIPEnable", 'Restore from manifest or remove override')) {
    UI-Skip -Label 'Restore CEIPEnable' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Restoring CEIPEnable value' -Action {
    if (-not (Restore-ToolkitRegistryValue -Id 'reg:CEIPEnable')) {
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name 'CEIPEnable' -ErrorAction SilentlyContinue
        }
    }
}

UI-Summary -DoneMessage 'CEIP restored' -Details @(
    'CEIP returns to its SKU default state.'
)
UI-Exit
