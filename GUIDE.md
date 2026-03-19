# Windows 11 Gaming Optimization Guide

This repo is a Windows optimization toolkit with one primary path:

1. Read this guide.
2. Launch `launcher.ps1`.
3. Run only the phases that match your machine and your tolerance for trade-offs.

`APPLY-EVERYTHING.ps1` is still available, but it is the aggressive path, not the default recommendation.

## Before You Start

- Run PowerShell scripts as Administrator.
- If PowerShell blocks local scripts, run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` in an elevated shell.
- Create a backup first. The toolkit has a checkpoint path for a reason.
- Laptops, hybrid-GPU systems, and work-managed PCs need extra care.
- Not every change is perfectly reversible. The manifest improves rollback, but removed apps and some system policies can still require manual recovery.

## Choose Your Path

### Recommended path: launcher first

Run:

```powershell
.\launcher.ps1
```

Use the launcher as the main entrypoint. It groups the repo into:

- `Setup` for backup and prerequisites
- `Optimize` for power, services, registry, cleanup, and security trade-offs
- `GPU and Network` for device-specific tuning and driver flows
- `Safety and Verify` for full apply, full revert, and verification

### Aggressive path: full-stack apply

Run:

```powershell
.\APPLY-EVERYTHING.ps1
```

Use this only when you already understand the trade-offs. It includes:

- power and Windows tuning
- service and registry changes
- startup cleanup
- GPU MSI mode and network tuning
- Windows Update suppression
- VBS / HVCI / LSA trade-offs
- shell customization
- Defender exclusions
- app debloat and temp cleanup

### Rollback path

Run:

```powershell
.\REVERT-EVERYTHING.ps1
```

This restores tracked settings first, then falls back to sensible defaults where no captured state exists.

### Verification path

Run:

```powershell
.\10 verify\verify-tweaks.ps1
```

This checks the same phases exposed by the launcher and the full apply flow so you can see what is still applied, what drifted, and what was already present.

## Primary Entry Points

| Entry point | When to use it | Main risk | Undo |
| --- | --- | --- | --- |
| `launcher.ps1` | You want the guided menu | Low by itself | N/A |
| `1 backup/create-backup.ps1` | You want a restore point and registry backup first | Low | Restore point and exported registry files |
| `0 prerequisites/install-runtimes.ps1` | Games are missing VC++ or legacy DirectX runtimes | Low | Uninstall from Apps / Features |
| `2 power plan/configure-power.ps1` | You want the performance power baseline only | Low to medium | Switch back to Balanced |
| `4 services/disable-services.ps1` | You want service changes without the full stack | Medium | `4 services/revert-all.bat` or full revert |
| `5 registry tweaks/apply-all.reg` | You want the raw registry pack | Medium | `5 registry tweaks/revert-all.reg` or full revert |
| `6 gpu/install-gpu-driver.ps1` | You want the clean GPU driver path | Medium to high | DDU + reinstall / full revert for tracked settings |
| `8 security vs performance/configure-vbs.ps1` | You want the security trade-off step only | High | Re-enable via the same folder or full revert |
| `APPLY-EVERYTHING.ps1` | You want the whole stack in one run | High | `REVERT-EVERYTHING.ps1` |

## Phase Reference

### Setup

#### Backup and restore

- What it changes: creates a restore point and exports key registry areas.
- Why run it: gives you the safest rollback point before tuning.
- Main risk: restore-point creation can be throttled or unavailable by Windows policy.
- Undo: use System Restore or import the exported `.reg` files.

#### Runtime prep

- What it changes: installs Visual C++ runtimes and the legacy DirectX June 2010 redistributable.
- Why run it: fixes missing runtime dependencies for older games and launchers.
- Main risk: low; this is standard dependency installation.
- Undo: uninstall from Windows apps settings if needed.

### Optimize

#### Power plan

- What it changes: activates Ultimate Performance and tunes detailed power settings.
- Why run it: reduces power-saving latency and background throttling.
- Main risk: worse idle power usage, worse battery behavior on laptops.
- Undo: switch back to Balanced or run the full revert.

#### Services

- What it changes: disables selected background services.
- Why run it: reduces unnecessary background work on gaming-focused systems.
- Main risk: features like printing, search indexing, and telemetry-related components may stop working as expected.
- Undo: `4 services/revert-all.bat` or the full revert script.

#### Registry pack

- What it changes: latency, Game Bar, Explorer, privacy, sound, and visual-effect related registry settings.
- Why run it: applies many common Windows gaming tweaks in one place.
- Main risk: broadest surface area in the repo; some changes are preference-driven, not universally better.
- Undo: `5 registry tweaks/revert-all.reg` for the raw pack, or `REVERT-EVERYTHING.ps1` for the tracked path.

#### Timer service

- What it changes: installs a service to request lower timer resolution.
- Why run it: can reduce input latency on some systems.
- Main risk: more wakeups and power cost.
- Undo: `REVERT-EVERYTHING.ps1` removes the toolkit-managed timer service.

#### Cleanup

- What it changes: removes bundled apps and clears temp/cache folders.
- Why run it: trims non-essential software and stale files.
- Main risk: some removed apps may need manual reinstall.
- Undo: reinstall apps from Microsoft Store or winget; temp-file cleanup is not reversible.

#### Security trade-off

- What it changes: disables VBS, HVCI, and related protections.
- Why run it: removes security features that can affect latency or compatibility for aggressive tuning.
- Main risk: reduced Windows hardening.
- Undo: use the same folder scripts or `REVERT-EVERYTHING.ps1`.

### GPU and Network

#### GPU MSI mode

- What it changes: enables MSI mode for detected display devices.
- Why run it: lowers interrupt latency on supported hardware.
- Main risk: misbehaving drivers or hardware-specific instability.
- Undo: rerun the relevant GPU flow or use full revert.

#### GPU driver flow

- What it changes: stages a DDU-backed clean driver install and optional hidden vendor settings.
- Why run it: cleanest path when troubleshooting or redoing GPU drivers.
- Main risk: highest-risk path in the repo if interrupted mid-clean/install.
- Undo: use DDU again and reinstall a known-good driver.

#### Network

- What it changes: TCP settings, adapter properties, Nagle-related flags, and DNS.
- Why run it: reduces avoidable network latency on gaming systems.
- Main risk: adapter-specific compatibility differences and changed DNS behavior.
- Undo: `7 network/revert-network.bat` or `REVERT-EVERYTHING.ps1`.

### Safety and Verify

#### Apply Everything

- What it changes: runs the aggressive full stack across all phases.
- Why run it: fastest route to the maximum scripted tuning pass.
- Main risk: combines every compatibility and security trade-off in the repo.
- Undo: `REVERT-EVERYTHING.ps1`.

#### Revert Everything

- What it changes: restores manifest-backed state where available and applies default-based rollback elsewhere.
- Why run it: fastest supported return path from the full-stack flow.
- Main risk: app removals and some broad defaults still need manual follow-up.
- Undo: this is the undo path.

#### Verify

- What it changes: nothing.
- Why run it: shows whether tracked changes are applied, preexisting, unsupported, drifted, or failed.
- Main risk: none.
- Undo: not applicable.

## Repo Map

Use this map when you want to open folders directly instead of using the launcher:

- `0 prerequisites/` runtime installers
- `1 backup/` restore point and registry backup
- `2 power plan/` power and sleep behavior
- `4 services/` service toggles
- `5 registry tweaks/` raw registry packs and timer service
- `6 gpu/` MSI mode, DDU, and driver flows
- `7 network/` adapter and TCP tuning
- `8 security vs performance/` VBS / HVCI trade-off scripts
- `9 cleanup/` debloat, temp cleanup, WinUtil wrapper
- `10 verify/` state inspection and health checks
- `lib/` shared PowerShell helpers and manifest/state tracking
- `website/` guide-first landing page mirroring the repo workflow

## Troubleshooting

### The launcher or scripts say Administrator is required

Open PowerShell as Administrator, then run the script again.

### PowerShell refuses to run local scripts

Run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### A tweak applied, but Verify says it drifted

Windows, OEM utilities, enterprise policy, or driver software may have overwritten it. Use Verify to find the phase, then re-run only that area instead of the whole stack.

### A laptop behaves worse after tuning

Undo the power and GPU-focused phases first. The toolkit does not automatically downgrade itself for battery-capable systems.

### Revert finished, but the PC still feels off

Reboot first. Then run Verify. If the remaining issue is an app removal or an external tool side effect, that requires manual follow-up.
