# ============================================================
# Re-enable Write Cache Buffer Flushing — revert path
# Windows 11 Gaming Optimization Guide
# ============================================================
# Restores per-disk write cache flushing setting from the
# manifest. Falls back to removing the override so the storage
# stack uses its safe default.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Re-enable Write Cache Flushing"
UI-Header -Title "Re-enable Write Cache Buffer Flushing" -Subtitle "Restore safe storage default"
UI-RequireAdmin -ScriptName "Re-enable Write Cache Flushing"

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\writecache-before.json"

# Pull every manifest entry with step "writecache-flush" and restore it.
$state = Get-ToolkitState
if ($state -and $state.registry) {
    $regKeys = $state.registry
    $properties = if ($regKeys -is [hashtable]) {
        $regKeys.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Name = $_.Key; Value = $_.Value } }
    } else {
        $regKeys.PSObject.Properties
    }
    $count = 0
    foreach ($prop in $properties) {
        if ($prop.Value.step -eq "writecache-flush") {
            UI-Step -Label "Restoring $($prop.Name)" -Action {
                Restore-ToolkitRegistryValue -Id $prop.Name | Out-Null
            }
            $count++
        }
    }
    if ($count -eq 0) {
        UI-Note -Message "No tracked writecache-flush entries in manifest. Nothing to restore." -Color $script:UI_Info
    }
}

if (Test-Path $beforePath) { Remove-Item $beforePath -Force -ErrorAction SilentlyContinue }

UI-Summary -DoneMessage "Write cache flushing restored" -Details @(
    "Reboot for the storage stack to pick up the change."
)
UI-Exit
