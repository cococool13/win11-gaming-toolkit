<#
.SYNOPSIS
    Re-enable Data Execution Prevention (DEP) by restoring the prior
    BCD nx policy captured by disable-dep.ps1.

.DESCRIPTION
    Reads the dep-before.json sidecar (captured by disable-dep.ps1)
    and restores the user's prior `nx` policy. Falls back to nx=OptIn
    (the Windows default for client editions) if the sidecar is
    missing. The bcdedit /set call is gated by $PSCmdlet.ShouldProcess
    so -WhatIf previews the operation without modifying boot config.

.NOTES
    Tier: Safe (restores security default)
    Pair: disable-dep.ps1
    Anti-cheat impact: NONE — restoring DEP (nx=OptIn or whatever
        the user had pre-toolkit) is the OS-default state. Anti-cheat
        layers expect nx to be on; this is the safe direction.
    Reboot required for nx to take effect.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Re-enable DEP"
UI-Header -Title "Re-enable Data Execution Prevention" -Subtitle "Restore prior nx policy"
UI-RequireAdmin -ScriptName "Re-enable DEP"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\dep-before.json"

$nxValue = "OptIn"
if (Test-Path $beforePath) {
    $before = Get-Content $beforePath -Raw | ConvertFrom-Json
    if ($before.nx) { $nxValue = $before.nx }
    UI-Note -Message "Restoring nx=$nxValue from $beforePath"
} else {
    UI-Note -Message "No sidecar — restoring nx=OptIn (Windows client default)." -Color $script:UI_Warning
}

UI-Step -Label "Setting nx=$nxValue" -Action {
    if (-not $PSCmdlet.ShouldProcess("BCD {current} nx", "bcdedit /set nx $nxValue")) {
        return
    }
    $output = bcdedit /set "{current}" nx $nxValue 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "bcdedit failed: $output"
    }
}

if (Test-Path $beforePath) { Remove-Item $beforePath -Force -ErrorAction SilentlyContinue }

UI-Summary -DoneMessage "DEP restored" -Details @(
    "A REBOOT is required for nx changes to take effect."
)
UI-Exit
