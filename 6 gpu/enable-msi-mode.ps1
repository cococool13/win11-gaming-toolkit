# ============================================================
# Enable MSI Mode for Detected GPUs
# Windows 11 Gaming Optimization Guide
# ============================================================
# Enables Message Signaled Interrupts (MSI) for real GPUs only.
# Filters out Microsoft Basic Display Adapter, Hyper-V, and
# virtual displays (Parsec, OBS Virtual Cam, IDD drivers).
#
# Vendor match: VEN_10DE (NVIDIA), VEN_1002 (AMD), VEN_8086 (Intel).
#
# Tracked via Set-TrackedRegistry so REVERT-EVERYTHING can restore
# the prior MSI mode state from the manifest.
#
# Optional: -IncludeStorage also enables MSI on the primary NVMe
# controller. Off by default; opt-in.
# ============================================================

param([switch]$IncludeStorage)

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"

$Host.UI.RawUI.WindowTitle = "Enable MSI Mode for GPUs"
UI-Header -Title "Enable MSI Mode for GPUs" -Subtitle "Lower interrupt latency for real display devices only"
UI-RequireAdmin -ScriptName "Enable MSI Mode"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$gpuDevices = @(Get-GpuVendor)
if ($gpuDevices.Count -eq 0) {
    UI-Note -Message "[SKIP] No NVIDIA / AMD / Intel display devices found." -Color $script:UI_Warning
    Add-ToolkitStepResult -Key "gpu-msi" -Tier "Advanced" -Status "skipped" -Reason "No real GPUs detected"
    UI-Exit
    exit 0
}

UI-Section -Title "Detected real GPUs"
foreach ($gpu in $gpuDevices) {
    UI-Note -Message ("  {0}  ({1}, VEN_{2})" -f $gpu.FriendlyName, $gpu.Vendor.ToUpper(), $gpu.DeviceId)
}

UI-Section -Title "Applying MSI mode"
foreach ($gpu in $gpuDevices) {
    UI-Step -Label "MSI mode for $($gpu.FriendlyName)" -Action {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpu.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        Set-ToolkitRegistryValue `
            -Id "gpu-msi:$($gpu.InstanceId)" `
            -Path $regPath `
            -Name "MSISupported" `
            -Value 1 -Type "DWord" `
            -Tier "Advanced" -Step "gpu-msi"
        Add-ToolkitStepResult -Key "gpu-msi:$($gpu.InstanceId)" -Tier "Advanced" -Status "applied" -Reason "MSI mode enabled"
    }
}

if ($IncludeStorage) {
    UI-Section -Title "Storage MSI extension (-IncludeStorage)"
    $nvmeDevices = @(Get-PnpDevice -Class SCSIAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -match "PCI\\VEN_" -and $_.FriendlyName -match "NVMe" -and $_.Status -eq "OK" })
    if ($nvmeDevices.Count -eq 0) {
        UI-Skip -Label "NVMe MSI" -Reason "No NVMe controller detected"
    } else {
        foreach ($nvme in $nvmeDevices) {
            UI-Step -Label "MSI mode for $($nvme.FriendlyName)" -Action {
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($nvme.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
                Set-ToolkitRegistryValue `
                    -Id "gpu-msi:$($nvme.InstanceId)" `
                    -Path $regPath `
                    -Name "MSISupported" `
                    -Value 1 -Type "DWord" `
                    -Tier "Advanced" -Step "gpu-msi"
                Add-ToolkitStepResult -Key "gpu-msi:$($nvme.InstanceId)" -Tier "Advanced" -Status "applied" -Reason "NVMe MSI mode enabled"
            }
        }
    }
}

UI-Summary -DoneMessage "MSI mode applied" -Details @(
    "A reboot is required for the change to take effect.",
    "Verify after reboot: Device Manager > Display Adapters > GPU > Properties > Resources > Message Signaled."
) -RevertHint "Run REVERT-EVERYTHING.ps1 to restore the prior MSI mode state."
UI-Exit
