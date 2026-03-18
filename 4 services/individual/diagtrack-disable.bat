@echo off
:: Disable DiagTrack (Connected User Experiences and Telemetry)
:: Sends usage data to Microsoft. Safe to disable.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config DiagTrack start= disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
echo [DONE] DiagTrack disabled.
pause
