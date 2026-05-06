# ============================================================
# Revert MMAgent — companion to configure-mmagent.ps1
# Windows 11 Gaming Optimization Guide
# ============================================================
# Reads the mmagent-before.json sidecar (captured by
# configure-mmagent.ps1) and re-enables exactly the features
# that were on at apply time. If the sidecar is missing,
# falls back to Windows defaults (everything enabled).
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Revert MMAgent"
UI-Header -Title "Revert MMAgent" -Subtitle "Restore MMAgent baseline"
UI-RequireAdmin -ScriptName "Revert MMAgent"

if (-not (Get-Command Set-MMAgent -ErrorAction SilentlyContinue)) {
    UI-Note -Message "[ERROR] MMAgent cmdlets are not available on this Windows edition." -Color $script:UI_Error
    UI-Exit
    exit 1
}

UI-ResetCounters
$beforePath = Join-Path $env:ProgramData "Win11GamingToolkit\state\mmagent-before.json"

$before = $null
if (Test-Path $beforePath) {
    $before = Get-Content $beforePath -Raw | ConvertFrom-Json
    UI-Note -Message "Restoring MMAgent from $beforePath"
} else {
    UI-Note -Message "No baseline sidecar found. Restoring Windows defaults (all features on)." -Color $script:UI_Warning
    $before = [PSCustomObject]@{
        PageCombining = $true
        OperationAPI = $true
        ApplicationPreLaunch = $true
        MemoryCompression = $true
    }
}

function Apply-MMAgentFeature {
    param([string]$Name, [bool]$Enable)
    if ($Enable) {
        Enable-MMAgent -$Name -ErrorAction SilentlyContinue
    } else {
        Disable-MMAgent -$Name -ErrorAction SilentlyContinue
    }
}

UI-Step -Label "PageCombining = $($before.PageCombining)" -Action {
    if ($before.PageCombining) { Enable-MMAgent -PageCombining -ErrorAction Stop }
    else { Disable-MMAgent -PageCombining -ErrorAction Stop }
}
UI-Step -Label "OperationAPI = $($before.OperationAPI)" -Action {
    if ($before.OperationAPI) { Enable-MMAgent -OperationAPI -ErrorAction Stop }
    else { Disable-MMAgent -OperationAPI -ErrorAction Stop }
}
UI-Step -Label "ApplicationPreLaunch = $($before.ApplicationPreLaunch)" -Action {
    if ($before.ApplicationPreLaunch) { Enable-MMAgent -ApplicationPreLaunch -ErrorAction Stop }
    else { Disable-MMAgent -ApplicationPreLaunch -ErrorAction Stop }
}
UI-Step -Label "MemoryCompression = $($before.MemoryCompression)" -Action {
    if ($before.MemoryCompression) { Enable-MMAgent -MemoryCompression -ErrorAction Stop }
    else { Disable-MMAgent -MemoryCompression -ErrorAction Stop }
}

# Once restored, drop the sidecar so a future apply re-captures fresh state.
if (Test-Path $beforePath) {
    Remove-Item $beforePath -Force -ErrorAction SilentlyContinue
}

UI-Summary -DoneMessage "MMAgent reverted" -Details @(
    "Reboot for changes to fully settle."
)
UI-Exit
