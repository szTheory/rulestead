---
phase: 121-mix-exunit-performance-test-value-cleanup
plan: "02"
subsystem: rulestead-core-tests
tags: [async-audit, exunit, test-value, ci-reliability, evidence-gated]
requirements_completed: [CIDX-06]

dependency_graph:
  requires: [121-01-SUMMARY.md]
  provides: [121-ASYNC-AUDIT.md]
  affects: []

tech_stack:
  added: []
  patterns: [evidence-gated-allowlist, correctness-first-serial, greppable-hazard-gate]

key_files:
  created:
    - .planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-ASYNC-AUDIT.md
  modified: []

decisions:
  - "0 async:false RepoCase modules flipped: every candidate carries a disqualifying hazard (global Fake singleton, Application.put_env, telemetry.attach, capture_log, or DDL-in-setup); correctness-first D-02 applied"
  - "code_refs_plug_test.exs kept serial: DDL-in-setup (CREATE TABLE IF NOT EXISTS) is a DB-ownership disqualifier per D-01"
  - "Do-not-flip trio preserved: stale_flag_worker (named Telemetry.Cache + ETS), batcher (global ETS delete + supervised singleton), inbound_http (shared sandbox dependency)"

metrics:
  duration: "~3 minutes"
  completed_date: "2026-06-16"
  tasks_completed: 2
  files_changed: 1
---

# Phase 121 Plan 02: Evidence-Gated Async Audit Summary

## One-liner

Evidence-gated audit of 23 async:false RepoCase candidates — every module carries a disqualifying global-state hazard; net flips = 0 (correctness-first D-02 honored, suite green).

## What Was Built

`121-ASYNC-AUDIT.md` — a per-module async verdict record for all 23 `async: false` RepoCase candidates in `rulestead/test/`. The audit independently re-ran the greppable hazard gate on every candidate, cross-checked against RESEARCH.md's pre-verified table, and produced evidence-backed verdicts.

**Result:** 0 modules flipped to `async: true`. Every candidate carries at least one disqualifying hazard:

- 20 modules: `Rulestead.Fake` global named singleton (`@adapters [...Fake...]` or `Fake.Control.reset!`) and/or `Application.put_env/delete_env` process-global app-env mutation
- 1 module: `:telemetry.attach_many` (scheduled_execution_audit_contract_test)
- 1 module: `@moduletag capture_log: true` (webhooks/outbound_delivery_test)
- 1 module (borderline): `CREATE TABLE IF NOT EXISTS` DDL in setup — no Fake/app-env/telemetry hazard, but DB-ownership disqualifier per D-01 (`webhooks/code_refs_plug_test.exs`)

**Do-not-flip trio explicitly preserved:**
- `oban/stale_flag_worker_test.exs` — named `Rulestead.Telemetry.Cache` GenServer + ETS
- `analytics/batcher_test.exs` — global ETS table delete + supervised Analytics.Batcher singleton
- `webhooks/inbound_http_test.exs` — shared sandbox dependency (DB records created by IngressPlug visible via `list_webhook_records`)

**Latent risk noted (out of scope):** `store/webhook_adapter_contract_test.exs` and `store/webhook_outbound_contract_test.exs` are already `async: true` (via `use ExUnit.Case`) yet call `Rulestead.Fake.reset()` — pre-existing hazard, noted only per RESEARCH Pitfall 3, not changed.

## Verification

- `cd rulestead && mix test --warnings-as-errors`: **0 failures** (586 tests, 8 properties, 4 excluded)
- No source files in `rulestead/test/` were modified
- `121-ASYNC-AUDIT.md` exists and contains: `KEEP SERIAL`, `code_refs_plug_test`, `stale_flag_worker_test`, `batcher_test`, `inbound_http_test`, and `## Decision` section

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Re-run greppable hazard gate, write 121-ASYNC-AUDIT.md | 57f9f3e | 121-ASYNC-AUDIT.md (182 lines) |
| 2 | Apply 0 flips — suite green, Decision section in audit | (no new files — 0-flip decision documented in Task 1 commit) | none |

## Deviations from Plan

None — plan executed exactly as written. The audit recommended 0 flips (the expected outcome per D-02), and the suite remained green. The Decision section was written as part of the Task 1 audit file rather than a separate Task 2 append, which is equivalent and correct per the plan's default action description.

## Known Stubs

None. This plan produces only a planning artifact (121-ASYNC-AUDIT.md); no UI components, no data sources, no stubs.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes were introduced. The audit found no previously unregistered trust-boundary surfaces.

## Self-Check

- [x] `121-ASYNC-AUDIT.md` exists at correct path
- [x] Commit 57f9f3e exists in git log
- [x] Suite green: 0 failures confirmed twice
- [x] Do-not-flip trio preserved (verified by grep + file read)
- [x] 0 source files modified in rulestead/test/
