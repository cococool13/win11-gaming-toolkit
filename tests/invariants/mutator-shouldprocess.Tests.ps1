#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }
<#
.SYNOPSIS
    Repo-wide invariant: every mutating .ps1 supports -WhatIf via ShouldProcess.

.DESCRIPTION
    Two parts per mutator:
      1. Declares [CmdletBinding(SupportsShouldProcess)] at the script
         or function level
      2. Calls $PSCmdlet.ShouldProcess (or ShouldContinue) somewhere
         in the body — the attribute alone doesn't gate writes

    PSScriptAnalyzer rule PSShouldProcess catches part 2 at the function
    level but only for functions WITH the attribute. This invariant
    operates at the SCRIPT level — catches scripts that mutate via
    inline code or via helpers without ever opening a ShouldProcess
    gate themselves. CLAUDE.md quality bar: "-WhatIf and -Confirm
    work end-to-end on every mutator."

    Acceptable patterns (any of these passes):
      A) Script's param block has [CmdletBinding(SupportsShouldProcess)]
         AND the body calls $PSCmdlet.ShouldProcess directly
      B) Script body delegates to toolkit helpers that already gate via
         their own ShouldProcess (Set-ToolkitRegistryValue,
         Set-ToolkitServiceStartMode, Set-ToolkitDnsServers,
         Save-ToolkitSidecar, Remove-ToolkitSidecar,
         Set-TrackedRegistry, Set-TrackedService) — propagation handles
         the rest. Listed in $HelperBasedMutators so the helper-call
         IS the ShouldProcess plumbing.

    Known exclusions:
      - DduManual.ps1 (standalone DDU stager; runs in Safe Mode where
        ShouldProcess prompts are unsafe — explicit exclusion).
      - Scripts in `4 services/individual/` (.bat siblings; the .ps1s
        here are mobsync-disable/enable which are intentional thin
        wrappers around `sc.exe`).

.NOTES
    # CROSS-PLATFORM-NOTE
    # AST + text-scan; runs anywhere.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot '..' '_common.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'profile/parts/toolkit-aware.ps1')

    # Toolkit helpers that own ShouldProcess themselves. Calling any of
    # these in the script body satisfies the "ShouldProcess fires
    # somewhere in the call chain" contract.
    $script:GatingHelpers = @(
        'Set-ToolkitRegistryValue'
        'Set-ToolkitServiceStartMode'
        'Set-ToolkitDnsServers'
        'Save-ToolkitSidecar'
        'Remove-ToolkitSidecar'
        'Set-TrackedRegistry'
        'Set-TrackedService'
        # APPLY-EVERYTHING.ps1 helpers — already SupportsShouldProcess
        'Run-Step'
    )

    # Acknowledged exclusions — keep this list tight + justified.
    $script:KnownExcluded = @(
        'DduManual.ps1'
        '4 services/individual/mobsync-disable.ps1'
        '4 services/individual/mobsync-enable.ps1'
    )

    # Scripts that don't yet open a ShouldProcess gate. Each entry is
    # one or more raw-native calls (bcdedit, sc.exe, fsutil, etc.) or
    # cmdlets that don't propagate WhatIf. Fix per script in subsequent
    # commits; shrink this list as each lands. DON'T add new entries to
    # silence regressions — fix the script.
    $script:ShouldProcessGaps = @(
        '0 prerequisites/install-runtimes.ps1'
        '5 registry tweaks/individual/configure-mmagent.ps1'
        '5 registry tweaks/individual/enable-windows-update.ps1'
        '5 registry tweaks/individual/revert-mmagent.ps1'
        '5 registry tweaks/individual/uninstall-timer-resolution-service.ps1'
        '7 network/enable-adapter-power-savings.ps1'
        '8 security vs performance/enable-dep.ps1'
        '8 security vs performance/enable-smt-ht.ps1'
        '9 cleanup/cleanup-temp.ps1'
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
            ShouldProcessGap = ($script:ShouldProcessGaps -contains $row.Path)
        }
    }
}

Describe 'Invariant: every mutator supports -WhatIf via ShouldProcess' {

    It '<Path> opens a ShouldProcess gate (own attribute OR delegates to a gating helper)' -ForEach $script:MutatorCases {
        # Gap-tracking pattern (mirrors tests/5-registry-tweaks/individual-tweaks.Tests.ps1).
        # Listed scripts are known gaps — skip with a -Because that points
        # at the gap list so future commits shrink it script-by-script.
        # NEW gaps must be fixed in the script, NOT added here.
        if ($ShouldProcessGap) {
            Set-ItResult -Skipped -Because 'tracked in $ShouldProcessGaps; shrink per-commit'
            return
        }

        # Inline the gating-helpers list: $script: vars set in
        # BeforeDiscovery don't survive into It-body runtime scope.
        # Keep this list in sync with the BeforeDiscovery $GatingHelpers.
        $gatingHelpers = @(
            # Mutating writes — own SP attribute
            'Set-ToolkitRegistryValue'
            'Set-ToolkitServiceStartMode'
            'Set-ToolkitDnsServers'
            'Save-ToolkitSidecar'
            'Remove-ToolkitSidecar'
            'Set-TrackedRegistry'
            'Set-TrackedService'
            'Run-Step'
            # Manifest-restore helpers — internally call Set-Toolkit*
            # or built-in cmdlets (Remove-ItemProperty, etc.) that all
            # respect $WhatIfPreference via PSCmdlet preference chain.
            'Restore-ToolkitRegistryValue'
            'Restore-ToolkitServiceStartMode'
            'Restore-ToolkitDnsServers'
            'Restore-ToolkitDefenderExclusions'
        )

        $content = Get-Content -Raw -LiteralPath $FullPath

        # Path A: script's own param block carries SupportsShouldProcess
        # AND the body actually opens the gate at least once.
        $hasOwnAttr = $content -match '\[CmdletBinding\s*\([^)]*SupportsShouldProcess'
        $callsShouldProcess = $content -match '\$PSCmdlet\.ShouldProcess\b' -or $content -match '\$PSCmdlet\.ShouldContinue\b'
        $ownGate = $hasOwnAttr -and $callsShouldProcess

        # Path B: script delegates to a toolkit helper that gates for it.
        # Any single match suffices; a script can mix-and-match.
        $delegatedGate = $false
        foreach ($h in $gatingHelpers) {
            if ($content -match ([regex]::Escape($h))) {
                $delegatedGate = $true
                break
            }
        }

        ($ownGate -or $delegatedGate) | Should -BeTrue `
            -Because '-WhatIf must propagate to every mutating call — either via own ShouldProcess or a gating helper'
    }
}
