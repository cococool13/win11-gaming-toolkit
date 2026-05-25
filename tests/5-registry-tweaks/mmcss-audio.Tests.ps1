#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 5 registry tweaks/individual/tune-mmcss-audio.ps1 + restore-mmcss-audio.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Tune = Get-ToolkitScriptPath '5 registry tweaks/individual/tune-mmcss-audio.ps1'
    $script:Restore = Get-ToolkitScriptPath '5 registry tweaks/individual/restore-mmcss-audio.ps1'
    $script:TuneContent = Get-Content -Raw -LiteralPath $script:Tune
    $script:RestoreContent = Get-Content -Raw -LiteralPath $script:Restore
}

Describe 'MMCSS Pro Audio script pair' {

    Context 'File health' {
        It 'tune parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Tune, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It 'restore parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Restore, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Mutator surface' {
        It 'tune supports ShouldProcess' {
            (Test-ToolkitParameterShape -Path $script:Tune -RequireShouldProcess).SupportsShouldProcess | Should -BeTrue
        }
        It 'tune self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Tune).Passes | Should -BeTrue
        }
    }

    Context 'Manifest-tracked writes (CLAUDE.md invariant #2)' {
        $expectedIds = @(
            'reg:MmcssProAudioPriority'
            'reg:MmcssProAudioCategory'
            'reg:MmcssProAudioSfio'
            'reg:MmcssProAudioBackground'
        )
        It 'tune uses Id <_>' -ForEach $expectedIds {
            $script:TuneContent | Should -Match ([regex]::Escape($_))
        }
        It 'restore handles Id <_>' -ForEach $expectedIds {
            $script:RestoreContent | Should -Match ([regex]::Escape($_))
        }
    }

    Context 'Microsoft Learn citation' {
        It 'tune cites MMCSS docs' {
            $script:TuneContent | Should -Match 'learn\.microsoft\.com.*scheduler'
        }
    }
}
