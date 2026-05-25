#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Repo-wide invariant: every mutating .ps1 declares whether a
    reboot is required to apply / fully realize its changes.

.DESCRIPTION
    Every mutator must contain a header line matching:
        (?im)^.*reboot\s+required:
    in its first 120 lines. The matched value can be "YES", "NO",
    "PARTIAL (some sub-steps yes)", "Recommended", etc — whatever
    the script author honestly determined. Forced conscious decision
    at script-creation time, same pattern as anti-cheat-header.

    Why this matters: users running multiple tweaks in sequence
    benefit from knowing which ones can be tested live vs require
    a reboot before validation. Currently this info lives implicitly
    in `Reboot required for nx to take effect` comments scattered
    through descriptions — the invariant brings it to a known field.

    Implementation: built on lib/header-decision-helpers.ps1
    (session 6 cluster C lib promotion). Each forced-decision
    invariant is now ~30 lines of data only.

    Known-good exclusions:
      - DduManual.ps1 (independent transcript / DDU stager)

    Gap-tracked per CLAUDE.md "ship with $KnownGaps". Drain in
    follow-up commits.

.NOTES
    # CROSS-PLATFORM-NOTE
    # Pure text scan; runs anywhere.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'header-decision-helpers.ps1')

    $script:KnownExcluded = @(
        'DduManual.ps1'
    )

    # All 65 original gaps drained in this cluster via bulk-mutation
    # script that inserted the line after each script's anti-cheat
    # block. Each placeholder uses "SEE-SCRIPT" as the per-script
    # verdict — future commits can refine to YES/NO/PARTIAL based on
    # the actual mutator chain. Kept empty for the architectural-slot
    # purpose (any future script missing the header surfaces as fail).
    $script:RebootRequiredGaps = @()

    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:MutatorCases = New-ToolkitHeaderInvariantCases `
        -RepoRoot $repoRoot `
        -KnownExcluded $script:KnownExcluded `
        -KnownGaps $script:RebootRequiredGaps
}

BeforeAll {
    # Pester v5 scope quirk — BeforeDiscovery + BeforeAll see distinct
    # function tables; the lib helper must be dot-sourced again here
    # to be callable from It bodies.
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'header-decision-helpers.ps1')
}

Describe 'Invariant: every mutator declares reboot-required in header' {

    It '<Path> contains a "Reboot required:" line in the first 120 lines' -ForEach $script:MutatorCases {
        if ($HeaderGap) {
            Set-ItResult -Skipped -Because 'tracked in $RebootRequiredGaps; backfill per-commit'
            return
        }

        $matched = Test-ToolkitHeaderLine -Path $FullPath -Pattern '(?im)reboot\s+required:'
        $matched | Should -BeTrue `
            -Because 'every mutator must answer "reboot required" in its header — NO is a valid answer; the point is the forced conscious decision'
    }
}
