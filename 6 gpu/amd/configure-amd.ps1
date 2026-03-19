# ============================================================
# AMD GPU — Hidden Performance Settings
# Windows 11 Gaming Optimization Guide
# ============================================================
# Applies registry-based performance settings for competitive gaming.
# All changes tracked via Set-ToolkitRegistryValue for rollback.
#
# Requires: lib/toolkit-state.ps1, lib/gpu-detection.ps1
# Called by: 6 gpu/install-gpu-driver.ps1
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"

$stepName = "gpu-amd-settings"

function Apply-AmdAdapterSettings {
    param([Parameter(Mandatory)][string]$AdapterPath)

    Write-Host "  Applying AMD adapter-level settings..." -ForegroundColor Cyan

    # Disable Ultra Low Power State (ULPS) — prevents stuttering on wake
    Set-ToolkitRegistryValue -Id "amd:EnableUlps" `
        -Path $AdapterPath -Name "EnableUlps" `
        -Value 0 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Disable ULPS for the NA key variant too
    Set-ToolkitRegistryValue -Id "amd:EnableUlps_NA" `
        -Path $AdapterPath -Name "EnableUlps_NA" `
        -Value 0 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Disable deep sleep clock gating — keeps GPU responsive
    Set-ToolkitRegistryValue -Id "amd:PP_SclkDeepSleepDisable" `
        -Path $AdapterPath -Name "PP_SclkDeepSleepDisable" `
        -Value 1 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Disable DMA copy — reduces overhead
    Set-ToolkitRegistryValue -Id "amd:DisableDMACopy" `
        -Path $AdapterPath -Name "DisableDMACopy" `
        -Value 1 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Enable block writes — better memory performance
    Set-ToolkitRegistryValue -Id "amd:DisableBlockWrite" `
        -Path $AdapterPath -Name "DisableBlockWrite" `
        -Value 0 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Disable stutter mode — prevents micro-stuttering
    Set-ToolkitRegistryValue -Id "amd:StutterMode" `
        -Path $AdapterPath -Name "StutterMode" `
        -Value 0 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Disable DRMDMA power gating — keeps GPU clocks stable
    Set-ToolkitRegistryValue -Id "amd:DisableDrmdmaPowerGating" `
        -Path $AdapterPath -Name "DisableDrmdmaPowerGating" `
        -Value 1 -Type "DWord" -Tier "Advanced" -Step $stepName

    # Disable power gating for consistent performance
    Set-ToolkitRegistryValue -Id "amd:EnableAspmL0s" `
        -Path $AdapterPath -Name "EnableAspmL0s" `
        -Value 0 -Type "DWord" -Tier "Advanced" -Step $stepName

    Set-ToolkitRegistryValue -Id "amd:EnableAspmL1" `
        -Path $AdapterPath -Name "EnableAspmL1" `
        -Value 0 -Type "DWord" -Tier "Advanced" -Step $stepName
}

function Apply-AmdSystemSettings {
    Write-Host "  Applying system-level GPU settings..." -ForegroundColor Cyan

    $graphicsDriversPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"

    # Hardware Accelerated GPU Scheduling (HAGS)
    Set-ToolkitRegistryValue -Id "amd:HwSchMode" `
        -Path $graphicsDriversPath -Name "HwSchMode" `
        -Value 2 -Type "DWord" -Tier "Advanced" -Step $stepName
}

# --- Execute ---
try {
    $state = Initialize-ToolkitState

    $gpu = Get-GpuVendor | Where-Object { $_.Vendor -eq "amd" } | Select-Object -First 1
    if (-not $gpu) {
        throw "No AMD GPU detected"
    }

    if (-not $gpu.AdapterRegistryPath) {
        throw "Could not resolve AMD adapter registry path for: $($gpu.FriendlyName)"
    }

    Write-Host ""
    Write-Host "Configuring AMD GPU: $($gpu.FriendlyName)" -ForegroundColor Green
    Write-Host "Adapter path: $($gpu.AdapterRegistryPath)" -ForegroundColor Gray
    Write-Host ""

    # Check ReBAR / Smart Access Memory status
    $rebarStatus = Test-ReBarEnabled -AdapterRegistryPath $gpu.AdapterRegistryPath
    if ($rebarStatus -eq $false) {
        Write-Host "  [WARNING] Smart Access Memory (ReBAR) appears DISABLED." -ForegroundColor Yellow
        Write-Host "  Enable it in BIOS for better performance. See BIOS-CHECKLIST.md." -ForegroundColor Yellow
        Write-Host ""
    } elseif ($rebarStatus -eq $true) {
        Write-Host "  Smart Access Memory (ReBAR): Enabled" -ForegroundColor Green
    }

    Apply-AmdAdapterSettings -AdapterPath $gpu.AdapterRegistryPath
    Apply-AmdSystemSettings

    Add-ToolkitStepResult -Key $stepName -Tier "Advanced" -Status "applied" -Reason "AMD hidden performance settings"
    Write-Host ""
    Write-Host "AMD performance settings applied." -ForegroundColor Green

} catch {
    Add-ToolkitStepResult -Key $stepName -Tier "Advanced" -Status "failed" -Reason $_.Exception.Message
    throw
}
