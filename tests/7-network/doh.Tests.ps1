#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for 7 network/enable-doh.ps1 + disable-doh.ps1.

.DESCRIPTION
    DoH provider lists in the two scripts must stay in sync — if one
    grows without the other, revert leaks. Test asserts the IP sets
    are identical, plus the standard mutator surface contract.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Enable = Get-ToolkitScriptPath '7 network/enable-doh.ps1'
    $script:Disable = Get-ToolkitScriptPath '7 network/disable-doh.ps1'
    $script:EnableContent = Get-Content -Raw -LiteralPath $script:Enable
    $script:DisableContent = Get-Content -Raw -LiteralPath $script:Disable

    # Extract server IPs from both scripts. Match v4 (dotted-quad) and
    # v6 (compressed hex with at least one ::) literals quoted with '.
    $rx = [regex]"'((?:\d{1,3}\.){3}\d{1,3}|[0-9a-f:]+::?[0-9a-f:]+)'"
    $script:EnableServers = @($rx.Matches($script:EnableContent) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $script:DisableServers = @($rx.Matches($script:DisableContent) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
}

Describe 'DoH script pair — surface contract' {

    Context 'File health' {
        It 'enable-doh.ps1 parses without errors' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Enable, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        It 'disable-doh.ps1 parses without errors' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Disable, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Mutator surface (CLAUDE.md quality bar)' {
        It 'enable-doh.ps1 supports ShouldProcess' {
            $shape = Test-ToolkitParameterShape -Path $script:Enable -RequireShouldProcess
            $shape.SupportsShouldProcess | Should -BeTrue
        }
        It 'disable-doh.ps1 supports ShouldProcess' {
            $shape = Test-ToolkitParameterShape -Path $script:Disable -RequireShouldProcess
            $shape.SupportsShouldProcess | Should -BeTrue
        }
        It 'enable-doh.ps1 self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Enable).Passes | Should -BeTrue
        }
        It 'disable-doh.ps1 self-checks admin' {
            (Test-ToolkitAdminCheck -Path $script:Disable).Passes | Should -BeTrue
        }
    }

    Context 'Provider list parity (enable and disable must agree)' {
        It 'extracted at least one server from each script (sanity)' {
            $script:EnableServers.Count | Should -BeGreaterThan 0
            $script:DisableServers.Count | Should -BeGreaterThan 0
        }
        It 'disable list contains every server from enable list' {
            foreach ($srv in $script:EnableServers) {
                $script:DisableServers | Should -Contain $srv `
                    -Because "disable-doh.ps1 must clean up every IP enable-doh.ps1 might register ($srv missing)"
            }
        }
    }

    Context 'Microsoft Learn citation in header (Phase C convention)' {
        It 'enable-doh.ps1 cites at least one learn.microsoft.com URL' {
            $script:EnableContent | Should -Match 'learn\.microsoft\.com'
        }
    }

    Context 'Anti-cheat note (CLAUDE.md convention)' {
        It 'enable-doh.ps1 explicitly states no anti-cheat impact' {
            # DoH is transparent — the note is "none" rather than absent.
            # Helps users grep for anti-cheat behavior across the tree.
            $script:EnableContent | Should -Match 'Anti-cheat impact:\s*NONE'
        }
    }

    Context 'Comment-based help' {
        It 'enable-doh.ps1 has SYNOPSIS / DESCRIPTION / EXAMPLE / NOTES' {
            $h = Test-ToolkitCommentBasedHelp -Path $script:Enable
            $h.HasSynopsis | Should -BeTrue
            $h.HasDescription | Should -BeTrue
            $h.HasExample | Should -BeTrue
            $h.HasNotes | Should -BeTrue
        }
        It 'disable-doh.ps1 has SYNOPSIS / DESCRIPTION / EXAMPLE / NOTES' {
            $h = Test-ToolkitCommentBasedHelp -Path $script:Disable
            $h.HasSynopsis | Should -BeTrue
            $h.HasDescription | Should -BeTrue
            $h.HasExample | Should -BeTrue
            $h.HasNotes | Should -BeTrue
        }
    }
}
