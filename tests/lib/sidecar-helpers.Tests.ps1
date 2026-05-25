#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Behavioral tests for the sidecar JSON helpers in lib/toolkit-state.ps1.

.DESCRIPTION
    The sidecar helpers (Get/Save/Read/Remove-ToolkitSidecar) own the
    "capture pre-toolkit state to a per-tweak JSON beside the manifest"
    pattern. Three production callers consume them
    (write-cache-flush, RSS, IM); these tests pin the contract those
    callers depend on:

      - Save is idempotent (capture once, preserve on re-run unless -Force)
      - Save honors -WhatIf (no file written, returns $null)
      - Read returns an array even for single-element JSON (ConvertFrom-Json
        scalar quirk in PS 5.1 / 7)
      - Read returns $null for missing or unparseable sidecars
      - Remove is idempotent (silent on absent)
      - Path resolution is deterministic and lives next to the manifest

    File operations are cross-platform; this suite runs cleanly on
    macOS dev boxes (uses the $XDG_DATA_HOME fallback root that
    Initialize-ToolkitState configured).

.NOTES
    Each test redirects $script:ToolkitStateRoot to a per-test temp
    dir so we never collide with a real manifest. Cleanup in AfterAll.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Get-ToolkitScriptPath 'lib/toolkit-state.ps1')

    # Redirect the toolkit state root for the lifetime of this suite.
    # Set-Variable -Scope script reaches the dot-sourced script's
    # script: scope (same as $script:ToolkitStateRoot inside the lib).
    $script:OriginalStateRoot = $script:ToolkitStateRoot
    $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("toolkit-sidecar-test-{0}" -f [Guid]::NewGuid())
    Set-Variable -Scope script -Name ToolkitStateRoot -Value $script:TempRoot
}

AfterAll {
    Set-Variable -Scope script -Name ToolkitStateRoot -Value $script:OriginalStateRoot
    if (Test-Path -LiteralPath $script:TempRoot) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Sidecar helpers' {

    BeforeEach {
        # Fresh state root per test so order-independence holds.
        # Must live inside the Describe — Pester v5 disallows BeforeEach
        # at the block-container root.
        if (Test-Path -LiteralPath $script:TempRoot) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-ToolkitSidecarPath' {
        It 'returns <stem>-before.json under the state root' {
            $path = Get-ToolkitSidecarPath -Name 'rss'
            $path | Should -BeLike "*rss-before.json"
            (Split-Path -Parent $path) | Should -Be $script:TempRoot
        }
    }

    Context 'Save-ToolkitSidecar' {
        It 'creates the state root if missing (no manual mkdir)' {
            Test-Path -LiteralPath $script:TempRoot | Should -BeFalse
            $null = Save-ToolkitSidecar -Name 'rss' -InputObject @{ foo = 'bar' }
            Test-Path -LiteralPath $script:TempRoot | Should -BeTrue
        }

        It 'writes valid JSON containing the input' {
            $payload = @{ Name = 'Eth0'; Enabled = $true; Queues = 4 }
            $path = Save-ToolkitSidecar -Name 'rss' -InputObject $payload
            $path | Should -Not -BeNullOrEmpty
            $decoded = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
            $decoded.Name | Should -Be 'Eth0'
            $decoded.Enabled | Should -BeTrue
            $decoded.Queues | Should -Be 4
        }

        It 'returns the sidecar path on first save' {
            $path = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 1 }
            $path | Should -Be (Get-ToolkitSidecarPath -Name 'rss')
        }

        It 'is idempotent: second call without -Force returns $null and does NOT rewrite' {
            $first = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 1 }
            $firstMtime = (Get-Item -LiteralPath $first).LastWriteTimeUtc
            Start-Sleep -Milliseconds 50
            $second = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 2 }
            $second | Should -BeNullOrEmpty
            $secondMtime = (Get-Item -LiteralPath $first).LastWriteTimeUtc
            $secondMtime | Should -Be $firstMtime
            # Content unchanged (k=1, not k=2)
            $decoded = Get-Content -Raw -LiteralPath $first | ConvertFrom-Json
            $decoded.k | Should -Be 1
        }

        It '-Force overwrites an existing sidecar' {
            $path = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 1 }
            Start-Sleep -Milliseconds 10
            $again = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 99 } -Force
            $again | Should -Be $path
            $decoded = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
            $decoded.k | Should -Be 99
        }

        It '-WhatIf does not write a file and returns $null' {
            $result = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 1 } -WhatIf
            $result | Should -BeNullOrEmpty
            Test-Path -LiteralPath (Get-ToolkitSidecarPath -Name 'rss') | Should -BeFalse
        }
    }

    Context 'Read-ToolkitSidecar' {
        It 'returns $null when the sidecar is missing' {
            Read-ToolkitSidecar -Name 'never-saved' | Should -BeNullOrEmpty
        }

        It 'returns an array even for a single-element JSON' {
            # Regression test for the scalar-vs-array ConvertFrom-Json
            # quirk that bit 3 callers before this lib existed.
            # Note: ,$result | Should -BeOfType [System.Array] doesn't
            # survive Pester's pipeline unwrap. .Count works because
            # arrays expose Count; PSCustomObject does not (would throw).
            Save-ToolkitSidecar -Name 'rss' -InputObject @([PSCustomObject]@{ N = 'eth0' }) | Out-Null
            $result = Read-ToolkitSidecar -Name 'rss'
            $result.Count | Should -Be 1 -Because 'a single-element array still indexes; a bare PSCustomObject does not'
            $result[0].N | Should -Be 'eth0'
        }

        It 'returns an array for multi-element JSON' {
            Save-ToolkitSidecar -Name 'rss' -InputObject @(
                [PSCustomObject]@{ N = 'eth0' },
                [PSCustomObject]@{ N = 'wifi0' }
            ) | Out-Null
            $result = Read-ToolkitSidecar -Name 'rss'
            $result.Count | Should -Be 2
            $result[1].N | Should -Be 'wifi0'
        }

        It 'returns $null for unparseable JSON' {
            $path = Get-ToolkitSidecarPath -Name 'corrupt'
            New-Item -ItemType Directory -Path $script:TempRoot -Force | Out-Null
            Set-Content -LiteralPath $path -Value '{ this is not JSON' -Encoding utf8
            Read-ToolkitSidecar -Name 'corrupt' | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-ToolkitSidecar' {
        It 'deletes an existing sidecar' {
            Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 1 } | Out-Null
            $path = Get-ToolkitSidecarPath -Name 'rss'
            Test-Path -LiteralPath $path | Should -BeTrue
            Remove-ToolkitSidecar -Name 'rss'
            Test-Path -LiteralPath $path | Should -BeFalse
        }

        It 'is idempotent (no error when sidecar missing)' {
            { Remove-ToolkitSidecar -Name 'never-saved' } | Should -Not -Throw
        }

        It '-WhatIf does not delete' {
            $path = Save-ToolkitSidecar -Name 'rss' -InputObject @{ k = 1 }
            Remove-ToolkitSidecar -Name 'rss' -WhatIf
            Test-Path -LiteralPath $path | Should -BeTrue
        }
    }
}
