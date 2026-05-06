# ============================================================
# Configure Memory Manager Agent (MMAgent) for Gaming
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/6 MMAgent Features.ps1
#         + 3 Setup/2 Memory Compression.ps1
# ============================================================
# Disables MMAgent features that can cause hitches in games:
#
#   - PageCombining   : background memory dedup, costs CPU + cache
#   - OperationAPI    : telemetry-style API for memory ops
#   - ApplicationPreLaunch : auto-launches recently used apps
#   - MemoryCompression    : compresses pages instead of paging out
#                            (large benefit on low-RAM systems,
#                            measurable hitch source on 32GB+ rigs)
#
# State is captured to a sidecar JSON before apply, so revert can
# restore the exact pre-toolkit state instead of guessing defaults.
# ============================================================

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

UI-Step -Label "Disable PageCombining" -Action {
    Disable-MMAgent -PageCombining -ErrorAction Stop
    Add-ToolkitStepResult -Key "mmagent:PageCombining" -Tier "Advanced" -Status "applied" -Reason "PageCombining disabled"
}
UI-Step -Label "Disable OperationAPI" -Action {
    Disable-MMAgent -OperationAPI -ErrorAction Stop
    Add-ToolkitStepResult -Key "mmagent:OperationAPI" -Tier "Advanced" -Status "applied" -Reason "OperationAPI disabled"
}
UI-Step -Label "Disable ApplicationPreLaunch" -Action {
    Disable-MMAgent -ApplicationPreLaunch -ErrorAction Stop
    Add-ToolkitStepResult -Key "mmagent:ApplicationPreLaunch" -Tier "Advanced" -Status "applied" -Reason "ApplicationPreLaunch disabled"
}
UI-Step -Label "Disable MemoryCompression" -Action {
    Disable-MMAgent -MemoryCompression -ErrorAction Stop
    Add-ToolkitStepResult -Key "mmagent:MemoryCompression" -Tier "Advanced" -Status "applied" -Reason "MemoryCompression disabled"
}

UI-Summary -DoneMessage "MMAgent configured for gaming" -Details @(
    "On 32GB+ systems disabling MemoryCompression usually helps frame pacing.",
    "On 8-16GB systems the trade-off is worse — consider running revert-mmagent.ps1.",
    "Reboot for changes to fully settle."
) -RevertHint "Run revert-mmagent.ps1 in this folder."
UI-Exit
