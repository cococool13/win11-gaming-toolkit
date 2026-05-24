#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for lib/gpu-detection.ps1.

.DESCRIPTION
    Validates the vendor-detection + adapter-resolution surface that
    every 6 gpu/* script depends on. Static-only — actual PnP probing
    is Windows-only and lives in tests/integration/.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:ExpectedPublic = @(
        @{ Name = 'Get-GpuVendor' }
        @{ Name = 'Get-GpuAdapterRegistryPath' }
        @{ Name = 'Test-IntelArcDevice' }
        @{ Name = 'Get-PrimaryGpu' }
        @{ Name = 'Test-ReBarEnabled' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Target = Get-ToolkitScriptPath 'lib/gpu-detection.ps1'
    $script:Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:Target, [ref]$null, [ref]$null
    )
    $script:Functions = $script:Ast.FindAll({
            param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
    $script:FunctionNames = @($script:Functions | ForEach-Object Name)
    $script:Content = Get-Content -Raw -LiteralPath $script:Target
}

Describe 'lib/gpu-detection.ps1 — surface contract' {

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

    Context 'Public surface' {
        It 'exports <Name>' -ForEach $script:ExpectedPublic {
            $script:FunctionNames | Should -Contain $Name
        }
    }

    Context 'Vendor PCI IDs (CODEX audit fix)' {
        It 'matches NVIDIA VEN_10DE' {
            # Pre-CODEX-fix: vendor filter accepted every Display device.
            # Post-fix: must match by PCI vendor ID. Regression test.
            $script:Content | Should -Match 'VEN_10DE'
        }

        It 'matches AMD VEN_1002' {
            $script:Content | Should -Match 'VEN_1002'
        }

        It 'matches Intel VEN_8086' {
            $script:Content | Should -Match 'VEN_8086'
        }
    }

    Context 'PnP filter respects status/presence' {
        It 'uses -PresentOnly to skip ghost devices' {
            # Per CODEX audit fix #1 — the filter was missing -PresentOnly
            # before, accepting any device ever installed.
            $script:Content | Should -Match '-PresentOnly'
        }

        It 'requires Status -eq "OK"' {
            # Same audit fix — restrict to currently-healthy adapters.
            $script:Content | Should -Match 'Status\s+-eq\s+"OK"'
        }
    }
}
