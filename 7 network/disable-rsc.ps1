<#
.SYNOPSIS
    Disable Receive Segment Coalescing (RSC) on every active NIC.
    RSC combines incoming TCP segments at the adapter to reduce CPU
    interrupt load — at the cost of added latency.

.DESCRIPTION
    RSC is a NIC-driver feature that batches small consecutive TCP
    receive segments into one larger pseudo-segment before passing
    them up the IP stack. The CPU sees fewer interrupts and processes
    less per-packet overhead, which helps bulk throughput (file
    transfers, video streaming) — but adds 1-5ms of latency to
    individual segments because the batching adds a coalescing window.

    For competitive gaming, that extra latency on EVERY received
    server frame is a real cost. Disabling RSC trades a small CPU
    overhead bump for ~1-5ms lower receive-side latency. Worth it on
    1Gb+ Ethernet where the CPU overhead is already negligible on
    modern silicon.

    Per-adapter state is captured to a sidecar JSON ('rsc-coalesce-before')
    so enable-rsc.ps1 can restore exactly what each adapter had before.

    Anti-cheat impact: NONE. NIC driver advanced property; below the
    IP stack, no game-process surface.
    Reboot required: NO. Set-NetAdapterRsc applies live.
    Disk impact: LOW (~1 KB sidecar per adapter for per-adapter
    baseline capture).

.NOTES
    Tier: Advanced
    Pair: enable-rsc.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows-hardware/drivers/network/receive-segment-coalescing--rsc-
      https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapterrsc

    # CROSS-PLATFORM-NOTE
    # Windows-only (Set-NetAdapterRsc).
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable RSC'
UI-Header -Title 'Disable Receive Segment Coalescing (RSC)' -Subtitle 'Lower receive latency, slightly higher CPU'
UI-RequireAdmin -ScriptName 'Disable RSC'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not (Get-Command Get-NetAdapterRsc -ErrorAction SilentlyContinue)) {
    UI-Note -Message '[SKIP] NetAdapter cmdlets unavailable on this Windows edition.' -Color $script:UI_Warning
    UI-Exit
    exit 1
}

# Capture per-adapter state to sidecar so enable-rsc can restore.
$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
if ($adapters.Count -eq 0) {
    UI-Note -Message 'No active adapters; nothing to do.' -Color $script:UI_Warning
    UI-Exit
    exit 0
}

$snapshot = foreach ($a in $adapters) {
    $rsc = Get-NetAdapterRsc -Name $a.Name -ErrorAction SilentlyContinue
    if ($rsc) {
        [PSCustomObject]@{
            Name = $a.Name
            IPv4Enabled = $rsc.IPv4Enabled
            IPv6Enabled = $rsc.IPv6Enabled
        }
    }
}
$saved = Save-ToolkitSidecar -Name 'rsc-coalesce' -InputObject $snapshot
if ($saved) {
    UI-Note -Message "Captured $($snapshot.Count) adapter RSC baseline at $saved"
}

foreach ($entry in $snapshot) {
    if (-not $PSCmdlet.ShouldProcess($entry.Name, 'Disable-NetAdapterRsc -IPv4 -IPv6')) {
        UI-Skip -Label $entry.Name -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "$($entry.Name) — disable RSC" -Action {
        Disable-NetAdapterRsc -Name $entry.Name -IPv4 -IPv6 -ErrorAction SilentlyContinue
    }.GetNewClosure()
}

Add-ToolkitStepResult -Key 'rsc-disable' -Tier 'Advanced' -Status 'applied' `
    -Reason "RSC disabled on $($snapshot.Count) active adapter(s)"

UI-Summary -DoneMessage 'RSC disabled on active adapters' -Details @(
    'Receive latency drops 1-5ms per packet at the cost of slightly higher CPU.',
    'Pair with disable-rss-tuning.ps1 / disable-interrupt-moderation.ps1 for full receive-path tuning.'
) -RevertHint 'Run enable-rsc.ps1 in this folder.'
UI-Exit
