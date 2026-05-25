<#
.SYNOPSIS
    Apply Microsoft's recommended pagefile sizing: initial = installed
    RAM × 1.0, maximum = installed RAM × 1.5, on the OS drive only.

.DESCRIPTION
    Captures the current pagefile config to a sidecar JSON, then sets
    custom sizing per the documented rule-of-thumb:
      Initial size = (TotalPhysicalMemory_GB) × 1024 MB
      Maximum size = (TotalPhysicalMemory_GB) × 1024 × 1.5 MB

    Disables AutomaticManagedPagefile and configures a single pagefile
    at C:\pagefile.sys (or %SystemDrive%\pagefile.sys).

    Why custom sizing over "let Windows manage it"?
      - System-managed is the safe default and what we recommend for
        most users (check-pagefile.ps1 reports OK on that).
      - Custom sizing matters when: (1) you want to PIN the file to
        a specific drive (low-latency NVMe vs spinning disk), or
        (2) you want a predictable size (some games' commit-charge
        behavior changes with pagefile size).
      - The 1.0x..1.5x range is Microsoft's documented recommendation
        for non-server workloads.

    Anti-cheat impact: NONE — Win32_PageFileSetting CIM mutation;
    not inspected by BattlEye / EAC / Vanguard.
    Reboot required: YES — Windows applies pagefile size changes
    on next boot.
    Disk impact: HIGH — initial pagefile.sys creation reserves
    (RAM × 1.0) GB on the OS drive on next boot.

.NOTES
    Tier: Advanced (changes pagefile on the OS drive)
    Pair: revert-pagefile.ps1
    Audit: 12 hardware/check-pagefile.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/client-management/determine-appropriate-page-file-size
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

. "$PSScriptRoot\..\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Configure Pagefile'
UI-Header -Title 'Configure Pagefile (Microsoft-recommended sizing)' -Subtitle 'Initial=RAM × 1.0, Max=RAM × 1.5'
UI-RequireAdmin -ScriptName 'Configure Pagefile'

Initialize-ToolkitState | Out-Null

if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
    UI-Note -Message '[SKIP] Get-CimInstance unavailable.' -Color $script:UI_Warning
    UI-Exit
    exit 1
}

$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if (-not $cs) {
    UI-Note -Message '[ERROR] Could not read Win32_ComputerSystem.' -Color $script:UI_Error
    UI-Exit
    exit 1
}

$totalRamGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$initialMB = [int]($totalRamGB * 1024)
$maxMB = [int]($totalRamGB * 1024 * 1.5)
$systemDrive = $env:SystemDrive
$pagefilePath = "$systemDrive\pagefile.sys"

UI-KeyValue -Label 'Installed RAM' -Value "$totalRamGB GB"
UI-KeyValue -Label 'Target Initial' -Value "$initialMB MB"
UI-KeyValue -Label 'Target Maximum' -Value "$maxMB MB"
UI-KeyValue -Label 'Pagefile path' -Value $pagefilePath
Write-Host ''

# Capture current state to sidecar BEFORE any change.
$beforeUsage = @(Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction SilentlyContinue)
$beforeSetting = @(Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction SilentlyContinue)
$snapshot = [PSCustomObject]@{
    AutomaticManagedPagefile = [bool]$cs.AutomaticManagedPagefile
    PagefileSettings = @($beforeSetting | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                InitialSize = $_.InitialSize
                MaximumSize = $_.MaximumSize
            }
        })
    PagefileUsage = @($beforeUsage | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                AllocatedBaseSize = $_.AllocatedBaseSize
            }
        })
}
$saved = Save-ToolkitSidecar -Name 'pagefile' -InputObject $snapshot
if ($saved) {
    UI-Note -Message "Captured pre-change pagefile config at $saved"
}

if (-not $PSCmdlet.ShouldProcess($pagefilePath, "Set Initial=$initialMB MB / Max=$maxMB MB")) {
    UI-Skip -Label 'Configure pagefile' -Reason '-WhatIf preview'
    UI-Exit
    exit 0
}

# Step 1: turn off AutomaticManagedPagefile.
UI-Step -Label 'Disabling AutomaticManagedPagefile' -Action {
    $cs2 = Get-CimInstance -ClassName Win32_ComputerSystem
    if ($cs2.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs2 -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop
    }
}

# Step 2: ensure a setting record exists for $pagefilePath, then update.
UI-Step -Label 'Setting pagefile sizes' -Action {
    $existing = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "Name='$($pagefilePath -replace '\\', '\\\\')'" -ErrorAction SilentlyContinue
    if ($existing) {
        Set-CimInstance -InputObject $existing -Property @{
            InitialSize = $initialMB
            MaximumSize = $maxMB
        } -ErrorAction Stop
    } else {
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{
            Name = $pagefilePath
            InitialSize = $initialMB
            MaximumSize = $maxMB
        } -ErrorAction Stop | Out-Null
    }
}

Add-ToolkitStepResult -Key 'pagefile-sizing' -Tier 'Advanced' -Status 'applied' `
    -Reason "Set pagefile Initial=$initialMB MB, Max=$maxMB MB on $pagefilePath"

UI-Summary -DoneMessage 'Pagefile configured' -Details @(
    'REBOOT REQUIRED — pagefile size changes take effect on next boot.',
    "Verify after reboot with: 12 hardware/check-pagefile.ps1"
) -RevertHint 'Run revert-pagefile.ps1 in this folder.'
UI-Exit
