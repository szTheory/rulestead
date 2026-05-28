---
phase: 65-host-preview-evidence-contract
plan: 65-04
subsystem: testing
tags: [elixir, contract-tests, preview-evidence, stale-fingerprint, gov-05, adapter-parity]

requires:
  - phase: 65-03
    provides: Fake/Ecto preview evidence wiring and adapter contract patterns
provides:
  - preview_evidence_contract_test.exs with Fake/Ecto parity for evidence, stale, fail-closed
  - GOV-05 regression proving assess/2 ignores impression and sample evidence
  - Full phase 65 test slice green (52 tests)
affects:
  - 66-evidence-carry-through
  - 68-proof-docs

tech-stack:
  added: []
  patterns:
    - Configurable PreviewEvidenceContractStub via Application env :preview_evidence_stub_result
    - Per-adapter stub reset inside @adapters loops for isolated stale drift proofs
    - GOV boundary regression with high matched_impressions that must not affect verdict

key-files:
  created:
    - rulestead/test/rulestead/targeting/preview_evidence_contract_test.exs
  modified:
    - rulestead/test/rulestead/governance/blast_radius_threshold_test.exs

key-decisions:
  - "Stale drift test re-configures initial stub inside each adapter iteration to avoid cross-adapter Application env bleed"
  - "Task 3 verification-only: full phase slice passed without schema v1 fixture updates"

patterns-established:
  - "Contract tests use Rulestead.Test.PreviewEvidenceContractStub with :preview_evidence_stub_result for deterministic resolver scenarios"
  - "GOV-05 proof passes impression_evidence/sample_evidence on assess attrs and asserts verdict parity"

requirements-completed:
  - IMP-05
  - IMP-06

duration: 18min
completed: 2026-05-27
---

# Phase 65 Plan 04: Contract Tests Evidence Stale Fail-Closed Parity Summary

**Fake and Ecto contract tests prove schema v2 host evidence, fail-closed resolver errors, stale apply on impression drift, and GOV-05 reference-count-only blast-radius boundary**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-27T22:00:00Z
- **Completed:** 2026-05-27T22:18:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added `preview_evidence_contract_test.exs` with 7 tests iterating `@adapters [Rulestead.Fake, StoreEcto]` for resolver enrichment, oversized/invalid/policy-denied fail-closed, stale apply on impression drift (IMP-06), explicit sample preservation, and nil-resolver pre-v1.9 semantics
- Added GOV-05 regression in `blast_radius_threshold_test.exs` proving `assess/2` verdict unchanged when huge `impression_evidence` and `sample_evidence` maps are present
- Ran full phase 65 test slice (52 tests) — all green; no audience mutation fixtures still hardcode `preview_schema_version: 1`

## Task Commits

Each task was committed atomically:

1. **Task 1: preview_evidence_contract_test.exs** - `ebc2522` (test)
2. **Task 2: GOV-05 boundary regression** - `6512390` (test)
3. **Task 3: Full phase test slice** - verification only (no code changes required)

**Plan metadata:** `1395326` (docs: complete plan)

## Files Created/Modified

- `rulestead/test/rulestead/targeting/preview_evidence_contract_test.exs` - Adapter contract tests for evidence, stale, fail-closed, parity
- `rulestead/test/rulestead/governance/blast_radius_threshold_test.exs` - GOV-05 impression/sample evidence boundary regression

## Decisions Made

- Re-configure initial stub inside each `@adapters` iteration so Ecto does not inherit Fake's post-drift stub state during stale tests
- Keep `release_contract_test.exs` v1 schema assertion (release contract surface, not audience mutation fixture)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Per-adapter stub isolation in stale fingerprint test**
- **Found during:** Task 1 (apply rejects stale fingerprint)
- **Issue:** Single test-level stub configure left Ecto running both previews with matched_impressions: 99 after Fake iteration, so fingerprint never drifted and apply incorrectly succeeded
- **Fix:** Move initial `configure_stub!` (matched_impressions: 12) inside `Enum.each(@adapters, ...)` before each adapter's preview
- **Files modified:** `rulestead/test/rulestead/targeting/preview_evidence_contract_test.exs`
- **Verification:** `mix test test/rulestead/targeting/preview_evidence_contract_test.exs` green (7 tests)
- **Committed in:** `ebc2522` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Test isolation fix required for correct IMP-06 proof on Ecto adapter. No production code changes.

## Issues Encountered

None beyond the per-adapter stub isolation fix documented as deviation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 65 complete — all four plans shipped; ready for Phase 66 evidence carry-through and audit payload embedding
- Contract test patterns stable for Phase 68 verification expansion

## Self-Check: PASSED

- [x] `preview_evidence_contract_test.exs` exists with `@adapters [Rulestead.Fake, StoreEcto]`
- [x] Test `"apply rejects stale fingerprint when host evidence changes across adapters"` exists
- [x] Test `"assess ignores impression_evidence and sample_evidence for verdict"` exists in blast_radius_threshold_test.exs
- [x] `blast_radius_threshold.ex` has no `impression` references in assess path (grep clean)
- [x] `mix test` full phase slice green (52 tests, 0 failures)
- [x] Task commits: ebc2522, 6512390
- [x] No `preview_schema_version: 1` in audience mutation test fixtures (only release_contract_test.exs)

---
*Phase: 65-host-preview-evidence-contract*
*Completed: 2026-05-27*
