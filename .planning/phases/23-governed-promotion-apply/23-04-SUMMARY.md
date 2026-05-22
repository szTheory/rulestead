---
phase: 23-governed-promotion-apply
plan: 04
subsystem: backend
tags: [promotion, audit, history, reapply]
requires:
  - phase: 23-governed-promotion-apply
    provides: governed promotion execution from stored reviewed snapshots
provides:
  - promotion audit metadata with governance and environment-version linkage
  - backend reapply-version path built on immutable environment versions
  - regression coverage for promotion audit truth and reapply semantics
affects: [23-governed-promotion-apply, rulestead, admin]
tech-stack:
  added: []
  patterns: [forward reapply, audit metadata normalization]
key-files:
  created: []
  modified:
    - rulestead/lib/rulestead/promotion/apply.ex
    - rulestead/lib/rulestead/audit_event.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/test/rulestead/audit_event_governance_test.exs
    - rulestead/test/rulestead/promotion/reapply_version_test.exs
key-decisions:
  - "Reapply-version stays a forward promotion operation instead of reusing rollback-specific paths."
  - "Promotion audit payloads carry exact source, target, compare, and immutable version linkage for later mounted rendering."
patterns-established:
  - "Promotion history is replayed through compare/apply semantics, not inverse-write shortcuts."
  - "Audit metadata is the canonical backend truth for promotion review screens."
requirements-completed: [PROM-03, PROM-04]
duration: 15m
completed: 2026-05-18
---

# Phase 23: Governed Promotion Apply Summary

**Promotion audit truth and backend reapply-version support are in place, with targeted tests confirming immutable-version replay rather than rollback semantics**

## Performance

- **Duration:** 15m
- **Completed:** 2026-05-18
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Verified promotion audit metadata records the canonical source, target, compare, governance, and environment-version linkage needed by later review screens.
- Verified reapply-version is modeled as a fresh forward promotion from immutable environment history instead of `rollback_audit_event/1`.
- Confirmed the backend truth for 23-04 was already present and green with targeted tests.

## Task Commits

No commits were created in this workspace run because the repository already contained unrelated user and build-tree changes.

## Files Created/Modified

- `rulestead/lib/rulestead/promotion/apply.ex` - backend reapply-version entrypoint
- `rulestead/lib/rulestead/audit_event.ex` - promotion-specific audit metadata normalization
- `rulestead/lib/rulestead/store/ecto.ex` - persisted promotion audit linkage and reapply execution support
- `rulestead/test/rulestead/audit_event_governance_test.exs` - promotion audit metadata coverage
- `rulestead/test/rulestead/promotion/reapply_version_test.exs` - immutable-version reapply coverage

## Decisions Made

- Accepted the existing repo implementation for this slice after targeted verification instead of making speculative code changes.

## Deviations from Plan

None - targeted verification confirmed the plan output was already implemented.

## Issues Encountered

None in the targeted backend test set.

## User Setup Required

None.

## Next Phase Readiness

- Mounted admin screens can render exact promotion audit linkage and deep-link into reapply flows.
- Backend support for reapply-version is available for compare-route handoff.

---
*Phase: 23-governed-promotion-apply*
*Completed: 2026-05-18*
