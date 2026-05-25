<#
.SYNOPSIS
    Restore explorer.exe to Windows-default CPU affinity by removing
    the IFEO override written by disable-explorer-affinity.ps1.

.DESCRIPTION
    Tries Restore-ToolkitRegistryValue on both manifest entries first
    (exact-prior-value restore). If neither key is in the manifest,
    removes the CpuPriorityClass + AffinityMask values blindly so
    Explorer goes back to its scheduler-managed default.

.NOTES
    Tier: Safe (restores OS default)
    Pair: disable-explorer-affinity.ps1
    Anti-cheat impact: NONE — restorer for an IFEO registry value
        targeting explorer.exe; no game-process surface.
    Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
    Disk impact: NONE — registry-only write; no on-disk file creation.
    Must be run as Administrator.
#>

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
