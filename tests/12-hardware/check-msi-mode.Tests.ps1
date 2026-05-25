#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 12 hardware/check-msi-mode.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Script = Get-ToolkitScriptPath '12 hardware/check-msi-mode.ps1'
    $script:Content = Get-Content -Raw -LiteralPath $script:Script
}

Describe 'check-msi-mode.ps1 — read-only MSI mode audit' {

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
        # Audit-first design from the session prompt: no mutations.
        # Catches regression to a bulk-mutate implementation.
        It 'does not call any tracked-write helper' {
            $script:Content | Should -Not -Match 'Set-ToolkitRegistryValue'
            $script:Content | Should -Not -Match 'Set-TrackedRegistry'
            $script:Content | Should -Not -Match 'Set-ToolkitServiceStartMode'
        }
        It 'does not call Set-/Remove-/New-ItemProperty or sc.exe' {
            $script:Content | Should -Not -Match 'Set-ItemProperty'
            $script:Content | Should -Not -Match 'Remove-ItemProperty'
            $script:Content | Should -Not -Match 'New-ItemProperty'
            $script:Content | Should -Not -Match 'sc\.exe'
        }
    }

    Context 'Coverage of the three device classes' {
        It 'enumerates GPU (Display class), Net, and NVMe (SCSIAdapter filtered)' {
            $script:Content | Should -Match "Category\s*=\s*'GPU'"
            $script:Content | Should -Match "PnpClass\s*=\s*'Display'"
            $script:Content | Should -Match "Category\s*=\s*'Net'"
            $script:Content | Should -Match "PnpClass\s*=\s*'Net'"
            $script:Content | Should -Match "Category\s*=\s*'NVMe'"
            $script:Content | Should -Match "PnpClass\s*=\s*'SCSIAdapter'"
            $script:Content | Should -Match 'NVMe\|NVM Express'
        }
    }

    Context 'API surface' {
        It 'supports -AsObject for pipeline use' {
            $script:Content | Should -Match '\[switch\]\$AsObject'
        }
        It 'reads MSISupported under the documented Interrupt Management path' {
            $script:Content | Should -Match 'Interrupt Management'
            $script:Content | Should -Match 'MessageSignaledInterruptProperties'
            $script:Content | Should -Match 'MSISupported'
        }
    }

    Context 'Cross-platform safety' {
        It 'guards Get-PnpDevice availability for non-Windows runs' {
            $script:Content | Should -Match 'Get-Command Get-PnpDevice'
        }
    }
}
