#Requires -Version 5.1
<#
.SYNOPSIS
    Shared machinery for "forced-conscious-decision" header invariants
    (anti-cheat impact, reboot-required, disk-impact, etc).

.DESCRIPTION
    The pattern: each invariant asserts that every mutating script
    declares a specific decision in its header (within the first N
    lines), via a regex like `(?im)anti-cheat\s+impact:`. With three
    invariants sharing this shape (session 6 introduces reboot-required
    and disk-impact alongside the existing anti-cheat-header), the
    discovery + skip + match machinery moves here so each per-invariant
    file is just data (excluded list, gap list, regex).

    Two functions:
      - New-ToolkitHeaderInvariantCases
          Discover mutator-cases for a Pester -ForEach iteration.
          Returns one hashtable per case with Path + FullPath +
          HeaderGap fields ready for the It block.
      - Test-ToolkitHeaderLine
          Read the first N lines of a script and match a regex.
          Returns $true if the regex hits, $false otherwise.

.NOTES
    Cross-platform — pure file IO + text scan. Runs anywhere.

    Architecture-over-wiring promotion (session 6, cluster C):
    replaces 3 copies of the discover/filter/skip pattern with one
    lib helper. Each new "forced-conscious-decision" invariant
    becomes a 30-line file rather than a 90-line file.
#>

function New-ToolkitHeaderInvariantCases {
    <#
    .SYNOPSIS
        Build the -ForEach case array for a header-invariant Pester
        test. Filters out KnownExcluded entries; flags KnownGaps
        with HeaderGap=$true so the It block can Set-ItResult -Skipped.
    .PARAMETER RepoRoot
        Repo root for path resolution. Caller usually computes this
        as Split-Path -Parent (Split-Path -Parent $PSScriptRoot).
    .PARAMETER KnownExcluded
        Relative paths to exclude entirely (e.g. DduManual.ps1). These
        scripts are not in the iteration at all — distinct from gaps,
        which DO iterate but skip with a documented reason.
    .PARAMETER KnownGaps
        Relative paths tracked as pre-existing gaps. Each case gets
        HeaderGap=$true so the It block can skip without failing.
        SHRINK per-commit as scripts get backfilled. NEVER expand to
        absorb regressions — fix the script.
    .OUTPUTS
        Array of hashtables: @{ Path; FullPath; HeaderGap }.
    #>
    # Pure-data discovery — no system state mutated. PSSA flags `New-`
    # functions heuristically; the suppression makes the gate clean
    # without falsely requiring SupportsShouldProcess on an output-only
    # helper (same pattern as Set-ToolkitMapValue in toolkit-state.ps1).
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Output-only — discovers cases for Pester -ForEach; no system side effect.'
    )]
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string[]]$KnownExcluded = @(),
        [string[]]$KnownGaps = @()
    )

    # Dot-source Test-ToolkitInvariants if not already in scope.
    # This is the canonical mutator-classifier the toolkit ships.
    if (-not (Get-Command Test-ToolkitInvariants -ErrorAction SilentlyContinue)) {
        $awarePath = Join-Path $RepoRoot 'profile/parts/toolkit-aware.ps1'
        if (Test-Path -LiteralPath $awarePath) {
            . $awarePath
        }
    }

    $cases = @()
    $all = Test-ToolkitInvariants -RepoRoot $RepoRoot
    foreach ($row in $all) {
        if (-not $row.IsMutator) { continue }
        if ($KnownExcluded -contains $row.Path) { continue }
        $cases += @{
            Path = $row.Path
            FullPath = (Join-Path $RepoRoot $row.Path)
            HeaderGap = ($KnownGaps -contains $row.Path)
        }
    }
    return $cases
}

function Test-ToolkitHeaderLine {
    <#
    .SYNOPSIS
        Return $true if the script's first N lines match the given regex.
    .DESCRIPTION
        Pure file IO + Select-Object -First N + -join + -match. The
        N=120 default matches Test-ToolkitInvariants' head-window so
        callers fit the standard help-block / banner-header convention.
        If you raise N here, raise it there too.
    .PARAMETER Path
        Absolute path to the script.
    .PARAMETER Pattern
        Regex to match. Caller chooses case-insensitivity etc via
        inline flags like `(?im)^...`.
    .PARAMETER HeadLineCount
        How many lines from the top to scan. Default 120.
    .OUTPUTS
        Boolean.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Pattern,
        [int]$HeadLineCount = 120
    )

    $head = (Get-Content -LiteralPath $Path -TotalCount $HeadLineCount) -join "`n"
    return [bool]($head -match $Pattern)
}
