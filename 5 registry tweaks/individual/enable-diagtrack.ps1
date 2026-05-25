<#
.SYNOPSIS
    Re-enable the DiagTrack service to its pre-toolkit start mode
    captured by disable-diagtrack.ps1.

.DESCRIPTION
    Restores DiagTrack from the manifest entry recorded by
    disable-diagtrack.ps1 (typically AutomaticDelayedStart on a
    factory Windows 11 install). If no manifest entry exists,
    sets the service to Automatic with a delayed start as a safe
    Windows-default approximation.

.NOTES
    Tier: Safe (returns to OS default telemetry path)
    Anti-cheat impact: NONE — DiagTrack is user-mode telemetry upload;
        not inspected by BattlEye / EAC / similar.
    Pair: disable-diagtrack.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable DiagTrack'
UI-Header -Title 'Re-enable DiagTrack Service' -Subtitle 'Restore prior start mode'
UI-RequireAdmin -ScriptName 'Enable DiagTrack'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$svcName = 'DiagTrack'
if (-not (Get-Service -Name $svcName -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[SKIP] '$svcName' not present on this Windows edition." -Color $script:UI_Warning
    UI-Exit
    exit 0
}

if (-not $PSCmdlet.ShouldProcess("Service '$svcName'", 'Restore start mode + Start-Service')) {
    UI-Skip -Label 'Enable DiagTrack' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label "Restoring $svcName start mode" -Action {
    # Restore-ToolkitServiceStartMode returns $true if it restored from
    # manifest, $false if no entry — fall back to Manual (a safe middle
    # ground; AutomaticDelayedStart can't be set via Set-Service alone).
    if (-not (Restore-ToolkitServiceStartMode -Name $svcName)) {
        Set-Service -Name $svcName -StartupType Manual -ErrorAction Stop
        UI-Note -Message 'No manifest entry — defaulted to Manual.' -Color $script:UI_Info
    }
}

UI-Step -Label "Starting $svcName" -Action {
    Start-Service -Name $svcName -ErrorAction Stop
}

UI-Summary -DoneMessage 'DiagTrack restored' -Details @(
    'Telemetry uploads resume on the OS schedule.'
) -RevertHint 'Run disable-diagtrack.ps1 to disable again.'
UI-Exit
