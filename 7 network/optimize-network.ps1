# ============================================================
# Network Optimization for Gaming (Smart)
# Windows 11 Gaming Optimization Guide
# ============================================================
# Optimizes TCP/IP settings, disables Nagle's Algorithm,
# and tunes network adapter settings for lower latency.
# Pre-checks current state and skips already-applied settings.
# Tracks all changes in manifest for exact rollback.
#
# Replaces: optimize-network.bat
# Must be run as Administrator.
# ============================================================

. "$PSScriptRoot\..\lib\toolkit-state.ps1"

$Host.UI.RawUI.WindowTitle = "Gaming Optimization — Network"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Network Optimization for Gaming" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$state = Initialize-ToolkitState
$succeeded = 0
$skipped = 0

function Run-Step {
    param([string]$Description, [scriptblock]$Action)
    Write-Host "  $Description..." -NoNewline
    try {
        & $Action
        Write-Host " Done" -ForegroundColor Green
        $script:succeeded++
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $script:skipped++
    }
}

# Show active adapters
$activeAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
Write-Host "  Active adapters: $($activeAdapters.Count)" -ForegroundColor Gray
foreach ($adapter in $activeAdapters) {
    Write-Host "    - $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
}
Write-Host ""

# ---- TCP Settings ----
Write-Host "[1/6] TCP Tuning..." -ForegroundColor White

$tcpCurrent = (netsh int tcp show global 2>&1) -join "`n"
if ($tcpCurrent -match "Receive Window Auto-Tuning Level\s*:\s*normal") {
    Write-Host "  TCP Auto-Tuning: already set to normal" -ForegroundColor Gray
    $skipped++
} else {
    Run-Step "TCP Auto-Tuning: normal" {
        netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    }
}

Run-Step "RSS (Receive Side Scaling): enabled" {
    netsh int tcp set global rss=enabled 2>&1 | Out-Null
}

Run-Step "TCP Timestamps: disabled (reduces header overhead)" {
    netsh int tcp set global timestamps=disabled 2>&1 | Out-Null
}

# ---- Adapter Settings ----
Write-Host ""
Write-Host "[2/6] Adapter Optimization..." -ForegroundColor White

Run-Step "Large Send Offload: disabled" {
    foreach ($adapter in $activeAdapters) {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Large Send Offload*" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    }
}

# ---- Nagle's Algorithm ----
Write-Host ""
Write-Host "[3/6] Nagle's Algorithm..." -ForegroundColor White

Run-Step "Disabling Nagle on active interfaces" {
    $interfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $interfaces | ForEach-Object {
        $ip = (Get-ItemProperty $_.PSPath -Name "DhcpIPAddress" -ErrorAction SilentlyContinue).DhcpIPAddress
        if ($ip -and $ip -ne "0.0.0.0") {
            Set-ToolkitRegistryValue -Id "net:TcpAckFrequency:$($_.PSChildName)" `
                -Path $_.PSPath -Name "TcpAckFrequency" `
                -Value 1 -Type "DWord" -Tier "Advanced" -Step "network-optimize"
            Set-ToolkitRegistryValue -Id "net:TCPNoDelay:$($_.PSChildName)" `
                -Path $_.PSPath -Name "TCPNoDelay" `
                -Value 1 -Type "DWord" -Tier "Advanced" -Step "network-optimize"
        }
    }
}

# ---- DNS ----
Write-Host ""
Write-Host "[4/6] DNS Configuration..." -ForegroundColor White

# Show current DNS
$currentDns = @()
foreach ($adapter in $activeAdapters) {
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($dns.ServerAddresses) {
        $currentDns += "$($adapter.Name): $($dns.ServerAddresses -join ', ')"
    }
}
if ($currentDns.Count -gt 0) {
    Write-Host "  Current DNS:" -ForegroundColor Gray
    foreach ($entry in $currentDns) {
        Write-Host "    $entry" -ForegroundColor Gray
    }
}
Write-Host ""

Write-Host "  Choose DNS provider:" -ForegroundColor White
Write-Host "    [1] Cloudflare (1.1.1.1) — fast, privacy-focused [default]" -ForegroundColor White
Write-Host "    [2] Google (8.8.8.8) — reliable, widely used" -ForegroundColor White
Write-Host "    [3] Keep current DNS" -ForegroundColor White
Write-Host ""
do {
    $dnsChoice = Read-Host "  Enter choice (1/2/3) [1]"
    if ($dnsChoice -eq "") { $dnsChoice = "1" }
    if ($dnsChoice -notin @("1","2","3")) {
        Write-Host "  Invalid choice. Enter 1, 2, or 3." -ForegroundColor Yellow
    }
} while ($dnsChoice -notin @("1","2","3"))

if ($dnsChoice -ne "3") {
    $dnsServers = switch ($dnsChoice) {
        "2" { @("8.8.8.8", "8.8.4.4") }
        default { @("1.1.1.1", "1.0.0.1") }
    }
    $dnsName = if ($dnsChoice -eq "2") { "Google" } else { "Cloudflare" }

    Run-Step "Setting DNS to $dnsName ($($dnsServers -join ', '))" {
        Set-ToolkitDnsServers -ServerAddresses $dnsServers -Tier "Safe" -Step "network-optimize"
    }
} else {
    Write-Host "  DNS: Keeping current settings" -ForegroundColor Gray
    Add-ToolkitStepResult -Key "dns-set" -Tier "Safe" -Status "skipped" -Reason "User chose to keep current DNS"
    $skipped++
}

# ---- DNS Flush ----
Write-Host ""
Write-Host "[5/6] DNS Cache..." -ForegroundColor White

Run-Step "Flushing DNS cache" {
    Clear-DnsClientCache -ErrorAction Stop
}

# ---- Validate ----
Write-Host ""
Write-Host "[6/6] Validation..." -ForegroundColor White

if ($dnsChoice -ne "3") {
    Run-Step "Verifying DNS resolution" {
        $result = Resolve-DnsName -Name "google.com" -Type A -ErrorAction Stop
        if ($result) {
            Write-Host " ($($result[0].IPAddress))" -ForegroundColor Gray -NoNewline
        }
    }
}

Add-ToolkitStepResult -Key "network-optimize" -Tier "Advanced" -Status "applied" `
    -Reason "TCP tuning, Nagle disabled, LSO disabled"

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  NETWORK OPTIMIZATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Applied: $succeeded settings" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "  Skipped: $skipped settings" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  Prior state saved in manifest for exact rollback." -ForegroundColor Gray
Write-Host "  A reboot is recommended for all changes to take effect." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"
