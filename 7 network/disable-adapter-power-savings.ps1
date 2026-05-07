# ============================================================
# Disable Network Adapter Power Savings & Wake-on-LAN
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 6 Windows/26 Network Adapter Power Savings & Wake.ps1
# ============================================================
# For each Up adapter, disables:
#   - Selective suspend           (USB / PCIe NIC sleep)
#   - DeviceSleepOnDisconnect     (drops link state on idle)
#   - Wake on Magic Packet / Pattern  (Wake-on-LAN)
#
# These are common micro-stutter sources on 1G+ Ethernet under
# light load and can wake the system unexpectedly from sleep.
#
# Captures the prior state to a sidecar JSON so the matching
# enable script restores exactly what the user had before.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable NIC Power Savings"
UI-Header -Title "Disable NIC Power Savings & Wake" -Subtitle "Per-adapter selective-suspend + WoL off"
UI-RequireAdmin -ScriptName "Disable NIC Power Savings"

if (-not (Get-Command Get-NetAdapterPowerManagement -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[ERROR] NetAdapter cmdlets unavailable on this Windows edition." -Color $script:UI_Error
    UI-Exit
    exit 1
}

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$stateRoot = Join-Path $env:ProgramData "Win11GamingToolkit\state"
if (-not (Test-Path $stateRoot)) {
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
}
$beforePath = Join-Path $stateRoot "nic-power-before.json"

$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
if ($adapters.Count -eq 0) {
    UI-Note -Message "[SKIP] No Up adapters found." -Color $script:UI_Warning
    UI-Exit
    exit 0
}

if (-not (Test-Path $beforePath)) {
    $beforeSnapshot = @()
    foreach ($a in $adapters) {
        $pm = Get-NetAdapterPowerManagement -Name $a.Name -ErrorAction SilentlyContinue
        $beforeSnapshot += [PSCustomObject]@{
            Name = $a.Name
            DeviceSleepOnDisconnect = if ($pm) { [string]$pm.DeviceSleepOnDisconnect } else { $null }
            SelectiveSuspend = if ($pm) { [string]$pm.SelectiveSuspend } else { $null }
            WakeOnMagicPacket = if ($pm) { [string]$pm.WakeOnMagicPacket } else { $null }
            WakeOnPattern = if ($pm) { [string]$pm.WakeOnPattern } else { $null }
        }
    }
    $beforeSnapshot | ConvertTo-Json | Set-Content -Path $beforePath -Force
    UI-Note -Message "Captured NIC baseline at $beforePath"
}

UI-Section -Title "Applying"
foreach ($a in $adapters) {
    UI-Step -Label "Tuning $($a.Name)" -Action {
        Set-NetAdapterPowerManagement -Name $a.Name `
            -DeviceSleepOnDisconnect Disabled `
            -SelectiveSuspend Disabled `
            -WakeOnMagicPacket Disabled `
            -WakeOnPattern Disabled `
            -ErrorAction Stop
        Add-ToolkitStepResult -Key "nic-power:$($a.Name)" -Tier "Advanced" -Status "applied" -Reason "Power-savings + WoL disabled"
    }
}

UI-Summary -DoneMessage "NIC power savings disabled" -Details @(
    "Reboot recommended for the change to fully settle.",
    "Wake-on-LAN is now off — your PC will not wake from network packets."
) -RevertHint "Run enable-adapter-power-savings.ps1 in this folder."
UI-Exit
