@echo off
:: Re-enable Phone Service (PhoneSvc)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config PhoneSvc start= demand >nul 2>&1
echo [DONE] Phone Service re-enabled.
pause
