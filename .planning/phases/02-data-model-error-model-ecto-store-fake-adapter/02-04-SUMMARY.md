---
phase: 02-data-model-error-model-ecto-store-fake-adapter
plan: 04
subsystem: store
tags:
  - fake-adapter
  - contract-tests
  - phase-2
requires:
  - 02-02
  - 02-03
provides:
  - STORE-07
affects:
  - rulestead/lib/rulestead/fake.ex
  - rulestead/lib/rulestead/fake/control.ex
  - rulestead/test/support/store_contract_case.ex
  - rulestead/test/support/store_fixtures.ex
  - rulestead/test/rulestead/store/fake_contract_test.exs
tech_stack:
  - Elixir
  - ExUnit
  - Ecto changesets
patterns_added:
  - shared adapter contract suite
  - fake-control isolation
key_files_created:
  - rulestead/lib/rulestead/fake.ex
  - rulestead/lib/rulestead/fake/control.ex
  - rulestead/test/support/store_contract_case.ex
  - rulestead/test/support/store_fixtures.ex
  - rulestead/test/rulestead/store/fake_contract_test.exs
decisions:
  - Reused the Phase 02-03 schemas and `Rulestead.Ruleset` changeset to validate fake adapter writes instead of introducing fake-only validation shortcuts.
  - Kept reset, clock, seed, and inspection hooks in `Rulestead.Fake.Control` so the shared `Rulestead.Store` behaviour stayed contract-pure.
  - Made the shared contract suite accept adapter-specific control modules so Fake and the later Ecto adapter can run the same assertions against the same fixtures.
metrics:
  completed_at: 2026-04-23T19:11:30Z
  task_commits:
    - 63a43de
    - ed445dd
---

# Phase 2 Plan 04: Fake Adapter Contract Summary

Contract-faithful in-memory authoring store with shared adapter-parity tests rooted in the real ruleset/schema validation semantics.

## Outcome

`Rulestead.Fake` now implements the Phase 2 `Rulestead.Store` callbacks for fetch, draft save, publish, archive, and list. The adapter keeps environment and flag state in-memory, enforces archived read-only behavior, tracks active ruleset versions per environment, and maps invalid writes into the same `%Rulestead.Error{}` taxonomy used by the public store surface.

`Rulestead.Fake.Control` provides the fake-only affordances the plan required: deterministic reset, clock control, seed helpers, and state inspection. Those hooks live outside the shared store behaviour so tests can use them without widening the production contract.

The parity harness now lives in `Rulestead.StoreContractCase` with shared fixture builders in `Rulestead.StoreFixtures`. The contract suite covers:

- draft save and publish round-trip
- invalid ruleset payloads
- variant-weight validation failures
- not-found normalization
- publish/version conflict behavior
- archived/read-only behavior
- duplicate seed-key rejection
- list filtering by environment and query

`Rulestead.Store.FakeContractTest` runs that shared suite directly against the fake adapter and passes with both the default seed and `--seed 0`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Switched fake internal IDs to UUIDs**
- **Found during:** Task 1 verification
- **Issue:** The first fake implementation seeded integer IDs, but `Rulestead.Ruleset.changeset/2` requires `:binary_id` values for `flag_environment_id`.
- **Fix:** Updated fake-seeded flag, environment, and flag-environment IDs to use UUIDs so ruleset validation reuses the real schema semantics cleanly.
- **Files modified:** `rulestead/lib/rulestead/fake.ex`
- **Commit:** `63a43de`

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-04-SUMMARY.md`
- Commit `63a43de` exists in git history
- Commit `ed445dd` exists in git history
