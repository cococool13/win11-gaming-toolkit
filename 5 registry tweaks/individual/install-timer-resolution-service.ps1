# ============================================================
# Install Timer Resolution Service (STR)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Creates a Windows service that forces the system timer to its
# maximum resolution (~0.5ms instead of default ~15.6ms).
# This reduces input lag and improves frame pacing in games.
#
# Run as Administrator in PowerShell.
# ============================================================

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
    Write-Host "[ERROR] .NET Framework 4.0 compiler not found." -ForegroundColor Red
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
# Remove old service if exists
if (Get-Service -Name "STR" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "STR" -Force -ErrorAction SilentlyContinue
    sc.exe delete "STR" | Out-Null
    Start-Sleep -Seconds 2
}

New-Service -Name "STR" -DisplayName "Set Timer Resolution Service" -BinaryPathName $exePath -StartupType Automatic -ErrorAction SilentlyContinue | Out-Null

Write-Host "[4/4] Starting service and enabling global timer resolution..." -ForegroundColor Yellow
Start-Service -Name "STR" -ErrorAction SilentlyContinue

# Enable global timer resolution requests (Win11 24H2+)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f 2>$null | Out-Null

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
