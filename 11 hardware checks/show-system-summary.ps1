# ============================================================
# Show System Summary — Hardware + Windows baseline
# Windows 11 Gaming Optimization Guide
# Inspired by: FR33THYFR33THY/Ultimate — 1 Check/* (folder concept)
# Copyright FR33THY (MIT) for the category structure
# ============================================================
# Tier: Safe (read-only)
#
# Read-only baseline display of the machine the toolkit is about
# to be (or has been) applied to. Pulls from Get-CimInstance + a
# few targeted registry reads. No manifest writes. No mutations.
#
# This is the seed script for the new 1 Check/ folder ported from
# FR33THY/Ultimate. The folder will grow to include space/RAM/GPU
# checks, CPU/RAM/GPU stress-test wrappers (download external tools
# with SHA-256 verify), HWiNFO launcher, and the BIOS guide.
#
# Run from the launcher [1] submenu or directly.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "System Summary" -Subtitle "Read-only hardware + Windows baseline"

# Reuse the machine-profile helper that the launcher already uses.
$profile = Get-ToolkitMachineProfile
UI-ShowProfile -Profile $profile

# Additional details not in the profile
$cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
$ram = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
$totalRamGB = if ($ram) { [Math]::Round((($ram | Measure-Object Capacity -Sum).Sum / 1GB), 1) } else { "?" }
$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue

Write-Host ""
UI-KeyValue -Label "CPU"     -Value $(if ($cpu) { "$($cpu.Name) ($($cpu.NumberOfCores)c/$($cpu.NumberOfLogicalProcessors)t)" } else { "unknown" })
UI-KeyValue -Label "RAM"     -Value "${totalRamGB} GB ($(if ($ram) { $ram.Count } else { 0 }) sticks)"
UI-KeyValue -Label "BIOS"    -Value $(if ($bios) { "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate))" } else { "unknown" })
UI-KeyValue -Label "OS build" -Value $(if ($os) { "$($os.BuildNumber).$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).UBR)" } else { "unknown" })

# Manifest state (toolkit progress, if any)
Write-Host ""
$mfPath = Get-ToolkitManifestPath
if (Test-Path -LiteralPath $mfPath) {
    $state = Get-ToolkitState
    $stepCount = 0
    if ($state -and $state.PSObject.Properties["steps"] -and $state.steps) {
        $stepCount = if ($state.steps -is [hashtable]) { $state.steps.Keys.Count } else { @($state.steps.PSObject.Properties).Count }
    }
    UI-KeyValue -Label "Manifest" -Value "$mfPath  ($stepCount steps tracked)"
} else {
    UI-KeyValue -Label "Manifest" -Value "(none — toolkit not yet applied)"
}

Write-Host ""
Write-Host "  This script is read-only. Run [V] Verify status for tracked-step state." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
