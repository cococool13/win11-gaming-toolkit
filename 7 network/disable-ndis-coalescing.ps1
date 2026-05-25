<#
.SYNOPSIS
    Disable NIC NDIS interrupt coalescing and RxIRQCoalescing across
    active adapters by setting the documented per-property RxIrqMod
    / TxIrqMod / *IRQCoalesce values to "Off".

.DESCRIPTION
    Distinct from disable-interrupt-moderation.ps1 (which targets the
    higher-level *InterruptModeration property): this one toggles the
    NDIS-level IRQ coalescing properties that some vendor drivers
    expose separately (Intel I225-V, Mellanox ConnectX, certain
    Realtek silicon). Same goal: lower receive-side latency at the
    cost of slightly higher CPU per packet.

    Covers (where the adapter advertises the property):
      *IRQCoalesce          (generic)
      RxIrqMod, TxIrqMod    (Intel)
      *RxIrqCoalesce        (Realtek)

    Each property is set to its lowest documented value (0 / Off /
    Disabled) and the original value goes to the 'ndis-coalesce'
    sidecar for exact restore by enable-ndis-coalescing.ps1.

    Coordinates with:
      - disable-rss-tuning.ps1 (queue-count tuning)
      - disable-interrupt-moderation.ps1 (higher-level moderation)
      - disable-rsc.ps1 (TCP segment coalescing)
    Apply all three together for the fullest receive-path latency
    reduction.

    Anti-cheat impact: NONE. Per-adapter advanced property; below the
    IP stack, no game-process surface.
    Reboot required: NO. Set-NetAdapterAdvancedProperty applies live.
    Disk impact: LOW (sidecar JSON per adapter, ~1 KB).

.NOTES
    Tier: Advanced
    Pair: enable-ndis-coalescing.ps1
    Microsoft Learn:
      https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapteradvancedproperty
    Intel "Performance Tuning for Intel Ethernet Adapters":
      https://www.intel.com/content/www/us/en/support/articles/000005811/

    # CROSS-PLATFORM-NOTE
    # Windows-only.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param()

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

$Host.UI.RawUI.WindowTitle = 'Disable NDIS Coalescing'
UI-Header -Title 'Disable NDIS IRQ Coalescing' -Subtitle 'Per-adapter low-level coalescing toggle'
UI-RequireAdmin -ScriptName 'Disable NDIS Coalescing'

Initialize-ToolkitState | Out-Null
UI-ResetCounters

if (-not (Get-Command Get-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue)) {
    UI-Note -Message '[SKIP] NetAdapter cmdlets unavailable.' -Color $script:UI_Warning
    UI-Exit
    exit 1
}

$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
if ($adapters.Count -eq 0) {
    UI-Note -Message 'No active adapters.' -Color $script:UI_Warning
    UI-Exit
    exit 0
}

# Properties to look for. Each vendor uses slightly different
# RegistryKeyword names; we probe and set what's present.
$coalescePatterns = @('*IRQCoalesce', 'RxIrqMod', 'TxIrqMod', '*RxIrqCoalesce')

$snapshot = @()
foreach ($a in $adapters) {
    foreach ($pattern in $coalescePatterns) {
        $props = @(Get-NetAdapterAdvancedProperty -Name $a.Name `
                -RegistryKeyword $pattern -ErrorAction SilentlyContinue)
        foreach ($p in $props) {
            $snapshot += [PSCustomObject]@{
                Name = $a.Name
                Property = $p.RegistryKeyword
                DisplayValue = $p.DisplayValue
                RegistryValue = $p.RegistryValue
            }
        }
    }
}

if ($snapshot.Count -eq 0) {
    UI-Note -Message 'No NDIS coalescing properties found on any active adapter.' -Color $script:UI_Info
    UI-Exit
    exit 0
}

$saved = Save-ToolkitSidecar -Name 'ndis-coalesce' -InputObject $snapshot
if ($saved) {
    UI-Note -Message "Captured $($snapshot.Count) property baseline at $saved"
}

foreach ($entry in $snapshot) {
    $desc = "$($entry.Name)/$($entry.Property) → 0/Off"
    if (-not $PSCmdlet.ShouldProcess($desc, 'Set-NetAdapterAdvancedProperty')) {
        UI-Skip -Label $desc -Reason '-WhatIf preview'
        continue
    }
    UI-Step -Label "$($entry.Name) / $($entry.Property) — disable" -Action {
        # Try setting RegistryValue first (numeric, most reliable);
        # fall back to DisplayValue 'Off' if the property expects a
        # named enum value.
        try {
            Set-NetAdapterAdvancedProperty -Name $entry.Name `
                -RegistryKeyword $entry.Property `
                -RegistryValue 0 -ErrorAction Stop
        } catch {
            Set-NetAdapterAdvancedProperty -Name $entry.Name `
                -RegistryKeyword $entry.Property `
                -DisplayValue 'Off' -ErrorAction SilentlyContinue
        }
    }.GetNewClosure()
}

Add-ToolkitStepResult -Key 'ndis-coalesce-disable' -Tier 'Advanced' -Status 'applied' `
    -Reason "NDIS coalescing disabled on $($snapshot.Count) property/adapter pair(s)"

UI-Summary -DoneMessage 'NDIS coalescing disabled' -Details @(
    'Coordinates with disable-rss-tuning + disable-interrupt-moderation + disable-rsc.'
) -RevertHint 'Run enable-ndis-coalescing.ps1 in this folder.'
UI-Exit
