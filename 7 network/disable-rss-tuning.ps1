#Requires -Version 5.1
<#
.SYNOPSIS
    Restore per-adapter RSS settings from the sidecar captured by enable-rss-tuning.ps1.

.DESCRIPTION
    Pair of enable-rss-tuning.ps1. Reads rss-before.json (sidecar next
    to the manifest) and per adapter:
      - Sets Enabled back to its captured value
      - Sets NumberOfReceiveQueues back to its captured value

    Deletes the sidecar at the end so a future enable can capture a
    fresh baseline (matches the disable-write-cache-flush.ps1 pattern).

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Safe (restores prior state)
    Anti-cheat impact: NONE. RSS is below the game layer; CPUs assigned
        to receive queues are invisible to BattlEye / EAC.

    # CROSS-PLATFORM-NOTE
    # Windows-only (Set-NetAdapterRss).

    Exit codes:
      0  All adapters in the sidecar restored (or already at target)
      1  Sidecar missing — nothing to restore
      2  NetAdapter cmdlets unavailable
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title 'Restore RSS settings' -Subtitle 'Manifest-driven revert'
UI-RequireAdmin -ScriptName 'Restore RSS'
Initialize-ToolkitState | Out-Null

if (-not (Get-Command Set-NetAdapterRss -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Set-NetAdapterRss not available.' -ForegroundColor Yellow
    Write-ToolkitLog 'rss-revert-skip-noapi' -Level warn
    exit 2
}

$snapshot = Read-ToolkitSidecar -Name 'rss'
if (-not $snapshot) {
    Write-Host "  [SKIP] No 'rss' sidecar — enable-rss-tuning.ps1 never captured a baseline." -ForegroundColor Yellow
    exit 1
}

$restored = 0
$missing = 0
foreach ($entry in $snapshot) {
    $a = Get-NetAdapter -Name $entry.Name -ErrorAction SilentlyContinue
    if (-not $a) {
        Write-Host "  [SKIP] $($entry.Name): adapter no longer present" -ForegroundColor Gray
        $missing++
        continue
    }
    $desc = "$($entry.Name) (Enabled→$($entry.Enabled), Queues→$($entry.NumberOfReceiveQueues))"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Set-NetAdapterRss (restore)')) {
        continue
    }
    try {
        Set-NetAdapterRss -Name $entry.Name `
            -Enabled ([bool]$entry.Enabled) `
            -NumberOfReceiveQueues ([int]$entry.NumberOfReceiveQueues) `
            -ErrorAction Stop
        Write-Host "  [OK] $desc" -ForegroundColor Green
        Write-ToolkitLog 'rss-restored' -Data @{
            adapter = $entry.Name; enabled = $entry.Enabled; queues = $entry.NumberOfReceiveQueues
        }
        $restored++
    } catch {
        Write-Host "  [FAIL] $($entry.Name): $($_.Exception.Message)" -ForegroundColor Red
        Write-ToolkitLog 'rss-restore-failed' -Level error -Data @{
            adapter = $entry.Name; err = $_.Exception.Message
        }
    }
}

Remove-ToolkitSidecar -Name 'rss'
Add-ToolkitStepResult -Key 'rss-tuning-revert' -Tier 'Safe' -Status 'applied' `
    -Reason "Restored $restored adapter(s), $missing missing"
exit 0
