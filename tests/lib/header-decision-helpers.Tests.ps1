#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Behavioral tests for lib/header-decision-helpers.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'header-decision-helpers.ps1')
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

Describe 'lib/header-decision-helpers.ps1' {

    Context 'New-ToolkitHeaderInvariantCases — discovery + filtering' {

        It 'returns one case per mutator script (no exclusions)' {
            $cases = New-ToolkitHeaderInvariantCases -RepoRoot $script:RepoRoot
            $cases.Count | Should -BeGreaterThan 50  # toolkit has 60+ mutators
            $cases | ForEach-Object {
                $_.Path | Should -Not -BeNullOrEmpty
                $_.FullPath | Should -Not -BeNullOrEmpty
                Test-Path -LiteralPath $_.FullPath | Should -BeTrue
            }
        }

        It 'filters out KnownExcluded entries entirely (not just gap-flagged)' {
            $withExclusion = New-ToolkitHeaderInvariantCases -RepoRoot $script:RepoRoot `
                -KnownExcluded @('DduManual.ps1')
            $withoutExclusion = New-ToolkitHeaderInvariantCases -RepoRoot $script:RepoRoot
            $withExclusion.Count | Should -BeLessThan $withoutExclusion.Count
            ($withExclusion | Where-Object { $_.Path -eq 'DduManual.ps1' }) | Should -BeNullOrEmpty
        }

        It 'flags KnownGaps with HeaderGap=$true (still iterated)' {
            # Pick a real mutator that exists. Use disable-doh — exists,
            # is a known mutator, no risk of pre-existing state being weird.
            $cases = New-ToolkitHeaderInvariantCases -RepoRoot $script:RepoRoot `
                -KnownGaps @('7 network/disable-doh.ps1')
            $target = $cases | Where-Object { $_.Path -eq '7 network/disable-doh.ps1' }
            $target | Should -Not -BeNullOrEmpty
            $target.HeaderGap | Should -BeTrue
        }

        It 'returns HeaderGap=$false for scripts NOT in the gap list' {
            $cases = New-ToolkitHeaderInvariantCases -RepoRoot $script:RepoRoot `
                -KnownGaps @('7 network/disable-doh.ps1')
            $other = $cases | Where-Object { $_.Path -eq '7 network/enable-doh.ps1' }
            $other.HeaderGap | Should -BeFalse
        }
    }

    Context 'Test-ToolkitHeaderLine — regex match within head window' {

        BeforeEach {
            $script:TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("hdr-test-" + [guid]::NewGuid())
            New-Item -ItemType Directory -Path $script:TmpDir -Force | Out-Null
        }

        AfterEach {
            if ($script:TmpDir -and (Test-Path $script:TmpDir)) {
                Remove-Item -LiteralPath $script:TmpDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'matches a line within the default 120-line window' {
            $path = Join-Path $script:TmpDir 'match.ps1'
            "# Anti-cheat impact: NONE" | Set-Content -LiteralPath $path
            Test-ToolkitHeaderLine -Path $path -Pattern '(?im)anti-cheat\s+impact:' |
                Should -BeTrue
        }

        It 'returns $false when the pattern is absent' {
            $path = Join-Path $script:TmpDir 'no-match.ps1'
            "# some other content" | Set-Content -LiteralPath $path
            Test-ToolkitHeaderLine -Path $path -Pattern '(?im)anti-cheat\s+impact:' |
                Should -BeFalse
        }

        It 'is case-insensitive when caller passes (?i) flag' {
            $path = Join-Path $script:TmpDir 'case.ps1'
            '# ANTI-CHEAT Impact: NONE' | Set-Content -LiteralPath $path
            Test-ToolkitHeaderLine -Path $path -Pattern '(?im)anti-cheat\s+impact:' |
                Should -BeTrue
        }

        It 'respects -HeadLineCount — line beyond limit does NOT match' {
            $path = Join-Path $script:TmpDir 'beyond.ps1'
            # 5 dummy lines, then the marker on line 6
            $content = (1..5 | ForEach-Object { "# line $_" }) + '# Anti-cheat impact: NONE'
            $content | Set-Content -LiteralPath $path
            # Cap at 5 lines — should NOT find the marker on line 6
            Test-ToolkitHeaderLine -Path $path -Pattern '(?im)anti-cheat\s+impact:' -HeadLineCount 5 |
                Should -BeFalse
            # Cap at 10 lines — DOES find it
            Test-ToolkitHeaderLine -Path $path -Pattern '(?im)anti-cheat\s+impact:' -HeadLineCount 10 |
                Should -BeTrue
        }

        It 'returns a real Boolean (not a [Match] object or $null)' {
            $path = Join-Path $script:TmpDir 'bool-shape.ps1'
            '# Anti-cheat impact: NONE' | Set-Content -LiteralPath $path
            $result = Test-ToolkitHeaderLine -Path $path -Pattern '(?im)anti-cheat\s+impact:'
            $result | Should -BeOfType [bool]
        }
    }
}
