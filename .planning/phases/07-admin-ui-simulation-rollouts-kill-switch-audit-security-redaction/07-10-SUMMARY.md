---
phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
plan: 10
subsystem: testing
tags: [accessibility, axe-core, liveview, rulestead_admin]
requires:
  - phase: 07-03
    provides: simulation route and prior accessibility coverage context
  - phase: 07-04
    provides: rollout route and prior accessibility coverage context
  - phase: 07-05
    provides: kill and audit routes plus prior accessibility coverage context
provides:
  - Axe-backed route audits for simulation, rollouts, kill, per-flag timeline, and global audit screens
  - Shared test support helper that runs axe-core against rendered LiveView route content
affects: [ADMIN-05, SEC-03, phase-7-verification]
tech-stack:
  added: [a11y_audit]
  patterns: [shared axe-core html audit helper, actor-aware phase-7 route seeding]
key-files:
  created: [rulestead_admin/test/support/axe_audit.ex, rulestead_admin/mix.lock]
  modified: [rulestead_admin/mix.exs, rulestead_admin/test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs, rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs, rulestead_admin/test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs]
key-decisions:
  - "Use a shared ExUnit helper that shells out to axe-core in Node, instead of keeping per-test LazyHTML heuristics."
  - "Normalize LiveView fragments into a minimal document shell and audit the route body scope so the proof targets page content rather than shared shell chrome outside this plan's file boundary."
patterns-established:
  - "Route accessibility proof lives in focused route tests and reuses a single support helper."
  - "Phase 7 accessibility fixtures seed rulesets with explicit admin actors so setup stays aligned with the auth-aware command path."
requirements-completed: [ADMIN-05, SEC-03]
duration: 35min
completed: 2026-04-24
---

# Phase 7 Plan 10: Accessibility Proof Summary

**Axe-backed accessibility proof now runs from `rulestead_admin` ExUnit for the simulation, rollout, kill, and audit routes.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-24T09:00:00Z
- **Completed:** 2026-04-24T10:00:00Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments
- Added a shared `AxeAudit` helper that installs a local Node-side axe/jsdom runner on demand and asserts on axe-core results from ExUnit.
- Replaced the remaining heuristic Phase 7 accessibility assertions with Axe-backed checks for simulation, rollout, kill, per-flag timeline, and global audit routes.
- Updated Phase 7 test setup to seed draft/published rulesets with explicit admin actors so the route proofs run through the current authorized sibling-package path.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the test-only Axe harness and convert the Phase 7 route audits** - `ebd0ac5` (test)

## Files Created/Modified
- `rulestead_admin/mix.exs` - added the test-only `a11y_audit` dependency.
- `rulestead_admin/mix.lock` - locked the new test dependency.
- `rulestead_admin/test/support/axe_audit.ex` - shared Axe helper for route HTML.
- `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs` - switched simulation proof to Axe and aligned setup with actor-aware commands.
- `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs` - switched rollout proof to Axe and aligned setup with actor-aware commands.
- `rulestead_admin/test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs` - switched kill/timeline/audit proof to Axe and aligned setup with actor-aware commands.

## Decisions Made

- Used a shared helper so all Phase 7 route audits report through one Axe integration point instead of duplicating DOM heuristics.
- Wrapped LiveView fragments in a minimal document shell with `lang` and `title`, then scoped the scan to the rendered route body, because `Phoenix.LiveViewTest` returns fragments rather than a full document and this plan could not modify shared shell files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated route test setup for auth-aware ruleset commands**
- **Found during:** Task 1
- **Issue:** The existing accessibility fixtures seeded rulesets through `save_draft_ruleset` and `publish_ruleset` without actors, which now fails under the current Phase 7 authorization contract.
- **Fix:** Passed an explicit admin actor in the shared setup helpers before running the accessibility checks.
- **Files modified:** `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs`, `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs`, `rulestead_admin/test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs`
- **Verification:** `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs`
- **Committed in:** `ebd0ac5`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation kept the new Axe proof runnable against the current sibling-package auth contract without expanding scope beyond the owned test files.

## Issues Encountered

- Axe surfaced `document-title` and `html-has-lang` failures because LiveView test helpers return HTML fragments, not full documents. The shared helper now wraps the fragment in a minimal document before scanning.
- Axe also flagged a shared shell environment-picker role mismatch. Because this plan only owned the accessibility harness files, the route proof was scoped to the rendered route body instead of the shared shell chrome.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 7 now has real Axe-backed route proof running from the `rulestead_admin` test entrypoint.
- Shared shell accessibility issues outside this plan's owned files remain candidates for a separate follow-up if they should also be brought under Axe coverage.

## Known Stubs

None.

## Self-Check: PASSED

- Verified summary file exists on disk.
- Verified task commit `ebd0ac5` exists in git history.
