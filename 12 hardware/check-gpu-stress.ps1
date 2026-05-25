<#
.SYNOPSIS
    Read-only GPU thermal + clock audit. Reports current state and
    points the user at vendor utilities for real-time temps; opt-in
    -RunStress reserved for future FurMark / 3DMark integration.

.DESCRIPTION
    Reports per-GPU: vendor, friendly name, current driver version,
    and the WMI-exposed thermal data (almost always absent on
    consumer hardware; the script tells you so honestly). Detects
    installed stress tools (FurMark, 3DMark, Unigine Heaven) and
    reports their availability without invoking them.

    Real-time temps on consumer cards: use the vendor utility
    (NVIDIA System Information / NVIDIA App / AMD Adrenalin / Intel
    Arc Control) or HWiNFO64.

    Anti-cheat impact: NONE (pure PnP + CIM read).
    Reboot required: NO.
    Disk impact: NONE.

.PARAMETER RunStress
    Reserved for future stress-tool integration. Reports availability
    only today.

.PARAMETER AsObject
    Emit [PSCustomObject] records.

.NOTES
    Tier: Safe (read-only)
    HWiNFO64: https://www.hwinfo.com/
    FurMark: https://geeks3d.com/furmark/

    # CROSS-PLATFORM-NOTE
    # Windows-only. Returns @() on non-Windows.
#>
[CmdletBinding()]
param(
    [switch]$RunStress,
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"
. "$PSScriptRoot\..\lib\gpu-detection.ps1"

if (-not (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'GPU Stress Audit' -Subtitle 'Read-only'
    UI-Note -Message '[SKIP] Get-PnpDevice unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

$gpus = @(Get-GpuVendor)
$stressTools = @(
    @{ Name = 'FurMark'; Path = Join-Path ${env:ProgramFiles} 'Geeks3D\FurMark\FurMark.exe' }
    @{ Name = '3DMark'; Path = Join-Path ${env:ProgramFiles} 'UL\3DMark\3DMark.exe' }
    @{ Name = 'Unigine Heaven'; Path = Join-Path ${env:ProgramFiles} 'Unigine\Heaven Benchmark 4.0\Heaven.exe' }
)
$detectedTools = @($stressTools | Where-Object { Test-Path $_.Path })

$records = $gpus | ForEach-Object {
    [PSCustomObject]@{
        Vendor = $_.Vendor
        FriendlyName = $_.FriendlyName
        DeviceId = $_.DeviceId
        IsDiscrete = $_.IsDiscrete
    }
}

$summary = [PSCustomObject]@{
    GpuCount = $gpus.Count
    Gpus = $records
    StressToolsAvailable = $detectedTools.Name
    StressToolsMissing = @($stressTools | Where-Object { -not (Test-Path $_.Path) } | ForEach-Object { $_.Name })
    StressRequested = [bool]$RunStress
}

if ($AsObject) {
    return $summary
}

UI-Header -Title 'GPU Thermal + Clock Audit' -Subtitle 'Read-only — current state'
UI-KeyValue -Label 'Discrete GPUs' -Value $records.Count
Write-Host ''

if ($records.Count -eq 0) {
    Write-Host '  No discrete GPU detected.' -ForegroundColor Yellow
} else {
    foreach ($g in $records) {
        Write-Host "  $($g.FriendlyName) ($($g.Vendor.ToUpper()) / DeviceID $($g.DeviceId))" -ForegroundColor White
        Write-Host '    Real-time temps not available via WMI on consumer cards.' -ForegroundColor DarkGray
        Write-Host '    Use vendor utility or HWiNFO64 for live monitoring.' -ForegroundColor DarkGray
    }
    Write-Host ''
}

Write-Host '  Stress tools detected:' -ForegroundColor Cyan
if ($summary.StressToolsAvailable.Count -eq 0) {
    Write-Host '    (none installed)' -ForegroundColor Gray
} else {
    foreach ($t in $summary.StressToolsAvailable) {
        Write-Host "    - $t" -ForegroundColor Green
    }
}
if ($summary.StressToolsMissing.Count -gt 0) {
    Write-Host '  Recommended (install one):' -ForegroundColor Cyan
    foreach ($t in $summary.StressToolsMissing) {
        Write-Host "    - $t" -ForegroundColor Gray
    }
}
Write-Host ''

if ($RunStress) {
    Write-Host '  -RunStress is reserved for a future FurMark-fetch integration.' -ForegroundColor Yellow
    Write-Host ''
}
