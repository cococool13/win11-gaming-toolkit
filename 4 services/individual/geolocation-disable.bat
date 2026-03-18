@echo off
:: Disable Geolocation Service (lfsvc)
:: Tracks your location. Safe to disable for desktop gaming PCs.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config lfsvc start= disabled >nul 2>&1
sc stop lfsvc >nul 2>&1
echo [DONE] Geolocation Service disabled.
pause
