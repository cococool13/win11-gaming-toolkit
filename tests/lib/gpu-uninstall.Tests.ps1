#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Behavioral tests for lib/gpu-uninstall.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'gpu-uninstall.ps1')
}

Describe 'lib/gpu-uninstall.ps1' {

    Context 'Get-GpuDriverPublisherPattern — vendor → publisher regex' {
        It 'returns NVIDIA pattern for nvidia' {
            Get-GpuDriverPublisherPattern -Vendor 'nvidia' | Should -Be 'NVIDIA'
        }
        It 'returns AMD pattern that matches both Advanced Micro Devices and bare AMD' {
            $p = Get-GpuDriverPublisherPattern -Vendor 'amd'
            'Advanced Micro Devices, Inc.' | Should -Match $p
            'AMD' | Should -Match $p
            # Mustn't match unrelated vendors with "AMD" in the middle of a word
            'TIAMD Corp' | Should -Not -Match $p
        }
        It 'returns Intel pattern that matches both Intel Corporation and bare Intel' {
            $p = Get-GpuDriverPublisherPattern -Vendor 'intel'
            'Intel Corporation' | Should -Match $p
            'Intel' | Should -Match $p
        }
        It 'rejects unknown vendor at parameter binding time' {
            { Get-GpuDriverPublisherPattern -Vendor 'matrox' } | Should -Throw
        }
    }

    Context 'Get-InstalledGpuDriverPackages — cross-platform safety' {
        It 'returns empty array on non-Windows (pnputil unavailable)' {
            # On macOS / Linux pnputil does not exist; the helper must
            # not throw and must return @() so callers can foreach
            # without a $null check.
            if ($IsWindows) {
                Set-ItResult -Skipped -Because 'pnputil IS available on Windows; behavior verified at runtime'
                return
            }
            $result = Get-InstalledGpuDriverPackages -Vendor 'nvidia'
            # Avoid `$result | Should -BeOfType` — Pester unwraps the
            # array through the pipeline so the empty case looks like
            # $null. Asserting .Count is robust (single-element array
            # exposes Count; bare scalar doesn't).
            (, $result).Count | Should -Be 1  # outer array of 1 element (the inner array)
            $result.Count | Should -Be 0
        }
    }

    Context 'Uninstall-GpuDriverByPublisher — shape contract' {
        It 'always returns a hashtable with Removed/Packages/Failed keys' {
            # On non-Windows (or a Windows box with no matching driver),
            # the result is the empty form. Either way the shape is
            # stable so callers can index without null guards.
            $result = Uninstall-GpuDriverByPublisher -Vendor 'nvidia' -WhatIf
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'Removed'
            $result.Keys | Should -Contain 'Packages'
            $result.Keys | Should -Contain 'Failed'
            $result.Removed | Should -Be 0
        }
        It 'supports ShouldProcess (declares the attribute)' {
            $cmd = Get-Command Uninstall-GpuDriverByPublisher
            $cmd.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $cmd.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }
    }
}
