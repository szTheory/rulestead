---
phase: 96-design-tokens-brandbook-scaffold
plan: "03"
subsystem: infra
tags: [python, ci, drift-check, design-tokens, brand-tokens, lint]

requires:
  - phase: 96-design-tokens-brandbook-scaffold
    provides: "96-01: tokens.json with admin_css_mapping.light (the comparison target for check_brand_tokens.py)"

provides:
  - "scripts/check_brand_tokens.py — executable stdlib-only drift check that exits 1 against un-re-skinned CSS"
  - "scripts/ci/lint.sh extended — synced-pair CI guard + brand-token check + SVG size-budget loop appended"

affects: [96-design-tokens-brandbook-scaffold, 98-admin-reskin]

tech-stack:
  added: []
  patterns:
    - "comment-strip before selector search (Pitfall 3): re.sub(r'/\\*.*?\\*/', '', raw, flags=re.S) BEFORE css.find()"
    - "brace-depth walk for CSS block extraction — mirrors check_synced_pair.py exactly"
    - "case-insensitive hex comparison via .lower() on both sides"
    - "shopt -s nullglob for no-op-safe glob loops under set -euo pipefail"
    - "wc -c < file | tr -d ' ' for POSIX-portable byte count (not stat)"

key-files:
  created:
    - scripts/check_brand_tokens.py
  modified:
    - scripts/ci/lint.sh

key-decisions:
  - "Exit-1-by-design: check_brand_tokens.py intentionally exits 1 against current CSS — this is Phase 96 success criterion 3, proving the guard works before Phase 98"
  - "Skip non --rs-* keys in admin_css_mapping iteration to exclude DTCG metadata ($description) from comparison"
  - "check_synced_pair.py wired into CI (Pitfall 6 guard) — one extra line, strictly additive, prevents silent Blocks 2-3 mismatch regression in Phase 98"
  - "SVG budget loop placed after brand-token check so it executes in Phase 97+ after check_brand_tokens.py goes green"

patterns-established:
  - "Token drift check pattern: load JSON → extract CSS block via comment-strip+brace-walk → case-insensitive compare → per-token diff output"
  - "Additive CI lint extension: read full file, preserve all lines verbatim, append new sections with explanatory comments"

requirements-completed:
  - TOK-01
  - TOK-02
  - TOK-03

duration: 1min
completed: "2026-06-04"
---

# Phase 96 Plan 03: Brand-Token Drift Check + CI Extension Summary

**Python3 stdlib drift check (check_brand_tokens.py) that proves guard mechanism by exiting 1 against generic CSS, plus additive lint.sh extension wiring synced-pair CI guard and SVG size-budget loop**

## Performance

- **Duration:** 1 min
- **Started:** 2026-06-04T21:14:24Z
- **Completed:** 2026-06-04T21:16:59Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `scripts/check_brand_tokens.py`: executable, stdlib-only (sys, re, json), mirrors check_synced_pair.py comment-strip + brace-walk algorithm, exits 1 with 7-token per-token diff against current generic CSS (Phase 96 success criterion 3)
- `scripts/ci/lint.sh`: all 15 original lines preserved verbatim; three blocks appended: check_synced_pair.py CI guard (Pitfall 6), check_brand_tokens.py call with intentional-failure comment, SVG size-budget loop (shopt -s nullglob + wc -c + 20KB/50KB budgets)
- Auto-fixed: skip DTCG metadata keys (`$description`) in admin_css_mapping iteration — ensures only `--rs-*` token names are compared

## Task Commits

1. **Task 1: Write check_brand_tokens.py** - `ffae82e` (feat)
2. **Task 2: Extend lint.sh** - `0423183` (feat)

**Plan metadata:** (docs commit hash below)

## Files Created/Modified

- `scripts/check_brand_tokens.py` — Token drift check: reads tokens.json admin_css_mapping.light, extracts Block 1 of rulestead_admin.css via comment-strip+brace-walk, compares case-insensitively, exits 0 (BRAND TOKENS SYNCED) or 1 (BRAND TOKEN DRIFT DETECTED + per-token diff)
- `scripts/ci/lint.sh` — Extended with three additive blocks: check_synced_pair.py CI guard, check_brand_tokens.py call (intentionally exits 1), SVG size-budget loop (no-op when brandbook/assets/ absent)

## Decisions Made

- **Exit-1-by-design acknowledged:** check_brand_tokens.py must fail now (D-08). CI will fail at this step until Phase 98 re-skins rulestead_admin.css. The comment above the line documents this intent.
- **`$description` key skip:** admin_css_mapping.light contains a DTCG `$description` metadata key. The comparison loop skips any key that does not start with `--rs-` to prevent false "css=<missing>" errors.
- **check_synced_pair.py in CI (Pitfall 6):** Added `python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"` before the brand-token check — one extra additive line that closes the gap where Phase 98 edits could silently break the Blocks 2≡3 invariant.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Skip DTCG $description metadata key in admin_css_mapping iteration**
- **Found during:** Task 1 (acceptance criteria run)
- **Issue:** `admin_css_mapping.light` contains a `$description` key (DTCG metadata). The original loop iterated all keys, causing a false mismatch line: `$description: tokens.json=<long text>  css=<missing>` in the output
- **Fix:** Added `if not name.startswith("--rs-"): continue` guard inside the mapping iteration loop
- **Files modified:** scripts/check_brand_tokens.py
- **Verification:** Reran `python3 scripts/check_brand_tokens.py` — output now shows exactly 7 expected `--rs-*` mismatches, no `$description` line
- **Committed in:** ffae82e (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** Essential fix — without it, the output included a spurious `$description` mismatch line that would confuse Phase 98 operators reading the drift output. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- scripts/check_brand_tokens.py proves the guard mechanism: exits 1 against current generic CSS with exactly the expected 7-token diff
- scripts/ci/lint.sh is extended with all three required blocks; SVG budget loop exits 0 (no SVGs yet) and will remain no-op until Phases 97/99 add SVG assets
- Phase 96 plan 04 (if any) can proceed; Phase 98 is the phase that makes check_brand_tokens.py green

---
*Phase: 96-design-tokens-brandbook-scaffold*
*Completed: 2026-06-04*

## Self-Check: PASSED

- `scripts/check_brand_tokens.py` exists and is executable: VERIFIED
- `scripts/ci/lint.sh` contains check_brand_tokens.py, check_synced_pair.py, SVG SIZE BUDGET OK: VERIFIED
- All 15 original lint.sh lines preserved: VERIFIED (head -2 shows shebang + pipefail; dialyzer in head-16)
- `check_brand_tokens.py` exits 1 with 7-token diff: VERIFIED
- `check_synced_pair.py` still exits 0: VERIFIED
- Commits ffae82e and 0423183 exist: VERIFIED (git log)
