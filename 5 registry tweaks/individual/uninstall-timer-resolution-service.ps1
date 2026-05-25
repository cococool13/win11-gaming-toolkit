<#
.SYNOPSIS
    Uninstall the Timer Resolution Service (STR) installed by
    install-timer-resolution-service.ps1.

.DESCRIPTION
    Reverses the four side-effects of the STR install in order, each
    gated by $PSCmdlet.ShouldProcess so -WhatIf / -Confirm propagate
    from any caller (including REVERT-EVERYTHING.ps1):
      1. Stop the STR service if running
      2. Delete the service entry (sc.exe delete)
      3. Remove the GlobalTimerResolutionRequests kernel registry value
      4. Remove %ProgramFiles%\SetTimerResolution

    Idempotent — safe to re-run; missing pieces are skipped without error.

.NOTES
    Tier: Advanced (reverts an Advanced-tier install)
    Pair: install-timer-resolution-service.ps1
    Anti-cheat impact: NONE (this is the cleanup direction). The
        install side has MEDIUM risk on Vanguard / FACEIT; removing
        the service eliminates that risk. Reboot after uninstall to
        clear any residual timer-resolution state.
    Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
    Disk impact: NONE — registry-only write; no on-disk file creation.
    Must be run as Administrator.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Uninstall Timer Resolution Service (STR)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

UI-RequireAdmin -ScriptName "Uninstall Timer Resolution Service"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

$serviceName = "STR"
$installDir = Join-Path $env:ProgramFiles "SetTimerResolution"
$kernelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
$kernelValueName = "GlobalTimerResolutionRequests"

# [1/4] Stop the service if running
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    if ($existingService.Status -eq "Running") {
        if ($PSCmdlet.ShouldProcess("Service '$serviceName' (status: Running)", "Stop-Service")) {
            Write-Host "[1/4] Stopping $serviceName service..." -ForegroundColor Yellow
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Write-Host "      Stopped." -ForegroundColor Green
        }
    } else {
        Write-Host "[1/4] $serviceName service present but not running — skipping stop." -ForegroundColor Gray
    }
} else {
    Write-Host "[1/4] $serviceName service not installed — skipping stop." -ForegroundColor Gray
}

# [2/4] Delete the service entry
if ($existingService) {
    if ($PSCmdlet.ShouldProcess("Service '$serviceName'", "sc.exe delete")) {
        Write-Host "[2/4] Deleting $serviceName service..." -ForegroundColor Yellow
        $deleteOutput = & sc.exe delete $serviceName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      Deleted." -ForegroundColor Green
        } else {
            Write-Host "      sc.exe delete returned $LASTEXITCODE — manual check may be needed." -ForegroundColor Yellow
            Write-Host "      $deleteOutput" -ForegroundColor DarkGray
        }
        Start-Sleep -Seconds 1
    }
} else {
    Write-Host "[2/4] No service to delete — skipping." -ForegroundColor Gray
}

# [3/4] Remove the GlobalTimerResolutionRequests kernel registry value
$existingValue = Get-ItemProperty -Path $kernelPath -Name $kernelValueName -ErrorAction SilentlyContinue
if ($null -ne $existingValue) {
    if ($PSCmdlet.ShouldProcess("$kernelPath\$kernelValueName", "Remove-ItemProperty")) {
        Write-Host "[3/4] Removing $kernelValueName registry value..." -ForegroundColor Yellow
        Remove-ItemProperty -Path $kernelPath -Name $kernelValueName -Force -ErrorAction SilentlyContinue
        Write-Host "      Removed." -ForegroundColor Green
    }
} else {
    Write-Host "[3/4] $kernelValueName not set — skipping registry cleanup." -ForegroundColor Gray
}

# [4/4] Remove install directory
if (Test-Path -LiteralPath $installDir) {
    if ($PSCmdlet.ShouldProcess($installDir, "Remove-Item -Recurse")) {
        Write-Host "[4/4] Removing $installDir..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $installDir) {
            Write-Host "      Directory still present — files may be in use. Reboot and re-run." -ForegroundColor Yellow
        } else {
            Write-Host "      Removed." -ForegroundColor Green
        }
    }
} else {
    Write-Host "[4/4] $installDir not present — skipping directory cleanup." -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  [DONE] Timer Resolution Service uninstalled." -ForegroundColor Green
Write-Host ""
Write-Host "  Reboot recommended so any pending timer requests release." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
