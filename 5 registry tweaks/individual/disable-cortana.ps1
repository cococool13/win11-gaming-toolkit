<#
.SYNOPSIS
    Disable Cortana via the documented AllowCortana group policy.

.DESCRIPTION
    Sets HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search\
    AllowCortana = 0 — the Microsoft-documented mechanism for enterprise
    Cortana disable. Cortana background services stop spinning up on
    next sign-in, freeing memory and a small amount of CPU.

    Tracked via Set-ToolkitRegistryValue so enable-cortana.ps1 (or
    REVERT-EVERYTHING.ps1) restores the prior value exactly.

    Anti-cheat impact: NONE — Windows Search GPO value; no kernel
    hooks, no game-process surface.
    Reboot required: NO — applies on next sign-in.
    Disk impact: NONE (registry only).

.NOTES
    Tier: Safe
    Pair: enable-cortana.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/configuration/start/cortana-on-windows
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable Cortana'
UI-Header -Title 'Disable Cortana' -Subtitle 'Windows Search\AllowCortana = 0'
UI-RequireAdmin -ScriptName 'Disable Cortana'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not $PSCmdlet.ShouldProcess('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search\AllowCortana', 'Set 0')) {
    UI-Skip -Label 'Disable Cortana' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Writing AllowCortana = 0 (tracked)' -Action {
    Set-ToolkitRegistryValue -Id 'reg:AllowCortana' `
        -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' `
        -Name 'AllowCortana' -Value 0 -Type 'DWord' `
        -Tier 'Safe' -Step 'telemetry-cortana'
}

UI-Summary -DoneMessage 'Cortana disabled' -RevertHint 'Run enable-cortana.ps1 in this folder.'
UI-Exit
