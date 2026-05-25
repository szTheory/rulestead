---
phase: 42-runtime-contract-parity
plan: 02
subsystem: runtime-schema
tags:
  - flag
  - lifecycle
  - ownership
  - tests
dependency_graph:
  requires:
    - "42-01 clean GA migration baseline"
  provides: "Embed-only authored-state contract across core runtime code"
  affects:
    - rulestead/lib/rulestead/flag.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/test/
tech_stack:
  added: []
  patterns:
    - Ecto embeds for authored ownership and lifecycle
    - key-first store commands with normalized ownership filters
decisions:
  - Removed runtime and test expectations that `Rulestead.Flag` still exposes top-level `owner`, `permanent`, or `expected_expiration` fields.
  - Kept public command normalization intact while removing redundant fake-store backfill of legacy attrs.
metrics:
  duration: 1 session
  tasks_completed: 3
  tasks_total: 3
  files_modified: 7
---

# Phase 42 Plan 02: Embed-Only Runtime Contract Summary

**Aligned the core runtime, fake adapter, and targeted tests to the squashed authored-state contract.**

## What Was Built
- Removed remaining core assumptions that `Flag` exposes top-level lifecycle/owner fields instead of `ownership` and `lifecycle` embeds.
- Simplified the fake store so create/update paths consume normalized command embeds instead of rebuilding legacy fields internally.
- Updated targeted fixtures and tests to assert on `flag.ownership.owner_ref`, `flag.lifecycle.mode`, and `flag.lifecycle.review_by`.
- Corrected paginated owner-filter tests to use the supported `owner` selector instead of an unsupported `ownership` option in `ListFlags`.

## Verification
- `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/admin_test.exs`
- Result: passing on 2026-05-25.

## Threat Flags
- Broad repo coverage still contains older tests that create or update flags through legacy command inputs; those paths remain normalized at the command layer, but full-suite cleanup belongs to subsequent verification work rather than this plan’s core parity fix.
