---
phase: 53-impact-preview-contract
plan: 04
subsystem: store
tags: [elixir, ecto, audit, runtime-snapshot, audience, impact-preview, tdd]

requires:
  - phase: 53-01
    provides: Core ImpactPreview and AudienceDependencies contract.
  - phase: 53-02
    provides: Snapshot-local runtime audience compilation and evaluator behavior.
  - phase: 53-03
    provides: Public store command contract and Fake store parity.
provides:
  - Ecto preview/apply/archive enforcement with transaction-time fingerprint revalidation.
  - Durable support-safe audit evidence for accepted, blocked, and denied audience mutations.
  - Ecto runtime snapshot payloads containing compiled non-archived audience definitions.
affects: [phase-54, phase-55, phase-56, targeting, audit, runtime]

tech-stack:
  added: []
  patterns:
    - Ecto.Multi preview revalidation before durable audience mutation.
    - Audit-only blocked and denied audience mutation evidence.
    - Snapshot-local audience payloads for runtime evaluation.

key-files:
  created:
    - rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs
    - rulestead/test/rulestead/audience_mutation_audit_test.exs
  modified:
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/audit_event.ex
    - rulestead/lib/rulestead/store/command.ex

key-decisions:
  - "Archived Ecto audiences are omitted from runtime snapshot payloads; runtime compilation sees them as unavailable."
  - "Apply commands carry explicit samples so preview fingerprints remain fresh when sample evidence contributes to the preview."
  - "Blocked and denied audience mutations persist support-safe audit rows without mutating the audience."

patterns-established:
  - "Audience mutations re-run ImpactPreview inside the store transaction and compare the submitted fingerprint before update/archive."
  - "Audience audit metadata keeps preview evidence, blockers, and redacted sample evidence while recursively dropping sensitive context keys."
  - "Ecto snapshot publication includes non-archived audience definitions alongside flag payloads."

requirements-completed: [IMP-01, IMP-02, IMP-03, IMP-04]

duration: 12m 18s
completed: 2026-05-27
---

# Phase 53 Plan 04: Ecto Impact Preview Contract Summary

**Ecto-backed audience preview/apply enforcement with support-safe audit evidence and snapshot-local runtime audience payloads**

## Performance

- **Duration:** 12m 18s
- **Started:** 2026-05-27T10:13:11Z
- **Completed:** 2026-05-27T10:25:29Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added Ecto `preview_audience_impact/1` and `apply_audience_mutation/1` paths that rebuild the preview inside an `Ecto.Multi`, reject stale or incompatible confirmations, and leave audience rows unchanged on fail-closed cases.
- Persisted reconstructable audience mutation audit evidence for accepted, blocked, and denied outcomes, including preview fingerprint, references, scope, actor/reason, blockers, uncertainty, and redacted sample evidence.
- Published Ecto runtime snapshots with a non-archived `audiences` map so Plan 02 runtime compilation can evaluate audience references from snapshot data.

## Task Commits

Each task was committed atomically with TDD red and green commits:

1. **Task 1 RED: Ecto audience impact contract proof** - `0550150` (test)
2. **Task 1 GREEN: Ecto preview/apply enforcement** - `716f912` (feat)
3. **Task 2 RED: Audience mutation audit proof** - `3476c93` (test)
4. **Task 2 GREEN: Support-safe audit evidence** - `dd7e216` (feat)
5. **Task 3 RED: Ecto audience snapshot proof** - `d83e48c` (test)
6. **Task 3 GREEN: Ecto runtime snapshot audiences** - `ac79316` (feat)

## Files Created/Modified

- `rulestead/lib/rulestead/store/ecto.ex` - Implements Ecto preview/apply/archive enforcement, blocked/denied audit writes, and audience definitions in runtime snapshots.
- `rulestead/lib/rulestead/audit_event.ex` - Preserves support-safe preview/audit metadata and recursively scrubs sensitive keys.
- `rulestead/lib/rulestead/store/command.ex` - Carries explicit preview samples through apply commands so fingerprints can be rebuilt consistently.
- `rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs` - Proves Ecto preview payload shape, fail-closed apply behavior, snapshot versions, and runtime compilation.
- `rulestead/test/rulestead/audience_mutation_audit_test.exs` - Proves accepted, blocked, and denied audit reconstruction without raw PII leakage.

## Decisions Made

- Archived audiences are omitted from runtime snapshot payloads instead of included with an archived marker. This matches the fail-closed runtime behavior from Plan 02 because archived references compile as unavailable audience keys.
- Apply commands now retain explicit samples from the confirmed preview input. Without that, a preview fingerprint based on authored state plus explicit samples could not be rebuilt at apply time.
- Blocked and denied mutation attempts write audit-only evidence rows. This preserves support reconstruction while keeping the audience mutation itself transactional and fail-closed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Preserve explicit samples through apply commands**
- **Found during:** Task 2 (Persist support-safe audience mutation audit evidence)
- **Issue:** Apply-time preview revalidation could not reproduce fingerprints for previews whose basis included explicit sample evidence unless the apply command retained those samples.
- **Fix:** Added `samples` to `Command.ApplyAudienceMutation` and used the same redacted sample path for revalidation and audit evidence.
- **Files modified:** `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/test/rulestead/audience_mutation_audit_test.exs`
- **Verification:** `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs test/rulestead/admin_security_contract_test.exs`
- **Committed in:** `dd7e216`

---

**Total deviations:** 1 auto-fixed Rule 2 issue.
**Impact on plan:** The change was required for correctness of the planned transaction-time fingerprint revalidation and did not add a future-phase feature.

## Issues Encountered

None beyond the planned TDD red failures and the auto-fixed apply-command sample preservation.

## Verification

- `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/store/audience_impact_contract_test.exs` - passed, 9 tests, 0 failures.
- `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs test/rulestead/admin_security_contract_test.exs` - passed, 9 tests, 0 failures.
- `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/runtime/audience_snapshot_test.exs` - passed, 12 tests, 0 failures.
- `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/audience_mutation_audit_test.exs test/rulestead/runtime/audience_snapshot_test.exs test/rulestead/store/audience_impact_contract_test.exs` - passed, 21 tests, 0 failures.
- `cd rulestead && mix compile --warnings-as-errors` - passed.
- `find rulestead/priv/repo/migrations -name '*.exs' -newer .planning/phases/53-impact-preview-contract/53-04-PLAN.md 2>/dev/null | wc -l` - printed `0`.

## Known Stubs

None. Stub scan found no TODO/FIXME/placeholder text or hardcoded empty values that prevent the plan goal. The intentional empty audience-key assertion covers the chosen archived-audience omission behavior.

## Threat Flags

None. The security-relevant surfaces added here are the planned threat-model surfaces T-53-19 through T-53-24: transaction-time preview revalidation, audit evidence persistence, PII scrubbing, protected mutation rejection, and snapshot-local audience payloads.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 54+ can rely on the Ecto reference store enforcing the same preview-confirm-apply contract as the core command surface, with durable audit evidence and runtime snapshots that do not perform live audience lookups.

## Self-Check: PASSED

- Summary file created at `.planning/phases/53-impact-preview-contract/53-04-SUMMARY.md`.
- Task commits verified in git history: `0550150`, `716f912`, `3476c93`, `dd7e216`, `d83e48c`, `ac79316`.
- No tracked file deletions were introduced by task commits.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were not modified.

---
*Phase: 53-impact-preview-contract*
*Completed: 2026-05-27*
