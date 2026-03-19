# ============================================================
# Shared Download / File Helpers
# Windows 11 Gaming Optimization Guide
# ============================================================
# Extracted from DduManual.ps1 for reuse by GPU driver scripts.
# ============================================================

$script:GamingOptRoot = Join-Path $env:ProgramData "GamingOpt"

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
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

function Get-FileFromWeb {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$File
    )

    Write-Info "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $File -UseBasicParsing
    if (-not (Test-Path $File) -or (Get-Item $File).Length -lt 1000) {
        throw "Download failed or file too small: $File"
    }
}

function Test-FileSha256 {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedHash
    )

    $actualHash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    return $actualHash -eq $ExpectedHash.ToLowerInvariant()
}

function Test-FileAuthenticode {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$ExpectedSignerCN = ""
    )

    $signature = Get-AuthenticodeSignature $Path
    if ($signature.Status -ne "Valid") {
        return $false
    }
    if ($ExpectedSignerCN -ne "" -and $signature.SignerCertificate.Subject -notmatch [regex]::Escape($ExpectedSignerCN)) {
        return $false
    }
    return $true
}

function Ensure-7Zip {
    $sevenZipExe = Join-Path ${env:ProgramFiles} "7-Zip\7z.exe"
    if (Test-Path $sevenZipExe) {
        return $sevenZipExe
    }

    # Fetch version info from manifest (GitHub → cache → bundled)
    . "$PSScriptRoot\version-manifest.ps1"
    $sevenZipManifest = Get-ToolManifest -Name "sevenZip"
    $sevenZipInstaller = Join-Path $env:TEMP "7zip-installer.exe"
    $sevenZipUrl = $sevenZipManifest.url
    $sevenZipHash = $sevenZipManifest.sha256

    Write-Info "Installing 7-Zip v$($sevenZipManifest.version) for archive extraction..."
    Get-FileFromWeb -Url $sevenZipUrl -File $sevenZipInstaller

    # Verify SHA-256 hash first (if hash is a valid hex string)
    if ($sevenZipHash -match "^[0-9a-fA-F]{64}$") {
        if (-not (Test-FileSha256 -Path $sevenZipInstaller -ExpectedHash $sevenZipHash)) {
            Remove-Item $sevenZipInstaller -Force -ErrorAction SilentlyContinue
            throw "7-Zip installer hash mismatch — update pinned hash if 7-Zip version changed"
        }
    }

    # Also verify Authenticode signature
    $signature = Get-AuthenticodeSignature $sevenZipInstaller
    if ($signature.Status -ne "Valid") {
        Remove-Item $sevenZipInstaller -Force -ErrorAction SilentlyContinue
        throw "7-Zip installer signature is invalid"
    }

    Start-Process -FilePath $sevenZipInstaller -ArgumentList "/S" -Wait
    if (-not (Test-Path $sevenZipExe)) {
        throw "7-Zip installation failed"
    }

    return $sevenZipExe
}

function Restore-DriverSearchPolicy {
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}
