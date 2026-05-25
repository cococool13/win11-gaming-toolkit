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

    # Gap-tracking. 53 pre-existing scripts need the header backfill;
    # drain in subsequent commits per the CLAUDE.md "shrink, don't
    # silence" rule. NEW scripts must include the header at creation
    # time — never add to this list to absorb a new regression.
    #
    # Each entry is a script that doesn't currently declare anti-cheat
    # impact. Listed alphabetically by Path so diffs stay clean.
    $script:AntiCheatGaps = @(
        # First-batch drain landed (this commit) — 18 obvious-NONE
        # scripts backfilled. Remaining entries are either:
        #   (a) genuinely require careful anti-cheat assessment
        #       (Spectre/HVCI/VBS/Defender/timer-resolution/SMT)
        #   (b) orchestrators where the impact is the union of bundled
        #       phases (APPLY-EVERYTHING, REVERT-EVERYTHING)
        #   (c) GPU driver installers — review pending vendor docs
        # Drain per-commit as each is reviewed.

        '0 prerequisites/install-runtimes.ps1'
        '2 power plan/configure-power.ps1'
        '2 power plan/revert-power.ps1'
        '4 services/disable-services.ps1'
        '4 services/enable-services.ps1'
        '4 services/individual/mobsync-disable.ps1'
        '4 services/individual/mobsync-enable.ps1'
        '5 registry tweaks/individual/configure-mmagent.ps1'
        '5 registry tweaks/individual/disable-explorer-affinity.ps1'
        '5 registry tweaks/individual/disable-spectre-meltdown.ps1'
        '5 registry tweaks/individual/disable-windows-update.ps1'
        '5 registry tweaks/individual/enable-explorer-affinity.ps1'
        '5 registry tweaks/individual/enable-spectre-meltdown.ps1'
        '5 registry tweaks/individual/enable-windows-update.ps1'
        '5 registry tweaks/individual/install-timer-resolution-service.ps1'
        '5 registry tweaks/individual/revert-mmagent.ps1'
        '5 registry tweaks/individual/uninstall-timer-resolution-service.ps1'
        '6 gpu/amd/configure-amd.ps1'
        '6 gpu/amd/install-amd.ps1'
        '6 gpu/configure-amd-ulps.ps1'
        '6 gpu/enable-msi-mode.ps1'
        '6 gpu/force-rebar.ps1'
        '6 gpu/intel/configure-intel.ps1'
        '6 gpu/intel/install-intel.ps1'
        '6 gpu/nvidia/configure-nvidia.ps1'
        '6 gpu/nvidia/force-p0-state.ps1'
        '6 gpu/nvidia/install-nvidia.ps1'
        '8 security vs performance/configure-vbs.ps1'
        '8 security vs performance/disable-defender-wholesale.ps1'
        '8 security vs performance/enable-defender-wholesale.ps1'
        '8 security vs performance/enable-dep.ps1'
        '8 security vs performance/enable-smt-ht.ps1'
        'APPLY-EVERYTHING.ps1'
        'REVERT-EVERYTHING.ps1'
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
