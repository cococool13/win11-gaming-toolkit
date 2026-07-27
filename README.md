# Win11 Gaming Toolkit

PowerShell-based system-tuning toolkit for Windows 11 gaming machines.
**Manifest-tracked, reversible, no bundled binaries, source-cited.**

> Why this exists: most "Windows gaming optimizer" tools optimize for
> measurable claims and ignore measurable trade-offs. This one
> documents anti-cheat / reboot / disk impact in every script header,
> backs every mutation with a captured-state manifest, and ships its
> reverter as a hard contract.

## At a glance

| | This toolkit |
|---|---|
| Tweaks declare anti-cheat impact | ✓ (66/66 mutators, researched per script) |
| Tweaks declare reboot-required | ✓ (66/66) |
| Tweaks declare disk impact | ✓ (66/66) |
| ShouldProcess (-WhatIf) on every mutator | ✓ (53/53) |
| Every mutator has a paired restore script | ✓ (56/56) |
| Bundled binaries | None — every download is SHA-256 verified |
| Source-cited per tweak (Microsoft Learn / vendor docs) | ✓ |
| Test suite | 1100+ Pester tests, gate-enforced |
| Lib helper coverage | ~48% (gate floor 25%) |
| PSScriptAnalyzer | 0 errors / 0 warnings on every commit |

## Quickstart

1. Clone or download this repo to a local folder.
2. Right-click PowerShell → **Run as Administrator**.
3. From an admin PowerShell:
   ```powershell
   cd "<path-to-repo>"
   .\launcher.ps1
   ```
4. From the launcher:
   - `[V]` verify current state (read-only)
   - `[A]` apply the full stack
   - `[R]` revert all
   - `[?]` keybindings + per-script help

The launcher refuses to start without administrator rights and exits
cleanly. **Read [GUIDE.md](GUIDE.md) before running `[A] Apply All`
for the first time.**

## Risk tiers

Every tweak declares one of three tiers. The launcher color-codes them.

- **Safe** (green) — changes defaults without weakening security.
  Backups, prereq installs, network defaults, verification, audit
  scripts.
- **Advanced** (yellow) — measurable benefit with real trade-offs.
  Disabled services, registry-level UI changes, GPU MSI mode,
  debloat. Reversible.
- **Security Trade-off** (`Trade-off`, red) — disables a real
  security mitigation for performance. VBS / HVCI / LSA-PPL,
  Spectre / Meltdown mitigations, DEP, wholesale Defender disable.
  Opt-in only, reversible, headers explain what breaks.

Every Advanced and Trade-off tweak captures pre-toolkit state to a
manifest at `%ProgramData%\Win11GamingToolkit\state\manifest.json`.
`REVERT-EVERYTHING.ps1` reads the manifest and restores exactly.

## Evidence-backed tweak catalog

Each tweak below carries a Microsoft Learn or vendor-doc citation in
its script header. Categories live in the numbered folders.

### Network (7 network/)

| Pair | What it does | Source |
|---|---|---|
| `disable-doh` / `enable-doh` | Register Cloudflare/Quad9/Google DNS-over-HTTPS templates | [Microsoft Learn — Set-DnsClientDohServerAddress](https://learn.microsoft.com/en-us/powershell/module/dnsclient/set-dnsclientdohserveraddress) |
| `disable-rss-tuning` / `enable-rss-tuning` | Per-adapter RSS queue tuning (min(CPU, NIC, 8)) | [Microsoft — RSS](https://learn.microsoft.com/en-us/windows-hardware/drivers/network/introduction-to-receive-side-scaling) |
| `disable-interrupt-moderation` / `enable-interrupt-moderation` | Per-NIC IM toggle (Intel + Realtek + Marvell vendor coverage) | [Intel — Performance Tuning](https://www.intel.com/content/www/us/en/support/articles/000005811/) |
| `disable-rsc` / `enable-rsc` | Receive Segment Coalescing toggle (lower latency, higher CPU) | [Microsoft — RSC](https://learn.microsoft.com/en-us/windows-hardware/drivers/network/receive-segment-coalescing--rsc-) |
| `disable-ndis-coalescing` / `enable-ndis-coalescing` | NDIS-level IRQ coalescing (Intel I225-V, Mellanox, Realtek) | [Microsoft — Set-NetAdapterAdvancedProperty](https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapteradvancedproperty) |
| `disable-ipv6-binding` / `enable-ipv6-binding` | Per-adapter IPv6 unbind (Trade-off — breaks IPv6-dependent apps) | [Microsoft KB — IPv6 disable](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows) |
| `enable-adapter-power-savings` / `disable-adapter-power-savings` | Per-NIC selective-suspend / wake-on-LAN toggle | [Microsoft — NetAdapterPowerManagement](https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapterpowermanagement) |
| `optimize-network` | TCP/IP stack tuning + Nagle disable + adapter properties | (composite — see header) |

### Registry tweaks (5 registry tweaks/individual/)

Thirty+ per-component paired toggles. The most-used:

| Pair | What it does | Source |
|---|---|---|
| `disable-mpo` / `enable-mpo` | DWM Multiplane Overlay disable (fixes stutter on some HDR rigs); WDDM 2.7+ gate enforced | [Microsoft — WDDM 2.7](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/wddm-2-7-features) |
| `tune-mmcss-audio` / `restore-mmcss-audio` | Pro Audio low-latency MMCSS profile | [Microsoft — MMCSS](https://learn.microsoft.com/en-us/windows/win32/procthread/multimedia-class-scheduler-service) |
| `disable-write-cache-flush` / `enable-write-cache-flush` | Per-disk write cache buffer flushing toggle (Trade-off — data loss risk) | [Microsoft — Storage cache settings](https://learn.microsoft.com/en-us/windows-hardware/drivers/storage/storage-stack-cache-mode-settings) |
| `disable-storage-sense` / `enable-storage-sense` | Stop automatic disk-cleanup background task | [Microsoft — Storage Sense](https://learn.microsoft.com/en-us/windows/configuration/storage-sense) |
| `enable-hags` / `disable-hags` | Hardware-Accelerated GPU Scheduling — `[Experimental]` gated, 24H2/25H2 regression notes inline | [Microsoft — HAGS](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/hardware-accelerated-gpu-scheduling) |
| `disable-diagtrack` / `enable-diagtrack` | DiagTrack service stop + manifest-tracked startup mode | [Microsoft — Manage telemetry endpoints](https://learn.microsoft.com/en-us/windows/privacy/manage-windows-1809-endpoints) |
| `disable-allow-telemetry` / `enable-allow-telemetry` | GPO-layer telemetry cut (AllowTelemetry=Security) | [Microsoft — Configure diagnostic data](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization) |
| `disable-ceip` / `enable-ceip` | Legacy SQMClient CEIP path disable | [Microsoft — SQMClient CEIPEnable](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-7/dd565638(v=ws.10)) |
| `disable-cortana` / `enable-cortana` | AllowCortana=0 GPO | [Microsoft — Cortana on Windows](https://learn.microsoft.com/en-us/windows/configuration/start/cortana-on-windows) |
| `disable-edge-prefetch` / `enable-edge-prefetch` | Edge NetworkPredictionOptions=Disabled | [Microsoft — Edge policies](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies#networkpredictionoptions) |
| `disable-web-search-start` / `enable-web-search-start` | Local-only Start menu results | [Microsoft — Cortana on Windows](https://learn.microsoft.com/en-us/windows/configuration/start/cortana-on-windows) |
| `disable-activity-history` / `enable-activity-history` | Timeline / Activity Feed disable (3 GPO values) | [Microsoft — Windows diagnostic data](https://learn.microsoft.com/en-us/windows/configuration/windows-diagnostic-data) |
| `disable-advertising-id` / `enable-advertising-id` | Per-user AdvertisingInfo\Enabled=0 | [Microsoft — Advertising identifier](https://learn.microsoft.com/en-us/windows/uwp/monetize/about-the-advertising-identifier) |
| `configure-pagefile` / `revert-pagefile` | Set pagefile to Microsoft-recommended sizing (RAM × 1.0 / × 1.5) | [Microsoft — Pagefile sizing](https://learn.microsoft.com/en-us/windows/client-management/determine-appropriate-page-file-size) |

### GPU (6 gpu/)

| Pair | What it does | Source |
|---|---|---|
| `enable-msi-mode` / `disable-msi-mode` | Per-GPU Message-Signaled Interrupts toggle | [Microsoft — MSI](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/introduction-to-message-signaled-interrupts) |
| `force-rebar` / `disable-rebar` | Force Resizable BAR exposure | [Microsoft — ReBAR](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/resizable-bar-support) |
| `force-p0-state` / `revert-p0-state` | NVIDIA pegged to P0 (benchmark consistency) | (vendor — see header) |
| `configure-amd-ulps` / `revert-amd-ulps` | AMD multi-GPU ULPS disable | (vendor — see header) |
| `install-nvidia` / `uninstall-nvidia` (+ AMD + Intel) | Driver install / uninstall via pnputil | (per-vendor download URLs in versions.json) |

### Hardware audits (12 hardware/) — all read-only

| Script | Reports |
|---|---|
| `check-input-polling` | Per-HID-device polling-rate (mouse/keyboard/gamepad) |
| `check-msi-mode` | Per-device MSI mode (GPU + Net + NVMe) |
| `check-rebar` | 3-layer ReBAR state (silicon / firmware / driver) |
| `check-directstorage` | 4-prereq DirectStorage check (PASS/WARN/FAIL) |
| `check-pagefile` | Pagefile config + Microsoft-recommended sizing |
| `check-cpu-stress` | CPU thermal/frequency + 3rd-party stress tool availability |
| `check-gpu-stress` | GPU thermal/clock + stress tool availability |
| `check-ram` | DIMM inventory + WHEA error counts (corrected / uncorrected) |
| `show-mouse-info` | Connected mice + reported polling rates |

### External tools (13 external tools/) — launchers, not bundles

Three third-party GUIs that cover ground this toolkit deliberately doesn't.
Nothing is vendored: each script downloads the tool at runtime, **verifies its
Authenticode signature against the expected publisher, and refuses to execute
on a mismatch** — the same abort-never-warn rule the rest of the toolkit uses.
Downloads are deleted on exit unless you pass `-KeepDownload`.

| Script | Tool | Verified publisher | Covers |
|---|---|---|---|
| `launch-shutup10` | O&O ShutUp10++ | O&O Software GmbH | Telemetry / privacy toggles as one checklist |
| `launch-autoruns` | Sysinternals Autoruns | Microsoft Corporation | Every auto-start location, well past Task Manager |
| `launch-device-cleanup` | DeviceCleanup | Uwe Sieber | Stale non-present devices after hardware swaps |

These are verified by publisher signature rather than a pinned SHA-256:
all three ship from rolling "latest" URLs, so a pinned hash would break the
download on the vendor's next release while proving nothing extra. Tools with
a versioned URL (DDU, WinUtil, 7-Zip) stay SHA-256 pinned in `versions.json`.

> Changes you make **inside** these tools are not toolkit steps: they are not
> written to the manifest and `REVERT-EVERYTHING` will not undo them. Each
> tool owns its own undo (ShutUp10's restore point, re-ticking an Autoruns
> entry, reattaching hardware).

### Security trade-offs (8 security vs performance/)

Opt-in only. Each has a paired restorer.

| Pair | What it does | Anti-cheat impact |
|---|---|---|
| `configure-vbs -Disable` / `configure-vbs -Enable` | VBS / HVCI / LSA Protection toggle | **HIGH** — breaks R6 Siege (BattlEye) + Valorant (Vanguard) on Win11 24H2+ |
| `disable-spectre-meltdown` / `enable-spectre-meltdown` | CPU speculative-execution mitigations | NONE |
| `disable-defender-wholesale` / `enable-defender-wholesale` | Wholesale Defender disable | NONE direct |
| `disable-dep` / `enable-dep` | BCD nx=AlwaysOff | NONE |
| `disable-smt-ht` / `enable-smt-ht` | BCD numproc cap | NONE on most CPUs; potential heuristic flag on Zen 5 |

## Comparison with alternatives

| Concern | This toolkit | ChrisTitusTech/winutil | FR33THY/Ultimate | BoringBoredom/PC-Tuning | djdallmann/GamingPCSetup |
|---|---|---|---|---|---|
| Reversible via manifest | ✓ | partial (per-tweak) | ✗ | ✗ | ✗ |
| Anti-cheat impact in every script header | ✓ (researched) | ✗ | ✗ | partial | partial |
| Reboot/disk impact in every header | ✓ | ✗ | ✗ | ✗ | ✗ |
| Pester test suite enforced in CI | ✓ (1100+) | ✗ | ✗ | ✗ | ✗ |
| PSScriptAnalyzer 0/0 enforced | ✓ | ✗ | ✗ | n/a | n/a |
| SHA-256 verified third-party downloads | ✓ | ✓ | partial | n/a | n/a |
| Microsoft Learn / vendor cite per tweak | ✓ | partial | ✗ | ✓ | partial |
| Cross-platform dev (macOS / Linux dev hosts) | ✓ (lib falls back to XDG_DATA_HOME) | ✗ | ✗ | ✗ | ✗ |
| Bundled binaries shipped in-repo | None | None | Some | None | None |
| Active maintenance | ✓ | ✓ | ✓ (active) | Mostly archived | Less active |

Where the other tools win:
- **ChrisTitusTech/winutil** has a richer GUI, broader catalog, more
  active community. Excellent if you want one-click and don't need
  the rollback contract this toolkit provides.
- **FR33THY/Ultimate** has more aggressive Windows-system tweaks
  and a strong community feedback loop. Many of this toolkit's
  scripts cite FR33THY as the upstream source.
- **BoringBoredom/PC-Tuning** is a research-paper-style write-up
  with extensive citations; this toolkit cites the same Microsoft
  Learn docs but ships them as runnable scripts.

## Documentation

- [GUIDE.md](GUIDE.md) — full operating instructions, repo map,
  troubleshooting (Win11 24H2 / 25H2 WaaSMedicSvc recovery).
- [BIOS-CHECKLIST.md](BIOS-CHECKLIST.md) — hardware tuning the
  toolkit cannot script (BIOS settings, hardware-side diagnostics).
- [CHANGELOG.md](CHANGELOG.md) — release notes per version.
- [KNOWN-ISSUES.md](KNOWN-ISSUES.md) — items considered, shipped
  limitations.
- [MANUAL-TEST-CHECKLIST.md](MANUAL-TEST-CHECKLIST.md) — runtime
  gate before any release tag.
- [SESSION-REPORT.md](SESSION-REPORT.md) — per-development-session
  changelog with architecture decisions, gap-tracking history.
- [CLAUDE.md](CLAUDE.md) — invariants, conventions, scope philosophy.

## Credits

- **FR33THY** — <https://github.com/FR33THYFR33THY/Ultimate>. Source
  for MPO disable, MMAgent tuning, NIC power savings, IPv6 unbind,
  Spectre / Meltdown override, DEP toggle, NVIDIA P0 state, AMD ULPS
  disable, Offline Files disable. Per-file attribution in script
  headers.
- **Khorvie Tech** — original toolkit lineage. Lineage credit in
  `Notice.txt`.
- **Chris Titus Tech** — <https://github.com/ChrisTitusTech/winutil>.
  Wrapped (SHA-256 verified) by `9 cleanup\chris-titus-winutil.bat`.
- **Wagnardsoft** — Display Driver Uninstaller. Wrapped by
  `DduManual.ps1` / `DduAuto.ps1`.

## License

MIT — see [LICENSE](LICENSE). Third-party tools the toolkit downloads
remain under their respective licenses.

## Versioning

The current version is in [VERSION](VERSION). The launcher reads it
at runtime. Tags follow [Semantic Versioning](https://semver.org/).
