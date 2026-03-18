# ============================================================
# Windows 11 Debloat Script
# Windows 11 Gaming Optimization Guide
# ============================================================
# Removes pre-installed bloatware apps that waste resources.
# Run as Administrator in PowerShell.
#
# Usage: Right-click > Run with PowerShell
#   OR: Open PowerShell as Admin, run: .\debloat.ps1
#
# NOTE: If you get an "execution policy" error, run this first:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Windows 11 Debloat — Remove Bloatware Apps" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check for admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run this script as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell > Run as Administrator, then run this script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Apps to remove — add or remove from this list as needed
$appsToRemove = @(
    "Clipchamp.Clipchamp"
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.GamingApp"                    # Xbox app (remove if not using Game Pass)
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"                   # Tips app
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.People"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.Todos"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.YourPhone"                    # Phone Link
    "Microsoft.ZuneMusic"                    # Groove Music / Media Player
    "Microsoft.ZuneVideo"                    # Movies & TV
    "MicrosoftCorporationII.QuickAssist"
    "MicrosoftTeams"                         # Teams personal (not work Teams)
    "Microsoft.549981C3F5F10"                # Cortana
)

# Apps we NEVER remove (safety list)
$neverRemove = @(
    "Microsoft.WindowsStore"
    "Microsoft.WindowsTerminal"
    "Microsoft.WindowsCalculator"
    "Microsoft.Windows.Photos"
    "Microsoft.ScreenSketch"                 # Snipping Tool
    "Microsoft.Paint"
    "Microsoft.WindowsNotepad"
    "Microsoft.DesktopAppInstaller"          # winget
)

Write-Host "Removing bloatware apps..." -ForegroundColor Yellow
Write-Host ""

$removed = 0
$skipped = 0

foreach ($app in $appsToRemove) {
    $package = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
    if ($package) {
        Write-Host "  Removing: $($package.Name)..." -NoNewline
        try {
            $package | Remove-AppxPackage -ErrorAction Stop
            Write-Host " Done" -ForegroundColor Green
            $removed++
        } catch {
            Write-Host " Failed (may need Store to uninstall)" -ForegroundColor Yellow
            $skipped++
        }
    }
}

# Also remove provisioned packages (prevents reinstall on new user accounts)
Write-Host ""
Write-Host "Removing provisioned packages (prevents reinstall)..." -ForegroundColor Yellow
foreach ($app in $appsToRemove) {
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $app }
    if ($provisioned) {
        try {
            $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
        } catch {
            # Silently skip — not critical
        }
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Removed: $removed apps" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "  Skipped: $skipped apps (manual removal needed)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Apps NOT removed (safe list): Calculator, Photos," -ForegroundColor Gray
Write-Host "  Snipping Tool, Paint, Notepad, Terminal, Store" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
