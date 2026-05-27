---
phase: 54-dependency-truth-and-promotion-safety
plan: 01
subsystem: api
tags: [dependency-inventory, ecto, fake, redaction, authorization]

requires:
  - phase: 53-impact-preview-contract
    provides: bounded audience impact preview + compare seams reused for dependency projection payloads
provides:
  - Canonical dependency inventory contract with deterministic scope-first sorting
  - Projection-backed audience dependency reads in Ecto with bootstrap rebuild path
  - Fake parity for dependency inventory reads and policy-safe partial redaction envelope
  - Public/store command surface for authorized dependency inventory reads
affects: [54-02, 54-03, DEP-01, DEP-04, promotion-safety, manifest-validation]

tech-stack:
  added: []
  patterns:
    - Projection-backed admin/read truth for dependency inventory (no runtime hot-path coupling)
    - Scope-explicit tuple ordering `{environment_key, tenant_key, flag_key, ruleset_version, rule_key, audience_key}`
    - Redacted partial-truth envelopes (`hidden_reference_count`, optional placeholders)

key-files:
  created:
    - rulestead/lib/rulestead/targeting/dependency_inventory.ex
    - rulestead/lib/rulestead/targeting/audience_reference_projection.ex
    - rulestead/lib/mix/tasks/rebuild.audience_reference_projection.ex
    - rulestead/priv/repo/migrations/20260527123000_create_audience_reference_projection.exs
    - rulestead/test/rulestead/targeting/dependency_inventory_test.exs
    - rulestead/test/rulestead/store/audience_dependency_inventory_contract_test.exs
  modified:
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/fake/control.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/admin/policy.ex
    - rulestead/lib/rulestead/admin/redaction.ex
    - rulestead/lib/rulestead/store/redis.ex
    - rulestead/test/rulestead/admin_security_contract_test.exs
    - rulestead/test/rulestead/release_contract_test.exs

key-decisions:
  - "Keep dependency inventory projection-backed and admin/read-path only; never attach to evaluator/snapshot hot path."
  - "Normalize tenant scope explicitly as `global` where host tenant key is absent to satisfy DEP-04 scope requirements."
  - "Centralize partial redaction behavior through `Admin.Redaction.redact_dependency_inventory/2` so Ecto/Fake stay behavior-compatible."

patterns-established:
  - "Projection refresh pattern: mutate authored state -> refresh per-environment inventory projection."
  - "Bootstrap pattern: explicit `rebuild_audience_reference_projection/0` + `mix rebuild.audience_reference_projection` for pre-existing authored rows."

requirements-completed: [DEP-01, DEP-04]
duration: 14 min
completed: 2026-05-27
---

# Phase 54 Plan 01: Dependency Truth And Promotion Safety Summary

**Shipped a canonical, deterministic audience dependency inventory with projection-backed Ecto/Fake parity and authorized redacted public read APIs for downstream promotion and manifest safety flows.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-05-27T13:00:00Z
- **Completed:** 2026-05-27T13:13:37Z
- **Tasks:** 3
- **Files modified:** 17

## Accomplishments
- Added `Rulestead.Targeting.DependencyInventory` with required-scope normalization, malformed detection, deterministic sort tuple, and redacted result shaping.
- Added `audience_reference_projection` schema/migration + Ecto/Fake refresh/query parity and bootstrap rebuild entrypoints.
- Exposed `Command.ListAudienceDependencies`, store callback, root `Rulestead.list_audience_dependencies/1`, and viewer-policy authorized partial truth outputs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement canonical dependency inventory envelope and stable sort semantics** - `038cdf8` (feat)
2. **Task 2: Add Ecto projection seam and Fake projection parity for inventory reads** - `7f8e4d8` (feat)
3. **Task 3: Expose public/store inventory APIs with policy-safe redacted partial truth** - `1db0f9c` (feat)

## Verification Evidence

- `MIX_ENV=test mix test test/rulestead/targeting/dependency_inventory_test.exs` -> **4 tests, 0 failures**
- `MIX_ENV=test mix test test/rulestead/store/audience_dependency_inventory_contract_test.exs` -> **3 tests, 0 failures**
- `MIX_ENV=test mix test test/rulestead/store/audience_dependency_inventory_contract_test.exs test/rulestead/admin_security_contract_test.exs test/rulestead/release_contract_test.exs` -> **23 tests, 0 failures**
- `MIX_ENV=test mix test test/rulestead/targeting/dependency_inventory_test.exs test/rulestead/store/audience_dependency_inventory_contract_test.exs test/rulestead/admin_security_contract_test.exs test/rulestead/release_contract_test.exs` -> **27 tests, 0 failures**

## Files Created/Modified
- `rulestead/lib/rulestead/targeting/dependency_inventory.ex` - canonical dependency inventory contract + sort/redaction helpers.
- `rulestead/lib/rulestead/targeting/audience_reference_projection.ex` - projection schema keyed by semantic dependency identity.
- `rulestead/priv/repo/migrations/20260527123000_create_audience_reference_projection.exs` - projection table + indexes/check constraints.
- `rulestead/lib/rulestead/store/ecto.ex` - projection refresh/query/rebuild seams + redacted inventory envelope.
- `rulestead/lib/rulestead/fake.ex` - in-memory projection parity + redacted inventory envelope.
- `rulestead/lib/rulestead/store/command.ex` - `ListAudienceDependencies` command struct.
- `rulestead/lib/rulestead/store.ex` - `list_audience_dependencies/1` callback.
- `rulestead/lib/rulestead.ex` - public `list_audience_dependencies/0,1` facade via `admin_read`.
- `rulestead/lib/rulestead/admin/policy.ex` - viewer action `:list_audience_dependencies`.
- `rulestead/lib/rulestead/admin/redaction.ex` - `redact_dependency_inventory/2` partial-truth helper.
- `rulestead/test/rulestead/store/audience_dependency_inventory_contract_test.exs` - Ecto/Fake parity + bootstrap/backfill pagination coverage.
- `rulestead/test/rulestead/admin_security_contract_test.exs` - authorized redaction contract coverage for dependency inventory reads.
- `rulestead/test/rulestead/release_contract_test.exs` - public API and store callback stability coverage updates.

## Decisions Made
- Projection identity uses full semantic scope `(environment, tenant, flag, ruleset, rule, audience)` to prevent cross-scope collisions.
- Inventory read output always sorts through `DependencyInventory.sort_entries/1` before paging/redaction to guarantee deterministic ordering.
- Partial truth is represented explicitly using `hidden_reference_count`, `redacted`, and optional `redacted_entries` placeholders.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing required-field malformed detection for nil tenant values**
- **Found during:** Task 1
- **Issue:** `normalize_string/1` atom handling converted `nil` to `"nil"`, suppressing malformed scope detection.
- **Fix:** Reordered normalization clauses and tightened helper defaults.
- **Files modified:** `rulestead/lib/rulestead/targeting/dependency_inventory.ex`
- **Verification:** `MIX_ENV=test mix test test/rulestead/targeting/dependency_inventory_test.exs`
- **Committed in:** `038cdf8`

**2. [Rule 3 - Blocking] Projection refresh transaction API mismatch**
- **Found during:** Task 2
- **Issue:** `Repo.transact/1` function form expected `{:ok | :error, _}` return values and raised on raw map return.
- **Fix:** Switched to `Repo.transaction/1` for projection rebuild/refresh helper.
- **Files modified:** `rulestead/lib/rulestead/store/ecto.ex`
- **Verification:** `MIX_ENV=test mix test test/rulestead/store/audience_dependency_inventory_contract_test.exs`
- **Committed in:** `7f8e4d8`

**3. [Rule 1 - Bug] Fake projection payload missing explicit environment key extraction**
- **Found during:** Task 2
- **Issue:** Fake projection builder assumed `payload.environment_key`; actual compare payload shape stores environment under `payload.environment.key`.
- **Fix:** Added payload extraction helpers and normalized projection context conversion.
- **Files modified:** `rulestead/lib/rulestead/fake.ex`
- **Verification:** `MIX_ENV=test mix test test/rulestead/store/audience_dependency_inventory_contract_test.exs`
- **Committed in:** `7f8e4d8`

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocker)
**Impact on plan:** All deviations were required for correctness and adapter parity; no scope creep beyond Plan 01 goals.

## Issues Encountered
- Local migration required `MIX_ENV=test` because default runtime repo config did not include a development database key; resolved by running migration in test environment.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Dependency inventory truth surface is now stable, deterministic, and API-exposed for downstream validator and promotion/manifest integration work.
- Phase 54 Plan 02 can now consume this projection/read contract for fail-closed publish and mutation gates.

---
*Phase: 54-dependency-truth-and-promotion-safety*
*Completed: 2026-05-27*
