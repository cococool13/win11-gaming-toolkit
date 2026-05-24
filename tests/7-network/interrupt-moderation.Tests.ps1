#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for the interrupt-moderation script pair.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Disable = Get-ToolkitScriptPath '7 network/disable-interrupt-moderation.ps1'
    $script:Enable = Get-ToolkitScriptPath '7 network/enable-interrupt-moderation.ps1'
    $script:DisableContent = Get-Content -Raw -LiteralPath $script:Disable
    $script:EnableContent = Get-Content -Raw -LiteralPath $script:Enable
}

Describe 'Interrupt Moderation script pair' {

    Context 'File health' {
        It 'disable parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Disable, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It 'enable parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Enable, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Mutator surface' {
        It 'disable supports ShouldProcess' {
            (Test-ToolkitParameterShape -Path $script:Disable -RequireShouldProcess).SupportsShouldProcess | Should -BeTrue
        }
        It 'enable supports ShouldProcess' {
            (Test-ToolkitParameterShape -Path $script:Enable -RequireShouldProcess).SupportsShouldProcess | Should -BeTrue
        }
        It 'disable self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Disable).Passes | Should -BeTrue
        }
        It 'enable self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Enable).Passes | Should -BeTrue
        }
    }

    Context 'Sidecar discipline + cross-script parity' {
        It 'both scripts use rss-im-before.json as the sidecar' {
            # Catches accidental rename that would break the contract.
            $script:DisableContent | Should -Match "'rss-im-before\.json'"
            $script:EnableContent | Should -Match "'rss-im-before\.json'"
        }
        It 'enable removes the sidecar after restore' {
            $script:EnableContent | Should -Match 'Remove-Item -LiteralPath \$sidecarPath'
        }
        It 'disable preserves existing sidecar (idempotent capture)' {
            $script:DisableContent | Should -Match 'if \(-not \(Test-Path -LiteralPath \$sidecarPath\)\)'
        }
    }

    Context 'Vendor property name coverage' {
        $vendorProperties = @(
            @{ Property = '*InterruptModeration' }      # Intel + Realtek
            @{ Property = 'InterruptModerationRate' }   # Marvell / Aquantia
            @{ Property = 'Interrupt Moderation' }      # legacy display name
        )
        It 'disable script searches for <Property>' -ForEach $vendorProperties {
            $script:DisableContent | Should -Match ([regex]::Escape($Property))
        }
    }

    Context 'Microsoft Learn citation' {
        It 'disable cites Set-NetAdapterAdvancedProperty docs' {
            $script:DisableContent | Should -Match 'learn\.microsoft\.com.*Set-NetAdapterAdvancedProperty'
        }
    }
}
