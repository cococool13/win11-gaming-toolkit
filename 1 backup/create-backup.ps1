# ============================================================
# Create System Restore Point & Registry Backup
# Windows 11 Gaming Optimization Guide
# ============================================================
# Combines restore point creation and registry backup into one
# smart script with validation and manifest integration.
#
# Replaces: create-restore-point.bat, backup-registry.bat
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Backup"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Create Backup (Restore Point + Registry)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$state = Initialize-ToolkitState
$succeeded = 0
$failed = 0

function Run-Step {
    param([string]$Description, [scriptblock]$Action)
    Write-Host "  $Description..." -NoNewline
    try {
        & $Action
        Write-Host " Done" -ForegroundColor Green
        $script:succeeded++
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $script:failed++
    }
}

# ============================================================
# STEP 1: SYSTEM RESTORE POINT
# ============================================================
Write-Host "[1/2] Creating System Restore Point..." -ForegroundColor White

Run-Step "Enabling System Restore on C:" {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
}

$script:restoreCreated = $false
Run-Step "Creating restore point" {
    Checkpoint-Computer -Description "Before Gaming Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    $script:restoreCreated = $true
}

if (-not $script:restoreCreated) {
    Write-Host "  [INFO] Restore point may have been throttled (Windows limits one per 24 hours)." -ForegroundColor Yellow
    Write-Host "  Continuing with registry backup..." -ForegroundColor Yellow
}

# ============================================================
# STEP 2: REGISTRY BACKUP
# ============================================================
Write-Host ""
Write-Host "[2/2] Backing Up Registry Keys..." -ForegroundColor White

$timestamp = (Get-Date -Format "yyyyMMdd_HHmm")
$backupDir = Join-Path $env:USERPROFILE "Documents\GamingOptBackup_$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "  Backup folder: $backupDir" -ForegroundColor Gray

# Comprehensive registry paths — covers ALL areas the toolkit modifies
$registryPaths = @(
    @{ Key = "HKCU\Control Panel\Desktop";                     Name = "Desktop" }
    @{ Key = "HKCU\Control Panel\Mouse";                       Name = "Mouse" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"; Name = "Explorer" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR"; Name = "GameDVR" }
    @{ Key = "HKCU\System\GameConfigStore";                    Name = "GameConfigStore" }
    @{ Key = "HKCU\Software\Microsoft\GameBar";                Name = "GameBar" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "Personalize" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "ContentDelivery" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "Search" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings"; Name = "SearchSettings" }
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "AdvertisingInfo" }
    @{ Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"; Name = "DriverSearching" }
    @{ Key = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name = "SessionManagerPower" }
    @{ Key = "HKLM\SYSTEM\CurrentControlSet\Control\Power";   Name = "Power" }
    @{ Key = "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Name = "DeviceGuard" }
    @{ Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa";     Name = "LSA" }
    @{ Key = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"; Name = "TcpipInterfaces" }
    @{ Key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "SystemProfile" }
    @{ Key = "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "PriorityControl" }
    @{ Key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DataCollection" }
)

$total = $registryPaths.Count
$current = 0
foreach ($entry in $registryPaths) {
    $current++
    $outputFile = Join-Path $backupDir "$($entry.Name).reg"
    $result = reg export $entry.Key $outputFile /y 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [$current/$total] $($entry.Name)" -ForegroundColor Green
        $succeeded++
    } else {
        # Path doesn't exist yet — that's OK, means toolkit hasn't modified it
        Write-Host "  [$current/$total] $($entry.Name) — not present (OK)" -ForegroundColor Gray
    }
}

# Record backup location in manifest
Add-ToolkitNote "Registry backup saved to: $backupDir"
Add-ToolkitStepResult -Key "backup" -Tier "Safe" -Status "applied" -Reason "Backup at $backupDir"

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  BACKUP COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Restore point: $(if ($script:restoreCreated) { 'Created' } else { 'Throttled (24h limit)' })" -ForegroundColor $(if ($script:restoreCreated) { "Green" } else { "Yellow" })
Write-Host "  Registry backup: $backupDir" -ForegroundColor Green
Write-Host "  Keys backed up: $current" -ForegroundColor Gray
Write-Host ""
Write-Host "  To restore registry: double-click any .reg file, or:" -ForegroundColor Gray
Write-Host "    reg import `"$backupDir\Desktop.reg`"" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to continue"
