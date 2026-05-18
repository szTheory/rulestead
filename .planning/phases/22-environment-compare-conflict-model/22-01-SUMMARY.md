---
phase: 22-environment-compare-conflict-model
plan: 01
subsystem: api
tags: [elixir, compare, promotions, ecto, fake, testing]
requires:
  - phase: 21-infrastructure-observability-ui
    provides: existing store adapters, authored-state payload helpers, and environment metadata
provides:
  - canonical authored-state environment compare contract
  - scoped compare token and fingerprint semantics
  - fake and ecto adapter parity coverage for compare payloads
affects: [phase-23-apply-governance, admin-ui, cli, manifests]
tech-stack:
  added: []
  patterns: [read-only compare service, adapter-projected canonical payloads, scoped compare token hashing]
key-files:
  created:
    - rulestead/lib/rulestead/promotion/compare.ex
    - rulestead/test/rulestead/promotion/compare_test.exs
    - rulestead/test/rulestead/store/compare_contract_test.exs
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
key-decisions:
  - "Kept the compare contract in one backend module so token scope, finding taxonomy, and payload shape remain auditable in one seam."
  - "Compared published authored state only, with drafts and operational overrides surfaced as warnings instead of diff inputs."
  - "Relaxed adapter parity assertions to canonical compare semantics rather than raw internal identifiers or timestamps."
patterns-established:
  - "Compare requests flow through a first-class store command and adapter callback."
  - "Compare tokens hash only the scoped flag set plus dependency closure and schema version."
requirements-completed: [PROM-01, PROM-02]
duration: 1 session
completed: 2026-05-18
---

# Phase 22 Plan 01: Environment Compare Contract Summary

**Canonical authored-state environment compare payloads now ship through one public backend facade with scoped stale-preview tokens and Ecto/Fake parity coverage.**

## Performance

- **Duration:** 1 session
- **Started:** Not captured precisely in this resumed execution context
- **Completed:** 2026-05-18T17:22:58Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added a first-class read-only compare API, command, and store callback for environment-to-environment authored-state previews.
- Implemented the canonical compare contract with dependency closure, typed findings, fingerprint metadata, and scoped compare tokens.
- Added targeted contract tests proving Ecto and Fake expose the same backend compare semantics for authored-state previews.

## Task Commits

1. **Tasks 1-2: compare contract and adapter parity implementation** - `4cfdb0e` (`feat`)

No separate plan-metadata commit was created because the user-restricted file scope excluded `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md`; the summary was committed separately as documentation only.

## Files Created/Modified

- `rulestead/lib/rulestead.ex` - public `compare_environments/2` and command-based facade entrypoints
- `rulestead/lib/rulestead/store.ex` - store compare callback contract
- `rulestead/lib/rulestead/store/command.ex` - compare command normalization for source/target keys, optional flag scope, and compare token
- `rulestead/lib/rulestead/promotion/compare.ex` - canonical compare payload builder, finding classification, fingerprinting, and token helpers
- `rulestead/lib/rulestead/store/ecto.ex` - authored-state compare projection for the Ecto adapter
- `rulestead/lib/rulestead/fake.ex` - authored-state compare projection for the Fake adapter
- `rulestead/test/rulestead/promotion/compare_test.exs` - compare API and token behavior coverage
- `rulestead/test/rulestead/store/compare_contract_test.exs` - Ecto/Fake compare contract and parity coverage

## Decisions Made

- Kept compare strictly read-only and did not introduce any Phase 23 apply, governance execution, or scheduling behavior.
- Classified findings by apply safety (`blocker`, `warning`, `info`, `in_sync`) instead of returning a raw structural diff.
- Treated target runtime overrides and source drafts as warnings outside the authored compare fingerprint basis to preserve stable token scope.

## Verification

- Ran `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs`
- Result: `9 tests, 0 failures`

## Deviations from Plan

### Execution Deviations

**1. Shared feature commit across both auto tasks**
- **Reason:** Task 1 and Task 2 both converged on the same new compare module and overlapping adapter-facing seams, so splitting them post-hoc would not have produced clean atomic commits in the dirty tree.
- **Impact:** None on shipped behavior or verification coverage.
- **Committed in:** `4cfdb0e`

**2. Planning state files were not updated**
- **Reason:** The user restricted edits to plan-owned files and excluded `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`.
- **Impact:** Implementation and summary are complete, but planner bookkeeping remains for a later unrestricted pass.

### Auto-fixed Issues

**1. [Rule 1 - Bug] Canonical normalization covered runtime structs that would otherwise cause adapter-parity noise**
- **Found during:** Task 2
- **Issue:** Compare payload normalization still exposed adapter-specific struct formatting for time-like values.
- **Fix:** Normalized `DateTime`, `NaiveDateTime`, `Date`, `Time`, and generic structs before map normalization.
- **Files modified:** `rulestead/lib/rulestead/promotion/compare.ex`
- **Verification:** Targeted compare tests and adapter parity suite passed.
- **Committed in:** `4cfdb0e`

---

**Total deviations:** 3
**Impact on plan:** The delivered compare contract matches the planned backend scope; remaining deviations are bookkeeping-only.

## Issues Encountered

- The targeted suite initially exposed adapter parity mismatches caused by non-canonical identifiers and timestamp-like values in projected payloads. Canonical normalization and parity assertions were tightened to compare the intended backend contract instead of adapter internals.
- The compile-only warning from split `canonical_flag/1` clauses was removed inside the plan-owned compare module before final verification.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None.

## Next Phase Readiness

- Phase 23 can consume one stable compare payload for apply previews, stale-preview checks, and operator-facing conflict rendering.
- Adapter parity for the canonical compare payload is now established for the two supported authored-state backends in this phase: Fake and Ecto.

## Self-Check: PASSED

- Verified summary file exists at `.planning/phases/22-environment-compare-conflict-model/22-01-SUMMARY.md`
- Verified feature commit `4cfdb0e` exists in `git log --oneline --all`
