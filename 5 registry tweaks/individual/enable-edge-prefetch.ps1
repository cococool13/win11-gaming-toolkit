<#
.SYNOPSIS
    Restore Edge predictive prefetching to its pre-toolkit
    NetworkPredictionOptions state captured by disable-edge-prefetch.ps1.

.DESCRIPTION
    Anti-cheat impact: NONE — pair-symmetric.
    Reboot required: NO — Edge picks up on next launch.
    Disk impact: NONE.

.NOTES
    Tier: Safe (restores Edge default)
    Pair: disable-edge-prefetch.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable Edge Prefetch'
UI-Header -Title 'Restore Edge Prefetch' -Subtitle 'Remove NetworkPredictionOptions override'
UI-RequireAdmin -ScriptName 'Enable Edge Prefetch'

Initialize-ToolkitState | Out-Null

$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'

if (-not $PSCmdlet.ShouldProcess("$path\NetworkPredictionOptions", 'Restore or remove')) {
    UI-Skip -Label 'Restore Edge prefetch' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Restoring NetworkPredictionOptions' -Action {
    if (-not (Restore-ToolkitRegistryValue -Id 'reg:EdgeNetworkPrediction')) {
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name 'NetworkPredictionOptions' -ErrorAction SilentlyContinue
        }
    }
}

UI-Summary -DoneMessage 'Edge prefetch restored to default'
UI-Exit
