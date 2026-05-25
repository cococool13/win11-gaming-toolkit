<#
.SYNOPSIS
    Re-enable Receive Segment Coalescing (RSC) per the rsc-coalesce
    sidecar captured by disable-rsc.ps1.

.DESCRIPTION
    Reads the rsc-coalesce sidecar (per-adapter IPv4Enabled +
    IPv6Enabled flags) and restores each adapter to its pre-toolkit
    state via Enable-NetAdapterRsc / Disable-NetAdapterRsc as
    appropriate. Falls back to a blanket Enable-NetAdapterRsc when
    the sidecar is missing (factory default is RSC on).

    Sidecar is removed at the end so a future disable can capture a
    fresh baseline.

    Anti-cheat impact: NONE — pair-symmetric with disable-rsc.ps1.
    Reboot required: NO. Set-NetAdapterRsc applies live.
    Disk impact: LOW (reads + deletes the rsc-coalesce sidecar JSON).

.NOTES
    Tier: Safe (restores OS default RSC state)
    Pair: disable-rsc.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/powershell/module/netadapter/enable-netadapterrsc

    # CROSS-PLATFORM-NOTE
    # Windows-only.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Enable RSC'
UI-Header -Title 'Re-enable RSC' -Subtitle 'Sidecar-driven restore'
UI-RequireAdmin -ScriptName 'Enable RSC'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not (Get-Command Enable-NetAdapterRsc -ErrorAction SilentlyContinue)) {
    UI-Note -Message '[SKIP] NetAdapter cmdlets unavailable.' -Color $script:UI_Warning
    UI-Exit
    exit 1
}

$snapshot = Read-ToolkitSidecar -Name 'rsc-coalesce'
if (-not $snapshot) {
    UI-Note -Message "No 'rsc-coalesce' sidecar — applying blanket RSC=enabled on Up adapters." -Color $script:UI_Warning
    $snapshot = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
            [PSCustomObject]@{ Name = $_.Name; IPv4Enabled = $true; IPv6Enabled = $true }
        })
}

foreach ($entry in $snapshot) {
    $desc = "$($entry.Name) → IPv4=$($entry.IPv4Enabled) IPv6=$($entry.IPv6Enabled)"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Enable/Disable-NetAdapterRsc')) {
        UI-Skip -Label $entry.Name -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "$($entry.Name) — restore" -Action {
        if ($entry.IPv4Enabled) {
            Enable-NetAdapterRsc -Name $entry.Name -IPv4 -ErrorAction SilentlyContinue
        } else {
            Disable-NetAdapterRsc -Name $entry.Name -IPv4 -ErrorAction SilentlyContinue
        }
        if ($entry.IPv6Enabled) {
            Enable-NetAdapterRsc -Name $entry.Name -IPv6 -ErrorAction SilentlyContinue
        } else {
            Disable-NetAdapterRsc -Name $entry.Name -IPv6 -ErrorAction SilentlyContinue
        }
    }.GetNewClosure()
}

Remove-ToolkitSidecar -Name 'rsc-coalesce'

Add-ToolkitStepResult -Key 'rsc-disable-revert' -Tier 'Safe' -Status 'applied' `
    -Reason "RSC restored on $($snapshot.Count) adapter(s) from sidecar"

UI-Summary -DoneMessage 'RSC restored on active adapters'
UI-Exit
