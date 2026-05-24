# ============================================================
# Configure Power Plan — alias for configure-power.ps1
# Windows 11 Gaming Optimization Guide
# ============================================================
# CURSOR-AUDIT #18: this file used to be a parallel implementation
# of the power-plan tuning logic. It was superseded by
# configure-power.ps1 (the manifest-tracked, idempotent version) but
# left in the tree for backward compat with user docs and bookmarks.
#
# This alias forwards every invocation to configure-power.ps1 so the
# two paths produce identical state. Old callers don't break; new
# callers are nudged toward the canonical script via the printed note.
#
# If you reach this file via a search or bookmark, prefer
# 2 power plan/configure-power.ps1 going forward.
# ============================================================

Write-Host ""
Write-Host "  [NOTE] configure-power-plan.ps1 is an alias for configure-power.ps1." -ForegroundColor Yellow
Write-Host "         Both share one implementation under the canonical name." -ForegroundColor Yellow
Write-Host ""

$canonical = Join-Path $PSScriptRoot "configure-power.ps1"
if (-not (Test-Path -LiteralPath $canonical)) {
    Write-Host "  [ERROR] Canonical script missing: $canonical" -ForegroundColor Red
    exit 1
}

# Forward all $args (none today but future-safe) to the canonical script.
& $canonical @args
exit $LASTEXITCODE
