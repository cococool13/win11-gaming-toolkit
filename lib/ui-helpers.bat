@echo off
:: ============================================================
:: Shared UI Helper for Batch Scripts
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Call this from any .bat script:
::   call "%~dp0..\lib\ui-helpers.bat"
::   -or-
::   call "%~dp0lib\ui-helpers.bat"
::
:: Then use: %C_OK%, %C_ERR%, %C_WARN%, %C_HEAD%, %C_DIM%, %C_R%
:: Example:  echo %C_OK%[OK]%C_R% Service disabled
:: ============================================================

:: Enable ANSI escape sequences (Windows 10 1511+)
:: The escape character is generated via a self-modifying prompt trick
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

:: Color codes (ANSI SGR sequences)
set "C_OK=%ESC%[92m"
set "C_ERR=%ESC%[91m"
set "C_WARN=%ESC%[93m"
set "C_HEAD=%ESC%[96m"
set "C_DIM=%ESC%[90m"
set "C_WHITE=%ESC%[97m"
set "C_R=%ESC%[0m"

:: Bold variants
set "C_BOK=%ESC%[1;92m"
set "C_BERR=%ESC%[1;91m"
set "C_BWARN=%ESC%[1;93m"
set "C_BHEAD=%ESC%[1;96m"

:: ---- Counters ----
set /a UI_OK=0
set /a UI_FAIL=0
set /a UI_SKIP=0

goto :eof

:: ============================================================
:: CALLABLE FUNCTIONS (use: call :function_name args)
:: ============================================================

:ui_header
:: Usage: call :ui_header "Title" ["Subtitle"]
echo.
echo   %C_HEAD%============================================================%C_R%
echo     %C_HEAD%%~1%C_R%
if not "%~2"=="" echo     %C_HEAD%%~2%C_R%
echo   %C_HEAD%============================================================%C_R%
echo.
goto :eof

:ui_section
:: Usage: call :ui_section "Section Title"
echo.
echo   %C_DIM%------------------------------------------------------------%C_R%
echo     %C_WHITE%%~1%C_R%
echo   %C_DIM%------------------------------------------------------------%C_R%
echo.
goto :eof

:ui_admin_check
:: Usage: call :ui_admin_check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   %C_ERR%[ERROR] This script must be run as Administrator.%C_R%
    echo   %C_ERR%Right-click and select "Run as administrator".%C_R%
    echo.
    pause
    exit /b 1
)
goto :eof

:ui_step_ok
:: Usage: call :ui_step_ok "Step description"
set /a UI_OK+=1
echo     %~1  %C_OK%[OK]%C_R%
goto :eof

:ui_step_fail
:: Usage: call :ui_step_fail "Step description"
set /a UI_FAIL+=1
echo     %~1  %C_ERR%[FAIL]%C_R%
goto :eof

:ui_step_skip
:: Usage: call :ui_step_skip "Step description"
set /a UI_SKIP+=1
echo     %~1  %C_WARN%[SKIP]%C_R%
goto :eof

:ui_summary
:: Usage: call :ui_summary "Done message" ["Revert hint"]
echo.
echo   %C_HEAD%============================================================%C_R%
if %UI_FAIL% equ 0 (
    echo     %C_OK%[DONE] %~1%C_R%
) else (
    echo     %C_WARN%[DONE] %~1 (with errors)%C_R%
)
echo.
echo     %C_OK%Succeeded: %UI_OK%%C_R%
if %UI_SKIP% gtr 0 echo     %C_WARN%Skipped:   %UI_SKIP%%C_R%
if %UI_FAIL% gtr 0 echo     %C_ERR%Failed:    %UI_FAIL%%C_R%
if not "%~2"=="" (
    echo.
    echo     %C_DIM%To revert: %~2%C_R%
)
echo   %C_HEAD%============================================================%C_R%
echo.
goto :eof

:ui_confirm
:: Usage: call :ui_confirm
echo.
echo     %C_WARN%Press Ctrl+C to cancel, or%C_R%
pause >nul 2>&1
echo     (continuing...)
goto :eof
