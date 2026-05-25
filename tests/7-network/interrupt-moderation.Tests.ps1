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

    Context 'Sidecar via lib helpers (post-9d8781b refactor)' {
        It 'disable captures via Save-ToolkitSidecar -Name rss-im' {
            $script:DisableContent | Should -Match "Save-ToolkitSidecar\s+-Name\s+'rss-im'"
        }
        It 'enable reads via Read-ToolkitSidecar -Name rss-im' {
            $script:EnableContent | Should -Match "Read-ToolkitSidecar\s+-Name\s+'rss-im'"
        }
        It 'enable cleans up via Remove-ToolkitSidecar -Name rss-im' {
            $script:EnableContent | Should -Match "Remove-ToolkitSidecar\s+-Name\s+'rss-im'"
        }
        It 'enable+disable agree on the sidecar stem' {
            # Cross-script parity (Note: capture happens in DISABLE,
            # restore in ENABLE — inverse of the RSS pair).
            $disableMatch = [regex]::Match($script:DisableContent, "Save-ToolkitSidecar\s+-Name\s+'([^']+)'")
            $enableMatch = [regex]::Match($script:EnableContent, "Read-ToolkitSidecar\s+-Name\s+'([^']+)'")
            $disableMatch.Success | Should -BeTrue
            $enableMatch.Success | Should -BeTrue
            $disableMatch.Groups[1].Value | Should -Be $enableMatch.Groups[1].Value
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
