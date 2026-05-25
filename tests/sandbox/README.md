# tests/sandbox/ — Windows Sandbox configs

Pre-baked `.wsb` configuration files for running toolkit scripts in a
**throwaway Windows Sandbox VM**. Sandbox state is discarded on close,
so every run starts from a fresh Windows install — perfect for proving
"this doesn't break the OS" without risking your real machine.

## Prerequisites (on the host machine)

1. Windows 11 Pro / Enterprise / Education. **Home does NOT include
   Windows Sandbox.**
2. Sandbox feature enabled:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM' -All
   ```
   Reboot after.
3. ≥ 4 GB RAM free, ≥ 1 GB disk free, hardware virtualization enabled
   in BIOS (Intel VT-x / AMD-V).

## How to use

1. Open a `.wsb` file from this directory (double-click, or
   `start tests\sandbox\apply-everything-default.wsb`).
2. Windows Sandbox boots a fresh Windows 11 VM (~30 seconds).
3. The mapped folder appears at `C:\repo` inside the VM.
4. The `LogonCommand` in each `.wsb` runs the target script
   automatically — you don't have to do anything inside the VM
   to kick it off.
5. Observe the script's console output. The toolkit log is at
   `C:\ProgramData\Win11GamingToolkit\logs\` inside the VM.
6. When done, **close the Sandbox window**. All VM state is destroyed.

## Available configs

| File | Target script | Args | Tier | What it proves |
|---|---|---|---|---|
| `apply-everything-default.wsb` | `APPLY-EVERYTHING.ps1` | (none) | Safe + Advanced | Default run completes; Phase 9/10 SKIP per CURSOR-AUDIT #1 gate |
| `apply-everything-tradeoffs.wsb` | `APPLY-EVERYTHING.ps1` | `-IncludeSecurityTradeoffs` | + Security Trade-off | Full stack including VBS/HVCI/LSA/Spectre. Anti-cheat warning surfaces. |
| `apply-everything-whatif.wsb` | `APPLY-EVERYTHING.ps1` | `-WhatIf` | dry-run | No actual writes; `What if:` prints for every Set-Tracked* call. |
| `debloat.wsb` | `9 cleanup/debloat.ps1` | (none) | Safe | UWP package removal happy-path. Verify protected apps survive. |
| `revert-everything.wsb` | `REVERT-EVERYTHING.ps1` | (none) | restores defaults | Idempotent revert from a manifest-less state. |
| `check-storage.wsb` | `11 hardware checks/check-storage.ps1` | (none) | Safe (read-only) | TRIM verification + media report on virtual disk. |

## What Sandbox does NOT prove

- **Reboot-required tweaks**: VBS/HVCI changes need a reboot to take
  effect. Sandbox tears down on close so you can never reboot it. Use
  `tests/manual/*.md` checklists on a snapshot-capable VM for those.
- **Anti-cheat compatibility**: BattlEye/EAC don't run in Sandbox.
  Real-world game testing requires a real install.
- **Driver state**: Sandbox uses synthetic display/network/storage
  drivers. GPU MSI mode, ReBAR, NIC RSS, etc. have no observable
  effect inside Sandbox.
- **Manifest persistence**: The manifest at
  `C:\ProgramData\Win11GamingToolkit\state\manifest.json` is wiped
  with the VM. Use Sandbox to test "the apply path runs"; use the
  manual checklist on a snapshotted VM to test "the manifest captured
  the right thing."

## How the .wsb files are structured

Common shape:

```xml
<Configuration>
  <VGpu>Disable</VGpu>            <!-- consistent perf, no driver weirdness -->
  <Networking>Default</Networking><!-- needed for download-helpers tests -->
  <MappedFolders>
    <MappedFolder>
      <HostFolder>%REPO%</HostFolder>
      <SandboxFolder>C:\repo</SandboxFolder>
      <ReadOnly>true</ReadOnly>   <!-- prevents the VM polluting the host repo -->
    </MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <Command>...launch target script in a console window...</Command>
  </LogonCommand>
</Configuration>
```

`%REPO%` is a placeholder you must substitute when launching — see
"How to use" above for the recommended invocation pattern that does
the substitution inline. **The .wsb files in this folder hardcode
`%REPO%`; you can't just double-click them — you must invoke them
through `Start-SandboxSession` (a tiny wrapper in `tools/`).**

## Cross-platform note

These .wsb files are XML and were authored on macOS. They have not
been runtime-tested — see `CLAUDE.md` → dev env / runtime split.
Any structural changes that move folders the LogonCommand references
will silently break sandbox runs until someone on a Windows host
catches it. Add `tests/manual/sandbox.md` rows when adding new .wsb
files so the human verifier can confirm they still launch.
