---
phase: 64-proof-docs-and-support-truth
plan: 64-01
subsystem: testing
tags: [mix, verify, auto-advance, merge-gate, elixir]

requires:
  - phase: 63-mounted-auto-advance-workflows
    provides: auto-advance contract tests and admin rollouts/timeline LiveView tests
provides:
  - mix verify.phase64 v1.8 merge gate (phase60 core union + auto-advance delta)
  - preferred_envs registration for verify.phase64
affects: [64-02, 64-03, 64-04, MAINTAINING.md, release_contract_test.exs]

tech-stack:
  added: []
  patterns:
    - "Flat test-path union in verify.phaseNN tasks (no sub-task delegation)"
    - "Orchestration contract tests clear admin_policy and Ecto automation tables between adapters"

key-files:
  created:
    - rulestead/lib/mix/tasks/verify.phase64.ex
  modified:
    - rulestead/mix.exs
    - rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs

key-decisions:
  - "verify.phase64 lists all 22 phase60 core paths plus 5 auto-advance delta paths explicitly"
  - "Admin subprocess includes rollouts_test.exs and timeline_test.exs alongside phase60 admin paths"
  - "Orchestration contract setup deletes admin_policy so production governed defaults apply under AllowPolicy test_helper"

patterns-established:
  - "Phase64 merge gate mirrors phase60 structure: core mix test then rulestead_admin subprocess"

requirements-completed: [VER-01]

duration: 25min
completed: 2026-05-27
---

# Phase 64 Plan 01: mix verify.phase64 Merge Gate Summary

**v1.8 merge gate runs phase60 regression plus auto-advance contract and admin rollouts/timeline tests in one `mix verify.phase64` command without delegating to sub-tasks.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-27T21:27:00Z
- **Completed:** 2026-05-27T21:32:41Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `Mix.Tasks.Verify.Phase64` with flat union of 27 core test paths (22 phase60 + 5 v1.8 delta) and admin subprocess including rollouts/timeline contract tests.
- Registered `{:"verify.phase64", :test}` in `rulestead/mix.exs` `preferred_envs`.
- Hardened orchestration contract tests for full-suite runs (Ecto table cleanup + `admin_policy` cleared during module setup).

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Mix.Tasks.Verify.Phase64** - `f5a54f2` (feat)
2. **Task 2: Register verify.phase64 in mix.exs preferred_envs** - `e0d2a04` (chore)

## Files Created/Modified

- `rulestead/lib/mix/tasks/verify.phase64.ex` - Phase 64 merge gate task (core union + admin subprocess)
- `rulestead/mix.exs` - `preferred_envs` entry for `verify.phase64`
- `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` - Ecto isolation and `admin_policy` setup for deterministic protected-env proof

## Decisions Made

- Kept phase60 admin paths verbatim and appended only the two v1.8 admin delta paths (rollouts + timeline).
- Avoided any `verify.phase60` reference in source (including comments) per plan verification grep.
- Cleared `admin_policy` in orchestration contract setup so production auto-advance uses Authorizer defaults (`change_request_required?` true) despite `Rulestead.AllowPolicy` in test_helper.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Blocking] Orchestration contract test isolation under full verify.phase64 suite**
- **Found during:** Task 1 (verify.phase64 automated verification)
- **Issue:** `test protected environment submits change request does not auto-advance` failed when run after phase60/contract tests: rollout advanced to 100% instead of submitting a change request. `reset_adapter!(StoreEcto)` was a no-op and `Rulestead.AllowPolicy` forced `change_request_required?` false in production.
- **Fix:** SQL cleanup of automation/governance tables on Ecto reset; delete `admin_policy` in module setup (restore on exit) so production governed defaults apply.
- **Files modified:** `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs`
- **Verification:** `mix verify.phase64` — 183 core tests + 88 admin tests, 0 failures
- **Committed in:** `f5a54f2` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for VER-01 proof command to exit 0; no scope creep beyond test isolation for paths already in the merge gate.

## Issues Encountered

None beyond the isolation fix above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **64-02** (release contract drift guards + README/MAINTAINING/package README updates).
- `mix verify.phase64` is the v1.8 superset merge gate; `mix verify.phase60` remains valid for v1.7-only regression.

## Self-Check: PASSED

- `cd rulestead && mix verify.phase64` → exit 0 (183 + 88 tests, 0 failures)
- `grep -q 'verify.phase64' rulestead/mix.exs` → PASS
- `! grep -q 'verify.phase60' rulestead/lib/mix/tasks/verify.phase64.ex` → PASS
- `mix help verify.phase64` → task loads without error

---
*Phase: 64-proof-docs-and-support-truth*
*Completed: 2026-05-27*
