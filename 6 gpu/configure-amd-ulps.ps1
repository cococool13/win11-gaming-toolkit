# ============================================================
# Disable AMD ULPS (Ultra Low Power State)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/14 Ulps.ps1
# ============================================================
# ULPS lets the inactive AMD GPU on multi-GPU systems enter a
# very low-power state, but the wake transition can cause hitches
# in games. Disabling ULPS is the standard recommendation for
# multi-GPU AMD setups.
#
# Vendor-gated to AMD only. On single-GPU systems this is a
# no-op anyway — but we still write EnableUlps=0 because some
# drivers leave it stuck on after a multi-GPU → single-GPU
# system change.
#
# Tracked via Set-TrackedRegistry on the resolved adapter path.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"

$Host.UI.RawUI.WindowTitle = "Disable AMD ULPS"
UI-Header -Title "Disable AMD ULPS" -Subtitle "Multi-GPU power-saving disable"
UI-RequireAdmin -ScriptName "Disable AMD ULPS"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$amdGpus = @(Get-GpuVendor | Where-Object { $_.Vendor -eq "amd" })
if ($amdGpus.Count -eq 0) {
    UI-Note -Message "[SKIP] No AMD GPU detected." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-amd-ulps" -Tier "Advanced" -Status "skipped" -Reason "No AMD GPU"
    UI-Exit
    exit 0
}

$script:AmdUlpsApplied = $false
foreach ($gpu in $amdGpus) {
    if (-not $gpu.AdapterRegistryPath) {
        UI-Skip -Label "ULPS off for $($gpu.FriendlyName)" -Reason "Adapter registry path could not be resolved"
        continue
    }
    UI-Step -Label "EnableUlps = 0 on $($gpu.FriendlyName)" -Action {
        Set-ToolkitRegistryValue `
            -Id "reg:AmdEnableUlps:$($gpu.DeviceId)" `
            -Path $gpu.AdapterRegistryPath `
            -Name "EnableUlps" `
            -Value 0 -Type "DWord" `
            -Tier "Advanced" -Step "gpu-amd-ulps"
        $script:AmdUlpsApplied = $true
    }
}

if ($script:AmdUlpsApplied) {
    $status = if ($script:UI_Failed -eq 0) { "applied" } else { "failed" }
    Add-ToolkitStepResult -Key "gpu-amd-ulps" -Tier "Advanced" -Status $status -Reason "AMD ULPS disabled"
}

UI-Summary -DoneMessage "AMD ULPS disabled" -Details @(
    "Reboot for the driver to pick up the change."
) -RevertHint "REVERT-EVERYTHING.ps1 will restore from manifest."
UI-Exit
