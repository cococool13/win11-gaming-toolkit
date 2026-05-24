# ============================================================
# Re-enable All Services — Manifest-Driven Revert
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Safe (restores prior state)
#
# Reads state.services from the manifest and calls
# Restore-ToolkitServiceStartMode for each tracked service. The
# manifest captures the pre-toolkit start mode per service, so this
# script restores the exact prior state (not blanket defaults).
#
# Falls back to defaults for services NOT in the manifest — covers
# the legacy case where users ran 4 services/individual/*-disable.bat
# before the toolkit-state pattern existed.
#
# Pair with: disable-services.ps1
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Revert Services"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Re-enable All Services (Manifest-Driven Revert)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Services this toolkit knows how to disable. Default-restore targets
# match disable-services.ps1 for parity with the old .bat behavior.
# These defaults are only used when the manifest has no entry for the
# service (legacy disable path or wiped manifest).
$serviceDefaults = [ordered]@{
    "DiagTrack"  = @{ Mode = "auto";   Desc = "Connected User Experiences (Telemetry)"; Start = $true  }
    "PhoneSvc"   = @{ Mode = "demand"; Desc = "Phone Service";                            Start = $false }
    "lfsvc"      = @{ Mode = "demand"; Desc = "Geolocation Service";                      Start = $false }
    "RetailDemo" = @{ Mode = "demand"; Desc = "Retail Demo Service";                      Start = $false }
    "MapsBroker" = @{ Mode = "auto";   Desc = "Downloaded Maps Manager";                  Start = $false }
    "Fax"        = @{ Mode = "demand"; Desc = "Fax Service";                              Start = $false }
    "Spooler"    = @{ Mode = "auto";   Desc = "Print Spooler";                            Start = $true  }
    "WSearch"    = @{ Mode = "auto";   Desc = "Windows Search";                           Start = $true  }
}

$state = Get-ToolkitState
$manifestServices = @{}
if ($state -and $state.PSObject.Properties["services"] -and $state.services) {
    if ($state.services -is [hashtable]) {
        foreach ($k in $state.services.Keys) {
            $manifestServices[$k] = $state.services[$k]
        }
    } else {
        foreach ($prop in $state.services.PSObject.Properties) {
            $manifestServices[$prop.Name] = $prop.Value
        }
    }
}

if ($manifestServices.Count -gt 0) {
    Write-Host "  Manifest has $($manifestServices.Count) tracked service(s)." -ForegroundColor Gray
} else {
    Write-Host "  Manifest empty — falling back to defaults for known service names." -ForegroundColor Yellow
}
Write-Host ""

# Union: services in manifest + known defaults that may have been disabled
# by the legacy .bat path. Manifest entries take precedence (exact prior state).
$work = New-Object System.Collections.Generic.List[string]
foreach ($k in $manifestServices.Keys) { [void]$work.Add($k) }
foreach ($k in $serviceDefaults.Keys) {
    if (-not $manifestServices.ContainsKey($k)) {
        [void]$work.Add($k)
    }
}

$succeeded = 0
$skipped = 0
$failed = 0
$current = 0

foreach ($name in $work) {
    $current++
    $service = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "  [$current/$($work.Count)] $name — service not installed; skipping." -ForegroundColor Gray
        $skipped++
        continue
    }

    $fromManifest = $manifestServices.ContainsKey($name)
    try {
        if ($fromManifest) {
            $restored = Restore-ToolkitServiceStartMode -Name $name
            if ($restored) {
                $beforeMode = $manifestServices[$name].before
                Write-Host "  [$current/$($work.Count)] $name — restored to '$beforeMode' (from manifest)." -ForegroundColor Green
                $succeeded++
                continue
            }
        }

        # Defaults fallback (no manifest entry or restore returned $false)
        if ($serviceDefaults.Contains($name)) {
            $def = $serviceDefaults[$name]
            $output = & sc.exe config $name "start=" $def.Mode 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "sc.exe config failed: $output"
            }
            if ($def.Start) {
                Start-Service -Name $name -ErrorAction SilentlyContinue
            }
            Write-Host "  [$current/$($work.Count)] $name — defaults restore: start=$($def.Mode)." -ForegroundColor Yellow
            $succeeded++
        } else {
            Write-Host "  [$current/$($work.Count)] $name — no defaults and manifest restore failed; manual check needed." -ForegroundColor Yellow
            $skipped++
        }
    } catch {
        Write-Host "  [$current/$($work.Count)] $name — FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Add-ToolkitStepResult -Key "services-revert" -Tier "Safe" -Status "applied" `
    -Reason "Restored $succeeded, skipped $skipped, failed $failed"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SERVICE REVERT COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Restored: $succeeded" -ForegroundColor Green
Write-Host "  Skipped:  $skipped" -ForegroundColor Yellow
if ($failed -gt 0) {
    Write-Host "  Failed:   $failed" -ForegroundColor Red
}
Write-Host ""
Read-Host "Press Enter to exit"
