@echo off
:: ============================================================
:: Re-enable VBS / Memory Integrity (HVCI)
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Restores Windows 11 default security settings.
:: Must be run as Administrator. Requires reboot.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Re-enable Virtualization-Based Security (VBS)"
call :ui_admin_check

reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 1 /f >nul 2>&1
call :ui_step_ok "[1/4] Memory Integrity (HVCI) enabled"

reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul 2>&1
call :ui_step_ok "[2/4] VBS enabled"

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RunAsPPL" /t REG_DWORD /d 1 /f >nul 2>&1
call :ui_step_ok "[3/4] LSA Protection restored"

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f >nul 2>&1
call :ui_step_ok "[4/4] Credential Guard default restored"

call :ui_summary "VBS, Memory Integrity, and LSA Protection re-enabled"
echo   %C_WARN%YOU MUST REBOOT for changes to take effect.%C_R%
echo.
pause
