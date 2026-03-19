# ============================================================
# Windows 11 Gaming Optimization - Launcher
# ============================================================
# Interactive menu to run any optimization step.
# Run as Administrator in PowerShell.
# ============================================================

. "$PSScriptRoot\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimization - Launcher"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

$script:LauncherPalette = @{
    Frame = "DarkCyan"
    Accent = "Cyan"
    Danger = "Red"
    Warning = "Yellow"
    Success = "Green"
    Muted = "DarkGray"
    Text = "White"
    Soft = "Gray"
}

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  [ERROR] This launcher must be run as Administrator." -ForegroundColor $script:LauncherPalette.Danger
    Write-Host "  Right-click > 'Run with PowerShell' (as Admin)" -ForegroundColor $script:LauncherPalette.Danger
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

function Write-LauncherLine {
    param(
        [string]$Text = "",
        [string]$Color = $script:LauncherPalette.Text
    )

    Write-Host $Text -ForegroundColor $Color
}

function Write-LauncherBoxLine {
    param(
        [string]$Content = "",
        [string]$Color = $script:LauncherPalette.Text
    )

    $innerWidth = 72
    $trimmed = if ($Content.Length -gt $innerWidth) { $Content.Substring(0, $innerWidth) } else { $Content }
    $padding = " " * ($innerWidth - $trimmed.Length)
    Write-Host ("  | {0}{1} |" -f $trimmed, $padding) -ForegroundColor $Color
}

function Get-LauncherFootnote {
    param(
        [bool]$IsLaptop,
        [bool]$IsHybridGraphics,
        [bool]$PartOfDomain
    )

    if ($IsLaptop -or $IsHybridGraphics) {
        return "Laptop / hybrid graphics detected. Review GPU and power changes before applying."
    }

    if ($PartOfDomain) {
        return "Domain-joined PC detected. Some policy-backed tweaks may be overridden later."
    }

    return "Desktop profile detected. Apply targeted steps first, then use full-stack mode if needed."
}

function Show-Menu {
    Clear-Host
    $profile = Get-ToolkitMachineProfile
    $footnote = Get-LauncherFootnote -IsLaptop:$profile.isLaptop -IsHybridGraphics:$profile.isHybridGraphics -PartOfDomain:$profile.partOfDomain
    $gpus = if ($profile.gpuCount -gt 0) { $profile.gpuCount } else { 0 }
    $adapters = if ($profile.activeAdapterCount -gt 0) { $profile.activeAdapterCount } else { 0 }
    $hybridLabel = if ($profile.isHybridGraphics) { "Hybrid" } else { "Single" }
    $domainLabel = if ($profile.partOfDomain) { "Joined" } else { "No" }
    $mobilityLabel = if ($profile.isLaptop) { "Laptop" } elseif ($profile.isHandheld) { "Handheld" } else { "Desktop" }

    Write-Host ""
    Write-Host "  ========================================================================" -ForegroundColor $script:LauncherPalette.Frame
    Write-Host "   __      ___       ___ _ _  " -ForegroundColor $script:LauncherPalette.Accent
    Write-Host "   \ \    / (_)_ _  / __(_) |_ _  _   " -ForegroundColor $script:LauncherPalette.Accent
    Write-Host "    \ \/\/ /| | ' \| (_ | |  _| || |  " -ForegroundColor $script:LauncherPalette.Accent
    Write-Host "     \_/\_/ |_|_||_|\___|_|\__|\_, |  " -ForegroundColor $script:LauncherPalette.Accent
    Write-Host "                               |__/   " -ForegroundColor $script:LauncherPalette.Accent
    Write-Host "  ========================================================================" -ForegroundColor $script:LauncherPalette.Frame
    Write-Host "  POWER SHELL LAUNCH PAD" -ForegroundColor $script:LauncherPalette.Text
    Write-Host "  Fast access to restore, optimize, verify, and recover." -ForegroundColor $script:LauncherPalette.Soft
    Write-Host ""

    Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $script:LauncherPalette.Frame
    Write-LauncherBoxLine -Content ("Machine   : {0} {1}" -f $profile.manufacturer, $profile.model)
    Write-LauncherBoxLine -Content ("OS        : {0}" -f $profile.windowsCaption)
    Write-LauncherBoxLine -Content ("Profile   : {0} | Power {1} | Domain {2}" -f $mobilityLabel, $profile.powerState, $domainLabel)
    Write-LauncherBoxLine -Content ("Graphics  : {0} GPU(s) | {1} layout" -f $gpus, $hybridLabel)
    Write-LauncherBoxLine -Content ("Network   : {0} active adapter(s) | Printers {1}" -f $adapters, $profile.printerCount)
    Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $script:LauncherPalette.Frame
    Write-Host ""

    Write-Host "  QUICK START" -ForegroundColor $script:LauncherPalette.Accent
    Write-LauncherLine "    [0] Safe checkpoint      Restore point + registry backup" $script:LauncherPalette.Text
    Write-LauncherLine "    [1] Runtime prep         VC++, DirectX, prerequisites" $script:LauncherPalette.Text
    Write-LauncherLine "    [A] Full send            Apply the aggressive full stack" $script:LauncherPalette.Success
    Write-LauncherLine "    [R] Panic button         Revert the tracked changes" $script:LauncherPalette.Danger
    Write-Host ""

    Write-Host "  CORE TUNING" -ForegroundColor $script:LauncherPalette.Accent
    Write-LauncherLine "    [2] Power plan           Ultimate Performance profile" $script:LauncherPalette.Text
    Write-LauncherLine "    [3] Services             Disable background services" $script:LauncherPalette.Text
    Write-LauncherLine "    [4] Registry             Apply bundled registry tweaks" $script:LauncherPalette.Text
    Write-LauncherLine "    [5] Timer service        Install timer resolution service" $script:LauncherPalette.Text
    Write-LauncherLine "    [6] GPU MSI mode         Lower interrupt latency" $script:LauncherPalette.Text
    Write-LauncherLine "    [7] Network              Adapter-aware optimization" $script:LauncherPalette.Text
    Write-LauncherLine "    [8] VBS / Memory         Security trade-off preset" $script:LauncherPalette.Warning
    Write-LauncherLine "    [9] Cleanup              Debloat and temp cleanup" $script:LauncherPalette.Text
    Write-Host ""

    Write-Host "  TOOLS" -ForegroundColor $script:LauncherPalette.Accent
    Write-LauncherLine "    [V] Verify               Inspect what actually stuck" $script:LauncherPalette.Text
    Write-LauncherLine "    [D] DDU                  Safe-mode GPU clean removal flow" $script:LauncherPalette.Text
    Write-LauncherLine "    [G] Driver install       Clean GPU driver install + tune" $script:LauncherPalette.Text
    Write-LauncherLine "    [W] WinUtil              Chris Titus WinUtil launcher" $script:LauncherPalette.Text
    Write-Host ""

    Write-Host "  NOTE" -ForegroundColor $script:LauncherPalette.Warning
    Write-LauncherLine ("    {0}" -f $footnote) $script:LauncherPalette.Soft
    Write-Host ""
    Write-LauncherLine "    [Q] Quit" $script:LauncherPalette.Muted
    Write-Host ""
}

function Run-Script {
    param([string]$Path, [string]$Type = "ps1")

    $fullPath = Join-Path $PSScriptRoot $Path
    if (-not (Test-Path $fullPath)) {
        Write-Host "  [ERROR] Script not found: $Path" -ForegroundColor $script:LauncherPalette.Danger
        Read-Host "  Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "  >>> Launching $Path" -ForegroundColor $script:LauncherPalette.Accent
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor $script:LauncherPalette.Muted
    Write-Host ""

    if ($Type -eq "bat") {
        cmd /c "`"$fullPath`""
    } elseif ($Type -eq "reg") {
        Write-Host "  Applying registry file..." -ForegroundColor $script:LauncherPalette.Warning
        reg import "$fullPath" 2>&1 | Out-Null
        Write-Host "  [DONE] Registry file applied." -ForegroundColor $script:LauncherPalette.Success
    } else {
        # Run in child process so exit in sub-script doesn't kill launcher
        $null = Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $fullPath) `
            -PassThru -Wait
    }

    Write-Host ""
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor $script:LauncherPalette.Muted
    Read-Host "  Press Enter to return to menu"
}

# ---- Main Loop ----
do {
    Show-Menu
    $choice = Read-Host "  Enter choice"
    $choice = $choice.Trim().ToUpper()

    switch ($choice) {
        "0" { Run-Script "1 backup\create-backup.ps1" }
        "1" { Run-Script "0 prerequisites\install-runtimes.ps1" }
        "2" { Run-Script "2 power plan\configure-power.ps1" }
        "3" { Run-Script "4 services\disable-services.ps1" }
        "4" { Run-Script "5 registry tweaks\apply-all.reg" "reg" }
        "5" { Run-Script "5 registry tweaks\individual\install-timer-resolution-service.ps1" }
        "6" { Run-Script "6 gpu\enable-msi-mode.ps1" }
        "7" { Run-Script "7 network\optimize-network.ps1" }
        "8" { Run-Script "8 security vs performance\configure-vbs.ps1" }
        "9" {
            Run-Script "9 cleanup\debloat.ps1"
            Run-Script "9 cleanup\cleanup-temp.ps1"
        }
        "A" { Run-Script "APPLY-EVERYTHING.ps1" }
        "R" { Run-Script "REVERT-EVERYTHING.ps1" }
        "V" { Run-Script "10 verify\verify-tweaks.ps1" }
        "D" { Run-Script "DduAuto.ps1" }
        "G" { Run-Script "6 gpu\install-gpu-driver.ps1" }
        "W" { Run-Script "9 cleanup\chris-titus-winutil.bat" "bat" }
        "Q" { break }
        default {
            Write-Host "  Invalid choice. Try again." -ForegroundColor $script:LauncherPalette.Warning
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "Q")

Write-Host ""
Write-Host "  Session closed." -ForegroundColor $script:LauncherPalette.Accent
Write-Host ""
