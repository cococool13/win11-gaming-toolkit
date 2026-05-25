#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 12 hardware/check-directstorage.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Script = Get-ToolkitScriptPath '12 hardware/check-directstorage.ps1'
    $script:Content = Get-Content -Raw -LiteralPath $script:Script
}

Describe 'check-directstorage.ps1 — read-only prereq audit' {

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

    Context 'Audit coverage — 4 prerequisite functions' {
        It 'tests NVMe presence via Get-PhysicalDisk BusType' {
            $script:Content | Should -Match "BusType\s+-eq\s+'NVMe'"
        }
        It 'tests Windows build floor (18363 / 19041 / 22000)' {
            $script:Content | Should -Match '22000'
            $script:Content | Should -Match '19041'
            $script:Content | Should -Match '18363'
        }
        It 'tests DX12 Ultimate runtime via build check' {
            $script:Content | Should -Match 'Test-Dx12UltimateSupport'
        }
        It 'tests GPU presence + vendor expectations' {
            $script:Content | Should -Match 'Test-GpuDirectStorageCapable'
            $script:Content | Should -Match 'RTX 2000\+|RX 5000\+|Intel Arc'
        }
    }

    Context 'API surface + sources' {
        It 'supports -AsObject for pipeline use' {
            $script:Content | Should -Match '\[switch\]\$AsObject'
        }
        It 'cites Microsoft Learn DirectStorage docs' {
            $script:Content | Should -Match 'learn\.microsoft\.com.*directstorage'
        }
    }
}
