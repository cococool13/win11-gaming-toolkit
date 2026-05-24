#Requires -Version 5.1
<#
.SYNOPSIS
    Audit installed UWP / Microsoft Store packages — report only.

.DESCRIPTION
    Read-only inventory of every Appx package currently installed for
    the running user. Companion to 9 cleanup/debloat.ps1's "report
    then decide" UX (the audit/check pattern from FR33THY/Ultimate
    that the prior session ported as a category seed).

    Output columns:
      Name           - PackageFamilyName (the stable id)
      DisplayName    - human-readable label (best-effort; some pkgs
                       only expose Name)
      Publisher      - signing identity
      InstallLocation- where files live (useful for size estimation)
      Status         - OK / Modified / Tampered
      OnDebloatList  - flagged ✓ if 9 cleanup/debloat.ps1 would
                       remove this package
      OnSafetyList   - flagged ✓ if it's in debloat.ps1's $neverRemove

    Sort: -Sort Name|Publisher|Status. Default: Name.
    Filter: -OnlyDebloatCandidates limits to apps debloat.ps1 would
    touch (use this to preview what running debloat would do).

    Sources cited:
      Microsoft Learn — Get-AppxPackage
        https://learn.microsoft.com/en-us/powershell/module/appx/get-appxpackage
      Microsoft Learn — UWP app lifecycle
        https://learn.microsoft.com/en-us/windows/uwp/launch-resume/app-lifecycle

.PARAMETER Sort
    Column to sort by. Default: Name.

.PARAMETER OnlyDebloatCandidates
    Limit output to apps in debloat.ps1's $appsToRemove list — preview
    what running debloat.ps1 with no edits would target.

.PARAMETER AsObject
    Emit raw PSCustomObject rows on the pipeline instead of formatted
    text. Use for piping into Export-Csv / Out-GridView.

.EXAMPLE
    PS> .\check-uwp-apps.ps1

.EXAMPLE
    PS> .\check-uwp-apps.ps1 -OnlyDebloatCandidates -Sort Publisher

.EXAMPLE
    PS> .\check-uwp-apps.ps1 -AsObject | Export-Csv -NoTypeInformation uwp.csv

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Safe (read-only)

    # CROSS-PLATFORM-NOTE
    # Get-AppxPackage is Windows-only. On macOS the script exits with
    # code 2 after the cmdlet check, no output.

    Anti-cheat impact: NONE. Pure read.

    Exit codes:
      0  Report rendered successfully
      2  Get-AppxPackage unavailable (Server Core / Linux)
#>
[CmdletBinding()]
param(
    [ValidateSet('Name', 'Publisher', 'Status')]
    [string]$Sort = 'Name',
    [switch]$OnlyDebloatCandidates,
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Get-AppxPackage not available.' -ForegroundColor Yellow
    Write-Host '         Requires Windows; Server Core may strip Appx module.' -ForegroundColor Yellow
    exit 2
}

# Parse the debloat lists straight from debloat.ps1 so this stays in
# sync without manual duplication. AST walk is safer than regex over
# the array literals.
$debloatScript = Join-Path $PSScriptRoot '..' '9 cleanup/debloat.ps1'
$debloatList = @()
$neverRemoveList = @()
if (Test-Path -LiteralPath $debloatScript) {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $debloatScript, [ref]$null, [ref]$null
    )
    foreach ($assign in $ast.FindAll({
                param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst]
            }, $true)) {
        $varName = $assign.Left.Extent.Text
        if ($varName -eq '$appsToRemove' -or $varName -eq '$neverRemove') {
            # Walk the array literal for either string elements or
            # hashtable `Name = '...'` entries.
            $strings = $assign.Right.FindAll({
                    param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst]
                }, $true) | ForEach-Object Value
            # For $appsToRemove the array holds hashtables; pick out
            # only the 'Name' values (every other index).
            if ($varName -eq '$appsToRemove') {
                $debloatList = @($strings | Where-Object { $_ -match '^[A-Za-z]' -and $_ -notin 'Safe', 'Advanced' -and $_ -notmatch '\s' })
            } else {
                $neverRemoveList = @($strings | Where-Object { $_ -match '^Microsoft' })
            }
        }
    }
}

UI-Header -Title 'UWP / Appx package audit' -Subtitle 'Read-only inventory'

$packages = @(Get-AppxPackage)
$rows = foreach ($p in $packages) {
    [PSCustomObject]@{
        Name = $p.Name
        DisplayName = if ($p.Name) { $p.Name } else { '(none)' }
        Publisher = ($p.Publisher -replace 'CN=', '' -replace ',.*', '')
        InstallLocation = $p.InstallLocation
        Status = $p.Status
        OnDebloatList = if ($debloatList -contains $p.Name) { '✓' } else { '' }
        OnSafetyList = if ($neverRemoveList -contains $p.Name) { '✓' } else { '' }
    }
}

if ($OnlyDebloatCandidates) {
    $rows = @($rows | Where-Object { $_.OnDebloatList -eq '✓' })
}

$rows = @($rows | Sort-Object $Sort)

if ($AsObject) {
    $rows
} else {
    $rows | Format-Table -AutoSize Name, Publisher, OnDebloatList, OnSafetyList, Status |
        Out-String -Width 200 | Write-Host
    Write-Host ('  Total: {0} packages.  Debloat candidates: {1}.  Protected (never removed): {2}.' -f `
            $packages.Count,
        ($rows | Where-Object OnDebloatList -EQ '✓').Count,
        ($rows | Where-Object OnSafetyList -EQ '✓').Count) -ForegroundColor Gray
}
exit 0
