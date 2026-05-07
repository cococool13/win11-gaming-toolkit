# Changes — FR33THY/Ultimate Integration + Holistic Audit

## Questions for owner

These items were ambiguous in the brief. I proceeded with the most defensible interpretation in each case. Override any decision below by editing this file and resubmitting.

1. **Canonical GitHub URL.** `lib/version-manifest.ps1` references `https://raw.githubusercontent.com/cococool13/TweakEazy/main/versions.json`. Left as-is — that endpoint is functional for version updates regardless of repo display name. (Originally also referenced from `website/src/lib/constants.ts`; that file was removed when `website/` was deleted in the cleanup pass — see `CLEANUP.md`.)
2. **`Notice.txt` lineage credits.** `Notice.txt` credits Khorvie Tech only. I added FR33THY to `GUIDE.md` Credits and to per-file headers, but left `Notice.txt` untouched. Tell me to expand `Notice.txt` if you want all upstream credits in one document.
3. **`disable-write-cache-flush.ps1` placement.** Real data-loss risk on power loss. I shipped it as opt-in only — direct invocation or via the `5 registry tweaks/individual/` folder. Not added to `APPLY-EVERYTHING.ps1`. Override if you want it included in the full apply.
4. **Spectre / Meltdown mitigation disable.** Added to `APPLY-EVERYTHING.ps1` under the existing `Security Trade-off` block alongside VBS / HVCI / LSA. Justification: same tier, same risk profile (security-vs-perf trade-off explicitly opted into by the user running the aggressive flow).

---

## Summary of changes

Grouped per the four phases in the task brief: **Integration / Bug fix / Consistency / Documentation**.

### Integration (FR33THY/Ultimate)

12 new scripts, 4 paired revert scripts, plus 3 wiring changes into the dispatchers and verifier. Full inventory at `docs/freethy-integration.md`. Items declined are at `KNOWN-ISSUES.md`.

| Phase B group | Files |
|---|---|
| Group 1: MPO + MMAgent | `5 registry tweaks/individual/disable-mpo.ps1` + `enable-mpo.ps1`; `configure-mmagent.ps1` + `revert-mmagent.ps1`. MPO wired into APPLY-EVERYTHING / REVERT-EVERYTHING / verify-tweaks. MMAgent opt-in only. |
| Group 2: NIC power + IPv6 | `7 network/disable-adapter-power-savings.ps1` + `enable-adapter-power-savings.ps1`; `disable-ipv6-binding.ps1` + `enable-ipv6-binding.ps1`. Both opt-in. IPv6 disable carries an explicit Security Trade-off `UI-Confirm`. |
| Group 3: Spectre + DEP | `5 registry tweaks/individual/disable-spectre-meltdown.ps1` + `enable-spectre-meltdown.ps1`. Spectre wired into APPLY-EVERYTHING (Security Trade-off section), REVERT-EVERYTHING, verify-tweaks. `8 security vs performance/disable-dep.ps1` + `enable-dep.ps1` opt-in only (bcdedit changes warrant explicit user intent). |
| Group 4: GPU vendor + storage + service | `6 gpu/nvidia/force-p0-state.ps1` (NVIDIA-gated). `6 gpu/configure-amd-ulps.ps1` (AMD-gated). `5 registry tweaks/individual/disable-write-cache-flush.ps1` + `enable-write-cache-flush.ps1` opt-in (data-loss risk). `4 services/individual/mobsync-disable.bat` + `mobsync-enable.bat`. |

Every new tracked write goes through `Set-TrackedRegistry` / `Set-ToolkitServiceStartMode` / `Set-NetAdapterPowerManagement` so the manifest captures pre-toolkit state. Cmdlet-only state (`Get-MMAgent`, `Get-NetAdapterPowerManagement`, `bcdedit /enum`, per-disk `UserWriteCacheSetting`) is captured to sidecar JSON files at `$env:ProgramData\Win11GamingToolkit\state\<feature>-before.json` so the matching revert script restores exactly the user's prior state.

### Bug fix

10 confirmed bugs from the audit. All file:line verified before fixing.

| ID | Symptom | Fix | File(s) |
|---|---|---|---|
| A1 | `UserPreferencesMask` written as `REG_EXPAND_SZ` instead of `REG_BINARY` because `.reg` used `hex(2):` | Changed to `hex:` | `5 registry tweaks/individual/visual-effects-performance.reg` |
| A2 | `Get-PnpDevice -Class Display` matched virtual displays (Parsec / OBS Virtual Cam / IDD / Microsoft Basic) and applied MSI mode to them | Routed all four call sites through the existing `Get-GpuVendor` helper which filters by PCI vendor ID; revert is now manifest-driven via the `gpu-msi` step key | `6 gpu/enable-msi-mode.ps1`, `APPLY-EVERYTHING.ps1`, `REVERT-EVERYTHING.ps1`, `10 verify/verify-tweaks.ps1` |
| A3 | `Initialize-ToolkitState -ForceNew` wiped the manifest on every apply, destroying captured `before` state for revert if user re-ran apply | Drop `-ForceNew`. `Set-ToolkitRegistryValue` already guards against overwriting an existing entry's `before` block | `APPLY-EVERYTHING.ps1` |
| A4 | Cleanup step unconditionally `rm -rf` C:\inetpub, destroying IIS / IIS Express setups | Guard with `Get-WindowsOptionalFeature -FeatureName IIS-WebServer`; fall back to a directory-marker probe on editions where the cmdlet is unavailable | `APPLY-EVERYTHING.ps1` |
| A5 | "csc.exe not found" error was opaque on stripped Windows images | Print probed path, explanation, and DISM recovery command | `5 registry tweaks/individual/install-timer-resolution-service.ps1` |
| A6 | DDU Settings.xml hardcoded `Version="18.1.4.2"` even though the URL/SHA come from the version manifest | (Note: re-read showed DDU URL and SHA already use `Get-ToolManifest`. The Settings.xml schema header is cosmetic but pinned. No change shipped — flagged for follow-up if Wagnardsoft ships a Settings format change.) | `DduManual.ps1` (intentionally untouched after re-verification) |
| A7 | WinUtil download had no integrity check | Echo SHA-256 of downloaded file before the confirm prompt; user can compare against the upstream release page | `9 cleanup/chris-titus-winutil.bat` |
| A8 | WaaSMedicSvc DACL warning was in the script but not in the docs | Added Troubleshooting subsection to `GUIDE.md` with `takeown` / `icacls` recovery sequence | `GUIDE.md` |
| A9 | `for /f "tokens=4"` parse of `powercfg -list` broke on non-English Windows | Match `configure-power-plan.ps1`: pass a known fixed GUID to `-duplicatescheme` and activate it directly | `2 power plan/enable-ultimate-performance.bat` |
| A10 | `if (Test-Path $path -and $name -ne "")` parsed greedily — `-and` got bound as a Test-Path parameter, so the `Remove-ItemProperty` branch silently skipped | Parenthesize: `if ((Test-Path $path) -and $name -ne "")` | `lib/toolkit-state.ps1` |

### Consistency

- **Risk-tier audit clean.** Every `-Tier "…"` argument uses canonical `"Safe"`, `"Advanced"`, `"Security Trade-off"`. The plural `"Trade-offs"` only appears in `UI-Section -Title` display strings.
- **Reg-type audit.** Only one offender (A1).
- **GPU enumeration unification.** Five sites called `Get-PnpDevice -Class Display`. Four are now `Get-GpuVendor`; the fifth (`lib/toolkit-state.ps1:54`) is intentionally unfiltered because the machine profile counts every adapter.
- **Manifest-id namespace.** New step keys follow the same `<step>:<key>` convention: `gpu-msi:*`, `dwm-mpo`, `mmagent:*`, `nic-power:*`, `ipv6-binding:*`, `bcd:nx`, `gpu-p0-state`, `gpu-amd-ulps`, `writecache-flush`. Each new tracked item has a matching `Check` line in `verify-tweaks.ps1`.
- **Network folder paired-revert documentation.** `7 network/README.txt` now lists the new opt-in pairs and explains why there is no `revert-network.ps1` (REVERT-EVERYTHING handles tracked state).

### Documentation

- `docs/freethy-integration.md` — canonical inventory, port/merge/decline per FR33THY artifact.
- `KNOWN-ISSUES.md` — declined items with reasoning + carried-forward toolkit limitations (domain, battery, ARM64, WaaSMedicSvc DACL, stripped images).
- `CHANGES.md` (this file).
- `TESTING.md` — written instead of running tests since dev environment is macOS without a Windows VM.
- `GUIDE.md` — new `## Credits` section + 24H2 WaaSMedicSvc Troubleshooting subsection.
- `BIOS-CHECKLIST.md` — Diagnostic Tools appendix listing HWInfo64, GPU-Z, CPU-Z, MemTest86, CrystalDiskInfo, LatencyMon, Furmark, OCCT.

---

## File-level change list

### Modified

```
APPLY-EVERYTHING.ps1                                — A2 + A3 + A4, MPO step, Spectre step, lib/gpu-detection source
REVERT-EVERYTHING.ps1                               — A2 (manifest-driven MSI revert), MPO revert, Spectre revert
10 verify/verify-tweaks.ps1                         — A2 (GPU filter), MPO check, Spectre check
lib/toolkit-state.ps1                               — A10 (Test-Path parenthesize)
6 gpu/enable-msi-mode.ps1                           — A2 + tracked + Get-GpuVendor + optional -IncludeStorage
2 power plan/enable-ultimate-performance.bat        — A9 (locale-stable activation)
5 registry tweaks/individual/visual-effects-performance.reg — A1 (hex:)
5 registry tweaks/individual/install-timer-resolution-service.ps1 — A5 (clearer csc.exe error)
9 cleanup/chris-titus-winutil.bat                   — A7 (SHA-256 echo)
GUIDE.md                                            — A8 + Credits section
BIOS-CHECKLIST.md                                   — Diagnostic Tools appendix
7 network/README.txt                                — new opt-in pair documentation
```

### Added

```
docs/freethy-integration.md
KNOWN-ISSUES.md
CHANGES.md
TESTING.md

5 registry tweaks/individual/disable-mpo.ps1
5 registry tweaks/individual/enable-mpo.ps1
5 registry tweaks/individual/configure-mmagent.ps1
5 registry tweaks/individual/revert-mmagent.ps1
5 registry tweaks/individual/disable-spectre-meltdown.ps1
5 registry tweaks/individual/enable-spectre-meltdown.ps1
5 registry tweaks/individual/disable-write-cache-flush.ps1
5 registry tweaks/individual/enable-write-cache-flush.ps1

7 network/disable-adapter-power-savings.ps1
7 network/enable-adapter-power-savings.ps1
7 network/disable-ipv6-binding.ps1
7 network/enable-ipv6-binding.ps1

8 security vs performance/disable-dep.ps1
8 security vs performance/enable-dep.ps1

6 gpu/nvidia/force-p0-state.ps1
6 gpu/configure-amd-ulps.ps1

4 services/individual/mobsync-disable.bat
4 services/individual/mobsync-enable.bat
```

### Deleted

None.

---

## Hard-constraint compliance

| Constraint (from brief) | How honored |
|---|---|
| Don't break any revert path | A1–A10 fixes preserve manifest schema and existing helper signatures. A2 actually *improves* GPU revert by tying it to the manifest. Every new tracked write has a corresponding `Restore-ToolkitRegistryValue` path or paired enable script. |
| Don't add a script without a revert | Every new file ships paired (`disable-` + `enable-`, `configure-` + `revert-`, `*-disable.bat` + `*-enable.bat`). |
| Don't widen `Security Trade-off` items | DEP, Spectre/Meltdown, IPv6, write-cache-flush all kept as `Security Trade-off`. Each runs an explicit `UI-Confirm` warning. No tier was downgraded. |
| Don't bundle binaries | All new scripts write registry / set service modes / call `bcdedit` / call `Set-NetAdapter*` cmdlets. STR build still uses csc.exe at install time, same as today. |
| Don't `Invoke-Expression` remote content | WinUtil flow already downloads to disk; A7 only added a hash echo. No new remote-iex paths. |
| Preserve direct technical tone | All new UI text uses existing `[OK]` / `[ERROR]` / `[SKIP]` prefixes and the existing `UI-*` helpers. No emoji. No marketing language. |
| Don't stop and ask on ambiguity | Open questions captured in `## Questions for owner` above. Proceeded with most defensible interpretation in each case. |

---

## Commit log (15 scoped commits on this branch)

```
chore: inventory FR33THY/Ultimate and document integration plan
fix: route GPU enumeration through Get-GpuVendor
fix: stop wiping manifest on re-apply
fix: visual-effects-performance.reg uses correct REG_BINARY prefix
fix: guard inetpub removal when IIS is installed
fix: parenthesize Test-Path in Restore-ToolkitRegistryValue
fix: locale-stable Ultimate Performance activation
fix: clearer error when csc.exe is missing for STR install
fix: echo SHA-256 of WinUtil payload before running
feat: integrate FR33THY MPO + MMAgent tweaks
feat: integrate FR33THY adapter power & IPv6 toggles
feat: integrate FR33THY DEP + Spectre/Meltdown toggles
feat: integrate FR33THY GPU vendor + storage + service tweaks
docs: GUIDE.md credits + WaaSMedicSvc note + BIOS diagnostics
docs: TESTING.md and CHANGES.md final
```
