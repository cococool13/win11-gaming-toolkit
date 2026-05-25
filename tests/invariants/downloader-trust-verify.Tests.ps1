#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Repo-wide invariant: every script that downloads a file to disk
    also verifies trust (SHA-256 OR Authenticode) in the same file.

.DESCRIPTION
    CLAUDE.md invariant #4: "Third-party tools (DDU, WinUtil) are
    downloaded at runtime and verified by SHA-256 against versions.json.
    Hash mismatch must abort, never warn-and-continue."

    Generalized: any script that writes a file to disk via the network
    must verify that file before invoking it. Acceptable verifiers:
      - Get-FileHash / Test-FileSha256 (SHA-256)
      - Get-AuthenticodeSignature / Test-FileAuthenticode (signed binary)

    Discrimination: file-download vs metadata-fetch.
    - File download (covered): Invoke-WebRequest -OutFile X,
      Get-FileFromWeb, .DownloadFile($url, $path)
    - Metadata fetch (excluded): Invoke-WebRequest without -OutFile
      (in-memory $response.Content). JSON manifests and API lookups
      live in this bucket; trusted-host expectation, no executable
      payload to verify.

    Current coverage (all compliant):
      - 0 prerequisites/install-runtimes.ps1 (Authenticode on VC++/DirectX)
      - lib/download-helpers.ps1 (Test-FileSha256 + Test-FileAuthenticode
        helpers + Get-FileFromWeb + Ensure-7Zip pipeline)
      - lib/gpu-download.ps1 (Get-GpuDriverInstaller wraps SHA→Authenticode
        fallback chain)

.NOTES
    # CROSS-PLATFORM-NOTE
    # Pure text scan; runs anywhere.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')

    # Patterns that mark a script as a "file downloader" (writes bytes
    # from the network to local disk). Order-insensitive — any match
    # promotes the script to the audit list.
    $script:DownloadPatterns = @(
        # Invoke-WebRequest -OutFile <something>
        # Capture the -OutFile presence anywhere in the call.
        '(?im)Invoke-WebRequest[^\r\n]*-OutFile\b'
        # Get-FileFromWeb is the toolkit's wrapper around IWR + sanity check
        '(?im)\bGet-FileFromWeb\b'
        # .NET WebClient style: $wc.DownloadFile(...)
        '(?im)\.DownloadFile\s*\('
        # BITS transfer
        '(?im)\bStart-BitsTransfer\b'
    )

    # Patterns that satisfy "trust verifier present in same file".
    $script:VerifyPatterns = @(
        '(?im)\bGet-FileHash\b'
        '(?im)\bTest-FileSha256\b'
        '(?im)\bGet-AuthenticodeSignature\b'
        '(?im)\bTest-FileAuthenticode\b'
    )

    # Acknowledged untrusted-by-design (none today). Use sparingly —
    # the right fix is to verify, not to silence. If a script genuinely
    # cannot verify (e.g. fetches signed-by-hash file BEFORE the hash
    # is known), document the rationale alongside its entry here.
    $script:KnownNoVerify = @()

    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $excludePattern = '(^|[\\/])(\.git|tests|profile|tools)([\\/]|$)'

    $script:DownloaderCases = @()
    $allPs1 = Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.ps1' -File |
        Where-Object { $_.FullName -notmatch $excludePattern }
    foreach ($f in $allPs1) {
        $content = Get-Content -Raw -LiteralPath $f.FullName
        $isDownloader = $false
        foreach ($pat in $script:DownloadPatterns) {
            if ($content -match $pat) { $isDownloader = $true; break }
        }
        if (-not $isDownloader) { continue }

        $relPath = $f.FullName.Substring($repoRoot.Length + 1)
        $script:DownloaderCases += @{
            Path = $relPath
            FullPath = $f.FullName
            NoVerifyOk = ($script:KnownNoVerify -contains $relPath)
        }
    }
}

Describe 'Invariant: every file-downloader verifies trust in-file' {

    It '<Path> verifies trust (SHA-256 or Authenticode) before exec' -ForEach $script:DownloaderCases {
        if ($NoVerifyOk) {
            Set-ItResult -Skipped -Because 'tracked in $KnownNoVerify; verification deliberately deferred'
            return
        }

        # Inline patterns: $script: scope doesn't survive into It-body
        # at runtime. Keep in sync with BeforeDiscovery $VerifyPatterns.
        $verifyPatterns = @(
            '(?im)\bGet-FileHash\b'
            '(?im)\bTest-FileSha256\b'
            '(?im)\bGet-AuthenticodeSignature\b'
            '(?im)\bTest-FileAuthenticode\b'
        )

        $content = Get-Content -Raw -LiteralPath $FullPath
        $hasVerifier = $false
        foreach ($pat in $verifyPatterns) {
            if ($content -match $pat) { $hasVerifier = $true; break }
        }

        $hasVerifier | Should -BeTrue `
            -Because "downloader scripts must verify the file before exec — none of Get-FileHash / Test-FileSha256 / Get-AuthenticodeSignature / Test-FileAuthenticode were found in '$Path'"
    }
}
