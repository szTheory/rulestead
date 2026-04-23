---
phase: 02-data-model-error-model-ecto-store-fake-adapter
plan: 02
subsystem: api
tags: [elixir, error-model, store-contract, public-api]
requires:
  - phase: 01-repo-bootstrap
    provides: sibling-package layout, strict package boundaries, root public module scaffold
provides:
  - stable Rulestead.Error envelope with typed helper namespaces
  - key-first Rulestead.Store behavior and shared command structs
  - bang/non-bang public wrappers plus reserved evaluate/3 and evaluate!/3 stubs
affects: [phase-02-adapters, phase-03-evaluator, api-stability]
tech-stack:
  added: []
  patterns: [single public error envelope, key-first store commands, root bang/non-bang wrappers]
key-files:
  created:
    - rulestead/lib/rulestead/error.ex
    - rulestead/lib/rulestead/evaluation_error.ex
    - rulestead/lib/rulestead/ruleset_error.ex
    - rulestead/lib/rulestead/kill_switch_error.ex
    - rulestead/lib/rulestead/config_error.ex
    - rulestead/lib/rulestead/store_error.ex
    - rulestead/lib/rulestead/auth_error.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
  modified:
    - rulestead/lib/rulestead.ex
key-decisions:
  - "Keep one concrete %Rulestead.Error{} as the only public runtime and wire error shape."
  - "Model the authoring store as key-first semantic callbacks instead of CRUD or UUID-facing APIs."
  - "Reserve evaluate/3 and evaluate!/3 with typed not-implemented errors so Phase 3 can land without reopening the public convention."
patterns-established:
  - "Error Pattern: typed helper namespaces construct Rulestead.Error rather than defining separate public exception structs."
  - "Store Pattern: adapters implement shared command structs centered on flag_key and environment_key."
  - "API Pattern: root public functions return tuples in non-bang form and raise the same error struct in bang form."
requirements-completed: [ERR-01, ERR-02, ERR-03, ERR-04]
duration: 22 min
completed: 2026-04-23
---

# Phase 2 Plan 02 Summary

**Stable public error and store contracts for Rulestead, with reserved bang/non-bang entrypoints and typed evaluator stubs**

## Performance

- **Duration:** 22 min
- **Started:** 2026-04-23T18:35:00Z
- **Completed:** 2026-04-23T18:56:58Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added `%Rulestead.Error{}` as the single public error envelope, including safe metadata/detail normalization and Jason-safe encoding that excludes `:cause`.
- Added the `Rulestead.Store` key-first behavior and shared command structs for fetch, draft save, publish, archive, and list/search operations.
- Extended `Rulestead` with store-facing bang/non-bang wrappers and explicit `evaluate/3` / `evaluate!/3` reservation via typed not-yet-implemented evaluation errors.

## Task Commits

1. **Task 1: Lock the public error envelope and typed helper namespaces** - `8666308` (`feat`)
2. **Task 2: Define the key-first store behavior and shared command structs** - `2364bfa` (`feat`)
3. **Task 3: Reserve public bang/non-bang conventions, including evaluator stubs** - `0366d42` (`feat`)

## Files Created/Modified

- `rulestead/lib/rulestead/error.ex` - Defines the stable root error struct, leaf atoms, normalization, and JSON-safe encoding.
- `rulestead/lib/rulestead/evaluation_error.ex` - Constructors for evaluation-domain errors, including the Phase 2 evaluator stub.
- `rulestead/lib/rulestead/ruleset_error.ex` - Constructors for ruleset-specific typed errors.
- `rulestead/lib/rulestead/kill_switch_error.ex` - Constructors for kill-switch typed errors.
- `rulestead/lib/rulestead/config_error.ex` - Constructors for config and adapter-configuration typed errors.
- `rulestead/lib/rulestead/store_error.ex` - Constructors for store contract failures and not-found normalization.
- `rulestead/lib/rulestead/auth_error.ex` - Constructors for auth-domain typed errors.
- `rulestead/lib/rulestead/store.ex` - Declares the shared store behavior and result type.
- `rulestead/lib/rulestead/store/command.ex` - Declares the key-first command structs shared by adapters.
- `rulestead/lib/rulestead.ex` - Adds public store wrappers, adapter lookup, bang lifting, and reserved evaluator stubs.
- `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-02-SUMMARY.md` - Records implementation outcome and verification notes.

## Decisions Made

- Used one stable `%Rulestead.Error{}` shape for both tuple and raised failures so later adapters and evaluator work do not introduce parallel error envelopes.
- Let `Rulestead` resolve the configured store adapter from `:store` or `:store_adapter`, then normalize invalid config and invalid adapter responses into typed config/store errors.
- Kept list/search as one `ListFlags` command surface for Phase 2 so later adapters can support search without widening the public behavior.

## Deviations from Plan

None in the owned code surface.

## Known Stubs

- `rulestead/lib/rulestead.ex`: `evaluate/3` and `evaluate!/3` intentionally return or raise a typed `:not_implemented` evaluation error. This is the plan’s required Phase 2 reservation and is expected to be replaced in Phase 3.

## Issues Encountered

- `mix format` could not run in this repo state because the existing formatter config imports dependencies such as `:phoenix` that are not present in `rulestead/mix.exs`. This was pre-existing and outside the owned files for this plan, so verification used `mix compile` and `mix test` instead.
- A parallel `git commit` attempt created a transient `.git/index.lock`; it cleared once the colliding process exited and the remaining task commit was completed serially.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 2 now has a fixed public contract for adapter work and for the Phase 3 evaluator entrypoints.
- The next adapter/evaluator plans can build on the error leaf atoms and store commands without reopening API shape decisions.

## Self-Check: PASSED

- Found `rulestead/lib/rulestead/error.ex`
- Found `rulestead/lib/rulestead/store.ex`
- Found `rulestead/lib/rulestead/store/command.ex`
- Found `rulestead/lib/rulestead.ex`
- Found commit `8666308`
- Found commit `2364bfa`
- Found commit `0366d42`

---
*Phase: 02-data-model-error-model-ecto-store-fake-adapter*
*Completed: 2026-04-23*
