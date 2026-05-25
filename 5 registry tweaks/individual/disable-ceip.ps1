<#
.SYNOPSIS
    Disable the Customer Experience Improvement Program (CEIP) at the
    documented SQMClient registry layer.

.DESCRIPTION
    CEIP is the older diagnostic-data program that predates the
    Connected User Experiences and Telemetry service. It still ships
    in Windows 11 for legacy compat and writes to
        HKLM\SOFTWARE\Microsoft\SQMClient\Windows\CEIPEnable
    Microsoft documents the registry mechanism for IT admins. Setting
    the value to 0 stops CEIP-style data collection at the SQM layer.

    This is independent of DiagTrack and AllowTelemetry — the three
    together represent the full per-component telemetry granularity
    most users want: service + GPO + legacy SQM all distinct toggles.

    Tracked via Set-ToolkitRegistryValue so enable-ceip.ps1 (or the
    manifest revert) restores the prior value exactly.

.NOTES
    Tier: Advanced
    Anti-cheat impact: NONE. SQMClient is the older diagnostic-data
        path; not inspected by BattlEye / EAC / similar.
    Source: https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-7/dd565638(v=ws.10)
    Pair: enable-ceip.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable CEIP'
UI-Header -Title 'Disable Customer Experience Improvement Program' -Subtitle 'SQMClient layer'
UI-RequireAdmin -ScriptName 'Disable CEIP'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not $PSCmdlet.ShouldProcess('HKLM:\SOFTWARE\Microsoft\SQMClient\Windows\CEIPEnable', 'Set to 0 (disabled)')) {
    UI-Skip -Label 'Disable CEIP' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Writing CEIPEnable = 0 (tracked)' -Action {
    Set-ToolkitRegistryValue `
        -Id 'reg:CEIPEnable' `
        -Path 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows' `
        -Name 'CEIPEnable' `
        -Value 0 -Type 'DWord' `
        -Tier 'Advanced' -Step 'telemetry-ceip'
}

UI-Summary -DoneMessage 'CEIP disabled' -Details @(
    'Legacy SQM telemetry path closed.',
    'Apply disable-diagtrack.ps1 + disable-allow-telemetry.ps1 for full coverage.'
) -RevertHint 'Run enable-ceip.ps1 in this folder.'
UI-Exit
