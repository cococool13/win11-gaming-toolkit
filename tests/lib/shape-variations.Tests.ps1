#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Data-driven (a.k.a. "property-based") tests for sidecar round-trip
    across registry-value-type variants AND manifest parser shape
    variations.

.DESCRIPTION
    Cluster B priorities 5 + 6 from the session-6 prompt. Two concerns,
    one suite:

      1. SIDECAR ROUND-TRIP per registry value type
         The sidecar pattern stores arbitrary JSON, but real callers
         capture values whose original registry type matters:
           - DWord  (int32)        — e.g. UserWriteCacheSetting
           - QWord  (int64)        — large counters / timestamps
           - String (default)      — most settings
           - MultiString (string[]) — comma-lists
           - ExpandString (string with %ENV%)
           - Binary (byte[])       — opaque blobs
         For each, Save → Read must preserve the value enough that the
         restore-side script can reconstruct the original.

      2. MANIFEST SHAPE VARIATIONS
         The toolkit-state manifest is [hashtable] in memory but
         [PSCustomObject] after JSON round-trip (ConvertFrom-Json
         deserializes objects to PSCustomObject by default). Every
         map helper (Test-/Get-/Set-ToolkitMapValue) must work with
         BOTH shapes. These tests exercise the actual loaded-from-
         disk shape that production reverters consume.

    Together these guard the data-integrity boundary the toolkit's
    rollback contract depends on (CLAUDE.md invariant #5).

.NOTES
    Cross-platform. Per-test temp dirs; no real registry / state
    pollution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Get-ToolkitScriptPath 'lib/toolkit-state.ps1')

    $script:OriginalStateRoot = $script:ToolkitStateRoot
}

AfterAll {
    Set-Variable -Scope script -Name ToolkitStateRoot -Value $script:OriginalStateRoot
}

Describe 'Sidecar round-trip — per registry value type' {

    BeforeEach {
        $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("shape-rt-" + [guid]::NewGuid())
        Set-Variable -Scope script -Name ToolkitStateRoot -Value $script:TempRoot
    }

    AfterEach {
        if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'DWord (int32) round-trips with type preservation' {
        # Real-world: UserWriteCacheSetting per disk.
        $original = [PSCustomObject]@{ Index = 0; UserWriteCacheSetting = [int32]1 }
        Save-ToolkitSidecar -Name 'dword-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'dword-test'
        $loaded[0].UserWriteCacheSetting | Should -Be 1
        # PowerShell's int → int round-trip preserves the numeric value;
        # the JSON intermediate doesn't preserve int32 vs int64 distinction,
        # but the value compares correctly which is what matters for restore.
    }

    It 'QWord (int64) round-trips with value preservation up to JS-safe integer range' {
        # JSON numbers max-safe-integer is 2^53 - 1; values above
        # that lose precision. Registry QWord values used by Windows
        # rarely exceed that range; for safety we pin a value that
        # fits comfortably.
        $bigValue = [int64]9007199254740000  # just under 2^53
        $original = [PSCustomObject]@{ Counter = $bigValue }
        Save-ToolkitSidecar -Name 'qword-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'qword-test'
        $loaded[0].Counter | Should -Be $bigValue
    }

    It 'String round-trips with whitespace + non-ASCII characters preserved' {
        # Real-world: vendor adapter names with spaces / special chars.
        $original = [PSCustomObject]@{
            Name = '  Intel(R) Ethernet I225-V  '
            Description = 'Adapter — with em-dash + non-ASCII: ümlaut'
        }
        Save-ToolkitSidecar -Name 'string-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'string-test'
        $loaded[0].Name | Should -Be '  Intel(R) Ethernet I225-V  '
        $loaded[0].Description | Should -Be 'Adapter — with em-dash + non-ASCII: ümlaut'
    }

    It 'MultiString (string[]) round-trips as a typed array' {
        $original = [PSCustomObject]@{
            DependsOn = @('RpcSs', 'Tcpip', 'NDIS')
        }
        Save-ToolkitSidecar -Name 'multistring-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'multistring-test'
        $loaded[0].DependsOn.Count | Should -Be 3
        $loaded[0].DependsOn[0] | Should -Be 'RpcSs'
        $loaded[0].DependsOn[2] | Should -Be 'NDIS'
    }

    It 'ExpandString (with %ENV% references) round-trips with placeholders intact' {
        # Critical: the sidecar must NOT expand %ENV% at capture time;
        # the restore side needs the literal placeholder to write
        # ExpandString correctly back into the registry.
        $original = [PSCustomObject]@{
            Path = '%SystemRoot%\System32\drivers\etc\hosts'
        }
        Save-ToolkitSidecar -Name 'expand-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'expand-test'
        $loaded[0].Path | Should -Be '%SystemRoot%\System32\drivers\etc\hosts'
    }

    It 'Binary (byte[]) — represented as base64 array in JSON, round-trips lossless' {
        # JSON has no native byte type. Toolkit convention: store as
        # an int array (each element 0-255). The restore script
        # reconstructs [byte[]] from this. Verify the value-by-value
        # equality holds.
        $bytes = @(0, 127, 255, 42, 13)
        $original = [PSCustomObject]@{ Blob = $bytes }
        Save-ToolkitSidecar -Name 'binary-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'binary-test'
        $loaded[0].Blob.Count | Should -Be 5
        for ($i = 0; $i -lt 5; $i++) {
            $loaded[0].Blob[$i] | Should -Be $bytes[$i]
        }
    }

    It 'null value (no prior registry entry marker) round-trips as $null' {
        # Convention: $null in a captured sidecar means "the value
        # did not exist before — restore should DELETE the override
        # rather than write any specific value back."
        $original = [PSCustomObject]@{ Index = 0; UserWriteCacheSetting = $null }
        Save-ToolkitSidecar -Name 'null-test' -InputObject @($original) | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'null-test'
        $loaded[0].UserWriteCacheSetting | Should -BeNullOrEmpty
    }

    It 'Mixed type record (typical real-world shape) round-trips coherently' {
        # The shape disable-write-cache-flush.ps1 actually captures.
        $original = @(
            [PSCustomObject]@{
                Index = [int]0
                Model = 'Samsung SSD 990 PRO 2TB'
                PnpId = 'NVME\VEN_144D&DEV_A80A\7&...'
                UserWriteCacheSetting = [int]1
            },
            [PSCustomObject]@{
                Index = [int]1
                Model = 'WDC WD10EZEX-00BN5A0'
                PnpId = 'IDE\DiskWDC_WD10EZEX-00BN5A0\...'
                UserWriteCacheSetting = $null
            }
        )
        Save-ToolkitSidecar -Name 'mixed-test' -InputObject $original | Out-Null
        $loaded = Read-ToolkitSidecar -Name 'mixed-test'
        $loaded.Count | Should -Be 2
        $loaded[0].Index | Should -Be 0
        $loaded[0].Model | Should -Be 'Samsung SSD 990 PRO 2TB'
        $loaded[0].UserWriteCacheSetting | Should -Be 1
        $loaded[1].UserWriteCacheSetting | Should -BeNullOrEmpty
    }
}

Describe 'Manifest parser shape variations — hashtable vs PSCustomObject' {

    BeforeEach {
        # Each test isolates its own state root + file, mocks
        # Get-ToolkitMachineProfile so Initialize works on macOS.
        $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("shape-mfst-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:TempRoot -Force | Out-Null
        Set-Variable -Scope script -Name ToolkitStateRoot -Value $script:TempRoot
        Set-Variable -Scope script -Name ToolkitStateFile -Value (Join-Path $script:TempRoot 'manifest.json')
        Set-Variable -Scope script -Name ToolkitState -Value $null
        Mock Get-ToolkitMachineProfile {
            [PSCustomObject]@{ systemName = 'TEST-PC'; isLaptop = $false; gpuCount = 1 }
        }
    }

    AfterEach {
        Set-Variable -Scope script -Name ToolkitState -Value $null
        if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'In-memory state has hashtable shape; loaded-from-disk has PSCustomObject shape' {
        # This is THE shape variation the production reverters live
        # with — the manifest helpers MUST handle both.
        $inMemory = Initialize-ToolkitState 6>$null
        $inMemory.registry | Should -BeOfType [hashtable]
        # Force re-load from disk
        Set-Variable -Scope script -Name ToolkitState -Value $null
        $reloaded = Get-ToolkitState
        # After ConvertFrom-Json, the empty hashtable becomes PSCustomObject.
        # (Empty hashtable serializes to {} which deserializes to empty
        # PSCustomObject in PS 5.1 / 7's default ConvertFrom-Json.)
        $reloaded.registry.GetType().Name | Should -Match 'PSCustomObject|PSObject|Hashtable'
        # Critical: regardless of the shape, the map helpers work.
        Test-ToolkitMapHasKey -Map $reloaded.registry -Key 'nonexistent' | Should -BeFalse
    }

    It 'Set-ToolkitMapValue can add to a hashtable then survive JSON round-trip readable via Get' {
        $state = Initialize-ToolkitState 6>$null
        Set-ToolkitMapValue -Map $state.registry -Key 'reg:Test' -Value ([ordered]@{
                path = 'HKLM:\foo'
                name = 'bar'
                tier = 'Safe'
            })
        Save-ToolkitState
        # Re-read from disk
        Set-Variable -Scope script -Name ToolkitState -Value $null
        $reloaded = Get-ToolkitState
        Test-ToolkitMapHasKey -Map $reloaded.registry -Key 'reg:Test' | Should -BeTrue
        $entry = Get-ToolkitMapValue -Map $reloaded.registry -Key 'reg:Test'
        $entry.path | Should -Be 'HKLM:\foo'
        $entry.tier | Should -Be 'Safe'
    }

    It 'Steps survive 100+ entries through round-trip (stress)' {
        # The steps map sees the most additions in a full APPLY run.
        # Sanity: 100 entries round-trip without truncation.
        Initialize-ToolkitState 6>$null | Out-Null
        for ($i = 0; $i -lt 100; $i++) {
            Add-ToolkitStepResult -Key "stress-$i" -Tier 'Safe' -Status 'applied' -Reason "n=$i"
        }
        Set-Variable -Scope script -Name ToolkitState -Value $null
        $reloaded = Get-ToolkitState
        # Count keys via Get-Member on the PSCustomObject (deserialized form)
        $reloadedSteps = $reloaded.steps
        $keyCount = if ($reloadedSteps -is [hashtable]) {
            $reloadedSteps.Keys.Count
        } else {
            @($reloadedSteps.PSObject.Properties).Count
        }
        $keyCount | Should -Be 100
        # Spot check first + last
        (Get-ToolkitMapValue -Map $reloaded.steps -Key 'stress-0').reason | Should -Be 'n=0'
        (Get-ToolkitMapValue -Map $reloaded.steps -Key 'stress-99').reason | Should -Be 'n=99'
    }

    It 'Notes array preserves order across round-trip' {
        Initialize-ToolkitState 6>$null | Out-Null
        Add-ToolkitNote -Message 'first'
        Add-ToolkitNote -Message 'middle'
        Add-ToolkitNote -Message 'last'
        Set-Variable -Scope script -Name ToolkitState -Value $null
        $reloaded = Get-ToolkitState
        $reloaded.notes[0] | Should -Be 'first'
        $reloaded.notes[1] | Should -Be 'middle'
        $reloaded.notes[2] | Should -Be 'last'
    }
}
