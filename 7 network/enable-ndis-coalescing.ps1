<#
.SYNOPSIS
    Re-enable NDIS IRQ coalescing per the 'ndis-coalesce' sidecar
    captured by disable-ndis-coalescing.ps1.

.DESCRIPTION
    Reads the ndis-coalesce sidecar (per-adapter / per-property
    DisplayValue + RegistryValue) and restores each to the captured
    pre-toolkit value via Set-NetAdapterAdvancedProperty.

    Sidecar is removed at the end.

    Anti-cheat impact: NONE — pair-symmetric with disable side.
    Reboot required: NO. Set-NetAdapterAdvancedProperty applies live.
    Disk impact: LOW (reads + deletes the ndis-coalesce sidecar).

.NOTES
    Tier: Safe (restores prior NDIS coalescing values)
    Pair: disable-ndis-coalescing.ps1

    # CROSS-PLATFORM-NOTE
    # Windows-only.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable NDIS Coalescing'
UI-Header -Title 'Re-enable NDIS Coalescing' -Subtitle 'Sidecar-driven restore'
UI-RequireAdmin -ScriptName 'Enable NDIS Coalescing'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not (Get-Command Set-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue)) {
    UI-Note -Message '[SKIP] NetAdapter cmdlets unavailable.' -Color $script:UI_Warning
    UI-Exit
    exit 1
}

$snapshot = Read-ToolkitSidecar -Name 'ndis-coalesce'
if (-not $snapshot) {
    UI-Note -Message "No 'ndis-coalesce' sidecar — nothing to restore." -Color $script:UI_Warning
    UI-Exit
    exit 0
}

foreach ($entry in $snapshot) {
    $desc = "$($entry.Name)/$($entry.Property) → $($entry.DisplayValue)"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Set-NetAdapterAdvancedProperty (restore)')) {
        UI-Skip -Label $desc -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "Restoring $desc" -Action {
        try {
            Set-NetAdapterAdvancedProperty -Name $entry.Name `
                -RegistryKeyword $entry.Property `
                -DisplayValue $entry.DisplayValue -ErrorAction Stop
        } catch {
            # DisplayValue restore can fail if the friendly value
            # changed between driver versions; fall back to numeric.
            if ($null -ne $entry.RegistryValue) {
                Set-NetAdapterAdvancedProperty -Name $entry.Name `
                    -RegistryKeyword $entry.Property `
                    -RegistryValue $entry.RegistryValue -ErrorAction SilentlyContinue
            }
        }
    }.GetNewClosure()
}

Remove-ToolkitSidecar -Name 'ndis-coalesce'

Add-ToolkitStepResult -Key 'ndis-coalesce-revert' -Tier 'Safe' -Status 'applied' `
    -Reason "Restored $($snapshot.Count) NDIS coalescing property/adapter pair(s)"

UI-Summary -DoneMessage 'NDIS coalescing restored'
UI-Exit
