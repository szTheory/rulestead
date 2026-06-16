---
phase: 121-mix-exunit-performance-test-value-cleanup
plan: "03"
subsystem: test-infrastructure
tags: [measurement, ci-reliability, evidence-record, before-after, partitioning-rejection]
requirements_completed: [CIDX-06]

dependency_graph:
  requires: [121-01-SUMMARY.md, 121-02-SUMMARY.md]
  provides: [121-MEASUREMENT.md]
  affects: []

tech_stack:
  added: []
  patterns: [locked-command-measurement, before-after-comparison, rejection-with-evidence]

key_files:
  created:
    - .planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-MEASUREMENT.md
  modified: []

decisions:
  - key: D-09 measurement
    value: "Default lane: ~4.6s real / 586 tests / 0 failures (was ~42s baseline). With dominant: ~22s / 587 tests. Delta: -37s default (-88%). Dominant test (17090ms) absent from default top-25; next-slowest module 303ms."
  - key: D-06 partitioning
    value: "REJECTED with 5 verified premises: single serial network test (partitions distribute modules not work); overwhelmingly async:false suite via global Fake + app-env; single Postgres sandbox + named Fake require per-partition isolation = fragility; no partition config in mix.exs; 18 schedulers already absorb tiny async set. Mapped to FUT-01 (deferred, reversible)."
  - key: D-05 no module splits
    value: "Next-slowest module 303ms (Promotion.ApplyTest) after dominant excluded. Concurrency-benefit bar unmet. No splits."
  - key: D-07 no Dialyzer/PLT change
    value: "Phase 120 already scoped PLT key. Dialyzer in lint lane only. No safe lever in Phase 121 boundary."
  - key: D-10 xref cycle
    value: "Length-47 compile-connected cycle centered on lib/rulestead.ex noted as architectural evidence. NOT refactored."

metrics:
  duration: 15 minutes
  completed_date: 2026-06-16
  tasks_completed: 2
  files_modified: 1
---

# Phase 121 Plan 03: Measurement Record and Decision Evidence Summary

Before/after wall-clock measurements using the exact Phase 119 commands show the default test lane dropped from ~42s to ~4.6s real (dominant test relocated); partitioning is rejected with 5 verified premises mapped to FUT-01; D-05/D-07/D-10 are recorded as deliberate no-action decisions — no source or config files touched.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Record before/after wall-clock and slowest-test measurements (D-09) | e8f1dc1 | 121-MEASUREMENT.md |
| 2 | Record the partitioning rejection and the no-action decisions (D-06/D-05/D-07/D-10) | e8f1dc1 | 121-MEASUREMENT.md (same file — integrated with Task 1) |

## Decisions Made

| Decision | Outcome |
|----------|---------|
| D-09 measurement commands | Used exact locked commands: `mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25`, run 4 times (default x2, with-dominant x2) |
| Env var (from 121-01-SUMMARY.md) | `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` confirmed; tag: `:published_hex_smoke` |
| Task integration | Tasks 1 and 2 written as one integrated measurement document (atomic — all decisions documented in a single coherent artifact) |

## Wall-Clock Measurements (D-09)

| Lane | Wall-clock (real) | Tests | Failures | Excluded | Dominant test? |
|------|-------------------|-------|----------|----------|----------------|
| Default (Runs 1-2) | ~4.6s | 586 | 0 | 4 | ABSENT (excluded) |
| With dominant (Runs 3-4) | ~22s | 587 | 0 | 3 | 17090ms (top of list) |
| Phase 119 baseline | ~42s | 587 | 1 | 1 | ~27950ms (top of list) |

**Default-lane improvement:** -37s wall-clock (-88%). Measured with 18 schedulers online (same as Phase 119).

**Slowest module (default lane):** `Rulestead.Promotion.ApplyTest` at 303ms — confirms D-05 bar unmet.

**Dominant test timing (with opt-in):** 17090ms (vs ~27950ms in Phase 119 — faster hex.pm network on measurement day; variance is expected real-network behavior).

## Decision Records

| Decision | Evidence | Action |
|----------|----------|--------|
| D-06: Partitioning rejected | 5 verified premises: serial-only dominant; async:false suite by design; per-partition DB/Fake isolation = fragility; no partition config; 18 schedulers absorb async set | None — FUT-01 deferred |
| D-05: No module splits | Next-slowest 303ms (default lane); bar unmet; global-state hazards not fixed by splits | None |
| D-07: No Dialyzer/PLT change | Phase 120 scoped PLT key; Dialyzer in lint lane; no lever in Phase 121 boundary | None |
| D-10: Xref cycle noted | Length-47 compile-connected cycle centered on lib/rulestead.ex; architectural evidence only | None |

## Acceptance Criteria Verified

### Must-Haves

- [x] Before/after slowest-test and wall-clock notes recorded using the exact Phase 119 commands (`mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25`)
- [x] `mix test --partitions` explicitly rejected with evidence (5 verified premises, FUT-01 mapping)
- [x] D-05 (no module split), D-07 (no Dialyzer change), D-10 (xref cycle noted) recorded as decisions, not actions

### Artifacts

- [x] `121-MEASUREMENT.md` exists at correct path
- [x] Contains "slowest" (multiple occurrences)
- [x] Contains "real" and "Finished in" wall-clock lines
- [x] Contains partitioning rejection section
- [x] Contains D-05, D-07, D-10 decision sections
- [x] `key_links` honored: `121-MEASUREMENT.md` before/after references the Phase 119 baseline (~42s real, dominant ~27.95s)

### Negative Checks

- [x] No source/config files changed — `git diff --diff-filter=M --name-only HEAD~1 HEAD` shows only `.planning/` artifact
- [x] `mix.exs` has no new partition config
- [x] No module was split
- [x] No Dialyzer/PLT key changed
- [x] `lib/rulestead.ex` xref cycle not refactored

## Deviations from Plan

None — plan executed exactly as written. Tasks 1 and 2 were integrated into one atomic file write rather than separate writes, which is equivalent and more coherent (both tasks produce sections of the same artifact; writing them together avoids a partial-state intermediate commit).

## Known Stubs

None — this plan produces only a planning artifact (121-MEASUREMENT.md); all measurements are freshly run, not fabricated.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. The measurements required network access to hex.pm for Runs 3-4 (the dominant test opts in to the live hex.pm call) — this is documented in `121-MEASUREMENT.md` and is the expected behavior of the opted-in proof.

## Self-Check

### Files exist:
- [x] `121-MEASUREMENT.md` exists at `.planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-MEASUREMENT.md`

### Commits exist:
- [x] `e8f1dc1` — docs(121-03): produce D-09 before/after measurement record (121-MEASUREMENT.md)

## Self-Check: PASSED
