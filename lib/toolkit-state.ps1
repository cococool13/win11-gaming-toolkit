# ============================================================
# Shared State / Preflight Helpers
# Windows 11 Gaming Optimization Guide
# ============================================================

$script:ToolkitVersion = "2.0.0"
$script:ToolkitStateRoot = Join-Path $env:ProgramData "Win11GamingToolkit\state"
$script:ToolkitStateFile = Join-Path $script:ToolkitStateRoot "manifest.json"
$script:ToolkitState = $null

function Get-ToolkitManifestPath {
    return $script:ToolkitStateFile
}

function Test-ToolkitMapHasKey {
    param($Map, [string]$Key)
    if ($Map -is [hashtable]) {
        return $Map.ContainsKey($Key)
    }
    return $null -ne $Map.PSObject.Properties[$Key]
}

function Get-ToolkitMapValue {
    param($Map, [string]$Key)
    if ($Map -is [hashtable]) {
        return $Map[$Key]
    }
    return $Map.PSObject.Properties[$Key].Value
}

function Set-ToolkitMapValue {
    param($Map, [string]$Key, $Value)
    if ($Map -is [hashtable]) {
        $Map[$Key] = $Value
        return
    }
    if ($Map.PSObject.Properties[$Key]) {
        $Map.$Key = $Value
    } else {
        $Map | Add-Member -NotePropertyName $Key -NotePropertyValue $Value
    }
}

function Test-ToolkitCommand {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-ToolkitMachineProfile {
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $enclosure = Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    $gpuDevices = @(Get-PnpDevice -Class Display -ErrorAction SilentlyContinue)
    $activeAdapters = @()
    if (Test-ToolkitCommand "Get-NetAdapter") {
        $activeAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
    }

    $printerCount = 0
    if (Test-ToolkitCommand "Get-Printer") {
        $printerCount = @(Get-Printer -ErrorAction SilentlyContinue).Count
    }

    $chassisTypes = @()
    if ($enclosure) {
        $chassisTypes = @($enclosure.ChassisTypes)
    }
    $laptopChassisTypes = @(8, 9, 10, 14, 30, 31, 32)
    $handheldChassisTypes = @(11, 30, 31, 32)
    $isLaptop = $false
    $isHandheld = $false
    foreach ($chassisType in $chassisTypes) {
        if ($laptopChassisTypes -contains $chassisType) {
            $isLaptop = $true
        }
        if ($handheldChassisTypes -contains $chassisType) {
            $isHandheld = $true
        }
    }

    $powerState = "Desktop / AC"
    if ($battery) {
        $powerState = "Battery-capable"
        if ($battery.BatteryStatus -in @(1, 4, 5, 11)) {
            $powerState = "On battery"
        } elseif ($battery.BatteryStatus -in @(2, 6, 7, 8, 9)) {
            $powerState = "Charging / AC"
        }
    }

    $dnsSnapshot = @()
    if (Test-ToolkitCommand "Get-DnsClientServerAddress") {
        $dnsSnapshot = @(Get-DnsClientServerAddress -ErrorAction SilentlyContinue | ForEach-Object {
            [PSCustomObject]@{
                InterfaceAlias = $_.InterfaceAlias
                InterfaceIndex = $_.InterfaceIndex
                AddressFamily = $_.AddressFamily
                ServerAddresses = @($_.ServerAddresses)
            }
        })
    }

    return [PSCustomObject]@{
        generatedAt = (Get-Date).ToString("o")
        systemName = $env:COMPUTERNAME
        manufacturer = $computerSystem.Manufacturer
        model = $computerSystem.Model
        isLaptop = $isLaptop
        isHandheld = $isHandheld
        powerState = $powerState
        gpuCount = $gpuDevices.Count
        isHybridGraphics = $gpuDevices.Count -gt 1
        activeAdapterCount = $activeAdapters.Count
        activeAdapters = @($activeAdapters | ForEach-Object { $_.Name })
        printerCount = $printerCount
        defenderAvailable = Test-ToolkitCommand "Get-MpPreference"
        partOfDomain = [bool]$computerSystem.PartOfDomain
        windowsVersion = $operatingSystem.Version
        windowsCaption = $operatingSystem.Caption
        dnsSnapshot = $dnsSnapshot
    }
}

function Save-ToolkitState {
    if (-not (Test-Path $script:ToolkitStateRoot)) {
        New-Item -ItemType Directory -Path $script:ToolkitStateRoot -Force | Out-Null
    }
    $script:ToolkitState.lastUpdated = (Get-Date).ToString("o")
    $json = $script:ToolkitState | ConvertTo-Json -Depth 12
    Set-Content -Path $script:ToolkitStateFile -Value $json -Force
}

function Get-ToolkitState {
    if ($script:ToolkitState) {
        return $script:ToolkitState
    }
    if (Test-Path $script:ToolkitStateFile) {
        $script:ToolkitState = Get-Content $script:ToolkitStateFile -Raw | ConvertFrom-Json -Depth 12
        return $script:ToolkitState
    }
    return $null
}

function Initialize-ToolkitState {
    param([switch]$ForceNew)

    # Preserve captured before-state once a manifest exists. Older callers used
    # -ForceNew during apply, which could destroy the only reliable revert data.
    if (Test-Path $script:ToolkitStateFile) {
        $script:ToolkitState = Get-Content $script:ToolkitStateFile -Raw | ConvertFrom-Json -Depth 12
        return $script:ToolkitState
    }

    $profile = Get-ToolkitMachineProfile
    $script:ToolkitState = [ordered]@{
        version = $script:ToolkitVersion
        createdAt = (Get-Date).ToString("o")
        lastUpdated = (Get-Date).ToString("o")
        context = $profile
        notes = @()
        registry = @{}
        services = @{}
        dns = [ordered]@{
            captured = $false
            interfaces = @{}
        }
        defender = [ordered]@{
            captured = $false
            before = @()
            added = @()
        }
        packages = [ordered]@{
            removed = @()
            provisionedRemoved = @()
        }
        steps = @{}
    }
    Save-ToolkitState
    return $script:ToolkitState
}

function Add-ToolkitNote {
    param([string]$Message)
    $state = Get-ToolkitState
    $state.notes += $Message
    Save-ToolkitState
}

function Add-ToolkitStepResult {
    param(
        [string]$Key,
        [string]$Tier,
        [string]$Status,
        [string]$Reason = ""
    )
    $state = Get-ToolkitState
    Set-ToolkitMapValue -Map $state.steps -Key $Key -Value ([ordered]@{
        tier = $Tier
        status = $Status
        reason = $Reason
        updatedAt = (Get-Date).ToString("o")
    })
    Save-ToolkitState
}

function Get-ToolkitRegistryState {
    param(
        [string]$Path,
        [string]$Name
    )

    $valueName = if ($null -eq $Name) { "" } else { $Name }
    $pathExists = Test-Path $Path
    if (-not $pathExists) {
        return [ordered]@{
            pathExists = $false
            valueExists = $false
            kind = $null
            value = $null
        }
    }

    $item = Get-Item -Path $Path -ErrorAction Stop
    $valueNames = @($item.GetValueNames())
    $defaultExists = $item.GetValue("", $null) -ne $null
    $valueExists = if ($valueName -eq "") { $defaultExists } else { $valueNames -contains $valueName }
    if (-not $valueExists) {
        return [ordered]@{
            pathExists = $true
            valueExists = $false
            kind = $null
            value = $null
        }
    }

    return [ordered]@{
        pathExists = $true
        valueExists = $true
        kind = $item.GetValueKind($valueName).ToString()
        value = $item.GetValue($valueName, $null, "DoNotExpandEnvironmentNames")
    }
}

function Set-ToolkitRegistryValue {
    param(
        [string]$Id,
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type,
        [string]$Tier,
        [string]$Step
    )

    $state = Get-ToolkitState
    if (-not (Test-ToolkitMapHasKey -Map $state.registry -Key $Id)) {
        Set-ToolkitMapValue -Map $state.registry -Key $Id -Value ([ordered]@{
            path = $Path
            name = $Name
            tier = $Tier
            step = $Step
            before = Get-ToolkitRegistryState -Path $Path -Name $Name
        })
        Save-ToolkitState
    }

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    $propertyType = switch ($Type) {
        "DWord" { "DWord" }
        "QWord" { "QWord" }
        "Binary" { "Binary" }
        "MultiString" { "MultiString" }
        "ExpandString" { "ExpandString" }
        default { "String" }
    }

    if ($Name -eq "") {
        $item = Get-Item -Path $Path -ErrorAction Stop
        $item.SetValue("", $Value)
    } else {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $propertyType -Force | Out-Null
    }
}

function Restore-ToolkitRegistryValue {
    param([string]$Id)

    $state = Get-ToolkitState
    if (-not (Test-ToolkitMapHasKey -Map $state.registry -Key $Id)) {
        return $false
    }
    $entry = Get-ToolkitMapValue -Map $state.registry -Key $Id
    $before = $entry.before
    $path = $entry.path
    $name = $entry.name

    if (-not $before.pathExists) {
        # Parenthesize Test-Path so $path doesn't get bound as -and parameter.
        # Without parens, PowerShell parses Test-Path's args greedily and the
        # Remove-ItemProperty branch is skipped (or throws), leaving the
        # toolkit-added value behind when the parent key didn't exist before.
        if ((Test-Path $path) -and $name -ne "") {
            Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
        }
        return $true
    }

    if (-not $before.valueExists) {
        if ($name -ne "") {
            Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
        }
        return $true
    }

    Set-ToolkitRegistryValue -Id $Id -Path $path -Name $name -Value $before.value -Type $before.kind -Tier $entry.tier -Step $entry.step
    return $true
}

function Set-ToolkitServiceStartMode {
    param(
        [string]$Name,
        [string]$Mode,
        [string]$Tier,
        [string]$Step
    )

    $state = Get-ToolkitState
    if (-not (Test-ToolkitMapHasKey -Map $state.services -Key $Name)) {
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$Name'" -ErrorAction SilentlyContinue
        Set-ToolkitMapValue -Map $state.services -Key $Name -Value ([ordered]@{
            name = $Name
            tier = $Tier
            step = $Step
            installed = $null -ne $service
            before = if ($service) { $service.StartMode } else { $null }
        })
        Save-ToolkitState
    }

    $output = sc.exe config $Name start= $Mode 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sc.exe config failed: $output"
    }
}

function Convert-ToolkitServiceModeToScMode {
    param([string]$Mode)

    switch -Regex ($Mode) {
        "^auto$|^automatic$" { return "auto" }
        "^manual$|^demand$" { return "demand" }
        "^disabled$" { return "disabled" }
        "^delayed auto start$" { return "delayed-auto" }
        default { throw "Unsupported service start mode: $Mode" }
    }
}

function Restore-ToolkitServiceStartMode {
    param([string]$Name)

    $state = Get-ToolkitState
    if (-not (Test-ToolkitMapHasKey -Map $state.services -Key $Name)) {
        return $false
    }
    $entry = Get-ToolkitMapValue -Map $state.services -Key $Name
    if (-not $entry.installed -or -not $entry.before) {
        return $true
    }
    $restoredMode = Convert-ToolkitServiceModeToScMode -Mode ([string]$entry.before)
    $output = sc.exe config $Name start= $restoredMode 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sc.exe config failed: $output"
    }
    return $true
}

function Normalize-ToolkitDnsAddressFamily {
    param($AddressFamily)

    switch -Regex ([string]$AddressFamily) {
        "^IPv4$|^2$|^InterNetwork$" { return "IPv4" }
        "^IPv6$|^23$|^InterNetworkV6$" { return "IPv6" }
        default { return $null }
    }
}

function Get-ToolkitDnsAddressFamily {
    param([string]$Address)

    $parsedAddress = [System.Net.IPAddress]::None
    if (-not [System.Net.IPAddress]::TryParse($Address, [ref]$parsedAddress)) {
        return $null
    }

    return Normalize-ToolkitDnsAddressFamily -AddressFamily $parsedAddress.AddressFamily
}

function Group-ToolkitDnsServersByFamily {
    param([string[]]$ServerAddresses)

    $groups = [ordered]@{
        IPv4 = @()
        IPv6 = @()
    }

    foreach ($server in @($ServerAddresses | Where-Object { $_ })) {
        $family = Get-ToolkitDnsAddressFamily -Address $server
        if (-not $family) {
            throw "Invalid DNS server address: $server"
        }
        $groups[$family] = @($groups[$family]) + @($server)
    }

    if (@($groups["IPv4"]).Count -eq 0 -and @($groups["IPv6"]).Count -eq 0) {
        throw "No DNS server addresses provided"
    }

    return $groups
}

function Capture-ToolkitDnsState {
    $state = Get-ToolkitState
    if ($state.dns.captured -or -not (Test-ToolkitCommand "Get-DnsClientServerAddress")) {
        return
    }

    $snapshot = @(Get-DnsClientServerAddress -ErrorAction SilentlyContinue)
    foreach ($item in $snapshot) {
        $addressFamily = Normalize-ToolkitDnsAddressFamily -AddressFamily $item.AddressFamily
        if (-not $addressFamily) {
            continue
        }
        $snapshotKey = "{0}:{1}" -f $item.InterfaceIndex, $addressFamily
        Set-ToolkitMapValue -Map $state.dns.interfaces -Key $snapshotKey -Value ([ordered]@{
            interfaceAlias = $item.InterfaceAlias
            addressFamily = $addressFamily
            serverAddresses = @($item.ServerAddresses)
        })
    }
    $state.dns.captured = $true
    Save-ToolkitState
}

function Set-ToolkitDnsServers {
    param(
        [string[]]$ServerAddresses,
        [string]$Tier,
        [string]$Step
    )

    foreach ($commandName in @("Get-NetAdapter", "Get-DnsClientServerAddress", "Set-DnsClientServerAddress")) {
        if (-not (Test-ToolkitCommand $commandName)) {
            throw "$commandName cmdlet unavailable"
        }
    }

    $serverGroups = Group-ToolkitDnsServersByFamily -ServerAddresses $ServerAddresses
    Capture-ToolkitDnsState
    $activeAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
    foreach ($adapter in $activeAdapters) {
        try {
            $adapterFailures = @()
            foreach ($family in @("IPv4", "IPv6")) {
                $familyServers = @($serverGroups[$family])
                if ($familyServers.Count -eq 0) {
                    continue
                }

                $target = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $family -ErrorAction Stop
                Set-DnsClientServerAddress -InputObject $target -ServerAddresses $familyServers -ErrorAction Stop

                $current = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $family -ErrorAction Stop
                $currentServers = @($current.ServerAddresses)
                $missingServers = @($familyServers | Where-Object { $currentServers -notcontains $_ })
                if ($missingServers.Count -gt 0) {
                    $adapterFailures += "$family missing $($missingServers -join ', ')"
                }
            }

            if ($adapterFailures.Count -eq 0) {
                Add-ToolkitStepResult -Key "dns:$($adapter.ifIndex)" -Tier $Tier -Status "applied" -Reason $Step
            } else {
                Add-ToolkitStepResult -Key "dns:$($adapter.ifIndex)" -Tier $Tier -Status "skipped" -Reason "DNS verification failed on adapter $($adapter.Name): $($adapterFailures -join '; ')"
            }
        } catch {
            Add-ToolkitStepResult -Key "dns:$($adapter.ifIndex)" -Tier $Tier -Status "skipped" -Reason "DNS apply failed on adapter $($adapter.Name): $($_.Exception.Message)"
        }
    }
}

function Restore-ToolkitDnsServers {
    $state = Get-ToolkitState
    if (-not $state.dns.captured) {
        return $false
    }

    $properties = if ($state.dns.interfaces -is [hashtable]) {
        $state.dns.interfaces.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Name = $_.Key; Value = $_.Value } }
    } else {
        $state.dns.interfaces.PSObject.Properties
    }
    foreach ($property in $properties) {
        $nameParts = ([string]$property.Name) -split ":", 2
        $interfaceIndex = [int]$nameParts[0]
        $entry = $property.Value
        $addressFamily = if ($nameParts.Count -gt 1) {
            Normalize-ToolkitDnsAddressFamily -AddressFamily $nameParts[1]
        } else {
            Normalize-ToolkitDnsAddressFamily -AddressFamily $entry.addressFamily
        }
        $addresses = @($entry.serverAddresses | Where-Object { $_ })

        if ($addressFamily) {
            $target = Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex -AddressFamily $addressFamily -ErrorAction SilentlyContinue
            if ($target) {
                if ($addresses.Count -gt 0) {
                    Set-DnsClientServerAddress -InputObject $target -ServerAddresses $addresses -ErrorAction SilentlyContinue
                } else {
                    Set-DnsClientServerAddress -InputObject $target -ResetServerAddresses -ErrorAction SilentlyContinue
                }
            }
        } elseif ($addresses.Count -gt 0) {
            Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $addresses -ErrorAction SilentlyContinue
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
        }
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    return $true
}

function Capture-ToolkitDefenderState {
    $state = Get-ToolkitState
    if ($state.defender.captured -or -not (Test-ToolkitCommand "Get-MpPreference")) {
        return
    }
    $paths = @((Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath)
    $state.defender.before = @($paths | Where-Object { $_ })
    $state.defender.captured = $true
    Save-ToolkitState
}

function Add-ToolkitDefenderExclusion {
    param(
        [string]$Path,
        [string]$Tier,
        [string]$Step
    )

    if (-not (Test-ToolkitCommand "Add-MpPreference")) {
        throw "Windows Defender cmdlets unavailable"
    }
    Capture-ToolkitDefenderState
    $current = @((Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath)
    if ($current -contains $Path) {
        Add-ToolkitStepResult -Key "defender:$Path" -Tier $Tier -Status "preexisting" -Reason $Step
        return
    }
    Add-MpPreference -ExclusionPath $Path -ErrorAction Stop
    $state = Get-ToolkitState
    if ($state.defender.added -notcontains $Path) {
        $state.defender.added += $Path
        Save-ToolkitState
    }
    Add-ToolkitStepResult -Key "defender:$Path" -Tier $Tier -Status "applied" -Reason $Step
}

function Restore-ToolkitDefenderExclusions {
    $state = Get-ToolkitState
    if (-not (Test-ToolkitCommand "Remove-MpPreference")) {
        return $false
    }
    foreach ($path in @($state.defender.added)) {
        Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
    }
    return $true
}

function Record-ToolkitPackageRemoval {
    param(
        [string]$PackageName,
        [switch]$Provisioned
    )

    $state = Get-ToolkitState
    if ($Provisioned) {
        if ($state.packages.provisionedRemoved -notcontains $PackageName) {
            $state.packages.provisionedRemoved += $PackageName
        }
    } else {
        if ($state.packages.removed -notcontains $PackageName) {
            $state.packages.removed += $PackageName
        }
    }
    Save-ToolkitState
}

function Get-ToolkitRecordedStatus {
    param([string]$Key)
    $state = Get-ToolkitState
    if ($state -and (Test-ToolkitMapHasKey -Map $state.steps -Key $Key)) {
        return (Get-ToolkitMapValue -Map $state.steps -Key $Key).status
    }
    return $null
}
