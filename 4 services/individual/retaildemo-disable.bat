@echo off
:: Disable Retail Demo Service
:: Only used in store display PCs. Always safe to disable.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config RetailDemo start= disabled >nul 2>&1
sc stop RetailDemo >nul 2>&1
echo [DONE] Retail Demo Service disabled.
pause
