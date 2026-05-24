@echo off
:: ============================================================
:: Re-enable All Services (Revert Gaming Optimization)
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Thin wrapper around revert-all.ps1 (manifest-driven revert).
:: Kept for backward compat with users who learned the .bat name.
::
:: CURSOR-AUDIT #8 fix: the previous .bat blindly reset services
:: to fixed defaults, ignoring state.services in the manifest.
:: The .ps1 reads the manifest and restores the exact pre-toolkit
:: start mode per service, falling back to defaults only when the
:: manifest has no entry for the service.
:: ============================================================

:: Load UI helpers (ANSI colors) for the admin check banner.
call "%~dp0..\lib\ui-helpers.bat"
call :ui_admin_check

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0revert-all.ps1"
exit /b %errorlevel%
