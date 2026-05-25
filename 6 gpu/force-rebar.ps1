# ============================================================
# Force Resizable BAR (ReBAR) for Discrete GPUs
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/7 ReBar Force.ps1
# Copyright FR33THY (MIT)
# ============================================================
# Tier: Advanced
#
# Forces Resizable BAR exposure to the OS even on combos where the
# motherboard / firmware enumerated it as off. Real perf win on
# supported titles (Intel Arc requires it; NVIDIA 30/40-series and
# AMD RDNA2+ gain 5-15% in some titles).
#
# REQUIREMENTS the script cannot check itself:
#   - BIOS must have Above 4G Decoding ENABLED
#   - BIOS must have CSM DISABLED (UEFI boot only)
#   - GPU must support ReBAR in its silicon (RTX 30+, RX 6000+, Arc)
#   - System RAM must allow it (most do)
#
# If the script-side writes go in but ReBAR doesn't show as enabled
# in nvidia-smi / GPU-Z, the firmware-side requirements above aren't
# met. Toggle them in BIOS, reboot, re-verify.
#
# Implementation: writes Display Class > 0000 (and adapter-resolved
# subkeys) HwUMAEnable=1. Manifest-tracked for revert.
#
# Must be run as Administrator. Pair: disable-rebar.ps1.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"

UI-Header -Title "Force Resizable BAR (ReBAR)" -Subtitle "Real perf win when firmware allows"
UI-RequireAdmin -ScriptName "Force ReBAR"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$gpus = @(Get-GpuVendor | Where-Object { $_.Vendor -in @("nvidia", "amd", "intel") })
if ($gpus.Count -eq 0) {
    UI-Note -Message "[SKIP] No supported discrete GPU detected." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-rebar" -Tier "Advanced" -Status "skipped" -Reason "No supported GPU"
    UI-Exit
    exit 0
}

$applied = $false
foreach ($gpu in $gpus) {
    if (-not $gpu.AdapterRegistryPath) {
        UI-Skip -Label "ReBAR for $($gpu.FriendlyName)" -Reason "Adapter registry path could not be resolved"
        continue
    }
    UI-Step -Label "HwUMAEnable = 1 on $($gpu.FriendlyName)" -Action {
        Set-ToolkitRegistryValue `
            -Id "reg:GpuHwUMAEnable:$($gpu.DeviceId)" `
            -Path $gpu.AdapterRegistryPath `
            -Name "HwUMAEnable" `
            -Value 1 -Type "DWord" `
            -Tier "Advanced" -Step "gpu-rebar"
        $script:RebarApplied = $true
    }
    $applied = $true
}

if ($applied) {
    $status = if ($script:UI_Failed -eq 0) { "applied" } else { "failed" }
    Add-ToolkitStepResult -Key "gpu-rebar" -Tier "Advanced" -Status $status -Reason "HwUMAEnable forced on discrete GPUs"
}

UI-Summary -DoneMessage "ReBAR forced" -Details @(
    "Reboot for the driver to renegotiate BAR sizes.",
    "Verify with GPU-Z 'Resizable BAR' field or nvidia-smi -q | grep BAR1.",
    "If still disabled: BIOS Above 4G Decoding ON + CSM OFF, then re-verify."
) -RevertHint "Run disable-rebar.ps1 (or REVERT-EVERYTHING.ps1)."
UI-Exit
