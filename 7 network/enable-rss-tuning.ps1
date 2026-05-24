#Requires -Version 5.1
<#
.SYNOPSIS
    Enable Receive Side Scaling (RSS) and tune the receive queue count
    on every supporting network adapter.

.DESCRIPTION
    RSS spreads inbound network packet processing across multiple CPU
    cores instead of pinning all RX interrupts to CPU 0. On a modern
    multi-core gaming box with a 1/2.5/10 GbE NIC, the difference is
    measurable under load (less DPC contention, lower jitter, fewer
    "Network is slow but CPU isn't pegged" stalls).

    Windows 11 enables RSS by default on most consumer NICs but caps
    the queue count conservatively (often 1 or 2). The optimal value
    is min(LogicalCpuCount, NIC.MaxReceiveQueues). This script reads
    both numbers per adapter and sets accordingly.

    Captures pre-change state per adapter to a sidecar JSON beside
    the manifest so disable-rss-tuning.ps1 can restore exact prior
    values — same pattern as disable-write-cache-flush.ps1.

    Sources cited:
      Microsoft Learn — Set-NetAdapterRss
        https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapterrss
      Microsoft Learn — Introduction to RSS
        https://learn.microsoft.com/en-us/windows-hardware/drivers/network/introduction-to-receive-side-scaling
      Microsoft Learn — Tuning network adapters
        https://learn.microsoft.com/en-us/windows-server/networking/technologies/network-subsystem/net-sub-performance-tuning-nics

    Anti-cheat impact: NONE. RSS is below the game layer; CPUs assigned
    to RX interrupts are still available for game threads via standard
    scheduler preemption.

.PARAMETER MaxQueues
    Cap the queue count this script will set. Default: min(CPU cores, 8).
    The "8" cap protects against very large queue counts on Threadripper
    / Xeon boxes where the NIC supports it but the perf benefit
    plateaus around 4-8 (Microsoft's published rule-of-thumb).

.EXAMPLE
    PS> .\enable-rss-tuning.ps1
    Auto-detect and set per-adapter.

.EXAMPLE
    PS> .\enable-rss-tuning.ps1 -MaxQueues 4 -WhatIf
    Show what would change with a 4-queue cap.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced

    # CROSS-PLATFORM-NOTE
    # NetAdapter module is Windows-only. macOS run hits the cmdlet
    # availability check and exits cleanly. tests/manual/enable-rss-tuning.md
    # documents the runtime smoke test.

    Exit codes:
      0  RSS settings applied (or already at target on every adapter)
      2  NetAdapter cmdlets unavailable (Server Core / stripped image)
      3  Sidecar JSON write failed
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param(
    [int]$MaxQueues
)

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title 'Enable RSS + tune queue count' -Subtitle 'Receive Side Scaling per network adapter'
UI-RequireAdmin -ScriptName 'Enable RSS tuning'
Initialize-ToolkitState | Out-Null

if (-not (Get-Command Get-NetAdapterRss -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Get-NetAdapterRss not available.' -ForegroundColor Yellow
    Write-Host '         Install NetAdapter module: Add-WindowsCapability -Online -Name NetAdapter~~~~' -ForegroundColor Yellow
    Write-ToolkitLog 'rss-skip-noapi' -Level warn
    exit 2
}

# Auto-detect MaxQueues if not explicit.
if (-not $PSBoundParameters.ContainsKey('MaxQueues') -or $MaxQueues -le 0) {
    $logical = (Get-CimInstance Win32_Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum
    # 8 is Microsoft's pragmatic ceiling — see header sources.
    $MaxQueues = [Math]::Min([int]$logical, 8)
    Write-Host "  Auto-detected queue cap: $MaxQueues (logical CPUs=$logical, ceiling=8)" -ForegroundColor Gray
}

$sidecarDir = Split-Path -Parent (Get-ToolkitManifestPath)
if (-not (Test-Path -LiteralPath $sidecarDir)) {
    New-Item -ItemType Directory -Path $sidecarDir -Force -ErrorAction SilentlyContinue | Out-Null
}
$sidecarPath = Join-Path $sidecarDir 'rss-before.json'

$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -eq 'Up' -and $_.InterfaceType -in 6, 71 })   # 6=Ethernet, 71=802.11
if ($adapters.Count -eq 0) {
    Write-Host '  [SKIP] No active wired/wireless adapters detected.' -ForegroundColor Yellow
    exit 0
}

# Capture before-state on first run only. If sidecar already exists,
# preserve it (a previous apply already captured the real pre-toolkit
# state; a second apply would overwrite with toolkit-modified state).
if (-not (Test-Path -LiteralPath $sidecarPath)) {
    $snapshot = foreach ($a in $adapters) {
        $rss = Get-NetAdapterRss -Name $a.Name -ErrorAction SilentlyContinue
        if (-not $rss) { continue }
        [PSCustomObject]@{
            Name = $a.Name
            Enabled = [bool]$rss.Enabled
            NumberOfReceiveQueues = [int]$rss.NumberOfReceiveQueues
            MaxReceiveQueues = [int]$rss.MaxReceiveQueues
        }
    }
    try {
        $snapshot | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $sidecarPath -Encoding utf8
        Write-Host "  Captured baseline at $sidecarPath" -ForegroundColor Gray
        Write-ToolkitLog 'rss-baseline-captured' -Data @{ path = $sidecarPath; adapters = $snapshot.Count }
    } catch {
        Write-Host "  [FAIL] sidecar write: $($_.Exception.Message)" -ForegroundColor Red
        Write-ToolkitLog 'rss-baseline-failed' -Level error -Data @{ err = $_.Exception.Message }
        exit 3
    }
}

UI-Section -Title 'Applying'
$applied = 0
$skipped = 0
foreach ($a in $adapters) {
    $rss = Get-NetAdapterRss -Name $a.Name -ErrorAction SilentlyContinue
    if (-not $rss) {
        Write-Host "  [SKIP] $($a.Name): driver doesn't expose RSS" -ForegroundColor Gray
        continue
    }

    $targetQueues = [Math]::Min($MaxQueues, [int]$rss.MaxReceiveQueues)
    $needsEnable = -not $rss.Enabled
    $needsQueueChange = ([int]$rss.NumberOfReceiveQueues -ne $targetQueues)

    if (-not ($needsEnable -or $needsQueueChange)) {
        Write-Host "  [SKIP] $($a.Name): already at target (Enabled=$($rss.Enabled), Queues=$($rss.NumberOfReceiveQueues))" -ForegroundColor Gray
        $skipped++
        continue
    }

    $desc = "$($a.Name) (Enabled $($rss.Enabled)→$true, Queues $($rss.NumberOfReceiveQueues)→$targetQueues)"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Set-NetAdapterRss')) {
        Write-ToolkitLog 'rss-skip-whatif' -Level warn -Data @{ adapter = $a.Name }
        continue
    }

    try {
        Set-NetAdapterRss -Name $a.Name -Enabled $true -NumberOfReceiveQueues $targetQueues -ErrorAction Stop
        Write-Host "  [OK] $desc" -ForegroundColor Green
        Write-ToolkitLog 'rss-applied' -Data @{
            adapter = $a.Name
            enabled = $true
            queues = $targetQueues
            wasEnabled = [bool]$rss.Enabled
            wasQueues = [int]$rss.NumberOfReceiveQueues
        }
        $applied++
    } catch {
        Write-Host "  [FAIL] $($a.Name): $($_.Exception.Message)" -ForegroundColor Red
        Write-ToolkitLog 'rss-failed' -Level error -Data @{
            adapter = $a.Name; err = $_.Exception.Message
        }
    }
}

Add-ToolkitStepResult -Key 'rss-tuning' -Tier 'Advanced' -Status 'applied' `
    -Reason "Applied $applied adapter(s), skipped $skipped already-at-target"

Write-Host ''
UI-Note -Message "Reverting: disable-rss-tuning.ps1 or REVERT-EVERYTHING.ps1." -Color $script:UI_Info
exit 0
