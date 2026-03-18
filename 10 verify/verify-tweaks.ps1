# ============================================================
# VERIFY TWEAKS — Health Check Report
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Checks every tweak from the guide and reports which are
# applied (green) vs default/missing (red).
#
# Does NOT change anything — read-only script.
# Run as Administrator for full results.
# ============================================================

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Verification Report"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GAMING OPTIMIZATION — HEALTH CHECK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$pass = 0
$fail = 0
$warn = 0

function Check($name, [scriptblock]$test) {
    try {
        $result = & $test
        if ($result -eq $true) {
            Write-Host "  [PASS] $name" -ForegroundColor Green
            $script:pass++
        } elseif ($result -eq "WARN") {
            Write-Host "  [WARN] $name" -ForegroundColor Yellow
            $script:warn++
        } else {
            Write-Host "  [FAIL] $name" -ForegroundColor Red
            $script:fail++
        }
    } catch {
        Write-Host "  [????] $name — Could not check: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ============================================================
# STEP 2: POWER PLAN
# ============================================================
Write-Host "--- Power Plan (Step 2) ---" -ForegroundColor White

Check "Ultimate Performance plan is active" {
    $active = powercfg /getactivescheme 2>&1
    $active -match "Ultimate Performance" -or $active -match "99999999-9999-9999-9999-999999999999"
}

Check "Hibernate is disabled" {
    $val = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue).HibernateEnabled
    $val -eq 0
}

Check "Fast Startup is disabled" {
    $val = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue).HiberbootEnabled
    $val -eq 0
}

Check "Power throttling is disabled" {
    $val = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -ErrorAction SilentlyContinue).PowerThrottlingOff
    $val -eq 1
}

# ============================================================
# STEP 4: SERVICES
# ============================================================
Write-Host ""
Write-Host "--- Services (Step 4) ---" -ForegroundColor White

$servicesToCheck = @(
    @("DiagTrack", "Connected User Experiences and Telemetry"),
    @("PhoneSvc", "Phone Service"),
    @("lfsvc", "Geolocation Service"),
    @("RetailDemo", "Retail Demo Service"),
    @("MapsBroker", "Downloaded Maps Manager"),
    @("Fax", "Fax Service")
)

foreach ($svc in $servicesToCheck) {
    Check "$($svc[1]) ($($svc[0])) is disabled" {
        $service = Get-Service -Name $svc[0] -ErrorAction SilentlyContinue
        if ($null -eq $service) { return $true }  # Not installed = good
        $service.StartType -eq "Disabled"
    }
}

# Optional services (warn if enabled, don't fail)
Check "Print Spooler (optional — disable if no printer)" {
    $service = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
    if ($service -and $service.StartType -ne "Disabled") { return "WARN" }
    return $true
}

Check "Windows Search (optional — disable if not needed)" {
    $service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    if ($service -and $service.StartType -ne "Disabled") { return "WARN" }
    return $true
}

# ============================================================
# STEP 5: REGISTRY TWEAKS
# ============================================================
Write-Host ""
Write-Host "--- Registry Tweaks (Step 5) ---" -ForegroundColor White

Check "MenuShowDelay = 0 (instant menus)" {
    $val = (Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -ErrorAction SilentlyContinue).MenuShowDelay
    $val -eq "0"
}

Check "MouseHoverTime = 10 (instant tooltips)" {
    $val = (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -ErrorAction SilentlyContinue).MouseHoverTime
    $val -eq "10"
}

Check "Startup delay disabled" {
    $val = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue).StartupDelayInMSec
    $val -eq 0
}

Check "Auto driver searching disabled" {
    $val = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -ErrorAction SilentlyContinue).SearchOrderConfig
    $val -eq 0
}

Check "Fullscreen optimizations disabled" {
    $val = (Get-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -ErrorAction SilentlyContinue).GameDVR_FSEBehaviorMode
    $val -eq 2
}

Check "Game CPU/GPU priority set to High" {
    $val = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -ErrorAction SilentlyContinue)."GPU Priority"
    $val -eq 8
}

Check "Network throttling disabled" {
    $val = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue).NetworkThrottlingIndex
    $val -eq 0xFFFFFFFF -or $val -eq 4294967295
}

Check "Game Bar / DVR disabled" {
    $val = (Get-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled
    $val -eq 0
}

Check "Game Mode still enabled" {
    $val = (Get-ItemProperty "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue).AutoGameModeEnabled
    $val -eq 1
}

Check "Mouse acceleration disabled" {
    $val = (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -ErrorAction SilentlyContinue).MouseSpeed
    $val -eq "0"
}

Check "Visual effects set to performance" {
    $val = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting
    $val -eq 3
}

Check "Advertising ID disabled" {
    $val = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    $val -eq 0
}

Check "Telemetry set to minimum" {
    $val = (Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue).AllowTelemetry
    $val -eq 0
}

Check "Accessibility shortcuts disabled (Sticky Keys)" {
    $val = (Get-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -ErrorAction SilentlyContinue).Flags
    $val -eq "2"
}

# ============================================================
# STEP 6: GPU
# ============================================================
Write-Host ""
Write-Host "--- GPU (Step 6) ---" -ForegroundColor White

$gpuDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue
foreach ($gpu in $gpuDevices) {
    Check "MSI mode enabled for $($gpu.FriendlyName)" {
        $id = $gpu.InstanceId
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $val = (Get-ItemProperty $regPath -Name "MSISupported" -ErrorAction SilentlyContinue).MSISupported
        $val -eq 1
    }
}

# ============================================================
# STEP 7: NETWORK
# ============================================================
Write-Host ""
Write-Host "--- Network (Step 7) ---" -ForegroundColor White

Check "TCP Timestamps disabled" {
    $out = netsh int tcp show global 2>&1
    $out -match "Timestamps\s*:\s*disabled"
}

Check "RSS enabled" {
    $out = netsh int tcp show global 2>&1
    $out -match "Receive-Side Scaling State\s*:\s*enabled"
}

Check "Nagle's Algorithm disabled (at least one adapter)" {
    $interfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    $found = $false
    Get-ChildItem $interfaces | ForEach-Object {
        $val = (Get-ItemProperty $_.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue).TCPNoDelay
        if ($val -eq 1) { $found = $true }
    }
    $found
}

Check "DNS set to optimized servers (Cloudflare or Google)" {
    $adapters = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $optimized = @("1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4")
    $found = $false
    foreach ($a in $adapters) {
        foreach ($dns in $a.ServerAddresses) {
            if ($dns -in $optimized) { $found = $true; break }
        }
        if ($found) { break }
    }
    if (-not $found) { return "WARN" }
    return $true
}

# ============================================================
# STEP 8: VBS / SECURITY
# ============================================================
Write-Host ""
Write-Host "--- Security vs Performance (Step 8) ---" -ForegroundColor White

Check "VBS disabled (better FPS, but reduced kernel security)" {
    $vbs = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
    if ($null -eq $vbs) { return "WARN" }
    # Report as WARN either way — this is a trade-off, not a binary good/bad
    if ($vbs.VirtualizationBasedSecurityStatus -eq 0) { return "WARN" }
    return $false
}

Check "HVCI disabled (better FPS, but reduced kernel security)" {
    $val = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    if ($null -eq $val) { return "WARN" }
    # Report as WARN — security trade-off, user should consciously decide
    if ($val -eq 0) { return "WARN" }
    return $false
}

# ============================================================
# BONUS CHECKS
# ============================================================
Write-Host ""
Write-Host "--- System Info ---" -ForegroundColor White

Check "Timer Resolution Service (STR) installed" {
    $service = Get-Service -Name "STR" -ErrorAction SilentlyContinue
    if ($null -eq $service) { return "WARN" }
    $service.Status -eq "Running"
}

Check "Windows Update auto-restart blocked" {
    $val = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue).NoAutoRebootWithLoggedOnUsers
    if ($null -eq $val) { return "WARN" }
    $val -eq 1
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  HEALTH CHECK RESULTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  PASS: $pass" -ForegroundColor Green
if ($warn -gt 0) {
    Write-Host "  WARN: $warn (optional tweaks not applied)" -ForegroundColor Yellow
}
if ($fail -gt 0) {
    Write-Host "  FAIL: $fail (tweaks missing or reverted)" -ForegroundColor Red
}
$total = $pass + $fail
if ($total -gt 0) {
    $pct = [math]::Round(($pass / $total) * 100)
    Write-Host ""
    Write-Host "  Optimization Score: $pct% ($pass/$total required tweaks applied)" -ForegroundColor White
}
Write-Host ""

if ($fail -gt 0) {
    Write-Host "  To fix FAIL items: re-run APPLY-EVERYTHING.ps1 as Administrator" -ForegroundColor Gray
    Write-Host "  Or apply individual tweaks from the relevant step folders." -ForegroundColor Gray
}
if ($warn -gt 0) {
    Write-Host "  WARN items are optional — apply them manually if desired." -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to exit"
