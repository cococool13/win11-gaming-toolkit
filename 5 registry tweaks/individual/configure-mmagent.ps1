<#
.SYNOPSIS
    Configure MMAgent (Memory Manager Agent) for gaming by disabling
    background memory features that can cause frame hitches.

.DESCRIPTION
    Disables four MMAgent features in order:
      - PageCombining       : background memory dedup
      - OperationAPI        : telemetry-style API for memory ops
      - ApplicationPreLaunch : auto-launches recently used apps
      - MemoryCompression    : compresses pages instead of paging out
                              (helps on low-RAM, hitches 32GB+ rigs)

    Each Disable-MMAgent call is gated by $PSCmdlet.ShouldProcess —
    -WhatIf prints what would be disabled without touching MMAgent.
    State captured to mmagent-before.json sidecar so revert can
    restore exact pre-toolkit state.

.NOTES
    Tier: Advanced
    Pair: revert-mmagent.ps1
    Anti-cheat impact: NONE — MMAgent (Memory Manager Agent) features
        are kernel memory-manager hints (page combining, prelaunch, etc.).
        No documented anti-cheat vendor inspection of MMAgent state;
        BattlEye / EAC / Vanguard care about hooked APIs and DKOM,
        not about whether MemoryCompression is on. Researched: no
        regression reports through 2025 across vendor changelogs.
    Source: FR33THYFR33THY/Ultimate — 8 Advanced/6 MMAgent Features.ps1
            + 3 Setup/2 Memory Compression.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Configure MMAgent for Gaming"
UI-Header -Title "Configure MMAgent for Gaming" -Subtitle "Disable background memory features that can hitch"
UI-RequireAdmin -ScriptName "Configure MMAgent"

if (-not (Get-Command Get-MMAgent -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[ERROR] MMAgent cmdlets are not available on this Windows edition." -Color $script:UI_Error
    UI-Note -Message "Skipping. (Server Core / stripped images do not ship MMAgent.)"
    UI-Exit
    exit 1
}

Initialize-ToolkitState | Out-Null
UI-ResetCounters

# Sidecar capture of current state. Lives next to the manifest so the
# matching revert script can find it without re-discovering paths.
$stateRoot = Join-Path $env:ProgramData "Win11GamingToolkit\state"
if (-not (Test-Path $stateRoot)) {
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
}
$beforePath = Join-Path $stateRoot "mmagent-before.json"
if (-not (Test-Path $beforePath)) {
    $before = Get-MMAgent | Select-Object PageCombining, OperationAPI, ApplicationPreLaunch, MemoryCompression
    $before | ConvertTo-Json | Set-Content -Path $beforePath -Force
    UI-Note -Message "Captured MMAgent baseline at $beforePath"
} else {
    UI-Note -Message "MMAgent baseline already captured (re-run idempotent)" -Color $script:UI_Info
}

# CURSOR-AUDIT #17: pre-check Get-MMAgent flags so re-running this script
# after a successful apply skips features that are already disabled instead
# of letting Disable-MMAgent throw on re-disable.
$mmCurrent = Get-MMAgent

# Per-feature loop. ShouldProcess gate is hoisted OUT of the UI-Step
# action block — relying on closure capture of $PSCmdlet inside `& $Action`
# is fragile across scope chains. Check up-front, only enter UI-Step when
# the operation will actually run.
$mmFeatures = @(
    @{ Name = 'PageCombining'; Current = $mmCurrent.PageCombining }
    @{ Name = 'OperationAPI'; Current = $mmCurrent.OperationAPI }
    @{ Name = 'ApplicationPreLaunch'; Current = $mmCurrent.ApplicationPreLaunch }
    @{ Name = 'MemoryCompression'; Current = $mmCurrent.MemoryCompression }
)
foreach ($f in $mmFeatures) {
    $name = $f.Name
    if (-not $f.Current) {
        UI-Skip -Label "Disable $name" -Reason "Already disabled"
        Add-ToolkitStepResult -Key "mmagent:$name" -Tier "Advanced" -Status "preexisting" -Reason "Already disabled"
        continue
    }
    if (-not $PSCmdlet.ShouldProcess("MMAgent.$name", "Disable-MMAgent")) {
        UI-Skip -Label "Disable $name" -Reason "-WhatIf preview"
        continue
    }
    UI-Step -Label "Disable $name" -Action {
        # Splatting because PowerShell can't bind dynamic switch by name
        # via -$name (parser interprets the dash as subtraction).
        $disableArgs = @{ ErrorAction = 'Stop'; $name = $true }
        Disable-MMAgent @disableArgs
        Add-ToolkitStepResult -Key "mmagent:$name" -Tier "Advanced" -Status "applied" -Reason "$name disabled"
    }.GetNewClosure()
}

UI-Summary -DoneMessage "MMAgent configured for gaming" -Details @(
    "On 32GB+ systems disabling MemoryCompression usually helps frame pacing.",
    "On 8-16GB systems the trade-off is worse — consider running revert-mmagent.ps1.",
    "Reboot for changes to fully settle."
) -RevertHint "Run revert-mmagent.ps1 in this folder."
UI-Exit
