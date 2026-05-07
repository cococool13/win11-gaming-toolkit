# ============================================================
# Enable Network Adapter Power Savings & Wake — revert path
# Windows 11 Gaming Optimization Guide
# ============================================================
# Reads the nic-power-before.json sidecar (captured by
# disable-adapter-power-savings.ps1) and restores per-adapter
# power-management state. Falls back to Windows defaults if the
# sidecar is missing.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Restore NIC Power Savings"
UI-Header -Title "Restore NIC Power Savings & Wake" -Subtitle "Per-adapter restore from sidecar"
UI-RequireAdmin -ScriptName "Restore NIC Power Savings"

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
        UI-Step -Label "Defaults for $($a.Name)" -Action {
            Set-NetAdapterPowerManagement -Name $a.Name `
                -DeviceSleepOnDisconnect Enabled `
                -SelectiveSuspend Enabled `
                -WakeOnMagicPacket Enabled `
                -WakeOnPattern Enabled `
                -ErrorAction SilentlyContinue
        }
    }
} else {
    $snapshot = Get-Content $beforePath -Raw | ConvertFrom-Json
    foreach ($entry in $snapshot) {
        UI-Step -Label "Restoring $($entry.Name)" -Action {
            $params = @{ Name = $entry.Name; ErrorAction = "SilentlyContinue" }
            if ($entry.DeviceSleepOnDisconnect) { $params["DeviceSleepOnDisconnect"] = $entry.DeviceSleepOnDisconnect }
            if ($entry.SelectiveSuspend)        { $params["SelectiveSuspend"] = $entry.SelectiveSuspend }
            if ($entry.WakeOnMagicPacket)       { $params["WakeOnMagicPacket"] = $entry.WakeOnMagicPacket }
            if ($entry.WakeOnPattern)           { $params["WakeOnPattern"] = $entry.WakeOnPattern }
            Set-NetAdapterPowerManagement @params
        }
    }
    Remove-Item $beforePath -Force -ErrorAction SilentlyContinue
}

UI-Summary -DoneMessage "NIC power savings restored"
UI-Exit
