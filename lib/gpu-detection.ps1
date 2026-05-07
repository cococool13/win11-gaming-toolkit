# ============================================================
# GPU Vendor Detection & Adapter Registry Path Resolution
# Windows 11 Gaming Optimization Guide
# ============================================================

$script:GpuClassGuid = "{4d36e968-e325-11ce-bfc1-08002be10318}"
$script:GpuClassRoot = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$script:GpuClassGuid"

function Get-GpuVendor {
    <#
    .SYNOPSIS
        Detects installed GPU vendor(s) by scanning PnP Display devices.
    .DESCRIPTION
        Returns one PSCustomObject per discrete GPU found. Skips Microsoft
        Basic Display Adapter and Hyper-V video adapters. Matches vendor by
        PCI Vendor ID: 10DE = NVIDIA, 1002 = AMD, 8086 = Intel.
    #>

    $devices = @(Get-PnpDevice -Class Display -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FriendlyName -notmatch "Microsoft Basic|Hyper-V" -and
            $_.Status -eq "OK" -and
            $_.InstanceId -match "VEN_(10DE|1002|8086)"
        })

    $results = @()
    foreach ($device in $devices) {
        $instanceId = $device.InstanceId
        $vendor = "Unknown"
        $deviceId = ""

        if ($instanceId -match "VEN_10DE") {
            $vendor = "nvidia"
        } elseif ($instanceId -match "VEN_1002") {
            $vendor = "amd"
        } elseif ($instanceId -match "VEN_8086") {
            $vendor = "intel"
        } else {
            continue
        }

        if ($instanceId -match "DEV_([0-9A-Fa-f]{4})") {
            $deviceId = $Matches[1].ToUpperInvariant()
        }

        $adapterPath = Get-GpuAdapterRegistryPath -FriendlyName $device.FriendlyName
        $isDiscrete = $vendor -ne "intel" -or (Test-IntelArcDevice -DeviceId $deviceId)

        $results += [PSCustomObject]@{
            Vendor              = $vendor
            FriendlyName        = $device.FriendlyName
            DeviceId            = $deviceId
            InstanceId          = $instanceId
            AdapterRegistryPath = $adapterPath
            IsDiscrete          = $isDiscrete
            Status              = $device.Status
        }
    }

    return $results
}

function Get-GpuAdapterRegistryPath {
    <#
    .SYNOPSIS
        Resolves the dynamic registry path for a GPU adapter under the
        Display class GUID. Matches by DriverDesc, not by subkey index.
    #>
    param([Parameter(Mandatory)][string]$FriendlyName)

    $subkeys = Get-ChildItem $script:GpuClassRoot -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -match "^\d{4}$" }

    foreach ($subkey in $subkeys) {
        $desc = (Get-ItemProperty $subkey.PSPath -ErrorAction SilentlyContinue).DriverDesc
        if ($desc -and $desc -eq $FriendlyName) {
            return $subkey.PSPath
        }
    }

    # Fallback: partial match
    foreach ($subkey in $subkeys) {
        $desc = (Get-ItemProperty $subkey.PSPath -ErrorAction SilentlyContinue).DriverDesc
        if ($desc -and $FriendlyName -match [regex]::Escape($desc)) {
            return $subkey.PSPath
        }
    }

    return $null
}

function Test-IntelArcDevice {
    <#
    .SYNOPSIS
        Returns $true if the given Intel device ID belongs to a discrete
        Arc GPU (Alchemist or Battlemage), as opposed to integrated graphics.
    #>
    param([string]$DeviceId)

    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        return $false
    }

    # Alchemist (Arc A-series): 56A0-56AF, 5690-569F
    # Battlemage (Arc B-series): E20x range
    return $DeviceId -match "^(56[9A][0-9A-F]|E2[0-9A-F]{2})$"
}

function Get-PrimaryGpu {
    <#
    .SYNOPSIS
        Returns the primary discrete GPU. Prefers NVIDIA/AMD over Intel
        integrated. Returns the first discrete GPU found.
    #>

    $gpus = @(Get-GpuVendor)
    if ($gpus.Count -eq 0) {
        return $null
    }

    # Prefer discrete GPUs
    $discrete = @($gpus | Where-Object { $_.IsDiscrete })
    if ($discrete.Count -gt 0) {
        # Prefer NVIDIA/AMD over Intel Arc
        $nvAmd = @($discrete | Where-Object { $_.Vendor -in @("nvidia", "amd") })
        if ($nvAmd.Count -gt 0) {
            return $nvAmd[0]
        }
        return $discrete[0]
    }

    # Only integrated GPUs found
    return $gpus[0]
}

function Test-ReBarEnabled {
    <#
    .SYNOPSIS
        Best-effort check for Resizable BAR (ReBAR) support.
        Returns $true, $false, or $null if detection is inconclusive.
    #>
    param([string]$AdapterRegistryPath)

    if ([string]::IsNullOrWhiteSpace($AdapterRegistryPath)) {
        return $null
    }

    # Check for LargeMemoryRange property (Intel/NVIDIA)
    $props = Get-ItemProperty -Path $AdapterRegistryPath -ErrorAction SilentlyContinue
    if ($null -ne $props.PSObject.Properties["KMD_EnableLargeBar"]) {
        return [bool]$props.KMD_EnableLargeBar
    }
    if ($null -ne $props.PSObject.Properties["LargeMemoryRange"]) {
        return [bool]$props.LargeMemoryRange
    }

    return $null
}
