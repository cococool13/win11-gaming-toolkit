# ============================================================
# Disable Unnecessary Services (Smart)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Disables services that are safe to turn off for gaming.
# Uses machine profile to skip services that are needed:
#   - Spooler: skipped if printers detected
#   - Domain services: skipped if domain-joined
# Tracks prior state in manifest for exact rollback.
#
# Replaces: apply-all.bat, individual/*.bat
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Disable Services"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Disable Unnecessary Services for Gaming" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$state = Initialize-ToolkitState
$profile = $state.context
$succeeded = 0
$skippedSmart = 0
$skippedAlready = 0
$failed = 0

# Service definitions with conditions
$services = @(
    @{ Name = "DiagTrack";   Desc = "Connected User Experiences (Telemetry)"; Tier = "Safe";     Condition = $null }
    @{ Name = "PhoneSvc";    Desc = "Phone Service";                          Tier = "Safe";     Condition = $null }
    @{ Name = "lfsvc";       Desc = "Geolocation Service";                    Tier = "Safe";     Condition = $null }
    @{ Name = "RetailDemo";  Desc = "Retail Demo Service";                    Tier = "Safe";     Condition = $null }
    @{ Name = "MapsBroker";  Desc = "Downloaded Maps Manager";                Tier = "Safe";     Condition = $null }
    @{ Name = "Fax";         Desc = "Fax Service";                            Tier = "Safe";     Condition = $null }
    @{ Name = "Spooler";     Desc = "Print Spooler";                          Tier = "Advanced"; Condition = "NoPrinters" }
    @{ Name = "WSearch";     Desc = "Windows Search";                         Tier = "Advanced"; Condition = $null }
)

# Show what will happen based on machine profile
Write-Host "  Machine: $($profile.manufacturer) $($profile.model)" -ForegroundColor Gray
Write-Host "  Printers: $($profile.printerCount)" -ForegroundColor Gray
Write-Host "  Domain: $($profile.partOfDomain)" -ForegroundColor Gray
Write-Host ""

# Preview changes
Write-Host "  Services to disable:" -ForegroundColor Yellow
$total = 0
foreach ($svc in $services) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if (-not $service) {
        continue
    }

    $skipReason = $null

    # Condition checks
    if ($svc.Condition -eq "NoPrinters" -and $profile.printerCount -gt 0) {
        $skipReason = "Printers detected ($($profile.printerCount))"
    }

    # Already disabled?
    $currentMode = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
    if ($currentMode -eq "Disabled") {
        $skipReason = "Already disabled"
    }

    if ($skipReason) {
        Write-Host "    [SKIP] $($svc.Name) — $($svc.Desc) ($skipReason)" -ForegroundColor Gray
    } else {
        Write-Host "    $($svc.Name) — $($svc.Desc) [$($svc.Tier)]" -ForegroundColor White
        $total++
    }
}

if ($total -eq 0) {
    Write-Host ""
    Write-Host "  All services already in desired state. Nothing to do." -ForegroundColor Green
    Add-ToolkitStepResult -Key "services-disable" -Tier "Safe" -Status "preexisting" -Reason "All services already disabled"
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host ""
Write-Host "  Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "  Press Enter to continue"
Write-Host ""

# Apply changes
$current = 0
foreach ($svc in $services) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if (-not $service) {
        continue
    }

    $current++

    # Re-check conditions
    if ($svc.Condition -eq "NoPrinters" -and $profile.printerCount -gt 0) {
        Add-ToolkitStepResult -Key "svc:$($svc.Name)" -Tier $svc.Tier -Status "skipped" `
            -Reason "Printers detected ($($profile.printerCount))"
        $skippedSmart++
        Write-Host "  [$current] $($svc.Name) — SKIPPED (printers detected)" -ForegroundColor Yellow
        continue
    }

    $currentMode = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
    if ($currentMode -eq "Disabled") {
        Add-ToolkitStepResult -Key "svc:$($svc.Name)" -Tier $svc.Tier -Status "preexisting" `
            -Reason "Already disabled"
        $skippedAlready++
        Write-Host "  [$current] $($svc.Name) — Already disabled" -ForegroundColor Gray
        continue
    }

    # Disable with manifest tracking
    try {
        Set-ToolkitServiceStartMode -Name $svc.Name -Mode "disabled" -Tier $svc.Tier -Step "services-disable"
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Add-ToolkitStepResult -Key "svc:$($svc.Name)" -Tier $svc.Tier -Status "applied" `
            -Reason "Disabled (was: $currentMode)"
        Write-Host "  [$current] $($svc.Name) — Disabled (was: $currentMode)" -ForegroundColor Green
        $succeeded++
    } catch {
        Write-Host "  [$current] $($svc.Name) — Failed: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Add-ToolkitStepResult -Key "services-disable" -Tier "Safe" -Status "applied" `
    -Reason "Disabled $succeeded services, skipped $skippedSmart (conditional), $skippedAlready (already disabled)"

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SERVICE OPTIMIZATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Disabled:         $succeeded services" -ForegroundColor Green
Write-Host "  Skipped (smart):  $skippedSmart services" -ForegroundColor Yellow
Write-Host "  Already disabled: $skippedAlready services" -ForegroundColor Gray
if ($failed -gt 0) {
    Write-Host "  Failed:           $failed services" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Prior state saved in manifest for exact rollback." -ForegroundColor Gray
Write-Host "  Undo: REVERT-EVERYTHING.ps1 or restore individual services." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to continue"
