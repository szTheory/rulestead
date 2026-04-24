---
phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
plan: 02
subsystem: ui
tags: [phoenix, liveview, admin, audit, rollout, kill-switch]
requires:
  - phase: 06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle
    provides: mounted admin shell, env query-param model, and shared live session seam
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    provides: phase7 admin facade and audit contracts from 07-01
provides:
  - dedicated mounted routes for simulation, rollouts, kill switch, per-flag timeline, and global audit
  - shared operator UI primitives for banners, summary grids, trace shells, confirm shells, and audit placeholders
  - compile-safe placeholder LiveViews that preserve the Phase 6 detail and rules boundaries
affects:
  - rulestead_admin/lib/rulestead_admin/router.ex
  - rulestead_admin/lib/rulestead_admin/live/session.ex
  - rulestead_admin/lib/rulestead_admin/components/operator_components.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex
  - rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex
tech-stack:
  added: []
  patterns:
    - route-backed operator screens stay inside the shared live session and env query model
    - phase 7 placeholder screens use shared operator components instead of screen-local markup
key-files:
  created:
    - rulestead_admin/lib/rulestead_admin/components/operator_components.ex
    - rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex
    - rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
    - rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex
    - rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex
    - rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex
  modified:
    - rulestead_admin/lib/rulestead_admin/router.ex
    - rulestead_admin/lib/rulestead_admin/live/session.ex
    - rulestead_admin/lib/rulestead_admin/components/shell.ex
    - rulestead_admin/test/rulestead_admin/router_test.exs
    - rulestead_admin/test/rulestead_admin/live/session_test.exs
key-decisions:
  - "Phase 7 screens mount as dedicated routes under the existing policy-aware live session rather than extending the Phase 6 detail or rules pages."
  - "The session helper remains the single owner of canonical `?env=` routing, environment links, and route-local policy state for placeholder screens."
  - "Shared operator components ship as honest placeholder primitives so later plans can add behavior without changing route or page ownership."
patterns-established:
  - "Use `Session.placeholder_assigns/2` for route-backed placeholder pages that need page copy, env links, and policy-state framing."
  - "Use `OperatorComponents` for Phase 7-specific UI shells while keeping `Shell.page` as the top-level frame."
requirements-completed: [ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-09]
duration: 25min
completed: 2026-04-24
---

# Phase 07 Plan 02: Route-backed Phase 7 admin screen skeleton

**Mounted Phase 7 routes, shared operator components, and compile-safe placeholder LiveViews for simulation, rollouts, kill switch, timeline, and audit**

## Performance

- **Duration:** 25 min
- **Started:** 2026-04-24T07:52:00Z
- **Completed:** 2026-04-24T08:17:35Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Extended the mounted admin router with dedicated Phase 7 routes while keeping every screen inside the existing policy-aware live session.
- Centralized canonical env path building, per-route env links, and shared policy-state assigns in the session helper for later screens to reuse.
- Added a shared Phase 7 operator component inventory and compile-safe placeholder LiveViews that preserve the Phase 6 detail and rules boundaries.

## Task Commits

1. **Task 1 RED: add route/session contract coverage** - `3423be8` (`test`)
2. **Task 1 GREEN: extend the mounted route set and session helpers** - `2a09536` (`feat`)
3. **Task 2: create shared operator components and page shells** - `6fa5cdc` (`feat`)

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/router.ex` - mounted Phase 7 route set
- `rulestead_admin/lib/rulestead_admin/live/session.ex` - canonical env path, env link, and policy-state helpers
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` - shared Phase 7 banner, summary, trace, confirm, diff, and audit primitives
- `rulestead_admin/lib/rulestead_admin/live/flag_live/{simulate,rollouts,kill,timeline}.ex` - compile-safe per-flag placeholder screens
- `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` - compile-safe global audit placeholder screen
- `rulestead_admin/test/rulestead_admin/{router_test.exs,live/session_test.exs}` - route/session coverage for the Phase 7 skeleton

## Decisions Made

- Kept `?env=` as the canonical selector for every new screen instead of introducing env-in-path routing.
- Reserved each operator workflow as its own route-backed screen so the existing detail and rules surfaces remain focused.
- Used placeholder-only copy throughout the new LiveViews to avoid leaking future Phase 7 feature behavior into this skeleton step.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Renamed `diff_card` assigns to avoid HEEx parsing failure**
- **Found during:** Task 2 verification
- **Issue:** Using `@after` as a HEEx assign name in the shared diff shell caused a compilation error.
- **Fix:** Renamed the diff component assigns to `before_value` and `after_value`.
- **Files modified:** `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`, `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`
- **Verification:** `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs`
- **Committed in:** `6fa5cdc`

---

**Total deviations:** 1 auto-fixed (1 bug). **Impact on plan:** No scope creep; the fix was required to keep the placeholder component inventory compile-safe.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later Phase 7 plans can add feature logic directly to the new route-backed screens without changing routing or session ownership.
- Shared operator primitives now exist for rollout warnings, kill confirmations, trace summaries, and audit placeholders.

## Known Stubs

None.

## Self-Check: PASSED

- Found task commits: `3423be8`, `2a09536`, `6fa5cdc`
- Found summary file: `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-02-SUMMARY.md`
