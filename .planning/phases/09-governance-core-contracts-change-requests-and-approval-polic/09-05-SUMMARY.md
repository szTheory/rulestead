---
phase: 09-governance-core-contracts-change-requests-and-approval-polic
plan: 05
subsystem: testing
tags: [governance, contracts, threat-model, ci, sibling-packages]
requires:
  - phase: 09-governance-core-contracts-change-requests-and-approval-polic
    provides: stable governance facade verbs, adapter parity, and approval-policy seams from 09-01 through 09-04
provides:
  - executable governance lifecycle and threat-model coverage for submit approve reject cancel and execute flows
  - governed direct-publish enforcement at the root facade
  - scripts-first Phase 09 verifier spanning core governance tests and admin smoke coverage
affects: [phase-09-closeout, governance-ui, scheduler, release-ci]
tech-stack:
  added: []
  patterns: [tdd, persisted-governance-auth-context, scripts-first phase verification]
key-files:
  created:
    - .planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-05-SUMMARY.md
    - rulestead/test/rulestead/governance_safety_contract_test.exs
    - rulestead/test/rulestead/governance_threat_model_test.exs
    - scripts/ci/verify_phase09_governance.sh
  modified:
    - rulestead/lib/rulestead.ex
key-decisions:
  - "Governance transition verbs authorize from persisted change-request context instead of trusting caller-supplied metadata echoes."
  - "The Phase 09 verifier keeps sibling-package visibility to the already-green router/session slice and explicitly leaves the carried Phase 07 simulate gap open."
patterns-established:
  - "Public governance transition commands can be validated from `change_request_id` plus actor alone."
  - "Phase-scoped CI entrypoints state what they verify and what they intentionally do not claim."
requirements-completed: [GOV-01, GOV-02, GOV-03, GOV-04]
duration: 7min
completed: 2026-04-24
---

# Phase 09 Plan 05: Governance safety verifier summary

**Facade-level governance safety tests, production direct-publish guards, and one scripts-first verifier that keeps sibling-package smoke visible without overstating Phase 7 closure**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-24T15:10:00Z
- **Completed:** 2026-04-24T15:16:49Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added focused governance lifecycle tests that prove submit, peer approve, reject, cancel, and execute behavior through the public facade.
- Added threat-model tests that prove production self-approval denial, direct publish change-request enforcement, and correlated immutable audit rows.
- Added `scripts/ci/verify_phase09_governance.sh` as the single readable verifier for the new core coverage plus the intentionally narrow admin smoke slice.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add governance contract tests that prove the full safety lifecycle** - `425c006` (test), `3582f1e` (feat)
2. **Task 2: Package Phase 9 verification into a scripts-first CI entrypoint with sibling-package smoke visibility** - `9a843e6` (chore)

## Files Created/Modified

- `rulestead/test/rulestead/governance_safety_contract_test.exs` - Locks the public-facade lifecycle contract for submit, approve, reject, cancel, and execute flows.
- `rulestead/test/rulestead/governance_threat_model_test.exs` - Proves production direct-publish denial, self-approval denial, and correlated Ecto audit rows.
- `rulestead/lib/rulestead.ex` - Hydrates persisted change-request context before authorizing governance transitions and routes direct publish through governed-action authorization.
- `scripts/ci/verify_phase09_governance.sh` - Runs the new governance suites plus the green admin router/session smoke slice with explicit step labels.

## Decisions Made

- Governance transition authorization now derives submitter, action, resource, and environment from stored change-request data rather than command metadata.
- The Phase 09 verifier intentionally includes only `rulestead_admin` router/session smoke coverage and prints that the `simulate_test.exs` gap remains a tracked Phase 07 carryover.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Approval and transition authorization trusted missing metadata instead of persisted change-request context**
- **Found during:** Task 1 (Add governance contract tests that prove the full safety lifecycle)
- **Issue:** `approve_change_request/1`, `reject_change_request/1`, `cancel_change_request/1`, and `execute_change_request/1` could fall back to `:manage_settings` / `nil` environment semantics when callers did not duplicate governance metadata, breaking self-approval denial and environment-sensitive authorization.
- **Fix:** Loaded the stored change request before authorization and normalized `{:ok, %ApprovalRequirement{}}` authorizer responses to `:ok` at the facade layer.
- **Files modified:** `rulestead/lib/rulestead.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/governance_safety_contract_test.exs test/rulestead/governance_threat_model_test.exs`
- **Committed in:** `3582f1e`

**2. [Rule 1 - Bug] Direct production publish bypassed the governed-action gate**
- **Found during:** Task 1 (Add governance contract tests that prove the full safety lifecycle)
- **Issue:** `publish_ruleset/1` still used plain admin authorization, so production direct publish could proceed even when a change request was required.
- **Fix:** Routed root-facade publish authorization through `Authorizer.authorize_governed_action/4`, preserving denied-audit persistence for blocked direct publishes.
- **Files modified:** `rulestead/lib/rulestead.ex`
- **Verification:** `bash scripts/ci/verify_phase09_governance.sh`
- **Committed in:** `3582f1e`

---

**Total deviations:** 2 auto-fixed (2 rule-1 bugs)
**Impact on plan:** Both fixes were required to make the new Phase 09 safety proofs true at the public facade. No scope creep.

## Issues Encountered

- The initial RED run exposed two latent facade bugs rather than just missing tests: approval transitions were metadata-dependent, and direct publish was not using the governed-action authorizer.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 09 now closes with one repeatable verifier that proves the governance safety rules and keeps sibling-package smoke visible.
- Later UI or orchestration work can rely on `change_request_id`-only transition commands instead of duplicating governance metadata client-side.
- The carried Phase 07 `simulate_test.exs` authorization drift remains intentionally open and is not masked by this verifier.

## Self-Check: PASSED

---
*Phase: 09-governance-core-contracts-change-requests-and-approval-polic*
*Completed: 2026-04-24*
