# ============================================================
# Wholesale Windows Defender Disable (CARGO-CULT, opt-in)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 6 Windows/33 Defender Optimize.ps1
#         + 8 Advanced/1 Defender.ps1
# Copyright FR33THY (MIT)
# ============================================================
# Tier: Security Trade-off (significant)
#
# === CARGO-CULT WARNING ===
# Wholesale Defender disable on Windows 11 24H2 is largely a no-op or
# unstable: Tamper Protection (on by default) silently reverts most of
# these registry writes within seconds. Even when writes stick, the
# scan-skip benefit on modern silicon is in the 1-3% FPS range and is
# absent entirely on Intel/AMD CPUs with VAES + SHA-NI instruction-set
# acceleration that Defender uses to keep its on-access cost minimal.
#
# RECOMMENDED ALTERNATIVE: use Defender Exclusions for game library
# paths only. APPLY-EVERYTHING.ps1 Phase 12 already adds these via
# Set-MpPreference -ExclusionPath, captured by Add-MpPreference and
# manifest-tracked for revert.
#
# Documented and shipped here per "nothing permanently off-limits".
# If a user wants this anyway, they get it; the warning ensures it's
# an informed choice.
#
# Pre-requisite: Tamper Protection must be turned off MANUALLY in
# Windows Security UI before this script's writes will persist. This
# script cannot do that — the UI toggle is protected from automation
# by design.
#
# Pass -Force to skip the confirmation prompt.
# Must be run as Administrator.
# Pair: enable-defender-wholesale.ps1
#
# Anti-cheat impact: NONE direct. Anti-cheat doesn't check whether
# Defender is on. INDIRECT risk: disabling Defender removes the OS
# baseline malware shield, so any malware that bypasses other defenses
# can tamper with anti-cheat state, but that's a system-security
# concern, not a vendor-policy concern. BattlEye / EAC / Vanguard do
# not refuse to launch based on Defender state alone.
# Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
# Disk impact: NONE — registry / cmdlet only; no installer / file extraction.
# ============================================================

param([switch]$Force)

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Disable Windows Defender (Wholesale)" -Subtitle "CARGO-CULT + Tamper Protection caveat"
UI-RequireAdmin -ScriptName "Disable Defender (wholesale)"

if (-not $Force) {
    Write-Host "  CARGO-CULT + TAMPER PROTECTION WARNING:" -ForegroundColor Red
    Write-Host "    Win11 24H2 Tamper Protection (ON by default) reverts most" -ForegroundColor Yellow
    Write-Host "    of these writes within seconds. The few that stick gain" -ForegroundColor Yellow
    Write-Host "    1-3% FPS at most on modern silicon." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    BETTER ALTERNATIVE: Defender exclusions for game library" -ForegroundColor Green
    Write-Host "    paths (APPLY-EVERYTHING.ps1 Phase 12 already does this)." -ForegroundColor Green
    Write-Host ""
    Write-Host "    PRE-REQUISITE: turn OFF Tamper Protection in" -ForegroundColor Red
    Write-Host "      Windows Security -> Virus & threat protection ->" -ForegroundColor Red
    Write-Host "      Manage settings -> Tamper Protection" -ForegroundColor Red
    Write-Host "    BEFORE running this script, or all writes will silently" -ForegroundColor Red
    Write-Host "    revert." -ForegroundColor Red
    Write-Host ""
    Write-Host "    Revert: enable-defender-wholesale.ps1." -ForegroundColor Gray
    Write-Host ""
    $proceed = Read-Host "  Continue? (y/N)"
    if ($proceed.Trim().ToUpper() -ne "Y") {
        Write-Host "  Cancelled." -ForegroundColor Gray
        exit 0
    }
    Write-Host ""
}

Initialize-ToolkitState | Out-Null
$stepName = "defender-wholesale"

$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
$spynetPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"

Write-Host "  Writing Defender policy keys..." -ForegroundColor Yellow
Set-ToolkitRegistryValue -Id "reg:DefenderDisableAntiSpyware" `
    -Path $policyPath -Name "DisableAntiSpyware" -Value 1 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName
Set-ToolkitRegistryValue -Id "reg:DefenderDisableAntiVirus" `
    -Path $policyPath -Name "DisableAntiVirus" -Value 1 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName

Set-ToolkitRegistryValue -Id "reg:DefenderDisableRealtimeMonitoring" `
    -Path $rtpPath -Name "DisableRealtimeMonitoring" -Value 1 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName
Set-ToolkitRegistryValue -Id "reg:DefenderDisableBehaviorMonitoring" `
    -Path $rtpPath -Name "DisableBehaviorMonitoring" -Value 1 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName
Set-ToolkitRegistryValue -Id "reg:DefenderDisableOnAccessProtection" `
    -Path $rtpPath -Name "DisableOnAccessProtection" -Value 1 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName

Set-ToolkitRegistryValue -Id "reg:DefenderSpynetReporting" `
    -Path $spynetPath -Name "SpynetReporting" -Value 0 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName
Set-ToolkitRegistryValue -Id "reg:DefenderSubmitSamplesConsent" `
    -Path $spynetPath -Name "SubmitSamplesConsent" -Value 2 -Type "DWord" `
    -Tier "Security Trade-off" -Step $stepName

# Best-effort: try Set-MpPreference too. Tamper Protection will block on
# Win11 24H2+ — the catch logs the rejection but does not re-throw because
# the policy-key writes above are the primary path and this is a fallback.
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction Stop
} catch {
    Write-Host "  [INFO] Set-MpPreference fallback blocked (likely Tamper Protection)." -ForegroundColor DarkGray
    Write-Host "         $($_.Exception.Message)" -ForegroundColor DarkGray
}

Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "applied" `
    -Reason "Defender wholesale-disable policy writes applied (Tamper Protection may revert)"

Write-Host ""
Write-Host "  [DONE] Policy keys written." -ForegroundColor Green
Write-Host "  Reboot for full effect." -ForegroundColor Yellow
Write-Host "  If Tamper Protection was on, expect Defender to come back online" -ForegroundColor Yellow
Write-Host "  within seconds — turn it off in Windows Security first." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
