<#
.SYNOPSIS
    Disable Windows diagnostic data collection at the Group Policy
    layer by setting AllowTelemetry = 0 (Security/Off).

.DESCRIPTION
    The documented Microsoft mechanism for controlling diagnostic data
    is the AllowTelemetry GPO value at:
        HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection
    Set to:
        0 = Security (Enterprise/Server SKUs only — falls back to
            Required-Diagnostic on Pro/Home; the lowest the SKU permits)
        1 = Required
        2 = Enhanced (deprecated)
        3 = Optional (factory default on consumer SKUs)

    Toolkit writes 0 (Security). On Pro/Home this effectively becomes
    Required (the SKU floor). This is the policy-layer cut, distinct
    from the service-layer cut of disable-diagtrack.ps1 — applying
    both gives the strongest practical reduction.

    Tracked via Set-ToolkitRegistryValue so the prior value can be
    restored exactly by enable-allow-telemetry.ps1 or the manifest
    rollback.

.NOTES
    Tier: Advanced
    Anti-cheat impact: NONE. AllowTelemetry is a GPO value read by
        the DiagTrack service; not inspected by BattlEye / EAC /
        similar. Independent of the service-start cut.
    Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
    Disk impact: NONE — registry-only write; no on-disk file creation.
    Source: https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
    Pair: enable-allow-telemetry.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable AllowTelemetry'
UI-Header -Title 'Set AllowTelemetry = 0' -Subtitle 'Group Policy layer — lowest SKU allows'
UI-RequireAdmin -ScriptName 'Disable AllowTelemetry'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not $PSCmdlet.ShouldProcess('HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry', 'Set to 0 (Security)')) {
    UI-Skip -Label 'Set AllowTelemetry' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Writing AllowTelemetry = 0 (tracked)' -Action {
    Set-ToolkitRegistryValue `
        -Id 'reg:AllowTelemetry' `
        -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
        -Name 'AllowTelemetry' `
        -Value 0 -Type 'DWord' `
        -Tier 'Advanced' -Step 'telemetry-policy'
}

UI-Summary -DoneMessage 'AllowTelemetry policy applied' -Details @(
    'On Pro/Home this effectively becomes Required (the SKU floor).',
    'Apply disable-diagtrack.ps1 too for the service-layer cut.'
) -RevertHint 'Run enable-allow-telemetry.ps1 in this folder.'
UI-Exit
