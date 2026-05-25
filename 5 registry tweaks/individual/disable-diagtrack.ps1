<#
.SYNOPSIS
    Disable the DiagTrack (Connected User Experiences and Telemetry)
    service — stops it, sets startup to Disabled, captures prior state.

.DESCRIPTION
    DiagTrack is the Windows service that uploads diagnostic data to
    Microsoft. Disabling it is the strongest cut at the service layer
    (the AllowTelemetry policy is a softer one — see
    disable-allow-telemetry.ps1).

    What changes:
      - Stop-Service DiagTrack (if running)
      - Set-ToolkitServiceStartMode DiagTrack Disabled (manifest-tracked)

    Pair: enable-diagtrack.ps1 (restores prior start mode via manifest)

.NOTES
    Tier: Advanced
    Anti-cheat impact: NONE. DiagTrack is the user-mode telemetry
        upload service; not inspected by BattlEye / EAC / similar.
    Source: https://learn.microsoft.com/en-us/windows/privacy/manage-windows-1809-endpoints
            https://learn.microsoft.com/en-us/windows/configuration/manage-connections-from-windows-operating-system-components-to-microsoft-services
    Pair: enable-diagtrack.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable DiagTrack'
UI-Header -Title 'Disable DiagTrack Service' -Subtitle 'Connected User Experiences and Telemetry'
UI-RequireAdmin -ScriptName 'Disable DiagTrack'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$svcName = 'DiagTrack'
$svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
if (-not $svc) {
    UI-Note -Message "[SKIP] '$svcName' service not present on this Windows edition." -Color $script:UI_Warning
    UI-Exit
    exit 0
}

# Hoist ShouldProcess (canonical pattern) before entering UI-Step.
if (-not $PSCmdlet.ShouldProcess("Service '$svcName'", 'Stop + Set-StartMode Disabled')) {
    UI-Skip -Label 'Disable DiagTrack' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label "Stopping $svcName (if running)" -Action {
    if ($svc.Status -eq 'Running') {
        Stop-Service -Name $svcName -Force -ErrorAction Stop
    }
}

UI-Step -Label "Setting $svcName start mode to Disabled (tracked)" -Action {
    Set-ToolkitServiceStartMode -Name $svcName -StartMode 'Disabled' -Tier 'Advanced' -Step 'telemetry-diagtrack'
}

UI-Summary -DoneMessage 'DiagTrack disabled' -Details @(
    'Telemetry uploads stop at the service layer.',
    'Apply disable-allow-telemetry.ps1 too if you want the GPO-level cut.'
) -RevertHint 'Run enable-diagtrack.ps1 in this folder.'
UI-Exit
