#Requires -Version 5.1
<#
.SYNOPSIS
    Register DNS-over-HTTPS (DoH) server templates with Windows.

.DESCRIPTION
    Win11 21H2+ (with 22H2 polish, 24H2 stable) ships a built-in DoH
    resolver. Registering a public DoH server with the cmdlet
    Set-DnsClientDohServerAddress causes any subsequent
    Set-DnsClientServerAddress for the same IPv4/IPv6 to be encrypted
    by the OS automatically — no per-app config, no third-party
    daemon, no host-file workaround.

    This script:
      1. Registers DoH templates for Cloudflare, Quad9, and Google
         (the three Microsoft documents as well-known compatible
         providers — see NOTES for the Microsoft Learn link).
      2. Optionally sets the active adapter DNS to Cloudflare so DoH
         actually applies. Default: register-only (the user picks).
      3. Logs a before/after measurement of `Resolve-DnsName` latency
         to the toolkit log so the user can see whether DoH helped or
         hurt their typical query path.

    Sources cited inline:
      Microsoft Learn — Set-DnsClientDohServerAddress
        https://learn.microsoft.com/en-us/powershell/module/dnsclient/set-dnsclientdohserveraddress
      Microsoft Learn — Configure DNS over HTTPS in Windows Server
        https://learn.microsoft.com/en-us/windows-server/networking/dns/doh-client-support
      RFC 8484 — DNS Queries over HTTPS (DoH)
        https://datatracker.ietf.org/doc/html/rfc8484

.PARAMETER ApplyToActiveAdapters
    Beyond registering DoH templates, also call Set-DnsClientServerAddress
    on every Up interface to actually use the DoH-protected Cloudflare
    addresses. Default: $false (template registration is non-invasive;
    actually routing through DoH is a separate decision).

.PARAMETER WhatIf
    Standard ShouldProcess. No DoH templates are registered and no DNS
    is changed; the script logs intent only.

.EXAMPLE
    PS> .\enable-doh.ps1
    Registers DoH templates with the OS but does NOT change active DNS.
    Safe to run repeatedly.

.EXAMPLE
    PS> .\enable-doh.ps1 -ApplyToActiveAdapters
    Registers + routes active adapters through Cloudflare DoH.

.EXAMPLE
    PS> .\enable-doh.ps1 -WhatIf
    Show what would change without writing.

.NOTES
    Author:   Win11 Gaming Toolkit
    Version:  1.0
    Tier:     Advanced

    # CROSS-PLATFORM-NOTE
    # Set-DnsClientDohServerAddress is Windows-only (DnsClient module).
    # On non-Windows hosts the cmdlet-presence check fails fast with
    # exit code 2; no fallback. Test on a Windows VM — see
    # tests/manual/enable-doh.md for the runtime checklist.

    Anti-cheat impact: NONE. DoH is transparent to gameplay; the OS
    resolves through DoH but presents stable IPs to applications.

    Exit codes:
      0  DoH templates registered (and adapters configured if requested)
      1  User declined a confirm prompt
      2  DnsClient module / cmdlet unavailable (older Win10, Server Core)
      3  Set-DnsClientDohServerAddress failed at the OS level
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [switch]$ApplyToActiveAdapters
)

. "$PSScriptRoot\..\lib\toolkit-state.ps1"
. "$PSScriptRoot\..\lib\ui-helpers.ps1"

UI-Header -Title 'Enable DNS-over-HTTPS' -Subtitle 'Register Cloudflare / Quad9 / Google DoH templates'
UI-RequireAdmin -ScriptName 'Enable DoH'
Initialize-ToolkitState | Out-Null

# Capability check — Set-DnsClientDohServerAddress shipped in
# Windows 11 21H2 / Server 2022. Skip cleanly on older / stripped images.
if (-not (Get-Command Set-DnsClientDohServerAddress -ErrorAction SilentlyContinue)) {
    Write-Host '  [SKIP] Set-DnsClientDohServerAddress not available.' -ForegroundColor Yellow
    Write-Host '         Requires Windows 11 21H2+. Server Core may also strip DnsClient.' -ForegroundColor Yellow
    Write-ToolkitLog 'doh-skip-noapi' -Level warn
    exit 2
}

# Well-known DoH providers. Reference RFC 8484 + per-provider docs.
# Each entry: (ServerAddress, DohTemplate, Label). Cloudflare first
# because it's the toolkit's existing DNS default in Set-ToolkitDnsServers.
$providers = @(
    @{ Server = '1.1.1.1'; Template = 'https://cloudflare-dns.com/dns-query'; Label = 'Cloudflare v4' }
    @{ Server = '1.0.0.1'; Template = 'https://cloudflare-dns.com/dns-query'; Label = 'Cloudflare v4 secondary' }
    @{ Server = '2606:4700:4700::1111'; Template = 'https://cloudflare-dns.com/dns-query'; Label = 'Cloudflare v6' }
    @{ Server = '2606:4700:4700::1001'; Template = 'https://cloudflare-dns.com/dns-query'; Label = 'Cloudflare v6 secondary' }
    @{ Server = '9.9.9.9'; Template = 'https://dns.quad9.net/dns-query'; Label = 'Quad9 v4' }
    @{ Server = '149.112.112.112'; Template = 'https://dns.quad9.net/dns-query'; Label = 'Quad9 v4 secondary' }
    @{ Server = '2620:fe::fe'; Template = 'https://dns.quad9.net/dns-query'; Label = 'Quad9 v6' }
    @{ Server = '8.8.8.8'; Template = 'https://dns.google/dns-query'; Label = 'Google v4' }
    @{ Server = '2001:4860:4860::8888'; Template = 'https://dns.google/dns-query'; Label = 'Google v6' }
)

# Before-metric: time Resolve-DnsName on a stable target with current
# resolver. Logged so the user has a baseline.
function Measure-Resolution {
    param([string]$Tag)
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        # microsoft.com is a stable resolution target Microsoft itself
        # uses in DNS troubleshooting docs.
        $null = Resolve-DnsName -Name 'microsoft.com' -Type A -ErrorAction Stop
        $sw.Stop()
        Write-ToolkitLog 'doh-measurement' -Data @{ tag = $Tag; ms = [int]$sw.ElapsedMilliseconds }
        Write-Host ("    {0,-10} microsoft.com A: {1} ms" -f $Tag, $sw.ElapsedMilliseconds) -ForegroundColor Gray
        return $sw.ElapsedMilliseconds
    } catch {
        Write-ToolkitLog 'doh-measurement-failed' -Level warn -Data @{ tag = $Tag; err = $_.Exception.Message }
        Write-Host ("    {0,-10} microsoft.com A: FAILED ({1})" -f $Tag, $_.Exception.Message) -ForegroundColor Yellow
        return $null
    }
}

UI-Section -Title 'Pre-change DNS latency baseline'
$msBefore = Measure-Resolution -Tag 'before'

# Register each provider. Set-DnsClientDohServerAddress is idempotent at
# the cmdlet level — re-registering an existing IP+template pair is a no-op.
UI-Section -Title 'Registering DoH templates'
$registered = 0
$failed = 0
foreach ($p in $providers) {
    $target = "$($p.Label) ($($p.Server))"
    if (-not $PSCmdlet.ShouldProcess($target, "Set-DnsClientDohServerAddress $($p.Template)")) {
        continue
    }
    try {
        # -AllowFallbackToUdp $false: hard-fail if DoH isn't reachable
        # rather than silently downgrade to plain UDP/53.
        # -AutoUpgrade $true: existing UDP queries to this IP auto-promote
        # to DoH the next time they fire.
        Set-DnsClientDohServerAddress `
            -ServerAddress $p.Server `
            -DohTemplate $p.Template `
            -AllowFallbackToUdp $false `
            -AutoUpgrade $true `
            -ErrorAction Stop | Out-Null
        Write-Host ("    [OK] {0}" -f $target) -ForegroundColor Green
        Write-ToolkitLog 'doh-template-registered' -Data @{
            server = $p.Server; template = $p.Template; label = $p.Label
        }
        $registered++
    } catch {
        Write-Host ("    [FAIL] {0}: {1}" -f $target, $_.Exception.Message) -ForegroundColor Red
        Write-ToolkitLog 'doh-template-failed' -Level error -Data @{
            server = $p.Server; template = $p.Template; err = $_.Exception.Message
        }
        $failed++
    }
}

# Optionally route active adapters through Cloudflare so DoH actually
# kicks in (registration alone is necessary but not sufficient).
$dnsApplied = $false
if ($ApplyToActiveAdapters) {
    UI-Section -Title 'Routing active adapters through Cloudflare DoH'
    if ($PSCmdlet.ShouldProcess('all active adapters', 'Set DNS to Cloudflare 1.1.1.1 / 1.0.0.1 + IPv6')) {
        try {
            # Set-ToolkitDnsServers takes care of per-adapter, per-family
            # capture so revert can restore the prior DNS state exactly.
            Set-ToolkitDnsServers `
                -ServerAddresses @('1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001') `
                -Tier 'Advanced' `
                -Step 'doh-enable'
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            $dnsApplied = $true
            Write-Host '    [OK] DNS applied; DoH is now actively encrypting queries.' -ForegroundColor Green
        } catch {
            Write-Host ("    [FAIL] Could not apply DNS: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Write-ToolkitLog 'doh-dns-apply-failed' -Level error -Data @{ err = $_.Exception.Message }
        }
    }
}

# After-metric: measure again. On a fresh cache and DoH-routed adapters
# this typically rises 5-30ms (TLS handshake on first query) then drops
# to near baseline once the connection is reused. We log the raw number;
# users interpret.
if ($dnsApplied) {
    Start-Sleep -Milliseconds 500  # let the DNS client settle
    UI-Section -Title 'Post-change DNS latency (first query may include TLS handshake)'
    $msAfter = Measure-Resolution -Tag 'after'
    if ($null -ne $msBefore -and $null -ne $msAfter) {
        $delta = $msAfter - $msBefore
        Write-Host ("    Delta:     {0,+5} ms" -f $delta) -ForegroundColor $(if ($delta -le 30) { 'Green' } else { 'Yellow' })
    }
}

Add-ToolkitStepResult -Key 'doh-enable' -Tier 'Advanced' -Status 'applied' `
    -Reason "Registered $registered DoH templates ($failed failed), DNS-applied=$dnsApplied"

Write-Host ''
UI-Note -Message ('Registered {0} DoH templates. {1}' -f $registered, $(
        if ($ApplyToActiveAdapters) { 'Active adapters routed through Cloudflare.' }
        else { 'Run again with -ApplyToActiveAdapters to actually use DoH.' }
    )) -Color $script:UI_Success
UI-Note -Message 'Verify: Get-DnsClientDohServerAddress | Format-Table' -Color $script:UI_Info
UI-Note -Message "Revert: disable-doh.ps1 in this folder, or REVERT-EVERYTHING.ps1." -Color $script:UI_Info
exit 0
