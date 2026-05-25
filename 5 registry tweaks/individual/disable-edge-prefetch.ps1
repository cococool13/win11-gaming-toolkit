<#
.SYNOPSIS
    Disable Microsoft Edge predictive prefetching via the documented
    PrefetchModeSetting group policy.

.DESCRIPTION
    Sets HKLM:\SOFTWARE\Policies\Microsoft\Edge\NetworkPredictionOptions
    = 2 (Disabled) — the Microsoft-documented mechanism to turn off
    Edge's DNS prefetch + page-prerender behavior. Lower background
    network traffic during gaming sessions, and stops Edge from
    pre-resolving names a user never visits.

    Distinct from disable-edge-background.ps1 (which targets startup
    boost + background mode); these are independent toggles that
    coordinate well.

    Anti-cheat impact: NONE — Edge browser group-policy value.
    Reboot required: NO — Edge picks up the policy on next launch.
    Disk impact: NONE (registry only).

.NOTES
    Tier: Safe
    Pair: enable-edge-prefetch.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies#networkpredictionoptions
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable Edge Prefetch'
UI-Header -Title 'Disable Edge Prefetch' -Subtitle 'NetworkPredictionOptions = 2'
UI-RequireAdmin -ScriptName 'Disable Edge Prefetch'

Initialize-ToolkitState | Out-Null

if (-not $PSCmdlet.ShouldProcess('HKLM:\SOFTWARE\Policies\Microsoft\Edge\NetworkPredictionOptions', 'Set 2 (Disabled)')) {
    UI-Skip -Label 'Disable Edge prefetch' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Writing NetworkPredictionOptions = 2 (tracked)' -Action {
    Set-ToolkitRegistryValue -Id 'reg:EdgeNetworkPrediction' `
        -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' `
        -Name 'NetworkPredictionOptions' -Value 2 -Type 'DWord' `
        -Tier 'Safe' -Step 'edge-prefetch'
}

UI-Summary -DoneMessage 'Edge prefetch disabled' -RevertHint 'Run enable-edge-prefetch.ps1.'
UI-Exit
