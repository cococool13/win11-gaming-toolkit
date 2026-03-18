@echo off
:: Re-enable Print Spooler (Spooler)
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config Spooler start= auto >nul 2>&1
sc start Spooler >nul 2>&1
echo [DONE] Print Spooler re-enabled.
pause
