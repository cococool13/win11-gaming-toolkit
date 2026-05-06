# ============================================================
# Enable IPv6 Binding — revert path
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores per-adapter ms_tcpip6 bindings from the sidecar JSON
# captured by disable-ipv6-binding.ps1, and removes the
# DisabledComponents registry value via the manifest restore.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Enable IPv6 Binding"
UI-Header -Title "Enable IPv6 Binding" -Subtitle "Restore default IPv6 configuration"
UI-RequireAdmin -ScriptName "Enable IPv6"

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\ipv6-binding-before.json"

UI-Section -Title "Per-adapter rebind"
if (Test-Path $beforePath) {
    $snapshot = Get-Content $beforePath -Raw | ConvertFrom-Json
    foreach ($entry in $snapshot) {
        if ($entry.Enabled -eq $false) {
            UI-Note -Message "Skipping $($entry.Name): was unbound before apply too" -Color $script:UI_Info
            continue
        }
        UI-Step -Label "Re-binding ms_tcpip6 on $($entry.Name)" -Action {
            Enable-NetAdapterBinding -Name $entry.Name -ComponentID ms_tcpip6 -ErrorAction Stop
        }
    }
    Remove-Item $beforePath -Force -ErrorAction SilentlyContinue
} else {
    UI-Note -Message "No sidecar — re-binding ms_tcpip6 on every adapter." -Color $script:UI_Warning
    foreach ($a in @(Get-NetAdapter -ErrorAction SilentlyContinue)) {
        UI-Step -Label "Re-binding $($a.Name)" -Action {
            Enable-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        }
    }
}

UI-Section -Title "DisabledComponents registry"
UI-Step -Label "Restoring Tcpip6 DisabledComponents" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:Tcpip6DisabledComponents")) {
        Remove-ItemProperty `
            -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" `
            -Name "DisabledComponents" -ErrorAction SilentlyContinue
    }
}

UI-Summary -DoneMessage "IPv6 restored" -Details @(
    "Reboot is required for the stack-level change."
)
UI-Exit
