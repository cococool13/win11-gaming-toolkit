#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for lib/ui-helpers.ps1.

.DESCRIPTION
    Validates the UI-* helper surface that ~75 scripts dot-source.
    AST-only — runtime tests (actual Write-Host capture, color codes)
    live in tests/integration/ tagged 'WindowsOnly'.

.NOTES
    Test rig: tests/_common.ps1 provides shared helpers.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:ExpectedPublic = @(
        @{ Name = 'UI-ResetCounters' }
        @{ Name = 'UI-RequireAdmin' }
        @{ Name = 'UI-RequireInternet' }
        @{ Name = 'UI-Header' }
        @{ Name = 'UI-Section' }
        @{ Name = 'UI-Note' }
        @{ Name = 'UI-KeyValue' }
        @{ Name = 'UI-ShowProfile' }
        @{ Name = 'UI-Step' }
        @{ Name = 'UI-Skip' }
        @{ Name = 'UI-Summary' }
        @{ Name = 'UI-Confirm' }
        @{ Name = 'UI-AskYesNo' }
        @{ Name = 'UI-Exit' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Target = Get-ToolkitScriptPath 'lib/ui-helpers.ps1'
    $script:Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:Target, [ref]$null, [ref]$null
    )
    $script:Functions = $script:Ast.FindAll({
            param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
    $script:FunctionNames = @($script:Functions | ForEach-Object Name)
}

Describe 'lib/ui-helpers.ps1 — surface contract' {

    Context 'File health' {
        It 'parses without errors' {
            $tokens = $null
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:Target, [ref]$tokens, [ref]$errors
            )
            $errors | Should -BeNullOrEmpty
        }

        It 'declares the script-scoped color constants' {
            # The UI palette must exist so every dot-sourcing script can
            # reference $script:UI_Success / UI_Error / UI_Warning / etc.
            $content = Get-Content -Raw -LiteralPath $script:Target
            foreach ($name in @('UI_Header', 'UI_Error', 'UI_Warning', 'UI_Success', 'UI_Info')) {
                $content | Should -Match "\`$script:$name\s*=" -Because 'every UI palette name in use across the tree must be declared here'
            }
        }
    }

    Context 'Public surface (the UI-* namespace)' {
        It 'exports <Name>' -ForEach $script:ExpectedPublic {
            $script:FunctionNames | Should -Contain $Name
        }
    }

    Context 'UI-ShowProfile no longer shadows automatic $Profile' {
        It 'uses parameter name $MachineProfile (not $Profile)' {
            # Regression test for the PSAvoidAssignmentToAutomaticVariable
            # fix at commit 596e701. The parameter was renamed; the
            # original name remains as an Alias so callers passing
            # -Profile continue to work.
            $fn = $script:Functions | Where-Object Name -EQ 'UI-ShowProfile'
            $fn | Should -Not -BeNullOrEmpty
            $paramNames = $fn.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
            $paramNames | Should -Contain 'MachineProfile'
            $paramNames | Should -Not -Contain 'Profile'
        }

        It 'declares Profile as a parameter Alias for back-compat' {
            $fn = $script:Functions | Where-Object Name -EQ 'UI-ShowProfile'
            $hasAlias = $false
            foreach ($p in $fn.Body.ParamBlock.Parameters) {
                foreach ($attr in $p.Attributes) {
                    if ($attr.TypeName.Name -eq 'Alias') {
                        foreach ($arg in $attr.PositionalArguments) {
                            if ($arg.Extent.Text -match "'Profile'") {
                                $hasAlias = $true
                            }
                        }
                    }
                }
            }
            $hasAlias | Should -BeTrue -Because 'callers passed -Profile $machineProfile before the rename; Alias preserves that surface'
        }
    }

    Context 'Internet check uses .NET Ping (no Test-Connection -ComputerName)' {
        It 'UI-RequireInternet does not use Test-Connection -ComputerName' {
            # Regression test for the PSAvoidUsingComputerNameHardcoded
            # Error-fix at commit 4e993a9.
            $fn = $script:Functions | Where-Object Name -EQ 'UI-RequireInternet'
            $body = $fn.Body.Extent.Text
            $body | Should -Not -Match 'Test-Connection.*-ComputerName'
            $body | Should -Match '\[System\.Net\.NetworkInformation\.Ping\]'
        }
    }
}
