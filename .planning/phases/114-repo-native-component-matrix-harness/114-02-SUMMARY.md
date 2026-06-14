---
phase: 114-repo-native-component-matrix-harness
plan: 02
subsystem: testing
tags: [playwright, phoenix, admin-ui, design-system, browser-evidence]

requires:
  - phase: 114-repo-native-component-matrix-harness
    provides: Demo-hosted Phoenix matrix route and stable data-matrix-section selectors from Plan 01
provides:
  - Curated Playwright matrix browser evidence across themes, viewports, reduced motion, keyboard, overflow, and screenshots
  - Static fixture preservation checks for token and theme guard inputs
  - Mobile containment fixes needed for no page-level overflow evidence
affects: [phase-115, phase-116, phase-117, phase-118, DSM-02, VER-01, VER-02]

tech-stack:
  added: []
  patterns:
    - Playwright browser contexts use backendUrl, demo sign-in, localStorage theme pinning, and testInfo.outputPath screenshots
    - Screenshot evidence remains artifact-only with no checked-in pixel baselines

key-files:
  created:
    - examples/demo/frontend/tests/ui-matrix.spec.ts
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css

key-decisions:
  - "Use curated Playwright screenshots and deterministic assertions instead of visual snapshot tooling."
  - "Keep static token/theme fixture specs as low-level guards alongside the repo-native Phoenix matrix."
  - "Fix matrix-exposed mobile overflow at the component CSS level so the browser assertion proves real behavior."

patterns-established:
  - "Matrix evidence names screenshot artifacts as ui-matrix-{section}-{theme}-{viewport}-{motion}.png."
  - "Matrix browser coverage scopes command-palette role assertions to #rs-cmdk to avoid unrelated native options."

requirements-completed: [DSM-02]

duration: 11min
completed: 2026-06-14
---

# Phase 114 Plan 02: Repo-Native Component Matrix Harness Summary

**Playwright evidence for the real Phoenix admin UI matrix across theme, viewport, reduced-motion, keyboard, overflow, screenshot, and static-fixture preservation paths.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-14T05:07:31Z
- **Completed:** 2026-06-14T05:18:55Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `ui-matrix.spec.ts` with light, dark, system-dark, desktop, mobile, and reduced-motion browser contexts for `/dev/rulestead-admin/ui-matrix`.
- Asserted `.rs-shell`, every representative matrix section, no page-level horizontal overflow, artifact screenshot creation, and command palette keyboard/focus behavior.
- Preserved existing static token/theme fixture coverage and added source/file assertions preventing baseline-maintenance tooling drift.

## Task Commits

1. **Task 1: Add matrix browser context and section coverage** - `5929d17` (test)
2. **Task 2: Add static-fixture preservation and keyboard/focus proof** - `2b3eb78` (test)

**Plan metadata:** pending final docs/state commit

## Files Created/Modified

- `examples/demo/frontend/tests/ui-matrix.spec.ts` - Curated Playwright evidence for the Phoenix matrix route, browser contexts, sections, screenshots, overflow, command palette behavior, static fixture preservation, and negative source guard.
- `rulestead_admin/priv/static/css/rulestead_admin.css` - Narrow containment fixes for long code, mutation-confirm, timeline/raw-detail, card, and dense-table content exposed by the mobile matrix evidence.

## Decisions Made

- Used `testInfo.outputPath(...)` screenshot artifacts only; no snapshot, pixel-diff, Storybook, or PhoenixStorybook tooling was added.
- Used the existing demo backend sign-in and theme localStorage pattern from `brand-ui-evidence.spec.ts`.
- Used the demo test database/server on `http://localhost:4003` for verification because an unrelated Docker listener already owned port 4000.

## Verification

- `DEMO_BACKEND_URL=http://localhost:4003 npm run test:e2e -- ui-matrix.spec.ts` - passed, 10/10 tests.
- `npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` - passed, 29/29 tests.
- `test -f rulestead_admin/priv/static/design-system.html` - passed.
- `test -f rulestead_admin/priv/static/theme-control-harness.html` - passed.
- `test -f rulestead_admin/priv/static/theme-harness.html` - passed.
- `! rg -q 'toHaveScreenshot|matchSnapshot|pixelmatch|visual-diff|Storybook|PhoenixStorybook' examples/demo/frontend/tests/ui-matrix.spec.ts` - passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed mobile page-level overflow exposed by matrix evidence**
- **Found during:** Task 1 (Add matrix browser context and section coverage)
- **Issue:** The required mobile no-overflow assertion failed with 246px of root overflow from long raw JSON, mutation-confirm, and dense-table matrix content.
- **Fix:** Added narrow CSS containment and breakability for cards, code tokens, raw-detail pre blocks, timeline items, mutation-confirm rows, and dense tables.
- **Files modified:** `rulestead_admin/priv/static/css/rulestead_admin.css`
- **Verification:** `DEMO_BACKEND_URL=http://localhost:4003 npm run test:e2e -- ui-matrix.spec.ts` passed 10/10 after the fix.
- **Committed in:** `5929d17`

**2. [Rule 3 - Blocking] Used isolated test-mode backend verification after local dev DB/server mismatch**
- **Found during:** Task 1 verification
- **Issue:** Port 4000 was owned by an unrelated Docker listener that did not serve the new route, and the dev database migration state was inconsistent with missing `rulestead.environments`.
- **Fix:** Prepared the demo test database with package migrations and seeds, then ran Phoenix in test mode on `PORT=4003` with `DEMO_BACKEND_URL=http://localhost:4003`.
- **Files modified:** none
- **Verification:** Matrix route returned 200 and the Playwright matrix spec passed.
- **Committed in:** not applicable

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocker).
**Impact on plan:** The fixes preserved the planned browser evidence scope and avoided weakening acceptance criteria.

## Issues Encountered

- The first matrix run found real mobile overflow. It was fixed before Task 1 was committed.
- A stale/incompatible local dev backend environment blocked direct use of port 4000. Verification used an isolated test-mode backend on port 4003.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - placeholder-related token names in CSS are existing design-system token names, not UI data stubs.

## Threat Flags

None - this plan added browser tests and CSS containment only; it did not add new endpoints, auth paths, file-access behavior in production code, schemas, or network surfaces beyond the planned Playwright route access.

## TDD Gate Compliance

The plan marked both tasks `tdd="true"`, but the deliverable was a Playwright evidence spec rather than production logic behind a separate test. Each task was committed as a test/evidence increment after failing live acceptance checks were observed and fixed; no separate RED/GREEN commit pair was applicable.

## Next Phase Readiness

Phase 115 can use `ui-matrix.spec.ts` and the `/dev/rulestead-admin/ui-matrix` route as a stable foundation-hardening evidence target. The matrix now proves mobile no-overflow for the exposed long-label, raw-detail, mutation-confirm, and dense-table cases.

## Self-Check: PASSED

- Created file exists: `examples/demo/frontend/tests/ui-matrix.spec.ts`.
- Modified file exists: `rulestead_admin/priv/static/css/rulestead_admin.css`.
- Task commits exist: `5929d17` and `2b3eb78`.
- Final verification commands passed before summary creation.

---
*Phase: 114-repo-native-component-matrix-harness*
*Completed: 2026-06-14*
