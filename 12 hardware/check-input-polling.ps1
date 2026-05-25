<#
.SYNOPSIS
    Read-only audit of every connected HID input device (mouse,
    keyboard, gamepad) and its reported polling rate.

.DESCRIPTION
    Walks Get-PnpDevice for the Mouse, Keyboard, and HIDClass classes
    and reports each present device's:
      - FriendlyName, InstanceId
      - Windows-class category
      - SampleRate registry value (where the vendor surfaces it; not
        all HID drivers populate this)
      - PnP DeviceID parsed for VID/PID so the user can match against
        their hardware on hand

    Read-only — does NOT change any device or registry value.
    Anti-cheat impact: NONE. Pure enumeration.

    For ACTUAL measurement of polling rate under input load, an
    external tool is required (the polling-rate property is the
    REQUESTED rate, not what the device delivers under contention).
    The companion check-mouse-polling.ps1 (downloads MouseTester with
    SHA-256 verify) is the next planned addition; this script is the
    Phase A read-only foundation it'll build on.

    Output is grouped by category (mice first, then keyboards, then
    other HID), each row terse and aligned. Pass -AsObject to get
    PSCustomObject records for piping (e.g.
    `check-input-polling -AsObject | Where-Object SampleRate -lt 500`).

.PARAMETER AsObject
    Emit [PSCustomObject] records to the pipeline instead of formatted
    text. Each record has Category, FriendlyName, InstanceId, Vid,
    Pid, SampleRate, Notes.

.NOTES
    Tier: Safe (read-only)
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows-hardware/drivers/usbcon/
      https://learn.microsoft.com/en-us/powershell/module/pnpdevice/get-pnpdevice
    Future pair: check-mouse-polling.ps1 (downloads measurement util)

    # CROSS-PLATFORM-NOTE
    # Windows-only (Get-PnpDevice). Returns early on non-Windows.
#>
[CmdletBinding()]
param(
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return }
    UI-Header -Title 'Input Polling Audit' -Subtitle 'Read-only HID enumeration'
    UI-Note -Message '[SKIP] Get-PnpDevice unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

# Categorize each present input device into the user-recognizable
# buckets. HIDClass catches gamepads, dongles, drawing tablets, etc.
# Mouse / Keyboard are dedicated PnP classes; HIDClass is the catch-all.
function Get-InputDeviceRecord {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)][object]$Device,
        [Parameter(Mandatory)][string]$Category
    )

    # Parse VID/PID from InstanceId — InstanceId looks like
    #   HID\VID_046D&PID_C09A&...   or
    #   USB\VID_046D&PID_C09A\...
    # NOTE: $devVid / $devPid — NOT $vid / $pid. $pid is a PowerShell
    # automatic variable (current process ID) and shadowing it would
    # break any later code that needed the real PID.
    $devVid = ''
    $devPid = ''
    if ($Device.InstanceId -match 'VID_([0-9A-Fa-f]{4})') { $devVid = $matches[1].ToUpper() }
    if ($Device.InstanceId -match 'PID_([0-9A-Fa-f]{4})') { $devPid = $matches[1].ToUpper() }

    # SampleRate is in HKLM:\SYSTEM\CurrentControlSet\Enum\<InstanceId>\
    # Device Parameters. Not all vendors populate it; absence is normal.
    $devParamPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Device.InstanceId)\Device Parameters"
    $sampleRate = (Get-ItemProperty -Path $devParamPath -Name 'SampleRate' -ErrorAction SilentlyContinue).SampleRate

    $notes = if ($sampleRate) {
        if ($sampleRate -ge 1000) { 'OK (1000+ Hz)' }
        elseif ($sampleRate -ge 500) { 'OK (500+ Hz, consider 1000 Hz for competitive play)' }
        elseif ($sampleRate -ge 250) { 'Low — competitive gaming benefits from 500-1000 Hz' }
        else { "Very low — vendor cap or driver issue?" }
    } else {
        'Not exposed by driver'
    }

    [PSCustomObject]@{
        Category = $Category
        FriendlyName = $Device.FriendlyName
        InstanceId = $Device.InstanceId
        Vid = $devVid
        Pid = $devPid
        SampleRate = $sampleRate
        Notes = $notes
    }
}

$records = @()
foreach ($category in @('Mouse', 'Keyboard', 'HIDClass')) {
    $devices = @(Get-PnpDevice -PresentOnly -Class $category -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq 'OK' })
    foreach ($d in $devices) {
        $records += Get-InputDeviceRecord -Device $d -Category $category
    }
}

if ($AsObject) {
    return $records
}

UI-Header -Title 'Input Polling Audit' -Subtitle 'Read-only HID enumeration'

if ($records.Count -eq 0) {
    UI-Note -Message 'No connected HID input devices detected.' -Color $script:UI_Warning
    return
}

UI-KeyValue -Label 'Detected' -Value "$($records.Count) HID input device(s)"
Write-Host ''

foreach ($category in @('Mouse', 'Keyboard', 'HIDClass')) {
    $subset = @($records | Where-Object Category -EQ $category)
    if ($subset.Count -eq 0) { continue }
    Write-Host "  $($category):" -ForegroundColor Cyan
    foreach ($r in $subset) {
        Write-Host "    - $($r.FriendlyName)" -ForegroundColor White
        Write-Host "        VID/PID: $($r.Vid)/$($r.Pid)" -ForegroundColor Gray
        $rateText = if ($r.SampleRate) { "$($r.SampleRate) Hz" } else { '(not exposed by driver)' }
        Write-Host "        Reported polling: $rateText" -ForegroundColor Gray
        Write-Host "        Note: $($r.Notes)" -ForegroundColor DarkGray
    }
    Write-Host ''
}

Write-Host '  This audit is read-only and reports what the driver SURFACES.' -ForegroundColor DarkGray
Write-Host '  To MEASURE polling rate under load, run a tool like MouseTester' -ForegroundColor DarkGray
Write-Host '  (planned check-mouse-polling.ps1 will fetch + SHA-256 verify it).' -ForegroundColor DarkGray
Write-Host ''
