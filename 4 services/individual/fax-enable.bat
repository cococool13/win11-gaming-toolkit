@echo off
:: Re-enable Fax Service
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config Fax start= demand >nul 2>&1
echo [DONE] Fax Service re-enabled.
pause
