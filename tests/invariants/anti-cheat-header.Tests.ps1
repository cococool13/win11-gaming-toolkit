#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Repo-wide invariant: every mutating .ps1 declares its anti-cheat
    impact in the header.

.DESCRIPTION
    Every mutator must contain a header line matching:
        (?im)^.*anti-cheat\s+impact:
    in its first 120 lines (the standard CLAUDE.md help-block window).

    The matched value can be "NONE", "Low (...)", "Medium (...)",
    "High (...)" — whatever the script author honestly determined.
    The point isn't the answer; it's the forced-conscious-decision.
    A user reading a header sees the anti-cheat verdict directly
    instead of having to guess from "well, it disables LSA-PPL, so
    probably yes?". Authors writing a new script must answer the
    question explicitly instead of leaving it implied.

    Implementation: AST-light text scan of the first 120 lines of
    each mutator script. Gap-tracked per CLAUDE.md's "invariants
    ship with $KnownGaps" rule. Drain as scripts get the line
    backfilled in subsequent commits.

    Known-good exclusions:
      - DduManual.ps1 — DDU itself is a third-party stager; anti-
        cheat impact is "depends on what DDU removes" which is the
        wrapper's caller's concern, documented in DduAuto.ps1 header.

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

    # ALL 52 ORIGINAL GAPS DRAINED across sessions 5 + 6.
    # Kept as empty array (architectural slot) so any future script
    # missing the header surfaces as a gate failure without needing
    # to re-instantiate the data structure.
    $script:AntiCheatGaps = @(
        # No current gaps. Add ONLY if a new script ships without the
        # header AND fixing the script is impractical in the same commit.
        # NEVER expand to absorb a regression — fix the script.
    )

    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:MutatorCases = New-ToolkitHeaderInvariantCases `
        -RepoRoot $repoRoot `
        -KnownExcluded $script:KnownExcluded `
        -KnownGaps $script:AntiCheatGaps
}

BeforeAll {
    # Dot-source again at It-body scope. Pester v5 runs BeforeDiscovery
    # in a separate scope from the actual It blocks, so functions
    # discovered there aren't visible to the test bodies.
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'header-decision-helpers.ps1')
}

Describe 'Invariant: every mutator declares anti-cheat impact in header' {

    It '<Path> contains an "Anti-cheat impact:" line in the first 120 lines' -ForEach $script:MutatorCases {
        if ($HeaderGap) {
            Set-ItResult -Skipped -Because 'tracked in $AntiCheatGaps; backfill per-commit'
            return
        }

        $matched = Test-ToolkitHeaderLine -Path $FullPath -Pattern '(?im)anti-cheat\s+impact:'
        $matched | Should -BeTrue `
            -Because 'every mutator must answer "anti-cheat impact" in its header — NONE is a valid answer; the point is the forced conscious decision'
    }
}
