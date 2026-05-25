<#
.SYNOPSIS
    Read-only CPU thermal + frequency audit. Reports current state
    via CIM; optionally invokes an external stress tool when present.

.DESCRIPTION
    Reports per-logical-CPU current frequency (vs. max) and the
    system thermal state via Win32_Processor + Win32_TemperatureProbe.
    Most consumer motherboards don't expose temps via WMI — this
    script doesn't pretend otherwise; it tells you WHERE to look
    instead.

    Optional stress test (-RunStress) requires a third-party tool
    (Prime95, OCCT, AIDA64). The script DOES NOT download or install
    any of them — it reports availability and points the user at the
    vendor pages. The opt-in flag exists so a future commit can add
    a SHA-256-verified Prime95 fetch without re-shaping the API.

    Anti-cheat impact: NONE (pure CIM read).
    Reboot required: NO.
    Disk impact: NONE.

.PARAMETER RunStress
    Reserved for a future Prime95 / OCCT integration. Currently
    reports tool availability + install state; does NOT run any
    stress. Default $false.

.PARAMETER AsObject
    Emit a [PSCustomObject] record instead of formatted text.

.NOTES
    Tier: Safe (read-only)
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor
    HWiNFO64 (better thermal source on most consumer boards):
      https://www.hwinfo.com/

    # CROSS-PLATFORM-NOTE
    # Windows-only (Win32_Processor CIM). Returns @() on non-Windows.
#>
[CmdletBinding()]
param(
    [switch]$RunStress,
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'CPU Stress Audit' -Subtitle 'Read-only'
    UI-Note -Message '[SKIP] Get-CimInstance unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

$cpus = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue)
$tempProbes = @(Get-CimInstance -ClassName Win32_TemperatureProbe -ErrorAction SilentlyContinue)

# Stress tool detection — opt-in, never auto-runs.
$stressTools = @(
    @{ Name = 'Prime95'; Path = Join-Path ${env:ProgramFiles} 'Prime95\prime95.exe' }
    @{ Name = 'OCCT'; Path = Join-Path ${env:ProgramFiles} 'OCCT\OCCT.exe' }
    @{ Name = 'AIDA64 Extreme'; Path = Join-Path ${env:ProgramFiles} 'FinalWire\AIDA64 Extreme\aida64.exe' }
)
$detectedTools = @($stressTools | Where-Object { Test-Path $_.Path })

$record = [PSCustomObject]@{
    LogicalProcessors = ($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
    Cores = ($cpus | Measure-Object -Property NumberOfCores -Sum).Sum
    CurrentClockMHz = ($cpus | Measure-Object -Property CurrentClockSpeed -Average).Average
    MaxClockMHz = ($cpus | Measure-Object -Property MaxClockSpeed -Average).Average
    ThermalProbeCount = $tempProbes.Count
    StressToolsAvailable = $detectedTools.Name
    StressToolsMissing = @($stressTools | Where-Object { -not (Test-Path $_.Path) } | ForEach-Object { $_.Name })
    StressRequested = [bool]$RunStress
}

if ($AsObject) {
    return $record
}

UI-Header -Title 'CPU Thermal + Frequency Audit' -Subtitle 'Read-only — current state'
UI-KeyValue -Label 'Cores / Logical' -Value ("$($record.Cores) / $($record.LogicalProcessors)")
UI-KeyValue -Label 'Avg current clock' -Value ("{0} MHz" -f $record.CurrentClockMHz)
UI-KeyValue -Label 'Avg max clock' -Value ("{0} MHz" -f $record.MaxClockMHz)
UI-KeyValue -Label 'Thermal probes' -Value $record.ThermalProbeCount
Write-Host ''

if ($record.ThermalProbeCount -eq 0) {
    Write-Host '  Most consumer motherboards do NOT expose CPU temperatures via WMI.' -ForegroundColor DarkGray
    Write-Host '  Use HWiNFO64 / LibreHardwareMonitor / vendor utility for real-time temps.' -ForegroundColor DarkGray
    Write-Host ''
}

Write-Host '  Stress tools detected:' -ForegroundColor Cyan
if ($record.StressToolsAvailable.Count -eq 0) {
    Write-Host '    (none installed)' -ForegroundColor Gray
} else {
    foreach ($t in $record.StressToolsAvailable) {
        Write-Host "    - $t" -ForegroundColor Green
    }
}
if ($record.StressToolsMissing.Count -gt 0) {
    Write-Host '  Recommended (install one):' -ForegroundColor Cyan
    foreach ($t in $record.StressToolsMissing) {
        Write-Host "    - $t" -ForegroundColor Gray
    }
}
Write-Host ''

if ($RunStress) {
    Write-Host '  -RunStress is reserved for a future Prime95-fetch integration.' -ForegroundColor Yellow
    Write-Host '  For now, install one of the tools above and run it manually.' -ForegroundColor Yellow
    Write-Host ''
}
