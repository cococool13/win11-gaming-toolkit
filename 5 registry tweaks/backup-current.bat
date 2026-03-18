@echo off
:: ============================================================
:: Backup Current Registry Values Before Applying Tweaks
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Run this BEFORE applying any .reg tweaks.
:: Saves current values so you can restore them later.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Backing Up Registry Keys (Pre-Tweak Snapshot)"
call :ui_admin_check

:: PowerShell instead of deprecated wmic (removed in Win11 24H2)
for /f %%I in ('powershell -Command "(Get-Date -Format ''yyyyMMdd_HHmm'')"') do set datetime=%%I
set BACKUP_DIR=%USERPROFILE%\Documents\RegTweakBackup_%datetime%
mkdir "%BACKUP_DIR%" 2>nul

echo   Saving to: %C_WHITE%%BACKUP_DIR%%C_R%
echo.

reg export "HKCU\Control Panel\Desktop" "%BACKUP_DIR%\Desktop.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[1/11] Desktop (MenuShowDelay)") else (call :ui_step_fail "[1/11] Desktop (MenuShowDelay)")

reg export "HKCU\Control Panel\Mouse" "%BACKUP_DIR%\Mouse.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[2/11] Mouse settings") else (call :ui_step_fail "[2/11] Mouse settings")

reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "%BACKUP_DIR%\Serialize.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[3/11] Explorer Serialize (Startup Delay)") else (call :ui_step_skip "[3/11] Explorer Serialize (Startup Delay)")

reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "%BACKUP_DIR%\DriverSearching.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[4/11] Driver Searching") else (call :ui_step_fail "[4/11] Driver Searching")

reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "%BACKUP_DIR%\Power.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[5/11] Power (Fast Startup)") else (call :ui_step_fail "[5/11] Power (Fast Startup)")

reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%BACKUP_DIR%\TcpipInterfaces.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[6/11] TCP/IP Interfaces (Nagle)") else (call :ui_step_fail "[6/11] TCP/IP Interfaces (Nagle)")

reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "%BACKUP_DIR%\SystemProfile.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[7/11] Game Scheduling and Network Throttling") else (call :ui_step_fail "[7/11] Game Scheduling and Network Throttling")

reg export "HKCU\System\GameConfigStore" "%BACKUP_DIR%\GameConfigStore.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[8/11] GameConfigStore (Fullscreen Optimizations)") else (call :ui_step_fail "[8/11] GameConfigStore (Fullscreen Optimizations)")

reg export "HKCU\Control Panel\Accessibility" "%BACKUP_DIR%\Accessibility.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[9/11] Accessibility settings") else (call :ui_step_skip "[9/11] Accessibility settings")

reg export "HKCU\AppEvents\Schemes" "%BACKUP_DIR%\SoundScheme.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[10/11] Sound scheme") else (call :ui_step_skip "[10/11] Sound scheme")

reg export "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "%BACKUP_DIR%\PowerThrottling.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[11/11] Power Throttling") else (call :ui_step_skip "[11/11] Power Throttling")

call :ui_summary "Backup complete"
echo   %C_DIM%To restore: double-click any .reg file in that folder.%C_R%
echo.
pause
