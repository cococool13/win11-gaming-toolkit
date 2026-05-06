@echo off
:: Disable MobSync (Microsoft Sync Center)
:: Source: FR33THYFR33THY/Ultimate — 8 Advanced/18 Start Search Shell Mobsync.ps1
:: MobSync handles Offline Files / mobile device sync. Unused on
:: most gaming desktops. Safe to disable.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config MobSync start= disabled >nul 2>&1
sc stop MobSync >nul 2>&1
echo [DONE] MobSync disabled.
pause
