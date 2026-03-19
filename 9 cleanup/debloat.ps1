# ============================================================
# Windows 11 Debloat Script (Smart)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Removes pre-installed bloatware apps that waste resources.
# Shows what will be removed with confirmation before acting.
# Records all removals in manifest for audit trail.
#
# Replaces: debloat.ps1 (dumb version)
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Debloat"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Windows 11 Debloat — Remove Bloatware Apps" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$state = Initialize-ToolkitState
$stepName = "debloat"

# Apps to remove — categorized by confidence level
$appsToRemove = @(
    @{ Name = "Clipchamp.Clipchamp";                   Desc = "Clipchamp Video Editor";    Tier = "Safe" }
    @{ Name = "Microsoft.BingNews";                    Desc = "Bing News";                 Tier = "Safe" }
    @{ Name = "Microsoft.BingWeather";                 Desc = "Bing Weather";              Tier = "Safe" }
    @{ Name = "Microsoft.GetHelp";                     Desc = "Get Help";                  Tier = "Safe" }
    @{ Name = "Microsoft.Getstarted";                  Desc = "Tips";                      Tier = "Safe" }
    @{ Name = "Microsoft.MicrosoftOfficeHub";          Desc = "Office Hub";                Tier = "Safe" }
    @{ Name = "Microsoft.MicrosoftSolitaireCollection"; Desc = "Solitaire Collection";     Tier = "Safe" }
    @{ Name = "Microsoft.MicrosoftStickyNotes";        Desc = "Sticky Notes";              Tier = "Safe" }
    @{ Name = "Microsoft.People";                      Desc = "People";                    Tier = "Safe" }
    @{ Name = "Microsoft.PowerAutomateDesktop";        Desc = "Power Automate";            Tier = "Safe" }
    @{ Name = "Microsoft.Todos";                       Desc = "Microsoft To Do";           Tier = "Safe" }
    @{ Name = "Microsoft.WindowsAlarms";               Desc = "Alarms & Clock";            Tier = "Safe" }
    @{ Name = "Microsoft.WindowsFeedbackHub";          Desc = "Feedback Hub";              Tier = "Safe" }
    @{ Name = "Microsoft.WindowsMaps";                 Desc = "Maps";                      Tier = "Safe" }
    @{ Name = "Microsoft.WindowsSoundRecorder";        Desc = "Sound Recorder";            Tier = "Safe" }
    @{ Name = "Microsoft.YourPhone";                   Desc = "Phone Link";                Tier = "Safe" }
    @{ Name = "Microsoft.ZuneMusic";                   Desc = "Groove Music / Media Player"; Tier = "Safe" }
    @{ Name = "Microsoft.ZuneVideo";                   Desc = "Movies & TV";               Tier = "Safe" }
    @{ Name = "MicrosoftCorporationII.QuickAssist";    Desc = "Quick Assist";              Tier = "Safe" }
    @{ Name = "MicrosoftTeams";                        Desc = "Teams (personal)";          Tier = "Safe" }
    @{ Name = "Microsoft.549981C3F5F10";               Desc = "Cortana";                   Tier = "Safe" }
    @{ Name = "Microsoft.GamingApp";                   Desc = "Xbox App";                  Tier = "Advanced" }
)

# Apps we NEVER remove (safety list)
$neverRemove = @(
    "Microsoft.WindowsStore"
    "Microsoft.WindowsTerminal"
    "Microsoft.WindowsCalculator"
    "Microsoft.Windows.Photos"
    "Microsoft.ScreenSketch"
    "Microsoft.Paint"
    "Microsoft.WindowsNotepad"
    "Microsoft.DesktopAppInstaller"
)

# ============================================================
# Scan installed apps
# ============================================================
Write-Host "  Scanning installed apps..." -ForegroundColor Gray
Write-Host ""

$toRemove = @()
$alreadyGone = @()

foreach ($app in $appsToRemove) {
    $package = Get-AppxPackage -Name $app.Name -ErrorAction SilentlyContinue
    if ($package) {
        $toRemove += $app
    } else {
        $alreadyGone += $app
    }
}

if ($alreadyGone.Count -gt 0) {
    Write-Host "  Already removed ($($alreadyGone.Count)):" -ForegroundColor Gray
    foreach ($app in $alreadyGone) {
        Write-Host "    [GONE] $($app.Desc)" -ForegroundColor DarkGreen
    }
    Write-Host ""
}

if ($toRemove.Count -eq 0) {
    Write-Host "  All bloatware already removed. Nothing to do." -ForegroundColor Green
    Add-ToolkitStepResult -Key $stepName -Tier "Safe" -Status "preexisting" -Reason "All bloatware already removed"
    Read-Host "Press Enter to exit"
    exit 0
}

# ============================================================
# Show confirmation with categorization
# ============================================================
$safeApps = @($toRemove | Where-Object { $_.Tier -eq "Safe" })
$advancedApps = @($toRemove | Where-Object { $_.Tier -eq "Advanced" })

Write-Host "  Will remove ($($toRemove.Count) apps):" -ForegroundColor Yellow
Write-Host ""

if ($safeApps.Count -gt 0) {
    Write-Host "  Safe to remove:" -ForegroundColor Green
    foreach ($app in $safeApps) {
        Write-Host "    $($app.Desc) ($($app.Name))" -ForegroundColor White
    }
}

if ($advancedApps.Count -gt 0) {
    Write-Host ""
    Write-Host "  Advanced (review carefully):" -ForegroundColor Yellow
    foreach ($app in $advancedApps) {
        Write-Host "    $($app.Desc) ($($app.Name))" -ForegroundColor Yellow
        if ($app.Name -eq "Microsoft.GamingApp") {
            Write-Host "      ^ Only remove if NOT using Xbox Game Pass" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "  Protected apps (NEVER removed):" -ForegroundColor DarkGray
Write-Host "    Calculator, Photos, Snipping Tool, Paint, Notepad," -ForegroundColor DarkGray
Write-Host "    Terminal, Store, winget" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "  Press Enter to continue"
Write-Host ""

# ============================================================
# Remove apps
# ============================================================
$removed = 0
$skipped = 0
$current = 0

foreach ($app in $toRemove) {
    $current++
    $package = Get-AppxPackage -Name $app.Name -ErrorAction SilentlyContinue
    if (-not $package) {
        Write-Host "  [$current/$($toRemove.Count)] $($app.Desc) — Already gone" -ForegroundColor Gray
        continue
    }

    Write-Host "  [$current/$($toRemove.Count)] $($app.Desc)..." -NoNewline
    try {
        $package | Remove-AppxPackage -ErrorAction Stop
        Record-ToolkitPackageRemoval -PackageName $app.Name
        Write-Host " Removed" -ForegroundColor Green
        $removed++
    } catch {
        Write-Host " Failed (may need Store)" -ForegroundColor Yellow
        $skipped++
    }
}

# ============================================================
# Remove provisioned packages (prevents reinstall on new users)
# ============================================================
Write-Host ""
Write-Host "  Removing provisioned packages..." -ForegroundColor Gray

$provRemoved = 0
$provSkipped = 0
foreach ($app in $toRemove) {
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq $app.Name }
    if ($provisioned) {
        try {
            $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
            Record-ToolkitPackageRemoval -PackageName $app.Name -Provisioned
            $provRemoved++
        } catch {
            $provSkipped++
        }
    }
}

if ($provRemoved -gt 0) {
    Write-Host "  Removed $provRemoved provisioned packages" -ForegroundColor Green
}
if ($provSkipped -gt 0) {
    Write-Host "  Skipped $provSkipped provisioned packages" -ForegroundColor Yellow
}

Add-ToolkitStepResult -Key $stepName -Tier "Safe" -Status "applied" `
    -Reason "Removed $removed apps, $provRemoved provisioned, $skipped failed"

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  DEBLOAT COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Removed:      $removed apps" -ForegroundColor Green
Write-Host "  Provisioned:  $provRemoved (prevents reinstall)" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "  Skipped:      $skipped apps (manual removal needed)" -ForegroundColor Yellow
}
Write-Host "  Already gone: $($alreadyGone.Count) apps" -ForegroundColor Gray
Write-Host ""
Write-Host "  Removals recorded in manifest for audit trail." -ForegroundColor Gray
Write-Host "  Note: Removed apps can be reinstalled from Microsoft Store." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to continue"
