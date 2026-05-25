#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 12 hardware/check-input-polling.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Script = Get-ToolkitScriptPath '12 hardware/check-input-polling.ps1'
    $script:Content = Get-Content -Raw -LiteralPath $script:Script
}

Describe 'check-input-polling.ps1 — read-only HID input audit' {

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
        # The whole point of this script is to be a pure-read audit.
        # Any mutating cmdlet appearing here is a regression to be
        # caught before it ships.
        It 'does not call any tracked-write helper' {
            $script:Content | Should -Not -Match 'Set-ToolkitRegistryValue'
            $script:Content | Should -Not -Match 'Set-TrackedRegistry'
            $script:Content | Should -Not -Match 'Save-ToolkitSidecar'
        }
        It 'does not call Set-/Remove-/New-ItemProperty or sc.exe' {
            $script:Content | Should -Not -Match 'Set-ItemProperty'
            $script:Content | Should -Not -Match 'Remove-ItemProperty'
            $script:Content | Should -Not -Match 'New-ItemProperty'
            $script:Content | Should -Not -Match 'sc\.exe'
        }
    }

    Context 'API surface' {
        It 'supports -AsObject for pipeline use' {
            $script:Content | Should -Match '\[switch\]\$AsObject'
        }
        It 'classifies devices into the 3 standard PnP buckets' {
            $script:Content | Should -Match "'Mouse',\s*'Keyboard',\s*'HIDClass'"
        }
        It 'parses VID/PID via regex (not hardcoded vendor list)' {
            $script:Content | Should -Match 'VID_\(\[0-9A-Fa-f\]\{4\}\)'
            $script:Content | Should -Match 'PID_\(\[0-9A-Fa-f\]\{4\}\)'
        }
    }

    Context 'Cross-platform safety' {
        It 'guards Get-PnpDevice availability for non-Windows runs' {
            $script:Content | Should -Match 'Get-Command Get-PnpDevice'
        }
    }
}
