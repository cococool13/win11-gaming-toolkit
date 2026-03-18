@echo off
:: Re-enable DiagTrack (Connected User Experiences and Telemetry)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config DiagTrack start= auto >nul 2>&1
sc start DiagTrack >nul 2>&1
echo [DONE] DiagTrack re-enabled.
pause
