# ============================================================
# Disable IPv6 Binding (IPv4-only operation)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 6 Windows/27 Network IPv4 Only.ps1
#
# TIER: Security Trade-off — disabling IPv6 breaks any application
# that requires IPv6 connectivity (modern Xbox Live multiplayer
# fallbacks, some VPN configurations, certain ISP-side filtering).
# Microsoft explicitly recommends *against* disabling IPv6.
# ============================================================
# What this changes:
#   1. Per-adapter unbind of ms_tcpip6 (Disable-NetAdapterBinding)
#   2. HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\
#      DisabledComponents = 0xFF (disable all IPv6 transitions)
#
# Captures per-adapter binding state to a sidecar JSON. The reg
# value goes through Set-TrackedRegistry so REVERT-EVERYTHING
# can restore from the manifest.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable IPv6 Binding"
UI-Header -Title "Disable IPv6 Binding (IPv4-only)" -Subtitle "Security Trade-off — breaks IPv6-dependent apps"
UI-RequireAdmin -ScriptName "Disable IPv6"
UI-Confirm -Message "This is a Security Trade-off step." -Warnings @(
    "Some games / VPNs / ISPs require IPv6. Test connectivity afterwards.",
    "Microsoft recommends NOT disabling IPv6. Proceed only if you understand the trade-off."
)

if (-not (Get-Command Get-NetAdapterBinding -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[ERROR] NetAdapter cmdlets unavailable." -Color $script:UI_Error
    UI-Exit
    exit 1
}

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$stateRoot = Join-Path $env:ProgramData "Win11GamingToolkit\state"
if (-not (Test-Path $stateRoot)) { New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null }
$beforePath = Join-Path $stateRoot "ipv6-binding-before.json"

$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue)
if (-not (Test-Path $beforePath)) {
    $snapshot = foreach ($a in $adapters) {
        $b = Get-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Name = $a.Name
            Enabled = if ($b) { [bool]$b.Enabled } else { $null }
        }
    }
    $snapshot | ConvertTo-Json | Set-Content -Path $beforePath -Force
    UI-Note -Message "Captured IPv6 binding baseline at $beforePath"
}

UI-Section -Title "Per-adapter unbind"
foreach ($a in $adapters) {
    UI-Step -Label "Unbinding ms_tcpip6 from $($a.Name)" -Action {
        Disable-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -ErrorAction Stop
        Add-ToolkitStepResult -Key "ipv6-binding:$($a.Name)" -Tier "Security Trade-off" -Status "applied" -Reason "ms_tcpip6 unbound"
    }
}

UI-Section -Title "DisabledComponents registry"
UI-Step -Label "Tcpip6 DisabledComponents = 0xFF" -Action {
    Set-ToolkitRegistryValue `
        -Id "reg:Tcpip6DisabledComponents" `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" `
        -Name "DisabledComponents" `
        -Value 0xFF -Type "DWord" `
        -Tier "Security Trade-off" -Step "ipv6-binding"
    Add-ToolkitStepResult -Key "reg:Tcpip6DisabledComponents" -Tier "Security Trade-off" -Status "applied" -Reason "IPv6 disabled at stack level"
}

UI-Summary -DoneMessage "IPv6 disabled" -Details @(
    "Reboot is required for the stack-level change.",
    "Test internet connectivity (ping a known IPv4 host) before relying on this.",
    "If anything network-dependent breaks, run enable-ipv6-binding.ps1 immediately."
) -RevertHint "Run enable-ipv6-binding.ps1 in this folder, or REVERT-EVERYTHING.ps1."
UI-Exit
