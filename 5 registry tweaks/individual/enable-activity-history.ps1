<#
.SYNOPSIS
    Restore Activity History (Timeline) to its pre-toolkit state.

.DESCRIPTION
    Restores EnableActivityFeed + PublishUserActivities +
    UploadUserActivities from their manifest entries; removes
    overrides otherwise.

    Anti-cheat impact: NONE — pair-symmetric.
    Reboot required: NO — applies on next sign-in.
    Disk impact: NONE.

.NOTES
    Tier: Safe (restores default)
    Pair: disable-activity-history.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable Activity History'
UI-Header -Title 'Restore Activity History'
UI-RequireAdmin -ScriptName 'Enable Activity History'

Initialize-ToolkitState | Out-Null

$base = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$entries = @(
    @{ Id = 'reg:EnableActivityFeed'; Name = 'EnableActivityFeed' }
    @{ Id = 'reg:PublishUserActivities'; Name = 'PublishUserActivities' }
    @{ Id = 'reg:UploadUserActivities'; Name = 'UploadUserActivities' }
)

foreach ($e in $entries) {
    if (-not $PSCmdlet.ShouldProcess("$base\$($e.Name)", 'Restore or remove')) {
        UI-Skip -Label $e.Id -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "Restoring $($e.Id)" -Action {
        if (-not (Restore-ToolkitRegistryValue -Id $e.Id)) {
            if (Test-Path $base) {
                Remove-ItemProperty -Path $base -Name $e.Name -ErrorAction SilentlyContinue
            }
        }
    }.GetNewClosure()
}

UI-Summary -DoneMessage 'Activity History restored to default'
UI-Exit
