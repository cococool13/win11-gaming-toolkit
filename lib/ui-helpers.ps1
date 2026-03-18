# ============================================================
# Shared UI Helper Functions
# Windows 11 Gaming Optimization Guide
# ============================================================
# Dot-source this file from any script:
#   . "$PSScriptRoot\..\lib\ui-helpers.ps1"
#   -or-
#   . "$PSScriptRoot\lib\ui-helpers.ps1"
# ============================================================

# ---- Brand Colors ----
$script:UI_Header    = "Cyan"
$script:UI_Section   = "DarkGray"
$script:UI_Success   = "Green"
$script:UI_Error     = "Red"
$script:UI_Warning   = "Yellow"
$script:UI_Info      = "Gray"
$script:UI_Accent    = "Magenta"
$script:UI_Label     = "White"

# ---- Counters ----
$script:UI_Succeeded = 0
$script:UI_Failed    = 0
$script:UI_Warned    = 0

function UI-ResetCounters {
    $script:UI_Succeeded = 0
    $script:UI_Failed    = 0
    $script:UI_Warned    = 0
}

# ---- Admin Check ----
function UI-RequireAdmin {
    param([string]$ScriptName = "This script")
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host ""
        Write-Host "  [ERROR] $ScriptName must be run as Administrator." -ForegroundColor $script:UI_Error
        Write-Host "  Right-click the script > 'Run with PowerShell' (as Admin)" -ForegroundColor $script:UI_Error
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ---- Internet Check ----
function UI-RequireInternet {
    if (-not (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "  [ERROR] Internet connection required." -ForegroundColor $script:UI_Error
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ---- Header ----
function UI-Header {
    param(
        [string]$Title,
        [string]$Subtitle = "",
        [string]$Color = $script:UI_Header
    )
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor $Color
    Write-Host "    $Title" -ForegroundColor $Color
    if ($Subtitle) {
        Write-Host "    $Subtitle" -ForegroundColor $Color
    }
    Write-Host "  ============================================================" -ForegroundColor $Color
    Write-Host ""
}

# ---- Section ----
function UI-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ------------------------------------------------------------" -ForegroundColor $script:UI_Section
    Write-Host "    $Title" -ForegroundColor $script:UI_Label
    Write-Host "  ------------------------------------------------------------" -ForegroundColor $script:UI_Section
    Write-Host ""
}

# ---- Run a step with inline status ----
function UI-Step {
    param(
        [string]$Label,
        [scriptblock]$Action,
        [switch]$NonCritical
    )
    Write-Host "    $Label..." -NoNewline -ForegroundColor $script:UI_Info
    try {
        & $Action
        Write-Host " Done" -ForegroundColor $script:UI_Success
        $script:UI_Succeeded++
    } catch {
        if ($NonCritical) {
            Write-Host " Skipped" -ForegroundColor $script:UI_Warning
            $script:UI_Warned++
        } else {
            Write-Host " Failed" -ForegroundColor $script:UI_Error
            Write-Host "      $($_.Exception.Message)" -ForegroundColor $script:UI_Error
            $script:UI_Failed++
        }
    }
}

# ---- Summary Footer ----
function UI-Summary {
    param(
        [string]$DoneMessage = "Operation complete",
        [string]$RevertHint  = ""
    )
    $total = $script:UI_Succeeded + $script:UI_Failed + $script:UI_Warned
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor $script:UI_Header
    if ($script:UI_Failed -eq 0) {
        Write-Host "    [DONE] $DoneMessage" -ForegroundColor $script:UI_Success
    } else {
        Write-Host "    [DONE] $DoneMessage (with errors)" -ForegroundColor $script:UI_Warning
    }
    Write-Host ""
    Write-Host "    Succeeded: $($script:UI_Succeeded)" -ForegroundColor $script:UI_Success
    if ($script:UI_Warned -gt 0) {
        Write-Host "    Skipped:   $($script:UI_Warned)" -ForegroundColor $script:UI_Warning
    }
    if ($script:UI_Failed -gt 0) {
        Write-Host "    Failed:    $($script:UI_Failed)" -ForegroundColor $script:UI_Error
    }
    if ($RevertHint) {
        Write-Host ""
        Write-Host "    To revert: $RevertHint" -ForegroundColor $script:UI_Info
    }
    Write-Host "  ============================================================" -ForegroundColor $script:UI_Header
    Write-Host ""
}

# ---- Confirm Prompt ----
function UI-Confirm {
    param(
        [string]$Message = "Continue?",
        [string[]]$Warnings = @()
    )
    if ($Warnings.Count -gt 0) {
        Write-Host ""
        foreach ($w in $Warnings) {
            Write-Host "    [!] $w" -ForegroundColor $script:UI_Warning
        }
    }
    Write-Host ""
    Write-Host "    Press Ctrl+C to cancel, or" -ForegroundColor $script:UI_Warning
    Read-Host "    Press Enter to continue"
}

# ---- Exit Prompt ----
function UI-Exit {
    Write-Host ""
    Read-Host "  Press Enter to exit"
}
