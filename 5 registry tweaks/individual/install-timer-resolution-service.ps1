# ============================================================
# Install Timer Resolution Service (STR)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Advanced
#
# Creates a Windows service that forces the system timer to its
# maximum resolution (~0.5ms instead of default ~15.6ms).
#
# === CARGO-CULT WARNING (CURSOR-AUDIT #11) ===
# Setting a low timer resolution was a real input-latency win on
# Windows 7/8/10. On Windows 11 24H2+, scheduler and HPET behavior
# changed: most modern games either request their own timer
# resolution via NtSetTimerResolution at startup, or run on the
# higher-resolution path by default. The standalone STR service
# now provides little-to-no measurable FPS / latency benefit for
# the majority of titles, and carries side effects (more CPU
# wakeups, higher idle power draw, occasional anti-cheat scrutiny).
#
# Sources: Bruce Dawson "Timers Tutorial" (randomascii blog),
# Microsoft Win11 24H2 scheduling notes, and the Discord-driven
# debates from late 2024 about Win11 24H2 timer behavior.
#
# RECOMMENDATION: skip this unless you are explicitly debugging
# 15ms input-latency stalls in a specific title. Use the audit
# tools in launcher's [V] Verify menu first.
#
# ANTI-CHEAT: Kernel-level timer manipulation is occasionally
# flagged by aggressive anti-cheats (Vanguard, FACEIT AC). If you
# run those games, prefer per-title workarounds or skip entirely.
#
# Pair: uninstall-timer-resolution-service.ps1 (idempotent revert).
#
# Run as Administrator in PowerShell.
# Pass -Force to skip the cargo-cult warning prompt (scripted use).
# ============================================================

param(
    [switch]$Force
)

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Install Timer Resolution Service" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# CARGO-CULT confirm — explicit opt-in (CURSOR-AUDIT #11)
if (-not $Force) {
    Write-Host "  CARGO-CULT WARNING:" -ForegroundColor Red
    Write-Host "    On Windows 11 24H2+, this service provides little-to-no" -ForegroundColor Yellow
    Write-Host "    measurable FPS/latency benefit for most modern titles." -ForegroundColor Yellow
    Write-Host "    Side effects: more CPU wakeups, higher idle power draw." -ForegroundColor Yellow
    Write-Host "    Anti-cheats (Vanguard, FACEIT) occasionally scrutinize" -ForegroundColor Yellow
    Write-Host "    kernel-level timer manipulation." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Documented for completeness; see header for sources." -ForegroundColor Yellow
    Write-Host ""
    $proceed = Read-Host "  Install anyway? (y/N)"
    if ($proceed.Trim().ToUpper() -ne "Y") {
        Write-Host "  Cancelled." -ForegroundColor Gray
        exit 0
    }
    Write-Host ""
}

# Initialize manifest so the registry write below captures before-state
Initialize-ToolkitState | Out-Null
$stepName = "timer-resolution"

# C# source for the timer resolution service
$csSource = @'
using System;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.ComponentModel;
using System.Configuration.Install;
using System.Reflection;
using System.Threading;
[assembly: AssemblyVersion("2.1")]
[assembly: AssemblyProduct("Set Timer Resolution Service")]
namespace TimerResService
{
    class TimerResService : ServiceBase
    {
        public TimerResService()
        {
            this.ServiceName = "STR";
            this.CanStop = true;
            this.CanPauseAndContinue = false;
        }
        static void Main()
        {
            ServiceBase.Run(new TimerResService());
        }
        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
            NtQueryTimerResolution(out _, out this.MaxRes, out _);
            uint actual = 0;
            NtSetTimerResolution(this.MaxRes, true, out actual);
        }
        protected override void OnStop()
        {
            uint actual = 0;
            NtSetTimerResolution(this.MaxRes, false, out actual);
            base.OnStop();
        }
        uint MaxRes = 0;
        [DllImport("ntdll.dll")] static extern int NtSetTimerResolution(uint DesiredRes, bool Set, out uint ActualRes);
        [DllImport("ntdll.dll")] static extern int NtQueryTimerResolution(out uint MinRes, out uint MaxRes, out uint ActualRes);
    }
    [RunInstaller(true)]
    public class Installer : System.Configuration.Install.Installer
    {
        public Installer()
        {
            var spi = new ServiceProcessInstaller { Account = ServiceAccount.LocalService };
            var si = new ServiceInstaller { DisplayName = "Set Timer Resolution Service", StartType = ServiceStartMode.Automatic, ServiceName = "STR" };
            this.Installers.Add(spi);
            this.Installers.Add(si);
        }
    }
}
'@

$installDir = "$env:ProgramFiles\SetTimerResolution"
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
$csPath = "$installDir\SetTimerResolutionService.cs"
$exePath = "$installDir\SetTimerResolutionService.exe"

Write-Host "[1/4] Writing service source code..." -ForegroundColor Yellow
Set-Content -Path $csPath -Value $csSource -Force

Write-Host "[2/4] Compiling service..." -ForegroundColor Yellow
$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $cscPath)) {
    Write-Host ""
    Write-Host "[ERROR] .NET Framework 4.x compiler (csc.exe) not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "This script compiles a small Windows service from C# source at install" -ForegroundColor Gray
    Write-Host "time. .NET Framework 4.x is normally bundled with Windows 10/11, but is" -ForegroundColor Gray
    Write-Host "missing on Server Core, custom debloat ISOs, or stripped images." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Recovery options:" -ForegroundColor Yellow
    Write-Host "  1. Repair the Windows component store:" -ForegroundColor Gray
    Write-Host "       DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor White
    Write-Host "       sfc /scannow" -ForegroundColor White
    Write-Host "  2. If csc.exe is still missing, install or repair the Microsoft" -ForegroundColor Gray
    Write-Host "       .NET Framework 4.8 Developer Pack from:" -ForegroundColor Gray
    Write-Host "       https://dotnet.microsoft.com/download/dotnet-framework/net48" -ForegroundColor White
    Write-Host "  3. For damaged framework installs, use Microsoft's repair tool:" -ForegroundColor Gray
    Write-Host "       https://www.microsoft.com/download/details.aspx?id=30135" -ForegroundColor White
    Write-Host "  4. Reboot, then re-run this script." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Looked for: $cscPath" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
Start-Process -Wait $cscPath -ArgumentList "-out:`"$exePath`" `"$csPath`"" -WindowStyle Hidden

# Cleanup source
Remove-Item $csPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $exePath)) {
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[3/4] Installing service..." -ForegroundColor Yellow
# CURSOR-AUDIT #11 idempotency: only recreate if the service is missing or
# points at a different binary. Re-running with the same exe is a no-op.
$existingService = Get-CimInstance -ClassName Win32_Service -Filter "Name='STR'" -ErrorAction SilentlyContinue
$needsRecreate = $true
if ($existingService -and $existingService.PathName) {
    # PathName may be quoted; strip and compare
    $existingPath = $existingService.PathName.Trim('"')
    if ($existingPath -ieq $exePath) {
        Write-Host "      STR service already installed pointing at $exePath — skipping recreate." -ForegroundColor Gray
        $needsRecreate = $false
    }
}
if ($needsRecreate) {
    if (Get-Service -Name "STR" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "STR" -Force -ErrorAction SilentlyContinue
        sc.exe delete "STR" | Out-Null
        Start-Sleep -Seconds 2
    }
    New-Service -Name "STR" -DisplayName "Set Timer Resolution Service" -BinaryPathName $exePath -StartupType Automatic -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "[4/4] Starting service and enabling global timer resolution..." -ForegroundColor Yellow
Start-Service -Name "STR" -ErrorAction SilentlyContinue

# CURSOR-AUDIT #11 idempotency: only write the kernel value if not already 1.
# Tracked via Set-ToolkitRegistryValue so uninstall-timer-resolution-service.ps1
# (or REVERT-EVERYTHING.ps1) can revert to the captured pre-install state.
$kernelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
$currentKernelValue = (Get-ItemProperty -Path $kernelPath -Name "GlobalTimerResolutionRequests" -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests
if ($currentKernelValue -ne 1) {
    Set-ToolkitRegistryValue -Id "reg:GlobalTimerResolutionRequests" `
        -Path $kernelPath -Name "GlobalTimerResolutionRequests" `
        -Value 1 -Type "DWord" -Tier "Advanced" -Step $stepName
} else {
    Write-Host "      GlobalTimerResolutionRequests already = 1; skipping write." -ForegroundColor Gray
}

Add-ToolkitStepResult -Key $stepName -Tier "Advanced" -Status "applied" `
    -Reason "STR service installed, GlobalTimerResolutionRequests = 1"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  [DONE] Timer Resolution Service installed!" -ForegroundColor Green
Write-Host ""
Write-Host "  The service forces ~0.5ms timer resolution (vs 15.6ms default)" -ForegroundColor Gray
Write-Host "  It starts automatically with Windows." -ForegroundColor Gray
Write-Host ""
Write-Host "  To verify: Open services.msc and look for" -ForegroundColor Gray
Write-Host "  'Set Timer Resolution Service' (Status: Running)" -ForegroundColor Gray
Write-Host ""
Write-Host "  To remove:" -ForegroundColor Gray
Write-Host "    Stop-Service STR; sc.exe delete STR" -ForegroundColor Gray
Write-Host "    del `"$env:ProgramFiles\SetTimerResolution\SetTimerResolutionService.exe`"" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
