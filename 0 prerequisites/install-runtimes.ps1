# ============================================================
# Install Gaming Prerequisites (Smart)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Many games require Visual C++ Redistributables and the legacy
# DirectX runtime. This script installs ALL versions silently.
# Missing these causes "VCRUNTIME140.dll not found" errors.
#
# Smart features:
#   - Detects already-installed VC++ versions, skips them
#   - Authenticode signature verification on all downloads
#   - Manifest integration for tracking
#
# Replaces: install-runtimes.ps1 (dumb version)
# Must be run as Administrator. Requires internet connection.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Prerequisites"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Install Gaming Prerequisites" -ForegroundColor Cyan
Write-Host "  (Visual C++ Runtimes & DirectX)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check internet
if (-not (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Internet connection required." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$state = Initialize-ToolkitState
$ProgressPreference = 'SilentlyContinue'
$tempDir = "$env:SystemRoot\Temp\GamingPrereqs"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# ============================================================
# Detect installed VC++ Redistributables
# ============================================================
Write-Host "  Scanning installed runtimes..." -ForegroundColor Gray

function Get-InstalledVcRedists {
    $installed = @()

    # Check both registry locations (x86 and x64)
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($regPath in $regPaths) {
        $entries = Get-ItemProperty $regPath -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match "Visual C\+\+|Microsoft Visual C\+\+" }
        foreach ($entry in $entries) {
            $installed += $entry.DisplayName
        }
    }

    # Also check via Get-Package (catches some that registry misses)
    $packages = Get-Package -Name "*Visual C++*" -ErrorAction SilentlyContinue
    foreach ($pkg in $packages) {
        $installed += $pkg.Name
    }

    return $installed | Sort-Object -Unique
}

$installedRedists = @(Get-InstalledVcRedists)

function Test-VcRedistInstalled {
    param([string]$Name)

    # Extract year and architecture from name like "VC++ 2015-2022 x64"
    $yearMatch = [regex]::Match($Name, '(\d{4})')
    $archMatch = [regex]::Match($Name, '(x86|x64)')

    if (-not $yearMatch.Success) { return $false }

    $year = $yearMatch.Groups[1].Value
    $arch = if ($archMatch.Success) { $archMatch.Groups[1].Value } else { "" }

    foreach ($installed in $installedRedists) {
        $installedLower = $installed.ToLower()
        # Handle "2015-2022" range — check if any version in the range is installed
        if ($Name -match "2015-2022") {
            if ($installedLower -match "(2015|2017|2019|2022)" -and
                ($arch -eq "" -or $installedLower -match $arch.ToLower())) {
                return $true
            }
        } else {
            if ($installedLower -match $year -and
                ($arch -eq "" -or $installedLower -match $arch.ToLower())) {
                return $true
            }
        }
    }
    return $false
}

# ============================================================
# Define VC++ Redistributables
# ============================================================
$vcRedists = @(
    @{ Name = "VC++ 2005 x86";  URL = "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE"; File = "vcredist2005_x86.exe"; Args = '/Q /C:"msiexec /i vcredist.msi /qn /norestart"' }
    @{ Name = "VC++ 2005 x64";  URL = "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE"; File = "vcredist2005_x64.exe"; Args = '/Q /C:"msiexec /i vcredist.msi /qn /norestart"' }
    @{ Name = "VC++ 2008 x86";  URL = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"; File = "vcredist2008_x86.exe"; Args = "/q" }
    @{ Name = "VC++ 2008 x64";  URL = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"; File = "vcredist2008_x64.exe"; Args = "/q" }
    @{ Name = "VC++ 2010 x86";  URL = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"; File = "vcredist2010_x86.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2010 x64";  URL = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"; File = "vcredist2010_x64.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2012 x86";  URL = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"; File = "vcredist2012_x86.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2012 x64";  URL = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"; File = "vcredist2012_x64.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2013 x86";  URL = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x86.exe"; File = "vcredist2013_x86.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2013 x64";  URL = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe"; File = "vcredist2013_x64.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2015-2022 x86"; URL = "https://aka.ms/vs/17/release/vc_redist.x86.exe"; File = "vcredist2022_x86.exe"; Args = "/quiet /norestart" }
    @{ Name = "VC++ 2015-2022 x64"; URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"; File = "vcredist2022_x64.exe"; Args = "/quiet /norestart" }
)

# ============================================================
# Preview: show what needs installing
# ============================================================
$needed = @()
$alreadyInstalled = @()

foreach ($vc in $vcRedists) {
    if (Test-VcRedistInstalled -Name $vc.Name) {
        $alreadyInstalled += $vc.Name
    } else {
        $needed += $vc
    }
}

if ($alreadyInstalled.Count -gt 0) {
    Write-Host "  Already installed ($($alreadyInstalled.Count)):" -ForegroundColor Gray
    foreach ($name in $alreadyInstalled) {
        Write-Host "    [OK] $name" -ForegroundColor DarkGreen
    }
    Write-Host ""
}

# Check DirectX
$dxInstalled = Test-Path "$env:SystemRoot\System32\d3dx9_43.dll"
$dxStatus = if ($dxInstalled) { "installed" } else { "needed" }

if ($needed.Count -eq 0 -and $dxInstalled) {
    Write-Host "  All prerequisites already installed. Nothing to do." -ForegroundColor Green
    Add-ToolkitStepResult -Key "prerequisites" -Tier "Safe" -Status "preexisting" -Reason "All VC++ runtimes and DirectX already installed"
    Read-Host "Press Enter to exit"
    exit 0
}

if ($needed.Count -gt 0) {
    Write-Host "  Need to install ($($needed.Count)):" -ForegroundColor Yellow
    foreach ($vc in $needed) {
        Write-Host "    $($vc.Name)" -ForegroundColor White
    }
}
if (-not $dxInstalled) {
    Write-Host "    DirectX June 2010 Legacy Runtime" -ForegroundColor White
}
Write-Host ""
Write-Host "  Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "  Press Enter to continue"
Write-Host ""

# ============================================================
# Download & Install needed VC++ Redistributables
# ============================================================
$totalSteps = $needed.Count + $(if (-not $dxInstalled) { 1 } else { 0 })
$currentStep = 0
$installFailed = 0
$installSuccess = 0

foreach ($vc in $needed) {
    $currentStep++
    $filePath = Join-Path $tempDir $vc.File

    Write-Host "  [$currentStep/$totalSteps] $($vc.Name)..." -NoNewline

    # Download
    try {
        Invoke-WebRequest -Uri $vc.URL -OutFile $filePath -UseBasicParsing -ErrorAction Stop

        # Verify Authenticode signature
        $sig = Get-AuthenticodeSignature $filePath
        if ($sig.Status -ne 'Valid') {
            Write-Host " Signature invalid, skipping" -ForegroundColor Yellow
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            $installFailed++
            continue
        }
    } catch {
        Write-Host " Download failed" -ForegroundColor Red
        $installFailed++
        continue
    }

    # Install
    try {
        $fileSize = (Get-Item $filePath).Length
        if ($fileSize -lt 10000) {
            Write-Host " Download incomplete ($fileSize bytes)" -ForegroundColor Yellow
            $installFailed++
            continue
        }
        Start-Process -Wait $filePath -ArgumentList $vc.Args -WindowStyle Hidden -ErrorAction Stop
        Write-Host " Done" -ForegroundColor Green
        $installSuccess++
    } catch {
        Write-Host " Install failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $installFailed++
    }
}

# ============================================================
# DirectX Legacy Runtime
# ============================================================
if (-not $dxInstalled) {
    $currentStep++
    Write-Host "  [$currentStep/$totalSteps] DirectX June 2010 Legacy Runtime..." -NoNewline

    $dxFile = Join-Path $tempDir "DirectX.exe"
    $dxDir = Join-Path $tempDir "DirectX"

    try {
        Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -OutFile $dxFile -UseBasicParsing -ErrorAction Stop

        # Verify Authenticode signature before running
        $dxSig = Get-AuthenticodeSignature $dxFile
        if ($dxSig.Status -ne 'Valid') {
            Write-Host " Signature invalid, skipping" -ForegroundColor Yellow
            Remove-Item $dxFile -Force -ErrorAction SilentlyContinue
            $installFailed++
            continue
        }

        Start-Process -Wait $dxFile -ArgumentList "/Q /T:`"$dxDir`"" -ErrorAction Stop
        Start-Process -Wait "$dxDir\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden -ErrorAction Stop
        Write-Host " Done" -ForegroundColor Green
        $installSuccess++
    } catch {
        Write-Host " Failed" -ForegroundColor Yellow
        $installFailed++
    }
} else {
    Write-Host "  DirectX Legacy Runtime: already installed" -ForegroundColor DarkGreen
}

# Cleanup temp files
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

$totalInstalled = $alreadyInstalled.Count + $installSuccess
Add-ToolkitStepResult -Key "prerequisites" -Tier "Safe" -Status "applied" `
    -Reason "Installed $installSuccess new, $($alreadyInstalled.Count) already present, $installFailed failed"

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PREREQUISITES COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Already installed: $($alreadyInstalled.Count) runtimes" -ForegroundColor Gray
Write-Host "  Newly installed:   $installSuccess runtimes" -ForegroundColor Green
if ($installFailed -gt 0) {
    Write-Host "  Failed:            $installFailed runtimes" -ForegroundColor Yellow
    Write-Host "  Re-run to retry failed installs." -ForegroundColor Yellow
}
Write-Host "  DirectX Legacy:    $dxStatus" -ForegroundColor $(if ($dxInstalled) { "Gray" } else { "Green" })
Write-Host ""
Read-Host "Press Enter to continue"
