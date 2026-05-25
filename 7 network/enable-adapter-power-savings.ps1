<#
.SYNOPSIS
    Restore per-adapter NIC power-management state from the
    nic-power-before.json sidecar captured by
    disable-adapter-power-savings.ps1.

.DESCRIPTION
    For each adapter in the sidecar, calls
    Set-NetAdapterPowerManagement with the four captured boolean
    settings (DeviceSleepOnDisconnect, SelectiveSuspend,
    WakeOnMagicPacket, WakeOnPattern). Falls back to Windows defaults
    (all four enabled) when the sidecar is missing.

    Each per-adapter Set-NetAdapterPowerManagement call is gated by
    $PSCmdlet.ShouldProcess BEFORE entering UI-Step — keeps the gate
    out of the `& $UIStepAction` ScriptBlock where $PSCmdlet scope
    resolution is unreliable.

.NOTES
    Tier: Safe (restores OS defaults / sidecar baseline)
    Pair: disable-adapter-power-savings.ps1
    Anti-cheat impact: NONE — per-adapter selective-suspend / wake-on
        properties; no game-process scheduling change.
    Reboot required: NO — Set-NetAdapterPowerManagement applies live.
    Disk impact: LOW — reads + deletes the nic-power sidecar JSON.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Restore NIC Power Savings"
UI-Header -Title "Restore NIC Power Savings & Wake" -Subtitle "Per-adapter restore from sidecar"
UI-RequireAdmin -ScriptName "Restore NIC Power Savings"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

if (-not (Get-Command Set-NetAdapterPowerManagement -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[ERROR] NetAdapter cmdlets unavailable." -Color $script:UI_Error
    UI-Exit
    exit 1
}

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\nic-power-before.json"

if (-not (Test-Path $beforePath)) {
    UI-Note -Message "No sidecar at $beforePath — restoring Windows defaults." -Color $script:UI_Warning
    foreach ($a in @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })) {
        # Hoisted ShouldProcess: gate BEFORE entering UI-Step. $PSCmdlet
        # is unreliable inside `& $UIStepAction` (canonical pattern,
        # see mmagent refactor 023a6b0).
        if (-not $PSCmdlet.ShouldProcess($a.Name, "Set-NetAdapterPowerManagement (defaults)")) {
            UI-Skip -Label "Defaults for $($a.Name)" -Reason "-WhatIf preview"
            continue
        }
        UI-Step -Label "Defaults for $($a.Name)" -Action {
            Set-NetAdapterPowerManagement -Name $a.Name `
                -DeviceSleepOnDisconnect Enabled `
                -SelectiveSuspend Enabled `
                -WakeOnMagicPacket Enabled `
                -WakeOnPattern Enabled `
                -ErrorAction SilentlyContinue
        }.GetNewClosure()
    }
} else {
    $snapshot = Get-Content $beforePath -Raw | ConvertFrom-Json
    foreach ($entry in $snapshot) {
        if (-not $PSCmdlet.ShouldProcess($entry.Name, "Set-NetAdapterPowerManagement (sidecar restore)")) {
            UI-Skip -Label "Restoring $($entry.Name)" -Reason "-WhatIf preview"
            continue
        }
        UI-Step -Label "Restoring $($entry.Name)" -Action {
            $params = @{ Name = $entry.Name; ErrorAction = "SilentlyContinue" }
            if ($entry.DeviceSleepOnDisconnect) { $params["DeviceSleepOnDisconnect"] = $entry.DeviceSleepOnDisconnect }
            if ($entry.SelectiveSuspend) { $params["SelectiveSuspend"] = $entry.SelectiveSuspend }
            if ($entry.WakeOnMagicPacket) { $params["WakeOnMagicPacket"] = $entry.WakeOnMagicPacket }
            if ($entry.WakeOnPattern) { $params["WakeOnPattern"] = $entry.WakeOnPattern }
            Set-NetAdapterPowerManagement @params
        }.GetNewClosure()
    }
    Remove-Item $beforePath -Force -ErrorAction SilentlyContinue
}

UI-Summary -DoneMessage "NIC power savings restored"
UI-Exit
