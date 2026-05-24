# ============================================================
# Disable SMT / Hyper-Threading (CARGO-CULT, opt-in)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/8 Smt Ht.ps1
# Copyright FR33THY (MIT)
# ============================================================
# Tier: Security Trade-off (workload-disruptive)
#
# === CARGO-CULT WARNING ===
# Disabling SMT (Intel: Hyper-Threading) on modern Ryzen / 13th-14th
# gen Intel / Core Ultra CPUs measurably HURTS multi-thread performance
# in nearly all 2025-era games. The CPU's logical cores are no longer
# the gaming bottleneck they once were on 4-thread quad-cores.
#
# Sources: TechPowerUp 2024 SMT/HT benchmark roundups, AMD's own
# 7000-series guidance, Linus Tech Tips multi-game test 2024-09.
#
# Shipped because the toolkit's design philosophy is "nothing is
# permanently off-limits" — but the empirical case AGAINST disabling
# SMT is loud, and most users who genuinely benefit are workload-
# specific cases (some pre-2018 sims, niche CPU-bound emulators).
# Faster path: do it from BIOS if you really need it — toggling at
# runtime via bcdedit is slower and less reliable.
#
# Implementation: bcdedit /set numproc <physicalCoreCount> limits the
# Windows boot to N processors. Setting N = physical core count
# effectively disables SMT/HT at the Windows scheduler level.
# Reboot REQUIRED. Revert: enable-smt-ht.ps1 removes the override.
#
# Pass -Force to skip the confirmation prompt (scripted use).
# Must be run as Administrator.
# ============================================================

param([switch]$Force)

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Disable SMT / Hyper-Threading" -Subtitle "CARGO-CULT — opt-in only"
UI-RequireAdmin -ScriptName "Disable SMT / Hyper-Threading"

if (-not $Force) {
    Write-Host "  CARGO-CULT WARNING:" -ForegroundColor Red
    Write-Host "    On modern Ryzen / 13th-14th gen Intel / Core Ultra CPUs," -ForegroundColor Yellow
    Write-Host "    disabling SMT measurably HURTS multi-thread performance" -ForegroundColor Yellow
    Write-Host "    in nearly all 2025-era games. Most users should not run" -ForegroundColor Yellow
    Write-Host "    this script." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    If you genuinely need SMT off (pre-2018 sims, niche" -ForegroundColor Yellow
    Write-Host "    CPU-bound emulators), prefer doing it from BIOS." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Revert: run enable-smt-ht.ps1 in this folder." -ForegroundColor Gray
    Write-Host ""
    $proceed = Read-Host "  Continue? (y/N)"
    if ($proceed.Trim().ToUpper() -ne "Y") {
        Write-Host "  Cancelled." -ForegroundColor Gray
        exit 0
    }
    Write-Host ""
}

Initialize-ToolkitState | Out-Null
$stepName = "cpu-smt-disable"

# Detect physical core count (NOT logical / thread count)
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$physicalCores = [int]$cpu.NumberOfCores
$logicalCores = [int]$cpu.NumberOfLogicalProcessors

Write-Host "  CPU: $($cpu.Name)" -ForegroundColor Gray
Write-Host "  Physical cores: $physicalCores  Logical (SMT) cores: $logicalCores" -ForegroundColor Gray

if ($physicalCores -lt 1 -or $logicalCores -le $physicalCores) {
    Write-Host "  [SKIP] CPU does not report SMT (logical = physical). Nothing to do." -ForegroundColor Yellow
    Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "skipped" -Reason "No SMT detected"
    exit 0
}

Write-Host ""
Write-Host "  Limiting Windows boot to $physicalCores processors via bcdedit /set numproc..." -ForegroundColor Yellow
$bcdOutput = & bcdedit.exe /set "{current}" numproc $physicalCores 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] bcdedit failed: $bcdOutput" -ForegroundColor Red
    Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "failed" -Reason "bcdedit error: $bcdOutput"
    exit 1
}

Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "applied" `
    -Reason "BCD numproc = $physicalCores (was: $logicalCores)"

Write-Host ""
Write-Host "  [DONE] SMT disabled at the scheduler level." -ForegroundColor Green
Write-Host "  REBOOT REQUIRED for the change to take effect." -ForegroundColor Yellow
Write-Host "  Revert: enable-smt-ht.ps1 (or REVERT-EVERYTHING.ps1)." -ForegroundColor Gray
Read-Host "Press Enter to exit"
