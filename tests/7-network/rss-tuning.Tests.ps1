#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 7 network/enable-rss-tuning.ps1 + disable-rss-tuning.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Enable = Get-ToolkitScriptPath '7 network/enable-rss-tuning.ps1'
    $script:Disable = Get-ToolkitScriptPath '7 network/disable-rss-tuning.ps1'
    $script:EnableContent = Get-Content -Raw -LiteralPath $script:Enable
    $script:DisableContent = Get-Content -Raw -LiteralPath $script:Disable
}

Describe 'RSS tuning script pair' {

    Context 'File health' {
        It 'enable parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Enable, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It 'disable parses' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Disable, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Mutator surface' {
        It 'enable supports ShouldProcess' {
            (Test-ToolkitParameterShape -Path $script:Enable -RequireShouldProcess).SupportsShouldProcess | Should -BeTrue
        }
        It 'disable supports ShouldProcess' {
            (Test-ToolkitParameterShape -Path $script:Disable -RequireShouldProcess).SupportsShouldProcess | Should -BeTrue
        }
        It 'enable self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Enable).Passes | Should -BeTrue
        }
        It 'disable self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Disable).Passes | Should -BeTrue
        }
    }

    Context 'Sidecar via lib helpers (post-9d8781b refactor)' {
        It 'enable uses Save-ToolkitSidecar -Name rss' {
            # The lib helper's default behavior IS capture-once-preserve;
            # we don't need to re-assert the conditional locally.
            $script:EnableContent | Should -Match "Save-ToolkitSidecar\s+-Name\s+'rss'"
        }
        It 'disable reads via Read-ToolkitSidecar -Name rss' {
            $script:DisableContent | Should -Match "Read-ToolkitSidecar\s+-Name\s+'rss'"
        }
        It 'disable cleans up via Remove-ToolkitSidecar -Name rss' {
            $script:DisableContent | Should -Match "Remove-ToolkitSidecar\s+-Name\s+'rss'"
        }
        It 'enable+disable agree on the sidecar stem' {
            # Cross-script parity: a future rename on one side without
            # the other would silently break revert.
            $enableMatch = [regex]::Match($script:EnableContent, "Save-ToolkitSidecar\s+-Name\s+'([^']+)'")
            $disableMatch = [regex]::Match($script:DisableContent, "Read-ToolkitSidecar\s+-Name\s+'([^']+)'")
            $enableMatch.Success | Should -BeTrue
            $disableMatch.Success | Should -BeTrue
            $enableMatch.Groups[1].Value | Should -Be $disableMatch.Groups[1].Value
        }
    }

    Context 'Microsoft Learn citation' {
        It 'enable cites Set-NetAdapterRss docs' {
            $script:EnableContent | Should -Match 'learn\.microsoft\.com.*Set-NetAdapterRss'
        }
    }

    Context 'Comment-based help' {
        It 'enable has SYNOPSIS / DESCRIPTION / EXAMPLE / NOTES' {
            $h = Test-ToolkitCommentBasedHelp -Path $script:Enable
            $h.HasSynopsis | Should -BeTrue
            $h.HasDescription | Should -BeTrue
            $h.HasExample | Should -BeTrue
            $h.HasNotes | Should -BeTrue
        }
    }
}
