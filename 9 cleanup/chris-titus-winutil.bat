@echo off
:: ============================================================
:: Launch Chris Titus Tech Windows Utility (WinUtil)
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: WinUtil is a popular open-source Windows debloating and
:: optimization tool with a GUI. It can:
::   - Remove bloatware with checkboxes
::   - Install common programs (browsers, tools, etc.)
::   - Apply Windows tweaks via a simple interface
::   - Configure Windows Update policies
::
:: Source: https://github.com/ChrisTitusTech/winutil
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Chris Titus Tech Windows Utility (WinUtil)"
call :ui_admin_check

echo   This will download and run WinUtil from GitHub.
echo   %C_DIM%Nothing is permanently installed — it runs once and exits.%C_R%
echo.
echo   %C_WHITE%Features:%C_R%
echo     %C_DIM%- Install common programs (browsers, 7-Zip, etc.)%C_R%
echo     %C_DIM%- Remove Windows bloatware via GUI checkboxes%C_R%
echo     %C_DIM%- Apply performance tweaks%C_R%
echo     %C_DIM%- Configure Windows Update%C_R%
echo.
echo   %C_DIM%Source: github.com/ChrisTitusTech/winutil%C_R%
echo.
echo   %C_WARN%SECURITY NOTE:%C_R%
echo   %C_DIM%This downloads PowerShell code from GitHub and runs it.%C_R%
echo   %C_DIM%If you prefer, download winutil.ps1 manually from:%C_R%
echo   %C_DIM%https://github.com/ChrisTitusTech/winutil/releases%C_R%
echo.
echo   %C_WARN%Press Ctrl+C to cancel, or%C_R%
pause

echo.
echo     Downloading WinUtil to local file...

:: Download to local file first, then verify and run (safer than irm | iex)
set "WINUTIL_FILE=%TEMP%\winutil.ps1"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1' -OutFile '%WINUTIL_FILE%' -UseBasicParsing"

if not exist "%WINUTIL_FILE%" (
    echo   %C_ERR%[ERROR] Download failed.%C_R%
    echo   %C_DIM%Try manually: https://github.com/ChrisTitusTech/winutil/releases%C_R%
    pause
    exit /b 1
)

call :ui_step_ok "Downloaded to %WINUTIL_FILE%"

:: Compute and surface SHA-256 of the downloaded payload before execution.
:: Chris Titus releases are auto-built per commit so we cannot pin a single
:: hash, but echoing the value lets a paranoid user compare it against the
:: hash printed on the upstream release page before allowing it to run.
for /f "tokens=*" %%h in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%WINUTIL_FILE%').Hash"') do set "WINUTIL_HASH=%%h"
echo.
echo   %C_HEAD%SHA-256:%C_R% %WINUTIL_HASH%
echo   %C_DIM%Compare against: https://github.com/ChrisTitusTech/winutil/releases%C_R%
echo.
echo   %C_WARN%SECURITY: The script has been saved locally. You can review it%C_R%
echo   %C_WARN%before running. To review: open the file in a text editor.%C_R%
echo.
echo   %C_WARN%Press Ctrl+C to cancel and review first, or%C_R%
pause

echo.
echo     Launching WinUtil...
powershell -ExecutionPolicy Bypass -File "%WINUTIL_FILE%"

:: Clean up
del "%WINUTIL_FILE%" 2>nul

echo.
echo   %C_OK%WinUtil session ended.%C_R%
echo.
pause
