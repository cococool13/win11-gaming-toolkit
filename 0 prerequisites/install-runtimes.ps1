# ============================================================
# Install Gaming Prerequisites (C++ Runtimes & DirectX)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Many games require Visual C++ Redistributables and the legacy
# DirectX runtime. This script installs ALL versions silently.
# Missing these causes "VCRUNTIME140.dll not found" and similar errors.
#
# Run as Administrator in PowerShell.
# Requires internet connection.
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Install Gaming Prerequisites" -ForegroundColor Cyan
Write-Host "  (Visual C++ Runtimes & DirectX)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check internet
if (-not (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Internet connection required." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ProgressPreference = 'SilentlyContinue'
$tempDir = "$env:SystemRoot\Temp\GamingPrereqs"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# ---- Visual C++ Redistributables ----
Write-Host "[1/3] Downloading Visual C++ Redistributables..." -ForegroundColor Yellow

$vcRedists = @(
    @{ Name = "VC++ 2005 x86";  URL = "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE"; File = "vcredist2005_x86.exe"; Args = '/Q /C:"msiexec /i vcredist.msi /qn /norestart"' },
    @{ Name = "VC++ 2005 x64";  URL = "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE"; File = "vcredist2005_x64.exe"; Args = '/Q /C:"msiexec /i vcredist.msi /qn /norestart"' },
    @{ Name = "VC++ 2008 x86";  URL = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"; File = "vcredist2008_x86.exe"; Args = "/q" },
    @{ Name = "VC++ 2008 x64";  URL = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"; File = "vcredist2008_x64.exe"; Args = "/q" },
    @{ Name = "VC++ 2010 x86";  URL = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"; File = "vcredist2010_x86.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2010 x64";  URL = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"; File = "vcredist2010_x64.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2012 x86";  URL = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"; File = "vcredist2012_x86.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2012 x64";  URL = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"; File = "vcredist2012_x64.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2013 x86";  URL = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x86.exe"; File = "vcredist2013_x86.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2013 x64";  URL = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe"; File = "vcredist2013_x64.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2015-2022 x86"; URL = "https://aka.ms/vs/17/release/vc_redist.x86.exe"; File = "vcredist2022_x86.exe"; Args = "/quiet /norestart" },
    @{ Name = "VC++ 2015-2022 x64"; URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"; File = "vcredist2022_x64.exe"; Args = "/quiet /norestart" }
)

foreach ($vc in $vcRedists) {
    $filePath = Join-Path $tempDir $vc.File
    if (-not (Test-Path $filePath)) {
        Write-Host "  Downloading $($vc.Name)..." -NoNewline
        try {
            Invoke-WebRequest -Uri $vc.URL -OutFile $filePath -UseBasicParsing
            # Verify the downloaded file has a valid Microsoft signature
            $sig = Get-AuthenticodeSignature $filePath
            if ($sig.Status -ne 'Valid') {
                Write-Host " WARNING: Invalid signature, skipping" -ForegroundColor Yellow
                Remove-Item $filePath -Force -ErrorAction SilentlyContinue
                continue
            }
            Write-Host " Done" -ForegroundColor Green
        } catch {
            Write-Host " Failed" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "[2/3] Installing Visual C++ Redistributables..." -ForegroundColor Yellow

$installFailed = 0
foreach ($vc in $vcRedists) {
    $filePath = Join-Path $tempDir $vc.File
    if (Test-Path $filePath) {
        $fileSize = (Get-Item $filePath).Length
        if ($fileSize -lt 10000) {
            Write-Host "  Skipping $($vc.Name) — download incomplete ($fileSize bytes)" -ForegroundColor Yellow
            $installFailed++
            continue
        }
        Write-Host "  Installing $($vc.Name)..." -NoNewline
        try {
            Start-Process -Wait $filePath -ArgumentList $vc.Args -WindowStyle Hidden
            Write-Host " Done" -ForegroundColor Green
        } catch {
            Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Yellow
            $installFailed++
        }
    } else {
        Write-Host "  Skipping $($vc.Name) — download failed" -ForegroundColor Yellow
        $installFailed++
    }
}

# ---- DirectX Legacy Runtime ----
Write-Host ""
Write-Host "[3/3] Installing DirectX Legacy Runtime (June 2010)..." -ForegroundColor Yellow

$dxFile = Join-Path $tempDir "DirectX.exe"
$dxDir = Join-Path $tempDir "DirectX"

Write-Host "  Downloading..." -NoNewline
try {
    Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -OutFile $dxFile -UseBasicParsing
    Write-Host " Done" -ForegroundColor Green

    Write-Host "  Extracting..." -NoNewline
    Start-Process -Wait $dxFile -ArgumentList "/Q /T:`"$dxDir`""
    Write-Host " Done" -ForegroundColor Green

    Write-Host "  Installing..." -NoNewline
    Start-Process -Wait "$dxDir\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed — you can install manually from microsoft.com" -ForegroundColor Yellow
}

# Cleanup temp files
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($installFailed -eq 0) {
    Write-Host "  [DONE] All gaming prerequisites installed!" -ForegroundColor Green
} else {
    Write-Host "  [DONE] Installation complete with $installFailed skipped items." -ForegroundColor Yellow
    Write-Host "  Re-run this script to retry failed downloads." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Installed:" -ForegroundColor Gray
Write-Host "    - Visual C++ 2005, 2008, 2010, 2012, 2013, 2015-2022" -ForegroundColor Gray
Write-Host "    - DirectX June 2010 Legacy Runtime" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
