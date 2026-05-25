#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 12 hardware/check-rebar.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Script = Get-ToolkitScriptPath '12 hardware/check-rebar.ps1'
    $script:Content = Get-Content -Raw -LiteralPath $script:Script
}

Describe 'check-rebar.ps1 — read-only ReBAR audit' {

    Context 'File health' {
        It 'parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Script, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It 'has comment-based help (SYNOPSIS + DESCRIPTION)' {
            $h = Test-ToolkitCommentBasedHelp -Path $script:Script
            $h.HasSynopsis | Should -BeTrue
            $h.HasDescription | Should -BeTrue
        }
    }

    Context 'Read-only contract — STAYS read-only' {
        It 'does not call any tracked-write helper' {
            $script:Content | Should -Not -Match 'Set-ToolkitRegistryValue'
            $script:Content | Should -Not -Match 'Set-TrackedRegistry'
        }
        It 'does not call Set-/Remove-/New-ItemProperty or sc.exe' {
            $script:Content | Should -Not -Match 'Set-ItemProperty'
            $script:Content | Should -Not -Match 'Remove-ItemProperty'
            $script:Content | Should -Not -Match 'New-ItemProperty'
            $script:Content | Should -Not -Match 'sc\.exe'
        }
    }

    Context 'Header decision lines (all 3 forced invariants)' {
        It 'declares Anti-cheat impact' {
            $script:Content | Should -Match '(?im)anti-cheat\s+impact:'
        }
        It 'declares Reboot required' {
            $script:Content | Should -Match '(?im)reboot\s+required:'
        }
        It 'declares Disk impact' {
            $script:Content | Should -Match '(?im)disk\s+impact:'
        }
    }

    Context 'API surface + content' {
        It 'supports -AsObject for pipeline use' {
            $script:Content | Should -Match '\[switch\]\$AsObject'
        }
        It 'reuses lib/gpu-detection (Get-GpuVendor + Test-ReBarEnabled)' {
            $script:Content | Should -Match 'Get-GpuVendor'
            $script:Content | Should -Match 'Test-ReBarEnabled'
            $script:Content | Should -Match 'gpu-detection\.ps1'
        }
        It 'cites Microsoft Learn + vendor docs in the header' {
            $script:Content | Should -Match 'learn\.microsoft\.com.*resizable-bar'
            $script:Content | Should -Match 'nvidia\.com'
            $script:Content | Should -Match 'amd\.com'
        }
    }

    Context 'Cross-platform safety' {
        It 'guards Get-PnpDevice availability for non-Windows runs' {
            $script:Content | Should -Match 'Get-Command Get-PnpDevice'
        }
    }
}
