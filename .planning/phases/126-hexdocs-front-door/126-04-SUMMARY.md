---
phase: 126-hexdocs-front-door
plan: "04"
subsystem: rulestead-core-docs
tags: [hexdocs, moduledoc, documentation, telemetry, config, test-helpers]
dependency_graph:
  requires: []
  provides: [real-moduledoc-test-helpers, real-moduledoc-telemetry, real-moduledoc-config]
  affects: [plan-05-module-groups]
tech_stack:
  added: []
  patterns: [render-frozen-contract-surface, phase-124-precedent]
key_files:
  created: []
  modified:
    - rulestead/lib/rulestead/test_helpers.ex
    - rulestead/lib/rulestead/telemetry.ex
    - rulestead/lib/rulestead/config.ex
decisions:
  - "D-02: TestHelpers moduledoc documents the Supported adopter facade contract (api_stability.md L97-99) — with_flag/3, put_flag/3, clear_flags/0, seed_bucket/3, assert_flag_evaluated/2"
  - "D-03: Telemetry moduledoc documents the locked 1.x public event catalog; Config moduledoc documents the validated host-app seam with NimbleOptions schema"
metrics:
  duration: "1m"
  completed: "2026-06-18"
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 126 Plan 04: Un-hide Core Modules Summary

Flipped three contracted-but-hidden core modules from `@moduledoc false` to real
`@moduledoc`: `Rulestead.TestHelpers` (D-02), `Rulestead.Telemetry`, and
`Rulestead.Config` (D-03). These are prerequisites for plan 05's module groups —
without them the "Testing" and "Telemetry & Config" groups render empty.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Un-hide Rulestead.TestHelpers (D-02) | a70279c | rulestead/lib/rulestead/test_helpers.ex |
| 2 | Un-hide Rulestead.Telemetry and Rulestead.Config (D-03) | c11b7c2 | rulestead/lib/rulestead/telemetry.ex, rulestead/lib/rulestead/config.ex |

## What Was Built

### Task 1 — Rulestead.TestHelpers

Replaced `@moduledoc false` with a real `@moduledoc` documenting:
- Quickstart example (`with_flag/3` block usage and `put_flag/3` test-scoped usage)
- Closed public API catalog: `with_flag/3`, `put_flag/3`, `clear_flags/0`, `seed_bucket/3`, `assert_flag_evaluated/2`
- Notes that `Rulestead.Fake` and `Rulestead.Fake.Control` are internal/not public

This enables the "Testing" module group in plan 05's `groups_for_modules`.

### Task 2 — Rulestead.Telemetry

Replaced `@moduledoc false` (below `# credo:disable-for-this-file`) with a real `@moduledoc` documenting:
- The locked 1.x public event catalog (eval decide stop, scheduled_execution, webhook_outbound)
- `attach_many/4` and `detach/1` usage for adopters
- Stability rules (event names are breaking to remove/rename; additive keys are patch)
- Note that `span/3`, `execute/3`, and `*_metadata` helpers are primarily internal

### Task 2 — Rulestead.Config

Replaced `@moduledoc false` with a real `@moduledoc` documenting:
- Configuration snippet for `config/config.exs`
- Public API: `validate/1`, `validate!/1`, `load/1`, `defaults/0`, `schema/0`
- Defaults table for the six integration points (plug, live_view, oban, runtime, tenancy, environment_key)

Both modules enable the "Telemetry & Config" module group in plan 05's `groups_for_modules`.

## Verification

- `mix docs --warnings-as-errors` exits 0 — no undefined-reference autolink failures
- `release_contract_test.exs` exits 0 — 26 tests, 0 failures (no contract change)
- All three files confirmed: real `@moduledoc` present, `@moduledoc false` absent

## Deviations from Plan

None — plan executed exactly as written. The three `@moduledoc false` replacements follow the exact same "render frozen contract surface" pattern established in Phase 124 for `Rulestead.Context`, `Rulestead.Runtime`, and `Rulestead.Admin.Policy`.

## Known Stubs

None.

## Threat Flags

None — documentation-only changes to existing public modules. No new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

- `rulestead/lib/rulestead/test_helpers.ex` — FOUND, real `@moduledoc` present
- `rulestead/lib/rulestead/telemetry.ex` — FOUND, real `@moduledoc` present
- `rulestead/lib/rulestead/config.ex` — FOUND, real `@moduledoc` present
- Commit a70279c — FOUND
- Commit c11b7c2 — FOUND
- `mix docs --warnings-as-errors` — exits 0
- `release_contract_test.exs` — 26 tests, 0 failures
