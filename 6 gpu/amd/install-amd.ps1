# ============================================================
# AMD Driver — Silent Minimal Install
# Windows 11 Gaming Optimization Guide
# ============================================================
# Requires: lib/download-helpers.ps1, lib/toolkit-state.ps1
# Called by: 6 gpu/install-gpu-driver.ps1
# ============================================================

param(
    [Parameter(Mandatory)][string]$InstallerPath
)

. "$PSScriptRoot\..\lib\download-helpers.ps1"
. "$PSScriptRoot\..\lib\toolkit-state.ps1"

function Install-AmdDriver {
    param([string]$Installer)

    Write-Info "Installing AMD driver (silent minimal)..."
    Write-Info "This may take several minutes. The screen may flicker."

    # AMD Adrenalin installer supports -install for silent mode
    $logFile = Join-Path $env:ProgramData "GamingOpt\amd-install.log"
    $process = Start-Process -FilePath $Installer `
        -ArgumentList "-install", "-log", $logFile `
        -Wait -PassThru

    if ($process.ExitCode -notin @(0, 1, 3010)) {
        throw "AMD installer exited with code $($process.ExitCode). See log: $logFile"
    }

    Write-Info "AMD driver installed successfully."
}

function Remove-AmdBloat {
    Write-Info "Removing AMD bloatware..."

    # Remove Adrenalin Software UWP app (keeps core driver)
    $amdApps = @(
        "*AdvancedMicroDevices*Adrenalin*"
        "*AMDRadeonSoftware*"
    )
    foreach ($pattern in $amdApps) {
        Get-AppxPackage $pattern -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.PackageName -like $pattern } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

    # Disable AMD telemetry services
    $amdTelemetryServices = @(
        "amdfendr"
        "amdfendrmgr"
        "AMD Crash Defender Service"
    )
    foreach ($svcName in $amdTelemetryServices) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            Set-ToolkitServiceStartMode -Name $svcName -Mode "disabled" `
                -Tier "Advanced" -Step "gpu-amd-install"
        }
    }

    # Disable AMD telemetry scheduled tasks
    $amdTasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -match "AMD|Radeon" -and $_.TaskName -match "Telemetry|Update|Report" }
    foreach ($task in $amdTasks) {
        Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Info "AMD bloatware removed."
}

# --- Execute ---
try {
    Install-AmdDriver -Installer $InstallerPath
    Remove-AmdBloat
    Add-ToolkitStepResult -Key "gpu-amd-install" -Tier "Advanced" -Status "applied" -Reason "Silent minimal install"
} catch {
    Add-ToolkitStepResult -Key "gpu-amd-install" -Tier "Advanced" -Status "failed" -Reason $_.Exception.Message
    throw
}
