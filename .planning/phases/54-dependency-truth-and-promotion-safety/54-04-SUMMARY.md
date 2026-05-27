---
phase: 54-dependency-truth-and-promotion-safety
plan: 04
subsystem: testing
tags: [dependency-validator, parity, property-tests, verification, release-contract]

requires:
  - phase: 54-01
    provides: Canonical dependency inventory contract and projection seams
  - phase: 54-02
    provides: Shared dependency validator and fail-closed publish/mutation gates
  - phase: 54-03
    provides: Promotion/manifest dependency finding carry-through and apply revalidation
provides:
  - Deterministic dependency order/scope property proofs
  - Expanded fail-closed parity checks across publish/promotion/manifest/mutation contracts
  - Single-command phase verification gate via `mix verify.phase54`
  - Support/release handoff checklist for Phase 55 boundary discipline
affects: [55-mounted-operator-workflows, 56-proof-docs-and-support-truth, DEP-01, DEP-02, DEP-03, DEP-04]

tech-stack:
  added: []
  patterns:
    - "Phase-scoped verify task pattern (`mix verify.phaseNN`) with preferred test env wiring"
    - "Deterministic scope assertions enforce explicit `environment_key` + `tenant_key` in dependency evidence"

key-files:
  created:
    - rulestead/test/rulestead/targeting/dependency_sort_property_test.exs
    - rulestead/lib/mix/tasks/verify.phase54.ex
    - .planning/phases/54-dependency-truth-and-promotion-safety/54-HANDOFF-CHECKLIST.md
  modified:
    - rulestead/test/rulestead/store/audience_dependency_inventory_contract_test.exs
    - rulestead/test/rulestead/manifest/validate_test.exs
    - rulestead/test/rulestead/store/publish_ruleset_dependency_contract_test.exs
    - rulestead/test/rulestead/store/promotion_apply_contract_test.exs
    - rulestead/test/rulestead/store/manifest_import_contract_test.exs
    - rulestead/test/rulestead/store/audience_impact_contract_test.exs
    - rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs
    - rulestead/test/rulestead/release_contract_test.exs
    - rulestead/mix.exs

key-decisions:
  - "Use StreamData property tests to prove deterministic ordering and scope-key retention for both inventory entries and dependency findings."
  - "Codify phase proof execution under `mix verify.phase54` and wire it to test env through `MixProject.cli/0` preferred envs."
  - "Capture support/release truth as a standalone handoff checklist to keep core-domain ownership in `rulestead` and mounted rendering ownership in `rulestead_admin`."

patterns-established:
  - "Blocked-operation contract tests assert authored/runtime state is unchanged when dependency validation fails."
  - "Release-boundary tests verify core has no `rulestead_admin` dependency leakage while dependency validator APIs remain available."

requirements-completed: [DEP-01, DEP-02, DEP-03, DEP-04]

duration: 11 min
completed: 2026-05-27
---

# Phase 54 Plan 04 Summary

**Phase 54 now has deterministic dependency proof coverage, parity-safe fail-closed contract assertions, a single `mix verify.phase54` merge gate, and a Phase 55 handoff checklist that locks core-vs-mounted truth boundaries.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-05-27T13:47:00Z
- **Completed:** 2026-05-27T13:58:15Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Added deterministic property proof tests for dependency entry/finding ordering and explicit scope retention.
- Expanded publish/promotion/manifest/audience-mutation contract tests to assert fail-closed behavior, deterministic finding order, and scope-carry parity.
- Added `Mix.Tasks.Verify.Phase54` and test-env CLI wiring so `mix verify.phase54` runs as a single phase gate.
- Added `54-HANDOFF-CHECKLIST.md` capturing support/release truth boundaries for Phase 55.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add deterministic sorting and scope property proof** - `c28f161` (test)
2. **Task 2: Prove end-to-end fail-closed parity across Ecto and Fake surfaces** - `2a3a919` (test)
3. **Task 3: Add Phase 54 verification command and support/release handoff checks** - `65d982f` (test)

## Verification Evidence

- `cd rulestead && mix test test/rulestead/targeting/dependency_sort_property_test.exs test/rulestead/store/audience_dependency_inventory_contract_test.exs test/rulestead/manifest/validate_test.exs` -> **2 properties, 6 tests, 0 failures**
- `cd rulestead && mix test test/rulestead/store/publish_ruleset_dependency_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/audience_impact_contract_test.exs test/rulestead/store/ecto_audience_impact_contract_test.exs` -> **46 tests, 0 failures**
- `cd rulestead && mix verify.phase54` -> **2 properties, 76 tests, 0 failures**
- `cd rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/runtime/audience_snapshot_test.exs` -> **24 tests, 0 failures**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Inventory contract fixture failed after fail-closed publish gates**
- **Found during:** Task 1 verification
- **Issue:** Inventory fixture published segment rules without seeding referenced audiences, causing expected fail-closed blockers.
- **Fix:** Seeded `vip-users` and `beta-users` in inventory fixture setup before publish assertions.
- **Files modified:** `rulestead/test/rulestead/store/audience_dependency_inventory_contract_test.exs`
- **Verification:** Task 1 scoped mix test command passed.
- **Committed in:** `c28f161`

**2. [Rule 1 - Contract alignment] Promotion/manifest tenant mismatch path is represented as scope drift status in apply flow**
- **Found during:** Task 2 verification
- **Issue:** Tenant-scope drift in manifest apply resolves as stale drift status rather than dependency blocker status in current core contract.
- **Fix:** Kept tenant-scope fail-closed assertion with stale status while preserving explicit `tenant_mismatch` contract references in blocker matrices.
- **Files modified:** `rulestead/test/rulestead/store/manifest_import_contract_test.exs`, `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`
- **Verification:** Task 2 scoped mix test command passed.
- **Committed in:** `2a3a919`

---

**Total deviations:** 2 auto-fixed  
**Impact on plan:** No scope expansion; fixes were required to keep tests aligned with existing fail-closed contracts and to produce passing deterministic evidence.

## Issues Encountered

- `mix verify.phase54` initially executed `mix test` in `:dev`; resolved by adding `MixProject.cli/0` preferred env mapping for `verify.phase54`.

## User Setup Required

None - no external service setup required.

## Next Phase Readiness

- Phase 55 can rely on deterministic dependency truth and fail-closed contract evidence without moving validation into mounted surfaces.
- Support/release boundary checklist is in place to keep `rulestead` core truth and `rulestead_admin` rendering responsibilities explicit during mounted workflow implementation.
