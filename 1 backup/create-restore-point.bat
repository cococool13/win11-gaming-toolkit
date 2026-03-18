@echo off
:: ============================================================
:: Create System Restore Point
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Run this FIRST before making any changes.
:: Creates a restore point you can roll back to if needed.
:: Must be run as Administrator.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Creating System Restore Point"
call :ui_admin_check

:: Enable System Restore on C: drive (in case it's disabled)
powershell -Command "Enable-ComputerRestore -Drive 'C:\'" 2>nul

:: Create the restore point
echo     Creating restore point: %C_WHITE%"Before Gaming Optimization"%C_R%...

powershell -Command "Checkpoint-Computer -Description 'Before Gaming Optimization' -RestorePointType 'MODIFY_SETTINGS'" 2>nul

if %errorlevel% equ 0 (
    call :ui_step_ok "Restore point created"
    echo.
    echo   %C_DIM%To restore later:%C_R%
    echo     %C_DIM%1. Open Start Menu, search "Create a restore point"%C_R%
    echo     %C_DIM%2. Click "System Restore..."%C_R%
    echo     %C_DIM%3. Select "Before Gaming Optimization"%C_R%
    echo     %C_DIM%4. Follow the wizard%C_R%
) else (
    echo.
    echo   %C_WARN%[WARNING] Could not create restore point.%C_R%
    echo   %C_DIM%This can happen if one was created recently%C_R%
    echo   %C_DIM%(Windows limits one per 24 hours by default).%C_R%
    echo.
    echo   %C_DIM%You can still proceed — the registry backup script%C_R%
    echo   %C_DIM%will save your current registry settings separately.%C_R%
)

echo.
pause
