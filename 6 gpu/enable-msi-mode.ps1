# ============================================================
# Enable MSI Mode for All GPUs
# Windows 11 Gaming Optimization Guide
# ============================================================
# Enables Message Signaled Interrupts (MSI) for all GPU devices.
# MSI mode has lower latency than legacy line-based interrupts,
# which can reduce micro-stuttering in games.
#
# Run as Administrator in PowerShell.
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Enable MSI Mode for GPUs" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$gpuDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue

if (-not $gpuDevices) {
    Write-Host "[WARNING] No display devices found." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

foreach ($gpu in $gpuDevices) {
    $name = $gpu.FriendlyName
    $id = $gpu.InstanceId
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"

    Write-Host "  GPU: $name" -ForegroundColor White

    # Create registry path if it doesn't exist
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    Set-ItemProperty -Path $regPath -Name "MSISupported" -Value 1 -Type DWord -Force
    Write-Host "    MSI Mode: Enabled" -ForegroundColor Green
}

Write-Host ""
Write-Host "[DONE] MSI mode enabled for all GPUs." -ForegroundColor Green
Write-Host "A reboot is required for changes to take effect." -ForegroundColor Yellow
Write-Host ""
Write-Host "To verify after reboot:" -ForegroundColor Gray
Write-Host "  Open Device Manager > Display Adapters > your GPU >" -ForegroundColor Gray
Write-Host "  Properties > Resources > check for 'Message Signaled'" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
