#Requires -Version 5.1
<#
.SYNOPSIS
    Restore MMCSS Pro Audio scheduling to pre-toolkit defaults.

.DESCRIPTION
    Pair of tune-mmcss-audio.ps1. Restores each touched reg:MmcssProAudio*
    value via Restore-ToolkitRegistryValue (manifest-driven).

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Safe (restores OS-default scheduling)

    # CROSS-PLATFORM-NOTE
    # Windows-only registry path under HKLM\SOFTWARE\Microsoft\Windows NT\.

    Exit codes:
      0  All keys restored (or already at default)
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

UI-Header -Title 'Restore MMCSS Pro Audio defaults' -Subtitle 'Manifest-driven revert'
UI-RequireAdmin -ScriptName 'Restore MMCSS Pro Audio'
Initialize-ToolkitState | Out-Null

$ids = @(
    'reg:MmcssProAudioPriority'
    'reg:MmcssProAudioCategory'
    'reg:MmcssProAudioSfio'
    'reg:MmcssProAudioBackground'
)

$restored = 0
$missing = 0
foreach ($id in $ids) {
    if (-not $PSCmdlet.ShouldProcess($id, 'Restore-ToolkitRegistryValue')) {
        continue
    }
    if (Restore-ToolkitRegistryValue -Id $id) {
        Write-Host "  [OK] $id" -ForegroundColor Green
        $restored++
    } else {
        Write-Host "  [SKIP] $id (no manifest entry)" -ForegroundColor Gray
        $missing++
    }
}

Add-ToolkitStepResult -Key 'mmcss-audio-revert' -Tier 'Safe' -Status 'applied' `
    -Reason "Restored $restored entries, $missing missing from manifest"
exit 0
