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
    [switch]$SkipAnalyzer
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
        $pesterResult = Invoke-Pester -Configuration $config
        $summary.PesterFailed = $pesterResult.FailedCount
        $summary.PesterPassed = $pesterResult.PassedCount
        $summary.PesterSkipped = $pesterResult.SkippedCount
        if ($pesterResult.FailedCount -gt 0) { $exitCode = 1 }
    }
}

Write-Output ''
Write-Output '== Summary =='
foreach ($k in $summary.Keys) {
    Write-Output ("  {0,-18} {1}" -f $k, $summary[$k])
}
Write-Output ''
if ($exitCode -eq 0) {
    Write-Output 'GATE: PASS'
} else {
    Write-Output 'GATE: FAIL'
}
exit $exitCode
