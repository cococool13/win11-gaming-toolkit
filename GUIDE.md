# Windows 11 Ultimate Gaming Optimization Guide

> A modern, safe, comprehensive guide to maximum gaming performance on Windows 11.
> No bundled executables. No bloatware. No harmful tweaks. Just clean scripts you can read and verify yourself.

---

## Quick Start — One-Click Apply

**Don't want to go step by step?** Run the master script to apply all safe tweaks at once:

```powershell
# Open PowerShell as Administrator, then:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\APPLY-EVERYTHING.ps1
```

This applies Steps 1-2, 4-7, and 9 automatically (backup, power plan, services, registry, GPU MSI mode, network, debloat, cleanup). It skips Step 3 (manual Windows Settings) and Step 8 (VBS — security trade-off). To undo: run `REVERT-EVERYTHING.ps1`.

---

## Before You Start

- **Back up first.** Step 1 exists for a reason. Don't skip it.
- **Run scripts as Administrator.** Right-click > "Run as administrator" for every `.bat` file.
- **PowerShell scripts** may need you to allow execution first:
  Open PowerShell as Admin and run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Every tweak is reversible.** Each step includes revert scripts or instructions.
- **Read the warnings.** Some tweaks (especially Step 8) have real trade-offs.
- **Check your BIOS first.** See [BIOS-CHECKLIST.md](BIOS-CHECKLIST.md) — enabling XMP alone can give 10-30% more FPS.
- **Gaming session mode.** Before a gaming session, run `gaming-mode.ps1` to close background apps, silence notifications, and pause updates. Run `gaming-mode-off.ps1` when done (or just reboot).

---

## Table of Contents

| Step | Name | Difficulty | Risk | Revertible? |
|------|------|-----------|------|-------------|
| [0](#step-0-install-gaming-prerequisites) | Install Gaming Prerequisites | Easy | None | N/A |
| [1](#step-1-backup--restore-point) | Backup & Restore Point | Easy | None | N/A |
| [2](#step-2-power-plan) | Power Plan (Basic + Advanced) | Easy | Safe | Yes |
| [3](#step-3-windows-settings) | Windows Settings | Easy | Safe | Yes (manual) |
| [4](#step-4-disable-unnecessary-services) | Disable Unnecessary Services | Easy | Low | Yes |
| [5](#step-5-registry-tweaks) | Registry Tweaks (Expanded) | Medium | Low | Yes |
| [6](#step-6-gpu-optimization) | GPU Optimization + MSI Mode | Medium | Safe | Yes |
| [7](#step-7-network-optimization) | Network Optimization | Medium | Low | Yes |
| [8](#step-8-security-vs-performance) | Security vs Performance (VBS) | Medium | Moderate | Yes |
| [9](#step-9-cleanup--debloat) | Cleanup, Debloat & WinUtil | Easy | Low | Partial |
| [10](#step-10-verify--benchmark) | Verify & Benchmark | Easy | None | N/A |

**Difficulty:** Easy = just run a script or toggle a setting. Medium = may need to understand what you're changing.
**Risk:** Safe = no downside. Low = minor side effects possible. Moderate = security trade-off (explained in detail).

---

## Step 0: Install Gaming Prerequisites

📁 **Folder:** `0 prerequisites/`

Many games require Visual C++ Redistributables and the legacy DirectX runtime. Without them, you get errors like "VCRUNTIME140.dll not found" or "d3dx9_43.dll not found".

### What to run:
- **`install-runtimes.ps1`** — Downloads and installs ALL Visual C++ runtimes (2005-2022) and the DirectX June 2010 legacy runtime

### What it installs:
- Visual C++ 2005, 2008, 2010, 2012, 2013, 2015-2022 (x86 + x64)
- DirectX June 2010 redistributable (D3DX9, D3DX10, D3DX11, XInput, etc.)

### Requirements:
- Internet connection (~200MB download)
- ~5 minutes to complete

---

## Step 1: Backup & Restore Point

📁 **Folder:** `1 backup/`

**Do this first.** Before changing anything, create a safety net.

### What to run:
1. **`create-restore-point.bat`** — Creates a Windows System Restore point
2. **`backup-registry.bat`** — Exports all registry keys we'll modify to your Desktop

### How to restore:
- **System Restore:** Start Menu > search "Create a restore point" > System Restore > select "Before Gaming Optimization"
- **Registry:** Double-click any `.reg` file in the backup folder on your Desktop

---

## Step 2: Power Plan

📁 **Folder:** `2 power plan/`

### What to run:
1. **`enable-ultimate-performance.bat`** — Unhides and activates the "Ultimate Performance" power plan
2. **`configure-power-plan.ps1`** *(NEW — Advanced)* — Fine-tunes every power sub-setting

### What the advanced script adds:
| Setting | Value | Why |
|---------|-------|-----|
| CPU min/max state | 100% / 100% | No downclocking |
| Core parking | All cores unparked | All CPU cores always active |
| PCI-E link state | Off | Full GPU bus speed |
| USB selective suspend | Off | Prevents peripheral disconnects |
| USB 3 link power mgmt | Off | Full USB bandwidth |
| Hibernate / Sleep | Off | No unexpected interruptions |
| Power throttling | Off | Prevents background throttling |
| Adaptive brightness | Off | Consistent display brightness |
| Wireless adapter | Max performance | Full WiFi speed |

### To revert:
Settings > System > Power > Power mode > select "Balanced"

---

## Step 3: Windows Settings

📁 **Folder:** `3 windows settings/`

### How to use:
1. Open the **CHECKLIST.md** file in this folder
2. Double-click each `.url` shortcut to jump directly to the right Settings page
3. Follow the checklist to change each setting

### Key changes:
| Setting | Change to | Why |
|---------|-----------|-----|
| Monitor refresh rate | Highest available | Smoother gameplay |
| HAGS | On | Lower input lag |
| Enhance pointer precision | **OFF** | Removes mouse acceleration |
| Startup apps | Disable unneeded | Frees RAM and CPU |
| Game Mode | On | Prioritizes game processes |
| Visual Effects | Best performance | Frees GPU resources |
| Do Not Disturb | On during gaming | No popup interruptions |

---

## Step 4: Disable Unnecessary Services

📁 **Folder:** `4 services/`

### What to run:
- **`apply-all.bat`** — Disables all listed services at once
- **`revert-all.bat`** — Re-enables all services

Or use **individual scripts** in `4 services/individual/` to toggle specific services.

### Services disabled:
| Service | What it does | Why disable |
|---------|-------------|-------------|
| DiagTrack | Sends telemetry to Microsoft | Uses CPU/network |
| Phone Service | Phone Link integration | Unnecessary for gaming |
| Geolocation | Location tracking | Unnecessary for desktop |
| Print Spooler | Manages printing | Skip if you have a printer |
| Windows Search | Indexes files for search | Frees CPU; Start search slower |
| Retail Demo | Store display mode | Never needed |
| Maps Manager | Offline maps | Unnecessary |
| Fax | Fax service | It's 2026 |

### What we DON'T disable:
BITS (breaks Windows Update), SysMain (Win11 manages well), Windows Defender, Audio services.

---

## Step 5: Registry Tweaks (Expanded)

📁 **Folder:** `5 registry tweaks/`

Now includes comprehensive privacy, visual effects, sound, Game Bar, explorer, and accessibility tweaks from multiple sources.

### What to run:
1. **`backup-current.bat`** FIRST — saves current registry values
2. **`apply-all.reg`** — applies ALL tweaks at once

Or pick individual tweaks from `5 registry tweaks/individual/`:

### Performance Tweaks:
| File | What it does |
|------|-------------|
| `menu-show-delay.reg` | Instant right-click menus |
| `mouse-hover-time.reg` | Instant tooltips |
| `disable-startup-delay.reg` | Apps load immediately at boot |
| `disable-driver-searching.reg` | Prevents auto-installing generic drivers |
| `disable-fast-startup.reg` | True clean shutdown; fixes dual-boot |
| `disable-fullscreen-optimizations.reg` | Reduces input lag in fullscreen games |
| `game-priority.reg` | More CPU/GPU time for games + no network throttle |
| `disable-power-throttling.reg` | *(NEW)* Prevents CPU throttling |
| `visual-effects-performance.reg` | *(NEW)* Disables all animations (keeps smooth fonts) |
| `disable-game-bar-dvr.reg` | *(NEW)* Disables Game Bar overlay (Game Mode stays ON) |
| `sound-scheme-none.reg` | *(NEW)* Removes all system sounds |
| `explorer-tweaks.reg` | *(NEW)* Show extensions, full path, disable OneDrive ads |
| `privacy-telemetry.reg` | *(NEW)* Comprehensive privacy lockdown |

### Windows Update Management:
| File | What it does |
|------|-------------|
| `disable-auto-restart.reg` | *(NEW)* Prevents forced restarts during gaming (sets active hours 8AM-2AM) |
| `revert-auto-restart.reg` | *(NEW)* Restores default auto-restart behavior |
| `disable-windows-update.ps1` | *(NEW)* Permanently disables Windows Update service + related services |
| `enable-windows-update.ps1` | *(NEW)* Re-enables Windows Update (run monthly to check for updates) |

### Advanced (PowerShell):
| File | What it does |
|------|-------------|
| `install-timer-resolution-service.ps1` | *(NEW)* Installs service for ~0.5ms timer (reduces input lag) |

### To revert:
Double-click **`revert-all.reg`** and confirm.

---

## Step 6: GPU Optimization

📁 **Folder:** `6 gpu/`

Open the subfolder for your GPU brand: **nvidia/**, **amd/**, or **intel/**

### NEW: MSI Mode for All GPUs
- **`enable-msi-mode.ps1`** — Enables Message Signaled Interrupts for all GPUs
- MSI mode has lower latency than legacy line-based interrupts
- Can reduce micro-stuttering in games

### GPU Subfolders:
Each contains a README with clean driver installation, recommended settings, and Resizable BAR / Smart Access Memory setup.

### DDU (Display Driver Uninstaller):
For the cleanest possible driver install, use DDU to completely remove old drivers before installing new ones. Download from the official site — see the GPU READMEs for links.

---

## Step 7: Network Optimization

📁 **Folder:** `7 network/`

### What to run:
- **`optimize-network.bat`** — Applies all network tweaks
- **`revert-network.bat`** — Restores defaults

### What it does:
- Disables Nagle's Algorithm (biggest impact — reduces packet batching delay)
- Disables Large Send Offload
- Disables TCP Timestamps
- Enables RSS (spreads network load across CPU cores)
- Sets DNS to Cloudflare Gaming (1.1.1.1) — shaves 10-50ms off server lookups
- Flushes DNS cache

See the README.txt in this folder for router QoS tips, port forwarding for popular games, and WiFi optimization for laptops.

---

## Step 8: Security vs Performance

📁 **Folder:** `8 security vs performance/`

> **READ THE README.txt IN THIS FOLDER BEFORE PROCEEDING.**

### Performance impact:
- **5-25% FPS improvement** depending on game and CPU

### What to run:
- **`disable-vbs.bat`** — Disables VBS + HVCI (requires reboot)
- **`enable-vbs.bat`** — Re-enables everything (requires reboot)

### Note:
The APPLY-EVERYTHING.ps1 script does NOT include this step. You must run it manually after reading the trade-offs.

---

## Step 9: Cleanup, Debloat & WinUtil

📁 **Folder:** `9 cleanup/`

### What to run:
1. **`debloat.ps1`** — Removes Windows 11 bloatware apps
2. **`cleanup-temp.bat`** — Clears temp files, shader cache, Windows Update cache
3. **`chris-titus-winutil.bat`** *(NEW)* — Launches Chris Titus Tech's WinUtil

### Chris Titus Tech Windows Utility (WinUtil):
A popular open-source GUI tool for Windows optimization. It can:
- Remove bloatware with checkboxes (visual interface)
- Install common programs (browsers, 7-Zip, VLC, etc.)
- Apply Windows tweaks via a simple interface
- Configure Windows Update policies

**Source:** github.com/ChrisTitusTech/winutil
**Nothing is installed** — it downloads and runs directly from GitHub each time.

To launch: Right-click `chris-titus-winutil.bat` > Run as Administrator

---

## Step 10: Verify & Benchmark

📁 **Folder:** `10 verify/`

### Automated Health Check:
- **`verify-tweaks.ps1`** *(NEW)* — Scans every tweak and outputs a color-coded report
  - **PASS** (green): Tweak is applied correctly
  - **FAIL** (red): Tweak is missing or was reverted (e.g., by Windows Update)
  - **WARN** (yellow): Optional tweak not applied
  - Shows an overall **Optimization Score** (e.g., "85% — 22/26 tweaks applied")

Run this after applying tweaks, and periodically to check if Windows Update reverted anything.

### Recommended tools:
| Tool | Best for | Cost |
|------|----------|------|
| CapFrameX | Real-world game FPS + frame time recording | Free |
| 3DMark Time Spy | Synthetic GPU benchmark | Free demo on Steam |
| UserBenchmark | Quick overall system health check | Free |

### Expected total improvement:
| Tweak | Expected FPS Gain |
|-------|-------------------|
| VBS/HVCI disabled (Step 8) | 5-25% |
| Power plan + services | 2-5% |
| Registry tweaks | 1-3% (mostly feel) |
| Timer Resolution Service | 1-3% (frame pacing) |
| MSI mode + GPU optimization | 2-10% |
| Network optimization | Lower ping, not FPS |
| **Total combined** | **10-35% FPS improvement** |

---

## Troubleshooting & Recovery

Something went wrong? Don't panic. Every tweak in this guide is reversible. Use this section to diagnose and fix common issues.

### Quick Fix: Bisect Method

If you're not sure which tweak caused a problem:
1. Run `REVERT-EVERYTHING.ps1` to undo all changes
2. If the problem goes away, re-apply tweaks **one step at a time**
3. Test after each step — when the problem returns, you found the culprit
4. Skip that tweak and continue with the rest

### Common Issues

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Game crashes after tweaks | Timer resolution or VBS change | Revert Step 5 timer service, or re-enable VBS (Step 8) |
| Black screen after GPU tweak | MSI mode or driver issue | Boot into Safe Mode (hold Shift + click Restart), run `6 gpu/enable-msi-mode.ps1` with `-Revert`, or use DDU to reinstall drivers |
| System unstable / random freezes | Power plan too aggressive or core unparking | Revert Step 2 first: Settings > Power > select "Balanced" |
| Start menu search is slow/broken | Windows Search service disabled | Run `4 services/individual/wsearch-enable.bat` as Admin |
| USB devices disconnect randomly | USB selective suspend in power plan | Check Settings > Power > USB settings, or revert Step 2 |
| Printer not working | Print Spooler service disabled | Run `4 services/individual/printspooler-enable.bat` as Admin |
| Blue screen (BSOD) | Usually MSI mode or timer resolution | Boot Safe Mode, revert MSI mode and uninstall timer service |
| Game stuttering got WORSE | Nagle's Algorithm or LSO change | Run `7 network/revert-network.bat` as Admin |
| Windows Update won't install | Services disabled or update paused | Run `4 services/revert-all.bat`, check if updates are paused |
| Can't hear system sounds | Sound scheme set to None | Run `5 registry tweaks/revert-all.reg` or go to Sound settings |

### Safe Mode Recovery

If you can't boot normally:
1. **Force Safe Mode:** Hold power button to shut down 3 times in a row — Windows will enter Recovery Mode
2. Select **Troubleshoot > Advanced options > Startup Settings > Restart**
3. Press **4** or **F4** for Safe Mode (or **5/F5** for Safe Mode with Networking)
4. In Safe Mode, run the relevant revert script or use System Restore from Step 1

### Known Incompatibilities

| Tweak | Incompatibility | Workaround |
|-------|----------------|------------|
| VBS disabled (Step 8) | Some anti-cheat systems (Vanguard, FACEIT) may require VBS/HVCI | Re-enable VBS for those games |
| Timer Resolution Service | Rare conflicts with audio production software (DAWs) | Stop the STR service before using DAW software |
| MSI mode | Some older GPUs (pre-2016) don't support MSI properly | Revert MSI mode if you see display artifacts |
| Nagle disabled | Can increase bandwidth usage on metered connections | Revert network tweaks if on limited data |
| Windows Search disabled | Outlook desktop search won't work | Re-enable Windows Search if you use Outlook |

### Nuclear Option: System Restore

If nothing else works:
1. Boot into Safe Mode (see above)
2. Open **Start Menu > search "Create a restore point"**
3. Click **System Restore**
4. Select the **"Before Gaming Optimization"** restore point from Step 1
5. This undoes ALL changes at once (registry, services, everything)

---

## How to Revert Everything

If something goes wrong or you want to undo all changes:

### Quick (one-click revert):
Run **`REVERT-EVERYTHING.ps1`** as Administrator — this undoes everything APPLY-EVERYTHING.ps1 changed (power plan, services, registry, network, GPU MSI mode, timer service).

### Manual (step-by-step):
1. **Registry:** Double-click `5 registry tweaks/revert-all.reg`
2. **Services:** Run `4 services/revert-all.bat` as Administrator
3. **Network:** Run `7 network/revert-network.bat` as Administrator
4. **VBS:** Run `8 security vs performance/enable-vbs.bat` as Administrator
5. **Power plan:** Settings > System > Power > select "Balanced"
6. **Windows Settings:** Manually revert using the checklist
7. **Timer Service:** `Stop-Service STR; sc.exe delete STR`
8. **Removed apps:** Reinstall from Microsoft Store
9. **Nuclear option:** Use the System Restore point from Step 1

---

## File Map

```
APPLY-EVERYTHING.ps1              ← One-click apply all safe tweaks
REVERT-EVERYTHING.ps1             ← One-click undo all tweaks
GUIDE.md                          ← This document
BIOS-CHECKLIST.md                 ← NEW — BIOS optimization (XMP, ReBAR, etc.)
gaming-mode.ps1                   ← NEW — Pre-gaming session optimizer
gaming-mode-off.ps1               ← NEW — Restore normal mode after gaming
0 prerequisites/
  ├── install-runtimes.ps1        ← C++ Runtimes & DirectX
  └── README.txt
1 backup/
  ├── create-restore-point.bat
  └── backup-registry.bat
2 power plan/
  ├── enable-ultimate-performance.bat
  ├── configure-power-plan.ps1    ← Advanced power settings
  └── README.txt
3 windows settings/
  ├── *.url                       ← Settings page shortcuts
  └── CHECKLIST.md
4 services/
  ├── apply-all.bat
  ├── revert-all.bat
  └── individual/                 ← Per-service toggle scripts
5 registry tweaks/
  ├── backup-current.bat
  ├── apply-all.reg               ← All tweaks combined
  ├── revert-all.reg
  └── individual/
      ├── menu-show-delay.reg
      ├── mouse-hover-time.reg
      ├── disable-startup-delay.reg
      ├── disable-driver-searching.reg
      ├── disable-fast-startup.reg
      ├── disable-fullscreen-optimizations.reg
      ├── game-priority.reg
      ├── disable-nagle.reg
      ├── disable-power-throttling.reg
      ├── visual-effects-performance.reg
      ├── disable-game-bar-dvr.reg
      ├── sound-scheme-none.reg
      ├── explorer-tweaks.reg
      ├── privacy-telemetry.reg
      ├── disable-auto-restart.reg           ← NEW — Prevent update restarts
      ├── revert-auto-restart.reg            ← NEW
      ├── disable-windows-update.ps1         ← NEW — Permanently disable WU
      ├── enable-windows-update.ps1          ← NEW — Re-enable WU for updates
      └── install-timer-resolution-service.ps1 (advanced)
6 gpu/
  ├── enable-msi-mode.ps1         ← MSI mode for all GPUs
  ├── nvidia/README.txt
  ├── amd/README.txt
  └── intel/README.txt
7 network/
  ├── optimize-network.bat        ← Now includes DNS optimization
  ├── revert-network.bat
  └── README.txt                  ← Expanded: QoS, port forwarding, WiFi tips
8 security vs performance/
  ├── disable-vbs.bat
  ├── enable-vbs.bat
  └── README.txt
9 cleanup/
  ├── debloat.ps1
  ├── cleanup-temp.bat
  └── chris-titus-winutil.bat     ← Chris Titus WinUtil launcher
10 verify/
  ├── verify-tweaks.ps1           ← NEW — Automated health check report
  └── README.txt
```

---

## FAQ

**Q: What's the single biggest FPS gain?**
A: Disabling VBS/HVCI (Step 8). It's 5-25% but has a security trade-off.

**Q: What if I just want to run one thing?**
A: Run `APPLY-EVERYTHING.ps1` as Administrator. It does everything except VBS (manual choice).

**Q: Is this safe?**
A: Every tweak is reversible. We removed harmful tweaks from the original guides (disabling BITS, SysMain, Prefetch). The only real trade-off is Step 8 (VBS), clearly documented.

**Q: What's the Timer Resolution Service?**
A: Windows normally ticks at ~15.6ms intervals. The service forces ~0.5ms ticks, which improves frame pacing and reduces input lag. It's used by competitive gamers. Install via `install-timer-resolution-service.ps1`.

**Q: What's Chris Titus WinUtil?**
A: An open-source GUI tool from YouTuber Chris Titus Tech that debloats Windows, installs programs, and applies tweaks. We include a launcher script — it downloads and runs directly from GitHub each time (nothing permanently installed).

**Q: What about DDU?**
A: DDU (Display Driver Uninstaller) is the gold standard for clean GPU driver installs. See the GPU READMEs in Step 6 for download links and instructions. We don't automate the safe-mode DDU process because it requires a reboot into Safe Mode and user interaction.

**Q: Do I need to run all steps?**
A: No. Each step is independent. Steps 2, 5, and 8 give the biggest gains for the least effort.

**Q: I have a laptop. Should I do all of this?**
A: Skip the advanced power plan tuning on battery. Everything else is fine.

**Q: How do I check if my tweaks are still applied?**
A: Run `10 verify/verify-tweaks.ps1` as Administrator. It checks every tweak and gives you a color-coded health report with an optimization score.

**Q: How do I stop Windows from restarting during a gaming session?**
A: Apply `disable-auto-restart.reg` (Step 5) to prevent forced restarts. For full control, run `disable-windows-update.ps1` to permanently disable Windows Update. Run `enable-windows-update.ps1` monthly to check for updates, then disable again.

**Q: What's Gaming Mode (gaming-mode.ps1)?**
A: A session launcher you run before gaming. It closes resource hogs (browsers, OneDrive, etc.), silences notifications, clears RAM, and pauses Windows Update. Nothing is permanent — everything restores on reboot or by running `gaming-mode-off.ps1`.

**Q: Should I change BIOS settings?**
A: Yes! See `BIOS-CHECKLIST.md`. Enabling XMP/DOCP alone can give 10-30% more FPS in CPU-bound games because your RAM is probably running at half its rated speed.

**Q: Why don't you bundle any .exe tools?**
A: Bundled executables go stale, can be tampered with, and create licensing issues. We link to official download pages so you always get the latest verified version.

---

## Credits & Sources

- FR33THY (youtube.com/FR33THY) — Timer Resolution Service, DDU automation, comprehensive privacy tweaks, power plan fine-tuning
- Chris Titus Tech (christitus.com) — WinUtil debloating tool
- Community-sourced Windows optimization knowledge

Built for the community. Share freely. If you find an issue, report it.
