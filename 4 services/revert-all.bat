@echo off
:: ============================================================
:: Re-enable All Services (Revert Gaming Optimization)
:: Windows 11 Gaming Optimization Guide
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Reverting All Service Changes"
call :ui_admin_check

echo   Restoring services to default state...
echo.

sc config DiagTrack start= auto >nul 2>&1 && sc start DiagTrack >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[1/8] DiagTrack (Telemetry)") else (call :ui_step_skip "[1/8] DiagTrack (Telemetry)")

sc config PhoneSvc start= demand >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[2/8] Phone Service") else (call :ui_step_skip "[2/8] Phone Service")

sc config lfsvc start= demand >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[3/8] Geolocation Service") else (call :ui_step_skip "[3/8] Geolocation Service")

sc config Spooler start= auto >nul 2>&1 && sc start Spooler >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[4/8] Print Spooler") else (call :ui_step_skip "[4/8] Print Spooler")

sc config WSearch start= auto >nul 2>&1 && sc start WSearch >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[5/8] Windows Search") else (call :ui_step_skip "[5/8] Windows Search")

sc config RetailDemo start= demand >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[6/8] Retail Demo Service") else (call :ui_step_skip "[6/8] Retail Demo Service")

sc config MapsBroker start= auto >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[7/8] Downloaded Maps Manager") else (call :ui_step_skip "[7/8] Downloaded Maps Manager")

sc config Fax start= demand >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[8/8] Fax Service") else (call :ui_step_skip "[8/8] Fax Service")

call :ui_summary "All services restored to default"
pause
