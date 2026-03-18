@echo off
:: ============================================================
:: Network Optimization for Gaming
:: Windows 11 Gaming Optimization Guide
:: ============================================================
:: Optimizes TCP/IP settings, disables Nagle's Algorithm,
:: and tunes network adapter settings for lower latency.
:: Must be run as Administrator.
:: ============================================================

:: Load UI helpers (ANSI colors)
call "%~dp0..\lib\ui-helpers.bat"

call :ui_header "Optimizing Network Settings for Gaming"
call :ui_admin_check

netsh int tcp set global autotuninglevel=normal >nul 2>&1
call :ui_step_ok "[1/8] TCP Auto-Tuning set to normal"

netsh int tcp set global rss=enabled >nul 2>&1
call :ui_step_ok "[2/8] RSS (Receive Side Scaling) enabled"

netsh int tcp set global dca=enabled >nul 2>&1
call :ui_step_ok "[3/8] Direct Cache Access enabled"

netsh int tcp set global timestamps=disabled >nul 2>&1
call :ui_step_ok "[4/8] TCP Timestamps disabled"

powershell -Command "Get-NetAdapter | ForEach-Object { Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Large Send Offload*' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue }" >nul 2>&1
call :ui_step_ok "[5/8] Large Send Offload disabled"

powershell -Command ^
  "$interfaces = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'; " ^
  "Get-ChildItem $interfaces | ForEach-Object { " ^
  "  $ip = (Get-ItemProperty $_.PSPath -Name 'DhcpIPAddress' -ErrorAction SilentlyContinue).DhcpIPAddress; " ^
  "  if ($ip -and $ip -ne '0.0.0.0') { " ^
  "    Set-ItemProperty $_.PSPath -Name 'TcpAckFrequency' -Value 1 -Type DWord -Force; " ^
  "    Set-ItemProperty $_.PSPath -Name 'TCPNoDelay' -Value 1 -Type DWord -Force; " ^
  "  } " ^
  "}"
call :ui_step_ok "[6/8] Nagle's Algorithm disabled on active adapters"

echo.
echo   %C_WHITE%Choose DNS provider:%C_R%
echo     %C_HEAD%1.%C_R% Cloudflare (1.1.1.1) — fast, privacy-focused %C_DIM%[default]%C_R%
echo     %C_HEAD%2.%C_R% Google (8.8.8.8)     — reliable, widely used
echo     %C_HEAD%3.%C_R% Skip                 — keep current DNS settings
echo.
set /p DNS_CHOICE="  Enter choice (1/2/3) [1]: "
if "%DNS_CHOICE%"=="" set DNS_CHOICE=1
if "%DNS_CHOICE%"=="3" goto skip_dns
if "%DNS_CHOICE%"=="2" (
    set "DNS_V4='8.8.8.8','8.8.4.4'"
    set "DNS_V6='2001:4860:4860::8888','2001:4860:4860::8844'"
    set "DNS_NAME=Google"
) else (
    set "DNS_V4='1.1.1.1','1.0.0.1'"
    set "DNS_V6='2606:4700:4700::1111','2606:4700:4700::1001'"
    set "DNS_NAME=Cloudflare"
)
powershell -Command ^
  "$v4 = @(%DNS_V4%); $v6 = @(%DNS_V6%); $all = $v4 + $v6; " ^
  "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { " ^
  "  Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses $all -ErrorAction SilentlyContinue; " ^
  "}"
call :ui_step_ok "[7/8] DNS set to %DNS_NAME%"
goto done_dns
:skip_dns
call :ui_step_skip "[7/8] DNS (user chose to skip)"
:done_dns

ipconfig /flushdns >nul 2>&1
call :ui_step_ok "[8/8] DNS cache flushed"

call :ui_summary "Network optimization applied" "Run revert-network.bat"
echo   %C_DIM%A reboot is recommended for all changes to take effect.%C_R%
echo.
pause
