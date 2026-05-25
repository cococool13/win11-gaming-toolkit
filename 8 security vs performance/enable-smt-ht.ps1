<#
.SYNOPSIS
    Re-enable SMT / Hyper-Threading by removing the BCD numproc override.

.DESCRIPTION
    Pairs with disable-smt-ht.ps1. Calls `bcdedit /deletevalue numproc`
    so Windows boots with all logical processors visible to the
    scheduler. The bcdedit call is gated by $PSCmdlet.ShouldProcess
    so -WhatIf previews without modifying boot config.

.NOTES
    Tier: Safe (restores OS default)
    Pair: disable-smt-ht.ps1
    Anti-cheat impact: NONE — re-enabling SMT restores OS-default
        logical-processor topology. The sibling (disable-smt-ht) carries
        LOW-MED anti-cheat heuristic risk on Zen 5 per recent reports,
        but the re-enable direction is always safe.
    Reboot required for SMT to come back online.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Re-enable SMT / Hyper-Threading" -Subtitle "Restore default scheduler"
UI-RequireAdmin -ScriptName "Re-enable SMT / Hyper-Threading"

Initialize-ToolkitState | Out-Null

if ($PSCmdlet.ShouldProcess("BCD {current} numproc", "bcdedit /deletevalue numproc")) {
    Write-Host "  Removing BCD numproc override..." -ForegroundColor Yellow
    $bcdOutput = & bcdedit.exe /deletevalue "{current}" numproc 2>&1
    if ($LASTEXITCODE -ne 0 -and "$bcdOutput" -notmatch "could not find the requested element") {
        Write-Host "  [WARN] bcdedit returned $LASTEXITCODE — verify with: bcdedit /enum {current}" -ForegroundColor Yellow
        Write-Host "  $bcdOutput" -ForegroundColor DarkGray
    } else {
        Write-Host "  [DONE] numproc override removed." -ForegroundColor Green
    }
} else {
    Write-Host "  [SKIP] -WhatIf: would call bcdedit /deletevalue numproc" -ForegroundColor Gray
}

Add-ToolkitStepResult -Key "cpu-smt-disable-revert" -Tier "Safe" -Status "applied" `
    -Reason "BCD numproc override removed"

Write-Host ""
Write-Host "  REBOOT REQUIRED for SMT to come back online." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
