#Requires -Version 5.1
<#
.SYNOPSIS
    Re-enable NIC Interrupt Moderation from sidecar baseline.

.DESCRIPTION
    Pair of disable-interrupt-moderation.ps1. Reads rss-im-before.json
    and restores each adapter/property pair to its captured DisplayValue.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Safe (restores prior state)

    # CROSS-PLATFORM-NOTE
    # Windows-only (Set-NetAdapterAdvancedProperty).

    Exit codes:
      0  All sidecar entries restored
      1  Sidecar missing
      2  NetAdapter cmdlets unavailable
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title 'Re-enable NIC Interrupt Moderation' -Subtitle 'Sidecar-driven restore'
UI-RequireAdmin -ScriptName 'Restore Interrupt Moderation'
Initialize-ToolkitState | Out-Null

if (-not (Get-Command Set-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Set-NetAdapterAdvancedProperty not available.' -ForegroundColor Yellow
    exit 2
}

$sidecarPath = Join-Path (Split-Path -Parent (Get-ToolkitManifestPath)) 'rss-im-before.json'
if (-not (Test-Path -LiteralPath $sidecarPath)) {
    Write-Host "  [SKIP] No sidecar at $sidecarPath — disable-interrupt-moderation.ps1 never ran." -ForegroundColor Yellow
    exit 1
}

$snapshot = @()
try {
    $snapshot = Get-Content -Raw -LiteralPath $sidecarPath | ConvertFrom-Json
    if ($snapshot -isnot [System.Array]) { $snapshot = @($snapshot) }
} catch {
    Write-Host "  [FAIL] Could not parse sidecar: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$restored = 0
foreach ($entry in $snapshot) {
    $desc = "$($entry.Name)/$($entry.Property) → $($entry.DisplayValue)"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Set-NetAdapterAdvancedProperty (restore)')) {
        continue
    }
    try {
        Set-NetAdapterAdvancedProperty -Name $entry.Name `
            -RegistryKeyword $entry.Property `
            -DisplayValue $entry.DisplayValue `
            -ErrorAction Stop
        Write-Host "  [OK] $desc" -ForegroundColor Green
        Write-ToolkitLog 'im-restored' -Data @{
            adapter = $entry.Name; property = $entry.Property; value = $entry.DisplayValue
        }
        $restored++
    } catch {
        Write-Host "  [FAIL] $($entry.Name): $($_.Exception.Message)" -ForegroundColor Red
        Write-ToolkitLog 'im-restore-failed' -Level error -Data @{
            adapter = $entry.Name; err = $_.Exception.Message
        }
    }
}

Remove-Item -LiteralPath $sidecarPath -Force -ErrorAction SilentlyContinue
Add-ToolkitStepResult -Key 'interrupt-moderation-revert' -Tier 'Safe' -Status 'applied' `
    -Reason "Restored $restored adapter property pairs"
exit 0
