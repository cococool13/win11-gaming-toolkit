#Requires -Version 5.1
<#
.SYNOPSIS
    Verify TRIM is enabled for SSDs and report fixed-disk health.

.DESCRIPTION
    Read-only by default. Three reports per fixed disk:
      1. Media type (SSD / HDD / unknown) from Get-PhysicalDisk
      2. NTFS TRIM enabled per fsutil behavior query DisableDeleteNotify
         (DisableDeleteNotify=0 means TRIM ON; =1 means TRIM OFF)
      3. ReFS TRIM enabled per fsutil behavior query DisableDeleteNotify ReFS

    On Windows 10/11, TRIM is on by default for NTFS on SSDs. Some clone
    operations, debloat ISOs, and third-party tools have been known to
    flip it off. This script catches that drift.

    Pass -Fix to enable TRIM via fsutil if disabled. Requires admin.
    Pass -Force with -Fix to skip the per-volume confirmation.

.PARAMETER Fix
    If TRIM is disabled (DisableDeleteNotify=1 for NTFS or ReFS), set
    it to 0. Default is report-only.

.PARAMETER Force
    Skip the Read-Host confirmation when paired with -Fix.

.EXAMPLE
    PS> .\check-storage.ps1
    Report current TRIM state for every fixed disk. No mutation.

.EXAMPLE
    PS> .\check-storage.ps1 -Fix
    Report + enable TRIM where disabled (prompts per change).

.EXAMPLE
    PS> .\check-storage.ps1 -Fix -Force -WhatIf
    Show what would be enabled without actually writing.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Safe (read-only) / Advanced (with -Fix)
    Sources:  Microsoft Learn — fsutil behavior
              https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior

    Exit codes:
      0  All TRIM checks passed (or -Fix was successful)
      1  User declined a -Fix prompt
      2  Required cmdlet unavailable (Get-PhysicalDisk missing)
      3  fsutil call failed in an unexpected way
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param(
    [switch]$Fix,
    [switch]$Force
)

. (Join-Path $PSScriptRoot '..' 'lib/toolkit-state.ps1')
. (Join-Path $PSScriptRoot '..' 'lib/ui-helpers.ps1')

UI-Header -Title 'Storage Check' -Subtitle 'TRIM state per fixed disk'

if (-not (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue)) {
    Write-Host '  [ERROR] Get-PhysicalDisk cmdlet not available.' -ForegroundColor Red
    Write-Host '          Requires Windows 8+ / Server 2012+. Install Storage module:' -ForegroundColor Yellow
    Write-Host '            Add-WindowsCapability -Online -Name Storage~~~~' -ForegroundColor Gray
    exit 2
}

if ($Fix) {
    UI-RequireAdmin -ScriptName 'check-storage.ps1 -Fix'
    Initialize-ToolkitState | Out-Null
    Write-ToolkitLog 'storage-check-started' -Data @{ mode = 'fix' }
} else {
    Write-ToolkitLog 'storage-check-started' -Data @{ mode = 'report' }
}

# --- Per-disk media report -----------------------------------------------
$disks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue |
        Where-Object { $_.BusType -ne 'USB' })

if ($disks.Count -eq 0) {
    Write-Host '  [SKIP] No non-USB physical disks detected.' -ForegroundColor Yellow
    exit 0
}

UI-Section -Title 'Physical disks'
foreach ($d in $disks) {
    $media = switch ($d.MediaType) {
        'SSD' { 'SSD' }
        'HDD' { 'HDD' }
        'SCM' { 'Storage Class Memory' }
        default { 'unknown' }
    }
    Write-Host ("    {0,-20} {1,-8} {2}" -f $d.FriendlyName, $media, "(bus: $($d.BusType))") -ForegroundColor White
}
Write-Host ''

# --- NTFS TRIM check ------------------------------------------------------
function Get-FsutilTrimSetting {
    <#
    .SYNOPSIS
        Parse `fsutil behavior query DisableDeleteNotify [<fs>]`.
    .OUTPUTS
        PSCustomObject with .Filesystem (NTFS / ReFS) and .TrimEnabled (bool / $null on parse failure).
    #>
    [CmdletBinding()]
    param([ValidateSet('NTFS', 'ReFS')][string]$Filesystem)
    $argList = @('behavior', 'query', 'DisableDeleteNotify')
    if ($Filesystem -eq 'ReFS') { $argList += 'ReFS' }
    $output = & fsutil @argList 2>&1
    if ($LASTEXITCODE -ne 0) {
        return [PSCustomObject]@{ Filesystem = $Filesystem; TrimEnabled = $null; Raw = "$output" }
    }
    # Output forms:
    #   NTFS DisableDeleteNotify = 0
    #   NTFS DisableDeleteNotify is not currently set
    if ($output -match 'DisableDeleteNotify\s*=\s*(\d+)') {
        $disabled = [int]$Matches[1]
        return [PSCustomObject]@{ Filesystem = $Filesystem; TrimEnabled = ($disabled -eq 0); Raw = "$output" }
    }
    if ($output -match 'is not currently set') {
        # Not explicitly set = default behavior = TRIM enabled.
        return [PSCustomObject]@{ Filesystem = $Filesystem; TrimEnabled = $true; Raw = "$output" }
    }
    return [PSCustomObject]@{ Filesystem = $Filesystem; TrimEnabled = $null; Raw = "$output" }
}

UI-Section -Title 'TRIM (DisableDeleteNotify)'
$exitCode = 0
foreach ($fs in 'NTFS', 'ReFS') {
    $trim = Get-FsutilTrimSetting -Filesystem $fs
    if ($null -eq $trim.TrimEnabled) {
        Write-Host ("    {0,-6} state: unparseable ({1})" -f $fs, $trim.Raw.Trim()) -ForegroundColor Yellow
        Write-ToolkitLog 'storage-trim-unparseable' -Level warn -Data @{ filesystem = $fs; raw = $trim.Raw.Trim() }
        continue
    }
    if ($trim.TrimEnabled) {
        Write-Host ("    {0,-6} TRIM: ENABLED" -f $fs) -ForegroundColor Green
        Write-ToolkitLog 'storage-trim-ok' -Data @{ filesystem = $fs; enabled = $true }
        continue
    }

    Write-Host ("    {0,-6} TRIM: DISABLED" -f $fs) -ForegroundColor Red
    Write-ToolkitLog 'storage-trim-bad' -Level warn -Data @{ filesystem = $fs; enabled = $false }

    if (-not $Fix) {
        $exitCode = 1
        Write-Host ("    {0,-6}    Re-run with -Fix to enable." -f '') -ForegroundColor Yellow
        continue
    }

    # -Fix path
    if (-not $Force) {
        $answer = Read-Host ("    Enable $fs TRIM via 'fsutil behavior set DisableDeleteNotify $fs 0'? (y/N)")
        if ($answer.Trim().ToUpper() -ne 'Y') {
            Write-Host ("    {0,-6}    Skipped by user." -f '') -ForegroundColor Gray
            Write-ToolkitLog 'storage-trim-fix-declined' -Level warn -Data @{ filesystem = $fs }
            $exitCode = 1
            continue
        }
    }

    if (-not $PSCmdlet.ShouldProcess("$fs TRIM", "fsutil behavior set DisableDeleteNotify $fs 0")) {
        Write-Host ("    {0,-6}    Skipped (-WhatIf)." -f '') -ForegroundColor Gray
        continue
    }

    $setArgs = @('behavior', 'set', 'DisableDeleteNotify', $fs, '0')
    $setOutput = & fsutil @setArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ("    {0,-6}    Enabled." -f '') -ForegroundColor Green
        Write-ToolkitLog 'storage-trim-fixed' -Data @{ filesystem = $fs }
    } else {
        Write-Host ("    {0,-6}    fsutil failed (exit $LASTEXITCODE): $setOutput" -f '') -ForegroundColor Red
        Write-ToolkitLog 'storage-trim-fix-failed' -Level error -Data @{
            filesystem = $fs; exit = $LASTEXITCODE; output = "$setOutput"
        }
        $exitCode = 3
    }
}
Write-Host ''

if ($Fix) {
    UI-Note -Message 'Reboot is not required — TRIM takes effect on the next storage flush.' -Color $script:UI_Info
}

Write-ToolkitLog 'storage-check-completed' -Data @{ exitCode = $exitCode }
exit $exitCode
