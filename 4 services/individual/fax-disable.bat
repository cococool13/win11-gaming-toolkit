@echo off
:: Disable Fax Service
:: It's 2026. You don't need fax. Safe to disable.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config Fax start= disabled >nul 2>&1
sc stop Fax >nul 2>&1
echo [DONE] Fax Service disabled.
pause
