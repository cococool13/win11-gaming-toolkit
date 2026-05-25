#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 12 hardware/check-pagefile.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Script = Get-ToolkitScriptPath '12 hardware/check-pagefile.ps1'
    $script:Content = Get-Content -Raw -LiteralPath $script:Script
}

Describe 'check-pagefile.ps1 — read-only pagefile audit' {

    Context 'File health' {
        It 'parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Script, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It 'has comment-based help' {
            $h = Test-ToolkitCommentBasedHelp -Path $script:Script
            $h.HasSynopsis | Should -BeTrue
            $h.HasDescription | Should -BeTrue
        }
    }

    Context 'Read-only contract' {
        It 'does not call any tracked-write helper or mutating cmdlet' {
            $script:Content | Should -Not -Match 'Set-ToolkitRegistryValue'
            $script:Content | Should -Not -Match 'Set-ItemProperty'
            $script:Content | Should -Not -Match 'New-ItemProperty'
            $script:Content | Should -Not -Match 'sc\.exe'
            $script:Content | Should -Not -Match 'wmic'
        }
    }

    Context 'Header decision lines' {
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

    Context 'Audit content' {
        It 'reads Win32_PageFileUsage + Win32_PageFileSetting' {
            $script:Content | Should -Match 'Win32_PageFileUsage'
            $script:Content | Should -Match 'Win32_PageFileSetting'
        }
        It 'reads total RAM via Win32_ComputerSystem' {
            $script:Content | Should -Match 'Win32_ComputerSystem'
            $script:Content | Should -Match 'TotalPhysicalMemory'
        }
        It 'computes recommended initial/max from installed RAM' {
            $script:Content | Should -Match 'recommendedInitialMB'
            $script:Content | Should -Match 'recommendedMaxMB'
        }
        It 'cites Microsoft Learn pagefile-sizing doc' {
            $script:Content | Should -Match 'learn\.microsoft\.com.*page-file-size'
        }
    }

    Context 'API surface' {
        It 'supports -AsObject' {
            $script:Content | Should -Match '\[switch\]\$AsObject'
        }
    }
}
