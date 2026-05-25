<#
.SYNOPSIS
    Restore the pagefile to its pre-toolkit state (typically
    AutomaticManagedPagefile = true) captured by configure-pagefile.ps1.

.DESCRIPTION
    Reads the 'pagefile' sidecar:
      - If pre-change AutomaticManagedPagefile was $true, re-enable it.
      - Otherwise, restore each captured Win32_PageFileSetting record
        to its prior InitialSize / MaximumSize.
    Falls back to "re-enable AutomaticManagedPagefile" when sidecar
    is missing (safe default).

    Sidecar is removed at the end.

    Anti-cheat impact: NONE — pair-symmetric.
    Reboot required: YES — pagefile changes apply on next boot.
    Disk impact: NONE direct (Windows resizes pagefile.sys at boot).

.NOTES
    Tier: Safe (restores default; reboot needed for resize to settle)
    Pair: configure-pagefile.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Revert Pagefile'
UI-Header -Title 'Revert Pagefile to Pre-Toolkit State'
UI-RequireAdmin -ScriptName 'Revert Pagefile'

Initialize-ToolkitState | Out-Null

$snapshot = Read-ToolkitSidecar -Name 'pagefile'
$useAutoManaged = $true
if ($snapshot) {
    $useAutoManaged = [bool]$snapshot.AutomaticManagedPagefile
}

if ($useAutoManaged) {
    UI-Note -Message 'Restoring AutomaticManagedPagefile = $true (Windows default).'
    if (-not $PSCmdlet.ShouldProcess('Win32_ComputerSystem.AutomaticManagedPagefile', 'Set $true')) {
        UI-Skip -Label 'Restore pagefile' -Reason '-WhatIf preview'
        UI-Exit
        exit 0
    }
    UI-Step -Label 'Re-enabling AutomaticManagedPagefile' -Action {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        if (-not $cs.AutomaticManagedPagefile) {
            Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $true } -ErrorAction Stop
        }
    }
} else {
    UI-Note -Message 'Restoring pre-toolkit custom pagefile sizes from sidecar.'
    foreach ($entry in $snapshot.PagefileSettings) {
        $desc = "$($entry.Name) → Initial=$($entry.InitialSize) MB / Max=$($entry.MaximumSize) MB"
        if (-not $PSCmdlet.ShouldProcess($desc, 'Set Win32_PageFileSetting')) {
            UI-Skip -Label $desc -Reason '-WhatIf preview'
            continue
        }
        UI-Step -Label "Restoring $desc" -Action {
            $existing = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "Name='$($entry.Name -replace '\\', '\\\\')'" -ErrorAction SilentlyContinue
            if ($existing) {
                Set-CimInstance -InputObject $existing -Property @{
                    InitialSize = $entry.InitialSize
                    MaximumSize = $entry.MaximumSize
                } -ErrorAction Stop
            }
        }.GetNewClosure()
    }
}

Remove-ToolkitSidecar -Name 'pagefile'

Add-ToolkitStepResult -Key 'pagefile-sizing-revert' -Tier 'Safe' -Status 'applied' `
    -Reason ('Pagefile restored to ' + $(if ($useAutoManaged) { 'AutomaticManagedPagefile' } else { 'sidecar-captured custom sizes' }))

UI-Summary -DoneMessage 'Pagefile reverted' -Details @(
    'REBOOT REQUIRED — pagefile size changes apply on next boot.'
)
UI-Exit
