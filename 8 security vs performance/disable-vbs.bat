@echo off
:: ============================================================
:: Disable VBS / Memory Integrity (HVCI)
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Tier: Security Trade-off
::
:: WARNING: This REDUCES your security protection.
:: Read README.txt in this folder before running.
::
:: This is the single biggest FPS gain on modern Win11.
:: Can improve FPS by 5-25% depending on the game and CPU.
::
:: ANTI-CHEAT: BattlEye and EAC on Win11 24H2+ may stop working
:: after this change. R6 Siege and other BattlEye titles may
:: refuse to launch. Test affected titles after reboot. If a
:: game stops working, run enable-vbs.bat or REVERT-EVERYTHING.ps1.
::
:: Must be run as Administrator. Requires reboot.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Disable Virtualization-Based Security (VBS)"
call :ui_admin_check

echo   %C_BERR%WARNING: This disables important security features.%C_R%
echo   %C_DIM%Read the README.txt for full details.%C_R%
echo.
echo   %C_OK%Benefits:%C_R% +5-25%% FPS improvement in many games
echo   %C_ERR%Risk:%C_R%     Reduced protection against kernel-level exploits
echo.
echo   %C_BERR%ANTI-CHEAT WARNING:%C_R%
echo   %C_ERR%BattlEye and EAC on Win11 24H2+ may stop working after this change.%C_R%
echo   %C_ERR%R6 Siege and other BattlEye titles may refuse to launch.%C_R%
echo   %C_WARN%Test affected titles after reboot; run enable-vbs.bat to revert.%C_R%
echo.
echo   %C_WARN%NOTE: This also disables LSA Protection (LSASS credential guard).%C_R%
echo   %C_DIM%This means credential-dumping tools could extract passwords%C_R%
echo   %C_DIM%from memory. Only safe on dedicated gaming PCs with no%C_R%
echo   %C_DIM%domain accounts or sensitive stored credentials.%C_R%
echo.
echo   %C_WARN%Press Ctrl+C to cancel, or%C_R%
pause

echo.

reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
call :ui_step_ok "[1/4] Memory Integrity (HVCI) disabled"

reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul 2>&1
call :ui_step_ok "[2/4] VBS disabled"

echo.
echo   %C_BERR%Step 3: Disabling LSA Protection (credential guard)%C_R%
echo   %C_WARN%This allows credential-dumping tools to extract passwords.%C_R%
echo   %C_WARN%Only proceed on dedicated gaming PCs with no sensitive accounts.%C_R%
echo.
echo   %C_WARN%Press Ctrl+C to skip this step, or%C_R%
pause

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RunAsPPL" /t REG_DWORD /d 0 /f >nul 2>&1
call :ui_step_ok "[3/4] LSA Protection disabled"

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f >nul 2>&1
call :ui_step_ok "[4/4] Credential Guard disabled"

call :ui_summary "VBS and Memory Integrity disabled" "Run enable-vbs.bat"

echo   %C_BERR%YOU MUST REBOOT for changes to take effect.%C_R%
echo.
echo   %C_DIM%To verify after reboot:%C_R%
echo     %C_DIM%1. Open Start, type "msinfo32", press Enter%C_R%
echo     %C_DIM%2. Look for "Virtualization-based security"%C_R%
echo     %C_DIM%3. It should say "Not enabled"%C_R%
echo.
pause
