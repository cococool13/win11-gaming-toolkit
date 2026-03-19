# ============================================================
# GPU Driver — Detect, Download, Install (Debloated), Configure
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Orchestrator script: detects GPU vendor, downloads the correct
# driver, installs with minimal components, and applies hidden
# performance settings. Callable standalone or via DDU RunOnce chain.
#
# Usage:
#   .\install-gpu-driver.ps1                       # Interactive
#   .\install-gpu-driver.ps1 -PostDdu              # Unattended (DDU chain)
#   .\install-gpu-driver.ps1 -AutoDetectLatest     # Query vendor API for latest
#   .\install-gpu-driver.ps1 -SkipSettings         # Install only, no tweaks
#   .\install-gpu-driver.ps1 -Vendor nvidia        # Force vendor
#
# Undo: REVERT-EVERYTHING.ps1 (rolls back all registry changes)
# ============================================================

param(
    [switch]$PostDdu,
    [switch]$AutoDetectLatest,
    [switch]$SkipSettings,
    [ValidateSet("nvidia", "amd", "intel", "")]
    [string]$Vendor = ""
)

# --- Load shared libraries ---
. "$PSScriptRoot\..\lib\download-helpers.ps1"
. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"
. "$PSScriptRoot\..\lib\gpu-download.ps1"

$Host.UI.RawUI.WindowTitle = "GPU Driver — Clean Install + Optimize"
if (-not $PostDdu) { Clear-Host }
$ProgressPreference = "SilentlyContinue"

# --- Admin check ---
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PostDdu) {
        # Re-elevate silently for unattended DDU chain
        $elevateArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath, "-PostDdu")
        if ($AutoDetectLatest) { $elevateArgs += "-AutoDetectLatest" }
        if ($SkipSettings) { $elevateArgs += "-SkipSettings" }
        if ($Vendor -ne "") { $elevateArgs += @("-Vendor", $Vendor) }
        Start-Process PowerShell.exe -Verb RunAs -ArgumentList $elevateArgs
        exit
    }
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Header ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GPU DRIVER — CLEAN INSTALL + OPTIMIZE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($PostDdu) {
    Write-Host "  Mode: Post-DDU automatic driver installation" -ForegroundColor Yellow
    Write-Host ""
}

# --- Internet check ---
try {
    Ensure-Internet
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    if ($PostDdu) {
        Write-Host "Cannot install GPU driver without internet. Re-enabling driver search for Windows Update fallback." -ForegroundColor Yellow
        Restore-DriverSearchPolicy
    }
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Initialize state ---
$state = Initialize-ToolkitState

# --- Detect GPU ---
Write-Info "Detecting GPU..."

$targetGpu = $null
if ($Vendor -ne "") {
    $gpus = @(Get-GpuVendor | Where-Object { $_.Vendor -eq $Vendor })
    if ($gpus.Count -eq 0) {
        Write-Host "[ERROR] No $Vendor GPU detected." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    $targetGpu = $gpus[0]
} else {
    $targetGpu = Get-PrimaryGpu
}

if (-not $targetGpu) {
    Write-Host "[ERROR] No supported GPU detected (NVIDIA/AMD/Intel)." -ForegroundColor Red
    if ($PostDdu) {
        Restore-DriverSearchPolicy
    }
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Detected: $($targetGpu.FriendlyName)" -ForegroundColor Green
Write-Host "  Vendor:   $($targetGpu.Vendor)" -ForegroundColor White
Write-Host "  Device:   $($targetGpu.DeviceId)" -ForegroundColor Gray
Write-Host ""

# --- Confirm (skip in unattended mode) ---
if (-not $PostDdu) {
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Download the $($targetGpu.Vendor.ToUpper()) driver" -ForegroundColor White
    Write-Host "  2. Install with minimal components (debloated)" -ForegroundColor White
    if (-not $SkipSettings) {
        Write-Host "  3. Apply hidden performance settings" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Press Ctrl+C to cancel, or" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    Write-Host ""
}

# --- Load version manifest ---
$manifestPath = Join-Path $PSScriptRoot "gpu-driver-versions.json"
$versionManifest = Get-GpuDriverVersionManifest -ManifestPath $manifestPath

# --- Resolve driver URL ---
Write-Info "Resolving driver download URL..."

$driverInfo = $null
$signerCN = ""

switch ($targetGpu.Vendor) {
    "nvidia" {
        $driverInfo = Resolve-NvidiaDriverUrl -Manifest $versionManifest -DeviceId $targetGpu.DeviceId -AutoDetect:$AutoDetectLatest
        $signerCN = $versionManifest.nvidia.signerCN
    }
    "amd" {
        $driverInfo = Resolve-AmdDriverUrl -Manifest $versionManifest
        $signerCN = $versionManifest.amd.signerCN
    }
    "intel" {
        $driverInfo = Resolve-IntelDriverUrl -Manifest $versionManifest
        $signerCN = $versionManifest.intel.signerCN
    }
}

Write-Host "  Version: $($driverInfo.Version)" -ForegroundColor White
Write-Host "  URL:     $($driverInfo.Url)" -ForegroundColor Gray
if ($driverInfo.AutoDetected) {
    Write-Host "  Source:  Auto-detected (vendor API)" -ForegroundColor Yellow
} else {
    Write-Host "  Source:  Pinned manifest" -ForegroundColor Green
}
Write-Host ""

# --- Download ---
Write-Info "Downloading driver..."

$installerPath = $null
try {
    $installerPath = Get-GpuDriverInstaller `
        -Vendor $targetGpu.Vendor `
        -Url $driverInfo.Url `
        -ExpectedHash $driverInfo.ExpectedHash `
        -ExpectedSignerCN $signerCN
} catch {
    Write-Host "[ERROR] Driver download/verification failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($PostDdu) {
        Restore-DriverSearchPolicy
    }
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Saved to: $installerPath" -ForegroundColor Gray
Write-Host ""

# --- Install ---
Write-Info "Installing driver..."

try {
    switch ($targetGpu.Vendor) {
        "nvidia" {
            $components = @($driverInfo.Components)
            & "$PSScriptRoot\nvidia\install-nvidia.ps1" -InstallerPath $installerPath -Components $components
        }
        "amd" {
            & "$PSScriptRoot\amd\install-amd.ps1" -InstallerPath $installerPath
        }
        "intel" {
            $driverOnly = if ($driverInfo.PSObject.Properties["DriverOnlyInf"]) { $driverInfo.DriverOnlyInf } else { $false }
            if ($driverOnly) {
                & "$PSScriptRoot\intel\install-intel.ps1" -InstallerPath $installerPath -DriverOnlyInf
            } else {
                & "$PSScriptRoot\intel\install-intel.ps1" -InstallerPath $installerPath
            }
        }
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Driver installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Re-enabling Windows driver search as safety fallback." -ForegroundColor Yellow
    Restore-DriverSearchPolicy
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# --- Configure (hidden settings) ---
if (-not $SkipSettings) {
    Write-Info "Applying hidden performance settings..."

    try {
        switch ($targetGpu.Vendor) {
            "nvidia" { & "$PSScriptRoot\nvidia\configure-nvidia.ps1" }
            "amd"    { & "$PSScriptRoot\amd\configure-amd.ps1" }
            "intel"  { & "$PSScriptRoot\intel\configure-intel.ps1" }
        }
    } catch {
        Write-Host "[WARNING] Settings application failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Driver is installed, but some performance settings may not be applied." -ForegroundColor Yellow
    }

    Write-Host ""
}

# --- Verify ---
Write-Info "Verifying installation..."

$postGpu = Get-GpuVendor | Where-Object { $_.Vendor -eq $targetGpu.Vendor } | Select-Object -First 1
if ($postGpu -and $postGpu.Status -eq "OK") {
    Write-Host "  GPU detected and driver loaded: $($postGpu.FriendlyName)" -ForegroundColor Green
    Add-ToolkitStepResult -Key "gpu-driver-verify" -Tier "Advanced" -Status "applied" -Reason "Driver verified after install"
} else {
    Write-Host "  [WARNING] GPU status is not 'OK'. A reboot may be required." -ForegroundColor Yellow
    Add-ToolkitStepResult -Key "gpu-driver-verify" -Tier "Advanced" -Status "applied" -Reason "Driver installed, reboot may be required"
}

# --- Summary ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GPU DRIVER INSTALL COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  GPU:      $($targetGpu.FriendlyName)" -ForegroundColor White
Write-Host "  Vendor:   $($targetGpu.Vendor.ToUpper())" -ForegroundColor White
Write-Host "  Version:  $($driverInfo.Version)" -ForegroundColor White
Write-Host "  Settings: $(if ($SkipSettings) { 'Skipped' } else { 'Applied' })" -ForegroundColor White
Write-Host ""
Write-Host "  A REBOOT is recommended for all changes to take effect." -ForegroundColor Yellow
Write-Host ""

if ($PostDdu) {
    $reboot = Read-Host "Reboot now? (Y/N)"
    if ($reboot -eq "Y" -or $reboot -eq "y") {
        Write-Host "Rebooting in 5 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    }
} else {
    Read-Host "Press Enter to return"
}
