---
phase: 114-repo-native-component-matrix-harness
plan: 01
subsystem: ui
tags: [phoenix, liveview, exunit, admin-ui, design-system]

requires:
  - phase: 113-design-system-inventory-ui-matrix-contract
    provides: UI matrix contract, required stress states, and evidence dimensions
provides:
  - Demo-hosted dev/test Phoenix UI matrix route
  - Deterministic fixed fixture assigns for real admin components
  - ExUnit route, fixture-health, and source-boundary coverage
affects: [phase-114-plan-02, phase-115, phase-116, phase-117, phase-118, DSM-02]

tech-stack:
  added: []
  patterns:
    - Demo-hosted LiveView harness outside RulesteadAdmin.Router.rulestead_admin/2
    - Centralized bounded synthetic fixture helpers for component evidence

key-files:
  created:
    - examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex
    - examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex
    - examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs
  modified:
    - examples/demo/backend/lib/rulestead_demo_web/router.ex
    - examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex

key-decisions:
  - "Matrix route is demo-hosted and dev/test gated at /dev/rulestead-admin/ui-matrix."
  - "The matrix renders real RulesteadAdmin.Components.* modules inside Shell.page/1 instead of copied static HEEx."
  - "Fixture data is synthetic, explicit, bounded, and kept under examples/demo/backend."

patterns-established:
  - "Use stable data-matrix-section selectors for downstream browser evidence."
  - "Verify matrix scope with source-boundary tests against the demo router and package router."

requirements-completed: [DSM-02]

duration: 8min
completed: 2026-06-14
---

# Phase 114 Plan 01: Repo-Native Component Matrix Harness Summary

**Demo-hosted Phoenix LiveView matrix rendering real admin components with deterministic stress fixtures and source-boundary tests.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-14T04:55:45Z
- **Completed:** 2026-06-14T05:03:04Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `RulesteadDemoWeb.UiMatrixFixtures` with bounded synthetic assigns for shell, primitives, composites, mutation flows, dense rows, audit/timeline, rule editor, rollout, governance, simulate, rare-state, and static-fixture sections.
- Added `/dev/rulestead-admin/ui-matrix` as a dev/test-only demo backend LiveView route outside the mounted admin package router.
- Added focused ExUnit coverage proving route reachability, `.rs-shell`, required `data-matrix-section` selectors, real component output, fixture health, and package-router/source boundaries.

## Task Commits

1. **Task 1: Create deterministic matrix fixture assigns** - `8a1b46e` (feat)
2. **Task 2: Add the demo-hosted LiveView matrix route** - `3378b84` (feat)
3. **Task 3: Add ExUnit route, source-boundary, and fixture-health coverage** - `3a17842` (test)

## Files Created/Modified

- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - Centralized deterministic synthetic fixture helpers for matrix sections and stress states.
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - Shell-wrapped LiveView matrix rendering real `RulesteadAdmin.Components.*`.
- `examples/demo/backend/lib/rulestead_demo_web/router.ex` - Dev/test-gated `/dev/rulestead-admin/ui-matrix` route outside the `/admin` mounted package scope.
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - Route smoke, fixture-health, source-boundary, and negative tooling assertions.

## Decisions Made

- Kept the matrix in the demo host and did not modify `rulestead_admin/lib/rulestead_admin/router.ex`.
- Used explicit fixture helper functions instead of component discovery so the render surface is deterministic and bounded.
- Left CSS/foundation/component polish untouched; this plan establishes evidence harness coverage for later phases.

## Verification

- `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` - passed, 3 tests / 0 failures.
- `cd examples/demo/backend && mix compile` - passed.
- `rg -q 'if Mix\.env\(\) in \[:dev, :test\] do' examples/demo/backend/lib/rulestead_demo_web/router.ex` - passed.
- `rg -q 'live "/ui-matrix", UiMatrixLive, :index' examples/demo/backend/lib/rulestead_demo_web/router.ex` - passed.
- `! rg -q 'ui-matrix' rulestead_admin/lib/rulestead_admin/router.ex` - passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed fixture shapes required by real component rendering**
- **Found during:** Task 3 (route smoke test)
- **Issue:** The first route render exposed invalid fixture shapes for `Shell.page/1`, `GovernanceComponents.blast_radius_panel/1`, and `AuditComponents.timeline_item/1`.
- **Fix:** Wrapped shell env options with `:environment`, changed policy capabilities to the shell capability map, made governance breach reasons structured maps, and added explicit nil rollback IDs to audit entries.
- **Files modified:** `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex`
- **Verification:** `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` passed.
- **Committed in:** `3a17842`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** The fix kept the planned scope intact and made the matrix prove real component compatibility instead of merely compiling.

## Issues Encountered

- Initial focused ExUnit run failed on real component assign-shape mismatches and an incorrect source-test path. Both were fixed before committing Task 3.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all empty, loading, error, unavailable, denied, and read-only examples are intentional deterministic matrix states.

## Next Phase Readiness

Plan 02 can add Playwright browser evidence against `/dev/rulestead-admin/ui-matrix` using the stable section selectors and real shell/component output from this plan.

## Self-Check: PASSED

- Created files exist: `ui_matrix_fixtures.ex`, `ui_matrix_live.ex`, and `ui_matrix_live_test.exs`.
- Task commits exist: `8a1b46e`, `3378b84`, and `3a17842`.
- Final plan-level verification commands passed before summary creation.

---
*Phase: 114-repo-native-component-matrix-harness*
*Completed: 2026-06-14*
