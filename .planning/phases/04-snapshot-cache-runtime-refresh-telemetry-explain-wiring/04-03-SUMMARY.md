---
phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
plan: 03
subsystem: rulestead-runtime
tags:
  - runtime
  - snapshot-cache
  - refresh
  - pubsub
  - startup
requires:
  - 04-01
provides:
  - supervised runtime ownership
  - degraded startup semantics
  - pubsub-plus-poll refresh worker
affects:
  - STORE-03
  - STORE-05
tech_stack:
  added:
    - phoenix_pubsub
  patterns:
    - per-environment refresh workers
    - last-known-good stale serving
    - explicit degraded runtime diagnostics
key_files:
  created:
    - rulestead/lib/rulestead/application.ex
    - rulestead/lib/rulestead/runtime/config.ex
    - rulestead/lib/rulestead/runtime/supervisor.ex
    - rulestead/lib/rulestead/runtime/refresh.ex
    - rulestead/test/rulestead/runtime/startup_test.exs
    - rulestead/test/rulestead/runtime/refresh_test.exs
  modified:
    - rulestead/lib/rulestead/runtime.ex
    - rulestead/lib/rulestead/runtime/cache.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/fake/control.ex
    - rulestead/lib/rulestead/result.ex
    - rulestead/mix.exs
    - rulestead/mix.lock
decisions:
  - Runtime startup now registers environment-local degraded state before the first successful refresh.
  - Refresh ownership moved into supervised per-environment workers that subscribe to version-only PubSub invalidations and poll as a correctness backstop.
  - Refresh failures preserve the previously applied snapshot and surface stale status instead of clearing ETS state.
metrics:
  completed_at: 2026-04-23T20:56:43Z
  task_commits:
    - d6052ab
    - dca870b
    - 8e86300
    - 2221b63
---

# Phase 04 Plan 03: Runtime Refresh and Startup Summary

Supervised runtime ownership now boots independently of host-app process order, exposes explicit degraded diagnostics before the first successful snapshot fetch, and keeps serving last-known-good ETS snapshots while refresh attempts fail.

## Tasks Completed

| Task | Outcome | Commits |
| --- | --- | --- |
| 1 | Added `Rulestead.Application`, runtime config/supervision, degraded startup semantics, and stale-startup coverage. | `d6052ab`, `dca870b` |
| 2 | Added `Rulestead.Runtime.Refresh`, PubSub wake-ups, polling fallback, fake store failure controls, and refresh/backoff coverage. | `8e86300`, `2221b63` |

## Verification

- `cd rulestead && mix test test/rulestead/runtime/startup_test.exs`
- `cd rulestead && mix test test/rulestead/runtime/refresh_test.exs test/rulestead/runtime/startup_test.exs`
- `cd rulestead && mix test test/rulestead/runtime/refresh_test.exs test/rulestead/runtime/startup_test.exs test/rulestead/runtime/runtime_test.exs test/rulestead/runtime/diagnostics_test.exs test/rulestead/result_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `Result` nil normalization**
- **Found during:** Task 1 verification
- **Issue:** `%Rulestead.Result{variant: nil}` normalized into the string `"nil"`, which broke degraded runtime projections.
- **Fix:** Added an explicit `nil` normalization branch before atom normalization.
- **Files modified:** `rulestead/lib/rulestead/result.ex`
- **Commit:** `dca870b`

**2. [Rule 3 - Blocking Issue] Added `phoenix_pubsub` to support real wake-up delivery**
- **Found during:** Task 2 RED phase
- **Issue:** The plan required Phoenix.PubSub wake-ups, but the dependency was not present in the package.
- **Fix:** Added `{:phoenix_pubsub, "~> 2.1"}` and refreshed `mix.lock` before implementing the worker/tests.
- **Files modified:** `rulestead/mix.exs`, `rulestead/mix.lock`
- **Commit:** `8e86300`

## Known Stubs

None.

## Threat Flags

None beyond the plan's existing startup-order and refresh-failure threat model.

## Self-Check: PASSED

- Found `.planning/phases/04-snapshot-cache-runtime-refresh-telemetry-explain-wiring/04-03-SUMMARY.md`
- Found commit `d6052ab`
- Found commit `dca870b`
- Found commit `8e86300`
- Found commit `2221b63`
