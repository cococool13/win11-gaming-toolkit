@echo off
:: Re-enable MobSync (Microsoft Sync Center)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config MobSync start= demand >nul 2>&1
echo [DONE] MobSync set to manual start.
pause
