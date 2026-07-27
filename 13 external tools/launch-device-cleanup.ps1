#Requires -Version 5.1
<#
.SYNOPSIS
    Download and launch DeviceCleanup (remove stale non-present devices).

.DESCRIPTION
    Windows keeps a registry entry for every device ever attached, including
    ones long gone. DeviceCleanup lists those non-present devices and lets
    you remove them. Useful after swapping a GPU, a headset, or a pile of USB
    peripherals, where the leftovers can keep stale driver settings alive.

    Nothing is installed. The archive is fetched to the toolkit staging
    directory, the executable is extracted, its Authenticode signature is
    verified against the author, and only then is it run.

    Trust: the zip carries no Authenticode signature, so verification happens
    on the extracted .exe before execution. A failed signature deletes the
    staging folder and aborts.

    Why Authenticode and not a pinned SHA-256: the author publishes a rolling
    archive at a fixed URL, so a pinned hash would break on the next release.

    This script mutates nothing itself, but the tool it launches does — and
    device removal is not tracked in the toolkit manifest, so it is not
    covered by REVERT-EVERYTHING. Removed non-present devices come back on
    their own when you physically reattach the hardware. Take a restore point
    first if you are unsure. It is a launcher, so it has no paired revert
    sibling; see $KnownUnpairable in
    tests/invariants/mutator-paired-restore.Tests.ps1.

.PARAMETER KeepDownload
    Leave the extracted tool in the staging directory instead of deleting it
    on exit.

.EXAMPLE
    PS> .\launch-device-cleanup.ps1
    Fetch, verify, run, then clean up.

.EXAMPLE
    PS> .\launch-device-cleanup.ps1 -WhatIf
    Show what would be downloaded and run without touching the network.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced (third-party tool; changes are user-driven)

    Anti-cheat impact: None from this script. Removing non-present devices
                       does not touch a running anti-cheat.
    Reboot required:   No.
    Disk impact:       ~50 KB transient in the staging directory, removed on
                       exit unless -KeepDownload is passed. Removing stale
                       device entries frees a negligible amount of registry
                       space; the benefit is cleanliness, not capacity.

    Sources:  Uwe Sieber — DeviceCleanup
              https://www.uwe-sieber.de/misc_tools_e.html

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

UI-Header -Title 'DeviceCleanup' -Subtitle 'Remove stale non-present devices'
UI-RequireAdmin

# Downloading and executing a third-party binary belongs in the audit trail.
Write-ToolkitScriptStart

$manifest = Get-ToolManifest -Name 'deviceCleanup'
$staging = Join-Path $script:GamingOptRoot 'external-tools/device-cleanup'
$archive = Join-Path $script:GamingOptRoot 'external-tools/DeviceCleanup.zip'
$target = Join-Path $staging $manifest.archiveEntry

if (-not $PSCmdlet.ShouldProcess($manifest.url, 'Download and launch DeviceCleanup')) {
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

# The zip is unsigned, so the extracted binary is what gets verified.
if (-not (Test-FileAuthenticode -Path $target -ExpectedSignerCN $manifest.signerCN)) {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [ERROR] Signature check failed for $($manifest.signerCN) — staging removed, nothing was run." -ForegroundColor Red
    exit 2
}

Write-Host "  [OK] Signature verified: $($manifest.signerCN)" -ForegroundColor Green
Write-Host '  Removals here are not manifest-tracked; reattach hardware to restore.' -ForegroundColor Cyan

Start-Process -FilePath $target -Wait

if (-not $KeepDownload) {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0
