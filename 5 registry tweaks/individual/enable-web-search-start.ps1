<#
.SYNOPSIS
    Restore Web Search in Start to its pre-toolkit state captured by
    disable-web-search-start.ps1.

.DESCRIPTION
    Restores BingSearchEnabled + CortanaConsent + DisableWebSearch from
    their manifest entries. Falls back to Remove-ItemProperty for
    entries not in the manifest.

    Anti-cheat impact: NONE — pair-symmetric.
    Reboot required: NO — Explorer picks up on next sign-in.
    Disk impact: NONE.

.NOTES
    Tier: Safe (restores Start search default)
    Pair: disable-web-search-start.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable Web Search in Start'
UI-Header -Title 'Restore Web Search in Start Menu'
UI-RequireAdmin -ScriptName 'Enable Web Search'

Initialize-ToolkitState | Out-Null

$entries = @(
    @{ Id = 'reg:BingSearchEnabled'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled' }
    @{ Id = 'reg:CortanaConsent'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'CortanaConsent' }
    @{ Id = 'reg:DisableWebSearch'; Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'DisableWebSearch' }
)

foreach ($e in $entries) {
    if (-not $PSCmdlet.ShouldProcess("$($e.Path)\$($e.Name)", 'Restore or remove')) {
        UI-Skip -Label $e.Id -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "Restoring $($e.Id)" -Action {
        if (-not (Restore-ToolkitRegistryValue -Id $e.Id)) {
            if (Test-Path $e.Path) {
                Remove-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction SilentlyContinue
            }
        }
    }.GetNewClosure()
}

UI-Summary -DoneMessage 'Web search in Start restored to default'
UI-Exit
