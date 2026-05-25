# ============================================================
# Re-enable Write Cache Buffer Flushing — revert path
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores per-disk write cache flushing setting from the
# manifest. Falls back to removing the override so the storage
# stack uses its safe default.
#
# Anti-cheat impact: NONE — per-disk Enum\<id>\Device Parameters
# registry value; no kernel hooks, no driver state.
# Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
# Disk impact: NONE — registry-only write; no on-disk file creation.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Re-enable Write Cache Flushing"
UI-Header -Title "Re-enable Write Cache Buffer Flushing" -Subtitle "Restore safe storage default"
UI-RequireAdmin -ScriptName "Re-enable Write Cache Flushing"

# Audit-trail: log this script invocation to
# %ProgramData%\Win11GamingToolkit\logs\<stem>-<ts>-<pid>.log
# (or $XDG_DATA_HOME on dev macOS). Idempotent per process.
Write-ToolkitScriptStart

UI-ResetCounters

# Pull every manifest entry with step "writecache-flush" and restore it.
$state = Get-ToolkitState
$count = 0
if ($state -and $state.registry) {
    $regKeys = $state.registry
    $properties = if ($regKeys -is [hashtable]) {
        $regKeys.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Name = $_.Key; Value = $_.Value } }
    } else {
        $regKeys.PSObject.Properties
    }
    foreach ($prop in $properties) {
        if ($prop.Value.step -eq "writecache-flush") {
            UI-Step -Label "Restoring $($prop.Name)" -Action {
                Restore-ToolkitRegistryValue -Id $prop.Name | Out-Null
            }
            $count++
        }
    }
}

# CURSOR-AUDIT #15: fall back to the sidecar when the manifest has no
# writecache-flush entries. Read-ToolkitSidecar returns $null when
# missing OR unparseable — both are "no fallback available" cases.
if ($count -eq 0) {
    $sidecar = Read-ToolkitSidecar -Name 'writecache'
    if ($sidecar) {
        UI-Note -Message "Manifest empty; falling back to 'writecache' sidecar" -Color $script:UI_Warning
        foreach ($d in $sidecar) {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($d.PnpId)\Device Parameters\Disk"
            if (-not (Test-Path $regPath)) {
                UI-Skip -Label "Disk $($d.Index) ($($d.Model))" -Reason "Device key no longer present"
                continue
            }
            UI-Step -Label "Sidecar restore — Disk $($d.Index) ($($d.Model))" -Action {
                if ($null -eq $d.UserWriteCacheSetting) {
                    # Pre-toolkit state: value not set. Remove the override.
                    Remove-ItemProperty -Path $regPath -Name "UserWriteCacheSetting" -ErrorAction SilentlyContinue
                } else {
                    Set-ItemProperty -Path $regPath -Name "UserWriteCacheSetting" -Value $d.UserWriteCacheSetting -Type DWord -Force
                }
            }
            $count++
        }
    }
}

if ($count -eq 0) {
    UI-Note -Message "No tracked writecache-flush entries in manifest or sidecar. Nothing to restore." -Color $script:UI_Info
}

Remove-ToolkitSidecar -Name 'writecache'

UI-Summary -DoneMessage "Write cache flushing restored" -Details @(
    "Reboot for the storage stack to pick up the change."
)
UI-Exit
