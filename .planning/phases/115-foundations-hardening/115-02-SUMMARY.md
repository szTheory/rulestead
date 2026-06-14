---
phase: 115-foundations-hardening
plan: 02
subsystem: ui-foundations
tags: [admin-css, reduced-motion, breakpoints, focus, radius, elevation]

requires:
  - phase: 115-foundations-hardening
    provides: Plan 01 foundation contract and guard
provides:
  - Reduced-motion transform neutralization for admin interaction states
  - Canonical rem breakpoint use for exact tool-layout threshold
  - Tightened foundation guard exception matching
affects: [phase-115, phase-116, ui-matrix, admin-css]

tech-stack:
  added: []
  patterns:
    - Reduced-motion media floor neutralizes nonessential transform effects
    - Exact pixel-equivalent breakpoints migrate to canonical rem values when safely touched

key-files:
  created: []
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
    - .planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md
    - scripts/check_admin_foundations.py

key-decisions:
  - "Reduced-motion users keep state changes but do not receive nonessential hover/active transform motion."
  - "The exact 960px tool-layout breakpoint is represented as canonical 60rem."
  - "The guard checks backticked exception literals so explanatory pixel text does not accidentally permit new media drift."

patterns-established:
  - "Reduced-motion transform neutralization lives inside the dedicated reduce media block near the existing motion section."
  - "Contract rows are removed when a noncanonical media threshold migrates to a canonical breakpoint."

requirements-completed: [FND-01, FND-03, FND-04, FND-05]

duration: 3min
completed: 2026-06-14
---

# Phase 115 Plan 02: Targeted Admin CSS Foundation Hardening Summary

**Reduced-motion behavior now neutralizes nonessential transforms, and one exact pixel breakpoint is normalized to canonical `60rem`.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-14T06:51:00Z
- **Completed:** 2026-06-14T06:53:49Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Expanded the `prefers-reduced-motion: reduce` block to neutralize active, hover, badge, signal, task-link, attention-card, environment, brand, and command-palette transforms.
- Migrated `.rs-tool-layout` from the exact pixel equivalent to canonical `60rem`.
- Removed the resolved breakpoint exception from the foundation contract and tightened the guard so only backticked exception literals count as documented exceptions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add a reduced-motion floor for nonessential transforms** - `1cb024f` (fix)
2. **Task 2: Normalize or document foundation-sensitive CSS selectors** - `a8f126d` (refactor)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `rulestead_admin/priv/static/css/rulestead_admin.css` - Neutralizes reduced-motion transforms and uses `60rem` for the exact tool-layout breakpoint.
- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` - Removes the resolved `rs-tool-layout` pixel exception and records the canonical migration.
- `scripts/check_admin_foundations.py` - Requires exception literals to appear as explicit backticked contract entries.

## Decisions Made

- Kept color, border, and shadow state feedback intact under reduced motion; only transform motion is neutralized.
- Migrated only the exact `960px` == `60rem` threshold. All content-specific pixel thresholds remain documented exceptions.
- Tightened the guard after migration so the canonical table's explanatory pixel text cannot mask future undocumented pixel media queries.

## Deviations from Plan

None - plan executed within the foundation hardening scope. The contract and guard edits were required to keep the breakpoint ledger accurate after the safe CSS migration.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `python3 scripts/check_admin_foundations.py` -> `ADMIN FOUNDATIONS OK`
- `git diff --check -- rulestead_admin/priv/static/css/rulestead_admin.css` -> pass
- CSS diff hex-literal check -> no new hex literals

## Next Phase Readiness

Ready for Plan 03. Reduced-motion and breakpoint source behavior are guard-backed; the matrix spec can now assert reduced-motion transform behavior and dense technical containment.

## Self-Check: PASSED

---
*Phase: 115-foundations-hardening*
*Completed: 2026-06-14*
