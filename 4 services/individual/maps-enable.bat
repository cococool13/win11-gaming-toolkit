@echo off
:: Re-enable Downloaded Maps Manager (MapsBroker)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config MapsBroker start= auto >nul 2>&1
echo [DONE] Maps Manager re-enabled.
pause
