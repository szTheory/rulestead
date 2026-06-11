---
phase: 101-html-brand-book
plan: "03"
subsystem: docs
tags: [brandbook, html, drift-check, ci, budget]

requires:
  - phase: 101-html-brand-book
    provides: "101-02 generated HTML page experience and importable render_brandbook()"
provides:
  - "Executable generated-HTML drift, static assertion, and 262144-byte budget guard"
  - "scripts-first lint wiring for the generated HTML brand book guard"
  - "Documented generated HTML budget without relaxing logo or specimen SVG budgets"
affects: [101-html-brand-book, brandbook, scripts, ci]

tech-stack:
  added: []
  patterns:
    - "stdlib-only HTML drift guard importing render_brandbook(repo_root)"
    - "generated artifact byte-compare with bounded unified diff"
    - "scripts-first CI wiring before SVG budget checks"

key-files:
  created:
    - scripts/check_brandbook_html.py
    - .planning/phases/101-html-brand-book/101-03-SUMMARY.md
  modified:
    - brandbook/BUDGET.md
    - scripts/ci/lint.sh
    - brandbook/index.html

key-decisions:
  - "The generated HTML budget is fixed at 256 KB / 262144 bytes."
  - "The new checker validates generated source refs, section order, unsafe markers, unique IDs, local links, trailing newline, and drift before reporting success."
  - "Doc-excerpt links are validated against their originating source document bases when they do not resolve from the generated page root."

patterns-established:
  - "Checker success output is exactly `BRANDBOOK HTML SYNCED (N bytes)`."
  - "Generated HTML source changes require regenerating and committing `brandbook/index.html` so the drift guard stays green."

requirements-completed: [BOOK-01, BOOK-02]

duration: 13 min
completed: 2026-06-06
---

# Phase 101 Plan 03: HTML Brand Book Drift Guard Summary

**Generated HTML brand book drift checking, 262144-byte budget enforcement, and CI lint wiring are now active.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-06-06T05:14:37Z
- **Completed:** 2026-06-06T05:22:57Z
- **Tasks:** 4
- **Files modified:** 5

## Accomplishments

- Added executable `scripts/check_brandbook_html.py` with byte-for-byte regeneration drift detection, a bounded unified diff, a 262144-byte HTML budget, required section/source checks, unsafe marker checks, unique ID validation, local link validation, and one-trailing-newline enforcement.
- Documented the generated HTML budget in `brandbook/BUDGET.md` while preserving logo SVG `20480` bytes and specimen SVG `51200` bytes.
- Wired `scripts/check_brandbook_html.py` into `scripts/ci/lint.sh` immediately after `check_tokens_css.py` and before the SVG size-budget loop.
- Regenerated `brandbook/index.html` so the updated budget source remains synchronized with the committed generated artifact.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add check_brandbook_html.py drift, budget, and static assertion guard** - `eadabf0` / `eadabf0155b0374cc3cbd18385a40789c449fcd3`
2. **Task 2: Document generated HTML budget without relaxing SVG budgets** - `f29139d` / `f29139da5ae9fb5cc675ecab4cd150a0e3df01b8`
3. **Task 3: Wire generated HTML guard into scripts-first lint lane** - `ef0eacd` / `ef0eacd71db21bfc5e58ddee8c57a01d93aa86d6`
4. **Task 4: Run guard sweep after drift, budget, and CI wiring** - `1fdd3bd` / `1fdd3bd5804f32ebd1a1d1450a1a63ef83b69640`
5. **Close-out auto-fix: validate embedded brandbook excerpt links** - `0ff03a7` / `0ff03a75f20d6ef3ee4dc1b7176d10fe7b3c0f4e`

## Files Created/Modified

- `scripts/check_brandbook_html.py` - Generated HTML drift, budget, and static assertion guard.
- `brandbook/BUDGET.md` - Adds generated HTML budget row, policy bullets, and narrow checker command.
- `scripts/ci/lint.sh` - Runs the generated HTML guard after tokens.css mirror checking and before SVG budgets.
- `brandbook/index.html` - Regenerated from canonical sources after the budget doc update.
- `.planning/phases/101-html-brand-book/101-03-SUMMARY.md` - Plan completion summary.

## Decisions Made

- Kept the HTML budget at the planned 256 KB / 262144 bytes.
- Kept `scripts/ci/lint.sh` scripts-first: no Node, Playwright, npm, browser, or publishing lane changes.
- Validated doc-excerpt links against their original source document bases where page-root resolution is not correct for copied markdown excerpts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated generated HTML artifact after budget source update**
- **Found during:** Task 4 (Run guard sweep after drift, budget, and CI wiring)
- **Issue:** Updating `brandbook/BUDGET.md` changes a canonical source rendered into `brandbook/index.html`; without committing the regenerated HTML, `scripts/check_brandbook_html.py` correctly reports drift.
- **Fix:** Ran `python3 scripts/gen_brandbook_html.py` and committed the resulting `brandbook/index.html` sync.
- **Files modified:** `brandbook/index.html`
- **Verification:** `python3 scripts/check_brandbook_html.py` printed `BRANDBOOK HTML SYNCED (133280 bytes)`.
- **Committed in:** `1fdd3bd` / `1fdd3bd5804f32ebd1a1d1450a1a63ef83b69640`

**2. [Rule 3 - Blocking] Tightened embedded doc-excerpt link validation**
- **Found during:** Close-out review after Task 4
- **Issue:** The first checker version skipped links inside rendered `.doc-excerpt` source copies to avoid false failures on source-relative markdown links. That weakened the planned local-link validity assertion.
- **Fix:** Track rendered doc-excerpt source order and validate excerpt-relative links against their originating source bases when they do not resolve from `brandbook/`.
- **Files modified:** `scripts/check_brandbook_html.py`
- **Verification:** `python3 scripts/check_brandbook_html.py` printed `BRANDBOOK HTML SYNCED (133280 bytes)` and the full lint lane passed.
- **Committed in:** `0ff03a7` / `0ff03a75f20d6ef3ee4dc1b7176d10fe7b3c0f4e`

---

**Total deviations:** 2 auto-fixed blocking issues.
**Impact on plan:** Both fixes preserve the intended generated-source and static-link contracts. No runtime, publishing, or shared planning state files were changed.

## Issues Encountered

- Python guard runs created transient `scripts/__pycache__/`; it was removed before commits and not staged.
- Full lint generated package tar output as part of the existing lint flow, but no publish step was run and no package artifacts were staged.

## Verification

- `python3 -m py_compile scripts/check_brandbook_html.py` - exit 0.
- `python3 scripts/gen_brandbook_html.py` - exit 0; printed `WROTE brandbook/index.html (133280 bytes)`.
- `python3 scripts/check_brandbook_html.py` - exit 0; printed `BRANDBOOK HTML SYNCED (133280 bytes)`.
- `python3 scripts/check_synced_pair.py` - exit 0; printed `SYNCED PAIR IDENTICAL (56 tokens)` and `SYNCED PAIR IDENTICAL (light: 57 tokens)`.
- `python3 scripts/check_brand_tokens.py` - exit 0; printed `BRAND TOKENS SYNCED (68 tokens)`.
- `python3 scripts/check_tokens_css.py` - exit 0; printed `TOKENS.CSS MIRROR SYNCED (68 tokens)`.
- `bash scripts/ci/lint.sh` - exit 0; key final outputs included `BRANDBOOK HTML SYNCED (133280 bytes)` and `SVG SIZE BUDGET OK`.
- `wc -c < brandbook/index.html` - `133280`, under the `262144` byte budget.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `101-04`: browser evidence, brandbook README finalization, and v1.14 milestone closeout can proceed after the orchestrator updates shared tracking. This executor intentionally did not modify `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, or `.planning/REQUIREMENTS.md`.

## Self-Check: PASSED

---
*Phase: 101-html-brand-book*
*Completed: 2026-06-06*
