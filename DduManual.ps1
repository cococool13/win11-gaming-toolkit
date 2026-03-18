param(
    [switch]$PrepareSafeMode
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    exit
}

$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
Clear-Host
$ProgressPreference = "SilentlyContinue"

function Get-FileFromWeb {
    param([Parameter(Mandatory)][string]$URL, [Parameter(Mandatory)][string]$File)
    Invoke-WebRequest -Uri $URL -OutFile $File -UseBasicParsing
}

if (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Write-Host "Internet Connection Required`n" -ForegroundColor Red
    Pause
    exit
}

$stageRoot = "$env:ProgramData\GamingOpt"
$dduRoot = Join-Path $stageRoot "DDU"
$7zInstaller = "$env:SystemRoot\Temp\7 Zip.exe"
$dduInstaller = "$env:SystemRoot\Temp\DDU.exe"
$leaveSafeMode = Join-Path $stageRoot "Leave-Safe-Mode.cmd"

Write-Host "Preparing guided DDU automation..." -ForegroundColor Cyan

Get-FileFromWeb -URL "https://www.7-zip.org/a/7z2301-x64.exe" -File $7zInstaller
$sig = Get-AuthenticodeSignature $7zInstaller
if ($sig.Status -ne "Valid") {
    Write-Host "[ABORT] 7-Zip installer signature is invalid." -ForegroundColor Red
    Pause
    exit 1
}
Start-Process -Wait $7zInstaller -ArgumentList "/S"

Get-FileFromWeb -URL "https://www.wagnardsoft.com/DDU/download/DDU%20v18.1.4.2_setup.exe" -File $dduInstaller
if (-not (Test-Path $dduRoot)) {
    New-Item -ItemType Directory -Path $dduRoot -Force | Out-Null
}
& "C:\Program Files\7-Zip\7z.exe" x $dduInstaller -o"$dduRoot" -y | Out-Null

$dduExe = Join-Path $dduRoot "Display Driver Uninstaller.exe"
if (-not (Test-Path $dduExe)) {
    Write-Host "[ABORT] DDU extraction failed." -ForegroundColor Red
    Pause
    exit 1
}

$dduSettingsDir = Join-Path $dduRoot "Settings"
if (-not (Test-Path $dduSettingsDir)) {
    New-Item -ItemType Directory -Path $dduSettingsDir -Force | Out-Null
}
@'
<?xml version="1.0" encoding="utf-8"?>
<DisplayDriverUninstaller Version="18.1.4.2">
	<Settings>
		<SelectedLanguage>en-US</SelectedLanguage>
		<CheckUpdates>False</CheckUpdates>
		<CreateRestorePoint>False</CreateRestorePoint>
		<SaveLogs>True</SaveLogs>
		<PreventWinUpdate>True</PreventWinUpdate>
		<RememberLastChoice>False</RememberLastChoice>
	</Settings>
</DisplayDriverUninstaller>
'@ | Set-Content -Path (Join-Path $dduSettingsDir "Settings.xml") -Force

@'
@echo off
bcdedit /deletevalue {current} safeboot >nul 2>&1
shutdown -r -t 5
'@ | Set-Content -Path $leaveSafeMode -Force

Write-Host ""
Write-Host "DDU staged at:" -ForegroundColor Green
Write-Host "  $dduExe" -ForegroundColor White
Write-Host "Safe Mode exit helper:" -ForegroundColor Green
Write-Host "  $leaveSafeMode" -ForegroundColor White
Write-Host ""

if ($PrepareSafeMode) {
    Write-Host "Setting next boot to Safe Mode (minimal)..." -ForegroundColor Yellow
    cmd /c "bcdedit /set {current} safeboot minimal"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ABORT] Failed to schedule Safe Mode boot." -ForegroundColor Red
        Pause
        exit 1
    }
    Write-Host "After reboot: run DDU from the staged path, then run Leave-Safe-Mode.cmd." -ForegroundColor Yellow
    Write-Host "Rebooting in 5 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    shutdown -r -t 0
    exit 0
}

Write-Host "Launching DDU in the current session." -ForegroundColor Yellow
Write-Host "If you want Safe Mode first, run DduAuto.ps1 instead." -ForegroundColor Yellow
Start-Process $dduExe
Pause
