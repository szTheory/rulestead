---
phase: 54-dependency-truth-and-promotion-safety
plan: 02
subsystem: api
tags: [dependency-validator, audience-mutation, publish-safety, ecto, fake]

requires:
  - phase: 54-01
    provides: Canonical dependency inventory projection and normalized entry contract
provides:
  - Shared dependency validator with stable blocker findings and deterministic sorting
  - Fail-closed publish gating in Ecto and Fake using one dependency blocker contract
  - Fail-closed audience mutation gating in Ecto and Fake with blocker audit evidence
affects: [promotion-apply, compare, manifest-import, support-audit]

tech-stack:
  added: []
  patterns:
    - Shared validation seam: inventory entries -> validator findings -> to_error/blockers?
    - Deterministic blocker envelopes persisted in audit metadata for blocked writes

key-files:
  created:
    - rulestead/lib/rulestead/targeting/dependency_validator.ex
    - rulestead/test/rulestead/store/publish_ruleset_dependency_contract_test.exs
  modified:
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs
    - rulestead/test/rulestead/store/audience_impact_contract_test.exs

key-decisions:
  - "Treat stale dependency references as validator findings so adapters fail closed through one shared error envelope."
  - "Persist blocked-operation dependency findings in audit metadata to keep support reconstruction deterministic."
  - "Normalize string-key and atom-key reference payloads in mutation validation to preserve Ecto/Fake parity."

patterns-established:
  - "Validator contract: `validate/2` + `blockers?/1` + `to_error/2` used by all write gates"
  - "Blocked write audit pattern: emit event with structured blocker maps and sorted dependency findings"

requirements-completed: [DEP-02, DEP-04]

duration: 15min
completed: 2026-05-27
---

# Phase 54 Plan 02 Summary

**Shared dependency truth now blocks unsafe publish and audience mutation writes in both Ecto and Fake with deterministic blocker findings and auditable evidence.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-27T13:15:00Z
- **Completed:** 2026-05-27T13:30:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Added `Rulestead.Targeting.DependencyValidator` with stable codes (`missing_reference`, `archived_reference`, `incompatible_reference`, `stale_reference`, `tenant_mismatch`) and deterministic sort semantics.
- Enforced dependency validation before `publish_ruleset` in Ecto and Fake, returning shared invalid-command blocker errors and writing blocked publish audit evidence.
- Enforced dependency validation before `apply_audience_mutation` in Ecto and Fake, including stale-reference detection from affected reference key drift and blocked mutation audit evidence.
- Extended contract tests to prove Ecto/Fake parity for validator semantics, publish fail-closed behavior, and mutation blocker/audit behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build shared dependency validator with normalized blocker schema** - `06d94b7` (feat)
2. **Task 2: Enforce validator blockers in ruleset publish** - `342789e` (feat)
3. **Task 3: Enforce validator blockers in audience mutation attempts** - `934c059` (feat)

## Files Created/Modified
- `rulestead/lib/rulestead/targeting/dependency_validator.ex` - Shared dependency finding contract, blocker helpers, and deterministic ordering.
- `rulestead/lib/rulestead/store/ecto.ex` - Publish and mutation dependency gates, blocked audit metadata, and normalized dependency entry helpers.
- `rulestead/lib/rulestead/fake.ex` - Publish and mutation dependency gates with blocked audit event parity.
- `rulestead/test/rulestead/store/publish_ruleset_dependency_contract_test.exs` - Validator semantics and Ecto/Fake publish blocker parity.
- `rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs` - Ecto mutation stale/incompatible dependency blocker assertions with audit metadata checks.
- `rulestead/test/rulestead/store/audience_impact_contract_test.exs` - Fake mutation stale/incompatible dependency blocker assertions with audit metadata checks.

## Decisions Made
- Centralized blocker classification in validator errors instead of path-specific message parsing.
- Kept runtime hot path pure by confining dependency validation to write workflows only.
- Used fallback scope hydration for stale findings so missing current entries still emit deterministic identity fields.

## Deviations from Plan

### Auto-fixed Issues

**1. Validator stale detection initially over-fired**
- **Found during:** Task 1 verification
- **Issue:** `expected_reference_keys` defaulted to an empty list and incorrectly emitted `stale_reference` for all entries.
- **Fix:** Preserve `nil` when expected keys are omitted; only run symmetric-difference stale checks when expected keys are explicitly present.
- **Files modified:** `rulestead/lib/rulestead/targeting/dependency_validator.ex`
- **Verification:** `mix test test/rulestead/targeting/dependency_inventory_test.exs test/rulestead/store/publish_ruleset_dependency_contract_test.exs`
- **Committed in:** `06d94b7`

**2. Nil tenant normalization caused false tenant mismatches**
- **Found during:** Task 1 verification
- **Issue:** `normalize_string/1` treated `nil` as an atom and converted it to `"nil"`, triggering false `tenant_mismatch`.
- **Fix:** Match `nil` before atom normalization.
- **Files modified:** `rulestead/lib/rulestead/targeting/dependency_validator.ex`
- **Verification:** `mix test test/rulestead/targeting/dependency_inventory_test.exs test/rulestead/store/publish_ruleset_dependency_contract_test.exs`
- **Committed in:** `06d94b7`

**3. Rule metadata access broke with ruleset struct entries**
- **Found during:** Task 2 verification
- **Issue:** `get_in/2` on `Rulestead.Ruleset.Rule` structs raised during publish dependency metadata extraction.
- **Fix:** Normalize rule structs to maps before metadata lookups.
- **Files modified:** `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`
- **Verification:** `mix test test/rulestead/store/publish_ruleset_dependency_contract_test.exs`
- **Committed in:** `342789e`

---

**Total deviations:** 3 auto-fixed
**Impact on plan:** All deviations were correctness fixes required to satisfy deterministic fail-closed behavior without scope creep.

## Issues Encountered
- Fake preview affected references may surface string-keyed maps with nil scope fields; mutation dependency entry hydration was updated with command-scope fallbacks to maintain parity.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Promotion compare/apply and manifest flows can now consume the same validator findings contract in 54-03.
- No blocker remains for DEP-03 integration; shared seams are in place.

---
*Phase: 54-dependency-truth-and-promotion-safety*
*Completed: 2026-05-27*
