param(
    [switch]$PrepareSafeMode,
    [switch]$Automatic
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    exit
}

$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
Clear-Host
$ProgressPreference = "SilentlyContinue"

$stageRoot = Join-Path $env:ProgramData "GamingOpt"
$dduRoot = Join-Path $stageRoot "DDU"
$resumeScriptPath = Join-Path $stageRoot "DDU-Resume.ps1"
$leaveSafeMode = Join-Path $stageRoot "Leave-Safe-Mode.cmd"
$launchLog = Join-Path $stageRoot "DDU-Auto.log"
$sevenZipInstaller = Join-Path $env:TEMP "7zip-installer.exe"
$dduInstaller = Join-Path $env:TEMP "DDU-setup.exe"
$runOnceName = "*!GamingOpt-DDU"

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Get-FileFromWeb {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$File
    )

    Invoke-WebRequest -Uri $Url -OutFile $File -UseBasicParsing
}

function Ensure-Internet {
    if (-not (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        throw "Internet connection required"
    }
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Ensure-7Zip {
    $sevenZipExe = Join-Path ${env:ProgramFiles} "7-Zip\7z.exe"
    if (Test-Path $sevenZipExe) {
        return $sevenZipExe
    }

    Write-Info "Installing 7-Zip for DDU extraction..."
    Get-FileFromWeb -Url "https://www.7-zip.org/a/7z2301-x64.exe" -File $sevenZipInstaller
    if (-not (Test-Path $sevenZipInstaller) -or (Get-Item $sevenZipInstaller).Length -lt 100000) {
        throw "7-Zip download failed"
    }

    $signature = Get-AuthenticodeSignature $sevenZipInstaller
    if ($signature.Status -ne "Valid") {
        throw "7-Zip installer signature is invalid"
    }

    Start-Process -FilePath $sevenZipInstaller -ArgumentList "/S" -Wait
    if (-not (Test-Path $sevenZipExe)) {
        throw "7-Zip installation failed"
    }

    return $sevenZipExe
}

function Stage-DduPayload {
    Ensure-Directory -Path $stageRoot
    Ensure-Directory -Path $dduRoot

    $sevenZipExe = Ensure-7Zip

    Write-Info "Downloading DDU..."
    Get-FileFromWeb -Url "https://www.wagnardsoft.com/DDU/download/DDU%20v18.1.4.2_setup.exe" -File $dduInstaller
    if (-not (Test-Path $dduInstaller) -or (Get-Item $dduInstaller).Length -lt 100000) {
        throw "DDU download failed"
    }

    Remove-Item -Path (Join-Path $dduRoot "*") -Recurse -Force -ErrorAction SilentlyContinue
    & $sevenZipExe x $dduInstaller "-o$dduRoot" -y | Out-Null

    $dduExe = Join-Path $dduRoot "Display Driver Uninstaller.exe"
    if (-not (Test-Path $dduExe)) {
        throw "DDU extraction failed"
    }

    $dduSettingsDir = Join-Path $dduRoot "Settings"
    Ensure-Directory -Path $dduSettingsDir

    @'
<?xml version="1.0" encoding="utf-8"?>
<DisplayDriverUninstaller Version="18.1.4.2">
	<Settings>
		<SelectedLanguage>en-US</SelectedLanguage>
		<RemoveMonitors>True</RemoveMonitors>
		<RemoveCrimsonCache>True</RemoveCrimsonCache>
		<RemoveAMDDirs>True</RemoveAMDDirs>
		<RemoveAudioBus>True</RemoveAudioBus>
		<RemoveAMDKMPFD>True</RemoveAMDKMPFD>
		<RemoveNvidiaDirs>True</RemoveNvidiaDirs>
		<RemovePhysX>True</RemovePhysX>
		<Remove3DTVPlay>True</Remove3DTVPlay>
		<RemoveGFE>True</RemoveGFE>
		<RemoveNVBROADCAST>True</RemoveNVBROADCAST>
		<RemoveNVCP>True</RemoveNVCP>
		<RemoveINTELCP>True</RemoveINTELCP>
		<RemoveINTELIGS>True</RemoveINTELIGS>
		<RemoveOneAPI>True</RemoveOneAPI>
		<RemoveEnduranceGaming>True</RemoveEnduranceGaming>
		<RemoveIntelNpu>True</RemoveIntelNpu>
		<RemoveAMDCP>True</RemoveAMDCP>
		<UseRoamingConfig>False</UseRoamingConfig>
		<CheckUpdates>False</CheckUpdates>
		<CreateRestorePoint>False</CreateRestorePoint>
		<SaveLogs>True</SaveLogs>
		<RemoveVulkan>True</RemoveVulkan>
		<ShowOffer>False</ShowOffer>
		<EnableSafeModeDialog>False</EnableSafeModeDialog>
		<PreventWinUpdate>True</PreventWinUpdate>
		<UsedBCD>False</UsedBCD>
		<KeepNVCPopt>False</KeepNVCPopt>
		<RememberLastChoice>False</RememberLastChoice>
		<LastSelectedGPUIndex>0</LastSelectedGPUIndex>
		<LastSelectedTypeIndex>0</LastSelectedTypeIndex>
	</Settings>
</DisplayDriverUninstaller>
'@ | Set-Content -Path (Join-Path $dduSettingsDir "Settings.xml") -Force

    Set-ItemProperty -Path (Join-Path $dduSettingsDir "Settings.xml") -Name IsReadOnly -Value $true

    @'
@echo off
bcdedit /deletevalue {current} safeboot >nul 2>&1
shutdown -r -t 5
'@ | Set-Content -Path $leaveSafeMode -Force

    return $dduExe
}

function New-DduResumeScript {
    param(
        [string]$DduExe,
        [string[]]$DduArguments
    )

    $quotedArgs = @($DduArguments | ForEach-Object { "'{0}'" -f $_.Replace("'", "''") }) -join ", "
    $argumentsArray = if ([string]::IsNullOrWhiteSpace($quotedArgs)) { "@()" } else { "@($quotedArgs)" }

    $scriptBody = @"
`$ErrorActionPreference = 'Continue'
`$Host.UI.RawUI.WindowTitle = 'GamingOpt DDU Resume'
Start-Transcript -Path '$launchLog' -Append -Force | Out-Null

try {
    cmd /c "bcdedit /deletevalue {current} safeboot" 2>&1 | Out-Null
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name '$runOnceName' -ErrorAction SilentlyContinue

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        `$quotedSelf = '"' + `$PSCommandPath + '"'
        Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `$quotedSelf"
        exit
    }

    if (-not (Test-Path '$DduExe')) {
        Write-Host '[ABORT] Staged DDU executable is missing.' -ForegroundColor Red
        Write-Host 'Use the Leave-Safe-Mode helper if you want to reboot immediately.' -ForegroundColor Yellow
        exit 1
    }

    `$dduArguments = $argumentsArray
    if (`$dduArguments.Count -gt 0) {
        Start-Process -FilePath '$DduExe' -ArgumentList `$dduArguments -Wait
    } else {
        Start-Process -FilePath '$DduExe' -Wait
    }
} finally {
    Stop-Transcript | Out-Null
}
"@

    Set-Content -Path $resumeScriptPath -Value $scriptBody -Force
}

function Register-DduRunOnce {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Force | Out-Null
    $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Maximized -File `"$resumeScriptPath`""
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name $runOnceName -Value $command -PropertyType String -Force | Out-Null
}

function Remove-DduRunOnce {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name $runOnceName -ErrorAction SilentlyContinue
}

function Set-DriverSearchPolicy {
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
}

try {
    Ensure-Internet

    Write-Info "Preparing DDU payload..."
    $dduExe = Stage-DduPayload
    Set-DriverSearchPolicy

    Write-Host ""
    Write-Host "DDU staged at:" -ForegroundColor Green
    Write-Host "  $dduExe" -ForegroundColor White
    Write-Host "Safe Mode exit helper:" -ForegroundColor Green
    Write-Host "  $leaveSafeMode" -ForegroundColor White
    Write-Host ""

    if ($PrepareSafeMode) {
        $dduArguments = if ($Automatic) {
            @("-CleanSoundBlaster", "-CleanRealtek", "-CleanAllGpus", "-Restart")
        } else {
            @()
        }

        New-DduResumeScript -DduExe $dduExe -DduArguments $dduArguments
        Register-DduRunOnce

        Write-Info "Scheduling next boot into Safe Mode..."
        cmd /c "bcdedit /set {current} safeboot minimal"
        if ($LASTEXITCODE -ne 0) {
            Remove-DduRunOnce
            throw "Failed to schedule Safe Mode boot"
        }

        if ($Automatic) {
            Write-Host "The next admin login in Safe Mode will auto-run DDU with the aggressive clean-and-restart arguments." -ForegroundColor Yellow
        } else {
            Write-Host "The next admin login in Safe Mode will auto-launch DDU for a manual run." -ForegroundColor Yellow
        }
        Write-Host "Safe boot is cleared at handoff time to prevent boot loops if DDU fails." -ForegroundColor Yellow
        Write-Host "Rebooting in 5 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        shutdown -r -t 0
        exit 0
    }

    Write-Host "Launching DDU in the current session." -ForegroundColor Yellow
    Write-Host "Use DduAuto.ps1 for the unattended Safe Mode handoff." -ForegroundColor Yellow
    Start-Process -FilePath $dduExe
    Pause
} catch {
    Write-Host "[ABORT] $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}
