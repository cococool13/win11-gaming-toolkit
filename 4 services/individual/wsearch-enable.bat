@echo off
:: Re-enable Windows Search (WSearch)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config WSearch start= auto >nul 2>&1
sc start WSearch >nul 2>&1
echo [DONE] Windows Search re-enabled.
pause
