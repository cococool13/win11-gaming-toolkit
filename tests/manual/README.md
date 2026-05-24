# tests/manual/ — Windows-only verifier checklists

This directory holds **human-runner checklists** for behaviors that
can't be Pester'd statically on the macOS dev environment.

## Why these exist

Pester suites under `tests/*.Tests.ps1` are AST/text-scan only — they
catch surface regressions (param shape, function presence, gate
plumbing) on any platform. They cannot prove that:

- `Set-ItemProperty` actually wrote the registry value
- `sc.exe config` actually flipped the service start mode
- `Remove-AppxPackage` actually removed the package
- `Windows Sandbox` (`.wsb`) actually launched and ran the script

Those require a Windows runtime. The toolkit's design env is macOS
(see `CLAUDE.md` → "Dev environment vs. runtime") so static + manual
is the gate, not "macOS + Windows CI = good enough."

## How to use

1. Pick the file matching the script you changed (e.g. `APPLY-EVERYTHING.md`).
2. Boot Windows 11 in a VM (Hyper-V, VMware, Parallels) or use a
   dedicated test machine. **Do not run on your main install.**
3. Walk the numbered checklist, ticking off each row.
4. Any FAIL row: open an issue, link the SHA you tested, note the
   step. Don't try to "fix forward" by re-running with different args.

## Sandbox configs

`tests/sandbox/*.wsb` are pre-baked Windows Sandbox configs that
mount the repo, install PowerShell 7, and run a target script in
fresh-VM isolation. Document for each: what state the sandbox VM
should reach if the script works, what an obvious failure looks like.

Sandbox isn't a Pester substitute — Sandbox sessions tear down on
exit so there's no manifest to inspect afterward. Use it for "does
this run without throwing" smoke checks, not for revert validation.
