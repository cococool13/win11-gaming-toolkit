# Cursor toolkit audit report

Audit pass run from Cursor against `.cursorrules`. Read-only — no files modified during the audit itself. Findings are captured here verbatim and cross-referenced into `KNOWN-ISSUES.md` → `## Logged for next release` for tracking.

**Summary:** Tier strings in code are clean. Many opt-in scripts follow apply/revert, admin checks, and `UI-Confirm` well. The biggest gaps are **Apply Everything bundling security trade-offs without a separate off-by-default gate**, **orphan apply scripts** (no colocated revert), **legacy service `.bat` paths that bypass `toolkit-state`**, and **unguarded raw `reg add` / `Set-ItemProperty` blocks** in `APPLY-EVERYTHING.ps1` and a few standalone scripts.

---

## 1. Apply / revert pairing — orphans

### Well-paired (representative)

| Apply | Revert |
|-------|--------|
| `disable-mpo.ps1` | `enable-mpo.ps1` |
| `disable-ntfs-last-access.ps1` | `enable-ntfs-last-access.ps1` |
| `disable-edge-background.ps1` | `enable-edge-background.ps1` |
| `disable-spectre-meltdown.ps1` | `enable-spectre-meltdown.ps1` |
| `disable-write-cache-flush.ps1` | `enable-write-cache-flush.ps1` |
| `disable-windows-update.ps1` | `enable-windows-update.ps1` |
| `configure-mmagent.ps1` | `revert-mmagent.ps1` |
| `disable-adapter-power-savings.ps1` | `enable-adapter-power-savings.ps1` |
| `disable-ipv6-binding.ps1` | `enable-ipv6-binding.ps1` |
| `disable-dep.ps1` | `enable-dep.ps1` |
| `mobsync-disable.ps1` | `mobsync-enable.ps1` |
| `optimize-network.ps1` | `7 network/revert-network.bat` |
| `apply-all.reg` | `revert-all.reg` |
| `disable-auto-restart.reg` | `revert-auto-restart.reg` |

`REVERT-EVERYTHING.ps1` also reverts manifest-tracked GPU steps (`gpu-p0-state`, `gpu-amd-ulps`, etc.) when those scripts used `Set-ToolkitRegistryValue`.

### Orphans (apply with no colocated revert script)

| Apply script / entry | Revert situation | Severity |
|---------------------|------------------|----------|
| `5 registry tweaks/individual/install-timer-resolution-service.ps1` | Uninstall only described in comments (`Stop-Service STR; sc.exe delete STR`) — no `uninstall-timer-resolution-service.ps1` | **High** |
| `9 cleanup/debloat.ps1` | Package removals logged in manifest; no reinstall/revert script | **High** |
| `6 gpu/nvidia/configure-nvidia.ps1` | No `revert-nvidia-settings.ps1`; relies on `REVERT-EVERYTHING.ps1` | **Medium** (Drift) |
| `6 gpu/amd/configure-amd.ps1` | Same | **Medium** |
| `6 gpu/intel/configure-intel.ps1` | Same | **Medium** |
| `6 gpu/enable-msi-mode.ps1` | No `disable-msi-mode.ps1` | **Medium** |
| `6 gpu/nvidia/force-p0-state.ps1` | No dedicated revert script | **Medium** |
| `6 gpu/configure-amd-ulps.ps1` | No `revert-amd-ulps.ps1` (manifest revert only) | **Medium** |
| `2 power plan/configure-power.ps1` | No `revert-power.ps1` in folder | **Medium** |
| `9 cleanup/cleanup-temp.ps1` | No revert (destructive cleanup) | **Low** (likely intentional) |
| `0 prerequisites/install-runtimes.ps1` | No revert | **Low** |
| `1 backup/create-backup.ps1` | No revert | **Low** |
| `6 gpu/install-gpu-driver.ps1` (+ `install-*.ps1`) | Installer flow; not reversible by script | **Low** |
| `9 cleanup/chris-titus-winutil.bat` | External tool; no revert | **Medium** |
| `DduManual.ps1` / `DduAuto.ps1` | Driver workflow; no paired revert | **Low** |
| `2 power plan/configure-power-plan.ps1` | Legacy duplicate of `configure-power.ps1`; no dedicated revert | **Low** (Drift) |

### `.reg` bundle (not 1:1 paired)

These individual apply `.reg` files have **no** sibling revert `.reg`; rollback is only via `5 registry tweaks/revert-all.reg` or `REVERT-EVERYTHING.ps1`:

`disable-power-throttling.reg`, `disable-game-bar-dvr.reg`, `explorer-tweaks.reg`, `game-priority.reg`, `visual-effects-performance.reg`, `disable-fullscreen-optimizations.reg`, `mouse-hover-time.reg`, `disable-startup-delay.reg`, `privacy-telemetry.reg`, `disable-fast-startup.reg`, `disable-driver-searching.reg`, `sound-scheme-none.reg`, `menu-show-delay.reg`

### Legacy service `.bat` pairs (paired but wrong architecture)

`4 services/individual/*-disable.bat` / `*-enable.bat` are paired with each other but **not** with `disable-services.ps1` manifest tracking. `4 services/revert-all.bat` resets services to **defaults**, not manifest-captured state — **Inconsistency** with `disable-services.ps1`.

---

## 2. Admin check at top — violators

Scripts using `UI-RequireAdmin` or an inline elevation check at the top: **most** mutating `.ps1` files, plus `launcher.ps1:550-556` (blocks entire menu if not admin).

### Violators (mutate registry/services; no admin check in file)

| File:line | Severity | Problem | Proposed fix |
|-----------|----------|---------|--------------|
| `6 gpu/nvidia/configure-nvidia.ps1:1` | **High** | Writes HKLM/HKCU via `Set-ToolkitRegistryValue` with no elevation check if dot-sourced or run directly | Add `UI-RequireAdmin` or inline admin gate at top (match sibling scripts) |
| `6 gpu/amd/configure-amd.ps1:1` | **High** | Same | Same |
| `6 gpu/intel/configure-intel.ps1:1` | **High** | Same | Same |

**Note:** These are safe when only called from `install-gpu-driver.ps1:39-50`, which does check admin — but `.cursorrules` requires every script to fail fast on its own.

**Convention drift (not failures):** Many scripts use inline `if (-NOT ... IsInRole ... Administrator)` instead of `UI-RequireAdmin` — acceptable per rules, but inconsistent.

**Legacy `.bat`:** `4 services/individual/diagtrack-disable.bat:4` uses `net session` (OK). Other individual service bats follow the same pattern.

---

## 3. Idempotency — unguarded registry / service / task writes

"Guarded" here means: read current state and skip/no-op when already at target, or route through helpers that preserve `before` state without blind overwrite.

### Critical / high

| File:line | Category | Severity | Problem | Proposed fix |
|-----------|----------|----------|---------|--------------|
| `APPLY-EVERYTHING.ps1:394-401` | Bug | **High** | Nagle (`TcpAckFrequency`, `TCPNoDelay`) via raw `Set-ItemProperty -Force` on every interface with DHCP IP; not tracked in manifest; `REVERT-EVERYTHING.ps1:273-278` only removes keys blindly | Use `Set-TrackedRegistry` per interface (as `7 network/optimize-network.ps1` does) |
| `APPLY-EVERYTHING.ps1:228-316` (many `Reg-Add` steps) | Drift | **High** | Large Phase 5 block uses `Reg-Add` helper without per-value state checks; not in manifest | Migrate high-risk keys to `Set-TrackedRegistry` or skip when already set |
| `APPLY-EVERYTHING.ps1:437-454` | Safety | **High** | VBS/HVCI/LSA/Spectre keys applied every run via `Set-TrackedRegistry` (good for manifest) but no "already disabled" skip | Add pre-check like `configure-vbs.ps1:92-96` |
| `5 registry tweaks/individual/disable-windows-update.ps1:35-76` | Drift | **High** | `Stop-Service` / `sc.exe config` / `Set-ItemProperty -Force` without toolkit-state; re-run always re-stops; AU policy not restored from manifest | Route through `Set-ToolkitServiceStartMode` + `Set-ToolkitRegistryValue` |
| `8 security vs performance/disable-vbs.bat:36-53` | Drift | **Medium** | `reg add` always forces values; no idempotency or manifest | Prefer `configure-vbs.ps1` or add state checks + toolkit tracking |
| `5 registry tweaks/individual/install-timer-resolution-service.ps1:128-140` | Bug | **Medium** | Always deletes/recreates `STR` service and forces `GlobalTimerResolutionRequests=1` | Check service exists and registry value already `1` before mutate |
| `4 services/individual/diagtrack-disable.bat:5-6` | Drift | **Medium** | `sc config` / `sc stop` with no "already disabled" check | Deprecate in favor of `disable-services.ps1` or add guards |
| `4 services/revert-all.bat:16+` | Inconsistency | **Medium** | Blind `sc config` to fixed defaults; ignores manifest from `disable-services.ps1` | Manifest-driven restore or document "defaults only" |

### Medium / low

| File:line | Category | Severity | Problem | Proposed fix |
|-----------|----------|----------|---------|--------------|
| `lib/toolkit-state.ps1:290-295` | Drift | **Low** | `Set-ToolkitRegistryValue` always `New-ItemProperty -Force` (no "already equals target" skip) | Optional: compare current value before write |
| `5 registry tweaks/individual/configure-mmagent.ps1:52-66` | Bug | **Medium** | `Disable-MMAgent` on re-run may fail if already disabled | Check `Get-MMAgent` flags first |
| `5 registry tweaks/individual/enable-write-cache-flush.ps1:20-41` | Bug | **Medium** | Captures `writecache-before.json` on apply but **never reads it** on revert; only manifest | On revert, fall back to sidecar JSON when manifest empty |
| `7 network/disable-adapter-power-savings.ps1:64-73` | Drift | **Low** | Re-applies power settings even if already disabled (sidecar captured once only) | Compare `Get-NetAdapterPowerManagement` before set |
| `2 power plan/configure-power-plan.ps1:76-113` | Drift | **Low** | Raw `reg add` without state checks (superseded by `configure-power.ps1` but still in tree) | Remove or redirect to `configure-power.ps1` |
| `APPLY-EVERYTHING.ps1:163` | Drift | **Low** | Power setting `Attributes` unhide via `reg add` (documented in `KNOWN-ISSUES.md`) | Accept or track if needed |

`Set-ToolkitRegistryValue` **does** guard manifest `before` capture (won't overwrite first snapshot) — good for revert, not full write idempotency.

---

## 4. Manifest tier strings

**Result: PASS** in executable tier arguments.

All `-Tier` arguments found use exactly: `Safe`, `Advanced`, `Security Trade-off`.

Display-only shortening is intentional:
- `launcher.ps1:177` → label `Trade-off` when tier is `Security Trade-off`
- `10 verify/verify-tweaks.ps1:353` → canonical footer string

**No code drift** found (`Security-tradeoff`, `Tradeoffs`, etc.).

---

## 5. HKCU vs HKLM mismatches

| File:line | Category | Severity | Problem | Proposed fix |
|-----------|----------|----------|---------|--------------|
| `5 registry tweaks/individual/privacy-telemetry.reg:47-48` | Inconsistency | **Medium** | Delivery Optimization uses `HKEY_USERS\S-1-5-20\...` (NETWORK SERVICE profile), not standard HKCU/HKLM policy paths | Confirm Win11 DO policy hive; likely move to `HKLM\SOFTWARE\Policies\...` or documented user SID |
| `6 gpu/nvidia/configure-nvidia.ps1:52-57` | Drift | **Low** | `ThreadedOptimization` under `HKCU:\...\NVTweak` while other NPI-style keys use `HKLM` | Verify against NVIDIA Profile Inspector behavior; document if intentional per-user override |
| `APPLY-EVERYTHING.ps1:344-345` | — | **Low** | Copilot disabled in **both** HKCU and HKLM policies | Intentional machine + user policy; not a bug |

Most per-user tweaks (Game DVR, FSO, Explorer) correctly use HKCU; machine policies (Edge, WU AU, DeviceGuard) use HKLM.

---

## 6. Win10-era / no-op / harmful on Win11

| File:line | Category | Severity | Problem | Proposed fix |
|-----------|----------|----------|---------|--------------|
| `5 registry tweaks/individual/install-timer-resolution-service.ps1:5-9,140` | Cargo-cult | **High** | STR + `GlobalTimerResolutionRequests` — widely debunked for gaming; Win11 24H2+ behavior differs; adds kernel timer side effects | Mark opt-in only with strong "unlikely benefit" warning; consider removing from recommended paths |
| `5 registry tweaks/individual/game-priority.reg:14` | Cargo-cult | **Medium** | `NetworkThrottlingIndex=0xffffffff` — legacy multimedia myth | Drop or document negligible benefit on Win11 |
| `APPLY-EVERYTHING.ps1:394-401`, `7 network/optimize-network.ps1` (Nagle) | Cargo-cult | **Medium** | Disabling Nagle on all DHCP interfaces can **hurt** throughput/latency on some networks | Make opt-in; scope to gaming adapter only |
| `5 registry tweaks/individual/disable-startup-delay.reg:6-7` | Cargo-cult | **Low** | `Explorer\Serialize\StartupDelayInMSec` — often ignored on Win11 (StartupApproved model changed) | Verify on 24H2; remove if no-op |
| `2 power plan/configure-power-plan.ps1` | Drift | **Low** | Duplicate/legacy power path alongside `configure-power.ps1` | Consolidate to one script |
| `6 gpu/configure-amd-ulps.ps1` + `6 gpu/amd/configure-amd.ps1:22-29` | Drift | **Low** | ULPS disabled twice (overlapping FR33THY ports) | Single code path |

Still **valid on Win11** (with caveats): MPO (`OverlayTestMode=5`), NTFS last access, fast startup off, Game DVR keys, Ultimate Performance / power throttling off, HwSchMode/HAGS.

---

## 7. Anti-cheat risk without explicit warning

`.cursorrules` requires flagging BattlEye-relevant changes (R6 Siege called out). **No file mentions BattlEye or EAC.**

| File:line | Category | Severity | Problem | Proposed fix |
|-----------|----------|----------|---------|--------------|
| `APPLY-EVERYTHING.ps1:437-454` | Safety | **Critical** | Disables HVCI, VBS, LSA, Spectre mitigations in bulk with no anti-cheat comment | Add header + `UI-Confirm` warning: HVCI/VBS changes may affect BattlEye/EAC on Win11 24H2+ |
| `8 security vs performance/configure-vbs.ps1:90-142` | Safety | **High** | Security warnings present but **no anti-cheat** note | Add comment block: test R6 Siege / BattlEye after reboot |
| `8 security vs performance/disable-vbs.bat:1-31` | Safety | **High** | Security warning only | Same anti-cheat comment |
| `5 registry tweaks/individual/install-timer-resolution-service.ps1:1` | Safety | **Medium** | Timer manipulation; some titles/AC sensitive | Warn before install |
| `5 registry tweaks/individual/disable-windows-update.ps1:1` | Safety | **Medium** | Blocks WU — anti-cheat/driver updates may stall | Note monthly manual update for AC patches |
| `6 gpu/enable-msi-mode.ps1`, `APPLY-EVERYTHING.ps1:357-367` | Safety | **Low** | MSI mode rarely triggers AC; low risk | Optional one-line note |

No wholesale Defender disable found (exclusions only in `APPLY-EVERYTHING.ps1:518`).

---

## 8. Security posture vs off-by-default toggle

| File:line | Category | Severity | Problem | Proposed fix |
|-----------|----------|----------|---------|--------------|
| `APPLY-EVERYTHING.ps1:412-454` | Safety | **Critical** | Phases 9–10 (WU suppression + VBS/HVCI/LSA/Spectre) run inside **Apply All** after a single global confirm — not behind separate default-off toggles | Add `-IncludeSecurityTradeoffs` switch defaulting to `$false`, or split quick action |
| `8 security vs performance/configure-vbs.ps1:15-17,90` | Safety | **High** | Default invocation (no `-Enable`) **disables** VBS/HVCI; opt-in is "run script" not "pass -Disable" | Require `-Disable` / `-ConfirmDisable`; default should no-op or only report state |
| `8 security vs performance/disable-vbs.bat` | Safety | **Medium** | Named "disable"; has pauses but no structured toggle | OK as explicit opt-in; align with `configure-vbs.ps1` |
| `5 registry tweaks/individual/disable-spectre-meltdown.ps1:28` | — | **Low** | Has `UI-Confirm` | Good pattern |
| `8 security vs performance/disable-dep.ps1:27` | — | **Low** | Has `UI-Confirm` | Good pattern |
| `7 network/disable-ipv6-binding.ps1:27` | — | **Low** | Has `UI-Confirm` | Good pattern |

**Not in `APPLY-EVERYTHING.ps1` (correctly opt-in only):** MMAgent, IPv6 binding, DEP (`bcdedit`), write-cache flush, NIC power savings.

---

## Prioritized findings (master list)

Sorted by severity, then category.

### Critical

1. **`APPLY-EVERYTHING.ps1:437-454`** — Safety — Security trade-offs (VBS/HVCI/LSA/Spectre) bundled in Apply All without separate default-off gate; no anti-cheat warning. **Fix:** `-IncludeSecurityTradeoffs:$false` by default + BattlEye/EAC comment block.
2. **`APPLY-EVERYTHING.ps1:437-454`** — Safety — Same block: violates "security posture behind explicit default-off toggle" when using `[A] Apply All`.

### High

3. **`5 registry tweaks/individual/install-timer-resolution-service.ps1`** — Drift — No paired uninstall/revert script. **Fix:** Add `uninstall-timer-resolution-service.ps1`.
4. **`9 cleanup/debloat.ps1`** — Drift — No revert script for removed packages. **Fix:** Document manual Store reinstall or export package list for restore.
5. **`APPLY-EVERYTHING.ps1:394-401`** — Bug — Untracked Nagle writes; incomplete revert. **Fix:** `Set-TrackedRegistry` (see `KNOWN-ISSUES.md:103-105`).
6. **`6 gpu/nvidia/configure-nvidia.ps1:1`**, **`configure-amd.ps1:1`**, **`configure-intel.ps1:1`** — Bug — No admin check if run standalone.
7. **`8 security vs performance/configure-vbs.ps1:90`** — Safety — Default path disables security; should be explicit `-Disable` switch.
8. **`4 services/revert-all.bat` vs `disable-services.ps1`** — Inconsistency — Revert ignores manifest. **Fix:** Use `Restore-ToolkitServiceStartMode` or deprecate bat.

### Medium

9. **`5 registry tweaks/individual/disable-windows-update.ps1`** — Drift — Raw service/registry ops, not toolkit-state.
10. **`5 registry tweaks/individual/privacy-telemetry.reg:47`** — Inconsistency — `HKEY_USERS\S-1-5-20` for Delivery Optimization.
11. **`5 registry tweaks/individual/install-timer-resolution-service.ps1`** — Cargo-cult — Timer resolution service of dubious Win11 benefit.
12. **`5 registry tweaks/individual/game-priority.reg:14`** — Cargo-cult — `NetworkThrottlingIndex` myth.
13. **`APPLY-EVERYTHING.ps1:228+` Phase 5 `Reg-Add` mass** — Drift — Weak idempotency and manifest coverage.
14. **GPU scripts without colocated revert** (`force-p0-state`, `enable-msi-mode`, `configure-amd-ulps`, `configure-*-settings`) — Drift — Rely on full revert only.
15. **`5 registry tweaks/individual/enable-write-cache-flush.ps1`** — Bug — Ignores `writecache-before.json` sidecar.
16. **Anti-cheat warnings missing** on VBS/HVCI/timer/WU scripts (see §7).

### Low

17. **`2 power plan/configure-power-plan.ps1`** — Drift — Legacy duplicate.
18. **`lib/toolkit-state.ps1:294`** — Drift — Always `-Force` registry write.
19. **Individual `.reg` files** — Drift — No 1:1 revert; only `revert-all.reg`.
20. **Legacy `4 services/individual/*.bat`** — Drift — Bypass `toolkit-state.ps1`.
21. **`5 registry tweaks/individual/enable-spectre-meltdown.ps1`** — Bug — No `Initialize-ToolkitState` (works via remove fallback only).

---

## What looks solid

- Canonical tier strings in all `-Tier` arguments.
- Strong opt-in scripts: `disable-dep.ps1`, `disable-spectre-meltdown.ps1`, `disable-ipv6-binding.ps1`, `disable-write-cache-flush.ps1` (confirm + paired revert).
- `lib/gpu-detection.ps1:19-24` — `-PresentOnly`, `Status -eq "OK"`, vendor ID filter (CODEX item 1 appears fixed).
- `lib/toolkit-state.ps1` DNS — IPv4/IPv6 keyed separately (CODEX item 5 appears fixed).
- `9 cleanup/chris-titus-winutil.bat:62-71` — SHA-256 verify before run.
- `REVERT-EVERYTHING.ps1:229-235` — Includes `gpu-p0-state` and `gpu-amd-ulps` in GPU revert loop.

---

## Suggested triage order

1. **Apply All security gating** + anti-cheat comments on VBS/HVCI paths.
2. **Nagle tracking** in `APPLY-EVERYTHING.ps1`.
3. **Admin checks** on GPU configure scripts.
4. **Orphans:** timer-resolution uninstall script, debloat revert story, `revert-all.bat` vs manifest.
5. **Cargo-cult review:** timer service, `NetworkThrottlingIndex`, Nagle defaults.
