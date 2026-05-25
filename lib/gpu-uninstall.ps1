#Requires -Version 5.1
<#
.SYNOPSIS
    Vendor-agnostic GPU driver uninstall via pnputil.

.DESCRIPTION
    Counterpart to lib/gpu-download.ps1's Get-GpuDriverInstaller.
    Enumerates the local driver store, filters by publisher pattern
    matching the vendor (NVIDIA / Advanced Micro Devices / Intel
    Corporation), then deletes each matching driver package via
    `pnputil /delete-driver oemNN.inf /uninstall /force`.

    The /uninstall flag removes the device too, not just the package.
    The /force flag bypasses the "driver in use" check (we WANT to
    remove the live driver — the system falls back to Microsoft Basic
    Display Adapter until a fresh install).

    For a TRULY clean state (registry leftovers, install services),
    the caller should recommend DDU as a follow-up. The toolkit ships
    DduManual.ps1 for exactly this.

.NOTES
    # CROSS-PLATFORM-NOTE
    # Windows-only (pnputil is Windows). Dev macOS hits the
    # Get-Command guard and returns early.

    Tier: Advanced (driver removal — system falls back to MBDA
    until next install; cosmetic + perf degradation until then).
#>

function Get-GpuDriverPublisherPattern {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('nvidia', 'amd', 'intel')]
        [string]$Vendor
    )
    # Patterns are regex against the `Driver package provider:` line
    # in `pnputil /enum-drivers` output. Inclusive — matches the few
    # publisher-name variants each vendor has shipped over the years.
    switch ($Vendor) {
        'nvidia' { return 'NVIDIA' }
        'amd' { return 'Advanced Micro Devices|^AMD\b' }
        'intel' { return 'Intel Corporation|^Intel\b' }
    }
}

function Get-InstalledGpuDriverPackages {
    <#
    .SYNOPSIS
        Parse `pnputil /enum-drivers` for entries whose publisher matches
        the vendor regex. Returns [PSCustomObject]@{ InfName, ClassName,
        Provider, OriginalName, Version }.
    .DESCRIPTION
        Pure-read helper. Safe to call under -WhatIf since it does not
        modify anything. Returns @() on non-Windows or when pnputil is
        unavailable.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('nvidia', 'amd', 'intel')]
        [string]$Vendor
    )

    if (-not (Get-Command pnputil -ErrorAction SilentlyContinue)) {
        Write-Verbose 'pnputil unavailable (non-Windows or stripped image); returning empty set.'
        return @()
    }

    $pattern = Get-GpuDriverPublisherPattern -Vendor $Vendor
    $output = & pnputil.exe /enum-drivers 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "pnputil /enum-drivers returned exit code $LASTEXITCODE"
        return @()
    }

    # pnputil emits a header line then per-driver blocks separated by
    # blank lines. Each block has key-value lines like:
    #   Published Name:     oem42.inf
    #   Original Name:      nv_dispi.inf
    #   Provider Name:      NVIDIA
    #   Class Name:         Display adapters
    #   Driver Version:     12/15/2025 32.0.15.1234
    # We parse line-by-line into records, then filter by Provider regex.
    $records = @()
    $current = $null
    foreach ($line in $output) {
        if ($line -match '^\s*$') {
            if ($null -ne $current -and $current.Provider) { $records += $current }
            $current = $null
            continue
        }
        if ($line -match '^Published Name\s*:\s*(.+)$') {
            $current = [PSCustomObject]@{
                InfName = $matches[1].Trim()
                OriginalName = ''
                Provider = ''
                ClassName = ''
                Version = ''
            }
        } elseif ($null -ne $current) {
            if ($line -match '^Original Name\s*:\s*(.+)$') { $current.OriginalName = $matches[1].Trim() }
            elseif ($line -match '^Provider Name\s*:\s*(.+)$') { $current.Provider = $matches[1].Trim() }
            elseif ($line -match '^Class Name\s*:\s*(.+)$') { $current.ClassName = $matches[1].Trim() }
            elseif ($line -match '^Driver Version\s*:\s*(.+)$') { $current.Version = $matches[1].Trim() }
        }
    }
    # Last record may not have a trailing blank line
    if ($null -ne $current -and $current.Provider) { $records += $current }

    return @($records | Where-Object { $_.Provider -match $pattern })
}

function Uninstall-GpuDriverByPublisher {
    <#
    .SYNOPSIS
        Remove every installed driver package whose publisher matches
        the vendor regex. Returns @{ Removed = <count>; Packages =
        <list of InfNames>; Failed = <list of @{Inf=...;Reason=...}> }.
    .DESCRIPTION
        Wrapper around `pnputil /delete-driver oemNN.inf /uninstall
        /force`. Gates each delete via $PSCmdlet.ShouldProcess so
        -WhatIf prints the deletion plan without modifying the system.

        Failures are accumulated (not thrown) so partial uninstalls
        complete what they can. Caller decides what to do with the
        Failed list.

    .EXAMPLE
        $result = Uninstall-GpuDriverByPublisher -Vendor 'nvidia' -WhatIf
        $result.Removed   # 0 under -WhatIf
        $result.Packages  # what WOULD be removed
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('nvidia', 'amd', 'intel')]
        [string]$Vendor
    )

    # NOTE: do NOT use $matches — it's a PowerShell automatic variable
    # populated by the -match operator. Shadowing it would clobber any
    # later regex result inside this function.
    $pkgMatches = Get-InstalledGpuDriverPackages -Vendor $Vendor
    $result = @{
        Removed = 0
        Packages = @()
        Failed = @()
    }

    if (-not $pkgMatches -or $pkgMatches.Count -eq 0) {
        Write-Verbose "No installed $Vendor driver packages found via pnputil."
        return $result
    }

    foreach ($pkg in $pkgMatches) {
        $target = "$($pkg.InfName) ($($pkg.OriginalName), v$($pkg.Version), publisher $($pkg.Provider))"
        if (-not $PSCmdlet.ShouldProcess($target, "pnputil /delete-driver /uninstall /force")) {
            # Under -WhatIf, count the package in Packages so the caller
            # can show the deletion preview. Don't increment Removed —
            # nothing was actually removed.
            $result.Packages += $pkg.InfName
            continue
        }

        $output = & pnputil.exe /delete-driver $pkg.InfName /uninstall /force 2>&1
        if ($LASTEXITCODE -eq 0) {
            $result.Removed++
            $result.Packages += $pkg.InfName
        } else {
            $result.Failed += @{ Inf = $pkg.InfName; Reason = "exit $LASTEXITCODE — $($output -join ' ')" }
        }
    }

    return $result
}
