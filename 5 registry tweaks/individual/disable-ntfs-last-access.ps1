# ============================================================
# Disable NTFS Last-Access Timestamp Updates
# Windows 11 Gaming Optimization Guide
# Source:
#   https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior
# ============================================================
# Disables on-disk Last Access timestamp updates for NTFS.
# Microsoft documents this as reducing the impact of access-time
# logging on file and directory access.
#
# Reboot required. Tracked via toolkit-state so the exact previous
# value can be restored by enable-ntfs-last-access.ps1 or full revert.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable NTFS Last Access"
UI-Header -Title "Disable NTFS Last Access" -Subtitle "NtfsDisableLastAccessUpdate = 1"
UI-RequireAdmin -ScriptName "Disable NTFS Last Access"

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$fileSystemPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"

UI-Step -Label "Disable NTFS last-access updates" -Action {
    Set-ToolkitRegistryValue `
        -Id "reg:NtfsDisableLastAccessUpdate" `
        -Path $fileSystemPath `
        -Name "NtfsDisableLastAccessUpdate" `
        -Value 1 -Type "DWord" `
        -Tier "Advanced" -Step "ntfs-last-access"
    Add-ToolkitStepResult -Key "reg:NtfsDisableLastAccessUpdate" -Tier "Advanced" -Status "applied" -Reason "NTFS Last Access updates disabled"
}

UI-Summary -DoneMessage "NTFS last-access updates disabled" -Details @(
    "Reboot for the file-system behavior change to take effect.",
    "Backup, indexing, or audit tools that rely on access time can see stale timestamps."
) -RevertHint "Run enable-ntfs-last-access.ps1 in this folder, or REVERT-EVERYTHING.ps1."
UI-Exit
