---
phase: 06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle
plan: 03
subsystem: rulestead-admin-package-foundation
tags: [phase-6, admin, liveview, routing]
requires: [ADMIN-08, ADMIN-10]
provides: [mounted-admin-package, policy-aware-live-session, shared-admin-shell]
affects:
  - rulestead_admin/mix.exs
  - rulestead_admin/lib/rulestead_admin/application.ex
  - rulestead_admin/lib/rulestead_admin/router.ex
  - rulestead_admin/lib/rulestead_admin/live/session.ex
  - rulestead_admin/lib/rulestead_admin/components/shell.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex
  - rulestead_admin/test/test_helper.exs
  - rulestead_admin/test/support/conn_case.ex
  - rulestead_admin/test/rulestead_admin/router_test.exs
  - rulestead_admin/test/rulestead_admin/live/session_test.exs
decisions:
  - Require an explicit `policy:` option in the router macro and route all mounted screens through one shared LiveView session hook.
  - Treat `env` in the URL as canonical state; when the URL carries an invalid environment, fall back to the default environment instead of remembered state.
  - Reserve `/new` and `/:key/edit` route space now while keeping Phase 7 surfaces out of the package.
metrics:
  completed_at: 2026-04-23
---

# Phase 06 Plan 03: Admin Package Foundation Summary

`rulestead_admin` now mounts as a real Phoenix LiveView package with a host-policy seam, centralized environment/session normalization, a shared shell with explicit production emphasis, and compile-safe placeholder screens for the Phase 6 list, detail, and rules surfaces.

## What Changed

- Added Phoenix, Phoenix HTML, Phoenix LiveView, and LazyHTML test support to `rulestead_admin`, plus a minimal application supervisor with package-local PubSub.
- Added a package-local test endpoint/router harness so the admin package can verify route/session wiring without copying the runtime/store setup into a second place.
- Replaced the router stub with a real `rulestead_admin/2` mount macro that requires `policy:`, opens a shared `live_session`, and mounts only the Phase 6 list/detail/rules route set plus the reserved `/new` and `/:key/edit` placeholders.
- Added `RulesteadAdmin.Live.Session` to centralize actor lookup, environment normalization, canonical URL `env` handling, remembered-env fallback, and policy-aware `on_mount` assignment.
- Added `RulesteadAdmin.Components.Shell` with one global environment picker and explicit production styling.
- Added compile-safe placeholder LiveViews for flag list, flag detail, and rules workspace so later Phase 6 plans can fill behavior in without changing the mount/session contract.
- Expanded route/session coverage with a TDD flow: a failing test gate for the mount seam and a passing suite for router expansion, env resolution, and shell rendering.

## Verification

- `cd rulestead_admin && mix test test/rulestead_admin_test.exs test/rulestead_admin/router_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs test/rulestead_admin/live/session_test.exs`

Both verification commands passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical correctness] Invalid URL environment no longer falls through to remembered state**
- **Found during:** Task 2 verification
- **Issue:** An invalid `?env=` value was incorrectly reusing the remembered environment, which violated the plan’s canonical-URL rule and could hide environment scope.
- **Fix:** Changed shared session resolution so an invalid URL environment falls back to the default environment directly.
- **Files modified:** `rulestead_admin/lib/rulestead_admin/live/session.ex`
- **Commit:** `0397d6e`

## Residual Risks

- Verification still emits pre-existing Phase 06-02 behaviour warnings from the sibling `rulestead` package (`Rulestead.Store.Ecto` and `Rulestead.Fake` missing new Phase 6 callbacks). Those warnings are outside the 06-03 write scope and did not block the admin package tests.
- Resolving the new Phoenix dependencies generated local `rulestead_admin/mix.lock`, `deps/`, and `_build/` artifacts. They were needed to run verification, but they are outside this plan’s allowed write scope and are not part of this summary’s affected-file list.

## Known Stubs

- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`: placeholder content only; real list search/filter/pagination lands in 06-04.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`: placeholder content only; real flag detail content lands in 06-04.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex`: placeholder content only; real rules workspace lands in 06-05.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-03-SUMMARY.md`.
- Task commits recorded:
  - `d96cf1e` `feat(06-03): add admin liveview package wiring`
  - `d0a9a9c` `test(06-03): add failing admin mount seam coverage`
  - `0397d6e` `feat(06-03): mount admin liveview placeholder screens`
