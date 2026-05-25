<#
.SYNOPSIS
    Disable Web Search in the Start menu — keep Start search local.

.DESCRIPTION
    Sets the HKCU policy values that stop the Start menu from sending
    typed queries to Bing for web suggestions. After this runs,
    typing into Start returns only local app / file results.

    Two values are tracked (both per-user):
      HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search
        BingSearchEnabled = 0
        CortanaConsent     = 0

    Plus the HKLM policy that also blocks web search:
      HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search
        DisableWebSearch = 1

    All three go through Set-ToolkitRegistryValue so the matching
    enable script restores each from the manifest.

    Anti-cheat impact: NONE — Start menu / Windows Search policy.
    Reboot required: NO — Explorer picks up on next sign-in.
    Disk impact: NONE.

.NOTES
    Tier: Safe
    Pair: enable-web-search-start.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/configuration/start/cortana-on-windows
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable Web Search in Start'
UI-Header -Title 'Disable Web Search in Start Menu' -Subtitle 'Local results only'
UI-RequireAdmin -ScriptName 'Disable Web Search'

Initialize-ToolkitState | Out-Null

$writes = @(
    @{ Id = 'reg:BingSearchEnabled'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Value = 0 }
    @{ Id = 'reg:CortanaConsent'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'CortanaConsent'; Value = 0 }
    @{ Id = 'reg:DisableWebSearch'; Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'DisableWebSearch'; Value = 1 }
)

foreach ($w in $writes) {
    if (-not $PSCmdlet.ShouldProcess("$($w.Path)\$($w.Name)", "Set $($w.Value)")) {
        UI-Skip -Label $w.Id -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "Writing $($w.Id)" -Action {
        Set-ToolkitRegistryValue -Id $w.Id `
            -Path $w.Path -Name $w.Name `
            -Value $w.Value -Type 'DWord' `
            -Tier 'Safe' -Step 'web-search-start'
    }.GetNewClosure()
}

UI-Summary -DoneMessage 'Web search in Start disabled' -RevertHint 'Run enable-web-search-start.ps1.'
UI-Exit
