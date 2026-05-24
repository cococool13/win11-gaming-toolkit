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

    Context 'Sidecar discipline (matches disable-write-cache-flush.ps1 pattern)' {
        It 'enable captures baseline once (preserves existing sidecar)' {
            # Re-running enable shouldn't overwrite a sidecar that
            # already captured pre-toolkit state — otherwise a second
            # apply would record the toolkit-modified state as "before".
            $script:EnableContent | Should -Match 'Test-Path -LiteralPath \$sidecarPath'
            $script:EnableContent | Should -Match 'if \(-not \(Test-Path -LiteralPath \$sidecarPath\)\)'
        }
        It 'disable removes the sidecar after successful restore' {
            $script:DisableContent | Should -Match 'Remove-Item -LiteralPath \$sidecarPath'
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
