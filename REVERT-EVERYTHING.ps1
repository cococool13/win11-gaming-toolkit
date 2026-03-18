# ============================================================
# REVERT EVERYTHING — Undo All Gaming Optimizations
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Restores all changes made by APPLY-EVERYTHING.ps1 back to
# Windows 11 defaults.
#
# Must be run as Administrator. Requires reboot after completion.
# ============================================================

$Host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimization — Reverting All Tweaks"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  REVERT ALL GAMING OPTIMIZATIONS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---- Admin Check ----
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "This will UNDO all gaming optimizations and restore Windows defaults." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "Press Enter to continue"
Write-Host ""

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

# ============================================================
# POWER PLAN
# ============================================================
Write-Host ""
Write-Host "[1/7] Restoring Power Plan..." -ForegroundColor White

Run-Step "Activating Balanced power plan" {
    powercfg /setactive SCHEME_BALANCED 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "powercfg failed" }
}

Run-Step "Deleting custom power plan" {
    powercfg /delete 99999999-9999-9999-9999-999999999999 2>&1 | Out-Null
    # OK if this fails — plan may not exist
}

Run-Step "Re-enabling hibernate" {
    powercfg /hibernate on 2>&1 | Out-Null
}

Run-Step "Re-enabling Fast Startup" {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Removing power throttling override" {
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /f 2>&1 | Out-Null
}

# ============================================================
# WINDOWS SETTINGS
# ============================================================
Write-Host ""
Write-Host "[1.5/9] Restoring Windows Settings..." -ForegroundColor White

Run-Step "Re-enabling transparency" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Re-enabling background apps" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Restoring HAGS to default" {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Re-enabling notifications" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_TOASTS_ENABLED" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /f 2>&1 | Out-Null
}

# ============================================================
# SERVICES
# ============================================================
Write-Host ""
Write-Host "[2/9] Restoring Services..." -ForegroundColor White

$serviceDefaults = @(
    @("DiagTrack", "auto"),
    @("PhoneSvc", "demand"),
    @("lfsvc", "demand"),
    @("RetailDemo", "demand"),
    @("MapsBroker", "auto"),
    @("Fax", "demand")
)

foreach ($svc in $serviceDefaults) {
    Run-Step "Restoring $($svc[0]) to $($svc[1])" {
        sc.exe config $svc[0] start= $svc[1] 2>&1 | Out-Null
    }
}

# ============================================================
# REGISTRY TWEAKS
# ============================================================
Write-Host ""
Write-Host "[3/7] Reverting Registry Tweaks..." -ForegroundColor White

# Performance
Run-Step "MenuShowDelay = 400" { reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f 2>&1 | Out-Null }
Run-Step "MouseHoverTime = 400" { reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "400" /f 2>&1 | Out-Null }
Run-Step "Removing startup delay override" { reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /f 2>&1 | Out-Null }
Run-Step "Re-enabling auto driver searching" { reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 1 /f 2>&1 | Out-Null }
Run-Step "Re-enabling Fast Startup" { reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null }

# Fullscreen optimizations
Run-Step "Removing fullscreen optimization overrides" {
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /f 2>&1 | Out-Null
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /f 2>&1 | Out-Null
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f 2>&1 | Out-Null
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /f 2>&1 | Out-Null
}

# Game priority
Run-Step "Restoring game priority defaults" {
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 2 /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "Medium" /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "Normal" /f 2>&1 | Out-Null
}

Run-Step "Restoring network throttling defaults" {
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0x14 /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0x0a /f 2>&1 | Out-Null
}

# Game Bar / DVR
Run-Step "Re-enabling Game Bar/DVR" {
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

# Mouse
Run-Step "Restoring mouse acceleration default" {
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f 2>&1 | Out-Null
}

# Visual effects
Run-Step "Restoring visual effects to Let Windows choose" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "1" /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f 2>&1 | Out-Null
}

# Explorer
Run-Step "Restoring Explorer defaults" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 2 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v "FullPath" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
}

# Sound
Run-Step "Restoring default sound scheme" {
    reg add "HKCU\AppEvents\Schemes" /ve /t REG_SZ /d ".Default" /f 2>&1 | Out-Null
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
}

# Accessibility
Run-Step "Restoring accessibility shortcut defaults" {
    reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "510" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "62" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "126" /f 2>&1 | Out-Null
}

# Privacy
Run-Step "Restoring privacy defaults" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Allow" /f 2>&1 | Out-Null
}

# ============================================================
# STARTUP BLOAT
# ============================================================
Write-Host ""
Write-Host "[3.5/9] Restoring Startup Apps..." -ForegroundColor White

Run-Step "Re-enabling OneDrive startup" {
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /f 2>&1 | Out-Null
}

Run-Step "Re-enabling Teams startup" {
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\common\officeupdate" /v "preventteamsinstall" /f 2>&1 | Out-Null
}

Run-Step "Re-enabling Widgets" {
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Re-enabling Cortana" {
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /f 2>&1 | Out-Null
}

Run-Step "Re-enabling Copilot" {
    reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f 2>&1 | Out-Null
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f 2>&1 | Out-Null
}

# ============================================================
# WINDOWS CUSTOMIZATION
# ============================================================
Write-Host ""
Write-Host "[3.7/9] Reverting Windows Customization..." -ForegroundColor White

Run-Step "Restoring Win11 context menu" {
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>&1 | Out-Null
}

Run-Step "Re-enabling Bing search" {
    reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Restoring taskbar defaults" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Re-enabling lock screen tips" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Re-enabling suggested content" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

Run-Step "Restoring light mode" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}

# ============================================================
# NETWORK
# ============================================================
Write-Host ""
Write-Host "[4/9] Reverting Network Settings..." -ForegroundColor White

Run-Step "Restoring TCP timestamps" { netsh int tcp set global timestamps=enabled 2>&1 | Out-Null }

Run-Step "Re-enabling Large Send Offload" {
    Get-NetAdapter | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
    } 2>$null
}

Run-Step "Removing Nagle overrides" {
    $interfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $interfaces | ForEach-Object {
        Remove-ItemProperty $_.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty $_.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
    }
}

Run-Step "Resetting DNS to automatic (DHCP)" {
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
}

# ============================================================
# WINDOWS UPDATE MANAGEMENT
# ============================================================
Write-Host ""
Write-Host "[4.5/7] Reverting Windows Update settings..." -ForegroundColor White

Run-Step "Re-enabling auto-restart for updates" {
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (Test-Path $auPath) {
        Set-ItemProperty $auPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty $auPath -Name "AUOptions" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    }
}

Run-Step "Re-enabling Windows Update services" {
    sc.exe config wuauserv start= demand 2>&1 | Out-Null
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    sc.exe config UsoSvc start= demand 2>&1 | Out-Null
    Start-Service -Name UsoSvc -ErrorAction SilentlyContinue
    sc.exe config DoSvc start= auto 2>&1 | Out-Null
    Start-Service -Name DoSvc -ErrorAction SilentlyContinue
    $medicPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
    if (Test-Path $medicPath) {
        Set-ItemProperty $medicPath -Name "Start" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

Run-Step "Resetting active hours to default" {
    $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (Test-Path $uxPath) {
        Set-ItemProperty $uxPath -Name "ActiveHoursStart" -Value 8 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty $uxPath -Name "ActiveHoursEnd" -Value 17 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================
# GPU MSI MODE
# ============================================================
Write-Host ""
Write-Host "[5/7] Reverting GPU MSI Mode..." -ForegroundColor White

Run-Step "Removing MSI mode overrides" {
    $gpuDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue
    foreach ($gpu in $gpuDevices) {
        $id = $gpu.InstanceId
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        Remove-ItemProperty -Path $regPath -Name "MSISupported" -ErrorAction SilentlyContinue
    }
}

# ============================================================
# TIMER RESOLUTION SERVICE
# ============================================================
Write-Host ""
Write-Host "[6/7] Removing Timer Resolution Service (if installed)..." -ForegroundColor White

Run-Step "Stopping and removing STR service" {
    if (Get-Service -Name "STR" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "STR" -Force -ErrorAction SilentlyContinue
        sc.exe delete "STR" 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
    Remove-Item "$env:SystemRoot\SetTimerResolutionService.exe" -Force -ErrorAction SilentlyContinue
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /f 2>&1 | Out-Null
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  REVERT COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Succeeded: $succeeded operations" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed:    $failed operations (check messages above)" -ForegroundColor Red
}
Write-Host ""
Write-Host "  NOT reverted (must be done manually):" -ForegroundColor Yellow
Write-Host "    - Removed apps: reinstall from Microsoft Store" -ForegroundColor Gray
Write-Host "    - VBS/HVCI: run '8 security vs performance\enable-vbs.bat'" -ForegroundColor Gray
Write-Host "    - This PC desktop icon: remove manually if unwanted" -ForegroundColor Gray
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Yellow
Write-Host "  REBOOT REQUIRED for all changes to take effect" -ForegroundColor Yellow
Write-Host "  ============================================" -ForegroundColor Yellow
Write-Host ""

$reboot = Read-Host "Reboot now? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host "Rebooting in 5 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
} else {
    Write-Host "Remember to reboot!" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
}
