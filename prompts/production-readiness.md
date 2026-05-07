# Production Readiness Pass

You are doing the final pass on this toolkit. Three predecessor agents have run before you:

1. **Claude — FR33THY integration + bug audit.** Output: `CHANGES.md`, `KNOWN-ISSUES.md`, `docs/freethy-integration.md`.
2. **Codex — verification + discovery.** Output: `CODEX-AUDIT.md`, `DISCOVERY-BACKLOG.md`. Branch: `codex/audit-extend-win11-toolkit` (26 commits) merged to main.
3. **Claude — cleanup + launcher redesign.** Output: `CLEANUP.md`, new `launcher.ps1` (562 lines), `website/` removed, branches consolidated.

Current state:
- `main` is the only active branch.
- Safety branches `CC/salvage-pre-cleanup` and `CC/sleepy-hellman-f4b52f` exist on origin pending this verification.
- Tracked files: 124.
- `launcher.ps1` syntax-validated via PS7 `[Parser]::ParseInput()` on macOS but **unverified at Windows runtime**.
- New script-scoped variable `$script:ToolkitLogRoot` added to `lib/toolkit-state.ps1`.
- Documented design deviation: no `3 privacy/` top-level folder; privacy tweaks live in `5 registry tweaks/`.

Your job: take this from "feature-complete" to "production-ready, no mistakes." Verify every claim from the three predecessor reports holds. Hunt regressions from the cleanup. Validate runtime (or queue a precise manual test). Cut a release.

**Do not introduce new features.** Polish and verify only. If you find something tempting to add, log it in `KNOWN-ISSUES.md` for the next release.

## Definition of done

- Tagged release pushed to origin.
- `PRODUCTION-READY.md` documents every Phase 1 check with pass/fail evidence.
- Either `TEST-REPORT.md` (ran Windows test) or `MANUAL-TEST-CHECKLIST.md` (queued for owner) exists at repo root.
- `CHANGELOG.md`, `README.md`, version file present and accurate.
- Safety branches retired (only if everything is clean).
- Zero blockers open.

## Phase 0 — Ground

1. Read in full: `CHANGES.md`, `CODEX-AUDIT.md`, `DISCOVERY-BACKLOG.md`, `CLEANUP.md`, `KNOWN-ISSUES.md`, `GUIDE.md`, `BIOS-CHECKLIST.md`, `prompts/README.md`.
2. Read end-to-end: `lib/toolkit-state.ps1`, `APPLY-EVERYTHING.ps1`, `REVERT-EVERYTHING.ps1`, `10 verify/verify-tweaks.ps1`, `launcher.ps1`.
3. Output current commit hash, tracked file count, and active branch before doing anything else.

## Phase 1 — Verify cleanup integrity

The previous pass merged 26 commits and rewrote a 562-line launcher. Confirm nothing leaked.

1. **Merge sanity**:
   ```bash
   git log --oneline main~30..main
   ```
   Read every commit message. Flag forced merges, partial reverts, or "wip" commits in `## Merge audit` of your output.

2. **Orphan deletion check** (`lib/launcher-menu.ps1` was deleted as orphan):
   ```bash
   git log --all --oneline -- lib/launcher-menu.ps1
   grep -rn "launcher-menu" --include="*.ps1" --include="*.bat" --include="*.md"
   ```
   Confirm zero current references.

3. **New helper export**:
   ```bash
   grep -rn "ToolkitLogRoot" --include="*.ps1" --include="*.bat" --include="*.md"
   ```
   Confirm `$script:ToolkitLogRoot` is consumed where it should be (launcher's `[L]` View recent log) and that nothing else relied on a previous export shape.

4. **Website residue** (should be zero hits):
   ```bash
   grep -rn "website\|TweakEazy\|FILE_LINKS\|repoFile" --include="*.md" --include="*.ps1" --include="*.bat" --include="*.yml"
   ```

5. **Tier string consistency**:
   ```bash
   grep -rEn "Safe|Advanced|Security Trade-off|Trade-off|Tradeoff|tradeoff" --include="*.ps1" --include="*.bat" --include="*.md"
   ```
   Canonical strings in code: `Safe`, `Advanced`, `Security Trade-off`. Display label `Trade-off` only in launcher render. Any mismatch is a bug.

6. **GUIDE.md filesystem reconciliation**: every path mentioned in `GUIDE.md` exists on disk. Every file in numbered folders is either documented or intentionally not. Diff and reconcile.

7. **`.reg` value types**: re-sweep all `.reg` files. Confirm `hex:` (REG_BINARY), `hex(2):` (REG_EXPAND_SZ), `dword:` (REG_DWORD), etc. match what each key actually expects. (The `visual-effects-performance.reg` `UserPreferencesMask` fix should hold; verify.)

## Phase 2 — Final audit pass

Walk the repo cold. Failure modes that historically appear at this stage:

- **Dangling references in `APPLY-EVERYTHING.ps1`**: every `Run-Step` path resolves on disk. Every `Set-TrackedRegistry` / `Set-TrackedService` call has a matching restore in `REVERT-EVERYTHING.ps1` and a check in `verify-tweaks.ps1`. Diff the three files against each other.
- **Idempotency trace**: read the apply path and mentally simulate apply → revert → apply. Manifest should round-trip cleanly. If anything writes outside the helper functions, flag it.
- **Manifest schema**: confirm `verify-tweaks.ps1` handles the current manifest format. If any predecessor changed a field, document the migration path in `KNOWN-ISSUES.md`.
- **Tier surface area**: every entry in `APPLY-EVERYTHING.ps1` has a declared tier. Every tier maps to the launcher's three-color scheme. No untiered tweaks.
- **Documentation drift**: `GUIDE.md` step counts, `BIOS-CHECKLIST.md` vendor sections, `README.md` quick-start, all match current code.
- **Top-of-file credits**: every file derived from FR33THY, Calypto, BoringBoom, djdallmann, etc. credits the source explicitly.
- **DDU + winutil hash verification**: `DduManual.ps1` version pin still documented or parameterized. `chris-titus-winutil.bat` still prints SHA256 before execution.

For each finding, classify:
- `blocker` — must fix before tagging release. Fix in a `fix:` commit.
- `non-blocker` — log to `KNOWN-ISSUES.md` for next release.
- `accepted deviation` — justify in `PRODUCTION-READY.md` under `## Accepted deviations`.

## Phase 3 — Windows runtime validation

The launcher and full apply/revert flow are unverified at Windows runtime. Pick the path that matches your environment.

**Path A — Windows host reachable** (RDP, SSH, local VM, gaming PC): run `prompts/windows-test.md` end-to-end. The `TEST-REPORT.md` it produces is your runtime evidence.

**Path B — Mac/Linux only**: produce `MANUAL-TEST-CHECKLIST.md` at repo root. Literal click-by-click checklist the owner can run on a Win11 VM in under one hour. Each item must be:
- Specific (exact command, exact click target)
- Binary pass/fail criterion
- Reference the file or function under test

Checklist must cover at minimum:
- `launcher.ps1` renders: header alignment, tier colors (Safe = green, Advanced = yellow, Trade-off = red), status indicators (`✓ applied`, `! drift`), ASCII fallback in ISE, narrow terminal (60 cols) layout intact.
- `APPLY-EVERYTHING.ps1` clean run: zero `Failed`, manifest written, post-reboot sanity (network, audio, display, login).
- `verify-tweaks.ps1` post-apply: tracked tweaks report `APPLIED`, no `DRIFTED`.
- `REVERT-EVERYTHING.ps1` clean run: zero `Failed`, post-reboot sanity.
- Idempotency: re-apply (zero `Failed`), re-revert (zero `Failed`), apply→revert→apply (manifests match).
- Non-admin launch: clean refusal, no partial menu.
- Locale: confirm `enable-ultimate-performance.bat` GUID-based parsing doesn't depend on English `for /f` output.

Record which path was taken in `PRODUCTION-READY.md`.

## Phase 4 — Release prep

1. **Version**: pick a real version. First public release → `v1.0.0`. Otherwise follow semver from prior tags (`git tag -l`).
2. **Single source of truth**: store version in `VERSION` file at repo root or `lib/version.ps1` exporting `$Toolkit_Version = '1.0.0'`. `launcher.ps1` header reads from this — replace any hardcoded version string.
3. **`CHANGELOG.md`** at repo root. Conventional format (Keep a Changelog spec). Roll up `CHANGES.md`, `CODEX-AUDIT.md`, `CLEANUP.md` into user-facing entries by category: `Added / Changed / Fixed / Removed`. Keep the source audit docs as-is for the historical record — `CHANGELOG.md` is the user-facing summary.
4. **`README.md`** sweep:
   - Title, one-line description.
   - Screenshot of the launcher (place in `docs/img/launcher.png`; if not yet captured, leave a placeholder note in `KNOWN-ISSUES.md`).
   - Quick start: three steps max to first apply.
   - Risk tier explanation (Safe / Advanced / Security Trade-off — what each means, what reverts).
   - Link to `GUIDE.md` for full docs, `BIOS-CHECKLIST.md` for hardware tweaks, `CHANGELOG.md` for release notes.
   - License, credits (FR33THY, Calypto, BoringBoom, djdallmann, ChrisTitusTech, plus any others surfaced).
   - No marketing language. No emoji.
5. **`LICENSE`** present. If absent, add one matching the repo's existing license signal (MIT default).
6. **`.gitattributes`**: PowerShell and batch files declared as `text eol=crlf` so a Mac-cloned repo doesn't ship LF line endings to Windows. Verify or add:
   ```
   *.ps1 text eol=crlf
   *.bat text eol=crlf
   *.cmd text eol=crlf
   *.reg text eol=crlf
   *.md  text eol=lf
   ```
7. **`.editorconfig`**: if absent, add. 4-space indent for `.ps1`, 2-space for `.md`.
8. **Tag the release** — only after Phases 1–3 are clean and all blockers fixed:
   ```bash
   git tag -a v1.0.0 -m "Production-ready release"
   git push origin v1.0.0
   ```

## Phase 5 — Retire safety branches

Only if Phases 1–3 surfaced zero blockers and the release tag pushed clean:
```bash
git push origin --delete CC/salvage-pre-cleanup CC/sleepy-hellman-f4b52f
git branch -D CC/salvage-pre-cleanup CC/sleepy-hellman-f4b52f 2>/dev/null
```

If anything in Phases 1–3 is unresolved, safety branches stay until the toolkit is actually clean.

## Phase 6 — Output

1. **`PRODUCTION-READY.md`** at repo root:
   - Release version + tag
   - Phase 1 verification table (check / pass-fail / evidence path)
   - Phase 2 findings (blockers fixed with commit links / non-blockers logged / accepted deviations)
   - Phase 3 path taken (A or B) with reference to `TEST-REPORT.md` or `MANUAL-TEST-CHECKLIST.md`
   - Phase 4 release artifact confirmation
   - Phase 5 branch retirement status
2. Either `TEST-REPORT.md` or `MANUAL-TEST-CHECKLIST.md`.
3. New `CHANGELOG.md`, updated `README.md`, version file, `.gitattributes`, `.editorconfig` if added.
4. Conventional commits, one per logical change.
5. Final tag pushed to origin.

## Hard constraints

- No new features. No "while we're here" additions. Polish only.
- If a check passes, log it explicitly in `PRODUCTION-READY.md`. "Verified clean" is a result, not a skip.
- If a check fails, fix it in a `fix:` commit before tagging. Do not tag with known blockers.
- Do not retire safety branches until the release tag is pushed clean.
- Do not modify `lib/toolkit-state.ps1` helper signatures. The cleanup pass added `$script:ToolkitLogRoot`; further changes are scope creep.
- One commit per logical change. The tag is the final action.
- If you find a discovery item not in `DISCOVERY-BACKLOG.md` that's worth adding, log it in `KNOWN-ISSUES.md` for the next release. Do not implement.
- Do not delete or rewrite any predecessor report (`CHANGES.md`, `CODEX-AUDIT.md`, `CLEANUP.md`). They are the historical record. `CHANGELOG.md` is the new user-facing summary; the audit docs stay alongside it.
- If something is genuinely ambiguous (release version number, license choice, whether a deviation is acceptable), pick the most defensible default, document the choice in `PRODUCTION-READY.md` under `## Decisions`, and continue. Do not stop and ask.

Begin with Phase 0. Output the current commit hash, tracked file count, and active branch as your first action — do not run any verification until that's on record.
