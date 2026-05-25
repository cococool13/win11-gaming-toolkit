# ============================================================
# Restore explorer.exe Default Affinity
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Safe (restores OS default)
#
# Pair with: explorer-affinity-core1.ps1
# Restores explorer.exe to Windows-default CPU affinity by removing
# the Image File Execution Options override values from the manifest
# (or, if not in manifest, removing the values blindly).
#
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title "Restore explorer.exe Default Affinity" -Subtitle "Removes CPU0 pinning"
UI-RequireAdmin -ScriptName "Restore explorer.exe affinity"

Initialize-ToolkitState | Out-Null

$restored = $false
if (Restore-ToolkitRegistryValue -Id "reg:ExplorerCpuPriorityClass") { $restored = $true }
if (Restore-ToolkitRegistryValue -Id "reg:ExplorerAffinityMask") { $restored = $true }

if (-not $restored) {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions"
    if (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name "CpuPriorityClass" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $path -Name "AffinityMask" -ErrorAction SilentlyContinue
    }
}

Add-ToolkitStepResult -Key "explorer-affinity-revert" -Tier "Safe" -Status "applied" `
    -Reason "explorer.exe affinity / priority restored to default"

Write-Host ""
Write-Host "  [DONE] Restart Explorer (or reboot) for the change to take effect." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
