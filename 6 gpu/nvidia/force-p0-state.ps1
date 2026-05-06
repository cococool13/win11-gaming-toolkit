# ============================================================
# Force NVIDIA GPU P0 Power State
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 5 Graphics/8 P0 State.ps1
# ============================================================
# Pegs the NVIDIA GPU at its highest performance state by setting
# PerfLevelSrc and DisableDynamicPstate under the adapter's class
# subkey. Useful for benchmark consistency. Costs idle power and
# heat — the GPU never downclocks.
#
# Vendor-gated: only runs if Get-GpuVendor reports an NVIDIA GPU.
# Path is resolved dynamically (no hardcoded \0000 / \0001) via
# Get-GpuAdapterRegistryPath, matching by FriendlyName.
#
# NOTE: For most users, NVIDIA Control Panel > Manage 3D settings
# > Power management mode = "Prefer maximum performance" achieves
# the same effect with less risk. This script is the registry
# equivalent for systems where you cannot use NVCP (Server, IoT,
# debloated images).
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"
. "$PSScriptRoot\..\..\lib\gpu-detection.ps1"

$Host.UI.RawUI.WindowTitle = "Force NVIDIA GPU P0 State"
UI-Header -Title "Force NVIDIA GPU P0 Power State" -Subtitle "Pegged max-performance — costs idle power"
UI-RequireAdmin -ScriptName "Force NVIDIA P0 State"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$nvidiaGpus = @(Get-GpuVendor | Where-Object { $_.Vendor -eq "nvidia" })
if ($nvidiaGpus.Count -eq 0) {
    UI-Note -Message "[SKIP] No NVIDIA GPU detected." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-p0-state" -Tier "Advanced" -Status "skipped" -Reason "No NVIDIA GPU"
    UI-Exit
    exit 0
}

$script:NvidiaP0Applied = $false
foreach ($gpu in $nvidiaGpus) {
    if (-not $gpu.AdapterRegistryPath) {
        UI-Skip -Label "P0 for $($gpu.FriendlyName)" -Reason "Adapter registry path could not be resolved"
        continue
    }

    UI-Step -Label "PerfLevelSrc on $($gpu.FriendlyName)" -Action {
        Set-ToolkitRegistryValue `
            -Id "reg:NvPerfLevelSrc:$($gpu.DeviceId)" `
            -Path $gpu.AdapterRegistryPath `
            -Name "PerfLevelSrc" `
            -Value 0x2222 -Type "DWord" `
            -Tier "Advanced" -Step "gpu-p0-state"
        $script:NvidiaP0Applied = $true
    }

    UI-Step -Label "DisableDynamicPstate on $($gpu.FriendlyName)" -Action {
        Set-ToolkitRegistryValue `
            -Id "reg:NvDisableDynamicPstate:$($gpu.DeviceId)" `
            -Path $gpu.AdapterRegistryPath `
            -Name "DisableDynamicPstate" `
            -Value 1 -Type "DWord" `
            -Tier "Advanced" -Step "gpu-p0-state"
        $script:NvidiaP0Applied = $true
    }
}

if ($script:NvidiaP0Applied) {
    $status = if ($script:UI_Failed -eq 0) { "applied" } else { "failed" }
    Add-ToolkitStepResult -Key "gpu-p0-state" -Tier "Advanced" -Status $status -Reason "NVIDIA P0 state registry keys"
}

UI-Summary -DoneMessage "P0 state forced" -Details @(
    "Reboot for the driver to pick up the new keys.",
    "Idle GPU power and temps will rise — this is by design."
) -RevertHint "REVERT-EVERYTHING.ps1 will restore from manifest."
UI-Exit
