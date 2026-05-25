#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Repo-wide invariant: every mutating .ps1 that writes files,
    registry, or installs software declares its disk-impact in the
    header.

.DESCRIPTION
    Every mutator must contain a header line matching:
        (?im)^.*disk\s+impact:
    in its first 120 lines. The matched value names the disk scope:
      - NONE     (registry-only mutation, no on-disk file changes)
      - LOW      (small files: log lines, sidecar JSON)
      - MEDIUM   (single installer download / extract, ~10-200 MB)
      - HIGH     (driver install, ISO extract, full debloat, > 1 GB)

    Forced conscious decision at script-creation time, same pattern
    as anti-cheat-header + reboot-required-header. The user reading a
    script header knows up-front whether to expect disk churn —
    important on low-storage systems (handheld gaming PCs, Steam Decks
    running Win11, laptops with small primary SSDs).

    Implementation: built on lib/header-decision-helpers.ps1.

    Known-good exclusions:
      - DduManual.ps1 (DDU stager; its impact is "what DDU writes",
        documented in DduAuto.ps1)

    Gap-tracked per CLAUDE.md "ship with $KnownGaps".

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
    # script. Future scripts missing the header trip the gate; never
    # add to absorb a regression.
    $script:DiskImpactGaps = @()

    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:MutatorCases = New-ToolkitHeaderInvariantCases `
        -RepoRoot $repoRoot `
        -KnownExcluded $script:KnownExcluded `
        -KnownGaps $script:DiskImpactGaps
}

BeforeAll {
    # Pester v5 scope quirk — see anti-cheat-header.Tests.ps1.
    . (Join-Path $PSScriptRoot '..' '..' 'lib' 'header-decision-helpers.ps1')
}

Describe 'Invariant: every mutator declares disk-impact in header' {

    It '<Path> contains a "Disk impact:" line in the first 120 lines' -ForEach $script:MutatorCases {
        if ($HeaderGap) {
            Set-ItResult -Skipped -Because 'tracked in $DiskImpactGaps; backfill per-commit'
            return
        }

        $matched = Test-ToolkitHeaderLine -Path $FullPath -Pattern '(?im)disk\s+impact:'
        $matched | Should -BeTrue `
            -Because 'every mutator must answer "disk impact" in its header — NONE is a valid answer; the point is the forced conscious decision'
    }
}
