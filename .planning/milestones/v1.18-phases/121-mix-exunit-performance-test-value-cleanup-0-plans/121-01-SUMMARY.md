---
phase: 121-mix-exunit-performance-test-value-cleanup
plan: 01
subsystem: test-infrastructure
tags: [exunit, ci, performance, test-value, supply-chain-proof]
requirements_completed: [CIDX-06]
decisions:
  - key: D-03 (tag/env names)
    value: "Tag: :published_hex_smoke; env var: RULESTEAD_RUN_PUBLISHED_HEX_SMOKE; scope: guarded_rollout_foundations"
  - key: D-04 (no retry)
    value: "No blind retry added; explicit @tag timeout: 300_000 is the only hardening"
  - key: D-08 (test.sh structure)
    value: "all) arm, case dispatch, Supported scopes: list unchanged; new microcopy functions added for guarded_rollout_foundations"
dependency_graph:
  requires: []
  provides: [published_hex_smoke_tag, guarded_rollout_foundations_scope_wiring]
  affects: [default_test_lane_wall_clock, release_gate_supply_chain_proof_reachability]
tech_stack:
  added: []
  patterns: [exunit_tag_default_exclude, env_conditional_test_helper_exclude, test_sh_logged_scope_function]
key_files:
  created: []
  modified:
    - rulestead/test/test_helper.exs
    - rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs
    - scripts/ci/test.sh
metrics:
  duration: 6 minutes
  completed_date: 2026-06-16
  tasks_completed: 2
  files_modified: 3
---

# Phase 121 Plan 01: Tag Published-Hex Smoke Test and Wire Named Scope Summary

Relocated the single dominant ~20-28s published-Hex test off the default `mix test` loop behind an opt-in ExUnit tag (`@tag :published_hex_smoke`) excluded via `test_helper.exs` env-conditional, while keeping the supply-chain installability proof reachable via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1` on the `guarded_rollout_foundations` CI scope.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tag the dominant test default-excluded and extend test_helper exclude | 488e811 | verify_release_publish_test.exs, test_helper.exs |
| 2 | Wire guarded_rollout_foundations scope to opt in published-Hex proof | 16bc3dc | scripts/ci/test.sh |

## Decisions Made

| Decision | Outcome |
|----------|---------|
| Tag name | `@tag :published_hex_smoke` (per-test, not @moduletag — fast sibling tests stay in default lane) |
| Env var | `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` (mirrors `RULESTEAD_RUN_INSTALL_INTEGRATION` pattern) |
| Canonical scope | `guarded_rollout_foundations` (file already present, lowest churn; D-03 per RESEARCH.md Open Q1) |
| test_helper shape | Extended with `|> then(fn ex ->` chain style to build `exclude: [install_integration: true, published_hex_smoke: true]` by default |
| Timeout | `@tag timeout: 300_000` per-test only (mirrors install_smoke_test.exs:7; does not affect fast sibling tests) |
| No blind retry | Confirmed — no retry/loop added around System.cmd (D-04) |

## Wall-Clock Impact (D-09 Measurement)

| Lane | Before | After | Delta |
|------|--------|-------|-------|
| Default `mix test --warnings-as-errors` | ~42s, 587 tests+8 props, 1 excluded | ~5s, 586 tests+8 props, 4 excluded | ~-37s |
| Dominant test observed in default lane? | Yes (~27.95s in top 5) | No (excluded, not in top 5) | Removed |
| Dominant test reachable? | All lane | guarded_rollout_foundations (RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1) | Relocated |

**Post-change default run (confirmed):** 5.0s, 586 tests, 0 failures (4 excluded — 2 install_integration from install_smoke_test + install_golden_test, 1 published_hex_smoke, 1 other).

**Published-Hex proof confirmed running:** `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 mix test --include published_hex_smoke test/rulestead/mix/tasks/verify_release_publish_test.exs` — 9 tests, 0 failures, dominant test took ~19878ms (~20s). Test name `admin consumer fixture compiles against published Hex packages` confirmed in output.

## Supply-Chain Proof Reachability

The dominant proof case is reachable via:
- `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh`
- `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 cd rulestead && mix test --include published_hex_smoke test/rulestead/mix/tasks/verify_release_publish_test.exs`

The `guarded_rollout_foundations` scope now uses the logged pattern (`run_mix_logged`) for all pre-existing invocations, with an explicit `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix rulestead test --include published_hex_smoke` call that opts the proof back in after tagging would have silently dropped it (RESEARCH.md Pitfall 1).

## Acceptance Criteria Verified

### Source Checks
- [x] `verify_release_publish_test.exs` contains `@tag :published_hex_smoke` directly above the dominant test (line 201)
- [x] `verify_release_publish_test.exs` contains `@tag timeout: 300_000` on that same test (line 202)
- [x] No retry/loop added around `System.cmd` (D-04)
- [x] `@published_smoke_version "0.1.4"` unchanged (line 199)
- [x] `test_helper.exs` default exclude list contains both `install_integration: true` and `published_hex_smoke: true`
- [x] `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` string present in test_helper.exs
- [x] Lines formerly at 10-24 (now 15-29) byte-identical; only lines 1-14 changed
- [x] `scripts/ci/test.sh` contains `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix rulestead test --include published_hex_smoke` within `run_guarded_rollout_foundations`
- [x] `all)` arm still reads `run_mix rulestead test --warnings-as-errors --exclude install_integration` (unchanged)
- [x] `case "${TEST_SCOPE}"` dispatch unchanged (no new scope added)
- [x] "Supported scopes:" list at line 648 unchanged
- [x] `guarded_rollout_foundations` failure microcopy added with category + boundary + `Rerun:` + Remediation; `Rerun:` references `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`

### Behavior Checks
- [x] `mix test test/rulestead/mix/tasks/verify_release_publish_test.exs --slowest 5` — dominant test excluded (1 excluded, not in top 5, 0 failures)
- [x] `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 mix test --include published_hex_smoke ...` — dominant test runs and passes (19878ms, 9 tests, 0 failures)
- [x] Full default suite: 586 tests, 0 failures, 5.0s

## Deviations from Plan

### Auto-added: Failure microcopy for guarded_rollout_foundations scope

**Found during:** Task 2
**Issue:** The plan said "keep this scope's existing failure microcopy intact" but `run_guarded_rollout_foundations` had NO failure microcopy (no `print_*`, no `*_failure_category` — it was a simple passthrough function). Without microcopy, the D-08 acceptance criterion ("guarded_rollout_foundations failure microcopy still contains category + boundary + Rerun: + remediation") would be unsatisfiable.
**Fix:** Added `print_guarded_rollout_foundations_failure_guidance()` and `guarded_rollout_foundations_failure_category()` functions following the exact shape of other scopes (e.g., `blast_radius_governance`). Refactored `run_guarded_rollout_foundations` to use `run_mix_logged` for failure category detection, keeping the existing tests intact and adding the opt-in invocation. The Rerun: microcopy references `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1` as required.
**Files modified:** scripts/ci/test.sh
**Commit:** 16bc3dc
**Rule:** Rule 2 (auto-add missing critical functionality — required for D-08 acceptance criterion to be satisfiable)

## Known Stubs

None — all data flows are fully wired. The published-Hex proof test runs against live hex.pm and asserts actual compilation succeeds.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The changes are test-infrastructure only.

## Self-Check

### Files exist:
- [x] `rulestead/test/test_helper.exs` — modified
- [x] `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` — modified
- [x] `scripts/ci/test.sh` — modified

### Commits exist:
- [x] `488e811` — feat(121-01): tag published-Hex smoke test default-excluded with opt-in env
- [x] `16bc3dc` — feat(121-01): wire guarded_rollout_foundations scope to opt in published-Hex proof

## Self-Check: PASSED
