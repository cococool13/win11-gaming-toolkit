# ============================================================
# Cleanup Temp Files and Caches (Smart)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Clears temporary files, Windows Update cache, shader cache,
# and other junk. Handles locked files gracefully and estimates
# space freed. Warns about shader cache impact.
#
# Replaces: cleanup-temp.bat
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Cleanup"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Cleanup Temp Files and Caches" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$totalFreed = 0

function Get-FolderSizeMB {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    $bytes = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    return [math]::Round(($bytes / 1MB), 1)
}

function Clear-FolderSafe {
    param(
        [string]$Path,
        [string]$Description,
        [string]$StepNum
    )

    Write-Host "  [$StepNum] $Description..." -NoNewline

    if (-not (Test-Path $Path)) {
        Write-Host " Not found" -ForegroundColor Gray
        return
    }

    $sizeBefore = Get-FolderSizeMB -Path $Path
    $deletedCount = 0
    $lockedCount = 0

    Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop
            $deletedCount++
        } catch {
            $lockedCount++
        }
    }

    $sizeAfter = Get-FolderSizeMB -Path $Path
    $freed = [math]::Max(0, $sizeBefore - $sizeAfter)
    $script:totalFreed += $freed

    if ($lockedCount -gt 0) {
        Write-Host " Done ($([math]::Round($freed, 0)) MB freed, $lockedCount files locked)" -ForegroundColor Yellow
    } else {
        Write-Host " Done ($([math]::Round($freed, 0)) MB freed)" -ForegroundColor Green
    }
}

# ---- Estimate total space ----
Write-Host "  Estimating space to free..." -ForegroundColor Gray

$targets = @(
    @{ Path = $env:TEMP;                                    Desc = "User temp folder" }
    @{ Path = "$env:WINDIR\Temp";                           Desc = "Windows temp folder" }
    @{ Path = "$env:WINDIR\SoftwareDistribution\Download";  Desc = "Windows Update cache" }
    @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"; Desc = "Thumbnail cache" }
    @{ Path = "$env:LOCALAPPDATA\D3DSCache";                Desc = "DirectX Shader Cache" }
    @{ Path = "$env:LOCALAPPDATA\NVIDIA\DXCache";           Desc = "NVIDIA Shader Cache" }
    @{ Path = "$env:LOCALAPPDATA\NVIDIA\GLCache";           Desc = "NVIDIA GL Cache" }
    @{ Path = "$env:LOCALAPPDATA\AMD\DxCache";              Desc = "AMD Shader Cache" }
)

$estimatedTotal = 0
foreach ($target in $targets) {
    $size = Get-FolderSizeMB -Path $target.Path
    if ($size -gt 0) {
        $estimatedTotal += $size
    }
}

Write-Host "  Estimated space to free: ~$([math]::Round($estimatedTotal, 0)) MB" -ForegroundColor White
Write-Host ""
Write-Host "  NOTE: Shader cache cleanup means the first launch of each" -ForegroundColor Yellow
Write-Host "  game may take slightly longer as shaders recompile." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "  Press Enter to continue"
Write-Host ""

# ---- Clean ----
Clear-FolderSafe -Path $env:TEMP -Description "User temp folder" -StepNum "1/8"
Clear-FolderSafe -Path "$env:WINDIR\Temp" -Description "Windows temp folder" -StepNum "2/8"

# Windows Update cache — stop service first
Write-Host "  [3/8] Windows Update cache..." -NoNewline
$wuRunning = (Get-Service wuauserv -ErrorAction SilentlyContinue).Status -eq "Running"
if ($wuRunning) { Stop-Service wuauserv -Force -ErrorAction SilentlyContinue }
$sizeBefore = Get-FolderSizeMB -Path "$env:WINDIR\SoftwareDistribution\Download"
Get-ChildItem "$env:WINDIR\SoftwareDistribution\Download" -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
$sizeAfter = Get-FolderSizeMB -Path "$env:WINDIR\SoftwareDistribution\Download"
$freed = [math]::Max(0, $sizeBefore - $sizeAfter)
$totalFreed += $freed
if ($wuRunning) { Start-Service wuauserv -ErrorAction SilentlyContinue }
Write-Host " Done ($([math]::Round($freed, 0)) MB freed)" -ForegroundColor Green

# Thumbnail cache — only .db files
Write-Host "  [4/8] Thumbnail cache..." -NoNewline
$thumbs = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
$thumbSize = ($thumbs | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
$thumbs | Remove-Item -Force -ErrorAction SilentlyContinue
$totalFreed += [math]::Round($thumbSize, 1)
Write-Host " Done ($([math]::Round($thumbSize, 0)) MB freed)" -ForegroundColor Green

Clear-FolderSafe -Path "$env:LOCALAPPDATA\D3DSCache" -Description "DirectX Shader Cache" -StepNum "5/8"
Clear-FolderSafe -Path "$env:LOCALAPPDATA\NVIDIA\DXCache" -Description "NVIDIA Shader Cache" -StepNum "6/8"
Clear-FolderSafe -Path "$env:LOCALAPPDATA\AMD\DxCache" -Description "AMD Shader Cache" -StepNum "7/8"

# Disk Cleanup (silent)
Write-Host "  [8/8] Disk Cleanup (silent)..." -NoNewline
$cleanupKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files"
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin"
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files"
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files"
)
foreach ($key in $cleanupKeys) {
    if (Test-Path $key) {
        New-ItemProperty -Path $key -Name "StateFlags0100" -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
Start-Process cleanmgr -ArgumentList "/sagerun:100" -Wait -ErrorAction SilentlyContinue
Write-Host " Done" -ForegroundColor Green

Add-ToolkitStepResult -Key "cleanup" -Tier "Safe" -Status "applied" -Reason "Freed ~$([math]::Round($totalFreed, 0)) MB"

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CLEANUP COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total space freed: ~$([math]::Round($totalFreed, 0)) MB" -ForegroundColor Green
Write-Host ""
Write-Host "  What was cleaned:" -ForegroundColor Gray
Write-Host "    - User & Windows temp files" -ForegroundColor Gray
Write-Host "    - Windows Update download cache" -ForegroundColor Gray
Write-Host "    - Thumbnail cache" -ForegroundColor Gray
Write-Host "    - DirectX / NVIDIA / AMD shader caches" -ForegroundColor Gray
Write-Host "    - Recycle Bin, Error Reports, Delivery Optimization" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to continue"
