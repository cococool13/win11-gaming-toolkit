# ============================================================
# Re-enable Windows Defender (Wholesale)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Tier: Safe (restores OS default)
#
# Pair with: disable-defender-wholesale.ps1
# Restores every reg:Defender* manifest entry. Falls back to direct
# Remove-ItemProperty for keys not in the manifest.
#
# Anti-cheat impact: NONE — restorer for Defender state; returns to
# OS default. Re-enabling Defender carries no anti-cheat vendor
# policy risk (vendors don't refuse to launch based on Defender on).
#
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title "Re-enable Windows Defender" -Subtitle "Manifest-driven restore"
UI-RequireAdmin -ScriptName "Re-enable Windows Defender"

Initialize-ToolkitState | Out-Null
$state = Get-ToolkitState

$restored = 0
if ($state -and $state.PSObject.Properties["registry"] -and $state.registry) {
    $regKeys = @()
    if ($state.registry -is [hashtable]) {
        $regKeys = @($state.registry.Keys)
    } else {
        $regKeys = @($state.registry.PSObject.Properties.Name)
    }
    foreach ($id in $regKeys) {
        if ($id -like "reg:Defender*") {
            UI-Step -Label "Restoring $id" -Action {
                Restore-ToolkitRegistryValue -Id $id | Out-Null
            }
            $restored++
        }
    }
}

# Best-effort defaults restore via Set-MpPreference. Tamper Protection
# almost never blocks an *enable* operation, but on stripped images
# Set-MpPreference itself may be absent — catch logs that case.
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
    Set-MpPreference -DisableIOAVProtection $false -ErrorAction Stop
} catch {
    Write-Host "  [INFO] Set-MpPreference fallback unavailable; manifest restore handled the primary path." -ForegroundColor DarkGray
    Write-Host "         $($_.Exception.Message)" -ForegroundColor DarkGray
}

if ($restored -eq 0) {
    UI-Note -Message "No Defender entries in manifest. Removing policy keys blindly as a fallback." -Color $script:UI_Warning
    foreach ($path in @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        )) {
        if (Test-Path $path) {
            foreach ($name in @(
                    "DisableAntiSpyware", "DisableAntiVirus",
                    "DisableRealtimeMonitoring", "DisableBehaviorMonitoring", "DisableOnAccessProtection",
                    "SpynetReporting", "SubmitSamplesConsent"
                )) {
                Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
            }
        }
    }
}

Add-ToolkitStepResult -Key "defender-wholesale-revert" -Tier "Safe" -Status "applied" `
    -Reason "Defender wholesale-disable policies reverted ($restored manifest entries restored)"

Write-Host ""
Write-Host "  [DONE] Defender policies reverted." -ForegroundColor Green
Write-Host "  Reboot for full effect. Verify in Windows Security UI." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
