# ============================================================
# Re-enable SMT / Hyper-Threading
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Safe (restores OS default)
#
# Pair with: disable-smt-ht.ps1
# Removes the BCD numproc override so Windows boots with all logical
# processors visible to the scheduler.
#
# Must be run as Administrator. Reboot required.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Re-enable SMT / Hyper-Threading" -Subtitle "Restore default scheduler"
UI-RequireAdmin -ScriptName "Re-enable SMT / Hyper-Threading"

Initialize-ToolkitState | Out-Null

Write-Host "  Removing BCD numproc override..." -ForegroundColor Yellow
$bcdOutput = & bcdedit.exe /deletevalue "{current}" numproc 2>&1
if ($LASTEXITCODE -ne 0 -and "$bcdOutput" -notmatch "could not find the requested element") {
    Write-Host "  [WARN] bcdedit returned $LASTEXITCODE — verify with: bcdedit /enum {current}" -ForegroundColor Yellow
    Write-Host "  $bcdOutput" -ForegroundColor DarkGray
} else {
    Write-Host "  [DONE] numproc override removed." -ForegroundColor Green
}

Add-ToolkitStepResult -Key "cpu-smt-disable-revert" -Tier "Safe" -Status "applied" `
    -Reason "BCD numproc override removed"

Write-Host ""
Write-Host "  REBOOT REQUIRED for SMT to come back online." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
