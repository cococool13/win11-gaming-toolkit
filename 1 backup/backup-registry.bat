@echo off
:: ============================================================
:: Backup Registry Keys (Gaming Optimization)
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Exports all registry keys that will be modified by this guide.
:: The backup is saved to a timestamped folder in Documents.
:: Must be run as Administrator.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Backing Up Registry Keys"
call :ui_admin_check

:: Create backup folder with timestamp (PowerShell instead of deprecated wmic)
for /f %%I in ('powershell -Command "(Get-Date -Format ''yyyyMMdd_HHmm'')"') do set datetime=%%I
set BACKUP_DIR=%USERPROFILE%\Documents\RegistryBackup_%datetime%
mkdir "%BACKUP_DIR%" 2>nul

echo   Saving backups to: %C_WHITE%%BACKUP_DIR%%C_R%
echo.

reg export "HKCU\Control Panel\Desktop" "%BACKUP_DIR%\Desktop.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[1/7] Explorer settings") else (call :ui_step_fail "[1/7] Explorer settings")

reg export "HKCU\Control Panel\Mouse" "%BACKUP_DIR%\Mouse.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[2/7] Mouse settings") else (call :ui_step_fail "[2/7] Mouse settings")

reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "%BACKUP_DIR%\Serialize.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[3/7] Serialize (startup delay)") else (call :ui_step_skip "[3/7] Serialize (startup delay)")

reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "%BACKUP_DIR%\DriverSearching.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[4/7] Driver Searching settings") else (call :ui_step_fail "[4/7] Driver Searching settings")

reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "%BACKUP_DIR%\Power.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[5/7] Power settings (Fast Startup)") else (call :ui_step_fail "[5/7] Power settings (Fast Startup)")

reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%BACKUP_DIR%\TcpipInterfaces.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[6/7] Network (Nagle) settings") else (call :ui_step_fail "[6/7] Network (Nagle) settings")

reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "%BACKUP_DIR%\GamePriority.reg" /y >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[7/7] Game Priority settings") else (call :ui_step_fail "[7/7] Game Priority settings")

call :ui_summary "Registry backup complete"
echo   %C_DIM%Saved to: %BACKUP_DIR%%C_R%
echo   %C_DIM%To restore: double-click any .reg file in that folder,%C_R%
echo   %C_DIM%or use "reg import filename.reg" from an admin command prompt.%C_R%
echo.
pause
