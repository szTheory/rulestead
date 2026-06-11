---
phase: 99-specimens
plan: 04
subsystem: brandbook/assets/specimens
tags: [brand, svg, specimens, svgo, lint, phase-close]
dependency_graph:
  requires:
    - brandbook/assets/specimens/*.svg (all 6 committed by Plans 01-03)
    - brandbook/assets/logo/svgo.config.mjs (SVGO config reused verbatim)
    - scripts/ci/lint.sh (SVG size-budget loop at lines 41-48; threshold 51200)
  provides:
    - brandbook/assets/specimens/palette.svg (final SVGO-optimized state)
    - brandbook/assets/specimens/typography.svg (final SVGO-optimized state)
    - brandbook/assets/specimens/components.svg (final SVGO-optimized state)
    - brandbook/assets/specimens/code-block.svg (final SVGO-optimized state)
    - brandbook/assets/specimens/readme-header.svg (final SVGO-optimized state)
    - brandbook/assets/specimens/social-card.svg (final SVGO-optimized state)
  affects:
    - Phase 100 (depends on Phase 99 complete; repo in final state for CI end-to-end confirmation)
    - Phase 101 HTML brand book (consumes all 6 specimen files)
tech-stack:
  added: []
  patterns:
    - idempotent SVGO batch pass (multipass on already-optimized SVGs is safe and converges quickly)
    - post-SVGO role=img re-insertion via sed (SVGO preset-default strips role="img" via removeUnknownsAndDefaults)
    - SVG size-budget CI gate via scripts/ci/lint.sh bash loop (threshold 51200 bytes; nullglob)

key-files:
  created: []
  modified:
    - brandbook/assets/specimens/palette.svg
    - brandbook/assets/specimens/typography.svg
    - brandbook/assets/specimens/components.svg
    - brandbook/assets/specimens/code-block.svg
    - brandbook/assets/specimens/readme-header.svg
    - brandbook/assets/specimens/social-card.svg
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "SVGO batch pass on already-optimized specimens is idempotent — files converged in 7-15ms each with <1% further reduction"
  - "role=img re-inserted via sed after every SVGO run (SVGO preset-default strips it via removeUnknownsAndDefaults — known pattern from Plans 01-03)"
  - "Full lint.sh run passed (dialyzer, synced-pair, brand-tokens, SVG budget all green); SVG SIZE BUDGET OK confirmed as final Phase 99 CI gate"
  - "Phase 99 complete: all 6 specimens ≤51200 bytes, zero base64, title element in every file, role=img on every SVG root"

requirements-completed: [SPEC-01, SPEC-02]

duration: ~5min
completed: 2026-06-05
---

# Phase 99 Plan 04: Specimens Phase-Close (SVGO Batch + Lint Gate + Doc Updates) Summary

**Idempotent SVGO batch pass on all 6 specimens confirms final optimized state; full lint.sh run exits 0 with "SVG SIZE BUDGET OK"; Phase 99 closed with STATE/ROADMAP/REQUIREMENTS updated.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-05T22:00:00Z
- **Completed:** 2026-06-05T22:05:00Z
- **Tasks:** 2
- **Files modified:** 9 (6 SVG specimens + 3 planning docs)

## Accomplishments

- Re-ran SVGO with `svgo.config.mjs` (multipass, removeDesc:false, cleanupIds:false, convertColors:false) on all 6 specimens; files converged idempotently with < 1% further reduction each
- Re-inserted `role="img"` on every SVG root after SVGO (consistent with Plans 01-03 known deviation)
- Full `bash scripts/ci/lint.sh` exits 0: dialyzer green, synced-pair green (56 dark + 57 light tokens), brand-tokens green (68 tokens), tokens.css mirror green, SVG SIZE BUDGET OK
- Updated STATE.md (Phase 100 ready-to-plan, 71% progress, 4 Phase 99 decisions recorded), ROADMAP.md (Phase 99 [x] complete, 4/4 plans, progress table 2026-06-05), REQUIREMENTS.md (SPEC-01 and SPEC-02 already [x] from prior plans — confirmed)

## Task Commits

Each task was committed atomically:

1. **Task 1: SVGO batch optimize all 6 specimens + full lint.sh guard sweep** - `1e88311` (chore)
2. **Task 2: Update planning docs — Phase 99 complete (STATE + ROADMAP + REQUIREMENTS)** - `862e4b8` (docs)

## Files Created/Modified

- `brandbook/assets/specimens/palette.svg` — Final SVGO-optimized state (10,023 bytes; was 10,034)
- `brandbook/assets/specimens/typography.svg` — Final SVGO-optimized state (3,669 bytes; was 3,680)
- `brandbook/assets/specimens/components.svg` — Final SVGO-optimized state (3,444 bytes; was 3,455)
- `brandbook/assets/specimens/code-block.svg` — Final SVGO-optimized state (1,774 bytes; was 1,785)
- `brandbook/assets/specimens/readme-header.svg` — Final SVGO-optimized state (1,216 bytes; was 1,227)
- `brandbook/assets/specimens/social-card.svg` — Final SVGO-optimized state (1,490 bytes; was 1,501)
- `.planning/STATE.md` — Phase 100 ready-to-plan; progress 57%→71%; 4 Phase 99 decisions; Operator Next Steps updated
- `.planning/ROADMAP.md` — Phase 99 [x] complete; all 4 plans checked; completion note added; progress table updated to 4/4 Complete 2026-06-05
- `.planning/REQUIREMENTS.md` — SPEC-01 and SPEC-02 confirmed [x] done (set in prior plans); traceability rows confirmed Complete

## Decisions Made

- SVGO batch on already-optimized files is safe and idempotent — chosen over skipping to guarantee a single committed final state
- Full lint.sh run executed (not just the SVG budget loop) to confirm all CI guards green; lint.sh passed end-to-end including dialyzer, synced-pair, brand-tokens, tokens.css mirror, and SVG budget

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] SVGO strips role="img" via preset-default**
- **Found during:** Task 1 (same known issue documented in Plans 01-03)
- **Issue:** SVGO 4.x `preset-default` removes `role="img"` via `removeUnknownsAndDefaults`. Acceptance criteria require `role="img"` on every specimen root element.
- **Fix:** Re-inserted `role="img"` on all 6 SVG root elements via sed after SVGO optimization. Consistent with Plans 01-03 fix; shared `svgo.config.mjs` left unmodified.
- **Files modified:** All 6 specimen SVGs
- **Verification:** `grep -c 'role="img"' brandbook/assets/specimens/*.svg` — all return 1
- **Committed in:** 1e88311

---

**Total deviations:** 1 auto-fixed (1 missing critical functionality — same known SVGO behavior as Plans 01-03)
**Impact on plan:** Auto-fix is a known pattern from all prior specimen plans. No scope creep.

## Issues Encountered

None beyond the known SVGO role="img" stripping behavior (documented above). Full lint.sh passed on first run.

## Known Stubs

None. All 6 specimens are fully realized source-controlled SVG assets.

## Threat Flags

No new threat surface introduced. This plan only re-ran SVGO and updated internal planning documents.

T-99-01 mitigated: `grep -c 'base64' brandbook/assets/specimens/*.svg` — all 6 return 0.
T-99-03 mitigated: post-SVGO `grep -c '<title'` — all 6 return 1; role="img" re-inserted on all roots.
T-99-04 mitigated: `grep -c '\[x\].*SPEC-01' REQUIREMENTS.md` = 1; `grep -c '\[x\].*Phase 99' ROADMAP.md` = 1; `grep -c 'Phase 99 complete' STATE.md` = 3.

## Next Phase Readiness

Phase 99 is complete. All 4 success criteria are verified:
1. `palette.svg` has annotated swatches with `#3A6F8F` (Stead Blue) — SC-1 met
2. `typography.svg` uses live `<text>` elements with token labels — SC-2 met
3. All 6 specimen files exist in `brandbook/assets/specimens/` — SC-3 met
4. `bash scripts/ci/lint.sh 2>&1 | grep 'SVG SIZE BUDGET OK'` — SC-4 met

Phase 100 (Marketing Copy + Repo Artifact Plan) can be started with `/gsd:plan-phase 100`.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| brandbook/assets/specimens/palette.svg | FOUND (10,023 bytes) |
| brandbook/assets/specimens/typography.svg | FOUND (3,669 bytes) |
| brandbook/assets/specimens/components.svg | FOUND (3,444 bytes) |
| brandbook/assets/specimens/code-block.svg | FOUND (1,774 bytes) |
| brandbook/assets/specimens/readme-header.svg | FOUND (1,216 bytes) |
| brandbook/assets/specimens/social-card.svg | FOUND (1,490 bytes) |
| .planning/STATE.md Phase 99 complete | FOUND |
| .planning/ROADMAP.md Phase 99 [x] | FOUND |
| .planning/REQUIREMENTS.md SPEC-01 [x] | FOUND |
| .planning/REQUIREMENTS.md SPEC-02 [x] | FOUND |
| SVG SIZE BUDGET OK | VERIFIED |
| Commit 1e88311 (Task 1) | FOUND |
| Commit 862e4b8 (Task 2) | FOUND |

---
*Phase: 99-specimens*
*Completed: 2026-06-05*
