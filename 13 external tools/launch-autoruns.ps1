#Requires -Version 5.1
<#
.SYNOPSIS
    Download and launch Sysinternals Autoruns (startup entry inspector).

.DESCRIPTION
    Autoruns lists every auto-start location Windows has — Run keys, services,
    scheduled tasks, drivers, codecs, shell extensions — far past what Task
    Manager's Startup tab shows. It is the tool to reach for when something
    is starting with Windows and you cannot find where it is configured.

    Nothing is installed. The Sysinternals archive is fetched to the toolkit
    staging directory, the 64-bit executable is extracted, its Authenticode
    signature is verified against Microsoft, and only then is it run.

    Trust: the zip itself carries no Authenticode signature, so verification
    happens on the extracted .exe before execution. A failed signature
    deletes the whole staging folder and aborts.

    Why Authenticode and not a pinned SHA-256: Sysinternals ships a rolling
    Autoruns.zip at a fixed URL, so a pinned hash would break on their next
    release. The Microsoft signature survives updates.

    This script mutates nothing itself. Disabling an entry inside Autoruns
    is a change the toolkit does not track in its manifest — Autoruns keeps
    its own backups, and re-ticking the box is the revert. It is a launcher,
    so it has no paired revert sibling; see $KnownUnpairable in
    tests/invariants/mutator-paired-restore.Tests.ps1.

.PARAMETER KeepDownload
    Leave the extracted tool in the staging directory instead of deleting it
    on exit.

.EXAMPLE
    PS> .\launch-autoruns.ps1
    Fetch, verify, run, then clean up.

.EXAMPLE
    PS> .\launch-autoruns.ps1 -WhatIf
    Show what would be downloaded and run without touching the network.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced (third-party tool; changes are user-driven)

    Anti-cheat impact: None from this script. Note that disabling a driver
                       or service entry inside Autoruns can affect an
                       anti-cheat that expects it — read each entry before
                       unticking it.
    Reboot required:   No to run. Entries you disable apply at next logon.
    Disk impact:       ~4 MB transient in the staging directory, removed on
                       exit unless -KeepDownload is passed.

    Sources:  Microsoft Learn — Autoruns for Windows
              https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns

    Exit codes:
      0  Tool launched (or -WhatIf preview completed)
      1  Download or extraction failed
      2  Signature verification failed — staging removed, nothing executed
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [switch]$KeepDownload
)

. (Join-Path $PSScriptRoot '..' 'lib/download-helpers.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/ui-helpers.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/version-manifest.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/toolkit-state.ps1')

UI-Header -Title 'Sysinternals Autoruns' -Subtitle 'Every auto-start location on this machine'
UI-RequireAdmin

# Downloading and executing a third-party binary belongs in the audit trail.
Write-ToolkitScriptStart

$manifest = Get-ToolManifest -Name 'autoruns'
$staging = Join-Path $script:GamingOptRoot 'external-tools/autoruns'
$archive = Join-Path $script:GamingOptRoot 'external-tools/Autoruns.zip'
$target = Join-Path $staging $manifest.archiveEntry

if (-not $PSCmdlet.ShouldProcess($manifest.url, 'Download and launch Autoruns')) {
    Write-Host "  [WHATIF] Would download $($manifest.url)" -ForegroundColor Yellow
    Write-Host "  [WHATIF] Would extract $($manifest.archiveEntry)" -ForegroundColor Yellow
    Write-Host "  [WHATIF] Would verify Authenticode signer '$($manifest.signerCN)'" -ForegroundColor Yellow
    exit 0
}

Ensure-Internet
Ensure-Directory -Path $staging

try {
    Get-FileFromWeb -Url $manifest.url -File $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $staging -Force
    Remove-Item $archive -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "  [ERROR] Download or extraction failed: $_" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $target)) {
    Write-Host "  [ERROR] '$($manifest.archiveEntry)' not found in the archive." -ForegroundColor Red
    exit 1
}

# The zip is unsigned, so the extracted binary is what gets verified —
# checking the archive would prove nothing about what actually runs.
if (-not (Test-FileAuthenticode -Path $target -ExpectedSignerCN $manifest.signerCN)) {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [ERROR] Signature check failed for $($manifest.signerCN) — staging removed, nothing was run." -ForegroundColor Red
    exit 2
}

Write-Host "  [OK] Signature verified: $($manifest.signerCN)" -ForegroundColor Green
Write-Host '  Read each entry before unticking it — some belong to anti-cheat.' -ForegroundColor Cyan

Start-Process -FilePath $target -Wait

if (-not $KeepDownload) {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0
