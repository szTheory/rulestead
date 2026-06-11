---
phase: 98-admin-re-skin-css-cascade
plan: "01"
subsystem: testing
tags: [python, ci, css, brand-tokens, guard-scripts, lint]

# Dependency graph
requires:
  - phase: 96-tokens-brandbook-scaffold
    provides: check_brand_tokens.py (light-only), tokens.json with admin_css_mapping.light
  - phase: 97-logo-mark-svg-system
    provides: Final hex values confirmed; Block 3 dark CSS correct
provides:
  - "check_synced_pair.py now guards both dark pair (Block 2≡3) AND light pair (Block 1≡4)"
  - "check_brand_tokens.py now diffs both Block 1 vs admin_css_mapping.light AND Block 3 vs admin_css_mapping.dark"
  - "lint.sh CWD bug fixed — guard scripts can run without FileNotFoundError after cd rulestead/"
affects: [98-02, 98-03, 98-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive guard extension: fold dark mismatches into same list as light, prefix [dark] for readability"
    - "CWD restore pattern: insert cd back to repo root after Elixir tool cd, before Python relative-path scripts"

key-files:
  created: []
  modified:
    - scripts/check_synced_pair.py
    - scripts/check_brand_tokens.py
    - scripts/ci/lint.sh

key-decisions:
  - "D-05a: Block 1≡4 light-pair assertion added additively — decls() reused verbatim, both pairs must pass before return 0"
  - "D-05b: Block 3 dark diff folded into mismatches list with [dark] prefix — same exit logic, no refactor of existing light diff"
  - "D-04a preserved: case-insensitive hex comparison (css_val.lower() != expected.lower()) applied to dark diff identically"
  - "lint.sh CWD fix: cd back to RULESTEAD_REPO inserted at line 18 (after dialyzer, before guard block)"

patterns-established:
  - "Guard script additive pattern: new checks fold into same exit list, never split into separate exit paths"
  - "Selector for Block 4: '.rs-shell[data-theme=\\\"light\\\"]' without trailing comma is sufficient for find() after comment-strip"
  - "Selector for Block 3 (dark): '.rs-shell[data-theme=\\\"dark\\\"],' with trailing comma matches the rule opening"

requirements-completed: [SKIN-02, SKIN-03]

# Metrics
duration: 8min
completed: 2026-06-05
---

# Phase 98 Plan 01: CI Guard Script Extensions Summary

**Additive Block 1≡4 light-pair assertion + Block 3 dark token diff + lint.sh CWD fix — 15 pre-re-skin mismatches now machine-verifiable**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-05T19:38:20Z
- **Completed:** 2026-06-05T19:46:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Extended check_synced_pair.py (D-05a): added Block 1≡4 light-pair assertion after the existing Block 2≡3 dark check; both pairs must pass for exit 0; exits 1 with "SYNCED PAIR MISMATCH (light)" and per-token diff on failure
- Extended check_brand_tokens.py (D-05b): added Block 3 dark token diff folded into the same mismatches list as the light diff, with [dark] prefix for readability; the highest-risk one-digit transposition `--rs-success-border #166634 vs #166534` is now actively caught
- Fixed lint.sh CWD bug: inserted `cd "${RULESTEAD_REPO}"` at line 18 before the guard block so all three Python scripts resolve their repo-root-relative paths correctly after `cd "${RULESTEAD_REPO}/rulestead"` at line 6

## Verification Results (pre-re-skin)

```
check_synced_pair.py  → exit 0: SYNCED PAIR IDENTICAL (56 tokens) + SYNCED PAIR IDENTICAL (light: 57 tokens)
check_brand_tokens.py → exit 1: BRAND TOKEN DRIFT DETECTED (15 mismatches: 7 light + 8 dark)
check_tokens_css.py   → exit 0: TOKENS.CSS MIRROR SYNCED (68 tokens)
check_contrast.py     → exit 0: CONTRAST CHECK PASS (18 checks)
```

The [dark] --rs-success-border mismatch (tokens.json=#166634 vs css=#166534) is present and confirmed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend check_synced_pair.py — add Block 1≡4 light-pair assertion (D-05a)** - `8806649` (feat)
2. **Task 2: Extend check_brand_tokens.py — Block 3 dark diff (D-05b) + fix lint.sh CWD** - `f868277` (feat)

## Files Created/Modified
- `scripts/check_synced_pair.py` - Added Block 1≡4 light-pair check; updated docstring for both dark+light guards
- `scripts/check_brand_tokens.py` - Added Block 3 dark diff (D-05b); updated docstring for Blocks 1+3; added [dark] prefix mismatch reporting
- `scripts/ci/lint.sh` - Inserted CWD restore line before guard block (line 18)

## Decisions Made
- Reused decls() for light-pair check unchanged — no new function needed; selector string without trailing comma uniquely matches Block 4 after comment stripping
- Folded dark mismatches into the same list as light mismatches — single exit condition preserves T-98-02 threat mitigation (no silent exit 0 on dark-only errors)
- Block 3 dark selector used with trailing comma (`.rs-shell[data-theme="dark"],`) to match the exact rule opening in CSS

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 98-02 (CSS re-skin) can now proceed with machine-verifiable guard coverage for all four cascade blocks
- check_brand_tokens.py will exit 0 once Phase 98-02 re-skins both light (Block 1+4) and dark (Block 3) tokens
- check_synced_pair.py will continue to exit 0 as long as Block pairs stay synchronized during re-skin

## Self-Check: PASSED

Files exist:
- scripts/check_synced_pair.py: FOUND
- scripts/check_brand_tokens.py: FOUND
- scripts/ci/lint.sh: FOUND

Commits exist:
- 8806649: FOUND
- f868277: FOUND

---
*Phase: 98-admin-re-skin-css-cascade*
*Completed: 2026-06-05*
