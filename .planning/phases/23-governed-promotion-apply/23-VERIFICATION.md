---
phase: 23-governed-promotion-apply
verified: 2026-05-18T22:36:14Z
status: complete
score: 12/12 must-haves verified
overrides_applied: 0
human_verification: []
---

# Phase 23: Governed Promotion Apply Verification Report

**Phase Goal:** Whole-flag environment configuration can be promoted safely into a target environment through the existing mutation, approval, audit, and mounted-admin review envelope.
**Verified:** 2026-05-18T22:36:14Z
**Status:** complete

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Direct promotion applies authored state rather than cloning runtime snapshots. | ✓ VERIFIED | `23-01` introduced the shared `Rulestead.Promotion.Apply` contract, direct facade wiring, and adapter parity coverage in `rulestead/test/rulestead/promotion/apply_test.exs` and `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`. |
| 2 | Successful direct apply records immutable environment history and regenerates the target snapshot in the same authoritative write. | ✓ VERIFIED | `23-01` added `Rulestead.EnvironmentVersion`, the environment-version migration, and targeted persistence coverage in `rulestead/test/rulestead/environment_version_test.exs`. |
| 3 | Promotion scope stays bounded to the selected flag set. | ✓ VERIFIED | The Phase 23 apply contract is driven by the reviewed compare bundle and explicit `flag_keys`, with direct-apply regression coverage in `rulestead/test/rulestead/promotion/apply_test.exs`. |
| 4 | Promotion is accepted as a first-class governed action. | ✓ VERIFIED | `23-02` extended approval, policy, authorizer, change-request, scheduled-execution, and persistence vocabularies, proven by `rulestead/test/rulestead/governance_facade_contract_test.exs` and `rulestead/test/rulestead/governance_safety_contract_test.exs`. |
| 5 | Governed promotion stores the reviewed bundle snapshot for later execution. | ✓ VERIFIED | `23-02` persists promotion intent in `command_snapshot`, and the later execution tests depend on that exact stored payload. |
| 6 | Approved governed promotion executes the stored bundle instead of recomputing fresh source intent. | ✓ VERIFIED | `23-03` routes approved execution back through the shared apply contract, covered by `rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs`. |
| 7 | Scheduled promotion revalidates compare freshness and dependency safety before mutating the target. | ✓ VERIFIED | `23-03` adds schedule-time revalidation with failure-safe behavior, covered by the same scheduled-execution adapter suite. |
| 8 | Promotion audit metadata records canonical source, target, compare token, governance linkage, and environment-version ids. | ✓ VERIFIED | `23-04` normalizes promotion audit truth in `rulestead/lib/rulestead/audit_event.ex`, covered by `rulestead/test/rulestead/audit_event_governance_test.exs`. |
| 9 | Re-apply version is modeled as a fresh forward promotion rather than a rollback shortcut. | ✓ VERIFIED | `23-04` keeps re-apply on the promotion/apply path and proves it in `rulestead/test/rulestead/promotion/reapply_version_test.exs`. |
| 10 | The mounted compare route remains the operator entrypoint for promotion and re-apply. | ✓ VERIFIED | `23-05` wires compare review and re-apply deep links through the existing mounted screens, covered by `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` and `show_test.exs`. |
| 11 | Change-request and schedule detail screens render stored promotion intent instead of inventing a separate console. | ✓ VERIFIED | `23-05` updates the mounted admin review surfaces, covered by `rulestead_admin/test/rulestead_admin/live/change_request_live/show_test.exs` and `schedule_live/show_test.exs`. |
| 12 | The admin package remains a bounded mounted companion package. | ✓ VERIFIED | The shipped UI work stays within `rulestead_admin` LiveViews and tests without introducing standalone publish or release-orchestration surfaces. |

**Score:** 12/12 truths verified

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Backend promotion apply, governance execution, audit linkage, and re-apply path | `cd rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/environment_version_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/governance_facade_contract_test.exs test/rulestead/governance_safety_contract_test.exs test/rulestead/store/scheduled_execution_adapter_contract_test.exs test/rulestead/audit_event_governance_test.exs test/rulestead/promotion/reapply_version_test.exs` | `23 tests, 0 failures` | ✓ PASS |
| Mounted admin promotion handoff, governed review, and re-apply deep links | `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs test/rulestead_admin/live/change_request_live/show_test.exs test/rulestead_admin/live/schedule_live/show_test.exs` | `12 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PROM-03` | `23-01`, `23-03`, `23-04`, `23-05` | Promote whole-flag authored configuration safely between environments without runtime-snapshot cloning. | ✓ SATISFIED | Direct apply, stored-snapshot execution, immutable history, and re-apply coverage all passed in the targeted backend and mounted-admin suites. |
| `PROM-04` | `23-02`, `23-03`, `23-04`, `23-05` | Protected-environment promotion stays inside the existing governance, audit, approval, and operator review surfaces. | ✓ SATISFIED | Governance vocabulary, stored reviewed snapshots, audit linkage, mounted review screens, and scheduling flows all passed targeted tests. |

### Gaps Summary

No requirement-level or phase-goal gaps were found in the targeted Phase 23 verification run.

---

_Verified: 2026-05-18T22:36:14Z_
_Verifier: Codex_
