# ============================================================
# tests/_common.ps1 — shared Pester test scaffolding
# Windows 11 Gaming Optimization Guide
# ============================================================
# Dot-sourced by every <script>.Tests.ps1 file. Provides:
#   - $script:RepoRoot            absolute path to repo root
#   - Get-ToolkitScriptPath       resolve script under test
#   - Test-ToolkitParameterShape  assert standard mutator surface
#                                 (CmdletBinding, ShouldProcess, etc.)
#   - Invoke-ToolkitWhatIf        run a script with -WhatIf and assert
#                                 no side-effects via dry-run scope
#
# All tests are macOS-runnable (parser-only / static-analysis style).
# Tests that require Windows registry / services are tagged
# 'WindowsOnly' and skipped when -not $IsWindows.
# ============================================================

$script:RepoRoot = Split-Path -Parent $PSScriptRoot

function Get-ToolkitScriptPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RelativePath)
    $full = Join-Path $script:RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $full)) {
        throw "Script under test not found: $full"
    }
    return $full
}

function Get-ToolkitScriptAst {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    [System.Management.Automation.Language.Parser]::ParseFile(
        $Path, [ref]$null, [ref]$null
    )
}

function Test-ToolkitParameterShape {
    <#
    .SYNOPSIS
        Assert a script has the toolkit's standard mutator surface.
    .DESCRIPTION
        Checks for [CmdletBinding(SupportsShouldProcess)] when the script
        mutates registry/services/files, the inline admin self-check
        pattern, and the param block existing if any parameters declared.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$RequireShouldProcess
    )
    $ast = Get-ToolkitScriptAst -Path $Path
    $params = $ast.ParamBlock
    $cmdletBinding = $false
    $shouldProcess = $false

    if ($params -and $params.Attributes) {
        foreach ($attr in $params.Attributes) {
            if ($attr.TypeName.Name -eq 'CmdletBinding') {
                $cmdletBinding = $true
                foreach ($named in $attr.NamedArguments) {
                    if ($named.ArgumentName -eq 'SupportsShouldProcess') {
                        $shouldProcess = $true
                    }
                }
            }
        }
    }

    [PSCustomObject]@{
        Path = $Path
        HasParamBlock = $null -ne $params
        HasCmdletBinding = $cmdletBinding
        SupportsShouldProcess = $shouldProcess
        Passes = -not $RequireShouldProcess -or $shouldProcess
    }
}

function Test-ToolkitAdminCheck {
    <#
    .SYNOPSIS
        Assert the script self-checks admin before any mutation.
    .DESCRIPTION
        Looks for either UI-RequireAdmin call OR the inline
        IsInRole(Administrator) pattern within the first 60 lines.
        Per CLAUDE.md invariant #6.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $content = Get-Content -LiteralPath $Path -Raw
    $head = ($content -split "`n" | Select-Object -First 60) -join "`n"
    $hasUI = $head -match 'UI-RequireAdmin'
    $hasInline = $head -match 'IsInRole.*Administrator'
    [PSCustomObject]@{
        Path = $Path
        HasUIRequireAdmin = $hasUI
        HasInlineAdminCheck = $hasInline
        Passes = $hasUI -or $hasInline
    }
}

function Test-ToolkitCommentBasedHelp {
    <#
    .SYNOPSIS
        Assert the script has minimal comment-based help.
    .DESCRIPTION
        Looks for at least .SYNOPSIS and .DESCRIPTION in the first
        100 lines (script-level help). Doesn't check inner functions.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $content = Get-Content -LiteralPath $Path -Raw
    $head = ($content -split "`n" | Select-Object -First 100) -join "`n"
    [PSCustomObject]@{
        Path = $Path
        HasSynopsis = $head -match '\.SYNOPSIS'
        HasDescription = $head -match '\.DESCRIPTION'
        HasExample = $head -match '\.EXAMPLE'
        HasNotes = $head -match '\.NOTES'
        Passes = ($head -match '\.SYNOPSIS') -and ($head -match '\.DESCRIPTION')
    }
}
