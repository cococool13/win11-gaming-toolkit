#Requires -Version 5.1
<#
.SYNOPSIS
    Download and launch O&O ShutUp10++ (telemetry and privacy settings).

.DESCRIPTION
    O&O ShutUp10++ is a free portable tool that exposes Windows telemetry,
    diagnostics, and privacy settings as a single checklist. Nothing is
    installed: one .exe is fetched to the toolkit staging directory, verified,
    and run. The toolkit does not drive it or preselect anything — every
    change is yours to make in its UI, and its own "Create a restore point"
    action is the revert path.

    Trust: the download is verified by Authenticode against the publisher CN
    in versions.json before it is ever executed. A failed or missing
    signature aborts and deletes the file; it never warns and continues.

    Why Authenticode and not a pinned SHA-256: O&O publishes a single
    unversioned URL that changes content on every release, so a pinned hash
    would break the download the day they ship an update. The signature
    survives updates while still proving the bytes came from O&O.

    This script mutates nothing itself. It is a launcher, so it has no
    paired revert sibling; see $KnownUnpairable in
    tests/invariants/mutator-paired-restore.Tests.ps1.

.PARAMETER KeepDownload
    Leave the downloaded .exe in the staging directory instead of deleting
    it on exit. Useful for running it again offline.

.EXAMPLE
    PS> .\launch-shutup10.ps1
    Fetch, verify, run, then clean up the download.

.EXAMPLE
    PS> .\launch-shutup10.ps1 -WhatIf
    Show what would be downloaded and run without touching the network.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced (third-party tool; changes are user-driven)

    Anti-cheat impact: None. This script only downloads and starts a GUI.
                       Settings you then apply are Windows privacy toggles,
                       not game-visible driver or kernel changes.
    Reboot required:   No (some settings inside the tool ask for one)
    Disk impact:       ~80 MB transient in the staging directory, removed
                       on exit unless -KeepDownload is passed.

    Sources:  O&O ShutUp10++ — https://www.oo-software.com/en/shutup10

    Exit codes:
      0  Tool launched (or -WhatIf preview completed)
      1  Download failed
      2  Signature verification failed — file deleted, nothing executed
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [switch]$KeepDownload
)

. (Join-Path $PSScriptRoot '..' 'lib/download-helpers.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/ui-helpers.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/version-manifest.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/toolkit-state.ps1')

UI-Header -Title 'O&O ShutUp10++' -Subtitle 'Telemetry and privacy settings'
UI-RequireAdmin

# Downloading and executing a third-party binary belongs in the audit trail.
Write-ToolkitScriptStart

$manifest = Get-ToolManifest -Name 'shutup10'
$staging = Join-Path $script:GamingOptRoot 'external-tools'
$target = Join-Path $staging 'OOSU10.exe'

if (-not $PSCmdlet.ShouldProcess($manifest.url, 'Download and launch O&O ShutUp10++')) {
    Write-Host "  [WHATIF] Would download $($manifest.url)" -ForegroundColor Yellow
    Write-Host "  [WHATIF] Would verify Authenticode signer '$($manifest.signerCN)'" -ForegroundColor Yellow
    Write-Host "  [WHATIF] Would launch $target" -ForegroundColor Yellow
    exit 0
}

Ensure-Internet
Ensure-Directory -Path $staging

try {
    Get-FileFromWeb -Url $manifest.url -File $target
} catch {
    Write-Host "  [ERROR] Download failed: $_" -ForegroundColor Red
    exit 1
}

# Verify before executing, never after. A tool that edits privacy settings
# system-wide is exactly the kind of download worth refusing on a bad sig.
if (-not (Test-FileAuthenticode -Path $target -ExpectedSignerCN $manifest.signerCN)) {
    Remove-Item $target -Force -ErrorAction SilentlyContinue
    Write-Host "  [ERROR] Signature check failed for $($manifest.signerCN) — file deleted, nothing was run." -ForegroundColor Red
    exit 2
}

Write-Host "  [OK] Signature verified: $($manifest.signerCN)" -ForegroundColor Green
Write-Host '  Launching. Review each setting yourself before applying.' -ForegroundColor Cyan

Start-Process -FilePath $target -Wait

if (-not $KeepDownload) {
    Remove-Item $target -Force -ErrorAction SilentlyContinue
}

exit 0
