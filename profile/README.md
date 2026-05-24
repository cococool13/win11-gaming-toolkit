# Win11 Gaming Toolkit — dev profile

PowerShell profile that loads toolkit-aware helpers on every session.
For **developers** working on this toolkit, not for end-users running it.

End-users only ever invoke `launcher.ps1`; nothing in this folder is
required to run any tweak script.

## Install

```powershell
pwsh -File profile/Install-Profile.ps1
```

This appends an idempotent dot-source line to
`$PROFILE.CurrentUserAllHosts` (which covers both Windows PowerShell 5.1
and PowerShell 7+). Existing content is backed up to `<profile>.bak.<ts>`
before any modification. Re-running prints "already installed" and exits.

The `-WhatIf` flag is fully supported — preview the change without writing.

Uninstall: open `$PROFILE.CurrentUserAllHosts`, delete the lines between
`# === Win11 Gaming Toolkit dev profile ===` markers.

## What you get

| Function | Purpose |
|---|---|
| `Get-ToolkitLog` | Tail / open the most recent script log under `%ProgramData%\Win11GamingToolkit\logs` |
| `Get-ToolkitManifest` | Load `manifest.json` as a PSObject for inspection |
| `Test-ToolkitInvariants` | Walk the repo and assert CLAUDE.md invariants |
| `Show-ToolkitMenu` | Colored cheat-sheet of common dev commands |

Plus baseline PSReadLine tuning (ListView prediction, history search on
arrow keys, MenuComplete on Tab). Only applied if PSReadLine ≥ 2.2 is
available (always true on PowerShell 7+).

## Add your own modules

Drop any `.ps1` into `profile/parts/`. The main profile dot-sources every
`.ps1` in that directory alphabetically on session start. Good for:

- Per-project aliases
- `prompt {}` function override
- Module imports you want toolkit-wide
- Custom completers

`parts/` files run inside the PowerShell session — same scope and same
permissions as anything else you type interactively.

## Why a layered profile?

The toolkit's `lib/` is for **runtime** scripts (`launcher.ps1` etc.).
The `profile/` is for the **user's shell session**. Keeping them
separate means:

- End-users never load dev cruft when running `launcher.ps1` (the
  scripts dot-source `lib/`, not `profile/`).
- Developers get session-time helpers (`Show-ToolkitMenu`, `Get-ToolkitLog`)
  that would clutter the runtime scripts.
- The CI gate (`tools/Invoke-ToolkitGate.ps1`) runs the same way for
  everyone regardless of personal profile state.

## Phase B status

This is the starter cut. Items still queued per the continuous-improvement
loop's Phase B:

- `posh-git`, `Terminal-Icons`, `PSFzf`, `zoxide`, `CompletionPredictor`
  pinned via `PSResourceGet`
- Oh My Posh or Starship prompt (decision deferred — both are valid)
- `profile/windows-terminal/settings.json` with toolkit color scheme +
  elevated/non-elevated `pwsh` profiles
