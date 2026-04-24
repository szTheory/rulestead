---
phase: 06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle
plan: 01
subsystem: rulestead-core-admin-contracts
tags: [phase-6, admin, lifecycle, pagination]
requires: [ADMIN-10, LIFE-01, LIFE-03]
provides: [root-admin-facade, host-policy-seam, lifecycle-classifier, lifecycle-persistence]
affects:
  - rulestead/lib/rulestead.ex
  - rulestead/lib/rulestead/admin/policy.ex
  - rulestead/lib/rulestead/admin/lifecycle.ex
  - rulestead/lib/rulestead/store.ex
  - rulestead/lib/rulestead/store/command.ex
  - rulestead/lib/rulestead/flag.ex
  - rulestead/lib/rulestead/flag_environment.ex
  - rulestead/priv/repo/migrations/TIMESTAMP_add_phase6_admin_lifecycle_fields.exs
  - rulestead/test/rulestead/admin_contract_test.exs
  - rulestead/test/rulestead/admin_lifecycle_test.exs
decisions:
  - Keep the public Phase 6 surface on `Rulestead` root verbs instead of introducing a second primary admin API.
  - Keep `Rulestead.Admin.Policy.can?/4` as the single host authorization seam for mounted admin actions.
  - Represent permanent lifecycle explicitly with a boolean and persist `last_evaluated_at` per flag environment.
metrics:
  completed_at: 2026-04-23
---

# Phase 06 Plan 01: Core Admin Contracts Summary

Phase 6 now has the core contract layer the admin package will build against: root-level `Rulestead` admin verbs, the host-owned `Rulestead.Admin.Policy.can?/4` seam, typed cursor-oriented store commands, explicit permanent lifecycle persistence, and a shared lifecycle classifier that derives `:active`, `:potentially_stale`, `:stale`, and `:archived` from persisted data.

## What Changed

- Added `Rulestead.create_flag/1,2`, `update_flag/1,3`, `list_environments/0,1`, and `record_evaluation/1,3` while keeping the public Phase 6 surface on `Rulestead`.
- Added `Rulestead.Admin.Policy` with the required `can?/4` callback shape for host-owned admin authorization.
- Extended `Rulestead.Store` and `Rulestead.Store.Command` with typed Phase 6 commands for create/update lifecycle edits, environment listing, evaluation freshness recording, and cursor-oriented flag listing metadata.
- Added `Rulestead.Admin.Lifecycle` as the shared lifecycle classifier for admin and store code.
- Updated `Rulestead.Flag` to persist `permanent` and reject invalid lifecycle combinations: blank owner, neither expiration nor permanent, or both at once.
- Updated `Rulestead.FlagEnvironment` to persist `last_evaluated_at`.
- Added the Phase 6 migration for `flags.permanent`, the exact-one lifecycle constraint, and `flag_environments.last_evaluated_at`.
- Added focused contract coverage in `admin_contract_test.exs` and `admin_lifecycle_test.exs`.

## Verification

- `cd rulestead && mix test test/rulestead/admin_contract_test.exs`
- `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs`

Both targeted 06-01 test files passed.

## Deviations from Plan

None in owned files. The work stayed inside the declared 06-01 write scope.

## Residual Risks

- `Rulestead.Store.Ecto` and `Rulestead.Fake` do not yet implement the new Phase 6 callbacks, so compiling the targeted tests emits behaviour warnings. That implementation work belongs to Phase 06 plan 06-02.
- The new migration is authored but has not been exercised against a live repo migration run in this plan, since 06-01 verification was limited to the targeted contract and lifecycle unit suites.

## Known Stubs

None in the owned files.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-01-SUMMARY.md`.
- Task commits recorded:
  - `b83aabb` `feat(06-01): add phase 6 admin core contracts`
  - `49dfbd8` `feat(06-01): add lifecycle persistence contracts`
