#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Behavioral tests for lib/version-manifest.ps1 — 3-tier fallback
    (remote → cache → bundled) + GPU / Tool subsetters.

.DESCRIPTION
    Exercises every branch of Get-VersionManifest, Fetch-RemoteManifest,
    Get-GpuManifest, and Get-ToolManifest by mocking Invoke-WebRequest
    and overriding the script-scoped cache + bundled paths to per-test
    temp files. Lifts file from 0% coverage.

    No real network traffic.

.NOTES
    Test rig: tests/_common.ps1 provides shared helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'version-manifest.ps1')

    # Sample manifest matching the schema Fetch-RemoteManifest validates
    # (must have schemaVersion + gpu, plus tools.<name>.<fields>).
    $script:SampleJson = @'
{
  "schemaVersion": 2,
  "gpu": {
    "nvidia": { "url": "https://example/nv.exe", "sha256": "abc" }
  },
  "tools": {
    "ddu": { "url": "https://example/ddu.zip", "sha256": "111", "version": "18.0" },
    "sevenZip": { "url": "https://example/7z.exe", "sha256": "222", "version": "24.0" }
  }
}
'@
}

Describe 'lib/version-manifest.ps1' {

    Context 'Cache-root fallback (loads clean on macOS / Server Core)' {
        It 'declares a non-empty $script:ManifestCachePath even when ProgramData is absent' {
            # Regression for the dev-macOS Join-Path null bug surfaced
            # while writing this test file. The lib must dot-source
            # cleanly anywhere PowerShell 5.1+ runs.
            $script:ManifestCachePath | Should -Not -BeNullOrEmpty
            # On Windows the path includes ProgramData; elsewhere it
            # uses XDG_DATA_HOME or ~/.local/share — but it's always
            # under a 'GamingOpt' subdirectory.
            $script:ManifestCachePath | Should -Match 'GamingOpt'
        }
    }

    Context 'Fetch-RemoteManifest — happy path + failure branches' {

        BeforeEach {
            # Steer the lib at a per-test temp cache so we don't pollute
            # the dev box's real ~/.local/share/GamingOpt/.
            $script:OrigCache = $script:ManifestCachePath
            $script:TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("vm-test-" + [guid]::NewGuid())
            $script:ManifestCachePath = Join-Path $script:TmpDir 'versions-cache.json'
        }

        AfterEach {
            $script:ManifestCachePath = $script:OrigCache
            if ($script:TmpDir -and (Test-Path $script:TmpDir)) {
                Remove-Item -LiteralPath $script:TmpDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'returns the parsed manifest and writes the cache on a successful fetch' {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{ Content = $script:SampleJson }
            }
            $result = Fetch-RemoteManifest 6>$null
            $result | Should -Not -BeNullOrEmpty
            $result.schemaVersion | Should -Be 2
            $result.gpu.nvidia.url | Should -Be 'https://example/nv.exe'
            # Cache file should now exist with the fetched content.
            Test-Path $script:ManifestCachePath | Should -BeTrue
            (Get-Content $script:ManifestCachePath -Raw) | Should -Match 'schemaVersion'
        }

        It 'returns $null when remote payload lacks required fields' {
            # Schema validation: missing .gpu (or .schemaVersion) means
            # the fetch result is rejected even if the JSON parses.
            Mock Invoke-WebRequest {
                [PSCustomObject]@{ Content = '{"schemaVersion": 2}' }
            }
            (Fetch-RemoteManifest 6>$null) | Should -BeNullOrEmpty
            # Reject path does NOT write the cache (don't poison local with bad data).
            Test-Path $script:ManifestCachePath | Should -BeFalse
        }

        It 'returns $null when the HTTP call itself throws' {
            Mock Invoke-WebRequest { throw 'boom' }
            (Fetch-RemoteManifest 6>$null) | Should -BeNullOrEmpty
            Test-Path $script:ManifestCachePath | Should -BeFalse
        }
    }

    Context 'Get-VersionManifest — 3-tier fallback chain' {

        BeforeEach {
            $script:OrigCache = $script:ManifestCachePath
            $script:OrigBundled = $script:ManifestBundledPath
            $script:TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("vm-fallback-" + [guid]::NewGuid())
            New-Item -ItemType Directory -Path $script:TmpDir -Force | Out-Null
            $script:ManifestCachePath = Join-Path $script:TmpDir 'cache.json'
            $script:ManifestBundledPath = Join-Path $script:TmpDir 'bundled.json'
        }

        AfterEach {
            $script:ManifestCachePath = $script:OrigCache
            $script:ManifestBundledPath = $script:OrigBundled
            if ($script:TmpDir -and (Test-Path $script:TmpDir)) {
                Remove-Item -LiteralPath $script:TmpDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'tier 1: returns the remote manifest when available (cache + bundled not touched)' {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{ Content = $script:SampleJson }
            }
            $result = Get-VersionManifest 6>$null
            $result.schemaVersion | Should -Be 2
        }

        It 'tier 2: falls back to cache when remote fails AND cache exists' {
            Mock Invoke-WebRequest { throw 'no network' }
            # Pre-populate the cache file with a manifest containing a
            # distinct version marker so we can confirm it's the source.
            $cachedJson = $script:SampleJson -replace '"schemaVersion": 2', '"schemaVersion": 99'
            Set-Content -Path $script:ManifestCachePath -Value $cachedJson
            $result = Get-VersionManifest 6>$null
            $result.schemaVersion | Should -Be 99
        }

        It 'tier 3: falls back to bundled when remote fails AND no cache' {
            Mock Invoke-WebRequest { throw 'no network' }
            $bundledJson = $script:SampleJson -replace '"schemaVersion": 2', '"schemaVersion": 77'
            Set-Content -Path $script:ManifestBundledPath -Value $bundledJson
            $result = Get-VersionManifest 6>$null
            $result.schemaVersion | Should -Be 77
        }

        It 'throws when every tier fails (no remote, no cache, no bundled)' {
            Mock Invoke-WebRequest { throw 'no network' }
            { Get-VersionManifest 6>$null } | Should -Throw 'No version manifest available*'
        }
    }

    Context 'Get-GpuManifest / Get-ToolManifest subsetters' {

        BeforeEach {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{ Content = $script:SampleJson }
            }
        }

        It 'Get-GpuManifest returns the .gpu subtree' {
            $g = Get-GpuManifest 6>$null
            $g.nvidia.url | Should -Be 'https://example/nv.exe'
            $g.nvidia.sha256 | Should -Be 'abc'
        }

        It 'Get-ToolManifest returns the named tool entry' {
            $ddu = Get-ToolManifest -Name 'ddu' 6>$null
            $ddu.url | Should -Be 'https://example/ddu.zip'
            $ddu.version | Should -Be '18.0'
            $sevenZip = Get-ToolManifest -Name 'sevenZip' 6>$null
            $sevenZip.sha256 | Should -Be '222'
        }

        It 'Get-ToolManifest throws on an unknown tool' {
            { Get-ToolManifest -Name 'nope' 6>$null } | Should -Throw "*'nope' not found*"
        }
    }
}
