# ============================================================
# Re-enable Data Execution Prevention (DEP) — revert path
# Windows 11 Gaming Optimization Guide
# ============================================================
# Reads the dep-before.json sidecar (captured by disable-dep.ps1)
# and restores the user's prior `nx` policy. Falls back to
# nx=OptIn (the Windows default for client editions) if the
# sidecar is missing.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Re-enable DEP"
UI-Header -Title "Re-enable Data Execution Prevention" -Subtitle "Restore prior nx policy"
UI-RequireAdmin -ScriptName "Re-enable DEP"

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\dep-before.json"

$nxValue = "OptIn"
if (Test-Path $beforePath) {
    $before = Get-Content $beforePath -Raw | ConvertFrom-Json
    if ($before.nx) { $nxValue = $before.nx }
    UI-Note -Message "Restoring nx=$nxValue from $beforePath"
} else {
    UI-Note -Message "No sidecar — restoring nx=OptIn (Windows client default)." -Color $script:UI_Warning
}

UI-Step -Label "Setting nx=$nxValue" -Action {
    $output = bcdedit /set "{current}" nx $nxValue 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "bcdedit failed: $output"
    }
}

if (Test-Path $beforePath) { Remove-Item $beforePath -Force -ErrorAction SilentlyContinue }

UI-Summary -DoneMessage "DEP restored" -Details @(
    "A REBOOT is required for nx changes to take effect."
)
UI-Exit
