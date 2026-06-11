---
phase: 96-design-tokens-brandbook-scaffold
plan: "02"
subsystem: brand
tags: [brand-book, brandbook, hex-reconciliation, git-mv, markdown, documentation]

requires:
  - phase: 95-brand-audit-palette-reconciliation
    provides: "D-11 signed-off AA-verified hex palette — 15 canonical replacements; Gap 2 Success/Danger on Stone Mist"
  - phase: 96-design-tokens-brandbook-scaffold/96-01
    provides: "brandbook/ directory structure (tokens.json, tokens.css already present)"

provides:
  - "brandbook/brand-book.md — canonical brand book relocated from prompts/ via git mv; §12 hexes reconciled to AA-verified canonicals (D-11/D-12)"
  - "prompts/rulestead-brand-book.md — pointer stub under 10 lines referencing brandbook/brand-book.md"
  - "brandbook/README.md — directory index cross-linking brand-book.md, tokens.json, tokens.css, docs/brand-usage.md, and admin CSS"
  - "brandbook/docs/brand-usage.md — check_brand_tokens.py usage guide, intentional CI failure note, synced-pair rule, new-token guide"

affects:
  - "96-03 (check_brand_tokens.py and lint.sh extension) — docs reference check_brand_tokens.py at scripts/ path"
  - "phase-98 (admin CSS re-skin) — brand-usage.md documents Phase 98 re-skin target and synced-pair update requirement"
  - "phase-100 (brandbook/ final README + copy docs) — brandbook/README.md stub designates Phase 100 expansion"

tech-stack:
  added: []
  patterns:
    - "git mv before content edit — commit working-tree changes, then mv, then apply rework in one commit batch"
    - "Pointer stub pattern — prompts/rulestead-brand-book.md is a sub-10-line HTML-comment + markdown link to canonical location"
    - "Gap-2 blockquote note — per-surface AA note embedded immediately after the semantic color entry it qualifies"

key-files:
  created:
    - "brandbook/brand-book.md (relocated from prompts/ via git mv; §12 hexes reconciled)"
    - "brandbook/README.md (directory index stub, 23 lines)"
    - "brandbook/docs/brand-usage.md (usage guide — check script, CI failure note, synced-pair rule, new-token guide)"
    - "prompts/rulestead-brand-book.md (pointer stub, 4 lines)"
  modified: []

key-decisions:
  - "Committed working-tree edit to prompts/rulestead-brand-book.md as its own standalone commit before git mv, creating clean auditable history"
  - "§12 hex replacements applied as exact substitutions per D-11/D-12 signed-off table — no other hexes touched"
  - "Gap-2 notes added as blockquotes immediately after Success/Danger entries in §12, referencing both the SM-passing canonical and the White/RT-passing book hex"
  - "brandbook/README.md kept under 25 lines (stub); Phase 100 will expand to full index"
  - "brand-usage.md explicitly documents both Phase 96 exit-1 and Phase 98 exit-0 expected outputs to prevent future confusion"

patterns-established:
  - "git mv sequence: commit-then-mv-then-rework produces clean auditable three-commit history via git log --follow"
  - "Blockquote Gap-2 note format directly below semantic color entry — consistent with §12 structure"
  - "brandbook/docs/ as location for operational usage notes tied to brand assets"

requirements-completed:
  - TOK-01
  - TOK-02

duration: 3min
completed: "2026-06-04"
---

# Phase 96 Plan 02: Brand-Book Relocation + §12 Hex Reconciliation + Brandbook Docs Summary

**Relocated brand-book from prompts/ to brandbook/ via git mv, reconciled §12 hexes to AA-verified D-11 canonicals (#9b5931 Ember Copper, #8f601a Warning, #606d66 Moss Grey, #2d7753/#b04848 Gap-2), and authored brandbook/README.md + brandbook/docs/brand-usage.md with check-script usage, intentional CI failure note, and synced-pair rule.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-04T21:07:24Z
- **Completed:** 2026-06-04T21:10:07Z
- **Tasks:** 2
- **Files modified:** 4 (brandbook/brand-book.md, prompts/rulestead-brand-book.md, brandbook/README.md, brandbook/docs/brand-usage.md)

## Accomplishments

- Brand book relocated from `prompts/rulestead-brand-book.md` to `brandbook/brand-book.md` via `git mv` with clean auditable commit history (`git log --follow` shows 3 commits)
- §12 color system reconciled: 5 old hex values replaced with D-11 AA-verified canonicals; Gap-2 blockquote notes added for Success and Danger on Stone Mist; §8 tagline "Runtime decisions, made clear." left untouched
- `prompts/rulestead-brand-book.md` replaced with a 4-line pointer stub referencing the new canonical location
- `brandbook/README.md` (23 lines) created as a directory index cross-linking all brandbook/ files plus the admin CSS
- `brandbook/docs/brand-usage.md` created with check script usage guide, both Phase 96 (exit 1) and Phase 98 (exit 0) expected outputs, intentional CI failure explanation, synced-pair rule (Blocks 1≡4 / 2≡3), and new-token guide

## Task Commits

Each task was committed atomically:

1. **Pre-task: Commit brand-book working-tree edit** - `cb023e3` (chore)
2. **Task 1: Relocate brand-book, reconcile §12 hexes, write pointer stub** - `9874613` (chore)
3. **Task 2: Author brandbook/README.md and brandbook/docs/brand-usage.md** - `3b7312b` (docs)

**Plan metadata:** (docs: complete plan — committed with STATE/ROADMAP)

## Files Created/Modified

- `brandbook/brand-book.md` — Canonical brand book (relocated from prompts/ via git mv; §12 hexes reconciled to AA-verified canonicals: #9b5931, #8f601a, #606d66, #2d7753, #b04848; Gap-2 blockquote notes added for Success and Danger)
- `prompts/rulestead-brand-book.md` — Pointer stub (4 lines; HTML comment + markdown link to brandbook/brand-book.md)
- `brandbook/README.md` — Directory index (23 lines; table of brandbook/ files + admin CSS cross-link + Phase 100 note)
- `brandbook/docs/brand-usage.md` — Usage guide (check_brand_tokens.py invocation, expected Phase 96/98 outputs, intentional CI failure note, synced-pair rule with Block 1≡4/2≡3, new-token guide, admin CSS cross-reference)

## Decisions Made

- Committed the working-tree edit as its own standalone commit before `git mv` — clean, auditable sequence matching D-11 plan
- Warning hex `#B57A21` → `#8f601a` (not `#B57A21` in Warning section, confirming no accidental double-change)
- Gap-2 notes use blockquote format directly below the semantic color entry they qualify, including the book hex as the White/RT-safe fallback
- README.md kept minimal (23 lines) — stub explicitly notes Phase 100 expansion
- brand-usage.md explicitly documents both Phase 96 exit-1 and Phase 98 exit-0 expected outputs to prevent future implementer confusion

## Deviations from Plan

None — plan executed exactly as written. The three-commit sequence (pre-task commit → relocation+rework commit → docs commit) matches the plan's specified steps precisely.

## Issues Encountered

None. All acceptance criteria and plan-level verification checks passed on first attempt. `check_synced_pair.py` exits 0 (rulestead_admin.css untouched throughout).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `brandbook/brand-book.md` is now the canonical brand book; `prompts/rulestead-brand-book.md` is a pointer stub
- `brandbook/README.md` and `brandbook/docs/brand-usage.md` provide the REPO-01 self-contained context for Phase 96-03 (check_brand_tokens.py script) and Phase 98 (admin CSS re-skin)
- `check_synced_pair.py` still exits 0 — no regression in dark synced pair
- Ready for Phase 96 Plan 03 (check_brand_tokens.py + lint.sh CI extension)

---
*Phase: 96-design-tokens-brandbook-scaffold*
*Completed: 2026-06-04*

## Self-Check: PASSED

### Verification Results

| Check | Command | Result |
|-------|---------|--------|
| brand-book.md exists | `test -f brandbook/brand-book.md` | PASS |
| History preserved (≥2 commits) | `git log --follow brandbook/brand-book.md \| grep -c commit` | count=3 PASS |
| Old hex absent (#B96A3A) | `grep '#B96A3A' brandbook/brand-book.md` | count=0 PASS |
| New canonical #9b5931 (≥2) | `grep -c '#9b5931' brandbook/brand-book.md` | count=2 PASS |
| Gap-2 notes (≥2) | `grep -c 'Gap 2' brandbook/brand-book.md` | count=2 PASS |
| §8 tagline (≥1) | `grep -c 'Runtime decisions, made clear' brandbook/brand-book.md` | count=3 PASS |
| Pointer stub (<10 lines) | `wc -l < prompts/rulestead-brand-book.md` | lines=4 PASS |
| Pointer references path (≥1) | `grep -c 'brandbook/brand-book.md' prompts/rulestead-brand-book.md` | count=2 PASS |
| Docs exist | `test -f brandbook/README.md && test -f brandbook/docs/brand-usage.md` | PASS |
| check_synced_pair.py exits 0 | `python3 scripts/check_synced_pair.py` | SYNCED PAIR IDENTICAL (56 tokens) PASS |
| README.md <35 lines | `wc -l < brandbook/README.md` | lines=23 PASS |
| check_brand_tokens.py in usage (≥2) | `grep -c 'check_brand_tokens.py' brandbook/docs/brand-usage.md` | count=5 PASS |
| SYNCED PAIR in usage (≥1) | `grep -c 'SYNCED PAIR' brandbook/docs/brand-usage.md` | count=2 PASS |
| Intentional in usage (≥1) | `grep -ci 'intentional' brandbook/docs/brand-usage.md` | count=3 PASS |
| Phase 98 in usage (≥2) | `grep -c 'Phase 98' brandbook/docs/brand-usage.md` | count=5 PASS |

All 15 checks PASSED.
