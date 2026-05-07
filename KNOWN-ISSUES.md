# Known Issues and Intentional Omissions

This file documents items that were considered but not shipped, with reasoning. It is the place to look when you ask "why doesn't the toolkit do X" — especially for X drawn from FR33THY/Ultimate or other Windows tweak guides.

## Items declined from FR33THY/Ultimate

### `2 Refresh/*` — bare-metal install flow

FR33THY ships factory-reset, `autounattend.xml`, and reinstall scripts for clean Windows installs. This toolkit operates on existing systems. Out of scope.

### `3 Setup/1 BitLocker.ps1` — BitLocker disable

Disabling BitLocker requires re-encryption decisions and TPM behavior that should be a manual user decision, not a scripted toggle. Skip.

### `3 Setup/3-12` (most of Setup folder)

First-boot configuration (Convert Home→Pro, language/region, Edge settings, Store settings) is one-time install plumbing. Out of scope. `12 Updates Pause` overlaps `5 registry tweaks/individual/disable-windows-update.ps1` already in this repo.

### `4 Installers/*` — third-party tool bundles

MSI Afterburner, NVIDIA Profile Inspector, MoreClockTool, CRU. We do not bundle binaries (constraint #4 in the toolkit charter). Users should install these tools themselves from upstream sources.

### `5 Graphics/3 Driver Install Debloat & Settings.ps1` (33 KB)

Overlaps `DduManual.ps1` + `DduAuto.ps1` + `6 gpu/install-gpu-driver.ps1` flow we already maintain. Re-implementing FR33THY's flow on top would be redundant and add a second installer code path.

### `5 Graphics/7 Hdcp.ps1` — HDCP disable

HDCP affects DRM-protected content (Netflix, etc.) more than gaming performance. Niche.

### `5 Graphics/12 Resolution Refresh Rate.ps1` & `13 Hags Windowed.ps1`

Both walk the user through clicking the Settings UI. No registry equivalent. Documented in `BIOS-CHECKLIST.md` instead.

### `6 Windows/22 Control Panel Settings.ps1` (108 KB)

A 108 KB registry blob touching hundreds of keys. Many overlap our existing changes; many are preference-driven (icon spacing, taskbar appearance) rather than performance. Porting wholesale would require auditing every key for tier classification — too broad for the safety/correctness budget. Cherry-picking the genuinely additive performance keys (write cache, MMAgent, MPO) was done; the rest is left.

### `6 Windows/31 UAC.ps1` — UAC lowering

Lowering UAC has clear security implications and no measurable gaming-performance benefit. Skip.

### `6 Windows/33 Defender Optimize.ps1` (24 KB) & `8 Advanced/1 Defender.ps1` (30 KB)

Wholesale Defender disable. Crosses the line from "performance trade-off" to "broken Windows install" — per the brief, items that disable Defender wholesale are explicitly out of scope. We already provide `Defender exclusions` for game library paths under `Security Trade-off`, which is the supportable middle ground.

### `8 Advanced/2 Firewall.ps1` — firewall disable

Same logic as Defender. We don't ship a script that disables Windows Firewall. Users who want firewall changes should make them manually with full awareness.

### `8 Advanced/5 File Download Security Warning.ps1`

Disables Mark-of-the-Web SmartScreen warnings on downloaded files. Real malware-mitigation feature. Skip.

### `8 Advanced/8 Smt Ht.ps1` — Disable SMT / HT

Disabling Hyper-Threading / SMT helps a narrow class of CPU-bound games and *hurts* every productivity workload. Workload-specific. Skip — users who need this know exactly when they need it and can do it from BIOS.

### `8 Advanced/9 Core 1 Thread 1.ps1` — single-core affinity for `explorer.exe`

Pins Explorer to logical core 1. Breaks every multithreaded application that inherits affinity. Workload-specific. Skip.

### `8 Advanced/15 Driver Whql Secure Boot Bypass.ps1`

Disables Windows driver-signing enforcement. Real attack surface increase, niche benefit (lets unsigned drivers load). Skip.

### `8 Advanced/19 NVME Faster Driver.ps1`

Force-installs Microsoft's inbox `stornvme.sys` over vendor NVMe drivers. Vendor drivers carry firmware-specific quirks (queue depth, command coalescing, telemetry); switching to inbox often costs more than the marginal performance gain. Skip — users who want this should install via Device Manager themselves.

## Items shipped as opt-in only (NOT in `APPLY-EVERYTHING.ps1`)

### `5 registry tweaks/individual/disable-write-cache-flush.ps1`

Per-disk write cache buffer flushing disabled. Material data-loss risk on power loss. Provided as a standalone script for users on UPS-backed desktops who explicitly want the small write-throughput gain. Reverted via paired `enable-write-cache-flush.ps1`.

## Existing toolkit limitations carried forward

### Domain-joined PCs

`partOfDomain = true` is captured in the manifest profile and surfaced as a launcher hint. The aggressive update-suppression and Defender-exclusion steps will still run if the user proceeds — the toolkit does not auto-skip them. Enterprise policy may revert most of the changes anyway. Run on a domain-joined gaming PC at your own risk.

### Battery laptops

The launcher reports `isLaptop / isHandheld` and surfaces a "start with Setup, then use only the areas you understand" hint. Aggressive power tuning still applies if the user proceeds. The Ultimate Performance plan removes thermal/battery throttling, which on a laptop on battery measurably shortens battery life. Users on laptops should switch the active power plan back to Balanced when on battery.

### ARM64 Windows

Driver-related items (MSI mode for GPU on Snapdragon X) are not separately tested. The PnP enumeration filter in `lib/gpu-detection.ps1` matches by PCI vendor ID, so non-PCI integrated graphics (Snapdragon X Adreno) are skipped automatically. Some other items (DDU flow, NVIDIA-specific scripts) are no-ops on ARM and silently skip.

### `WaaSMedicSvc` on 24H2 / 25H2

`disable-windows-update.ps1` may report a warning if the WaaSMedicSvc registry key has a DACL that prevents even SYSTEM from writing the `Start` value. On those builds, Windows Update may auto-re-enable itself periodically. Taking ownership of the key with `takeown` and `icacls` is documented in `GUIDE.md` Troubleshooting; the toolkit will not do this automatically.

### Stripped Windows images (Server Core, debloat ISOs)

`install-timer-resolution-service.ps1` requires `csc.exe` from .NET Framework 4.0. Missing on stripped images. The script fails with a clear error and exits cleanly. Use `Add-WindowsCapability -Online -Name 'NetFx3~~~~'` to recover, then re-run.
