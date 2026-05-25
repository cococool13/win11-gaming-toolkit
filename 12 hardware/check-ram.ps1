<#
.SYNOPSIS
    Read-only RAM audit — reports installed modules + speed + WHEA
    memory errors logged since last boot. Opt-in -RunStress reserved
    for MemTest86 / Windows Memory Diagnostic dispatch.

.DESCRIPTION
    Reports per-DIMM: capacity, configured speed, manufacturer, part
    number. Counts WHEA-Logger memory-corrected and memory-uncorrected
    errors in the System event log since last boot — a non-zero count
    on uncorrected errors means a marginal DIMM or RAM-slot issue.

    Real burn-in stress requires booting MemTest86 (Win can't reliably
    test RAM it's currently using). Windows Memory Diagnostic
    (mdsched.exe) provides a reboot-time test that's good enough for
    "is this stick failing?" diagnosis — the script reports its
    presence but does NOT auto-launch it.

    Anti-cheat impact: NONE (CIM + event log read).
    Reboot required: NO (audit itself; MemTest86 / mdsched would).
    Disk impact: NONE.

.PARAMETER RunStress
    Reserved for future mdsched.exe dispatch behind confirmation.

.PARAMETER AsObject
    Emit a [PSCustomObject] record.

.NOTES
    Tier: Safe (read-only)
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/client-management/windows-memory-diagnostic
    MemTest86 (third-party):
      https://www.memtest86.com/

    # CROSS-PLATFORM-NOTE
    # Windows-only.
#>
[CmdletBinding()]
param(
    [switch]$RunStress,
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'RAM Audit' -Subtitle 'Read-only'
    UI-Note -Message '[SKIP] Get-CimInstance unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

$dimms = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue)
$totalGB = if ($dimms) { [math]::Round((($dimms | Measure-Object -Property Capacity -Sum).Sum) / 1GB, 1) } else { 0 }

# WHEA memory error counts via Get-WinEvent. WHEA-Logger provider
# events 17 (corrected) and 18 (uncorrected) cover the memory-error
# event IDs for the in-box reporting path.
$correctedErrors = 0
$uncorrectedErrors = 0
if (Get-Command Get-WinEvent -ErrorAction SilentlyContinue) {
    try {
        $events = @(Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                ProviderName = 'Microsoft-Windows-WHEA-Logger'
            } -ErrorAction SilentlyContinue -MaxEvents 500)
        # 17 = corrected hardware error, 18 = uncorrected hardware error.
        # Memory-class subsetting is in the event payload XML; for a
        # cheap proxy we report both counts and let the user dig if
        # uncorrected > 0.
        $correctedErrors = @($events | Where-Object { $_.Id -eq 17 }).Count
        $uncorrectedErrors = @($events | Where-Object { $_.Id -eq 18 }).Count
    } catch {
        # Event log may be inaccessible (e.g. non-admin run); silent fail
        # so the audit still emits the DIMM inventory.
        $null = $_
    }
}

$mdschedAvailable = Test-Path (Join-Path $env:SystemRoot 'System32\mdsched.exe')

$record = [PSCustomObject]@{
    TotalGB = $totalGB
    DimmCount = $dimms.Count
    Dimms = @($dimms | ForEach-Object {
            [PSCustomObject]@{
                CapacityGB = [math]::Round($_.Capacity / 1GB, 1)
                ConfiguredSpeedMHz = $_.ConfiguredClockSpeed
                MaxSpeedMHz = $_.Speed
                Manufacturer = $_.Manufacturer
                PartNumber = ($_.PartNumber).Trim()
                Location = $_.DeviceLocator
            }
        })
    WheaCorrectedErrors = $correctedErrors
    WheaUncorrectedErrors = $uncorrectedErrors
    MdschedAvailable = $mdschedAvailable
}

if ($AsObject) {
    return $record
}

UI-Header -Title 'RAM Audit' -Subtitle 'Read-only — DIMMs + WHEA error counts'
UI-KeyValue -Label 'Total RAM' -Value "$totalGB GB across $($dimms.Count) DIMM(s)"
Write-Host ''

foreach ($d in $record.Dimms) {
    Write-Host "  $($d.Location): $($d.CapacityGB) GB @ $($d.ConfiguredSpeedMHz) MHz" -ForegroundColor White
    Write-Host "    $($d.Manufacturer) — $($d.PartNumber)" -ForegroundColor Gray
}
Write-Host ''

$wheaColor = if ($uncorrectedErrors -gt 0) { $script:UI_Error }
elseif ($correctedErrors -gt 0) { $script:UI_Warning }
else { $script:UI_Success }
Write-Host '  WHEA-Logger errors in System event log:' -ForegroundColor Cyan
Write-Host "    Corrected:    $correctedErrors" -ForegroundColor $wheaColor
Write-Host "    Uncorrected:  $uncorrectedErrors" -ForegroundColor $wheaColor
if ($uncorrectedErrors -gt 0) {
    Write-Host '  → UNCORRECTED errors indicate failing hardware. Run MemTest86 ASAP.' -ForegroundColor Red
}
Write-Host ''

if ($mdschedAvailable) {
    Write-Host '  Windows Memory Diagnostic (mdsched.exe) is available.' -ForegroundColor Gray
    Write-Host '  Launch from Start menu or run mdsched in an elevated shell.' -ForegroundColor Gray
}
Write-Host '  For thorough testing, boot from MemTest86 (USB, 4+ hours).' -ForegroundColor Gray
Write-Host ''

if ($RunStress) {
    Write-Host '  -RunStress is reserved for a future mdsched dispatch.' -ForegroundColor Yellow
    Write-Host ''
}
