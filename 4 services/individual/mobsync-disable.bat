@echo off
:: Disable Offline Files / Sync Center through the tracked PowerShell path.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0mobsync-disable.ps1"
pause
