# Changes — FR33THY/Ultimate Integration + Holistic Audit

## Questions for owner

These items were ambiguous in the brief. I proceeded with the most defensible interpretation in each case. Override any decision below by editing this file and resubmitting.

1. **Canonical GitHub URL.** `lib/version-manifest.ps1` and `website/src/lib/constants.ts` both reference `https://github.com/cococool13/TweakEazy`. I left this as-is. If the canonical name should match the worktree label (`win11-gaming-toolkit` / `PC Tweaks`), say so and I'll update both files plus the GUIDE.md repo map.
2. **`Notice.txt` lineage credits.** `Notice.txt` credits Khorvie Tech only. I added FR33THY to `GUIDE.md` Credits and to per-file headers, but left `Notice.txt` untouched. Tell me to expand `Notice.txt` if you want all upstream credits in one document.
3. **`disable-write-cache-flush.ps1` placement.** Real data-loss risk on power loss. I shipped it as opt-in only (launcher entry, not in `APPLY-EVERYTHING.ps1`). Override if you want it included in the full apply.
4. **Spectre / Meltdown mitigation disable.** Added to `APPLY-EVERYTHING.ps1` under the existing `Security Trade-off` block alongside VBS / HVCI / LSA. Justification: same tier, same risk profile (security-vs-perf trade-off explicitly opted into by the user running the aggressive flow).

---

## Summary of changes

Grouped per Phase-5 deliverable: **Integration / Bug fix / Consistency / Documentation**.

### Integration

_To be filled after Phase B commits._

### Bug fix

_To be filled after Phase A commits._

### Consistency

_To be filled after Phase C commits._

### Documentation

- `docs/freethy-integration.md` — full inventory of FR33THY artifacts with port / merge / decline decisions.
- `KNOWN-ISSUES.md` — items declined and existing toolkit limitations carried forward.
- This file (`CHANGES.md`).

---

## File-level change list

_To be filled commit-by-commit._
