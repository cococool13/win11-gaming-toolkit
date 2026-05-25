<#
.SYNOPSIS
    Restore the AllowTelemetry policy value to its pre-toolkit state
    captured by disable-allow-telemetry.ps1.

.DESCRIPTION
    Tries Restore-ToolkitRegistryValue against the manifest entry
    'reg:AllowTelemetry'. If no manifest entry exists (e.g. running
    on a fresh box that never ran disable-allow-telemetry.ps1),
    removes the value so Windows falls back to its SKU default
    (3 = Optional on consumer SKUs).

.NOTES
    Tier: Safe (returns to OS default telemetry policy)
    Anti-cheat impact: NONE — GPO value at DataCollection key; not
        inspected by anti-cheat layers.
    Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
    Disk impact: NONE — registry-only write; no on-disk file creation.
    Pair: disable-allow-telemetry.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable AllowTelemetry'
UI-Header -Title 'Restore AllowTelemetry policy' -Subtitle 'Return to SKU default'
UI-RequireAdmin -ScriptName 'Enable AllowTelemetry'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

if (-not $PSCmdlet.ShouldProcess("$path\AllowTelemetry", 'Restore from manifest or remove override')) {
    UI-Skip -Label 'Restore AllowTelemetry' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

UI-Step -Label 'Restoring AllowTelemetry policy value' -Action {
    if (-not (Restore-ToolkitRegistryValue -Id 'reg:AllowTelemetry')) {
        # Pre-toolkit state had no override -> remove the value so
        # Windows reverts to the SKU default. Test-Path guards against
        # the case where the parent key was never created.
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
        }
    }
}

UI-Summary -DoneMessage 'AllowTelemetry restored' -Details @(
    'On consumer SKUs the default is 3 (Optional).',
    'Run enable-diagtrack.ps1 too if you also want the service layer back.'
)
UI-Exit
