# ============================================================
# Windows 11 Gaming Optimization — Launcher
# ============================================================
# Interactive menu to run any optimization step.
# Run as Administrator in PowerShell.
# ============================================================

$Host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimization — Launcher"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  [ERROR] This launcher must be run as Administrator." -ForegroundColor Red
    Write-Host "  Right-click > 'Run with PowerShell' (as Admin)" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "    WINDOWS 11 GAMING OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "    Interactive Launcher" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  --- SETUP ---" -ForegroundColor DarkGray
    Write-Host "    [0]  Create Restore Point & Registry Backup" -ForegroundColor White
    Write-Host "    [1]  Install Gaming Prerequisites (VC++, DirectX)" -ForegroundColor White
    Write-Host ""
    Write-Host "  --- OPTIMIZE ---" -ForegroundColor DarkGray
    Write-Host "    [2]  Enable Ultimate Performance Power Plan" -ForegroundColor White
    Write-Host "    [3]  Disable Unnecessary Services" -ForegroundColor White
    Write-Host "    [4]  Apply Registry Tweaks (all at once)" -ForegroundColor White
    Write-Host "    [5]  Install Timer Resolution Service" -ForegroundColor White
    Write-Host "    [6]  Enable GPU MSI Mode" -ForegroundColor White
    Write-Host "    [7]  Optimize Network Settings" -ForegroundColor White
    Write-Host "    [8]  Disable VBS / Memory Integrity" -ForegroundColor Yellow
    Write-Host "    [9]  Cleanup Temp Files & Caches" -ForegroundColor White
    Write-Host ""
    Write-Host "  --- ALL-IN-ONE ---" -ForegroundColor DarkGray
    Write-Host "    [A]  APPLY EVERYTHING (recommended)" -ForegroundColor Green
    Write-Host "    [R]  REVERT EVERYTHING" -ForegroundColor Red
    Write-Host ""
    Write-Host "  --- SESSION ---" -ForegroundColor DarkGray
    Write-Host "    [G]  Gaming Mode ON (pre-game optimizer)" -ForegroundColor Magenta
    Write-Host "    [O]  Gaming Mode OFF (restore normal)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  --- TOOLS ---" -ForegroundColor DarkGray
    Write-Host "    [V]  Verify Tweaks (health check)" -ForegroundColor White
    Write-Host "    [D]  DDU — Clean GPU Driver (auto mode)" -ForegroundColor White
    Write-Host "    [W]  Chris Titus WinUtil" -ForegroundColor White
    Write-Host ""
    Write-Host "    [Q]  Quit" -ForegroundColor DarkGray
    Write-Host ""
}

function Run-Script {
    param([string]$Path, [string]$Type = "ps1")
    $fullPath = Join-Path $PSScriptRoot $Path
    if (-not (Test-Path $fullPath)) {
        Write-Host "  [ERROR] Script not found: $Path" -ForegroundColor Red
        Read-Host "  Press Enter to continue"
        return
    }
    Write-Host ""
    Write-Host "  Running: $Path" -ForegroundColor Cyan
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    if ($Type -eq "bat") {
        cmd /c "`"$fullPath`""
    } elseif ($Type -eq "reg") {
        Write-Host "  Applying registry file..." -ForegroundColor Yellow
        reg import "$fullPath" 2>&1 | Out-Null
        Write-Host "  [DONE] Registry file applied." -ForegroundColor Green
    } else {
        & $fullPath
    }

    Write-Host ""
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    Read-Host "  Press Enter to return to menu"
}

# ---- Main Loop ----
do {
    Show-Menu
    $choice = Read-Host "  Enter choice"
    $choice = $choice.Trim().ToUpper()

    switch ($choice) {
        "0" {
            Run-Script "1 backup\create-restore-point.bat" "bat"
            Run-Script "1 backup\backup-registry.bat" "bat"
        }
        "1" { Run-Script "0 prerequisites\install-runtimes.ps1" }
        "2" { Run-Script "2 power plan\enable-ultimate-performance.bat" "bat" }
        "3" { Run-Script "4 services\apply-all.bat" "bat" }
        "4" { Run-Script "5 registry tweaks\apply-all.reg" "reg" }
        "5" { Run-Script "5 registry tweaks\individual\install-timer-resolution-service.ps1" }
        "6" { Run-Script "6 gpu\enable-msi-mode.ps1" }
        "7" { Run-Script "7 network\optimize-network.bat" "bat" }
        "8" { Run-Script "8 security vs performance\disable-vbs.bat" "bat" }
        "9" { Run-Script "9 cleanup\cleanup-temp.bat" "bat" }
        "A" { Run-Script "APPLY-EVERYTHING.ps1" }
        "R" { Run-Script "REVERT-EVERYTHING.ps1" }
        "G" { Run-Script "gaming-mode.ps1" }
        "O" { Run-Script "gaming-mode-off.ps1" }
        "V" { Run-Script "10 verify\verify-tweaks.ps1" }
        "D" { Run-Script "DduAuto.ps1" }
        "W" { Run-Script "9 cleanup\chris-titus-winutil.bat" "bat" }
        "Q" { break }
        default {
            Write-Host "  Invalid choice. Try again." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "Q")

Write-Host ""
Write-Host "  Goodbye!" -ForegroundColor Cyan
Write-Host ""
