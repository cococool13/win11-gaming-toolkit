# ============================================================
# Disable Data Execution Prevention (DEP)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 8 Advanced/4 Data Execution Prevention.ps1
#
# TIER: Security Trade-off
# DEP is a CPU/OS-enforced protection that marks memory pages as
# non-executable. Setting nx=AlwaysOff disables it entirely. This
# was a meaningful protection against buffer-overflow exploits
# in the early 2010s; modern attacks bypass it routinely, but
# disabling still expands attack surface meaningfully.
# ============================================================
# What this changes:
#   bcdedit /set {current} nx AlwaysOff
#
# Captures the current `nx` policy via bcdedit /enum {current}
# to a sidecar JSON so the matching enable script restores
# exactly the user's prior policy.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable DEP"
UI-Header -Title "Disable Data Execution Prevention (DEP)" -Subtitle "bcdedit nx AlwaysOff"
UI-RequireAdmin -ScriptName "Disable DEP"
UI-Confirm -Message "This is a Security Trade-off step." -Warnings @(
    "DEP is a CPU/OS protection against execution of data pages.",
    "Disabling raises attack surface for buffer-overflow class bugs.",
    "Skip this on systems that browse the internet broadly or run untrusted code."
)

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$stateRoot = Join-Path $env:ProgramData "Win11GamingToolkit\state"
if (-not (Test-Path $stateRoot)) { New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null }
$beforePath = Join-Path $stateRoot "dep-before.json"

if (-not (Test-Path $beforePath)) {
    $bcd = bcdedit /enum "{current}" 2>&1
    $nxLine = ($bcd | Select-String -Pattern '^\s*nx\s+').Line
    $nxValue = if ($nxLine) { ($nxLine -split '\s+', 2)[1].Trim() } else { "OptIn" }
    [PSCustomObject]@{ nx = $nxValue } | ConvertTo-Json | Set-Content -Path $beforePath -Force
    UI-Note -Message "Captured DEP baseline (nx=$nxValue) at $beforePath"
}

UI-Step -Label "Setting nx=AlwaysOff" -Action {
    $output = bcdedit /set "{current}" nx AlwaysOff 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "bcdedit failed: $output"
    }
    Add-ToolkitStepResult -Key "bcd:nx" -Tier "Security Trade-off" -Status "applied" -Reason "DEP set to AlwaysOff"
}

UI-Summary -DoneMessage "DEP disabled" -Details @(
    "A REBOOT is required. The bootloader picks up the new nx setting at next boot.",
    "Verify after reboot with: bcdedit /enum {current} | findstr /i nx"
) -RevertHint "Run enable-dep.ps1 in this folder."
UI-Exit
