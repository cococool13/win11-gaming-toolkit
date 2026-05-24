#Requires -Version 5.1
<#
.SYNOPSIS
    Disable per-adapter Interrupt Moderation for lower network latency jitter.

.DESCRIPTION
    NIC interrupt moderation batches inbound packets into fewer
    interrupts so the CPU stays out of interrupt context — saves
    power and CPU on bulk traffic, but adds 0.5-3ms of jitter to
    latency-sensitive single-packet flows (game traffic, voice).

    Disabling InterruptModeration trades a small CPU uptick for
    measurably tighter latency on competitive game traffic. The
    benefit is most visible on Intel-branded NICs (most common in
    consumer gaming boards) and Realtek 2.5GbE — both ship moderation
    enabled by default.

    Sidecar-JSON revert pattern (matches enable-rss-tuning.ps1 and
    disable-write-cache-flush.ps1): per-adapter pre-toolkit values
    captured to rss-im-before.json beside the manifest.

    Sources cited:
      Microsoft Learn — Set-NetAdapterAdvancedProperty
        https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapteradvancedproperty
      Microsoft Learn — Network adapter tuning for low latency
        https://learn.microsoft.com/en-us/windows-server/networking/technologies/network-subsystem/net-sub-performance-top
      Intel — Performance Tuning for Intel Ethernet Adapters
        https://www.intel.com/content/www/us/en/support/articles/000005811/

    Anti-cheat impact: NONE. Below the IP stack; no game-process
    privilege change.

.PARAMETER WhatIf
    Standard ShouldProcess.

.EXAMPLE
    PS> .\disable-interrupt-moderation.ps1

.EXAMPLE
    PS> .\disable-interrupt-moderation.ps1 -WhatIf

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced
    Pair:     enable-interrupt-moderation.ps1

    # CROSS-PLATFORM-NOTE
    # NetAdapter module is Windows-only. tests/manual/disable-interrupt-moderation.md
    # is the runtime checklist.

    Some NICs name the property differently:
      *InterruptModeration      (most Intel + Realtek)
      InterruptModerationRate   (some Marvell / Aquantia)
      Interrupt Moderation      (legacy display name)
    This script targets all three patterns; if your NIC uses a fourth
    name, add it to $modProperties below.

    Exit codes:
      0  All eligible adapters disabled (or already disabled)
      2  NetAdapter cmdlets unavailable
      3  Sidecar JSON write failed
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title 'Disable NIC Interrupt Moderation' -Subtitle 'Trade CPU for tighter latency jitter'
UI-RequireAdmin -ScriptName 'Disable Interrupt Moderation'
Initialize-ToolkitState | Out-Null

if (-not (Get-Command Get-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Get-NetAdapterAdvancedProperty not available.' -ForegroundColor Yellow
    Write-ToolkitLog 'im-skip-noapi' -Level warn
    exit 2
}

# Known property names. Order matters — the first match per adapter wins.
$modProperties = @('*InterruptModeration', 'InterruptModerationRate', 'Interrupt Moderation')

$sidecarDir = Split-Path -Parent (Get-ToolkitManifestPath)
if (-not (Test-Path -LiteralPath $sidecarDir)) {
    New-Item -ItemType Directory -Path $sidecarDir -Force -ErrorAction SilentlyContinue | Out-Null
}
$sidecarPath = Join-Path $sidecarDir 'rss-im-before.json'

$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -eq 'Up' -and $_.InterfaceType -in 6, 71 })
if ($adapters.Count -eq 0) {
    Write-Host '  [SKIP] No active wired/wireless adapters.' -ForegroundColor Yellow
    exit 0
}

# Build the snapshot: per adapter, the first IM-style property that
# exists. Properties not in $modProperties are ignored.
$rows = foreach ($a in $adapters) {
    $matched = $null
    foreach ($p in $modProperties) {
        $val = Get-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $p -ErrorAction SilentlyContinue
        if ($val) { $matched = $val; break }
    }
    if (-not $matched) {
        Write-Host "  [SKIP] $($a.Name): no Interrupt Moderation property" -ForegroundColor Gray
        continue
    }
    [PSCustomObject]@{
        Name = $a.Name
        Property = $matched.RegistryKeyword
        DisplayValue = $matched.DisplayValue
        RegistryValue = $matched.RegistryValue
    }
}

# Capture baseline on first run only (preserve existing sidecar).
if (-not (Test-Path -LiteralPath $sidecarPath)) {
    try {
        $rows | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $sidecarPath -Encoding utf8
        Write-Host "  Captured baseline at $sidecarPath" -ForegroundColor Gray
        Write-ToolkitLog 'im-baseline-captured' -Data @{ path = $sidecarPath; adapters = $rows.Count }
    } catch {
        Write-Host "  [FAIL] sidecar write: $($_.Exception.Message)" -ForegroundColor Red
        Write-ToolkitLog 'im-baseline-failed' -Level error -Data @{ err = $_.Exception.Message }
        exit 3
    }
}

UI-Section -Title 'Applying'
$applied = 0
foreach ($r in $rows) {
    # "Disabled" is the universal display value across vendors;
    # the registry-value side varies (0 / 'Disabled').
    if ($r.DisplayValue -eq 'Disabled') {
        Write-Host "  [SKIP] $($r.Name)/$($r.Property): already Disabled" -ForegroundColor Gray
        continue
    }
    $desc = "$($r.Name)/$($r.Property): $($r.DisplayValue) → Disabled"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Set-NetAdapterAdvancedProperty')) {
        Write-ToolkitLog 'im-skip-whatif' -Level warn -Data @{ adapter = $r.Name; property = $r.Property }
        continue
    }
    try {
        Set-NetAdapterAdvancedProperty -Name $r.Name `
            -RegistryKeyword $r.Property `
            -DisplayValue 'Disabled' `
            -ErrorAction Stop
        Write-Host "  [OK] $desc" -ForegroundColor Green
        Write-ToolkitLog 'im-disabled' -Data @{
            adapter = $r.Name; property = $r.Property; was = $r.DisplayValue
        }
        $applied++
    } catch {
        Write-Host "  [FAIL] $($r.Name): $($_.Exception.Message)" -ForegroundColor Red
        Write-ToolkitLog 'im-failed' -Level error -Data @{
            adapter = $r.Name; err = $_.Exception.Message
        }
    }
}

Add-ToolkitStepResult -Key 'interrupt-moderation' -Tier 'Advanced' -Status 'applied' `
    -Reason "Disabled IM on $applied adapter(s)"

Write-Host ''
UI-Note -Message 'Revert: enable-interrupt-moderation.ps1 or REVERT-EVERYTHING.ps1.' -Color $script:UI_Info
exit 0
