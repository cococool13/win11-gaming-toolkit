<#
.SYNOPSIS
    Revert MMAgent (Memory Manager Agent) to the pre-toolkit state
    captured by configure-mmagent.ps1.

.DESCRIPTION
    Reads the mmagent-before.json sidecar and re-enables exactly the
    features that were on at apply time. Falls back to Windows defaults
    (all features enabled) when the sidecar is missing. Each
    Enable/Disable-MMAgent call is gated by $PSCmdlet.ShouldProcess
    so -WhatIf previews the operation without modifying MMAgent.

.NOTES
    Tier: Safe (restores prior state)
    Pair: configure-mmagent.ps1
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Revert MMAgent"
UI-Header -Title "Revert MMAgent" -Subtitle "Restore MMAgent baseline"
UI-RequireAdmin -ScriptName "Revert MMAgent"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

if (-not (Get-Command Set-MMAgent -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[ERROR] MMAgent cmdlets are not available on this Windows edition." -Color $script:UI_Error
    UI-Exit
    exit 1
}

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\mmagent-before.json"

$before = $null
if (Test-Path $beforePath) {
    $before = Get-Content $beforePath -Raw | ConvertFrom-Json
    UI-Note -Message "Restoring MMAgent from $beforePath"
} else {
    UI-Note -Message "No baseline sidecar found. Restoring Windows defaults (all features on)." -Color $script:UI_Warning
    $before = [PSCustomObject]@{
        PageCombining = $true
        OperationAPI = $true
        ApplicationPreLaunch = $true
        MemoryCompression = $true
    }
}

# Per-feature loop. ShouldProcess gate hoisted OUT of the UI-Step
# action block (same reason as configure-mmagent.ps1 — $PSCmdlet
# closure capture inside `& $Action` is fragile).
$mmFeatures = @('PageCombining', 'OperationAPI', 'ApplicationPreLaunch', 'MemoryCompression')
foreach ($name in $mmFeatures) {
    $shouldEnable = [bool]$before.$name
    $verb = if ($shouldEnable) { 'Enable' } else { 'Disable' }
    if (-not $PSCmdlet.ShouldProcess("MMAgent.$name", "$verb-MMAgent")) {
        UI-Skip -Label "$name = $shouldEnable" -Reason "-WhatIf preview"
        continue
    }
    UI-Step -Label "$name = $shouldEnable" -Action {
        # Splatting because PowerShell can't bind dynamic switch by name
        # via -$name (parser interprets the dash as subtraction).
        $cmdletArgs = @{ ErrorAction = 'Stop'; $name = $true }
        if ($shouldEnable) {
            Enable-MMAgent @cmdletArgs
        } else {
            Disable-MMAgent @cmdletArgs
        }
    }.GetNewClosure()
}

# Once restored, drop the sidecar so a future apply re-captures fresh state.
if (Test-Path $beforePath) {
    Remove-Item $beforePath -Force -ErrorAction SilentlyContinue
}

UI-Summary -DoneMessage "MMAgent reverted" -Details @(
    "Reboot for changes to fully settle."
)
UI-Exit
