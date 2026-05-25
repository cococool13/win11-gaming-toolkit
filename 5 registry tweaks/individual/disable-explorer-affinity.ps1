<#
.SYNOPSIS
    Pin explorer.exe to CPU0 (single-core affinity) — opt-in
    CARGO-CULT tweak preserved for completeness.

.DESCRIPTION
    Writes CpuPriorityClass=5 and AffinityMask=1 under
    HKLM\...\Image File Execution Options\explorer.exe\PerfOptions,
    pinning Explorer's threads to logical CPU 0.

    === CARGO-CULT WARNING ===
    Pinning Explorer to a single logical core is a Win7-era myth. On
    Win11 24H2+ it produces ZERO measurable game-FPS benefit and CAN
    cause UI hitches when Explorer competes with other CPU0-pinned
    threads (audio driver, real-time clock, etc.). Shipped because
    the toolkit's design philosophy is "nothing permanently
    off-limits" — informed-choice opt-in.

    Pass -Force to skip the confirmation prompt.

.NOTES
    Tier: Advanced
    Pair: enable-explorer-affinity.ps1
    Anti-cheat impact: NONE — Image File Execution Options registry
        for explorer.exe; anti-cheat layers inspect game processes,
        not Explorer. Per-process CPU affinity hint is a user-mode
        scheduler nudge, no kernel hooks.
    Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
    Disk impact: NONE — registry-only write; no on-disk file creation.
    Source: FR33THYFR33THY/Ultimate — 8 Advanced/9 Core 1 Thread 1.ps1
            (Copyright FR33THY, MIT)
#>

param([switch]$Force)

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title "Pin explorer.exe to Core 1" -Subtitle "CARGO-CULT — opt-in only"
UI-RequireAdmin -ScriptName "Pin explorer.exe affinity"

if (-not $Force) {
    Write-Host "  CARGO-CULT WARNING:" -ForegroundColor Red
    Write-Host "    Pinning Explorer to CPU0 produces ZERO measurable game-FPS" -ForegroundColor Yellow
    Write-Host "    benefit on Win11 24H2+ and CAN cause UI hitches under load." -ForegroundColor Yellow
    Write-Host "    Documented for completeness; not recommended." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Revert: run enable-explorer-affinity.ps1." -ForegroundColor Gray
    Write-Host ""
    $proceed = Read-Host "  Continue? (y/N)"
    if ($proceed.Trim().ToUpper() -ne "Y") {
        Write-Host "  Cancelled." -ForegroundColor Gray
        exit 0
    }
    Write-Host ""
}

Initialize-ToolkitState | Out-Null
$path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions"
$stepName = "explorer-affinity"

Set-ToolkitRegistryValue -Id "reg:ExplorerCpuPriorityClass" `
    -Path $path -Name "CpuPriorityClass" -Value 5 -Type "DWord" `
    -Tier "Advanced" -Step $stepName
Set-ToolkitRegistryValue -Id "reg:ExplorerAffinityMask" `
    -Path $path -Name "AffinityMask" -Value 1 -Type "DWord" `
    -Tier "Advanced" -Step $stepName

Add-ToolkitStepResult -Key $stepName -Tier "Advanced" -Status "applied" `
    -Reason "explorer.exe pinned to CPU0 with priority class 5"

Write-Host ""
Write-Host "  [DONE] explorer.exe pinned to Core 1." -ForegroundColor Green
Write-Host "  Restart Explorer (or reboot) for the change to take effect." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
