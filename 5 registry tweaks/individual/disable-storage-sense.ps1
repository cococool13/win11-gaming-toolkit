<#
.SYNOPSIS
    Disable Storage Sense (Windows' automatic disk-cleanup background task)
    for the current user.

.DESCRIPTION
    Sets HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\
    Parameters\StoragePolicy\01 = 0 (DWORD) via Set-ToolkitRegistryValue,
    which both applies the change and registers a manifest entry for
    later restore by enable-storage-sense.ps1 (or REVERT-EVERYTHING.ps1).

    Storage Sense fires on a Windows-managed schedule and can pause the
    disk mid-game with background cleanup I/O. Disabling it returns
    cleanup control to the user.

.NOTES
    Tier: Safe — disabling auto-cleanup does not compromise the OS.
    Anti-cheat impact: NONE (UWP/settings feature; no kernel hooks).
    Microsoft Learn: https://learn.microsoft.com/en-us/windows/configuration/storage-sense
    Upstream: FR33THYFR33THY/Ultimate — 7 Performance/Storage Sense
#>
# ============================================================
# Disable Storage Sense (Auto Disk Cleanup) — Per-user
# Windows 11 Gaming Optimization Guide
# Source: https://learn.microsoft.com/en-us/windows/configuration/storage-sense
# Source: FR33THYFR33THY/Ultimate — 7 Performance/Storage Sense
# ============================================================
# Storage Sense is Windows' automatic disk-cleanup background task.
# When it fires it can:
#   - Pause the disk for several seconds during a game session (background I/O)
#   - Empty Recycle Bin / clear Downloads / wipe Windows temp on a schedule
#   - Sweep shader/compile caches that were already paid for
#
# Disabling it gives the user explicit control: cleanup happens when
# they run a cleanup script (9 cleanup/cleanup-temp.ps1), not at a
# random time mid-game. No background scheduler running means no random
# microstutter from disk I/O contention.
#
# Tier: Safe — disabling auto-cleanup doesn't compromise the OS in any
# way. Worst case is disk-full warnings if the user never runs cleanup.
#
# Anti-cheat impact: NONE.
#   Storage Sense is a UWP / settings-app feature, not a kernel hook;
#   disabling it does not touch any driver, service, or memory the
#   anti-cheat layer inspects. Safe on R6 Siege / Valorant / EAC / BE.
#
# Before/after metric:
#   - Before: Storage Sense may run unannounced (default cadence varies)
#   - After:  Cleanup occurs only when the user explicitly initiates it
#
# Reversal: enable-storage-sense.ps1 restores the prior value from the
# manifest, or removes the override so Storage Sense returns to the
# Windows default (usually disabled out-of-box on Win11 unless the user
# opted in via Settings).
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Storage Sense"
UI-Header -Title "Disable Storage Sense" -Subtitle "Stop automatic disk cleanup"
UI-RequireAdmin -ScriptName "Disable Storage Sense"

# Audit-trail: log script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

Initialize-ToolkitState | Out-Null
UI-ResetCounters

# Storage Sense master toggle. Value 01 is the documented enable flag;
# 0 disables, 1 enables. All other StoragePolicy children (cadence,
# age thresholds) become inert once the master is off, so we only
# need to track this single value for a clean revert.
$storagePolicyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"

UI-Step -Label "Disable Storage Sense master toggle" -Action {
    Set-ToolkitRegistryValue `
        -Id "reg:StorageSenseMaster" `
        -Path $storagePolicyPath `
        -Name "01" `
        -Value 0 -Type "DWord" `
        -Tier "Safe" -Step "storage-sense"
    Add-ToolkitStepResult -Key "reg:StorageSenseMaster" -Tier "Safe" -Status "applied" `
        -Reason "Storage Sense automatic cleanup disabled"
}

UI-Summary -DoneMessage "Storage Sense disabled" -Details @(
    "Run 9 cleanup/cleanup-temp.ps1 when you want a controlled cleanup.",
    "No reboot required — the change is picked up on next Settings query."
) -RevertHint "Run enable-storage-sense.ps1 in this folder."
UI-Exit
