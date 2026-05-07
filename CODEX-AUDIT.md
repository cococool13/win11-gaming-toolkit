# Codex Audit

Audit target: `CC/hardcore-rubin-7d2584`
Base checked: `cd8182156655810b72437464d8d7a6cbe4f67d7f`
Audit date: 2026-05-07

## Discrepancies

1. `CHANGES.md` says the GPU MSI filter now uses active NVIDIA / AMD / Intel devices only, but `lib/gpu-detection.ps1` uses `Get-PnpDevice -Class Display` without `-PresentOnly` and accepts every status except `Error`. The requested filter was `VEN_10DE|VEN_1002|VEN_8086`, `Status -eq "OK"`, and `-PresentOnly`.
2. `docs/freethy-integration.md` lists target files that do not exist: `6 gpu/enable-msi-priority.ps1`, `5 registry tweaks/individual/disable-mpo.reg`, and `5 registry tweaks/individual/hardware-flip.reg`.
3. Several FR33THY additions are not mentioned by `APPLY-EVERYTHING.ps1`, `REVERT-EVERYTHING.ps1`, or `10 verify/verify-tweaks.ps1`: MMAgent, adapter power savings, IPv6 binding, DEP, write-cache flush, NVIDIA P0 state, AMD ULPS, and MobSync.
4. `6 gpu/nvidia/force-p0-state.ps1` and `6 gpu/configure-amd-ulps.ps1` tell users `REVERT-EVERYTHING.ps1` will restore their registry changes, but Revert only scans `gpu-nvidia-settings`, `gpu-amd-settings`, and `gpu-intel-settings`. The `gpu-p0-state` and `gpu-amd-ulps` steps are left behind.
5. The P0 and ULPS scripts call `Set-ToolkitRegistryValue` but do not record an applied step result on success, so Verify cannot distinguish toolkit-applied state from preexisting state.
6. `4 services/individual/mobsync-disable.bat` uses raw `sc config MobSync` / `sc stop MobSync`. This is not routed through toolkit-state helpers and targets a service-style name that is not the documented Offline Files service (`CscService`).
7. `9 cleanup/chris-titus-winutil.bat` downloads from the mutable `latest` URL and prints a SHA256, but does not compare it to an expected hash before execution. That violates the runtime download rule: download, verify SHA256, then execute from disk.
8. `Initialize-ToolkitState -ForceNew` remains destructive if any caller uses it: the function still creates a new manifest even when one already exists. Claude fixed the current Apply call site, not the helper semantics.
9. `5 registry tweaks/individual/install-timer-resolution-service.ps1` has a useful `csc.exe` precheck, but the recovery text suggests `DISM /FeatureName:NetFx4`, which is not a reliable Windows 10/11 recovery path for the .NET Framework 4.x compiler.
10. `DduManual.ps1` still hardcodes `<DisplayDriverUninstaller Version="18.1.4.2">` inside generated settings XML without tying that value to the manifest version or documenting why it is intentionally fixed.
11. `docs/freethy-integration.md` claims FR33THY ports are tracked via `lib/toolkit-state.ps1`, but network adapter power, IPv6 binding, DEP/BCD, and MobSync use sidecar files or raw commands rather than toolkit-state helpers.

## Independent Findings

1. `APPLY-EVERYTHING.ps1` and `REVERT-EVERYTHING.ps1` still contain many raw mutable operations (`reg add`, `reg delete`, `netsh`, `Set-NetAdapterAdvancedProperty`, `Stop-Service`, package removal, and hardcoded revert defaults). Some are older baseline behavior, but they weaken the repo invariant that revertible state should go through toolkit-state helpers.
2. `5 registry tweaks/apply-all.reg` does not include `UserPreferencesMask`, while the individual `visual-effects-performance.reg` file does. This is not a type bug, but it means the all-reg bundle and individual file do not apply identical visual-effects state.
3. Several mutating paths use `-ErrorAction SilentlyContinue` on operations that can fail in ways users should see, especially service installation/removal and network adapter mutation. Existing helper-routed paths are better because they throw or record status.
4. The discovery sweep found no existing coverage for Chromium Edge background/startup policies, NTFS last-access metadata, Windows CEIP / Compatibility Appraiser scheduled tasks, audio MMCSS task tuning, keyboard/mouse class queue sizes, or NVIDIA Profile Inspector automation.
5. DNS state capture in `lib/toolkit-state.ps1` keys snapshots only by `InterfaceIndex`, so IPv4 and IPv6 entries for the same adapter overwrite each other. The same helper also verifies the mixed Cloudflare IPv4+IPv6 list from `APPLY-EVERYTHING.ps1` against IPv4 only, which marks the DNS step as skipped even when the apply path succeeds. Revert then cannot reliably restore both address families.
6. PowerShell runtime validation could not be run in this macOS environment because `pwsh` is not installed.

## Verified Clean

1. There are no git tags, so `main...CC/hardcore-rubin-7d2584` is the correct comparison range for Claude's diff.
2. `visual-effects-performance.reg` uses `hex:` for `UserPreferencesMask`, which is correct for `REG_BINARY`.
3. `APPLY-EVERYTHING.ps1` no longer calls `Initialize-ToolkitState -ForceNew`, so current re-apply does not wipe the manifest through that path.
4. `APPLY-EVERYTHING.ps1` gates `C:\inetpub` cleanup on IIS optional-feature state or a toolkit-created marker.
5. `2 power plan/enable-ultimate-performance.bat` uses a fixed GUID and `powercfg -setactive`, avoiding locale-dependent text parsing.
6. Launcher menu file targets resolve to files that exist in the branch.
7. Actual `-Tier` arguments found in scripts use the canonical strings: `Safe`, `Advanced`, and `Security Trade-off`.
8. The repo contains no bundled external binaries and no `Invoke-Expression` against remote content in the audited branch.
