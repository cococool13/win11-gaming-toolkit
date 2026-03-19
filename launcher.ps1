# ============================================================
# Windows 11 Gaming Optimization - Launcher
# ============================================================

. "$PSScriptRoot\lib\toolkit-state.ps1"
. "$PSScriptRoot\lib\ui-helpers.ps1"
. "$PSScriptRoot\lib\launcher-menu.ps1"

$Host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimization - Launcher"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"

function Get-LauncherRiskNote {
    param($Profile)

    if ($Profile.isLaptop -or $Profile.isHybridGraphics) {
        return "Laptop or hybrid graphics detected. Start with Setup, then use only the areas you understand."
    }

    if ($Profile.partOfDomain) {
        return "Domain-joined system detected. Some policy-based changes may be reverted by your organization."
    }

    return "Desktop profile detected. Use Apply Everything only after reading the guide and revert path."
}

function Show-Menu {
    Clear-Host
    $profile = Get-ToolkitMachineProfile
    $menu = Get-LauncherMenu

    UI-Header -Title "Windows 11 Gaming Optimization" -Subtitle "Primary entrypoint for setup, tuning, revert, and verification"
    UI-ShowProfile -Profile $profile
    Write-Host ""

    foreach ($section in $menu) {
        UI-Section -Title $section.Title
        foreach ($item in $section.Items) {
            $keyColor = switch ($item.Key) {
                "A" { $script:UI_Success }
                "R" { $script:UI_Error }
                "8" { $script:UI_Warning }
                default { $script:UI_Label }
            }

            Write-Host ("    [{0}] {1,-18} {2}" -f $item.Key, $item.Label, $item.Summary) -ForegroundColor $keyColor
        }
    }

    UI-Section -Title "Guidance"
    UI-Note -Message (Get-LauncherRiskNote -Profile $profile) -Color $script:UI_Warning
    UI-Note -Message "Read GUIDE.md first if you are not sure which path fits your machine." -Color $script:UI_Info
    Write-Host ""
    Write-Host "    [Q] Quit" -ForegroundColor $script:UI_Soft
    Write-Host ""
}

function Get-LauncherItemMap {
    $map = @{}
    foreach ($section in Get-LauncherMenu) {
        foreach ($item in $section.Items) {
            $map[$item.Key] = $item
        }
    }
    return $map
}

function Invoke-LauncherSelection {
    param([string]$Choice)

    $items = Get-LauncherItemMap
    if (-not $items.ContainsKey($Choice)) {
        Write-Host "  Invalid choice. Try again." -ForegroundColor $script:UI_Warning
        Start-Sleep -Seconds 1
        return
    }

    $item = $items[$Choice]
    Write-Host ""
    Write-Host "  >>> Launching $($item.Label)" -ForegroundColor $script:UI_Header
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor $script:UI_Section
    Write-Host ""

    switch ($item.Type) {
        "bat" {
            $fullPath = Join-Path $PSScriptRoot $item.Path
            cmd /c "`"$fullPath`""
        }
        "reg" {
            $fullPath = Join-Path $PSScriptRoot $item.Path
            reg import "$fullPath" 2>&1 | Out-Null
            UI-Note -Message "[DONE] Registry file applied." -Color $script:UI_Success
        }
        "bundle" {
            Start-Process -FilePath "powershell.exe" `
                -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "9 cleanup\debloat.ps1")) `
                -PassThru -Wait | Out-Null
            Start-Process -FilePath "powershell.exe" `
                -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "9 cleanup\cleanup-temp.ps1")) `
                -PassThru -Wait | Out-Null
        }
        default {
            $fullPath = Join-Path $PSScriptRoot $item.Path
            Start-Process -FilePath "powershell.exe" `
                -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $fullPath) `
                -PassThru -Wait | Out-Null
        }
    }

    Write-Host ""
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor $script:UI_Section
    Read-Host "  Press Enter to return to menu"
}

UI-RequireAdmin -ScriptName "This launcher"

do {
    Show-Menu
    $choice = (Read-Host "  Enter choice").Trim().ToUpper()
    if ($choice -ne "Q") {
        Invoke-LauncherSelection -Choice $choice
    }
} while ($choice -ne "Q")

Write-Host ""
Write-Host "  Session closed." -ForegroundColor $script:UI_Header
Write-Host ""
