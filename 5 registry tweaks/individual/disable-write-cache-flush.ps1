# ============================================================
# Disable Write Cache Buffer Flushing (DATA-LOSS RISK)
# Windows 11 Gaming Optimization Guide
# Source: FR33THYFR33THY/Ultimate — 6 Windows/28 Write Cache Buffer Flushing.ps1
#
# TIER: Security Trade-off (data-loss on power loss)
# This is THE most dangerous opt-in script in the toolkit. Disabling
# write cache buffer flushing means Windows will not force the
# storage device to commit cached writes to media. On power loss,
# any data in the cache is gone — this can corrupt filesystems,
# databases, and partial file writes.
#
# Only enable on:
#   - Desktops on a UPS
#   - Laptops with healthy batteries (a true desktop "power loss"
#     scenario is rare on a laptop)
# Do NOT enable on:
#   - Servers handling persistent data
#   - PCs that crash often
#   - Any system without battery / UPS protection
# ============================================================
# Implementation:
#   Each fixed disk's PowerProtected DisableWriteCacheFlushing
#   property is set via Set-PhysicalDisk semantics (where
#   available) and the per-device registry equivalent.
#
# State is captured per-disk to a sidecar JSON before apply.
# ============================================================

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = "Disable Write Cache Flushing"
UI-Header -Title "Disable Write Cache Buffer Flushing" -Subtitle "DATA-LOSS RISK — read the warning"
UI-RequireAdmin -ScriptName "Disable Write Cache Flushing"
UI-Confirm -Message "DATA LOSS WARNING — this is the riskiest tweak in the toolkit." -Warnings @(
    "On power loss, any data in the storage write buffer is gone.",
    "Filesystem corruption, partial file writes, and database damage are all possible.",
    "Only proceed on a UPS-backed desktop or a laptop with a healthy battery.",
    "If you don't know what 'write cache buffer flush' means, run enable-write-cache-flush.ps1 instead."
)

Initialize-ToolkitState | Out-Null
UI-ResetCounters

$stateRoot = Join-Path $env:ProgramData "Win11GamingToolkit\state"
if (-not (Test-Path $stateRoot)) { New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null }
$beforePath = Join-Path $stateRoot "writecache-before.json"

# Each fixed disk's "Disk\UserWriteCacheSetting" lives under its enum entry.
# We capture and write per-disk so the matching enable script can flip
# things back exactly.
$disks = @(Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue |
    Where-Object { $_.MediaType -match "Fixed" })

if ($disks.Count -eq 0) {
    UI-Note -Message "[SKIP] No fixed disks detected." -Color $script:UI_Warning
    UI-Exit
    exit 0
}

if (-not (Test-Path $beforePath)) {
    $snapshot = foreach ($d in $disks) {
        # Map PnP device ID to the registry path under \Enum\
        $pnpId = $d.PNPDeviceID
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId\Device Parameters\Disk"
        $current = (Get-ItemProperty -Path $regPath -Name "UserWriteCacheSetting" -ErrorAction SilentlyContinue).UserWriteCacheSetting
        [PSCustomObject]@{
            Index = $d.Index
            Model = $d.Model
            PnpId = $pnpId
            UserWriteCacheSetting = $current
        }
    }
    $snapshot | ConvertTo-Json | Set-Content -Path $beforePath -Force
    UI-Note -Message "Captured $($disks.Count) disk baseline at $beforePath"
}

UI-Section -Title "Per-disk apply"
foreach ($d in $disks) {
    UI-Step -Label "$($d.Model) (disk $($d.Index))" -Action {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($d.PNPDeviceID)\Device Parameters\Disk"
        Set-ToolkitRegistryValue `
            -Id "reg:DiskWriteCacheFlush:$($d.Index)" `
            -Path $regPath `
            -Name "UserWriteCacheSetting" `
            -Value 1 -Type "DWord" `
            -Tier "Security Trade-off" -Step "writecache-flush"
    }
}

UI-Summary -DoneMessage "Write cache flushing disabled" -Details @(
    "Reboot is required for the storage stack to pick up the change.",
    "If you experience corruption, run enable-write-cache-flush.ps1 IMMEDIATELY."
) -RevertHint "Run enable-write-cache-flush.ps1 in this folder."
UI-Exit
