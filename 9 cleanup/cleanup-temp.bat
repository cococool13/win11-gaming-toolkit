@echo off
:: ============================================================
:: Cleanup Temp Files and Caches
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Clears temporary files, Windows Update cache, and other junk.
:: Replaces CCleaner — no third-party tools needed.
:: Must be run as Administrator.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Cleaning Up Temporary Files"
call :ui_admin_check

del /q /f /s "%TEMP%\*" >nul 2>&1
call :ui_step_ok "[1/6] User temp folder"

del /q /f /s "%WINDIR%\Temp\*" >nul 2>&1
call :ui_step_ok "[2/6] Windows temp folder"

net stop wuauserv >nul 2>&1
del /q /f /s "%WINDIR%\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1
call :ui_step_ok "[3/6] Windows Update cache"

del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
call :ui_step_ok "[4/6] Thumbnail cache"

del /q /f /s "%LOCALAPPDATA%\D3DSCache\*" >nul 2>&1
call :ui_step_ok "[5/6] DirectX Shader Cache"

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v "StateFlags0100" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v "StateFlags0100" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v "StateFlags0100" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v "StateFlags0100" /t REG_DWORD /d 2 /f >nul 2>&1
cleanmgr /sagerun:100 >nul 2>&1
call :ui_step_ok "[6/6] Disk Cleanup (silent mode)"

call :ui_summary "Cleanup complete"

echo   %C_DIM%What was cleaned:%C_R%
echo     %C_DIM%- User temp files%C_R%
echo     %C_DIM%- Windows temp files%C_R%
echo     %C_DIM%- Windows Update download cache%C_R%
echo     %C_DIM%- Thumbnail cache%C_R%
echo     %C_DIM%- DirectX shader cache%C_R%
echo     %C_DIM%- Recycle Bin, Error Reports, Delivery Optimization files%C_R%
echo.
echo   %C_WARN%NOTE: Shader cache cleanup means the first launch of each%C_R%
echo   %C_WARN%game after this may take slightly longer as shaders recompile.%C_R%
echo.
pause
