---
phase: 65-host-preview-evidence-contract
plan: 65-02
subsystem: api
tags: [elixir, impact-preview, schema-v2, fingerprint, impression-evidence]

requires:
  - phase: 65-01
    provides: PreviewEvidence limits validator and impression allowlist contract
provides:
  - ImpactPreview schema v2 with impression_evidence field
  - impression_fingerprint token in preview_fingerprint/1
  - preview_basis/1 helper with basis-derived uncertainty messages
  - redacted_impression_summary/1 for allowlisted impression redaction
affects:
  - 65-03-fake-ecto-wiring
  - 65-04-contract-tests

tech-stack:
  added: []
  patterns:
    - Schema v2 breaking bump with impression_fingerprint in deterministic token payload
    - Basis-specific uncertainty messages without authoritative population claims
    - Allowlisted impression summary redaction parallel to sample evidence path

key-files:
  created: []
  modified:
    - rulestead/lib/rulestead/targeting/impact_preview.ex
    - rulestead/test/rulestead/targeting/impact_preview_test.exs

key-decisions:
  - "Derive preview_basis to authored_state_with_host_evidence when impression_summary non-empty; store sets explicit basis for unavailable path"
  - "Unknown impression keys stripped silently in build path (limits validator fail-closed upstream)"

patterns-established:
  - "preview_fingerprint token includes impression_fingerprint alongside sample_fingerprint"
  - "uncertainty.authoritative_population_count? remains false for all preview_basis values"

requirements-completed:
  - IMP-05
  - IMP-06

duration: 15min
completed: 2026-05-27
---

# Phase 65 Plan 02: ImpactPreview Schema v2 And Evidence Fingerprints Summary

**ImpactPreview schema v2 with impression_evidence, impression_fingerprint in deterministic preview token, and basis-specific uncertainty messages per D-04/D-05**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-27T21:42:00Z
- **Completed:** 2026-05-27T21:57:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Bumped `@schema_version` to 2 with `impression_evidence` on built preview payloads
- Extended `preview_fingerprint/1` token payload with `impression_fingerprint` hash of redacted impression summary
- Added public `redacted_impression_summary/1` and `preview_basis/1` with D-05 uncertainty message taxonomy
- Preserved `authoritative_population_count?: false` for all basis values
- Added 5 new tests covering fingerprint determinism, impression redaction, schema version, and basis messages

## Task Commits

Each task was committed atomically:

1. **Task 1: Schema v2 and fingerprint token** - `d58cf25` (feat)
2. **Task 2: Extend impact_preview_test.exs** - `742a60c` (test)

## Files Created/Modified

- `rulestead/lib/rulestead/targeting/impact_preview.ex` - Schema v2, impression evidence, basis helpers, fingerprint extension
- `rulestead/test/rulestead/targeting/impact_preview_test.exs` - v2 contract tests (9 total)

## Decisions Made

- Derive `authored_state_with_host_evidence` when redacted impression summary is non-empty; store passes explicit basis for unavailable resolver path in 65-03
- Strip unknown impression keys in `redacted_impression_summary/1` (defense in depth after Limits fail-closed validation)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 65-03: Fake/Ecto `audience_preview_payload` wiring can pass `impression_summary` and `preview_basis` into `ImpactPreview.build/1`
- v1 fingerprints intentionally invalidated by schema bump; stale gate uses `schema_version()`

## Self-Check: PASSED

- [x] `ImpactPreview.schema_version() == 2`
- [x] `impression_fingerprint` present in `impact_preview.ex` token payload
- [x] Built preview includes `:impression_evidence` key
- [x] `uncertainty.authoritative_population_count?` is `false`
- [x] `mix test test/rulestead/targeting/impact_preview_test.exs --warnings-as-errors` green (9 tests)
- [x] Task commits: d58cf25, 742a60c

---
*Phase: 65-host-preview-evidence-contract*
*Completed: 2026-05-27*
