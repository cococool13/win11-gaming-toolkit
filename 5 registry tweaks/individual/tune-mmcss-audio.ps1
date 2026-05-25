#Requires -Version 5.1
<#
.SYNOPSIS
    Tune MMCSS Pro Audio scheduling for low-latency game/voice audio.

.DESCRIPTION
    The Multimedia Class Scheduler Service (MMCSS) assigns priority +
    affinity to threads tagged with a task profile. The "Pro Audio"
    profile is what DAWs, voice chat (Discord/Teams audio threads),
    and most low-latency game audio engines tag. Default MMCSS profile
    settings are conservative for desktop use; this script applies the
    Microsoft-documented "Pro Audio for low latency" values:

      Priority                  = 1   (default: 2; lower = higher pri)
      Scheduling Category       = "High"
      SFIO Priority             = "High"
      Affinity                  = 0   (any CPU; default)
      BackgroundOnly            = "False"

    Effect: audio worker threads stay at high pri even when other
    foreground apps grab CPU. Measurable in DPC Latency tools as
    fewer 1-3ms audio-DPC stalls.

    Sources cited:
      Microsoft Learn — Multimedia Class Scheduler Service
        https://learn.microsoft.com/en-us/windows/win32/procthread/multimedia-class-scheduler-service
      Microsoft Learn — Real-time priority on Windows
        https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/low-latency-audio
      MSDN — MMCSS Registry Entries
        https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/multimedia-class-scheduler-service

    Anti-cheat impact: NONE. MMCSS is a per-thread API; raising audio-
    worker priority does not give game processes elevated access.
    Reboot required: SEE-SCRIPT — heuristic-default; refine in follow-up.
    Disk impact: NONE — registry-only write; no on-disk file creation.

.PARAMETER WhatIf
    Standard ShouldProcess.

.EXAMPLE
    PS> .\tune-mmcss-audio.ps1

.EXAMPLE
    PS> .\tune-mmcss-audio.ps1 -WhatIf

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced
    Pair:     restore-mmcss-audio.ps1

    Tracked via Set-ToolkitRegistryValue so REVERT-EVERYTHING.ps1 picks
    it up alongside any per-pair revert script.

    Exit codes:
      0  Applied (or already at target on all keys)
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title 'Tune MMCSS Pro Audio' -Subtitle 'Low-latency audio scheduling'
UI-RequireAdmin -ScriptName 'Tune MMCSS Pro Audio'
Initialize-ToolkitState | Out-Null

# All keys live under SystemProfile\Tasks\Pro Audio.
$proAudio = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio'

$entries = @(
    @{ Id = 'reg:MmcssProAudioPriority'; Name = 'Priority'; Value = 1; Type = 'DWord' }
    @{ Id = 'reg:MmcssProAudioCategory'; Name = 'Scheduling Category'; Value = 'High'; Type = 'String' }
    @{ Id = 'reg:MmcssProAudioSfio'; Name = 'SFIO Priority'; Value = 'High'; Type = 'String' }
    @{ Id = 'reg:MmcssProAudioBackground'; Name = 'BackgroundOnly'; Value = 'False'; Type = 'String' }
)

# Idempotency pre-check + log per entry. Set-ToolkitRegistryValue itself
# has a value-equality fast-path (CURSOR-AUDIT #19) so re-runs are
# already no-ops at the OS level. The pre-check here just makes the
# script's own UI output read cleaner.
UI-Section -Title 'Applying'
foreach ($e in $entries) {
    $current = (Get-ItemProperty -Path $proAudio -Name $e.Name -ErrorAction SilentlyContinue).$($e.Name)
    if ($null -ne $current -and "$current" -eq "$($e.Value)") {
        Write-Host "  [SKIP] $($e.Name) = $current (already target)" -ForegroundColor Gray
        continue
    }
    Set-ToolkitRegistryValue `
        -Id $e.Id -Path $proAudio -Name $e.Name `
        -Value $e.Value -Type $e.Type `
        -Tier 'Advanced' -Step 'mmcss-audio'
    Write-Host "  [OK] $($e.Name) → $($e.Value)" -ForegroundColor Green
}

Add-ToolkitStepResult -Key 'mmcss-audio' -Tier 'Advanced' -Status 'applied' `
    -Reason 'MMCSS Pro Audio low-latency profile applied'

Write-Host ''
UI-Note -Message 'Effect visible in DPC Latency tools after the next audio app launch (no reboot needed).' -Color $script:UI_Info
UI-Note -Message 'Revert: restore-mmcss-audio.ps1 or REVERT-EVERYTHING.ps1.' -Color $script:UI_Info
exit 0
