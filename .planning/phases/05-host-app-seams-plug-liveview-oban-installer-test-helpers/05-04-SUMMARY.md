---
phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
plan: 04
subsystem: install-proof
tags: [integration, golden, installer, phoenix, fixtures]
requires:
  - 05-02
provides:
  - fresh Phoenix app install and boot proof
  - normalized golden stdout contract
  - normalized installed tree fixture contract
  - paired installer idempotency proof
affects:
  - INST-03
  - phase-05-installer
  - regression-proof
tech-stack:
  added: []
  patterns:
    - shared tmp-app fixture orchestration
    - timestamp-normalized golden fixtures
    - paired rerun idempotency verification
key-files:
  created:
    - rulestead/test/rulestead/integration/install_golden_test.exs
    - rulestead/test/support/install_fixture.ex
    - rulestead/test/fixtures/install_golden/STDOUT.txt
    - rulestead/test/fixtures/install_golden/tree/config/config.exs
    - rulestead/test/fixtures/install_golden/tree/config/rulestead.exs
    - rulestead/test/fixtures/install_golden/tree/lib/host_app_web/endpoint.ex
    - rulestead/test/fixtures/install_golden/tree/lib/host_app_web/router.ex
    - rulestead/test/fixtures/install_golden/tree/priv/repo/migrations/TIMESTAMP_create_rulestead_authoring_tables.exs
    - rulestead/test/fixtures/install_golden/tree/priv/repo/migrations/TIMESTAMP_seed_default_environments.exs
    - rulestead/test/fixtures/install_golden/tree/priv/repo/migrations/TIMESTAMP_create_rulestead_runtime_snapshots.exs
  modified:
    - rulestead/test/rulestead/integration/install_smoke_test.exs
decisions:
  - Kept the proof Phase-5-scoped by asserting install wiring, bootability, and `/admin/flags` mount insertion without making any Phase 6 UI claims.
  - Centralized generator, dependency injection, repo config, stdout normalization, and tree normalization in `Rulestead.Test.InstallFixture` so smoke and golden tests share one orchestration path.
  - Normalized migration timestamps and generated salts in fixture output to keep the golden contract stable across reruns.
metrics:
  completed_at: 2026-04-24T01:47:17Z
  verification_commands:
    - cd rulestead && mix test test/rulestead/integration/install_smoke_test.exs --timeout 300000
    - cd rulestead && mix test test/rulestead/integration/install_golden_test.exs --include golden --timeout 300000
---

# Phase 05 Plan 04 Summary

Phase 5 now has end-to-end installer proof against a real generated Phoenix app plus a byte-stable golden contract for both stdout and the installed file tree.

## What Shipped

- Refactored the fresh-app smoke test onto `Rulestead.Test.InstallFixture`, which generates a Phoenix host app, injects sibling package deps, runs `mix rulestead.install --yes`, migrates the DB, and verifies the installed host seam.
- Added `install_golden_test.exs` with normalized stdout and normalized tree comparisons, plus a paired second-run idempotency assertion that requires all rerun lines to be `skip ...`.
- Captured the normalized golden fixtures under `test/fixtures/install_golden/`, covering `config/config.exs`, `config/rulestead.exs`, the endpoint/router injections, and the Phase 5 migration files.

## Verification

- `cd rulestead && mix test test/rulestead/integration/install_smoke_test.exs --timeout 300000`
- `cd rulestead && mix test test/rulestead/integration/install_golden_test.exs --include golden --timeout 300000`
- `cd rulestead && mix test test/rulestead/plug_test.exs test/rulestead/live_view_test.exs test/rulestead/oban_test.exs test/rulestead/test_helpers_test.exs test/rulestead/telemetry_test.exs test/rulestead/mix/tasks/rulestead_install_test.exs test/rulestead/integration/install_smoke_test.exs test/rulestead/integration/install_golden_test.exs --include golden --timeout 300000`

## Known Stubs

- The `/admin/flags` seam is still the Phase 5 compile-safe mount only. Real admin UI routes remain deferred to Phase 6.

## Self-Check

PASSED
