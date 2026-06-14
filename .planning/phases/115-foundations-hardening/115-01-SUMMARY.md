---
phase: 115-foundations-hardening
plan: 01
subsystem: ui-foundations
tags: [admin-css, guard, breakpoints, focus, reduced-motion]

requires:
  - phase: 114-repo-native-component-matrix-harness
    provides: Repo-native UI matrix proof surface for foundation stress checks
provides:
  - Phase 115 foundation contract with breakpoint exception ledger
  - Deterministic admin foundations source guard
  - CI wiring for the new foundation guard
affects: [phase-115, phase-116, admin-ui, ui-matrix]

tech-stack:
  added: []
  patterns:
    - Stdlib Python source guard with deterministic marker and media-threshold checks
    - Foundation exception ledger before CSS migration

key-files:
  created:
    - .planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md
    - scripts/check_admin_foundations.py
  modified:
    - scripts/ci/lint.sh
    - rulestead_admin/priv/static/css/rulestead_admin.css

key-decisions:
  - "Document current noncanonical admin CSS media thresholds before migrating them."
  - "Keep the foundation guard source-only and stdlib-only."
  - "Add the minimal reduced-motion media hook early so the new guard can pass immediately."

patterns-established:
  - "Every noncanonical admin @media width literal must appear in 115-FOUNDATIONS-CONTRACT.md."
  - "Foundation CI proof runs through scripts/check_admin_foundations.py."

requirements-completed: [FND-01, FND-02, FND-05]

duration: 6min
completed: 2026-06-14
---

# Phase 115 Plan 01: Foundation Contract And Source Guard Summary

**Breakpoint exception ledger and stdlib source guard now make admin foundation drift auditable in CI.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-14T06:45:00Z
- **Completed:** 2026-06-14T06:50:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `115-FOUNDATIONS-CONTRACT.md` with canonical breakpoints, noncanonical media exceptions, scalar token rules, focus rules, reduced-motion rules, shape/elevation rules, dense-content rules, and verification commands.
- Added `scripts/check_admin_foundations.py`, a stdlib-only source guard that checks required contract sections, documented media thresholds, reduced-motion marker, command-palette focus exception marker, and `--rs-focus-ring`.
- Wired the guard into `scripts/ci/lint.sh` and added the minimal `prefers-reduced-motion: reduce` source floor required for the guard to pass before Wave 2 completes transform neutralization.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the foundation contract and exception ledger** - `7555698` (docs)
2. **Task 2: Add the deterministic foundation guard** - `30818eb` (test)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` - Phase 115 foundation rules and breakpoint exception ledger.
- `scripts/check_admin_foundations.py` - Deterministic source guard for contract sections, media threshold coverage, reduced motion, and focus markers.
- `scripts/ci/lint.sh` - Adds the foundation guard to the normal CI guard chain.
- `rulestead_admin/priv/static/css/rulestead_admin.css` - Adds the minimal reduced-motion media hook needed for the guard to pass immediately.

## Decisions Made

- Documented current pixel thresholds as explicit exceptions rather than rewriting them before matrix evidence.
- Kept the guard source-only and stdlib-only, matching existing token/logo guard scripts.
- Added the reduced-motion media hook in Wave 1 because Plan 01 required the new guard to pass while also requiring it to assert that the hook exists.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added minimal reduced-motion hook during guard setup**
- **Found during:** Task 2 (Add the deterministic foundation guard)
- **Issue:** The plan required `python3 scripts/check_admin_foundations.py` to pass immediately, but also required that guard to fail unless admin CSS contained `@media (prefers-reduced-motion: reduce)`, which was originally scheduled for Plan 02.
- **Fix:** Added the minimal reduced-motion media block with zero-duration transition/animation behavior. Plan 02 still owns transform neutralization.
- **Files modified:** `rulestead_admin/priv/static/css/rulestead_admin.css`
- **Verification:** `python3 scripts/check_admin_foundations.py`; `git diff --check`
- **Committed in:** `30818eb`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep the guard green at introduction time. Scope remains inside Phase 115 foundation behavior.

## Issues Encountered

None beyond the documented plan-ordering deviation.

## User Setup Required

None - no external service configuration required.

## Verification

- `python3 scripts/check_admin_foundations.py` -> `ADMIN FOUNDATIONS OK`
- `rg -q 'check_admin_foundations.py' scripts/ci/lint.sh` -> pass
- `git diff --check` -> pass

## Next Phase Readiness

Ready for Plan 02. The contract and guard are in place; Plan 02 can complete reduced-motion transform neutralization and review current breakpoint exceptions against the ledger.

## Self-Check: PASSED

---
*Phase: 115-foundations-hardening*
*Completed: 2026-06-14*
