#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Combined static contract tests for the three hardware stress
    audit scripts (CPU / GPU / RAM).
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:AuditCases = @(
        @{ Name = 'check-cpu-stress' }
        @{ Name = 'check-gpu-stress' }
        @{ Name = 'check-ram' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
}

Describe 'Hardware stress audits (CPU / GPU / RAM)' {

    Context 'File health' {
        It '<Name>.ps1 parses' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It '<Name>.ps1 has comment-based help' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            $h = Test-ToolkitCommentBasedHelp -Path $path
            $h.HasSynopsis | Should -BeTrue
            $h.HasDescription | Should -BeTrue
        }
    }

    Context 'All three are READ-ONLY (no tracked-write helpers, no Set-/Remove-/New-ItemProperty)' {
        It '<Name>.ps1 does not call any mutator' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            $content = Get-Content -Raw -LiteralPath $path
            $content | Should -Not -Match 'Set-ToolkitRegistryValue'
            $content | Should -Not -Match 'Set-TrackedRegistry'
            $content | Should -Not -Match 'Set-ItemProperty'
            $content | Should -Not -Match 'Remove-ItemProperty'
            $content | Should -Not -Match 'New-ItemProperty'
            $content | Should -Not -Match 'sc\.exe'
        }
    }

    Context 'All three carry the 3 forced-decision header lines' {
        It '<Name>.ps1 declares Anti-cheat impact' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            (Get-Content -Raw -LiteralPath $path) | Should -Match '(?im)anti-cheat\s+impact:'
        }
        It '<Name>.ps1 declares Reboot required' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            (Get-Content -Raw -LiteralPath $path) | Should -Match '(?im)reboot\s+required:'
        }
        It '<Name>.ps1 declares Disk impact' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            (Get-Content -Raw -LiteralPath $path) | Should -Match '(?im)disk\s+impact:'
        }
    }

    Context 'API surface' {
        It '<Name>.ps1 supports -AsObject for pipeline use' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            (Get-Content -Raw -LiteralPath $path) | Should -Match '\[switch\]\$AsObject'
        }
        It '<Name>.ps1 supports -RunStress (reserved, opt-in only)' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            (Get-Content -Raw -LiteralPath $path) | Should -Match '\[switch\]\$RunStress'
        }
        It '<Name>.ps1 does NOT auto-invoke any stress tool' -ForEach $script:AuditCases {
            $path = Get-ToolkitScriptPath "12 hardware/$Name.ps1"
            $content = Get-Content -Raw -LiteralPath $path
            # No Start-Process / & without ShouldProcess gate (the audit
            # scripts purely report; -RunStress is reserved for future).
            $content | Should -Not -Match 'Start-Process\s+["''](?:prime95|occt|aida64|furmark|3dmark|mdsched)'
        }
    }

    Context 'Tool detection (each script reports availability without invoking)' {
        It 'check-cpu-stress detects Prime95 / OCCT / AIDA64' {
            $path = Get-ToolkitScriptPath '12 hardware/check-cpu-stress.ps1'
            $content = Get-Content -Raw -LiteralPath $path
            $content | Should -Match 'Prime95'
            $content | Should -Match 'OCCT'
            $content | Should -Match 'AIDA64'
        }
        It 'check-gpu-stress detects FurMark / 3DMark / Unigine' {
            $path = Get-ToolkitScriptPath '12 hardware/check-gpu-stress.ps1'
            $content = Get-Content -Raw -LiteralPath $path
            $content | Should -Match 'FurMark'
            $content | Should -Match '3DMark'
            $content | Should -Match 'Unigine'
        }
        It 'check-ram reads WHEA-Logger events + mdsched availability' {
            $path = Get-ToolkitScriptPath '12 hardware/check-ram.ps1'
            $content = Get-Content -Raw -LiteralPath $path
            $content | Should -Match 'WHEA-Logger'
            $content | Should -Match 'mdsched'
        }
    }
}
