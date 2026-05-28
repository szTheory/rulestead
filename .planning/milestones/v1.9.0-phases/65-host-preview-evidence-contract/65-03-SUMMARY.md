---
phase: 65-host-preview-evidence-contract
plan: 65-03
subsystem: api
tags: [elixir, preview-evidence, fake, ecto, store-wiring, adapter-parity]

requires:
  - phase: 65-01
    provides: PreviewEvidence behaviour, limits validator, resolver facade
  - phase: 65-02
    provides: ImpactPreview schema v2, impression_evidence, preview_basis helpers
provides:
  - assemble_preview_evidence_attrs in Fake and Ecto before ImpactPreview.build
  - Rulestead.Fake.PreviewEvidenceResolver test stub
  - Adapter contract tests for configured vs nil resolver paths
affects:
  - 65-04-contract-tests

tech-stack:
  added: []
  patterns:
    - Store-boundary I/O: resolver invoke in audience_preview_payload only
    - Union merge with Limits.merge_samples preserving command rows first
    - preview_basis selection with host-evidence-unavailable fallback

key-files:
  created:
    - rulestead/lib/rulestead/fake/preview_evidence_resolver.ex
  modified:
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/targeting/preview_evidence.ex
    - rulestead/test/rulestead/store/audience_impact_contract_test.exs

key-decisions:
  - "Duplicate assemble_preview_evidence_attrs in Fake and Ecto to avoid compile-dep cycle"
  - "audience_preview_payload returns {:ok, preview} | {:error, error} for fail-closed resolver errors"
  - "Code.ensure_loaded before function_exported? so config-time resolver modules resolve correctly"

patterns-established:
  - "PreviewEvidence.resolve at store boundary; ImpactPreview.build stays pure"
  - "Fake.PreviewEvidenceResolver for contract tests; hosts configure via Application env"

requirements-completed:
  - IMP-05

duration: 18min
completed: 2026-05-27
---

# Phase 65 Plan 03: Store Adapter Wiring And Fake Test Resolver Summary

**Fake and Ecto audience_preview_payload invoke PreviewEvidence before ImpactPreview.build, with union sample merge, basis selection, and adapter contract tests via Rulestead.Fake.PreviewEvidenceResolver**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-27T21:42:00Z
- **Completed:** 2026-05-27T21:59:53Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `assemble_preview_evidence_attrs/5` in both `Rulestead.Fake` and `Rulestead.Store.Ecto` to build resolver query, merge samples, set impression summary and preview_basis
- Created `Rulestead.Fake.PreviewEvidenceResolver` test stub returning bounded samples and impression summary
- Updated all `audience_preview_payload` call sites to propagate `{:error, _}` from resolver failures
- Extended `audience_impact_contract_test.exs` with Fake/Ecto adapter parity for configured and nil resolver paths
- Fixed `PreviewEvidence.resolve/2` to `Code.ensure_loaded/1` before export check so dynamically configured resolver modules work

## Task Commits

Each task was committed atomically:

1. **Task 1: Shared preview evidence assembly helper** - `7e56d2f` (feat)
2. **Task 2: Adapter integration tests** - `1dde336` (test)

## Files Created/Modified

- `rulestead/lib/rulestead/fake/preview_evidence_resolver.ex` - Test-only PreviewEvidence behaviour stub
- `rulestead/lib/rulestead/fake.ex` - Assembly helper and wired audience_preview_payload
- `rulestead/lib/rulestead/store/ecto.ex` - Parity assembly helper and wired audience_preview_payload
- `rulestead/lib/rulestead/targeting/preview_evidence.ex` - ensure_loaded before function_exported check
- `rulestead/test/rulestead/store/audience_impact_contract_test.exs` - Adapter resolver contract describe block

## Decisions Made

- Duplicated small assembly helper in Fake/Ecto per plan (avoid new compile dependency module)
- Resolver errors fail-closed through tagged tuples; `:empty` reason maps to unavailable basis per D-05
- ensure_loaded fix applied to facade so host/test resolver modules not yet loaded at boot work correctly

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Code.ensure_loaded before function_exported? in PreviewEvidence.resolve**
- **Found during:** Task 2 (Adapter integration tests)
- **Issue:** Configured `Rulestead.Fake.PreviewEvidenceResolver` returned `:invalid_resolver` because module was not loaded and `function_exported?/3` returned false on unloaded modules
- **Fix:** Wrap resolver dispatch in `Code.ensure_loaded/1` before export check
- **Files modified:** `rulestead/lib/rulestead/targeting/preview_evidence.ex`
- **Verification:** `mix test test/rulestead/store/audience_impact_contract_test.exs` green (14 tests)
- **Committed in:** `1dde336` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for resolver wiring to function with Application-configured modules. No scope creep.

## Issues Encountered

None beyond the ensure_loaded fix documented as deviation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 65-04: stale fingerprint with evidence drift, fail-closed oversized/invalid, GOV boundary contract tests
- Store wiring and test resolver stable for Phase 66 evidence carry-through

## Self-Check: PASSED

- [x] `Rulestead.Fake.PreviewEvidenceResolver` exists with `@behaviour Rulestead.Targeting.PreviewEvidence`
- [x] `PreviewEvidence` referenced in `fake.ex` and `ecto.ex` audience_preview_payload paths
- [x] No `PreviewEvidence` references in `impact_preview.ex`
- [x] Contract test references `Rulestead.Fake.PreviewEvidenceResolver`
- [x] With resolver configured, `preview_basis == "authored_state_with_host_evidence"`
- [x] `mix compile --warnings-as-errors` green
- [x] `mix test test/rulestead/store/audience_impact_contract_test.exs` green (14 tests, 0 failures)
- [x] Task commits: 7e56d2f, 1dde336

---
*Phase: 65-host-preview-evidence-contract*
*Completed: 2026-05-27*
