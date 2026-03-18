@echo off
:: Disable Windows Search (WSearch)
:: WARNING: Start menu search and File Explorer search will be slower/broken.
:: Only disable if you use a third-party search tool (e.g., Everything).
net session >nul 2>&1 || (echo Run as Administrator. & pause & exit /b 1)
sc config WSearch start= disabled >nul 2>&1
sc stop WSearch >nul 2>&1
echo [DONE] Windows Search disabled. Start menu search will be slower.
pause
