---
phase: 74-api-stability-catalog-sync
plan: 74-02
subsystem: testing
tags: [release-contract, api-stability, drift-guards, post-ga-band]

requires:
  - phase: 74-01
    provides: Reconciled api_stability.md catalog prose
provides:
  - Bidirectional code→doc and doc→code catalog guards in release_contract_test.exs
  - Runtime export subset check against documented facade catalog
  - product-boundary Runtime semver assertions in post_ga_band_contract_test.exs
affects: [phase-75-verify-phase74]

tech-stack:
  added: []
  patterns:
    - "Substring asserts on backtick-wrapped function atoms and module strings"
    - "MapSet.subset? guard ties Runtime exports to documented facade list"

key-files:
  created: []
  modified:
    - rulestead/test/rulestead/release_contract_test.exs
    - rulestead/test/rulestead/post_ga_band_contract_test.exs

key-decisions:
  - "Arity-qualified catalog asserts (`name/arity`) match doc format over bare function names"
  - "Runtime semver band assert lives in post_ga_band_contract_test for readability"

patterns-established:
  - "@documented_* module attributes as single source for doc→code facade guards"

requirements-completed: [API-02, VER-03]

duration: 10 min
completed: 2026-05-28
---

# Phase 74 Plan 02: Bidirectional API Stability Drift Guards Summary

**release_contract_test.exs now asserts every @root_exports name, Store callback, Policy callback, Error type, and config key appears in api_stability.md, plus doc→code guards for Runtime and TestHelpers facades.**

## Performance

- **Duration:** 10 min
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `@documented_supported_facades`, `@documented_runtime_functions`, `@documented_test_helper_functions`
- New test `"documented public surfaces stay listed in the api stability contract"`
- New test `"supported adopter facades documented in api stability match the closed runtime catalog"`
- Extended post_ga_band_contract_test with Runtime semver / 0.1.x assertions

## Task Commits

1. **Task 74-02-01: Add module attributes and code→doc catalog tests** — pending atomic commit
2. **Task 74-02-02: Add doc→code facade guards and product-boundary assert** — pending atomic commit

## Files Created/Modified

- `rulestead/test/rulestead/release_contract_test.exs` — bidirectional catalog guards
- `rulestead/test/rulestead/post_ga_band_contract_test.exs` — Runtime semver band assert

## Self-Check: PASSED

- `mix test test/rulestead/release_contract_test.exs` — 25 tests, 0 failures
- `mix test test/rulestead/post_ga_band_contract_test.exs` — 2 tests, 0 failures
