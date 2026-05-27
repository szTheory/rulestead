---
phase: 62-orchestration-and-governed-execution
reviewed: 2026-05-27T20:15:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - rulestead/lib/rulestead/governance/rollout_auto_advance/schedule.ex
  - rulestead/lib/rulestead/governance/rollout_auto_advance.ex
  - rulestead/lib/rulestead/store/command.ex
  - rulestead/lib/rulestead/store/ecto.ex
  - rulestead/lib/rulestead/fake.ex
  - rulestead/lib/rulestead/fake/control.ex
  - rulestead/lib/rulestead/fake/orchestration_store.ex
  - rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
  - rulestead/test/support/store_fixtures.ex
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues
---

# Phase 62: Code Review Report

**Reviewed:** 2026-05-27T20:15:00Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** issues

## Summary

Phase 62 delivers governed auto-advance orchestration end-to-end: post-advance schedule hook with deterministic idempotency, `RolloutAutoAdvance.execute_scheduled_tick/3` (snapshot freshness → policy → fresh signals → eligibility → advance or CR submit), protected-environment routing via `Authorizer.approval_requirement/4`, and eight Fake/Ecto contract scenarios.

Review focused on T-62-07 (`policy_bypass` schedule mode), T-62-08 (no auto-approve in protected environments), and Fake/Ecto adapter parity. Verified `mix compile --warnings-as-errors` and the phase 62 regression suite (29 tests, 0 failures).

**Security assessment (T-62-07 / T-62-08):** No bypass or auto-approve vulnerabilities found. Automation ticks use `execution_mode: :policy_bypass` at schedule time (internal store path, `system:scheduler` actor), but execute-time orchestration re-consults `Authorizer.approval_requirement/4` and routes protected environments to `submit_change_request/1` only — never `approve_change_request/1` or direct `advance_rollout/1`. Contract test `"protected environment submits change request does not auto-advance"` passes on both adapters.

**Quality assessment:** Core orchestration logic is sound; one Fake/Ecto audit parity gap remains (see WR-01).

---

## Findings

### WR-01 — Fake missing `scheduled_execution.succeeded` audit with CR link (Fake/Ecto parity)

**Severity:** warning  
**Threat ref:** T-62-09 (adapter parity), 62-03 deliverable  
**Files:** `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`

Ecto `finalize_scheduled_execution_success/4` inserts a `scheduled_execution.succeeded` audit event and merges `RolloutAutoAdvance.automation_audit_metadata/1` (including `change_request_id` when outcome is `:change_request_submitted`). Fake `run_scheduled_execution/3` merges `automation_execution_metadata/1` into `execution_metadata` on the scheduled execution row but never appends a corresponding audit event.

**Impact:** Operators auditing via Fake (tests, local dev) will not see the scheduled-execution success audit with CR linkage that Ecto emits. `execution_metadata` parity holds; audit trail parity does not.

**Recommendation:** Mirror Ecto's `insert_scheduled_execution_audit_event/6` call in Fake's successful `run_scheduled_execution/3` path for policy-bypass ticks, or add a shared helper both adapters call on finalize.

---

### IN-01 — `approval_requirement/4` uses `system:scheduler` actor at execute time

**Severity:** info  
**Threat ref:** T-62-07  
**Files:** `rulestead/lib/rulestead/governance/rollout_auto_advance.ex`

Protected-env routing calls `Authorizer.approval_requirement(Schedule.scheduler_actor(), :advance_rollout, resource, environment_key)`. Default Authorizer behavior keys off `environment_key` (production → CR required), but host `Admin.Policy` implementations receive the system actor in `change_request_required?/4`. Policies that exempt `%{"type" => "system"}` actors in production could allow direct automation advance.

**Impact:** Low with default/nil policy; host misconfiguration risk only.

**Recommendation:** Document in admin integration guide that `change_request_required?/4` must not exempt system actors for governed actions in protected environments, or consider an environment-only overload for automation ticks.

---

### IN-02 — Ecto schedule hook is fail-open; Fake is not

**Severity:** info  
**Threat ref:** T-62-02  
**Files:** `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`

`maybe_schedule_auto_advance_tick/2` in Ecto wraps scheduling in `try/rescue` and emits telemetry on failure so `advance_rollout` still returns `{:ok, …}`. Fake `maybe_schedule_auto_advance_tick_in_state/2` has no equivalent guard; an unexpected raise during in-memory schedule would fail the advance.

**Impact:** Low — Fake schedule path is in-memory and unlikely to raise the Oban/schema failures that motivated Ecto fail-open. Parity gap for defensive consistency only.

**Recommendation:** Optional — wrap Fake schedule hook in rescue for symmetry, or document as intentional (Fake has no Oban dependency).

---

## Verified Behaviors

| Requirement | Threat | Verified |
|-------------|--------|----------|
| ORC-01 schedule → execute envelope | T-62-01–06 | Idempotency key, schedule hook, orchestrator pipeline, stale snapshot fail-closed |
| ORC-02 replay / race safety | T-62-10–11 | Contract tests: duplicate execute, manual-advance race, idempotent schedule |
| ROL-06 protected CR submit | T-62-07, T-62-08 | No `approve_change_request` in orchestrator; production submits CR without mutation |
| AUD-03 automation audit | — | Healthy advance emits `rollout.advance` with `source: guardrail_automation` |
| Fake/Ecto execute parity | T-62-09 | All 8 contract scenarios loop `@adapters`; outcomes match |

---

## Test Evidence

```bash
cd rulestead && mix compile --warnings-as-errors          # exit 0
cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs \
  test/rulestead/rollout_auto_advance_contract_test.exs \
  test/rulestead/guarded_rollout_test.exs \
  test/rulestead/scheduled_execution_conflict_test.exs \
  test/rulestead/guardrails/auto_advance_test.exs       # 29 tests, 0 failures
```

---

_Reviewed: 2026-05-27T20:15:00Z_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_
