---
phase: 09-governance-core-contracts-change-requests-and-approval-polic
verified: 2026-04-24T15:36:09Z
status: passed
score: 15/15 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 14/15
  gaps_closed:
    - "Governed mutations have durable storage tables and exact store command shapes before any root facade starts calling them."
  gaps_remaining: []
  regressions: []
---

# Phase 9: Governance Core Contracts, Change Requests, and Approval Policy Verification Report

**Phase Goal:** Establish the storage, domain contracts, policy hooks, and audit correlation model for governed mutations.
**Verified:** 2026-04-24T15:36:09Z
**Status:** passed
**Re-verification:** Yes - after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Governed mutations have canonical domain nouns, verbs, and lifecycle states before any persistence or UI wiring is added. | ✓ VERIFIED | `rulestead/lib/rulestead/governance/change_request.ex` defines the canonical states/actions, and `test/rulestead/governance/change_request_contract_test.exs` locks them. |
| 2 | A change request carries explicit actor, environment, governed action, payload snapshot, and correlation identifiers instead of inferring them from admin UI state. | ✓ VERIFIED | `Rulestead.Governance.ChangeRequest.new/1` and `serialize/1` persist `submitted_by`, `environment_key`, `action`, `command`, and `correlation_id` explicitly. |
| 3 | Approval requirements and self-approval posture are represented as explicit contracts that later policy and store plans can persist and enforce. | ✓ VERIFIED | `rulestead/lib/rulestead/governance/approval_requirement.ex` defines `required_approvals`, `change_request_required?`, and `self_approval_allowed?`; `Admin.Authorizer` resolves snapshots from policy hooks. |
| 4 | Governed mutations have durable storage tables and exact store command shapes before any root facade starts calling them. | ✓ VERIFIED | `MIX_ENV=test mix ecto.migrations` lists `20260424000100 create_rulestead_change_requests_and_approvals`, `MIX_ENV=test mix ecto.drop --force && mix ecto.create && mix ecto.migrate` applied it successfully, and the store command/store callback surfaces are present in `store.ex` and `store/command.ex`. |
| 5 | Audit events can carry immutable governance correlation fields linking submission, approval, rejection, cancellation, and execution. | ✓ VERIFIED | `rulestead/lib/rulestead/audit_event.ex` normalizes `change_request_id`, `approval_id`, `governance_action`, and `execution_stage`; governance audit tests remain green. |
| 6 | Store-level commands for change requests and approvals stay key-first and actor-bearing, matching the existing sibling-package/public-API design. | ✓ VERIFIED | `rulestead/lib/rulestead/store/command.ex` defines explicit governance command structs with actor/reason/metadata envelopes; `test/rulestead/store/command_governance_test.exs` locks the shape. |
| 7 | Host policy can declare when a governed production mutation requires a change request instead of direct execution. | ✓ VERIFIED | `rulestead/lib/rulestead/admin/policy.ex` exposes optional governance callbacks, and `test/rulestead/admin_governance_policy_test.exs` proves production publish can require a change request. |
| 8 | The default governance posture prevents self-approval for production change requests unless the host explicitly opts out. | ✓ VERIFIED | `rulestead/lib/rulestead/admin/authorizer.ex` fails closed on production self-approval, and `test/rulestead/governance_threat_model_test.exs` proves denial without caller-supplied submitter echoes. |
| 9 | Policy decisions stay on the host-owned auth seam and do not introduce bundled identity or role lookup inside `rulestead`. | ✓ VERIFIED | Governance remains an optional callback extension on `Rulestead.Admin.Policy`; no bundled identity/session framework was added to the core package. |
| 10 | The public `Rulestead` facade exposes governed-change verbs for submit, approve, reject, cancel, and execute without requiring `rulestead_admin`. | ✓ VERIFIED | `rulestead/lib/rulestead.ex` exports the five verbs and routes them through the existing admin write/auth envelope; `test/rulestead/governance_facade_contract_test.exs` covers the public surface. |
| 11 | Both Ecto and Fake adapters implement the same governance operations so contract tests and host apps can exercise governed flows through either backend. | ✓ VERIFIED | `test/rulestead/store/governance_adapter_contract_test.exs` runs the lifecycle assertions against `Rulestead.Fake` and `Rulestead.Store.Ecto`, including fetch/list parity. |
| 12 | Every governance transition emits immutable correlated audit metadata and the canonical `change_request.*` admin telemetry events. | ✓ VERIFIED | `rulestead/lib/rulestead/store/ecto.ex` and `rulestead/lib/rulestead/fake.ex` append `change_request.*` audit rows and call `Telemetry.execute([:rulestead, :admin, :change_request, ...], ...)`; `rulestead/lib/rulestead/telemetry.ex` preserves governance metadata fields. |
| 13 | Phase 9 safety rules are provable with one repeatable verification entrypoint instead of tribal knowledge. | ✓ VERIFIED | `scripts/ci/verify_phase09_governance.sh` now checks migration discoverability first, then runs the governance suites and the narrow `rulestead_admin` smoke slice. |
| 14 | Contract tests prove change-request submission, peer approval, self-approval denial, cancellation, rejection, and correlated execution behavior. | ✓ VERIFIED | `bash scripts/ci/verify_phase09_governance.sh` passed with `24 tests, 0 failures` in `rulestead` and `6 tests, 0 failures` in `rulestead_admin`. |
| 15 | Governance verification keeps sibling-package CI readability intact by using a scripts-first entrypoint that can include package-local smoke checks without folding in future UI work. | ✓ VERIFIED | The verifier script labels each step, keeps the `rulestead_admin` coverage to router/session smoke, and explicitly states that the carried Phase 07 `simulate_test.exs` gap is not claimed here. |

**Score:** 15/15 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `rulestead/lib/rulestead/governance/change_request.ex` | Canonical change-request contract | ✓ VERIFIED | Substantive module with fixed state/action vocabulary and serializer. |
| `rulestead/lib/rulestead/governance/approval.ex` | Approval review contract | ✓ VERIFIED | Shared request/correlation review contract present. |
| `rulestead/lib/rulestead/governance/approval_requirement.ex` | Explicit approval-policy snapshot | ✓ VERIFIED | Required approvals and self-approval posture explicit. |
| `rulestead/lib/rulestead/admin/policy.ex` | Host-owned governance policy seam | ✓ VERIFIED | Optional governance callbacks extend the existing auth seam. |
| `rulestead/lib/rulestead/admin/authorizer.ex` | Governance authorization and fail-closed rules | ✓ VERIFIED | Change-request requirement and self-approval denial implemented. |
| `rulestead/lib/rulestead/store.ex` | Governance callback surface | ✓ VERIFIED | Submit/approve/reject/cancel/execute/fetch/list callbacks declared. |
| `rulestead/lib/rulestead/store/command.ex` | Key-first governance command structs | ✓ VERIFIED | Actor-bearing governance commands and filter normalization are substantive. |
| `rulestead/lib/rulestead.ex` | Public governance facade | ✓ VERIFIED | Governance verbs route through the existing auth/redaction envelope. |
| `rulestead/lib/rulestead/store/ecto.ex` | Durable governance transitions and audit writes | ✓ VERIFIED | Store writes/read paths are implemented against the migrated tables. |
| `rulestead/lib/rulestead/fake.ex` | In-memory governance parity | ✓ VERIFIED | Matching lifecycle, audit correlation, and telemetry emission implemented. |
| `rulestead/lib/rulestead/telemetry.ex` | Canonical governance telemetry metadata helpers | ✓ VERIFIED | `governance_metadata/2` carries `change_request_id`, `correlation_id`, `audit_event_id`, and related fields. |
| `rulestead/lib/rulestead/audit_event.ex` | Normalized immutable governance audit metadata | ✓ VERIFIED | Governance fields are normalized into serialized audit metadata. |
| `rulestead/priv/repo/migrations/20260424000100_create_rulestead_change_requests_and_approvals.exs` | Durable governance schema migration | ✓ VERIFIED | Numeric migration filename is valid, substantive, and discoverable/applied by Ecto. |
| `scripts/ci/verify_phase09_governance.sh` | Scripts-first verifier | ✓ VERIFIED | Verifier now checks discoverability before the suite runs. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `change_request.ex` | `approval_requirement.ex` | embedded approval snapshot | ✓ WIRED | Change requests embed serialized approval requirements directly. |
| `approval.ex` | `change_request.ex` | shared request and correlation identifiers | ✓ WIRED | Approval contract carries `change_request_id` and `correlation_id`. |
| `store/command.ex` | `store.ex` | governance command structs consumed by callbacks | ✓ WIRED | Callback names and command modules match for submit/approve/reject/cancel/execute/fetch/list. |
| `admin/policy.ex` | `admin/authorizer.ex` | optional governance callbacks | ✓ WIRED | `policy_flag/6` resolves `change_request_required?/4` and `allow_self_approval?/4`. |
| `rulestead.ex` | store adapters | facade routes governed commands through auth plus store | ✓ WIRED | Public verbs call `admin_write/2`, which resolves persisted governance context before store execution. |
| `store/ecto.ex` and `fake.ex` | `audit_event.ex` and telemetry | correlated audit rows and `change_request.*` telemetry | ✓ WIRED | Both adapters append canonical audit events and emit `[:rulestead, :admin, :change_request, event]` telemetry. |
| governance migration file | Ecto migration runner | supported migration path | ✓ WIRED | `MIX_ENV=test mix ecto.migrations` lists `20260424000100`, and `MIX_ENV=test mix ecto.migrate` applies it. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `rulestead/lib/rulestead/store/ecto.ex` | `change_request`, `approval`, `audit_event` rows | `change_requests`, `approvals`, `audit_events` tables | Yes | ✓ FLOWING |
| `rulestead/lib/rulestead/fake.ex` | in-memory governance state | GenServer state maps | Yes | ✓ FLOWING |
| `rulestead/lib/rulestead.ex` | governed facade commands | `Admin.Authorizer` + configured store adapter | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Governance migration is discoverable by Ecto | `cd rulestead && MIX_ENV=test mix ecto.migrations` | Lists `20260424000100 create_rulestead_change_requests_and_approvals` as `up` | ✓ PASS |
| Governance migration applies through the supported install path | `cd rulestead && MIX_ENV=test mix ecto.drop --force && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate` | Migration ran forward successfully, including `20260424000100` with `create table change_requests` and `create table approvals` | ✓ PASS |
| Scripts-first Phase 09 verifier stays green | `bash scripts/ci/verify_phase09_governance.sh` | Governance suites passed (`24 tests, 0 failures`) and admin smoke passed (`6 tests, 0 failures`) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `GOV-01` | `09-01`, `09-02`, `09-04`, `09-05` | Operator can submit a change request instead of directly executing a governed production mutation. | ✓ SATISFIED | Public facade verbs, adapter parity, and the migrated durable tables are all in place. |
| `GOV-02` | `09-01`, `09-03`, `09-04`, `09-05` | Host policy can require approvals by environment and action for publish, rollout, kill-switch, and settings mutations. | ✓ SATISFIED | Policy hooks plus `Admin.Authorizer` resolve and enforce environment-sensitive approval requirements. |
| `GOV-03` | `09-01`, `09-03`, `09-04`, `09-05` | Default governance policy prevents self-approval for production change requests unless the host explicitly overrides it. | ✓ SATISFIED | Threat-model and policy tests prove default denial in production. |
| `GOV-04` | `09-01`, `09-02`, `09-04`, `09-05` | Approval, rejection, execution, and cancellation of change requests append correlated immutable audit events. | ✓ SATISFIED | Ecto and Fake adapters both emit correlated immutable audit rows across the lifecycle. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `rulestead/test/rulestead/governance_threat_model_test.exs` | 202 | Manual `Repo.query!/1` schema bootstrap for governance tables | ⚠ Warning | Can mask future migration drift inside this suite, although the migration discoverability/install-path checks now close the original blocker. |
| `rulestead/test/rulestead/store/governance_adapter_contract_test.exs` | 246 | Manual `Repo.query!/1` schema bootstrap for governance tables | ⚠ Warning | Same masking risk for adapter parity tests if the migration changes and the helper is not updated. |
| `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-02-PLAN.md` | 9 | Planning artifact still references the old `TIMESTAMP_...` migration path | ℹ Info | Documentation drift only; the code and verification now point to the real numeric migration filename. |

### Gaps Summary

No blocking gaps remain. The prior migration-path failure is closed: the governance migration now has a valid numeric filename, Ecto discovers and applies it through the supported path, and the phase verifier script fails fast if that discoverability regresses.

Residual risk is limited to non-blocking drift in two test helpers that still bootstrap governance tables manually. Those helpers no longer invalidate Phase 09 because the install path is now spot-checked directly, but they are worth tightening in a future cleanup if the migration evolves.

---

_Verified: 2026-04-24T15:36:09Z_
_Verifier: Claude (gsd-verifier)_
