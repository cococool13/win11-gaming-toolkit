#Requires -Version 5.1
<#
.SYNOPSIS
    Run the Win11 Gaming Toolkit quality gate: PSScriptAnalyzer + Pester.

.DESCRIPTION
    Single entrypoint for the CI/CD quality gate. Equivalent to what
    .github/workflows/ci.yml runs. Exits non-zero on any analyzer
    Error severity, or any Pester failure.

    Use locally:
        pwsh -File tools/Invoke-ToolkitGate.ps1
        pwsh -File tools/Invoke-ToolkitGate.ps1 -Path 'launcher.ps1'
        pwsh -File tools/Invoke-ToolkitGate.ps1 -Strict       # warnings fail too
        pwsh -File tools/Invoke-ToolkitGate.ps1 -SkipTests    # analyzer only

.PARAMETER Path
    Optional file or directory to scope the gate. Defaults to repo root.

.PARAMETER Strict
    Treat Warning severity as failure (Error severity always fails).
    Use after Phase A migration is complete.

.PARAMETER SkipTests
    Skip the Pester run. Useful for quick analyzer-only loops during fixes.

.PARAMETER SkipAnalyzer
    Skip PSScriptAnalyzer. Useful for Pester-only runs.

.PARAMETER Coverage
    Emit a non-gating CodeCoverage report alongside the Pester run.
    Measures coverage on lib/*.ps1 only (the helpers are the long-lived
    surface area worth tracking; individual tweak scripts are
    short and runtime-untestable from dev macOS). Coverage NEVER fails
    the gate — it's an informational report so trend lines are visible
    per-commit without blocking work that genuinely doesn't increase
    coverage (e.g. a doc-only PR).

.EXAMPLE
    PS> pwsh -File tools/Invoke-ToolkitGate.ps1
    Runs full gate on repo. Exit 0 on success.

.EXAMPLE
    PS> pwsh -File tools/Invoke-ToolkitGate.ps1 -Path 'launcher.ps1' -SkipTests
    Quick analyzer-only check on a single file during a fix loop.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    See:      .psscriptanalyzer.psd1 for rule configuration
              tests/ for Pester suite
#>
[CmdletBinding()]
param(
    [string]$Path = (Split-Path -Parent $PSScriptRoot),
    [switch]$Strict,
    [switch]$SkipTests,
    [switch]$SkipAnalyzer,
    [switch]$Coverage
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$settingsPath = Join-Path $repoRoot '.psscriptanalyzer.psd1'

$exitCode = 0
$summary = [ordered]@{
    AnalyzerErrors = 0
    AnalyzerWarnings = 0
    AnalyzerInfo = 0
    PesterFailed = 0
    PesterPassed = 0
    PesterSkipped = 0
    CoveragePct = $null  # populated only when -Coverage is passed
}

if (-not $SkipAnalyzer) {
    Write-Output ''
    Write-Output '== PSScriptAnalyzer =='
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Write-Error 'PSScriptAnalyzer not installed. Install-Module PSScriptAnalyzer -Scope CurrentUser'
        exit 10
    }
    Import-Module PSScriptAnalyzer -ErrorAction Stop

    $analyzerArgs = @{
        Path = $Path
        Recurse = $true
        Settings = $settingsPath
        ErrorAction = 'SilentlyContinue'
    }
    $results = Invoke-ScriptAnalyzer @analyzerArgs

    $summary.AnalyzerErrors = @($results | Where-Object Severity -EQ 'Error').Count
    $summary.AnalyzerWarnings = @($results | Where-Object Severity -EQ 'Warning').Count
    $summary.AnalyzerInfo = @($results | Where-Object Severity -EQ 'Information').Count

    if ($results) {
        $results | Group-Object Severity |
            ForEach-Object { Write-Output "  $($_.Name): $($_.Count)" }
        if ($summary.AnalyzerErrors -gt 0) {
            Write-Output ''
            Write-Output '-- Errors detail --'
            $results | Where-Object Severity -EQ 'Error' |
                Select-Object RuleName, ScriptName, Line, Message |
                Format-Table -AutoSize | Out-String | Write-Output
        }
    } else {
        Write-Output '  (clean)'
    }

    if ($summary.AnalyzerErrors -gt 0) { $exitCode = 1 }
    if ($Strict -and $summary.AnalyzerWarnings -gt 0) { $exitCode = 1 }
}

if (-not $SkipTests) {
    Write-Output ''
    Write-Output '== Pester =='
    $testsDir = Join-Path $repoRoot 'tests'
    if (-not (Test-Path -LiteralPath $testsDir)) {
        Write-Output '  (no tests/ directory — skipping)'
    } else {
        Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
        $config = New-PesterConfiguration
        $config.Run.Path = $testsDir
        $config.Run.PassThru = $true
        $config.Output.Verbosity = 'Normal'
        # Skip Windows-specific tests on macOS / Linux CI runners
        if (-not $IsWindows) {
            $config.Filter.ExcludeTag = @('WindowsOnly')
        }
        if ($Coverage) {
            # Cover lib/*.ps1 only — those are the long-lived helpers
            # the per-script suites and invariants both exercise. Per-
            # script tweak files are short and runtime-untestable from
            # dev macOS (registry hives don't exist), so including them
            # would dilute the coverage signal toward "% of static
            # parse-friendly files we touched" rather than "% of helper
            # surface our tests exercise."
            $libDir = Join-Path $repoRoot 'lib'
            $config.CodeCoverage.Enabled = $true
            $config.CodeCoverage.Path = (Join-Path $libDir '*.ps1')
            $config.CodeCoverage.OutputFormat = 'JaCoCo'
            $config.CodeCoverage.OutputPath = (Join-Path $repoRoot 'coverage.xml')
        }
        $pesterResult = Invoke-Pester -Configuration $config
        $summary.PesterFailed = $pesterResult.FailedCount
        $summary.PesterPassed = $pesterResult.PassedCount
        $summary.PesterSkipped = $pesterResult.SkippedCount
        if ($Coverage -and $pesterResult.CodeCoverage) {
            $cc = $pesterResult.CodeCoverage
            $total = $cc.CommandsAnalyzedCount
            $hit = $cc.CommandsExecutedCount
            if ($total -gt 0) {
                $summary.CoveragePct = [math]::Round(($hit / $total) * 100, 1)
            } else {
                $summary.CoveragePct = 0.0
            }
        }
        if ($pesterResult.FailedCount -gt 0) { $exitCode = 1 }
        # Coverage NEVER touches $exitCode — it's a report, not a gate.
    }
}

Write-Output ''
Write-Output '== Summary =='
foreach ($k in $summary.Keys) {
    $v = $summary[$k]
    # Suppress the coverage row entirely when -Coverage wasn't passed
    # so the default summary stays terse for the common-case run.
    if ($k -eq 'CoveragePct' -and $null -eq $v) { continue }
    Write-Output ("  {0,-18} {1}" -f $k, $v)
}
Write-Output ''
if ($exitCode -eq 0) {
    Write-Output 'GATE: PASS'
} else {
    Write-Output 'GATE: FAIL'
}
exit $exitCode
