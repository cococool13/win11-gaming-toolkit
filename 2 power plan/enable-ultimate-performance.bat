@echo off
:: ============================================================
:: Enable Ultimate Performance Power Plan
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Unhides and activates the "Ultimate Performance" plan that
:: Microsoft includes but hides on non-workstation editions.
:: Must be run as Administrator.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Enabling Ultimate Performance Power Plan"
call :ui_admin_check

:: Use a known fixed GUID for the duplicate so we can activate it without
:: parsing localized powercfg output. The for /f "tokens=4" approach broke
:: on non-English Windows because powercfg -list localizes both the column
:: layout and the "Ultimate Performance" string, so findstr never matched.
set "ULTIMATE_GUID=99999999-9999-9999-9999-999999999999"

:: Try to duplicate Ultimate Performance into our known GUID. The duplicate
:: command silently fails if the target GUID already exists, so re-runs
:: are idempotent. powercfg -duplicatescheme writes the duplicate to a
:: random GUID by default; pass our known GUID as the second argument so
:: we always know what to activate afterwards.
echo     Adding Ultimate Performance power plan...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 %ULTIMATE_GUID% >nul 2>&1

echo.
echo   %C_DIM%Available power plans:%C_R%
powercfg -list
echo.

powercfg -setactive %ULTIMATE_GUID% >nul 2>&1
if %errorlevel% equ 0 (
    call :ui_step_ok "Ultimate Performance plan activated"
    goto :done
)

echo   %C_WARN%[WARNING] Could not activate plan %ULTIMATE_GUID%.%C_R%
echo   %C_WARN%Open Power Options and select "Ultimate Performance" manually.%C_R%

:done
echo.
echo   %C_WARN%NOTE: This plan keeps your CPU at maximum frequency at all times.%C_R%
echo   %C_DIM%This increases power usage and heat. If you're on a laptop,%C_R%
echo   %C_DIM%you may want to switch back to "Balanced" when on battery.%C_R%
echo.
echo   %C_DIM%To switch plans: Settings > System > Power > Power mode%C_R%
echo   %C_DIM%Or run: powercfg -setactive SCHEME_BALANCED%C_R%
echo.
pause
