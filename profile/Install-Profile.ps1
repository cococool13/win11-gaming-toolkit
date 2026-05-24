#Requires -Version 5.1
<#
.SYNOPSIS
    Install the Win11 Gaming Toolkit dev profile into $PROFILE.

.DESCRIPTION
    Backs up any existing $PROFILE.CurrentUserAllHosts (one-time backup
    with timestamp suffix), then dot-sources this repo's profile from
    $PROFILE so the dev gets the toolkit-aware helpers on every session.

    Idempotent: re-running confirms the dot-source line is present and
    exits cleanly if already installed. Pass -Force to overwrite a
    user-customized $PROFILE.

    Uninstall: edit $PROFILE.CurrentUserAllHosts and remove the dot-source
    line; or restore the backup at the path the script prints on install.

.PARAMETER Force
    Overwrite the existing $PROFILE.CurrentUserAllHosts. Default false
    (the script appends an idempotent dot-source instead).

.EXAMPLE
    PS> .\profile\Install-Profile.ps1
    Adds the toolkit profile dot-source to your CurrentUserAllHosts profile.

.EXAMPLE
    PS> .\profile\Install-Profile.ps1 -WhatIf
    Show what would change without modifying anything.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Scope:    CurrentUser only — does not touch AllUsersAllHosts.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve the toolkit profile we want to dot-source.
$toolkitProfile = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
if (-not (Test-Path -LiteralPath $toolkitProfile)) {
    Write-Error "Cannot find toolkit profile at $toolkitProfile"
    exit 2
}

# CurrentUserAllHosts so both pwsh and Windows PowerShell pick it up.
$target = $PROFILE.CurrentUserAllHosts
$targetDir = Split-Path -Parent $target
if (-not (Test-Path -LiteralPath $targetDir)) {
    if ($PSCmdlet.ShouldProcess($targetDir, 'New-Item (profile directory)')) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
}

$marker = "# === Win11 Gaming Toolkit dev profile ==="
$dotSourceLine = ". '$toolkitProfile'"
$snippet = @"
$marker
if (Test-Path -LiteralPath '$toolkitProfile') {
    $dotSourceLine
}
# === end Win11 Gaming Toolkit dev profile ==="
"@

$existing = if (Test-Path -LiteralPath $target) { Get-Content -Raw -LiteralPath $target } else { '' }

if ($existing -match [regex]::Escape($marker)) {
    Write-Output "Toolkit profile already installed at $target"
    Write-Output 'Re-run with -Force to reinstall, or edit the file manually to update.'
    exit 0
}

# Backup any existing content before appending.
if ($existing -and -not $Force) {
    $backupPath = "$target.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    if ($PSCmdlet.ShouldProcess($backupPath, 'Copy-Item (backup existing profile)')) {
        Copy-Item -LiteralPath $target -Destination $backupPath -Force
    }
    Write-Output "Backed up existing profile: $backupPath"
}

$newContent = if ($existing) { "$existing`n$snippet`n" } else { "$snippet`n" }

if ($PSCmdlet.ShouldProcess($target, 'Append toolkit dot-source')) {
    Set-Content -LiteralPath $target -Value $newContent -Encoding utf8
    Write-Output "Installed toolkit dot-source into: $target"
    Write-Output 'Open a new PowerShell session for it to take effect, or:'
    Write-Output "  . '$toolkitProfile'"
} else {
    Write-Output 'Skipped (per -WhatIf).'
}
