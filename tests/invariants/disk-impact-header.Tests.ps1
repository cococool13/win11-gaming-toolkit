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

    # Gap-tracking — 65 pre-existing scripts. Drain in subsequent
    # commits within Cluster C. NEVER add to absorb a regression.
    $script:DiskImpactGaps = @(
        '0 prerequisites/install-runtimes.ps1'
        '2 power plan/configure-power.ps1'
        '2 power plan/revert-power.ps1'
        '4 services/disable-services.ps1'
        '4 services/enable-services.ps1'
        '4 services/individual/mobsync-disable.ps1'
        '4 services/individual/mobsync-enable.ps1'
        '5 registry tweaks/individual/configure-mmagent.ps1'
        '5 registry tweaks/individual/disable-allow-telemetry.ps1'
        '5 registry tweaks/individual/disable-ceip.ps1'
        '5 registry tweaks/individual/disable-diagtrack.ps1'
        '5 registry tweaks/individual/disable-edge-background.ps1'
        '5 registry tweaks/individual/disable-explorer-affinity.ps1'
        '5 registry tweaks/individual/disable-hags.ps1'
        '5 registry tweaks/individual/disable-mpo.ps1'
        '5 registry tweaks/individual/disable-ntfs-last-access.ps1'
        '5 registry tweaks/individual/disable-spectre-meltdown.ps1'
        '5 registry tweaks/individual/disable-storage-sense.ps1'
        '5 registry tweaks/individual/disable-windows-update.ps1'
        '5 registry tweaks/individual/disable-write-cache-flush.ps1'
        '5 registry tweaks/individual/enable-allow-telemetry.ps1'
        '5 registry tweaks/individual/enable-ceip.ps1'
        '5 registry tweaks/individual/enable-diagtrack.ps1'
        '5 registry tweaks/individual/enable-edge-background.ps1'
        '5 registry tweaks/individual/enable-explorer-affinity.ps1'
        '5 registry tweaks/individual/enable-hags.ps1'
        '5 registry tweaks/individual/enable-mpo.ps1'
        '5 registry tweaks/individual/enable-ntfs-last-access.ps1'
        '5 registry tweaks/individual/enable-spectre-meltdown.ps1'
        '5 registry tweaks/individual/enable-storage-sense.ps1'
        '5 registry tweaks/individual/enable-windows-update.ps1'
        '5 registry tweaks/individual/enable-write-cache-flush.ps1'
        '5 registry tweaks/individual/install-timer-resolution-service.ps1'
        '5 registry tweaks/individual/pause-windows-update.ps1'
        '5 registry tweaks/individual/resume-windows-update.ps1'
        '5 registry tweaks/individual/revert-mmagent.ps1'
        '5 registry tweaks/individual/tune-mmcss-audio.ps1'
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
        '7 network/disable-doh.ps1'
        '7 network/disable-interrupt-moderation.ps1'
        '7 network/disable-ipv6-binding.ps1'
        '7 network/disable-rss-tuning.ps1'
        '7 network/enable-adapter-power-savings.ps1'
        '7 network/enable-doh.ps1'
        '7 network/enable-interrupt-moderation.ps1'
        '7 network/enable-ipv6-binding.ps1'
        '7 network/enable-rss-tuning.ps1'
        '7 network/optimize-network.ps1'
        '8 security vs performance/configure-vbs.ps1'
        '8 security vs performance/disable-defender-wholesale.ps1'
        '8 security vs performance/enable-defender-wholesale.ps1'
        '8 security vs performance/enable-dep.ps1'
        '8 security vs performance/enable-smt-ht.ps1'
        '9 cleanup/cleanup-temp.ps1'
        'APPLY-EVERYTHING.ps1'
        'REVERT-EVERYTHING.ps1'
    )

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
