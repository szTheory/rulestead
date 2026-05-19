---
phase: 20
plan: 02
subsystem: runtime
tags: [runtime, invalidation, telemetry]
requires:
  - 20-01
provides:
  - notifier-driven refresh subscriptions
  - invalidation telemetry
affects:
  - runtime refresh workers
  - cluster convergence tests
  - telemetry contract coverage
key_files_modified:
  - rulestead/lib/rulestead/runtime/config.ex
  - rulestead/lib/rulestead/runtime/refresh.ex
  - rulestead/lib/rulestead/runtime/supervisor.ex
  - rulestead/lib/rulestead/fake/control.ex
  - rulestead/lib/rulestead/runtime/cluster_case.ex
  - rulestead/test/rulestead/runtime/refresh_test.exs
  - rulestead/test/rulestead/runtime/cluster_refresh_test.exs
  - rulestead/test/rulestead/telemetry_test.exs
completed_date: "2026-05-17"
---

# Phase 20 Plan 02: Runtime Invalidation Summary

Moved runtime refresh workers onto the notifier seam, added version-gated invalidation handling, and locked an invalidation-specific telemetry family. Runtime workers now subscribe through the configured notifier, ignore stale or duplicate notices, keep serving last-known-good snapshots when refresh after invalidation fails, and expose distinct events for received, ignored, triggered, and failed invalidation paths.

## Verification

- `mix test test/rulestead/runtime/refresh_test.exs test/rulestead/runtime/cluster_refresh_test.exs`
- `mix test test/rulestead/telemetry_test.exs`

## Deviations from Plan

- Updated `Rulestead.Runtime.Config` to inherit the validated host `runtime:` block so the installer-generated Phase 20 wiring is used by the runtime rather than remaining documentation-only.
