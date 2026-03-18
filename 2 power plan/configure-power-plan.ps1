# ============================================================
# Configure Ultimate Performance Power Plan (Detailed)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Goes beyond the basic "Ultimate Performance" plan by setting
# every sub-option to maximum performance: USB suspend off,
# PCI-E power management off, CPU cores unparked, etc.
#
# Run enable-ultimate-performance.bat FIRST, then run this.
# Must be run as Administrator in PowerShell.
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Configure Detailed Power Plan Settings" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create our custom plan with a fixed GUID
$planGuid = "99999999-9999-9999-9999-999999999999"

# Try to duplicate Ultimate Performance into our fixed GUID
cmd /c "powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $planGuid >nul 2>&1"
cmd /c "powercfg /SETACTIVE $planGuid >nul 2>&1"

# If that failed, use whatever plan is active
$activePlan = $planGuid
$testOutput = powercfg /getactivescheme 2>&1
if ($testOutput -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
    $activePlan = $Matches[1]
}

Write-Host "Active plan: $activePlan" -ForegroundColor Gray
Write-Host ""

# Helper function — sets both AC (plugged in) and DC (battery)
function Set-PowerIndex($subgroup, $setting, $value) {
    powercfg /setacvalueindex $activePlan $subgroup $setting $value 2>$null
    powercfg /setdcvalueindex $activePlan $subgroup $setting $value 2>$null
}

# ---- Hard Disk ----
Write-Host "[1/12] Hard disk: never turn off" -ForegroundColor Yellow
Set-PowerIndex "0012ee47-9041-4b5d-9b77-535fba8b1442" "6738e2c4-e8a5-4a42-b16a-e040e769756e" "0x00000000"

# ---- Wireless Adapter: Maximum Performance ----
Write-Host "[2/12] Wireless adapter: maximum performance" -ForegroundColor Yellow
Set-PowerIndex "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1" "12bbebe6-58d6-4636-95bb-3217ef867c1a" "000"

# ---- Sleep: Never ----
Write-Host "[3/12] Sleep: disabled" -ForegroundColor Yellow
Set-PowerIndex "238c9fa8-0aad-41ed-83f4-97be242c8f20" "29f6c1db-86da-48c5-9fdb-f2b67b1f44da" "0x00000000"

# ---- Hybrid Sleep: Off ----
Write-Host "[4/12] Hybrid sleep: off" -ForegroundColor Yellow
Set-PowerIndex "238c9fa8-0aad-41ed-83f4-97be242c8f20" "94ac6d29-73ce-41a6-809f-6363ba21b47e" "000"

# ---- Hibernate: Off ----
Write-Host "[5/12] Hibernate: off" -ForegroundColor Yellow
Set-PowerIndex "238c9fa8-0aad-41ed-83f4-97be242c8f20" "9d7815a6-7ee4-497e-8888-515a05f02364" "0x00000000"
powercfg /hibernate off 2>$null

# ---- USB Selective Suspend: Disabled ----
Write-Host "[6/12] USB selective suspend: disabled" -ForegroundColor Yellow
Set-PowerIndex "2a737441-1930-4402-8d77-b2bebba308a3" "48e6b7a6-50f5-4782-a5d4-53bb8f07e226" "000"

# ---- USB 3 Link Power Management: Off ----
Write-Host "[7/12] USB 3 link power management: off" -ForegroundColor Yellow
# Unhide the setting first
reg add "HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009" /v "Attributes" /t REG_DWORD /d 0 /f 2>$null | Out-Null
Set-PowerIndex "2a737441-1930-4402-8d77-b2bebba308a3" "d4e98f31-5ffe-4ce1-be31-1b38b384c009" "000"

# ---- PCI Express Link State: Off ----
Write-Host "[8/12] PCI Express link state power management: off" -ForegroundColor Yellow
Set-PowerIndex "501a4d13-42af-4429-9fd1-a8218c268e20" "ee12f906-d277-404b-b6da-e5fa1a576df5" "000"

# ---- CPU: 100% min/max, unpark all cores ----
Write-Host "[9/12] CPU: 100% min/max, all cores unparked" -ForegroundColor Yellow
# Minimum processor state 100%
Set-PowerIndex "54533251-82be-4824-96c1-47b60b740d00" "893dee8e-2bef-41e0-89c6-b55d0929964c" "0x00000064"
# Maximum processor state 100%
Set-PowerIndex "54533251-82be-4824-96c1-47b60b740d00" "bc5038f7-23e0-4960-96da-33abaf5935ec" "0x00000064"
# System cooling policy: active
Set-PowerIndex "54533251-82be-4824-96c1-47b60b740d00" "94d3a615-a899-4ac5-ae2b-e4d8f634367f" "001"
# Unhide core parking settings
reg add "HKLM\System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "Attributes" /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKLM\System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028" /v "Attributes" /t REG_DWORD /d 0 /f 2>$null | Out-Null
# Core parking min cores: 100% (all cores active)
Set-PowerIndex "54533251-82be-4824-96c1-47b60b740d00" "0cc5b647-c1df-4637-891a-dec35c318583" "0x00000064"
# Core parking max cores: 100%
Set-PowerIndex "54533251-82be-4824-96c1-47b60b740d00" "ea062031-0e34-4ff1-9b6d-eb1059334028" "0x00000064"

# ---- Display: 10 min timeout (OLED protection) ----
Write-Host "[10/12] Display timeout: 10 minutes" -ForegroundColor Yellow
Set-PowerIndex "7516b95f-f776-4464-8c53-06167f40cc99" "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" "600"

# ---- Adaptive Brightness: Off ----
Write-Host "[11/12] Adaptive brightness: off" -ForegroundColor Yellow
Set-PowerIndex "7516b95f-f776-4464-8c53-06167f40cc99" "fbd9aa66-9553-4097-ba44-ed6e9d65eab8" "000"

# ---- Disable Fast Startup ----
Write-Host "[12/12] Fast startup: disabled" -ForegroundColor Yellow
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d 0 /f 2>$null | Out-Null

# ---- Disable Power Throttling ----
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f 2>$null | Out-Null

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  [DONE] Power plan fully configured!" -ForegroundColor Green
Write-Host ""
Write-Host "  Settings applied:" -ForegroundColor Gray
Write-Host "    - CPU at 100% min/max with all cores unparked" -ForegroundColor Gray
Write-Host "    - PCI-E link state power management: Off" -ForegroundColor Gray
Write-Host "    - USB selective suspend: Disabled" -ForegroundColor Gray
Write-Host "    - USB 3 link power management: Off" -ForegroundColor Gray
Write-Host "    - Sleep/Hibernate: Disabled" -ForegroundColor Gray
Write-Host "    - Wireless adapter: Max performance" -ForegroundColor Gray
Write-Host "    - Power throttling: Disabled" -ForegroundColor Gray
Write-Host "    - Fast Startup: Disabled" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
