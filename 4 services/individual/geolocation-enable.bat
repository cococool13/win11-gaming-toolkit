@echo off
:: Re-enable Geolocation Service (lfsvc)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config lfsvc start= demand >nul 2>&1
echo [DONE] Geolocation Service re-enabled.
pause
