# ============================================================
# Pin explorer.exe to Core 1 (CARGO-CULT, opt-in)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/9 Core 1 Thread 1.ps1
# Copyright FR33THY (MIT)
# ============================================================
# Tier: Advanced
#
# === CARGO-CULT WARNING ===
# Pinning Explorer to a single logical core (CPU0) is a long-standing
# myth from the Win7 era. It produces ZERO measurable game-FPS benefit
# on Win11 24H2+ and can cause UI hitches when Explorer competes with
# other CPU0-pinned threads (audio driver, RTC, etc.).
#
# Documented here for completeness — the toolkit's design philosophy
# is "nothing permanently off-limits" and a user who specifically
# wants this can opt in. The empirical case against is at the top of
# the script so they make an informed choice.
#
# Implementation: writes ImagePath\explorer.exe\CpuPriorityClass and
# AffinityMask under HKLM\...\Image File Execution Options. Affinity
# mask 1 = bit 0 only = CPU0.
#
# Pass -Force to skip the confirmation prompt.
# Must be run as Administrator.
# Pair: restore-explorer-affinity.ps1
# ============================================================

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
    Write-Host "    Revert: run restore-explorer-affinity.ps1." -ForegroundColor Gray
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
