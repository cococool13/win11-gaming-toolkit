# ============================================================
# Intel Driver — Silent Minimal Install
# Windows 11 Gaming Optimization Guide
# ============================================================
# Preferred method: pnputil driver-only install (zero bloat).
# Fallback: silent EXE install if extraction fails.
#
# Requires: lib/download-helpers.ps1, lib/toolkit-state.ps1
# Called by: 6 gpu/install-gpu-driver.ps1
# ============================================================

param(
    [Parameter(Mandatory)][string]$InstallerPath,
    [switch]$DriverOnlyInf
)

. "$PSScriptRoot\..\lib\download-helpers.ps1"
. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$extractDir = Join-Path $env:TEMP "IntelDriverExtract"

function Install-IntelDriverViaInf {
    <#
    .SYNOPSIS
        Extracts the Intel driver package and installs only the core
        graphics INF via pnputil. Zero bloat — no Arc Control, no
        Intel Computing Improvement Program, no telemetry.
    #>
    param([string]$Installer)

    $sevenZipExe = Ensure-7Zip

    Write-Info "Extracting Intel driver package..."
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    & $sevenZipExe x $Installer "-o$extractDir" -y | Out-Null

    # Look for the core graphics INF
    $infPaths = @(
        (Join-Path $extractDir "Graphics\iigd_dch.inf"),
        (Join-Path $extractDir "Graphics\igdlh64.inf")
    )
    $infFile = $null
    foreach ($candidate in $infPaths) {
        if (Test-Path $candidate) {
            $infFile = $candidate
            break
        }
    }

    # Fallback: search recursively
    if (-not $infFile) {
        $found = Get-ChildItem -Path $extractDir -Filter "iigd_dch.inf" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $infFile = $found.FullName
        }
    }

    if (-not $infFile) {
        throw "Intel graphics INF not found in extracted package. Falling back to EXE install."
    }

    Write-Info "Installing Intel driver via pnputil (driver-only, zero bloat)..."
    Write-Info "INF: $infFile"

    $output = pnputil /add-driver $infFile /install 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -notin @(0, 3010)) {
        Write-Host "  pnputil output: $output" -ForegroundColor Yellow
        throw "pnputil driver install failed with exit code $exitCode"
    }

    Write-Info "Intel driver installed via INF successfully."
    return $true
}

function Install-IntelDriverViaExe {
    <#
    .SYNOPSIS
        Fallback: runs the Intel installer EXE with silent flags.
        Installs all components (less ideal but works reliably).
    #>
    param([string]$Installer)

    Write-Info "Installing Intel driver via silent EXE..."
    Write-Info "This may take several minutes. The screen may flicker."

    $process = Start-Process -FilePath $Installer `
        -ArgumentList "-s", "-norestart" `
        -Wait -PassThru

    if ($process.ExitCode -notin @(0, 1, 3010)) {
        throw "Intel installer exited with code $($process.ExitCode)"
    }

    Write-Info "Intel driver installed via EXE successfully."
}

function Remove-IntelBloat {
    Write-Info "Removing Intel bloatware..."

    # Remove Intel Arc Control UWP app
    Get-AppxPackage "*IntelGraphicsExperience*" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage "*ArcControl*" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

    # Disable Intel Computing Improvement Program (telemetry)
    $cipServices = @(
        "Intel(R) Computing Improvement Program"
        "igfxCUIService"
    )
    foreach ($svcName in $cipServices) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            Set-ToolkitServiceStartMode -Name $svcName -Mode "disabled" `
                -Tier "Advanced" -Step "gpu-intel-install"
        }
    }

    # Disable Intel telemetry scheduled tasks
    Get-ScheduledTask -TaskPath "\Intel\*" -ErrorAction SilentlyContinue |
        Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null

    Write-Info "Intel bloatware removed."
}

# --- Execute ---
try {
    $installed = $false

    if ($DriverOnlyInf) {
        try {
            Install-IntelDriverViaInf -Installer $InstallerPath
            $installed = $true
        } catch {
            Write-Host "  [INFO] INF install failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "  Falling back to EXE install..." -ForegroundColor Yellow
        }
    }

    if (-not $installed) {
        Install-IntelDriverViaExe -Installer $InstallerPath
    }

    Remove-IntelBloat
    Add-ToolkitStepResult -Key "gpu-intel-install" -Tier "Advanced" -Status "applied" -Reason "Silent minimal install"
} catch {
    Add-ToolkitStepResult -Key "gpu-intel-install" -Tier "Advanced" -Status "failed" -Reason $_.Exception.Message
    throw
} finally {
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
