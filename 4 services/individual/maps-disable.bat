@echo off
:: Disable Downloaded Maps Manager (MapsBroker)
:: Manages offline maps. Safe to disable if you don't use Windows Maps.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config MapsBroker start= disabled >nul 2>&1
sc stop MapsBroker >nul 2>&1
echo [DONE] Maps Manager disabled.
pause
