# ============================================================
# VBS / Memory Integrity Configuration (Smart)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Disables VBS, HVCI (Memory Integrity), and optionally LSA
# Protection for maximum gaming performance (+5-25% FPS).
#
# Pre-checks current state, skips if already configured.
# Tracks all changes in manifest for exact rollback.
#
# Replaces: disable-vbs.bat, enable-vbs.bat
# Must be run as Administrator. Requires reboot.
# ============================================================

param(
    [switch]$Enable  # Pass -Enable to re-enable VBS/HVCI
)

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — VBS / Memory Integrity"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  VBS / Memory Integrity — $(if ($Enable) { 'RE-ENABLE' } else { 'DISABLE' })" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$state = Initialize-ToolkitState
$stepName = "vbs-security"

# ---- Pre-check current state ----
Write-Host "  Checking current state..." -ForegroundColor Gray

$hvciPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$vbsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
$lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

$currentHVCI = (Get-ItemProperty -Path $hvciPath -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
$currentVBS = (Get-ItemProperty -Path $vbsPath -Name "EnableVirtualizationBasedSecurity" -ErrorAction SilentlyContinue).EnableVirtualizationBasedSecurity
$currentLSA = (Get-ItemProperty -Path $lsaPath -Name "RunAsPPL" -ErrorAction SilentlyContinue).RunAsPPL

$hvciStatus = if ($currentHVCI -eq 0) { "Disabled" } elseif ($currentHVCI -eq 1) { "Enabled" } else { "Not set" }
$vbsStatus = if ($currentVBS -eq 0) { "Disabled" } elseif ($currentVBS -eq 1) { "Enabled" } else { "Not set" }
$lsaStatus = if ($currentLSA -eq 0) { "Disabled" } elseif ($currentLSA -eq 1) { "Enabled" } else { "Not set" }

Write-Host "  Memory Integrity (HVCI): $hvciStatus" -ForegroundColor $(if ($hvciStatus -eq "Disabled") { "Green" } else { "Yellow" })
Write-Host "  VBS:                     $vbsStatus" -ForegroundColor $(if ($vbsStatus -eq "Disabled") { "Green" } else { "Yellow" })
Write-Host "  LSA Protection:          $lsaStatus" -ForegroundColor $(if ($lsaStatus -eq "Disabled") { "Green" } else { "Yellow" })
Write-Host ""

if ($Enable) {
    # Re-enable flow
    if ($hvciStatus -eq "Enabled" -and $vbsStatus -eq "Enabled") {
        Write-Host "  VBS/HVCI already enabled. Nothing to do." -ForegroundColor Green
        Read-Host "Press Enter to exit"
        exit 0
    }

    Write-Host "  This will RE-ENABLE security features." -ForegroundColor Green
    Write-Host "  Gaming performance may decrease slightly." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Press Ctrl+C to cancel, or" -ForegroundColor Yellow
    Read-Host "  Press Enter to continue"

    # Restore from manifest if available, otherwise set defaults
    $restored = Restore-ToolkitRegistryValue -Id "reg:HVCIEnabled"
    if (-not $restored) {
        Set-ToolkitRegistryValue -Id "reg:HVCIEnabled" -Path $hvciPath -Name "Enabled" `
            -Value 1 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
    }
    $restored = Restore-ToolkitRegistryValue -Id "reg:EnableVBS"
    if (-not $restored) {
        Set-ToolkitRegistryValue -Id "reg:EnableVBS" -Path $vbsPath -Name "EnableVirtualizationBasedSecurity" `
            -Value 1 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
    }
    Restore-ToolkitRegistryValue -Id "reg:RunAsPPL" | Out-Null
    Restore-ToolkitRegistryValue -Id "reg:LsaCfgFlags" | Out-Null

    Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "applied" -Reason "VBS/HVCI re-enabled"
    Write-Host ""
    Write-Host "  VBS/HVCI re-enabled. REBOOT REQUIRED." -ForegroundColor Green

} else {
    # Disable flow
    if ($hvciStatus -eq "Disabled" -and $vbsStatus -eq "Disabled" -and $lsaStatus -eq "Disabled") {
        Write-Host "  All already disabled. Nothing to do." -ForegroundColor Green
        Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "preexisting" -Reason "Already disabled"
        Read-Host "Press Enter to exit"
        exit 0
    }

    Write-Host "  WARNING: This disables important security features." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Benefits: +5-25% FPS improvement in many games" -ForegroundColor Green
    Write-Host "  Risk:     Reduced protection against kernel-level exploits" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press Ctrl+C to cancel, or" -ForegroundColor Yellow
    Read-Host "  Press Enter to continue"
    Write-Host ""

    # Disable HVCI
    Write-Host "  [1/4] Disabling Memory Integrity (HVCI)..." -NoNewline
    Set-ToolkitRegistryValue -Id "reg:HVCIEnabled" -Path $hvciPath -Name "Enabled" `
        -Value 0 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
    Write-Host " Done" -ForegroundColor Green

    # Disable VBS
    Write-Host "  [2/4] Disabling VBS..." -NoNewline
    Set-ToolkitRegistryValue -Id "reg:EnableVBS" -Path $vbsPath -Name "EnableVirtualizationBasedSecurity" `
        -Value 0 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
    Write-Host " Done" -ForegroundColor Green

    # LSA — extra confirmation
    Write-Host ""
    Write-Host "  Step 3: LSA Protection (credential guard)" -ForegroundColor Red
    Write-Host "  Disabling allows credential-dumping tools to extract passwords." -ForegroundColor Yellow
    Write-Host "  Only proceed on dedicated gaming PCs with no sensitive accounts." -ForegroundColor Yellow
    Write-Host ""
    $lsaChoice = Read-Host "  Disable LSA Protection? (Y/N) [N]"
    if ($lsaChoice -eq "Y" -or $lsaChoice -eq "y") {
        Write-Host "  [3/4] Disabling LSA Protection..." -NoNewline
        Set-ToolkitRegistryValue -Id "reg:RunAsPPL" -Path $lsaPath -Name "RunAsPPL" `
            -Value 0 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
        Write-Host " Done" -ForegroundColor Green

        Write-Host "  [4/4] Disabling Credential Guard..." -NoNewline
        Set-ToolkitRegistryValue -Id "reg:LsaCfgFlags" -Path $lsaPath -Name "LsaCfgFlags" `
            -Value 0 -Type "DWord" -Tier "Security Trade-off" -Step $stepName
        Write-Host " Done" -ForegroundColor Green
    } else {
        Write-Host "  [3/4] LSA Protection — Skipped" -ForegroundColor Yellow
        Write-Host "  [4/4] Credential Guard — Skipped" -ForegroundColor Yellow
    }

    Add-ToolkitStepResult -Key $stepName -Tier "Security Trade-off" -Status "applied" -Reason "VBS/HVCI disabled"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  YOU MUST REBOOT for changes to take effect." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  To verify after reboot:" -ForegroundColor Gray
Write-Host "    1. Open Start, type 'msinfo32', press Enter" -ForegroundColor Gray
Write-Host "    2. Look for 'Virtualization-based security'" -ForegroundColor Gray
Write-Host "    3. It should say '$(if ($Enable) { "Running" } else { "Not enabled" })'" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to continue"
