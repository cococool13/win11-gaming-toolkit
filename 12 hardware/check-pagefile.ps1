<#
.SYNOPSIS
    Read-only audit of the Windows pagefile configuration — reports
    current size, max size, location, and a recommended sizing range
    based on installed RAM.

.DESCRIPTION
    The pagefile is one of the most-misunderstood gaming-PC tweaks.
    Common bad advice (mostly carryover from XP / Win7 era):
      - "Disable the pagefile entirely on 32GB+ systems" — UNSAFE:
        many DX11/12 titles crash on commit-charge exhaustion when no
        pagefile is present, even with 64GB RAM, because the OS
        reserves working-set without backing storage.
      - "Set the pagefile to a fixed 4GB" — WRONG: too small for
        games that use commit-charge as a backing reservation.

    Microsoft's CURRENT recommendation (per the docs cited in NOTES)
    is "let Windows manage it" unless you have a specific reason.
    For competitive gaming, the recommended-but-stable shape is:
      Initial = installed RAM × 1.0  (Microsoft default rule-of-thumb)
      Maximum = installed RAM × 1.5  (allows growth without fragmenting)
    On systems with multiple drives, place the pagefile on the FASTEST
    drive (typically the NVMe OS drive).

    This script reports:
      - Total installed RAM
      - Current pagefile location(s) + sizes (initial / max / current
        usage)
      - System-managed vs custom-sized flag
      - Recommended initial/max based on RAM
      - Verdict: OK / TOO_SMALL / NO_PAGEFILE / OK_BUT_NOT_OPTIMAL

    Anti-cheat impact: NONE (pure CIM read).
    Reboot required: NO.
    Disk impact: NONE.

    -AsObject emits records for pipeline use.

.PARAMETER AsObject
    Emit [PSCustomObject] records.

.NOTES
    Tier: Safe (read-only)
    Pair: pagefile-sizing.ps1 (mutator) + revert-pagefile.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/windows/client-management/determine-appropriate-page-file-size

    # CROSS-PLATFORM-NOTE
    # Windows-only (Get-CimInstance). Returns @() on non-Windows.
#>
[CmdletBinding()]
param(
    [switch]$AsObject
)

. "$PSScriptRoot\..\lib\ui-helpers.ps1"

if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
    if ($AsObject) { return @() }
    UI-Header -Title 'Pagefile Audit' -Subtitle 'Read-only'
    UI-Note -Message '[SKIP] Get-CimInstance unavailable (non-Windows / stripped image).' -Color $script:UI_Warning
    return
}

# Total RAM via Win32_ComputerSystem (returns bytes).
$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$totalRamGB = if ($cs) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 1) } else { 0 }

# Pagefile records. Two CIM classes:
#   Win32_PageFileUsage — runtime stats (CurrentUsage, PeakUsage)
#   Win32_PageFileSetting — configured InitialSize / MaximumSize
# Join by Name (file path).
$usage = @(Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction SilentlyContinue)
$setting = @(Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction SilentlyContinue)
$autoManaged = if ($cs) { $cs.AutomaticManagedPagefile } else { $false }

$recommendedInitialMB = [int]($totalRamGB * 1024)
$recommendedMaxMB = [int]($totalRamGB * 1024 * 1.5)

function Get-PagefileVerdict {
    param(
        [Parameter(Mandatory)][object[]]$Usage,
        [Parameter(Mandatory)][object[]]$Setting,
        [Parameter(Mandatory)][bool]$AutoManaged,
        [Parameter(Mandatory)][int]$RecommendedInitialMB
    )
    if ($Usage.Count -eq 0) {
        return [PSCustomObject]@{
            Verdict = 'NO_PAGEFILE'
            Detail = 'No pagefile configured — unsafe for modern games with large commit-charge.'
            Remediation = 'Either enable system-managed pagefile (recommended) or set custom sizes per the recommendations below.'
        }
    }
    if ($AutoManaged) {
        return [PSCustomObject]@{
            Verdict = 'OK'
            Detail = 'System-managed pagefile (Windows auto-sizes). Safe default for most users.'
            Remediation = ''
        }
    }
    # Custom sizing. If max < recommended initial, flag TOO_SMALL.
    foreach ($s in $Setting) {
        if ($s.MaximumSize -gt 0 -and $s.MaximumSize -lt $RecommendedInitialMB) {
            return [PSCustomObject]@{
                Verdict = 'TOO_SMALL'
                Detail = "$($s.Name): max $($s.MaximumSize) MB < recommended initial $RecommendedInitialMB MB."
                Remediation = "Either raise the max to >= $($RecommendedInitialMB * 1.5) MB or switch to system-managed."
            }
        }
    }
    return [PSCustomObject]@{
        Verdict = 'OK'
        Detail = 'Custom-sized pagefile is within the recommended range.'
        Remediation = ''
    }
}

$verdict = Get-PagefileVerdict -Usage $usage -Setting $setting `
    -AutoManaged ([bool]$autoManaged) -RecommendedInitialMB $recommendedInitialMB

$records = [PSCustomObject]@{
    TotalRamGB = $totalRamGB
    AutoManaged = [bool]$autoManaged
    Pagefiles = @($usage | ForEach-Object {
            $s = $setting | Where-Object { $_.Name -eq $_.Name } | Select-Object -First 1
            [PSCustomObject]@{
                Path = $_.Name
                CurrentUsageMB = $_.CurrentUsage
                PeakUsageMB = $_.PeakUsage
                AllocatedBaseSizeMB = $_.AllocatedBaseSize
                InitialSizeMB = if ($s) { $s.InitialSize } else { 0 }
                MaximumSizeMB = if ($s) { $s.MaximumSize } else { 0 }
            }
        })
    RecommendedInitialMB = $recommendedInitialMB
    RecommendedMaxMB = $recommendedMaxMB
    Verdict = $verdict.Verdict
    Detail = $verdict.Detail
    Remediation = $verdict.Remediation
}

if ($AsObject) {
    return $records
}

UI-Header -Title 'Pagefile Audit' -Subtitle 'Read-only — current config + sizing recommendation'
UI-KeyValue -Label 'Installed RAM' -Value "$totalRamGB GB"
UI-KeyValue -Label 'Recommended' -Value ("Initial {0} MB / Max {1} MB" -f $recommendedInitialMB, $recommendedMaxMB)
UI-KeyValue -Label 'Auto-managed' -Value ([string]$autoManaged)
Write-Host ''

if ($records.Pagefiles.Count -eq 0) {
    Write-Host '  No pagefile configured.' -ForegroundColor Red
} else {
    Write-Host '  Configured pagefiles:' -ForegroundColor Cyan
    foreach ($pf in $records.Pagefiles) {
        Write-Host "    - $($pf.Path)" -ForegroundColor White
        Write-Host "        Initial: $($pf.InitialSizeMB) MB | Max: $($pf.MaximumSizeMB) MB" -ForegroundColor Gray
        Write-Host "        Allocated now: $($pf.AllocatedBaseSizeMB) MB | Current usage: $($pf.CurrentUsageMB) MB | Peak: $($pf.PeakUsageMB) MB" -ForegroundColor Gray
    }
}

Write-Host ''
$verdictColor = switch ($records.Verdict) {
    'OK' { $script:UI_Success }
    'TOO_SMALL' { $script:UI_Warning }
    'NO_PAGEFILE' { $script:UI_Error }
    default { $script:UI_Info }
}
Write-Host "  Verdict: $($records.Verdict) — $($records.Detail)" -ForegroundColor $verdictColor
if ($records.Remediation) {
    Write-Host "  → $($records.Remediation)" -ForegroundColor DarkGray
}
Write-Host ''
