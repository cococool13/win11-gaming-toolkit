# ============================================================
# APPLY EVERYTHING — One-Click Windows 11 Optimization
# ============================================================
#
# Applies all optimizations in one run. No manual steps needed.
#
# What it does:
#   1. Creates a system restore point + registry backup
#   2. Enables Ultimate Performance power plan
#   3. Automates Windows Settings (transparency, background apps, HAGS)
#   4. Disables unnecessary services
#   5. Applies registry tweaks (performance, privacy, visual)
#   6. Disables startup bloat (OneDrive, Teams, Widgets)
#   7. Enables MSI mode for GPUs
#   8. Optimizes network settings + DNS
#   9. Customizes Windows (classic context menu, clean taskbar, dark mode)
#   10. Removes bloatware apps
#   11. Cleans temp files
#
# NOT included (optional, run separately):
#   - VBS/HVCI disable (security trade-off — see 8 security vs performance/)
#   - BIOS tweaks (XMP, ReBAR — see BIOS-CHECKLIST.md)
#   - Timer Resolution Service
#   - GPU driver clean install (DDU)
#   - C++ Runtimes / DirectX install
#
# Run as Administrator. Reboot after.
# Undo: REVERT-EVERYTHING.ps1
# ============================================================

$Host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimization — Applying All Tweaks"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  WINDOWS 11 OPTIMIZATION" -ForegroundColor Cyan
Write-Host "  Applying All Tweaks" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---- Admin Check ----
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click the script > 'Run with PowerShell' (as Admin)" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ---- Confirmation ----
Write-Host "This will optimize Windows 11 for performance." -ForegroundColor Yellow
Write-Host "A restore point is created first so you can revert." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "Press Enter to continue"
Write-Host ""

$startTime = Get-Date
$succeeded = 0
$failed = 0

function Run-Step($description, [scriptblock]$action) {
    Write-Host "  $description..." -NoNewline
    try {
        & $action
        Write-Host " Done" -ForegroundColor Green
        $script:succeeded++
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

# Helper: run reg add and throw on failure
function Reg-Add {
    param([string[]]$Arguments)
    $output = & reg add @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "reg add failed: $output" }
}

# ============================================================
# STEP 1: BACKUP
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 1: Creating Backup" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "Creating system restore point" {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Before Gaming Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
}

# Registry backup (non-critical — don't count failures here)
$backupDir = "$env:USERPROFILE\Documents\GamingOptBackup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "  Backing up registry to: $backupDir" -ForegroundColor Gray

$regKeys = @(
    @("HKCU\Control Panel\Desktop", "Desktop.reg"),
    @("HKCU\Control Panel\Mouse", "Mouse.reg"),
    @("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power", "Power.reg"),
    @("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching", "DriverSearching.reg"),
    @("HKCU\System\GameConfigStore", "GameConfigStore.reg"),
    @("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "SystemProfile.reg"),
    @("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "ExplorerAdvanced.reg"),
    @("HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo", "AdvertisingInfo.reg")
)
$backupCount = 0
foreach ($rk in $regKeys) {
    $output = reg export $rk[0] "$backupDir\$($rk[1])" /y 2>&1
    if ($LASTEXITCODE -eq 0) { $backupCount++ }
}
Write-Host "  Registry backup complete ($backupCount/$($regKeys.Count) keys exported)." -ForegroundColor Green
Write-Host ""

# ============================================================
# STEP 2: POWER PLAN
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 2: Power Plan" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

$planGuid = "99999999-9999-9999-9999-999999999999"

Run-Step "Activating Ultimate Performance plan" {
    $output = cmd /c "powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $planGuid 2>&1"
    $output = cmd /c "powercfg /SETACTIVE $planGuid 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "powercfg failed" }
}

# Detailed power settings (best-effort — don't fail the whole script)
function Set-PowerIdx($sg, $s, $v) {
    powercfg /setacvalueindex $planGuid $sg $s $v 2>&1 | Out-Null
    powercfg /setdcvalueindex $planGuid $sg $s $v 2>&1 | Out-Null
}

Run-Step "Configuring detailed power settings" {
    # Hard disk: never off
    Set-PowerIdx "0012ee47-9041-4b5d-9b77-535fba8b1442" "6738e2c4-e8a5-4a42-b16a-e040e769756e" "0x00000000"
    # Wireless: max perf
    Set-PowerIdx "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1" "12bbebe6-58d6-4636-95bb-3217ef867c1a" "000"
    # Sleep: never
    Set-PowerIdx "238c9fa8-0aad-41ed-83f4-97be242c8f20" "29f6c1db-86da-48c5-9fdb-f2b67b1f44da" "0x00000000"
    # Hybrid sleep: off
    Set-PowerIdx "238c9fa8-0aad-41ed-83f4-97be242c8f20" "94ac6d29-73ce-41a6-809f-6363ba21b47e" "000"
    # Hibernate: off
    Set-PowerIdx "238c9fa8-0aad-41ed-83f4-97be242c8f20" "9d7815a6-7ee4-497e-8888-515a05f02364" "0x00000000"
    powercfg /hibernate off 2>&1 | Out-Null
    # USB selective suspend: off
    Set-PowerIdx "2a737441-1930-4402-8d77-b2bebba308a3" "48e6b7a6-50f5-4782-a5d4-53bb8f07e226" "000"
    # PCI-E link state: off
    Set-PowerIdx "501a4d13-42af-4429-9fd1-a8218c268e20" "ee12f906-d277-404b-b6da-e5fa1a576df5" "000"
    # CPU 100% min/max
    Set-PowerIdx "54533251-82be-4824-96c1-47b60b740d00" "893dee8e-2bef-41e0-89c6-b55d0929964c" "0x00000064"
    Set-PowerIdx "54533251-82be-4824-96c1-47b60b740d00" "bc5038f7-23e0-4960-96da-33abaf5935ec" "0x00000064"
    # Active cooling
    Set-PowerIdx "54533251-82be-4824-96c1-47b60b740d00" "94d3a615-a899-4ac5-ae2b-e4d8f634367f" "001"
    # Unpark all cores
    reg add "HKLM\System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "Attributes" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    Set-PowerIdx "54533251-82be-4824-96c1-47b60b740d00" "0cc5b647-c1df-4637-891a-dec35c318583" "0x00000064"
    Set-PowerIdx "54533251-82be-4824-96c1-47b60b740d00" "ea062031-0e34-4ff1-9b6d-eb1059334028" "0x00000064"
    # Display timeout: 10 min
    Set-PowerIdx "7516b95f-f776-4464-8c53-06167f40cc99" "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" "600"
    # Adaptive brightness: off
    Set-PowerIdx "7516b95f-f776-4464-8c53-06167f40cc99" "fbd9aa66-9553-4097-ba44-ed6e9d65eab8" "000"
}
Write-Host ""

# ============================================================
# STEP 3: WINDOWS SETTINGS (automated)
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 3: Windows Settings" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "Disable transparency effects" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f
}

Run-Step "Disable background apps" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f
}

Run-Step "Enable Hardware Accelerated GPU Scheduling" {
    Reg-Add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f
}

Run-Step "Suppress notifications (Do Not Disturb)" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_TOASTS_ENABLED" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /t REG_DWORD /d 0 /f
}

Write-Host ""

# ============================================================
# STEP 4: DISABLE SERVICES
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 4: Disabling Unnecessary Services" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

$services = @("DiagTrack", "PhoneSvc", "lfsvc", "RetailDemo", "MapsBroker", "Fax")

foreach ($name in $services) {
    Run-Step "Disabling $name" {
        $output = sc.exe config $name start= disabled 2>&1
        if ($LASTEXITCODE -ne 0) { throw "sc.exe config failed: $output" }
        sc.exe stop $name 2>&1 | Out-Null  # OK if stop fails (already stopped)
    }
}

Write-Host "  Note: Print Spooler and Windows Search NOT disabled" -ForegroundColor Gray
Write-Host "  (disable manually if you don't use them)" -ForegroundColor Gray
Write-Host ""

# ============================================================
# STEP 5: REGISTRY TWEAKS
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 5: Applying Registry Tweaks" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

# Performance tweaks
Run-Step "MenuShowDelay = 0 (instant menus)" {
    Reg-Add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
}

Run-Step "MouseHoverTime = 10 (instant tooltips)" {
    Reg-Add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "10" /f
}

Run-Step "Startup delay disabled" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f
}

Run-Step "Auto driver searching disabled" {
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f
}

Run-Step "Fast Startup disabled" {
    Reg-Add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f
}

Run-Step "Fullscreen optimizations disabled" {
    Reg-Add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f
    Reg-Add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f
    Reg-Add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f
    Reg-Add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f
}

Run-Step "Game CPU/GPU priority increased" {
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
}

Run-Step "Network throttling disabled" {
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xFFFFFFFF /f
}

Run-Step "Power throttling disabled" {
    Reg-Add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f
}

# Game Bar / DVR
Run-Step "Game Bar/DVR disabled (Game Mode stays ON)" {
    Reg-Add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f
}

# Mouse acceleration off
Run-Step "Mouse acceleration disabled" {
    Reg-Add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f
    Reg-Add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f
    Reg-Add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f
}

# Visual effects
Run-Step "Visual effects optimized for performance" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f
    Reg-Add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038012000000" /f
    Reg-Add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f
    Reg-Add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f
    Reg-Add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f
}

# Explorer tweaks
Run-Step "Explorer tweaks (show extensions, full path, etc.)" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v "FullPath" /t REG_DWORD /d 1 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f
}

# Sound scheme none
Run-Step "Sound scheme set to None" {
    Reg-Add "HKCU\AppEvents\Schemes" /ve /t REG_SZ /d ".None" /f
    Reg-Add "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /t REG_DWORD /d 1 /f
    # Silence individual sounds
    $soundKeys = @(".Default", "DeviceConnect", "DeviceDisconnect", "DeviceFail", "MailBeep", "Notification.Default", "SystemAsterisk", "SystemExclamation", "SystemNotification", "WindowsUAC")
    foreach ($sk in $soundKeys) {
        Reg-Add "HKCU\AppEvents\Schemes\Apps\.Default\$sk\.Current" /ve /t REG_SZ /d "" /f
    }
}

# Privacy / Telemetry
Run-Step "Privacy & telemetry disabled" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f
    Reg-Add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f
    Reg-Add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f
    Reg-Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f
}

# Autoplay off
Run-Step "Autoplay disabled" {
    Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d 1 /f
}

# Accessibility shortcuts off
Run-Step "Accessibility shortcuts disabled (Sticky/Toggle/Filter keys)" {
    Reg-Add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "2" /f
    Reg-Add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "34" /f
    Reg-Add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "2" /f
}

Write-Host ""

# ============================================================
# STEP 6: STARTUP OPTIMIZATION
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 6: Disabling Startup Bloat" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "Disable OneDrive autostart" {
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f 2>&1 | Out-Null
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f 2>&1 | Out-Null
    # Prevent OneDrive from reinstalling itself
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f
}

Run-Step "Disable Teams autostart" {
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "com.squirrel.Teams.Teams" /f 2>&1 | Out-Null
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\common\officeupdate" /v "preventteamsinstall" /t REG_DWORD /d 1 /f
}

Run-Step "Disable Widgets" {
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
}

Run-Step "Disable Cortana" {
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
}

Run-Step "Disable Copilot" {
    Reg-Add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f
    Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f
}

Write-Host ""

# ============================================================
# STEP 7: GPU — MSI MODE
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 7: GPU — Enabling MSI Mode" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

$gpuDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue
foreach ($gpu in $gpuDevices) {
    Run-Step "MSI Mode for $($gpu.FriendlyName)" {
        $id = $gpu.InstanceId
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "MSISupported" -Value 1 -Type DWord -Force -ErrorAction Stop
    }
}
Write-Host ""

# ============================================================
# STEP 8: NETWORK
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 8: Network Optimization" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "TCP Auto-Tuning: normal" {
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
}

Run-Step "RSS: enabled" {
    netsh int tcp set global rss=enabled 2>&1 | Out-Null
}

Run-Step "TCP Timestamps: disabled" {
    netsh int tcp set global timestamps=disabled 2>&1 | Out-Null
}

Run-Step "Large Send Offload: disabled" {
    Get-NetAdapter | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload*" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    }
}

Run-Step "Nagle's Algorithm: disabled (per active adapter)" {
    $interfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $interfaces | ForEach-Object {
        $ip = (Get-ItemProperty $_.PSPath -Name "DhcpIPAddress" -ErrorAction SilentlyContinue).DhcpIPAddress
        if ($ip -and $ip -ne "0.0.0.0") {
            Set-ItemProperty $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force
            Set-ItemProperty $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force
        }
    }
}

Write-Host ""
Write-Host "  Choose DNS provider:" -ForegroundColor Cyan
Write-Host "    1. Cloudflare (1.1.1.1) — fast, privacy-focused [default]" -ForegroundColor Gray
Write-Host "    2. Google (8.8.8.8) — reliable, widely used" -ForegroundColor Gray
Write-Host "    3. Skip — keep current DNS settings" -ForegroundColor Gray
$dnsChoice = Read-Host "  Enter choice (1/2/3) [1]"
if ([string]::IsNullOrWhiteSpace($dnsChoice)) { $dnsChoice = "1" }

if ($dnsChoice -ne "3") {
    $dnsServers = if ($dnsChoice -eq "2") {
        @("8.8.8.8","8.8.4.4","2001:4860:4860::8888","2001:4860:4860::8844")
    } else {
        @("1.1.1.1","1.0.0.1","2606:4700:4700::1111","2606:4700:4700::1001")
    }
    $dnsName = if ($dnsChoice -eq "2") { "Google" } else { "Cloudflare" }
    Run-Step "DNS: $dnsName on active adapters" {
        Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses $dnsServers -ErrorAction SilentlyContinue
        }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  Skipping DNS changes." -ForegroundColor Gray
}
Write-Host ""

# ============================================================
# STEP 8.5: WINDOWS UPDATE MANAGEMENT
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 8.5: Windows Update Management" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "Disable auto-restart for updates" {
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
    Set-ItemProperty $auPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force
    Set-ItemProperty $auPath -Name "AUOptions" -Value 3 -Type DWord -Force
}

Run-Step "Set active hours 8AM-2AM" {
    $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (-not (Test-Path $uxPath)) { New-Item -Path $uxPath -Force | Out-Null }
    Set-ItemProperty $uxPath -Name "ActiveHoursStart" -Value 8 -Type DWord -Force
    Set-ItemProperty $uxPath -Name "ActiveHoursEnd" -Value 2 -Type DWord -Force
    Set-ItemProperty $uxPath -Name "IsActiveHoursEnabled" -Value 1 -Type DWord -Force
}
Write-Host ""

# ============================================================
# STEP 9: WINDOWS CUSTOMIZATION
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 9: Windows Customization" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "Restore classic right-click menu (Win10 style)" {
    Reg-Add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f
}

Run-Step "Disable Bing/web results in Start Menu search" {
    Reg-Add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f
}

Run-Step "Clean taskbar (hide Search, Task View, Chat)" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f
}

Run-Step "Disable lock screen tips and ads" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f
}

Run-Step "Disable suggested content in Settings and Start" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 0 /f
}

Run-Step "Show This PC on desktop" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f
}

Run-Step "Enable dark mode" {
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
    Reg-Add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
}

Write-Host ""

# ============================================================
# STEP 10: DEBLOAT
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 10: Removing Bloatware Apps" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

$appsToRemove = @(
    "Clipchamp.Clipchamp", "Microsoft.BingNews", "Microsoft.BingWeather",
    "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MicrosoftStickyNotes",
    "Microsoft.People", "Microsoft.PowerAutomateDesktop", "Microsoft.Todos",
    "Microsoft.WindowsAlarms", "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps", "Microsoft.WindowsSoundRecorder",
    "Microsoft.YourPhone", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
    "MicrosoftCorporationII.QuickAssist", "MicrosoftTeams",
    "Microsoft.549981C3F5F10", "Microsoft.OutlookForWindows"
)

$removed = 0
$removeFailed = 0
foreach ($app in $appsToRemove) {
    $pkg = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
    if ($pkg) {
        try {
            $pkg | Remove-AppxPackage -ErrorAction Stop
            $removed++
        } catch {
            $removeFailed++
        }
    }
    # Also remove provisioned (best-effort)
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq $app } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue 2>&1 | Out-Null
}
Write-Host "  Removed $removed bloatware apps." -ForegroundColor Green
if ($removeFailed -gt 0) {
    Write-Host "  $removeFailed apps failed to remove (may require manual uninstall)." -ForegroundColor Yellow
}
Write-Host ""

# ============================================================
# STEP 11: CLEANUP
# ============================================================
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  STEP 11: Cleaning Temp Files" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor DarkGray

Run-Step "Clearing user temp" {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}

Run-Step "Clearing Windows temp" {
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
}

Run-Step "Clearing Windows Update cache" {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
}

Run-Step "Clearing shader cache" {
    Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

Run-Step "Removing leftover folders" {
    Remove-Item "$env:SystemDrive\inetpub" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemDrive\PerfLogs" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""

# ============================================================
# SUMMARY
# ============================================================
$elapsed = (Get-Date) - $startTime

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Succeeded: $succeeded operations" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed:    $failed operations (check messages above)" -ForegroundColor Red
}
Write-Host "  Completed in $([math]::Round($elapsed.TotalSeconds)) seconds." -ForegroundColor Gray
Write-Host ""
Write-Host "  Registry backup saved to:" -ForegroundColor Gray
Write-Host "    $backupDir" -ForegroundColor White
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Yellow
Write-Host "  REBOOT REQUIRED for all changes to take effect" -ForegroundColor Yellow
Write-Host "  ============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Optional (run separately if you want them):" -ForegroundColor Gray
Write-Host "    - VBS/HVCI:   8 security vs performance\disable-vbs.bat" -ForegroundColor Gray
Write-Host "    - BIOS:       See BIOS-CHECKLIST.md (XMP, ReBAR)" -ForegroundColor Gray
Write-Host "    - Timer:      5 registry tweaks\individual\install-timer-resolution-service.ps1" -ForegroundColor Gray
Write-Host "    - Runtimes:   0 prerequisites\install-runtimes.ps1" -ForegroundColor Gray
Write-Host "    - GPU driver: See 6 gpu\ READMEs" -ForegroundColor Gray
Write-Host "    - WinUtil:    9 cleanup\chris-titus-winutil.bat" -ForegroundColor Gray
Write-Host "    - Verify:     10 verify\verify-tweaks.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  To revert everything:" -ForegroundColor Gray
Write-Host "    Run REVERT-EVERYTHING.ps1 as Administrator" -ForegroundColor White
Write-Host ""

$reboot = Read-Host "Reboot now? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host "Rebooting in 5 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
} else {
    Write-Host "Remember to reboot before gaming!" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
}
