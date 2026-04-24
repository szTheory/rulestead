---
phase: 06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle
plan: 02
subsystem: rulestead-core-admin-payloads
tags: [phase-6, admin, lifecycle, pagination, telemetry]
requires: [ADMIN-01, ADMIN-02, LIFE-02, LIFE-03, LIFE-04]
provides: [root-admin-payloads, adapter-parity, stale-tracker, archived-runtime-exclusion]
affects:
  - rulestead/lib/rulestead.ex
  - rulestead/lib/rulestead/admin/stale_tracker.ex
  - rulestead/lib/rulestead/application.ex
  - rulestead/lib/rulestead/store/ecto.ex
  - rulestead/lib/rulestead/fake.ex
  - rulestead/test/rulestead/admin_test.exs
  - rulestead/test/rulestead/store_ecto_admin_test.exs
  - rulestead/test/rulestead/integration/admin_lifecycle_runtime_test.exs
decisions:
  - Keep Phase 6 list, detail, metadata mutation, and environment payload shaping behind the `Rulestead` root facade instead of introducing a second public admin API.
  - Feed lifecycle freshness from evaluation telemetry through a supervised, bounded stale tracker so runtime evaluation stays decoupled from store writes.
  - Exclude archived flags from regenerated runtime snapshots so archive is enforced in both admin writes and runtime evaluation.
metrics:
  completed_at: 2026-04-23
---

# Phase 06 Plan 02: Adapter Payloads And Stale Tracker Summary

Phase 6 now has real adapter-backed admin payloads and lifecycle freshness wiring: `Rulestead` serves list/detail metadata payloads with fake/Ecto parity, archived flags stay read-only and out of runtime evaluation, and stale classification is updated from bounded telemetry rather than from the evaluator hot path.

## What Changed

- Implemented Phase 6 list/detail/create/update/environment/evaluation verbs behind the `Rulestead` root facade with cursor-aware payload handling that works for both fake and Ecto adapters.
- Expanded `Rulestead.Store.Ecto` to build dense admin list and detail payloads with lifecycle classification, active-versus-draft ruleset summaries, recent owners, per-environment cards, cursor pagination, archive enforcement, and evaluation freshness persistence.
- Brought `Rulestead.Fake` to parity with the same lifecycle, cursor, metadata, and archive semantics used by the Ecto adapter.
- Added `Rulestead.Admin.StaleTracker` as a supervised telemetry consumer that debounces evaluation freshness writes and records only bounded lifecycle inputs.
- Added integration proof that archive regenerates runtime snapshots and removes archived flags from runtime lookup and evaluation.

## Verification

- `cd rulestead && mix test test/rulestead/admin_test.exs test/rulestead/store_ecto_admin_test.exs`
- `cd rulestead && mix test test/rulestead/integration/admin_lifecycle_runtime_test.exs`

Both verification commands passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added test-local schema guard for pending Phase 6 fields**
- **Found during:** Task 1 verification
- **Issue:** The current test database schema did not yet expose the `flags.permanent` and `flag_environments.last_evaluated_at` fields needed by the new Ecto admin payload tests.
- **Fix:** Added `ensure_phase6_schema!/0` in the Ecto admin test setup to add those columns when absent before seeding test data.
- **Files modified:** `rulestead/test/rulestead/store_ecto_admin_test.exs`

## Residual Risks

- The Ecto admin suite currently applies a test-local schema guard because the local test database had not already run the Phase 6 migration. Once the migration path is exercised consistently in CI and local setup, that guard may become redundant.
- The stale tracker is intentionally bounded and debounced; if evaluation traffic patterns change materially, the queue limit and flush interval may need retuning rather than more direct writes from runtime.

## Known Stubs

None in the owned files.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-02-SUMMARY.md`.
- Verified implementation commits exist:
  - `512186e` `test(06-02): add failing admin facade and lifecycle runtime coverage`
