# Changelog

All notable changes to this toolkit are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The audit history is preserved in `CHANGES.md`, `CODEX-AUDIT.md`, and `CLEANUP.md`; this file is the user-facing roll-up.

## [1.0.0] — 2026-05-07

First public release. The toolkit went through three predecessor passes (FR33THY integration + bug audit, codex verification + discovery, cleanup + launcher redesign) and a final production-readiness audit before this tag.

### Added
- Manifest-aware launcher (`launcher.ps1`) with header status (`Admin: yes/no`, `Build: <number>`, `Manifest: <N> entries`), per-category risk-tier coloring (`Safe` green, `Advanced` yellow, `Trade-off` red), and per-category status indicators (`[OK] applied` / `! drift`). ASCII fallback engages automatically in PowerShell ISE or terminals narrower than 80 columns.
- Twelve FR33THY/Ultimate-derived tweak scripts with paired reverts: `disable-mpo.ps1` / `enable-mpo.ps1`, `configure-mmagent.ps1` / `revert-mmagent.ps1`, `disable-adapter-power-savings.ps1` / `enable-adapter-power-savings.ps1`, `disable-ipv6-binding.ps1` / `enable-ipv6-binding.ps1`, `disable-spectre-meltdown.ps1` / `enable-spectre-meltdown.ps1`, `disable-dep.ps1` / `enable-dep.ps1`, `force-p0-state.ps1` (NVIDIA-gated), `configure-amd-ulps.ps1` (AMD-gated), `disable-write-cache-flush.ps1` / `enable-write-cache-flush.ps1` (opt-in due to data-loss risk), `disable-edge-background.ps1` / `enable-edge-background.ps1`, `disable-ntfs-last-access.ps1` / `enable-ntfs-last-access.ps1`, `mobsync-disable.ps1` / `mobsync-enable.ps1`. See `docs/freethy-integration.md` for the full inventory.
- Single-source-of-truth `VERSION` file at repo root; `lib/toolkit-state.ps1` reads it; `launcher.ps1` header pulls from `$script:ToolkitVersion`.
- Quick actions in launcher: `[A]` Apply All, `[V]` Verify status, `[R]` Revert All — each dispatches directly to the existing top-level scripts.
- Tools menu: `[M]` View manifest, `[L]` View recent log (under `%ProgramData%\Win11GamingToolkit\logs`), `[B]` Regenerate baseline (after typed `YES` confirm), `[?]` Help.
- Shared `Get-ToolkitLogRoot` helper in `lib/toolkit-state.ps1` for log-tail lookups.
- `MANUAL-TEST-CHECKLIST.md` — sixteen-section runtime gate the owner runs on Win11 before promoting the tag publicly.
- `PRODUCTION-READY.md` documenting the audit pass-fail matrix and accepted deviations.
- `BIOS-CHECKLIST.md` Diagnostic Tools appendix listing HWInfo64, GPU-Z, CPU-Z, MemTest86, CrystalDiskInfo, LatencyMon, Furmark, OCCT.

### Changed
- Launcher menu structure: from a single flat letter-keyed list to a tiered three-section layout (Quick actions / Categories / Tools) with category submenus per numbered folder.
- `APPLY-EVERYTHING.ps1` no longer calls `Initialize-ToolkitState -ForceNew`, preserving captured `before` state across re-applies. (Codex audit fix A3.)
- GPU MSI mode now targets only real graphics adapters (`VEN_10DE` NVIDIA, `VEN_1002` AMD, `VEN_8086` Intel) via `Get-GpuVendor`; virtual displays (Microsoft Basic Display, IDD, OBS Virtual Cam, Parsec) are excluded. Revert is manifest-driven via the `gpu-msi` step key. (Codex audit fix A2.)
- `enable-ultimate-performance.bat` activates the Ultimate Performance plan via fixed GUID + `powercfg -duplicatescheme`, removing the locale-dependent `for /f "tokens=4"` parse of `powercfg -list` output. (Codex audit fix A9.)
- DDU + WinUtil downloads compute SHA-256 against an expected hash in `versions.json` / a constant in the wrapper script, and refuse to execute on mismatch. (Audit fixes A6 + A7.)
- DNS state capture now keys on both `InterfaceIndex` and `AddressFamily`, so IPv4 and IPv6 entries for the same adapter are tracked separately. Revert restores both families.
- `verify-tweaks.ps1` footer uses canonical `Security Trade-off` (capitalized, hyphenated) instead of `Security-tradeoff`. Brought into line with the launcher's display-label convention.

### Fixed
- **A1**: `visual-effects-performance.reg` writes `UserPreferencesMask` as `REG_BINARY` (`hex:`), not `REG_EXPAND_SZ` (`hex(2):`).
- **A4**: `APPLY-EVERYTHING.ps1` cleanup phase guards the `C:\inetpub` removal with `Get-WindowsOptionalFeature -FeatureName IIS-WebServer`, so IIS / IIS Express setups are not destroyed.
- **A5**: `install-timer-resolution-service.ps1` prints the probed `csc.exe` path and a clear DISM recovery hint when the .NET Framework 4 compiler is missing on stripped images.
- **A8**: WaaSMedicSvc DACL recovery sequence (`takeown` + `icacls`) is documented in `GUIDE.md` Troubleshooting for Windows 24H2 / 25H2.
- **A10**: `Restore-ToolkitRegistryValue` parenthesizes `Test-Path` so its `-and` clause is not bound as a `Test-Path` parameter.
- Manifest preservation across re-runs: `Set-ToolkitRegistryValue` guards against overwriting an existing entry's `before` block.
- Phase 1 cleanup integrity: dropped the stale `.claude/launch.json` VS Code debug config that referenced the removed `website/` directory.

### Removed
- The entire `website/` Next.js landing site (30 tracked files, ~11.5k lines). The toolkit is the only deliverable.
- `lib/launcher-menu.ps1` (orphaned by the launcher rewrite — the new launcher embeds menu definitions inline).
- Build-tooling entries from `.gitignore` that referenced `website/.next/`, `website/out/`, `node_modules/`, and `firebase-debug.log`.
- Branches: `codex/audit-extend-win11-toolkit` (merged), `CC/hardcore-rubin-7d2584` (subset of codex), `claude/implement-todo-item-9uEXR` (website-only commit), `claude/add-claude-documentation-zxdYP` (orphan CLAUDE.md).

### Documented for next release (non-blocker, see `KNOWN-ISSUES.md`)
- `APPLY-EVERYTHING.ps1` Nagle write at lines 399–400 bypasses `Set-ToolkitRegistryValue`. The standalone `7 network/optimize-network.ps1` uses the helper. Convert APPLY's block in v1.1 so REVERT can restore Nagle defaults.
- Startup-cleanup `reg delete` calls (OneDrive / Teams autostart) are intentional vendor-default policy applies. Revert depends on the user re-launching the affected app.
- Power-Plan `Attributes` write at line 163 unhides a hidden setting (metadata, not behavior). No tier tag needed.
- Notice.txt scope: lineage credit only (Khorvie Tech). Broader credits are in `GUIDE.md`. Owner decision in `CHANGES.md` Q2.

### Design deviation
- The launcher omits a `[3] Privacy / telemetry` category. The repo's numbered-folder layout has no `3 privacy/`; privacy tweaks (`privacy-telemetry.reg`, `disable-edge-background.ps1`, `disable-windows-update.ps1`) live in `5 registry tweaks/individual/` and are reachable via `[5]` Registry tweaks → submenu. Documented in `CLEANUP.md`.

[1.0.0]: https://github.com/cococool13/TweakEazy/releases/tag/v1.0.0
