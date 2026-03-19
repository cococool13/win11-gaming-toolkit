# ============================================================
# REVERT EVERYTHING — Undo Gaming Optimizations
# Windows 11 Gaming Optimization Guide
# ============================================================
#
# Restores everything it can from the manifest-backed state capture.
# Falls back to default-based restoration for the broader registry pack.
#
# Must be run as Administrator. Requires reboot after completion.
# ============================================================

. "$PSScriptRoot\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimization — Revert Everything"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  REVERT ALL GAMING OPTIMIZATIONS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "This will UNDO the aggressive full-stack optimization pass." -ForegroundColor Yellow
Write-Host "Manifest-backed state will be restored first where available." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "Press Enter to continue"
Write-Host ""

$state = Initialize-ToolkitState
$manifestPath = Get-ToolkitManifestPath
$succeeded = 0
$failed = 0

function Run-Step {
    param([string]$Description, [scriptblock]$Action)
    Write-Host "  $Description..." -NoNewline
    try {
        & $Action
        Write-Host " Done" -ForegroundColor Green
        $script:succeeded++
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

function Restore-TrackedRegistryStep {
    param([string]$Id)
    Restore-ToolkitRegistryValue -Id $Id | Out-Null
}

# ============================================================
# STEP 1: POWER PLAN
# ============================================================
Write-Host "[1/10] Restoring Power Plan..." -ForegroundColor White

Run-Step "Activating Balanced power plan" {
    powercfg /setactive SCHEME_BALANCED 2>&1 | Out-Null
}
Run-Step "Deleting custom power plan" {
    powercfg /delete 99999999-9999-9999-9999-999999999999 2>&1 | Out-Null
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
# STEP 2: WINDOWS SETTINGS
# ============================================================
Write-Host ""
Write-Host "[2/10] Restoring Windows Settings..." -ForegroundColor White

Run-Step "Transparency effects" { Restore-TrackedRegistryStep "reg:EnableTransparency" }
Run-Step "Background apps" {
    Restore-TrackedRegistryStep "reg:GlobalUserDisabled"
    Restore-TrackedRegistryStep "reg:BackgroundAppGlobalToggle"
}
Run-Step "HAGS" { Restore-TrackedRegistryStep "reg:HwSchMode" }
Run-Step "Notifications" {
    Restore-TrackedRegistryStep "reg:ToastsEnabled"
    Restore-TrackedRegistryStep "reg:NotificationSound"
}

# ============================================================
# STEP 3: SERVICES
# ============================================================
Write-Host ""
Write-Host "[3/10] Restoring Services..." -ForegroundColor White

foreach ($svc in @("DiagTrack", "PhoneSvc", "lfsvc", "RetailDemo", "MapsBroker", "Fax", "Spooler", "WSearch")) {
    Run-Step "Restoring $svc" {
        if (-not (Restore-ToolkitServiceStartMode -Name $svc)) {
            if ($svc -in @("DiagTrack", "Spooler", "WSearch", "MapsBroker")) {
                sc.exe config $svc start= auto 2>&1 | Out-Null
            } else {
                sc.exe config $svc start= demand 2>&1 | Out-Null
            }
        }
    }
}

# ============================================================
# STEP 4: REGISTRY TWEAKS
# ============================================================
Write-Host ""
Write-Host "[4/10] Reverting Registry Tweaks..." -ForegroundColor White

Run-Step "MenuShowDelay = 400" { reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f 2>&1 | Out-Null }
Run-Step "MouseHoverTime = 400" { reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "400" /f 2>&1 | Out-Null }
Run-Step "Removing startup delay override" { reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /f 2>&1 | Out-Null }
Run-Step "Re-enabling auto driver searching" { reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 1 /f 2>&1 | Out-Null }
Run-Step "Removing fullscreen optimization overrides" {
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /f 2>&1 | Out-Null
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /f 2>&1 | Out-Null
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f 2>&1 | Out-Null
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /f 2>&1 | Out-Null
}
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
Run-Step "Re-enabling Game Bar / DVR" {
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}
Run-Step "Restoring mouse acceleration" {
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f 2>&1 | Out-Null
}
Run-Step "Restoring visual effects defaults" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "1" /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f 2>&1 | Out-Null
}
Run-Step "Restoring Explorer defaults" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 2 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v "FullPath" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
}
Run-Step "Restoring default sound scheme" {
    reg add "HKCU\AppEvents\Schemes" /ve /t REG_SZ /d ".Default" /f 2>&1 | Out-Null
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
}
Run-Step "Restoring accessibility defaults" {
    reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "510" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "62" /f 2>&1 | Out-Null
    reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "126" /f 2>&1 | Out-Null
}
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
# STEP 5: STARTUP
# ============================================================
Write-Host ""
Write-Host "[5/10] Restoring Startup Apps..." -ForegroundColor White

Run-Step "Re-enabling OneDrive startup" { reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /f 2>&1 | Out-Null }
Run-Step "Re-enabling Teams startup" { reg delete "HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\common\officeupdate" /v "preventteamsinstall" /f 2>&1 | Out-Null }
Run-Step "Re-enabling Widgets" {
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
}
Run-Step "Re-enabling Cortana" { reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /f 2>&1 | Out-Null }
Run-Step "Re-enabling Copilot" {
    reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f 2>&1 | Out-Null
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f 2>&1 | Out-Null
}

# ============================================================
# STEP 6: GPU MSI MODE
# ============================================================
Write-Host ""
Write-Host "[6/10] Reverting GPU MSI Mode..." -ForegroundColor White

Run-Step "Removing MSI mode overrides" {
    $gpuDevices = @(Get-PnpDevice -Class Display -ErrorAction SilentlyContinue)
    foreach ($gpu in $gpuDevices) {
        $id = $gpu.InstanceId
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        Remove-ItemProperty -Path $regPath -Name "MSISupported" -ErrorAction SilentlyContinue
    }
}

# ============================================================
# STEP 6.5: GPU HIDDEN SETTINGS
# ============================================================
Write-Host ""
Write-Host "[6.5/10] Reverting GPU Performance Settings..." -ForegroundColor White

$gpuSteps = @("gpu-nvidia-settings", "gpu-amd-settings", "gpu-intel-settings")
foreach ($gpuStep in $gpuSteps) {
    $stepStatus = Get-ToolkitRecordedStatus -Key $gpuStep
    if ($stepStatus -eq "applied") {
        Write-Host "  Reverting $gpuStep..." -ForegroundColor Gray
        $regKeys = $state.registry
        $properties = if ($regKeys -is [hashtable]) {
            $regKeys.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Name = $_.Key; Value = $_.Value } }
        } else {
            $regKeys.PSObject.Properties
        }
        foreach ($prop in $properties) {
            if ($prop.Value.step -eq $gpuStep) {
                Run-Step "Reverting $($prop.Name)" {
                    Restore-ToolkitRegistryValue -Id $prop.Name | Out-Null
                }
            }
        }
    }
}

# Restore GPU-related services disabled during driver install
foreach ($svc in @("NvTelemetryContainer", "amdfendr", "amdfendrmgr", "Intel(R) Computing Improvement Program")) {
    $svcEntry = $null
    if (Test-ToolkitMapHasKey -Map $state.services -Key $svc) {
        Run-Step "Restoring $svc" {
            Restore-ToolkitServiceStartMode -Name $svc | Out-Null
        }
    }
}

# ============================================================
# STEP 7: NETWORK
# ============================================================
Write-Host ""
Write-Host "[7/10] Reverting Network..." -ForegroundColor White

Run-Step "Restoring TCP timestamps" { netsh int tcp set global timestamps=enabled 2>&1 | Out-Null }
Run-Step "Re-enabling Large Send Offload" {
    Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
    }
}
Run-Step "Removing Nagle overrides" {
    $interfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $interfaces | ForEach-Object {
        Remove-ItemProperty $_.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty $_.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
    }
}
Run-Step "Restoring DNS" {
    if (-not (Restore-ToolkitDnsServers)) {
        Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue
        }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
    }
}

# ============================================================
# STEP 8: WINDOWS UPDATE + SECURITY
# ============================================================
Write-Host ""
Write-Host "[8/10] Reverting Windows Update + Security Trade-offs..." -ForegroundColor White

Run-Step "Restoring Windows Update policies" {
    Restore-TrackedRegistryStep "reg:NoAutoRebootWithLoggedOnUsers"
    Restore-TrackedRegistryStep "reg:AUOptions"
    Restore-TrackedRegistryStep "reg:NoAutoUpdate"
    Restore-TrackedRegistryStep "reg:ActiveHoursStart"
    Restore-TrackedRegistryStep "reg:ActiveHoursEnd"
    Restore-TrackedRegistryStep "reg:IsActiveHoursEnabled"
    Restore-TrackedRegistryStep "reg:WaaSMedicSvcStart"
}
Run-Step "Re-enabling Windows Update services" {
    foreach ($svc in @("wuauserv", "UsoSvc", "DoSvc")) {
        if (-not (Restore-ToolkitServiceStartMode -Name $svc)) {
            if ($svc -eq "DoSvc") {
                sc.exe config $svc start= auto 2>&1 | Out-Null
            } else {
                sc.exe config $svc start= demand 2>&1 | Out-Null
            }
        }
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }
}
Run-Step "Restoring VBS / HVCI / LSA" {
    Restore-TrackedRegistryStep "reg:HVCIEnabled"
    Restore-TrackedRegistryStep "reg:EnableVBS"
    Restore-TrackedRegistryStep "reg:RunAsPPL"
    Restore-TrackedRegistryStep "reg:LsaCfgFlags"
}

# ============================================================
# STEP 9: WINDOWS CUSTOMIZATION
# ============================================================
Write-Host ""
Write-Host "[9/10] Reverting Windows Customization..." -ForegroundColor White

Run-Step "Restoring Win11 context menu" { reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>&1 | Out-Null }
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
Run-Step "Restart Explorer" {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
}

# ============================================================
# STEP 10: DEFENDER + TIMER
# ============================================================
Write-Host ""
Write-Host "[10/10] Reverting Defender + Timer Resolution..." -ForegroundColor White

Run-Step "Removing toolkit-added Defender exclusions" {
    Restore-ToolkitDefenderExclusions | Out-Null
}
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
    Write-Host "  Failed:    $failed operations" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Manual follow-up still required for:" -ForegroundColor Yellow
Write-Host "    - Removed apps: reinstall from Microsoft Store / winget" -ForegroundColor Gray
Write-Host "    - Some broad registry tweaks still use default-based rollback" -ForegroundColor Gray
Write-Host "    - Any external tools run after APPLY-EVERYTHING" -ForegroundColor Gray
Write-Host "  Manifest used:" -ForegroundColor Gray
Write-Host "    $manifestPath" -ForegroundColor White
Write-Host ""
Write-Host "  REBOOT REQUIRED for all changes to take full effect" -ForegroundColor Yellow
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
