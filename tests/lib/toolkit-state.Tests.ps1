#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for lib/toolkit-state.ps1.

.DESCRIPTION
    AST-driven tests that run on any platform. Validate:
      - Public helper functions are present and exported (or accessible
        via dot-source).
      - Mutating helpers (Set-Toolkit*) carry SupportsShouldProcess.
      - In-memory helpers (Set-ToolkitMapValue) have explicit
        suppression so future analyzer runs don't re-flag them.

    Runtime tests (actual registry / service writes) are tagged
    'WindowsOnly' and live in tests/integration/. This file is
    static-only and safe on macOS / Linux CI runners.

.NOTES
    Test rig: tests/_common.ps1 provides shared helpers.
#>

BeforeDiscovery {
    # Pester v5 quirk: -ForEach iterations must be expanded at DISCOVERY
    # time, not run time. Loop variables defined inside Describe/Context
    # don't survive into It blocks.
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Mutators = @(
        @{ Name = 'Set-ToolkitRegistryValue' }
        @{ Name = 'Set-ToolkitServiceStartMode' }
        @{ Name = 'Set-ToolkitDnsServers' }
    )
    $script:ExpectedPublic = @(
        @{ Name = 'Get-ToolkitManifestPath' }
        @{ Name = 'Get-ToolkitLogRoot' }
        @{ Name = 'Get-ToolkitLogFile' }
        @{ Name = 'Write-ToolkitLog' }
        @{ Name = 'Write-ToolkitScriptStart' }
        @{ Name = 'Write-ToolkitScriptComplete' }
        @{ Name = 'Initialize-ToolkitState' }
        @{ Name = 'Get-ToolkitState' }
        @{ Name = 'Save-ToolkitState' }
        @{ Name = 'Set-ToolkitRegistryValue' }
        @{ Name = 'Restore-ToolkitRegistryValue' }
        @{ Name = 'Set-ToolkitServiceStartMode' }
        @{ Name = 'Restore-ToolkitServiceStartMode' }
        @{ Name = 'Set-ToolkitDnsServers' }
        @{ Name = 'Add-ToolkitStepResult' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Target = Get-ToolkitScriptPath 'lib/toolkit-state.ps1'
    $script:Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:Target, [ref]$null, [ref]$null
    )
    $script:Functions = $script:Ast.FindAll({
            param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
    $script:FunctionNames = @($script:Functions | ForEach-Object Name)
}

Describe 'lib/toolkit-state.ps1 — surface contract' {

    Context 'File health' {
        It 'parses without errors' {
            $tokens = $null
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:Target, [ref]$tokens, [ref]$errors
            )
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Mutating helpers declare SupportsShouldProcess (PSSA #15)' {
        It '<Name> carries [CmdletBinding(SupportsShouldProcess)]' -ForEach $script:Mutators {
            $fn = $script:Functions | Where-Object Name -EQ $Name
            $fn | Should -Not -BeNullOrEmpty -Because 'the function must exist for this test to be meaningful'

            $hasShouldProcess = $false
            $cmdletBinding = $fn.Body.ParamBlock.Attributes |
                Where-Object { $_.TypeName.Name -eq 'CmdletBinding' } |
                Select-Object -First 1
            if ($cmdletBinding) {
                foreach ($named in $cmdletBinding.NamedArguments) {
                    if ($named.ArgumentName -eq 'SupportsShouldProcess') {
                        $hasShouldProcess = $true
                    }
                }
            }
            $hasShouldProcess | Should -BeTrue -Because 'every mutator must support -WhatIf / -Confirm per CLAUDE.md quality bar'
        }

        It 'Set-ToolkitMapValue has analyzer suppression (in-memory only)' {
            $fn = $script:Functions | Where-Object Name -EQ 'Set-ToolkitMapValue'
            $fn | Should -Not -BeNullOrEmpty
            $hasSuppression = $false
            foreach ($attr in $fn.Body.ParamBlock.Attributes) {
                if ($attr.TypeName.Name -match 'SuppressMessage') {
                    foreach ($arg in $attr.PositionalArguments) {
                        if ($arg.Extent.Text -match 'PSUseShouldProcessForStateChangingFunctions') {
                            $hasSuppression = $true
                        }
                    }
                }
            }
            $hasSuppression | Should -BeTrue
        }
    }

    Context 'Public surface' {
        It 'exports <Name>' -ForEach $script:ExpectedPublic {
            $script:FunctionNames | Should -Contain $Name
        }
    }

    Context 'Write-ToolkitLog produces JSONL with required fields' {
        BeforeAll {
            . $script:Target
            # Force a fresh per-test log path via reflection of script-scope var.
            $tempLog = Join-Path ([System.IO.Path]::GetTempPath()) ("toolkit-test-{0}.log" -f [Guid]::NewGuid())
            Set-Variable -Scope script -Name 'ToolkitLogFile' -Value $tempLog
            $script:TempLog = $tempLog
        }

        AfterAll {
            if (Test-Path -LiteralPath $script:TempLog) {
                Remove-Item -LiteralPath $script:TempLog -Force -ErrorAction SilentlyContinue
            }
        }

        It 'appends a JSON line with ts/level/msg' {
            Write-ToolkitLog 'pester-test-1'
            Test-Path -LiteralPath $script:TempLog | Should -BeTrue
            $lines = @(Get-Content -LiteralPath $script:TempLog | Where-Object { $_.Trim() })
            $lines.Count | Should -BeGreaterOrEqual 1
            $obj = $lines[-1] | ConvertFrom-Json
            $obj.ts | Should -Not -BeNullOrEmpty
            $obj.level | Should -Be 'info'
            $obj.msg | Should -Be 'pester-test-1'
        }

        It 'includes optional Data as a nested object' {
            Write-ToolkitLog 'pester-test-2' -Data @{ key = 'value'; n = 42 }
            $lines = @(Get-Content -LiteralPath $script:TempLog | Where-Object { $_.Trim() })
            $obj = $lines[-1] | ConvertFrom-Json
            $obj.data.key | Should -Be 'value'
            $obj.data.n | Should -Be 42
        }

        It "honors -Level 'warn' / 'error'" {
            Write-ToolkitLog 'warn-line' -Level 'warn'
            Write-ToolkitLog 'error-line' -Level 'error'
            $lines = @(Get-Content -LiteralPath $script:TempLog | Where-Object { $_.Trim() })
            ($lines[-2] | ConvertFrom-Json).level | Should -Be 'warn'
            ($lines[-1] | ConvertFrom-Json).level | Should -Be 'error'
        }

        It 'rejects invalid -Level values at param-bind time' {
            { Write-ToolkitLog 'x' -Level 'fatal' } | Should -Throw
        }
    }
}

