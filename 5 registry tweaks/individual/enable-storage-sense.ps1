<#
.SYNOPSIS
    Restore Storage Sense to its pre-toolkit state for the current user.

.DESCRIPTION
    Paired with disable-storage-sense.ps1. If the manifest contains a
    'reg:StorageSenseMaster' entry, restores that exact value (which
    may have been 1 = enabled, or any other valid byte). If no entry
    exists, removes the override so Windows falls back to its default
    (off on fresh installs; whatever the user set in Settings otherwise).

.NOTES
    Tier: Safe — restorer is always safe to run.
    Microsoft Learn: https://learn.microsoft.com/en-us/windows/configuration/storage-sense
#>
# ============================================================
# Re-enable Storage Sense (Auto Disk Cleanup) — Per-user
# Windows 11 Gaming Optimization Guide
# Source: https://learn.microsoft.com/en-us/windows/configuration/storage-sense
# ============================================================
# Restores the prior Storage Sense state captured by
# disable-storage-sense.ps1. Two paths:
#   1) Manifest entry exists  -> Restore-ToolkitRegistryValue puts
#      the value back to what it was before APPLY ran.
#   2) No manifest entry      -> Remove the master toggle key so
#      Windows falls back to its default (Storage Sense off out of
#      box; the user enables it via Settings if desired).
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Re-enable Storage Sense"
UI-Header -Title "Re-enable Storage Sense" -Subtitle "Restore automatic disk cleanup"
UI-RequireAdmin -ScriptName "Re-enable Storage Sense"

# Audit-trail: log script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$storagePolicyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"

UI-Step -Label "Restore Storage Sense master toggle" -Action {
    if (-not (Restore-ToolkitRegistryValue -Id "reg:StorageSenseMaster")) {
        # Pre-toolkit state had no override -> remove the value so
        # Windows uses its default (off for upgraded users; on for
        # users who enabled it manually in Settings before APPLY).
        Remove-ItemProperty -Path $storagePolicyPath -Name "01" -ErrorAction SilentlyContinue
    }
}

UI-Summary -DoneMessage "Storage Sense state restored" -Details @(
    "Open Settings > System > Storage > Storage Sense to re-tune cadence if needed.",
    "No reboot required."
)
UI-Exit
