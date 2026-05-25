#Requires -Version 5.1
<#
.SYNOPSIS
    Unregister DNS-over-HTTPS templates registered by enable-doh.ps1.

.DESCRIPTION
    Pair script for enable-doh.ps1. Walks the same provider list and
    calls Remove-DnsClientDohServerAddress for each. Does NOT touch
    active adapter DNS settings — use REVERT-EVERYTHING.ps1 (or
    enable-doh.ps1 with the same -ApplyToActiveAdapters that was used
    on enable) to restore DNS routing.

    Idempotent: silent-skip on entries that aren't registered.

.PARAMETER WhatIf
    Standard ShouldProcess.

.EXAMPLE
    PS> .\disable-doh.ps1
    Removes all DoH templates this toolkit knows about.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Safe (restores default; encrypted DNS becomes plain UDP)

    # CROSS-PLATFORM-NOTE
    # Windows-only (Remove-DnsClientDohServerAddress).

    Exit codes:
      0  All known templates removed (or already absent)
      2  Cmdlet unavailable (older Win10, Server Core)
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title 'Disable DNS-over-HTTPS' -Subtitle 'Unregister DoH templates'
UI-RequireAdmin -ScriptName 'Disable DoH'
Initialize-ToolkitState | Out-Null

if (-not (Get-Command Remove-DnsClientDohServerAddress -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Remove-DnsClientDohServerAddress not available.' -ForegroundColor Yellow
    Write-ToolkitLog 'doh-revert-skip-noapi' -Level warn
    exit 2
}

# Mirror the provider list in enable-doh.ps1. Keep in sync if either
# script's list changes.
$providers = @(
    '1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001'
    '9.9.9.9', '149.112.112.112', '2620:fe::fe'
    '8.8.8.8', '2001:4860:4860::8888'
)

$removed = 0
$skipped = 0
foreach ($srv in $providers) {
    if (-not $PSCmdlet.ShouldProcess($srv, 'Remove-DnsClientDohServerAddress')) {
        continue
    }
    try {
        Remove-DnsClientDohServerAddress -ServerAddress $srv -ErrorAction Stop | Out-Null
        Write-Host "    [OK] $srv" -ForegroundColor Green
        Write-ToolkitLog 'doh-template-removed' -Data @{ server = $srv }
        $removed++
    } catch {
        # CmdletInvocationException for "no such entry" is the happy-path
        # for idempotent revert. Anything else is a real failure.
        if ($_.Exception.Message -match 'not registered|cannot find') {
            Write-Host "    [SKIP] $srv (not registered)" -ForegroundColor Gray
            $skipped++
        } else {
            Write-Host "    [FAIL] $srv : $($_.Exception.Message)" -ForegroundColor Red
            Write-ToolkitLog 'doh-template-remove-failed' -Level error -Data @{
                server = $srv; err = $_.Exception.Message
            }
        }
    }
}

Add-ToolkitStepResult -Key 'doh-enable-revert' -Tier 'Safe' -Status 'applied' `
    -Reason "Removed $removed DoH templates, skipped $skipped"

Write-Host ''
UI-Note -Message 'DNS routing is unchanged — adapters still use whatever DNS server they had.' -Color $script:UI_Info
UI-Note -Message 'Run REVERT-EVERYTHING.ps1 to also restore pre-toolkit DNS server addresses.' -Color $script:UI_Info
exit 0
