# ============================================================
# Show Mouse Info — connected mice + reported polling
# Windows 11 Gaming Optimization Guide
# Inspired by: FR33THYFR33THY/Ultimate — 7 Hardware/* (folder concept)
# Copyright FR33THY (MIT) for the category structure
# ============================================================
# Tier: Safe (read-only)
#
# Seed script for the new 7 Hardware/ folder. Enumerates connected
# HID mouse devices via PnP and reports the registry-claimed polling
# rate where Windows exposes it.
#
# Real polling-rate testing requires capturing input events under
# load (mouserate.exe, mousetester etc.) — that belongs in a separate
# tool-wrapping script that downloads the test util with SHA-256
# verify. This script is the read-only foundation.
#
# Future scripts in this folder (per FR33THY 7 Hardware/):
#   - check-mouse-polling.ps1 (downloads mouserate util, runs it)
#   - check-controller-polling.ps1 (XInput polling test)
#   - check-bufferbloat.ps1 (web-launch wrapper to dslreports test)
#
# Run from the launcher [7] submenu or directly.
# ============================================================

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Mouse Info" -Subtitle "Read-only enumeration of connected mice"

$mice = @(Get-PnpDevice -PresentOnly -Class Mouse -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "OK" })

if ($mice.Count -eq 0) {
    UI-Note -Message "No connected mouse devices detected." -Color $script:UI_Warning
    Read-Host "Press Enter to exit"
    exit 0
}

UI-KeyValue -Label "Detected" -Value "$($mice.Count) mouse device(s)"
Write-Host ""

foreach ($m in $mice) {
    Write-Host "  - $($m.FriendlyName)" -ForegroundColor White
    Write-Host "      Class:    Mouse" -ForegroundColor Gray
    Write-Host "      InstanceId: $($m.InstanceId)" -ForegroundColor Gray

    # Try to read SampleRate from the device parameters key (where some
    # mice expose their report-rate setting). Not all devices populate this.
    $devParamPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($m.InstanceId)\Device Parameters"
    $sampleRate = (Get-ItemProperty -Path $devParamPath -Name "SampleRate" -ErrorAction SilentlyContinue).SampleRate
    if ($sampleRate) {
        Write-Host "      Reported polling: ${sampleRate} Hz" -ForegroundColor Green
    } else {
        Write-Host "      Reported polling: (not exposed by driver)" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "  This script is read-only. To actually MEASURE polling rate" -ForegroundColor Gray
Write-Host "  under load, use an external tool like mouserate.exe or" -ForegroundColor Gray
Write-Host "  mousetester (downloaded with SHA-256 verify in a future" -ForegroundColor Gray
Write-Host "  release of this folder)." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
