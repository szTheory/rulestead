---
phase: 53-impact-preview-contract
plan: 03
subsystem: targeting
tags: [elixir, store, fake-adapter, audience, impact-preview, tdd]

requires:
  - phase: 53-impact-preview-contract
    provides: pure impact preview fingerprints and affected-reference summaries
provides:
  - Public facade and Store behavior callbacks for audience impact preview and guarded mutation.
  - Command structs carrying scoped preview evidence, actor, reason, metadata, and protected mutation posture.
  - Fake adapter preview/apply semantics with stale fingerprint, tenant mismatch, archive, delete-attempt, and protected-targeting fail-closed checks.
  - Redis read-only callback parity for the new audience impact surface.
affects: [phase-53, phase-54, phase-55, targeting, store, audit]

tech-stack:
  added: []
  patterns:
    - TDD RED/GREEN task commits for public/store audience impact contracts.
    - Existing admin_read/admin_write envelope reused for audience resources.
    - Fake adapter rebuilds current preview before mutation to reject stale confirmation evidence.

key-files:
  created:
    - rulestead/test/rulestead/store/audience_impact_contract_test.exs
  modified:
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/admin/policy.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/fake/control.ex
    - rulestead/lib/rulestead/store/redis.ex
    - rulestead/test/rulestead/release_contract_test.exs

key-decisions:
  - "Audience preview is an admin read and audience apply is an admin write, both using `%{resource_type: :audience, resource_key: audience_key}`."
  - "Fake apply rebuilds the current preview and requires the command fingerprint to match before mutating audience state."
  - "Redis remains read-only for the new callbacks, leaving Ecto persistence and durable audit implementation to Plan 53-04."

patterns-established:
  - "Audience mutation command validation fails before store dispatch when preview fingerprint, current schema version, or reason is missing."
  - "Fake audience mutation audit metadata carries preview fingerprint, schema version, preview basis, and affected reference keys."

requirements-completed: [IMP-01, IMP-02]

duration: 12min
completed: 2026-05-27
---

# Phase 53 Plan 03: Public/Store Audience Impact Contract Summary

**Public and Store audience impact preview/apply contracts with Fake stale-fingerprint enforcement and Redis read-only parity.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T09:57:32Z
- **Completed:** 2026-05-27T10:09:58Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `PreviewAudienceImpact` and `ApplyAudienceMutation` command structs plus Store callbacks and release-contract coverage.
- Added `Rulestead.preview_audience_impact/1/2/3` and `Rulestead.apply_audience_mutation/1/2` through existing admin authorization envelopes.
- Implemented Fake adapter preview/apply behavior that rebuilds current preview fingerprints, mutates only fresh confirmed updates/archives, and fails closed for stale, archived, tenant-mismatched, protected, or delete-attempt cases.
- Added Redis unsupported callback entries for the new surface.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Audience command contracts** - `4ed6257` (test)
2. **Task 1 GREEN: Audience command and Store callbacks** - `4f593eb` (feat)
3. **Task 2 RED: Public facade contract** - `a12ab44` (test)
4. **Task 2 GREEN: Admin envelope facade routing** - `125a2d4` (feat)
5. **Task 3 RED: Fake/Redis adapter contract** - `434660b` (test)
6. **Task 3 GREEN: Fake/Redis adapter parity** - `f902a18` (feat)

**Plan metadata:** this summary docs commit

## Files Created/Modified

- `rulestead/lib/rulestead/store/command.ex` - Adds audience preview/apply command structs and normalization.
- `rulestead/lib/rulestead/store.ex` - Adds Store behavior callbacks.
- `rulestead/lib/rulestead.ex` - Adds public facade functions, validation, audience resource mapping, and denied mutation persistence routing.
- `rulestead/lib/rulestead/admin/policy.ex` - Classifies preview as viewer-readable and apply as editor-writeable for fallback authorization.
- `rulestead/lib/rulestead/fake.ex` - Adds Fake preview/apply handlers and fail-closed semantics.
- `rulestead/lib/rulestead/fake/control.ex` - Adds `put_audience!/1` test seeding helper.
- `rulestead/lib/rulestead/store/redis.ex` - Adds read-only unsupported callbacks.
- `rulestead/test/rulestead/store/audience_impact_contract_test.exs` - Adds facade and Fake adapter contract tests.
- `rulestead/test/rulestead/release_contract_test.exs` - Adds command/callback/public export expectations.

## Decisions Made

- Used the canonical audience resource shape in authorization instead of inventing a new resource payload.
- Kept `delete_attempt` unsupported in Fake with `audience_delete_unsupported`, matching the plan boundary before Ecto delete semantics exist.
- Left Ecto callback implementation to Plan 53-04 while the new Store behavior warnings remain visible during targeted tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added fallback policy classification for audience actions**
- **Found during:** Task 2 (public facade routing)
- **Issue:** The plan listed `rulestead/lib/rulestead.ex` but the new actions also needed fallback authorization classification or viewer/editor roles would treat them as generic editor actions.
- **Fix:** Added `:preview_audience_impact` to viewer actions and `:apply_audience_mutation` to editor actions.
- **Files modified:** `rulestead/lib/rulestead/admin/policy.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/admin_security_contract_test.exs`
- **Committed in:** `125a2d4`

**2. [Rule 1 - Bug] Preserved string preview basis through apply command normalization**
- **Found during:** Task 3 (Fake stale fingerprint enforcement)
- **Issue:** `ApplyAudienceMutation` normalized string `preview_basis` values to an empty map, causing fresh Fake applies to appear stale.
- **Fix:** Accepted either map/list preview basis values or normalized string basis values.
- **Files modified:** `rulestead/lib/rulestead/store/command.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs`
- **Committed in:** `f902a18`

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 1).
**Impact on plan:** Both fixes were required for correct authorization and fingerprint freshness semantics. No future-phase UI or Ecto persistence scope was added.

## Issues Encountered

Targeted verification passes but emits expected behavior warnings for missing Ecto implementations of the new callbacks. Plan 53-04 owns Ecto enforcement and durable audit persistence.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. Stub-pattern scan only found existing literal assertions and blank-string guards, not placeholder functionality.

## Verification

- `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/admin_security_contract_test.exs test/rulestead/release_contract_test.exs` - 25 tests, 0 failures.
- Task 1 acceptance rg checks - passed for command fields and Store callbacks.
- Task 2 acceptance rg checks - passed for public facade routing and validation coverage.
- Task 3 acceptance rg checks - passed for Fake behavior, `put_audience!`, Redis unsupported callbacks, and contract tests.

## Next Phase Readiness

Ready for Plan 53-04 to implement Ecto persistence, durable audit evidence, and snapshot publication for accepted/blocked/denied audience mutations using the command and Fake contract established here.

## Self-Check: PASSED

- Created file exists: `rulestead/test/rulestead/store/audience_impact_contract_test.exs`.
- Modified files exist: command, Store behavior, facade, policy, Fake, Fake control, Redis, and release contract files.
- Task commits found: `4ed6257`, `4f593eb`, `a12ab44`, `125a2d4`, `434660b`, `f902a18`.
- Shared orchestrator files were not modified: `.planning/STATE.md` and `.planning/ROADMAP.md`.

---
*Phase: 53-impact-preview-contract*
*Completed: 2026-05-27*
