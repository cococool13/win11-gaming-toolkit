@echo off
:: Disable Phone Service (PhoneSvc)
:: Used for phone linking. Safe to disable if you don't use Phone Link.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config PhoneSvc start= disabled >nul 2>&1
sc stop PhoneSvc >nul 2>&1
echo [DONE] Phone Service disabled.
pause
