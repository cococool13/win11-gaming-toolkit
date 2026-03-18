@echo off
:: Re-enable Retail Demo Service
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config RetailDemo start= demand >nul 2>&1
echo [DONE] Retail Demo Service re-enabled.
pause
