# ============================================================
# Restore NTFS Last-Access Timestamp Updates
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores the prior NtfsDisableLastAccessUpdate value captured by
# disable-ntfs-last-access.ps1. If no manifest entry exists, falls
# back to enabling Last Access updates with the Microsoft-documented
# fsutil value 0.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Restore NTFS Last Access"
UI-Header -Title "Restore NTFS Last Access" -Subtitle "Restore access-time behavior"
UI-RequireAdmin -ScriptName "Restore NTFS Last Access"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$fileSystemPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"

UI-Step -Label "Restore NTFS last-access setting" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:NtfsDisableLastAccessUpdate")) {
        New-Item -Path $fileSystemPath -Force | Out-Null
        New-ItemProperty -Path $fileSystemPath -Name "NtfsDisableLastAccessUpdate" -Value 0 -PropertyType DWord -Force | Out-Null
    }
}

UI-Summary -DoneMessage "NTFS last-access setting restored" -Details @(
    "Reboot for the file-system behavior change to take effect."
)
UI-Exit
