@echo off
:: Disable Print Spooler (Spooler)
:: WARNING: Disabling this means you CANNOT print. Only disable if no printer.
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config Spooler start= disabled >nul 2>&1
sc stop Spooler >nul 2>&1
echo [DONE] Print Spooler disabled. You cannot print until re-enabled.
pause
