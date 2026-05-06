@echo off
:: Restore Offline Files / Sync Center through the tracked PowerShell path.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0mobsync-enable.ps1"
pause
