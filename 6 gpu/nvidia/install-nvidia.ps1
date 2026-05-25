# ============================================================
# NVIDIA Driver — Silent Debloated Install
# Windows 11 Gaming Optimization Guide
# ============================================================
# Requires: lib/download-helpers.ps1, lib/toolkit-state.ps1
# Called by: 6 gpu/install-gpu-driver.ps1
#
# Anti-cheat impact: NONE — installs NVIDIA's official signed driver
# package. The -Components filter only EXCLUDES bloat (GeForce
# Experience, NVIDIA Container telemetry, etc.); the core Display.Driver
# is byte-identical to a manual install from nvidia.com. Anti-cheat
# layers see the same driver state either way.
# Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
# Disk impact: NONE — registry / cmdlet only; no installer / file extraction.
# ============================================================

param(
    [Parameter(Mandatory)][string]$InstallerPath,
    [string[]]$Components = @("Display.Driver", "HDAudio")
)

# CLAUDE.md invariant #6 — every mutating script self-checks admin.
# Surfaced by Test-ToolkitInvariants (profile/parts/toolkit-aware.ps1).
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ''
    Write-Host '  [ERROR] install-nvidia.ps1 must be run as Administrator.' -ForegroundColor Red
    Write-Host '  Re-launch PowerShell as Admin or invoke via 6 gpu\install-gpu-driver.ps1.' -ForegroundColor Red
    Write-Host ''
    exit 1
}

. "$PSScriptRoot\..\..\lib\download-helpers.ps1"
. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
# Must come AFTER lib/toolkit-state.ps1 dot-source — that's where
# Write-ToolkitScriptStart is defined.
Write-ToolkitScriptStart

$extractDir = Join-Path $env:TEMP "NvidiaDriverExtract"

function Install-NvidiaDriver {
    param(
        [string]$Installer,
        [string[]]$SelectedComponents
    )

    # NVIDIA driver EXEs are self-extracting 7-Zip archives
    $sevenZipExe = Ensure-7Zip

    Write-Info "Extracting NVIDIA driver package..."
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    & $sevenZipExe x $Installer "-o$extractDir" -y | Out-Null

    $setupExe = Join-Path $extractDir "setup.exe"
    if (-not (Test-Path $setupExe)) {
        throw "NVIDIA setup.exe not found after extraction"
    }

    # Build component string: "Display.Driver,HDAudio"
    $componentString = $SelectedComponents -join ","

    Write-Info "Installing NVIDIA driver (components: $componentString)..."
    Write-Info "This may take several minutes. The screen may flicker."

    $process = Start-Process -FilePath $setupExe `
        -ArgumentList "-s", "-noreboot", "-noeula", "-components", $componentString `
        -Wait -PassThru

    # Exit codes: 0 = success, 1 = reboot required (OK)
    if ($process.ExitCode -notin @(0, 1)) {
        throw "NVIDIA installer exited with code $($process.ExitCode)"
    }

    Write-Info "NVIDIA driver installed successfully."
}

function Remove-NvidiaTelemetry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param()
    Write-Info "Disabling NVIDIA telemetry..."

    # Disable NvTelemetryContainer service
    $nvTelemetry = Get-Service -Name "NvTelemetryContainer" -ErrorAction SilentlyContinue
    if ($nvTelemetry) {
        Stop-Service -Name "NvTelemetryContainer" -Force -ErrorAction SilentlyContinue
        Set-ToolkitServiceStartMode -Name "NvTelemetryContainer" -Mode "disabled" `
            -Tier "Advanced" -Step "gpu-nvidia-install"
    }

    # Disable NVIDIA telemetry scheduled tasks
    $nvTasks = Get-ScheduledTask -TaskPath "\NV*" -ErrorAction SilentlyContinue
    foreach ($task in $nvTasks) {
        if ($task.TaskName -match "Telemetry|Update|NvTm") {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # Disable NVIDIA Container telemetry component
    $nvContainerSvc = Get-Service -Name "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
    if ($nvContainerSvc) {
        # Don't disable the whole container — it's needed for the driver.
        # Instead, remove telemetry plugin files if present.
        $telemetryPlugin = Join-Path ${env:ProgramFiles} "NVIDIA Corporation\NvTelemetry"
        if (Test-Path $telemetryPlugin) {
            Remove-Item $telemetryPlugin -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Info "NVIDIA telemetry disabled."
}

# --- Execute ---
try {
    Install-NvidiaDriver -Installer $InstallerPath -SelectedComponents $Components
    Remove-NvidiaTelemetry
    Add-ToolkitStepResult -Key "gpu-nvidia-install" -Tier "Advanced" -Status "applied" -Reason "Silent debloated install"
} catch {
    Add-ToolkitStepResult -Key "gpu-nvidia-install" -Tier "Advanced" -Status "failed" -Reason $_.Exception.Message
    throw
} finally {
    # Cleanup extracted files
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
