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
    . (Join-Path $PSScriptRoot '..' '..' 'profile/parts/toolkit-aware.ps1')

    $script:KnownExcluded = @(
        'DduManual.ps1'
    )

    # ALL 52 ORIGINAL GAPS DRAINED across sessions 5 + 6:
    #   Session 5: 18 obvious-NONE backfilled + power-plan pair (20 total)
    #   Session 6: remaining 32 backfilled (this drain), grouped by
    #     risk class (simple-NONE, GPU vendor, complex security,
    #     orchestrators). Each script's header now carries an
    #     "Anti-cheat impact:" line with per-vendor reasoning where
    #     non-NONE (configure-vbs HIGH, install-timer-resolution
    #     MEDIUM on Vanguard/FACEIT, disable-windows-update INDIRECT-
    #     MEDIUM via missed AC vendor version updates).
    # Kept as empty array (architectural slot) so any future script
    # missing the header surfaces as a gate failure without needing
    # to re-instantiate the data structure.
    $script:AntiCheatGaps = @(
        # No current gaps. Add ONLY if a new script ships without the
        # header AND fixing the script is impractical in the same commit.
        # NEVER expand to absorb a regression — fix the script.
    )

    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $all = Test-ToolkitInvariants -RepoRoot $repoRoot
    $script:MutatorCases = @()
    foreach ($row in $all) {
        if (-not $row.IsMutator) { continue }
        if ($script:KnownExcluded -contains $row.Path) { continue }
        $script:MutatorCases += @{
            Path = $row.Path
            FullPath = (Join-Path $repoRoot $row.Path)
            HeaderGap = ($script:AntiCheatGaps -contains $row.Path)
        }
    }
}

Describe 'Invariant: every mutator declares anti-cheat impact in header' {

    It '<Path> contains an "Anti-cheat impact:" line in the first 120 lines' -ForEach $script:MutatorCases {
        if ($HeaderGap) {
            Set-ItResult -Skipped -Because 'tracked in $AntiCheatGaps; backfill per-commit'
            return
        }

        # Same head-window as Test-ToolkitAdminCheck / Test-ToolkitInvariants
        # — fits well-documented comment-help blocks.
        $head = (Get-Content -LiteralPath $FullPath -TotalCount 120) -join "`n"
        $head | Should -Match '(?im)anti-cheat\s+impact:' `
            -Because 'every mutator must answer "anti-cheat impact" in its header — NONE is a valid answer; the point is the forced conscious decision'
    }
}
