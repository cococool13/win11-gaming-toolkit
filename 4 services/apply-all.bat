@echo off
:: ============================================================
:: Disable All Unnecessary Services (Gaming Optimization)
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Disables services that are safe to turn off for gaming.
:: Must be run as Administrator.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Disabling Unnecessary Services for Gaming"
call :ui_admin_check

echo   %C_WARN%[WARNING] This will disable the following services:%C_R%
echo     - DiagTrack %C_DIM%(Connected User Experiences and Telemetry)%C_R%
echo     - PhoneSvc %C_DIM%(Phone Service)%C_R%
echo     - lfsvc %C_DIM%(Geolocation Service)%C_R%
echo     - Spooler %C_DIM%(Print Spooler — skip if you have a printer)%C_R%
echo     - WSearch %C_DIM%(Windows Search — Start menu search will be slower)%C_R%
echo     - RetailDemo %C_DIM%(Retail Demo Service)%C_R%
echo     - MapsBroker %C_DIM%(Downloaded Maps Manager)%C_R%
echo     - Fax %C_DIM%(Fax Service)%C_R%
echo.
echo   %C_WARN%Press Ctrl+C to cancel, or%C_R%
pause

echo.

sc config DiagTrack start= disabled >nul 2>&1 && sc stop DiagTrack >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[1/8] DiagTrack (Telemetry)") else (call :ui_step_fail "[1/8] DiagTrack (Telemetry)")

sc config PhoneSvc start= disabled >nul 2>&1 && sc stop PhoneSvc >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[2/8] Phone Service") else (call :ui_step_fail "[2/8] Phone Service")

sc config lfsvc start= disabled >nul 2>&1 && sc stop lfsvc >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[3/8] Geolocation Service") else (call :ui_step_fail "[3/8] Geolocation Service")

sc config Spooler start= disabled >nul 2>&1 && sc stop Spooler >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[4/8] Print Spooler") else (call :ui_step_fail "[4/8] Print Spooler")

sc config WSearch start= disabled >nul 2>&1 && sc stop WSearch >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[5/8] Windows Search") else (call :ui_step_fail "[5/8] Windows Search")

sc config RetailDemo start= disabled >nul 2>&1 && sc stop RetailDemo >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[6/8] Retail Demo Service") else (call :ui_step_fail "[6/8] Retail Demo Service")

sc config MapsBroker start= disabled >nul 2>&1 && sc stop MapsBroker >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[7/8] Downloaded Maps Manager") else (call :ui_step_fail "[7/8] Downloaded Maps Manager")

sc config Fax start= disabled >nul 2>&1 && sc stop Fax >nul 2>&1
if %errorlevel% equ 0 (call :ui_step_ok "[8/8] Fax Service") else (call :ui_step_fail "[8/8] Fax Service")

call :ui_summary "All services disabled" "Run revert-all.bat as Administrator"
pause
