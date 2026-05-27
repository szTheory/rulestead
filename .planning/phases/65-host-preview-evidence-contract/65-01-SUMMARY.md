---
phase: 65-host-preview-evidence-contract
plan: 65-01
subsystem: api
tags: [elixir, preview-evidence, host-seam, redaction, fail-closed]

requires:
  - phase: 64
    provides: Guarded rollout auto-advance store patterns and audience preview foundation
provides:
  - PreviewEvidence behaviour and config-driven facade
  - Query normalization for resolver scope (environment, tenant, audience, operation, definitions)
  - Fail-closed limits validator with 25-row and 16 KiB caps
  - Unit tests for resolver seam, redaction, and error codes
affects:
  - 65-02-impact-preview-v2
  - 65-03-fake-ecto-wiring
  - 65-04-contract-tests

tech-stack:
  added: []
  patterns:
    - Host-owned PreviewEvidence behaviour mirroring Guardrails.Provider
    - Application env :preview_evidence_resolver with opts override
    - Fail-closed evidence validation before ImpactPreview.build (limits module)

key-files:
  created:
    - rulestead/lib/rulestead/targeting/preview_evidence.ex
    - rulestead/lib/rulestead/targeting/preview_evidence/query.ex
    - rulestead/lib/rulestead/targeting/preview_evidence/limits.ex
    - rulestead/test/rulestead/targeting/preview_evidence_test.exs
  modified: []

key-decisions:
  - "Opt-in resolver: no Application env returns {:ok, %{}} preserving pre-v1.9 preview path"
  - "Dedupe merge key uses actor_key + targeting_key when both present; explicit command rows win"
  - "Impression summary rejects unknown keys fail-closed rather than silently stripping PII fields"

patterns-established:
  - "PreviewEvidence.resolve/2 pipes raw resolver output through Limits.validate_and_redact/2"
  - "Stable error metadata codes: preview_evidence_oversized, preview_evidence_invalid, preview_evidence_policy_denied, preview_evidence_resolver_failed"

requirements-completed:
  - IMP-05

duration: 12min
completed: 2026-05-27
---

# Phase 65 Plan 01: Preview Evidence Resolver Seam And Limits Summary

**Host-configurable PreviewEvidence behaviour with normalized query map, fail-closed 25-row/16 KiB limits, and redacted sample/impression validation**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T22:00:00Z
- **Completed:** 2026-05-27T22:12:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `Rulestead.Targeting.PreviewEvidence` behaviour and facade reading `:preview_evidence_resolver` from Application env or opts
- Implemented `Query.new/1` with D-02 scoped keys and `GovernanceSupport.normalize_string/1` normalization
- Built `Limits` module with merge_samples dedupe, impression allowlist validation, sample redaction, and payload size enforcement
- Wired facade resolve path through limits validator with rescue fail-closed on resolver exceptions
- Added 7 unit tests covering no-resolver opt-in, stub resolver redaction, invalid impression keys, oversize samples, policy denial, exception rescue, and merge dedupe

## Task Commits

Each task was committed atomically:

1. **Task 1: Behaviour, facade, and query struct** - `ee63750` (feat)
2. **Task 2: Limits validator and merge policy** - `89e47c6` (feat)
3. **Task 3: Unit tests for seam and limits** - `191eebf` (test)

## Files Created/Modified

- `rulestead/lib/rulestead/targeting/preview_evidence.ex` - Behaviour callback, facade resolve/2, resolver_module/1
- `rulestead/lib/rulestead/targeting/preview_evidence/query.ex` - Normalized resolver query map builder
- `rulestead/lib/rulestead/targeting/preview_evidence/limits.ex` - merge_samples/3, validate_and_redact/2, enforce_payload_size!/1
- `rulestead/test/rulestead/targeting/preview_evidence_test.exs` - Stub resolvers and 7 acceptance tests

## Decisions Made

- Followed Guardrails.Provider pattern for behaviour + Application env config with opts override
- Unknown impression keys fail-closed with `preview_evidence_invalid` rather than silent strip (D-06/D-07)
- Empty resolver map normalizes to `%{samples: [], impression_summary: %{}}` through limits validator

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 65-02: ImpactPreview schema v2, impression fingerprint, preview_basis/uncertainty extensions
- Limits module and facade seam are stable integration point for Fake/Ecto wiring in 65-03

## Self-Check: PASSED

- [x] `rulestead/lib/rulestead/targeting/preview_evidence.ex` exists
- [x] `rulestead/lib/rulestead/targeting/preview_evidence/limits.ex` exists
- [x] `rulestead/test/rulestead/targeting/preview_evidence_test.exs` exists (7 tests)
- [x] `mix compile --warnings-as-errors` green
- [x] `mix test test/rulestead/targeting/preview_evidence_test.exs` green (7 tests, 0 failures)
- [x] Task commits: ee63750, 89e47c6, 191eebf

---
*Phase: 65-host-preview-evidence-contract*
*Completed: 2026-05-27*
