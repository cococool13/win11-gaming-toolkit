#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Static contract tests for lib/download-helpers.ps1.

.DESCRIPTION
    download-helpers.ps1 is dot-sourced by every install-* script and
    DduManual.ps1. Regressions here break the SHA-256 verify chain
    (CLAUDE.md invariant #4) or the internet-preflight short-circuit.

    AST + behavioral assertions on Test-FileSha256 (deterministic;
    runs from a temp file with known hash).
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:ExpectedPublic = @(
        @{ Name = 'Write-Info' }
        @{ Name = 'Ensure-Internet' }
        @{ Name = 'Ensure-Directory' }
        @{ Name = 'Get-FileFromWeb' }
        @{ Name = 'Test-FileSha256' }
        @{ Name = 'Test-FileAuthenticode' }
        @{ Name = 'Ensure-7Zip' }
        @{ Name = 'Restore-DriverSearchPolicy' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    $script:Target = Get-ToolkitScriptPath 'lib/download-helpers.ps1'
    $script:Content = Get-Content -Raw -LiteralPath $script:Target
    $script:Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:Target, [ref]$null, [ref]$null
    )
    $script:FunctionNames = @($script:Ast.FindAll({
                param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true) | ForEach-Object Name)

    # Source the lib so behavioral tests can call Test-FileSha256.
    . $script:Target

    # Get-AuthenticodeSignature is Windows-only (Microsoft.PowerShell.
    # Security module). On dev macOS / Linux it doesn't exist, and
    # Pester's Mock can only intercept existing commands. Define via
    # Set-Item Function: rather than `function …` syntax so PSSA's
    # PSAvoidOverwritingBuiltInCmdlets rule (which only triggers on
    # the declarative form) doesn't flag the necessary stub.
    if (-not (Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue)) {
        Set-Item Function:Get-AuthenticodeSignature {
            param([string]$FilePath)
            throw 'Get-AuthenticodeSignature stub: every behavioral test must Mock this'
        }
    }
}

Describe 'lib/download-helpers.ps1 — surface + behavior contract' {

    Context 'File health' {
        It 'parses without errors' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:Target, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Public surface' {
        It 'exports <Name>' -ForEach $script:ExpectedPublic {
            $script:FunctionNames | Should -Contain $Name
        }
    }

    Context 'Ensure-Internet uses .NET Ping (no Test-Connection -ComputerName)' {
        It 'avoids the analyzer false-positive cmdlet pattern' {
            # Regression test for commit 4e993a9 — Test-Connection swap
            # to [System.Net.NetworkInformation.Ping]::new().Send.
            $script:Content | Should -Not -Match 'Test-Connection.*-ComputerName'
            $script:Content | Should -Match '\[System\.Net\.NetworkInformation\.Ping\]'
        }
    }

    Context 'Test-FileSha256 behavioral contract (CLAUDE.md invariant #4)' {
        BeforeAll {
            # Create a deterministic temp file with a known SHA-256.
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("test-sha256-{0}.txt" -f [Guid]::NewGuid())
            'hello world' | Set-Content -LiteralPath $script:TempFile -NoNewline -Encoding utf8
            # SHA-256 of "hello world" (no newline, utf8):
            $script:KnownGoodHash = 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'
            $script:KnownBadHash = '0000000000000000000000000000000000000000000000000000000000000000'
        }

        AfterAll {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
        }

        It 'returns $true for a matching hash' {
            $result = Test-FileSha256 -Path $script:TempFile -ExpectedHash $script:KnownGoodHash
            $result | Should -BeTrue
        }

        It 'returns $false for a mismatching hash' {
            $result = Test-FileSha256 -Path $script:TempFile -ExpectedHash $script:KnownBadHash
            $result | Should -BeFalse
        }

        It 'is case-insensitive on the expected hash' {
            $upperHash = $script:KnownGoodHash.ToUpper()
            $result = Test-FileSha256 -Path $script:TempFile -ExpectedHash $upperHash
            $result | Should -BeTrue
        }
    }

    Context 'Ensure-Directory is idempotent' {
        BeforeAll {
            $script:TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("test-ensuredir-{0}" -f [Guid]::NewGuid())
        }
        AfterAll {
            Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        It 'creates a missing directory' {
            Ensure-Directory -Path $script:TempDir
            Test-Path -LiteralPath $script:TempDir -PathType Container | Should -BeTrue
        }
        It 're-runs without error when the directory already exists' {
            { Ensure-Directory -Path $script:TempDir } | Should -Not -Throw
            { Ensure-Directory -Path $script:TempDir } | Should -Not -Throw
        }
    }

    Context 'Write-Info (informational output wrapper)' {
        It 'emits its message without throwing on a typical call' {
            { Write-Info 'hello' 6>$null } | Should -Not -Throw
        }
        It 'tolerates empty + special-character strings' {
            { Write-Info '' 6>$null } | Should -Not -Throw
            { Write-Info "with `t tabs and `n newlines" 6>$null } | Should -Not -Throw
        }
    }

    Context 'Ensure-Internet — .NET Ping based reachability' {
        It 'returns silently when 8.8.8.8 ping succeeds (dev macOS expected reachable)' {
            # On any dev box with working DNS / public-net access, this
            # is the ground-truth path. Skip on isolated CI runners.
            if ($env:CI -eq 'true') {
                Set-ItResult -Skipped -Because 'CI runners may have egress restrictions'
                return
            }
            { Ensure-Internet } | Should -Not -Throw
        }
    }

    Context 'Get-FileFromWeb — Invoke-WebRequest wrapper with size guard' {
        BeforeEach {
            $script:DownloadTempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dlh-getfile-" + [guid]::NewGuid())
            New-Item -ItemType Directory -Path $script:DownloadTempDir -Force | Out-Null
        }
        AfterEach {
            Remove-Item -LiteralPath $script:DownloadTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'succeeds when the mocked download writes a sufficiently-large file' {
            $target = Join-Path $script:DownloadTempDir 'big.bin'
            Mock Invoke-WebRequest {
                param($Uri, $OutFile, $UseBasicParsing)
                # Write 2KB of payload to satisfy the >1000-byte guard.
                'x' * 2000 | Set-Content -LiteralPath $OutFile -NoNewline
            }
            { Get-FileFromWeb -Url 'https://example.com/big.bin' -File $target 6>$null } |
                Should -Not -Throw
            Test-Path $target | Should -BeTrue
        }

        It 'throws when the downloaded file is missing entirely' {
            $target = Join-Path $script:DownloadTempDir 'missing.bin'
            Mock Invoke-WebRequest { }
            # No file written; the size-guard branch should trigger.
            { Get-FileFromWeb -Url 'https://example.com/x.bin' -File $target 6>$null } |
                Should -Throw '*Download failed or file too small*'
        }

        It 'throws when the downloaded file is smaller than the 1000-byte sanity threshold' {
            $target = Join-Path $script:DownloadTempDir 'tiny.bin'
            Mock Invoke-WebRequest {
                param($Uri, $OutFile, $UseBasicParsing)
                # Only 50 bytes — well under the 1000-byte guard.
                'x' * 50 | Set-Content -LiteralPath $OutFile -NoNewline
            }
            { Get-FileFromWeb -Url 'https://example.com/x.bin' -File $target 6>$null } |
                Should -Throw '*Download failed or file too small*'
        }
    }

    Context 'Test-FileAuthenticode — signer-CN match logic' {

        It 'returns $false when signature status is anything but Valid' {
            Mock Get-AuthenticodeSignature {
                [PSCustomObject]@{ Status = 'NotSigned'; SignerCertificate = $null }
            }
            Test-FileAuthenticode -Path '/tmp/whatever' | Should -BeFalse
        }

        It 'returns $true when signature is Valid and no signer requirement provided' {
            Mock Get-AuthenticodeSignature {
                [PSCustomObject]@{
                    Status = 'Valid'
                    SignerCertificate = [PSCustomObject]@{ Subject = 'CN=Whoever' }
                }
            }
            Test-FileAuthenticode -Path '/tmp/whatever' | Should -BeTrue
        }

        It 'returns $true when signer matches the expected substring' {
            Mock Get-AuthenticodeSignature {
                [PSCustomObject]@{
                    Status = 'Valid'
                    SignerCertificate = [PSCustomObject]@{
                        Subject = 'CN=NVIDIA Corporation, O=NVIDIA, L=Santa Clara'
                    }
                }
            }
            Test-FileAuthenticode -Path '/tmp/nvfile.exe' -ExpectedSignerCN 'NVIDIA Corporation' |
                Should -BeTrue
        }

        It 'returns $false when signer does NOT match the expected substring' {
            Mock Get-AuthenticodeSignature {
                [PSCustomObject]@{
                    Status = 'Valid'
                    SignerCertificate = [PSCustomObject]@{
                        Subject = 'CN=Bogus, Inc.'
                    }
                }
            }
            Test-FileAuthenticode -Path '/tmp/foo.exe' -ExpectedSignerCN 'NVIDIA Corporation' |
                Should -BeFalse
        }
    }
}
