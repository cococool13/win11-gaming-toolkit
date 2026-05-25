#Requires -Version 5.1
<#
.SYNOPSIS
    Win11 Gaming Toolkit dev profile (CurrentUserAllHosts).

.DESCRIPTION
    Modular PowerShell profile that loads toolkit-aware helpers + sane
    interactive defaults. Designed for the developer working on this
    toolkit, NOT for end-users running it.

    Install: see profile/Install-Profile.ps1. Manually:
        Copy this file to $PROFILE.CurrentUserAllHosts, OR symlink it.

    The profile dot-sources every .ps1 under profile/parts/ alphabetically.
    Add new modules there; the profile picks them up automatically on
    the next session.

    Phase B per the continuous-improvement loop. See profile/README.md.
#>

# Resolve where this profile actually lives (handles symlinks gracefully).
$profileRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Toolkit-aware helpers (Get-ToolkitLog, Show-ToolkitMenu, etc.) plus
# any future parts files dropped into profile/parts/.
$partsDir = Join-Path $profileRoot 'parts'
if (Test-Path -LiteralPath $partsDir) {
    Get-ChildItem -LiteralPath $partsDir -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object { . $_.FullName }
}

# PSReadLine: ListView prediction + history search on arrow keys.
# Available on Windows PowerShell 5.1 if the user has PSReadLine 2.2+,
# always on PowerShell 7+.
if (Get-Module -ListAvailable PSReadLine | Where-Object { $_.Version -ge '2.2.0' }) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# Welcome banner — concise so it doesn't dominate the new-session view.
Write-Host ''
Write-Host '  Win11 Gaming Toolkit dev profile loaded.' -ForegroundColor Cyan
Write-Host "  Show-ToolkitMenu  for the dev cheat-sheet." -ForegroundColor DarkGray
Write-Host ''
