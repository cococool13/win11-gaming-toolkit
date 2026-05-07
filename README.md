# Win11 Gaming Toolkit

PowerShell-based system-tuning toolkit for Windows 11 gaming machines. Manifest-tracked, reversible, no bundled binaries.

## Quick start

1. Clone or download this repo to a local folder. Right-click PowerShell → **Run as Administrator**.
2. From an admin PowerShell, run:
   ```powershell
   cd "<path-to-repo>"
   .\launcher.ps1
   ```
3. From the launcher: `[V]` to verify current state, `[A]` to apply the full stack, `[R]` to revert. `[?]` shows the full keybinding list.

The launcher refuses to start without administrator rights and exits cleanly. Read [GUIDE.md](GUIDE.md) before running `[A] Apply All` for the first time.

## Risk tiers

Every tweak in the toolkit declares one of three tiers. The launcher color-codes them:

- **Safe** (green) — tweaks that change defaults but do not weaken security or trade off behavior. Backups, prerequisite installs, network defaults, verification.
- **Advanced** (yellow) — tweaks with measurable performance benefit but real trade-offs. Disabled services, registry-level UI changes, GPU MSI mode, debloat. Reversible via `[R]` Revert All.
- **Security Trade-off** (displayed as `Trade-off`, red) — tweaks that disable a real security mitigation in exchange for performance: VBS / HVCI / LSA-PPL, Spectre / Meltdown CPU mitigations, DEP. Opt-in, reversible. Read each script's header before running.

Every Advanced and Trade-off tweak captures the original registry / service state before writing. `REVERT-EVERYTHING.ps1` reads the manifest at `%ProgramData%\Win11GamingToolkit\state\manifest.json` and restores the captured pre-toolkit state.

## Documentation

- [GUIDE.md](GUIDE.md) — full operating instructions, repo map, troubleshooting (including the Windows 24H2 / 25H2 WaaSMedicSvc recovery sequence).
- [BIOS-CHECKLIST.md](BIOS-CHECKLIST.md) — hardware-side tuning the toolkit cannot script (BIOS settings, diagnostic tool downloads).
- [CHANGELOG.md](CHANGELOG.md) — release notes per version.
- [KNOWN-ISSUES.md](KNOWN-ISSUES.md) — items considered but not shipped, plus shipped limitations (domain join, battery laptops, ARM64, stripped images).
- [MANUAL-TEST-CHECKLIST.md](MANUAL-TEST-CHECKLIST.md) — runtime test gate run by the maintainer on a Win11 VM before promoting any tag.
- [CHANGES.md](CHANGES.md), [CODEX-AUDIT.md](CODEX-AUDIT.md), [CLEANUP.md](CLEANUP.md), [PRODUCTION-READY.md](PRODUCTION-READY.md) — historical audit record per pass; preserved for traceability. `CHANGELOG.md` is the user-facing summary.
- [docs/freethy-integration.md](docs/freethy-integration.md) — port / merge / decline matrix per upstream FR33THY artifact.

## Credits

- **FR33THY** — <https://github.com/FR33THYFR33THY/Ultimate>. Source for MPO disable, MMAgent tuning, NIC power savings, IPv6 unbind, Spectre / Meltdown override, DEP toggle, NVIDIA P0 state, AMD ULPS disable, Offline Files / Sync Center disable. Per-file source attribution in script headers.
- **Khorvie Tech** — original toolkit lineage. Lineage credit retained in `Notice.txt`.
- **Chris Titus Tech** — <https://github.com/ChrisTitusTech/winutil>. Wrapped (with SHA-256 verification) by `9 cleanup\chris-titus-winutil.bat`.
- **Wagnardsoft** — Display Driver Uninstaller (DDU). Wrapped (with SHA-256 verification) by `DduManual.ps1` / `DduAuto.ps1`.

## License

MIT — see [LICENSE](LICENSE). Third-party tools the toolkit downloads remain under their respective licenses.

## Versioning

The current version is in [VERSION](VERSION). The launcher reads it at runtime. Tags follow [Semantic Versioning](https://semver.org/).
