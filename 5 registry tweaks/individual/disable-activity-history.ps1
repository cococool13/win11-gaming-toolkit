<#
.SYNOPSIS
    Disable Windows Activity History (Timeline) via the documented
    EnableActivityFeed group policy.

.DESCRIPTION
    Three values at HKLM:\SOFTWARE\Policies\Microsoft\Windows\System:
      EnableActivityFeed     = 0   (no local activity collection)
      PublishUserActivities  = 0   (no publishing to Activity API)
      UploadUserActivities   = 0   (no upload to Microsoft Graph)

    Together they stop Activity History entirely at the policy layer.

    Anti-cheat impact: NONE — System policy values, no kernel hooks.
    Reboot required: NO — picks up on next sign-in.
    Disk impact: NONE (registry only).

.NOTES
    Tier: Safe
    Pair: enable-activity-history.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/configuration/windows-diagnostic-data
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable Activity History'
UI-Header -Title 'Disable Activity History (Timeline)' -Subtitle '3 GPO values'
UI-RequireAdmin -ScriptName 'Disable Activity History'

Initialize-ToolkitState | Out-Null

$base = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$writes = @(
    @{ Id = 'reg:EnableActivityFeed'; Name = 'EnableActivityFeed' }
    @{ Id = 'reg:PublishUserActivities'; Name = 'PublishUserActivities' }
    @{ Id = 'reg:UploadUserActivities'; Name = 'UploadUserActivities' }
)

foreach ($w in $writes) {
    if (-not $PSCmdlet.ShouldProcess("$base\$($w.Name)", 'Set 0')) {
        UI-Skip -Label $w.Id -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "Writing $($w.Id) = 0" -Action {
        Set-ToolkitRegistryValue -Id $w.Id `
            -Path $base -Name $w.Name `
            -Value 0 -Type 'DWord' `
            -Tier 'Safe' -Step 'activity-history'
    }.GetNewClosure()
}

UI-Summary -DoneMessage 'Activity History disabled' -RevertHint 'Run enable-activity-history.ps1.'
UI-Exit
