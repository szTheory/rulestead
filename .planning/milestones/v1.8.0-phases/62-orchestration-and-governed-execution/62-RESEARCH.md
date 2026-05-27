# Phase 62 — Research: Orchestration And Governed Execution

**Researched:** 2026-05-27  
**Source:** `62-CONTEXT.md` (user decisions), Phase 61 shipped code, `ScheduledExecution` / Oban patterns, contract tests  
**Requirements:** ROL-06, ORC-01, ORC-02, AUD-03

---

## 1. Executive Summary

Phase 62 closes the loop Phase 61 intentionally left open: after each manual or automated stage advance, when an enabled auto-advance policy exists, register **one** `ScheduledExecution` tick at `monitoring_window_ends_at`. At tick time, resolve **fresh** guardrail signals, run the pure `AutoAdvance.evaluate_eligibility/2` contract, and either (a) governed `advance_rollout` with `metadata.source: :guardrail_automation`, (b) auto-submit a change request in protected environments, or (c) finalize the tick as **completed without ruleset mutation** when blocked.

**Planner-critical constraints:**

| Constraint | Why it matters |
|------------|----------------|
| Single composite tick under `:advance_rollout` | No second worker, no evaluate-only governed action (D-01) |
| Schedule hook inside `advance_rollout` | Host burden stays zero; matches change-request schedule co-location (D-02) |
| Fake + Ecto parity on every store path | Merge-gate discipline; `@adapters` contract tests |
| Bounded `failure_reason` strings | `scheduled_execution_conflict_test.exs` posture — no silent skips on races |
| No auto-approve in protected env | ROL-06; reuse `submit_change_request` → human approval → existing execute path |
| Worker unchanged | `ScheduledExecutionWorker` already delegates to `execute_scheduled_execution/1` |

Phase 62 delivers four plans (62-01…62-04) mirroring Phases 57/61: schedule hook + idempotency, execute orchestration module, store integration + protected routing, adapter contract tests.

---

## 2. Current State Analysis

### 2.1 Phase 61 deliverables (ready to compose)

| Asset | Location | Phase 62 use |
|-------|----------|--------------|
| Policy table + upsert/fetch | `rollout_auto_advance_policies`, `upsert_rollout_auto_advance_policy/1`, `fetch_rollout_auto_advance_policy/1` | Load policy at schedule (enabled check) and execute (fresh enabled + complete check) |
| Pure evaluator | `Rulestead.Guardrails.AutoAdvance.evaluate_eligibility/2` | Tick execute eligibility gate |
| Store evaluate command | `evaluate_rollout_auto_advance/1` | Callable from orchestration; accepts explicit `signal_facts`, window timestamps |
| Contract tests | `rollout_auto_advance_contract_test.exs` | Regression guard; proves evaluate never mutates stage |
| Facade wrappers | `Rulestead.evaluate_rollout_auto_advance/3` etc. | Host + test entrypoints |

Phase 61 explicitly deferred: `ScheduledExecution` ticks, governed auto-`advance_rollout`, `guardrail_automation` audit rows, protected-env CR routing (61-CONTEXT D-03, D-07).

### 2.2 ScheduledExecution envelope (reuse as-is)

**Vocabulary** — `Rulestead.Governance.ScheduledExecution` already lists `:advance_rollout` as a governed action with `:policy_bypass` execution mode support.

**Worker** — `Rulestead.Oban.ScheduledExecutionWorker.perform/1` is thin: builds `Command.ExecuteScheduledExecution`, uses actor `system:scheduler`, calls configured store. **No worker changes expected.**

**Execute lifecycle** (Ecto + Fake parity):

```
execute_scheduled_execution/1
  ├─ state "completed" → {:ok, ...} replay-safe (ORC-02)
  ├─ state "cancelled" / "quarantined" → {:error, bounded message}
  └─ else → run_scheduled_execution/3
       ├─ insert execution_attempt (running)
       ├─ perform_scheduled_execution/2
       │    ├─ change_request_id present → execute_governed_change/2
       │    └─ direct → execute_direct_scheduled_action/3
       └─ finalize_scheduled_execution_success/4 | failure/4
```

**Direct advance path today** — both adapters call `advance_rollout/1` with snapshot fields only:

```4787:4807:rulestead/lib/rulestead/store/ecto.ex
  defp execute_direct_scheduled_action("advance_rollout", scheduled_execution, command) do
    advance_rollout(
      Command.AdvanceRollout.new(
        scheduled_execution.resource_key,
        scheduled_execution.environment_key,
        Map.merge(
          scheduled_execution.command_snapshot["rollout"] || scheduled_execution.command_snapshot,
          %{"signal_facts" => scheduled_execution.command_snapshot["signal_facts"]}
        ),
        ...
      )
    )
  end
```

There is **no** auto-advance orchestration branch, **no** fresh signal fetch, **no** eligibility gate, **no** protected-env CR routing on this path.

### 2.3 Schedule registration gap

`advance_rollout/1` (Ecto lines 834–910, Fake `handle_advance_rollout_in_state/2`) publishes ruleset, inserts `GuardrailDecision` (`action_type: :advance`, `decision_state: :pending_data`), emits `rollout.advance` audit — then **returns without scheduling**.

`schedule_governed_action/1` exists and enqueues Oban via `insert_scheduled_execution/2` + `enqueue_scheduled_execution_job/4`, but is **never called from advance_rollout**.

Current idempotency key is **`"scheduled_execution:#{correlation_id}"`** where `correlation_id` comes from `command.metadata["request_id"]` — **not** deterministic per rollout stage/window. Auto-advance needs the D-02 key shape:

```
scheduled_execution:auto_advance:{flag_key}:{environment_key}:{rule_key}:{stage}:{iso8601(window_ends)}
```

`insert_scheduled_execution/2` uses `insert_all` with **no ON CONFLICT**; duplicate keys fail the transaction → planner must pre-check, fetch-existing-on-conflict, or cancel superseded pending ticks before insert.

### 2.4 Protected-environment posture

`Rulestead.Admin.Authorizer.approval_requirement/4` defaults `change_request_required?` to **true** when `environment_key in ["prod", "production"]` and action is a governed action (includes `:advance_rollout`).

Direct `execute_direct_scheduled_action("advance_rollout", ...)` with `:policy_bypass` **bypasses** `authorize_governed_action/4` today — acceptable for operator-scheduled bypass ticks, **unacceptable** for automation in protected env (D-04). Tick execute must branch on `change_request_required?` before mutating.

Existing CR execute path for advance is proven:

```4627:4648:rulestead/lib/rulestead/store/ecto.ex
  defp execute_bounded_governed_action("advance_rollout", change_request, command) do
    advance_rollout(Command.AdvanceRollout.new(...))
  end
```

### 2.5 Conflict and idempotency primitives (ORC-02)

| Primitive | Behavior | Test anchor |
|-----------|----------|-------------|
| Completed replay | `execute_scheduled_execution` returns `{:ok, ...}` without re-running mutation | `scheduled_execution_adapter_contract_test.exs` |
| Stale rollout target | `rollout_stage_conflict` bounded failure | `scheduled_execution_conflict_test.exs` (missing stage in snapshot) |
| Transient failure → retry | attempt_count++, state stays `:scheduled` until limit → `:quarantined` | adapter contract test |
| Eligibility blocked | Phase 61 returns `status: :blocked` with explicit `reasons` — no advance | `rollout_auto_advance_contract_test.exs` |

**Gap:** No existing pattern for “completed tick, zero ruleset mutation, blocked eligibility.” Planner must use `finalize_scheduled_execution_success/4` with a non-mutating `execution_result` (e.g. `%{outcome: :blocked, eligibility: ...}`) rather than `finalize_scheduled_execution_failure/4` — blocked guardrails are **expected**, not operator errors.

**Gap:** No `auto_advance_superseded` reason exists yet; D-03 allows dedicated reason or reuse `rollout_stage_conflict` when snapshot stage/window no longer matches live rollout.

### 2.6 Audit and telemetry (AUD-03)

Successful manual advance already emits `rollout.advance` with `links.guardrail_decision_id`. Automation must add:

- `metadata.source: :guardrail_automation` (already used in Phase 61 evaluate tests)
- `scheduled_execution_id` correlation on advance command metadata
- Signal facts, observation window bounds, stage transition, eligibility snapshot in audit metadata
- Scheduled-execution lifecycle audit (`scheduled_execution.succeeded`) via existing finalize path

Blocked ticks: default to scheduled-execution lifecycle audit only (D-05); no established non-mutating guardrail audit stub in store today.

Telemetry: reuse `[:rulestead, :admin, :scheduled_execution, *]` events; worker sets `emit_lifecycle_telemetry: false` on execute command — store emits on finalize when enabled.

---

## 3. Implementation Approach

### 3.1 Schedule hook (ORC-01) — 62-01

**Where:** After successful `advance_rollout` transaction in **both** `Store.Ecto` and `Fake` (mirror exactly).

**When:**

1. `fetch_rollout_auto_advance_policy/1` for `(flag_key, environment_key, rule_key)` succeeds
2. Policy `enabled: true` and complete (`observation_window_seconds`, `next_stage`, `next_percentage`)
3. Command has `monitoring_window_ends_at` (always set on guarded rollout advances)

**Action:** `schedule_governed_action/1` with:

| Field | Value |
|-------|-------|
| `action` | `:advance_rollout` |
| `scheduled_for` | `command.monitoring_window_ends_at` |
| `execution_mode` | `:policy_bypass` (protected routing resolved at execute) |
| `resource_type` / `resource_key` | `"flag"` / flag_key |
| `environment_key` | command.environment_key |
| `actor` | `%{"id" => "system:scheduler", "type" => "system", "display" => "Scheduler"}` |
| `metadata.source` | `:guardrail_automation` |
| `metadata.automation_phase` | `"evaluate_and_advance"` (or equivalent — discretion D-01) |
| `command_snapshot` | See below |
| `idempotency_key` | Deterministic D-02 key (**requires extending schedule path**) |

**command_snapshot contents** (stale-target checks at execute):

```elixir
%{
  "rollout" => %{
    "rule_key" => rule_key,
    "stage" => command.stage,           # current stage when tick registered
    "percentage" => command.percentage, # current effective %
    "monitoring_window_started_at" => ...,
    "monitoring_window_ends_at" => ...
  },
  "auto_advance" => %{
    "policy_next_stage" => policy.next_stage,
    "policy_next_percentage" => policy.next_percentage,
    "observation_window_seconds" => policy.observation_window_seconds
  },
  "signal_facts" => []  # intentionally empty — fresh fetch at execute (D-05)
}
```

**Supersession:** When a new advance schedules a tick for the same `(flag, env, rule)` before prior window closes, cancel pending prior auto-advance ticks (filter `list_scheduled_executions` by metadata or idempotency prefix) **or** let stale execute fail with bounded reason — planner picks minimal diff; CONTEXT prefers cancel/supersede matching conflict patterns.

**Idempotency extension:** Add optional `idempotency_key` to `Command.ScheduleGovernedAction` (or dedicated internal helper) so auto-advance does not reuse `"scheduled_execution:#{correlation_id}"`. On duplicate insert, fetch existing row by key and return `{:ok, existing}` (discretion D-02).

**Schedule failure:** Must not roll back successful advance — schedule hook runs **after** commit; log/telemetry on schedule failure, bounded error to caller optional (prefer `:ok` advance + async schedule error in metadata over failing advance).

### 3.2 Execute orchestration (ORC-01, AUD-03) — 62-02

**Recommended module:** `Rulestead.Governance.RolloutAutoAdvance` (or `Rulestead.Guardrails.AutoAdvance.Orchestrator`) — store-adjacent, no I/O in pure evaluator.

**Entry:** Branch inside `execute_direct_scheduled_action("advance_rollout", ...)` when tick metadata indicates automation:

```elixir
automation_tick?(scheduled_execution.metadata) ->
  RolloutAutoAdvance.execute_scheduled_tick(store, scheduled_execution, command)
```

**Pipeline:**

```
1. validate_snapshot_freshness/2
   - Compare snapshot stage/percentage/window_ends vs latest GuardrailDecision + active ruleset
   - Policy still enabled + complete
   - On mismatch → {:error, "rollout_stage_conflict"} or "auto_advance_superseded"

2. resolve_signal_facts/2
   - Load rollout rule guardrails from active ruleset (StoreFixtures pattern: signal_key checkout_error_rate)
   - For each guardrail config: Guardrails.fetch_signal/2 (Application env :guardrails_provider)
   - Build signal_facts list for evaluate

3. evaluate_rollout_auto_advance/1
   - monitoring_window_ends_at from snapshot
   - evaluated_at = now() truncated
   - On :blocked → {:ok, %{outcome: :blocked, eligibility: ...}}  # no advance

4. resolve_approval_requirement/4
   - Authorizer.approval_requirement(system_scheduler_actor, :advance_rollout, resource, env)

5a. change_request_required? == false
   - build AdvanceRollout command from policy next_stage/next_percentage
   - compute next monitoring_window_* from policy.observation_window_seconds
   - metadata: source guardrail_automation, scheduled_execution_id, eligibility snapshot
   - advance_rollout/1 (triggers next schedule hook if policy still enabled)

5b. change_request_required? == true  (ROL-06)
   - submit_change_request/1 with governed_action :advance_rollout
   - command_snapshot mirrors manual advance + guardrail evidence + window context
   - actor system:scheduler — NO approve, NO execute
   - Return {:ok, %{outcome: :change_request_submitted, change_request: ...}}

6. AUD-03 on successful advance
   - advance_rollout already inserts GuardrailDecision + rollout.advance audit
   - Ensure advance command metadata carries automation evidence (planner verifies audit_event.metadata)
```

**Next window calculation (D-06):** On eligible advance at `evaluated_at`:

```elixir
started_at = evaluated_at
ends_at = DateTime.add(started_at, policy.observation_window_seconds, :second)
```

Pass as `monitoring_window_started_at` / `monitoring_window_ends_at` on the **next** stage's `AdvanceRollout` command — same semantics as manual flow.

### 3.3 Protected-environment routing (ROL-06) — 62-03

| Environment | Tick execute outcome |
|-------------|---------------------|
| `test`, staging, etc. | Direct `advance_rollout` via orchestration (`:policy_bypass`) |
| `prod` / `production` (default Authorizer) | `submit_change_request` only; CR stays `:submitted` until human `approve_change_request` → `execute_change_request` / `schedule_change_request` |

**CR command snapshot shape** — align with `execute_bounded_governed_action("advance_rollout", ...)` expectation:

```elixir
%{
  "rollout" => %{
    "rule_key" => ...,
    "stage" => policy.next_stage,
    "percentage" => policy.next_percentage,
    "monitoring_window_started_at" => ...,
    "monitoring_window_ends_at" => ...
  },
  "signal_facts" => resolved_facts
}
```

Include `approval_requirement` snapshot from `Authorizer.approval_requirement/4`. Metadata: `source: :guardrail_automation`, eligibility reasons empty, window bounds, `scheduled_execution_id`.

**Test environment strategy:** Contract tests can use `environment_key: "production"` with default Authorizer (no custom policy module) to assert CR path without standing up full admin stack.

### 3.4 Idempotency and race safety (ORC-02) — cross-cutting

| Race | Expected behavior |
|------|-------------------|
| Duplicate Oban delivery | First execute completes tick; second hits `"completed"` short-circuit — no double advance |
| Manual advance before tick | Snapshot stale → `rollout_stage_conflict` or `auto_advance_superseded` failure OR superseded cancel |
| Rollback / hold before tick | Fresh signals or eligibility → `:blocked`; tick completes without mutation |
| Policy disabled before tick | Re-check at execute → blocked completion |
| Duplicate schedule same window | Deterministic idempotency_key → single row |
| Operator cancel tick | `execute_scheduled_execution` → `"scheduled execution is cancelled"` |

**Explicit bounded reasons** (extend only if needed):

- `rollout_stage_conflict` — reuse (existing tests)
- `auto_advance_superseded` — optional dedicated reason for window/stage supersession
- `auto_advance_disabled` / eligibility reasons — on blocked **completion**, store in `execution_metadata` not `failure_reason`

**Do not** double-advance: orchestration must not call `advance_rollout` when eligibility is `:blocked`; stale snapshot must fail **before** advance attempt.

---

## 4. File-by-file Change Map

| File | Plan | Change |
|------|------|--------|
| `rulestead/lib/rulestead/store/command.ex` | 62-01 | Optional `idempotency_key` on `ScheduleGovernedAction` |
| `rulestead/lib/rulestead/store/ecto.ex` | 62-01, 62-03 | `maybe_schedule_auto_advance_tick/2` after advance commit; custom idempotency in `schedule_governed_action`; supersede/cancel helper; `insert_scheduled_execution` idempotent fetch |
| `rulestead/lib/rulestead/fake.ex` | 62-01, 62-03 | Parity: schedule hook in `handle_advance_rollout_in_state`; matching idempotency + cancel |
| `rulestead/lib/rulestead/governance/rollout_auto_advance.ex` | 62-02 | **New** — execute orchestration: snapshot validate, signal resolve, evaluate, advance/CR branch |
| `rulestead/lib/rulestead/store/ecto.ex` | 62-02, 62-03 | Branch `execute_direct_scheduled_action("advance_rollout", ...)` to orchestrator when automation metadata |
| `rulestead/lib/rulestead/fake.ex` | 62-02, 62-03 | Same branch in `execute_direct_scheduled_action/4` |
| `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` | — | **No change** (D-01) |
| `rulestead/lib/rulestead/governance/scheduled_execution.ex` | — | **No change** — vocabulary already sufficient |
| `rulestead/lib/rulestead/guardrails/auto_advance.ex` | — | **No change** — pure evaluator frozen |
| `rulestead/lib/rulestead/admin/authorizer.ex` | — | **No change** — call `approval_requirement/4` only |
| `rulestead/lib/rulestead.ex` | optional | Facade for tick listing/debug only if plans require; not mandatory for phase boundary |
| `rulestead/test/support/store_fixtures.ex` | 62-04 | Shared helpers: seed rollout + policy + stub provider |
| `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` | 62-04 | **New** — primary ORC/ROL/AUD contract file |
| `rulestead/test/rulestead/rollout_auto_advance_contract_test.exs` | 62-04 | Regression — must still pass unchanged |
| `rulestead/test/rulestead/guarded_rollout_test.exs` | 62-04 | Regression — ROL-07 unchanged |
| `rulestead/test/rulestead/scheduled_execution_conflict_test.exs` | 62-04 | Extend or sibling test for auto-advance stale snapshot |

---

## 5. Test Strategy (aligned with 62-04 contract tests)

**File:** `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs`  
**Pattern:** Copy `rollout_auto_advance_contract_test.exs` — `@adapters [Rulestead.Fake, StoreEcto]`, `async: false`, schema setup helpers.

**Stub provider:** Module implementing `fetch_signal/1` returning healthy/blocked facts (mirror `guardrails/contract_test.exs` StubProvider). Set `Application.put_env(:rulestead, :guardrails_provider, Stub)` in setup with `on_exit` restore.

### Required test cases (each iterates `@adapters`)

| # | Test name (intent) | Requirements | Assertions |
|---|-------------------|--------------|------------|
| 1 | `advance_rollout schedules auto_advance tick at monitoring_window_ends_at` | ORC-01 | After advance + enabled policy, `list_scheduled_executions` has one `:advance_rollout` tick; `scheduled_for == window_ends`; metadata source guardrail_automation; Oban job present (Ecto only or both) |
| 2 | `disabled policy does not schedule tick` | ORC-01 | No scheduled execution after advance |
| 3 | `healthy tick executes governed advance with guardrail_automation audit` | ORC-01, AUD-03 | Execute tick at/after window; ruleset percentage → policy next_percentage; audit `rollout.advance` metadata source; GuardrailDecision row; scheduled_execution `:completed` |
| 4 | `blocked tick completes without stage mutation` | ORC-01, ORC-02 | Provider returns breached/stale signal; execute tick → `:completed`; percentage unchanged; execution_metadata captures blocked reasons |
| 5 | `protected environment submits change request does not auto-advance` | ROL-06 | `environment_key: "production"`; execute tick → CR `:submitted`; no ruleset change until approve + execute CR |
| 6 | `duplicate execute is replay safe` | ORC-02 | Execute same tick twice; second `{:ok, completed}`; single advance audit count |
| 7 | `manual advance before tick fails closed with bounded reason` | ORC-02 | Schedule tick; manual advance to different stage; execute → error + `failure_reason` in `rollout_stage_conflict` / superseded family |
| 8 | `deterministic idempotency_key prevents duplicate ticks` | ORC-02 | Two schedule attempts same stage/window → one row |

**Regression suite (62-04 verify task):**

```bash
cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
cd rulestead && mix test test/rulestead/rollout_auto_advance_contract_test.exs
cd rulestead && mix test test/rulestead/guarded_rollout_test.exs
cd rulestead && mix test test/rulestead/scheduled_execution_conflict_test.exs
cd rulestead && mix test test/rulestead/guardrails/auto_advance_test.exs
```

**Fake time control:** Fake adapter uses `state.now` — tests should set/advance Fake clock for window close without flaking DateTime comparisons.

---

## 6. Risks and Pitfalls

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Schedule hook fails after advance commit** | Medium | Post-commit hook; surface telemetry; do not fail advance response |
| **Infinite tick chain** | Low | Each advance schedules **one** next tick; disabling policy stops chain |
| **Idempotency_key not pluggable** | High | Extend `ScheduleGovernedAction` + insert path before 62-01 lands |
| **insert_all without ON CONFLICT** | High | Pre-check by idempotency_key or rescue unique violation → fetch existing |
| **Blocked tick classified as failure** | High | Use success finalize with `outcome: :blocked`; avoid quarantine retry loop |
| **Protected env bypass via policy_bypass** | Critical | Orchestrator **must** check `approval_requirement` before direct advance |
| **Stale snapshot undetected** | High | Explicit validate snapshot vs live decision/ruleset before evaluate/advance |
| **Signal fetch in tests without provider** | Medium | Stub provider in contract setup; assert `:provider_missing` blocks in dedicated case |
| **PII in audit/telemetry** | Medium | Reuse `ScheduledExecution` sensitive key dropping; no raw traits in signal metadata |
| **Fake/Ecto drift on cancel supersede** | Medium | Shared helper module or identical logic comments; contract tests on both adapters |
| **advance_rollout schedule on CR-executed advance** | Low | Acceptable — CR execute calls `advance_rollout` which schedules next window if policy enabled |
| **Oban job duplicate on idempotent schedule return** | Medium | enqueue helper already skips if job exists for scheduled_execution_id |

---

## 7. Validation Architecture (Nyquist)

### Test dimensions

| Layer | Command | Validates | When |
|-------|---------|-----------|------|
| Unit | `mix test test/rulestead/guardrails/auto_advance_test.exs` | Pure eligibility unchanged | After any evaluator-touch (should be none) |
| Unit | New `rollout_auto_advance_orchestrator_test.exs` (optional) | Snapshot validate + signal resolve pure helpers | After 62-02 if helpers extracted |
| Integration | `rollout_auto_advance_orchestration_contract_test.exs` | Full schedule→execute paths, both adapters | After 62-04 |
| Regression | `rollout_auto_advance_contract_test.exs` | Phase 61 boundary intact | Every plan |
| Regression | `guarded_rollout_test.exs` | ROL-07 hold/rollback | 62-03, 62-04 |
| Regression | `scheduled_execution_adapter_contract_test.exs` | Replay/quarantine semantics preserved | 62-03 |
| Compile | `mix compile --warnings-as-errors` | No warnings | Every plan |

### Observability hooks

| Event | When | Metadata must include |
|-------|------|----------------------|
| `scheduled_execution.scheduled` | Tick registered on advance | `governed_action: advance_rollout`, `source: guardrail_automation`, deterministic idempotency_key |
| `scheduled_execution.started` / `succeeded` | Tick execute | `scheduled_execution_id`, attempt_count, environment |
| `rollout.advance` audit | Successful auto-advance | `source: guardrail_automation`, signal_facts summary, window bounds, stage diff, `scheduled_execution_id` link |
| `change_request.submitted` audit | Protected env tick | `source: guardrail_automation`, eligibility snapshot, pending advance payload |

### Contract test matrix

| Scenario | Fake | Ecto | ORC-01 | ORC-02 | ROL-06 | AUD-03 |
|----------|------|------|--------|--------|--------|--------|
| Schedule on advance | ✓ | ✓ | ✓ | partial | — | — |
| Healthy execute advance | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| Blocked execute no-op | ✓ | ✓ | ✓ | ✓ | — | partial |
| Protected CR submit | ✓ | ✓ | ✓ | — | ✓ | partial |
| Replay duplicate execute | ✓ | ✓ | — | ✓ | — | — |
| Manual advance race | ✓ | ✓ | — | ✓ | — | — |
| Idempotent schedule | ✓ | ✓ | — | ✓ | — | — |
| Policy disabled at execute | ✓ | ✓ | ✓ | ✓ | — | — |

**Nyquist quick run:** orchestration contract file only.  
**Nyquist full:** all rows + guarded_rollout + Phase 61 contract + compile.

---

## 8. Out of Scope confirmation

Per `62-CONTEXT.md` and ROADMAP — **do not plan or implement in Phase 62:**

| Item | Target |
|------|--------|
| Mounted toggle / pending observation UI | Phase 63 (ADM-04, AUD-04) |
| `mix verify.phase64`, release-contract, host seam docs | Phase 64 (VER-01–03) |
| Pre-approved CR at policy-enable time | Deferred |
| Separate `:evaluate_rollout_auto_advance` governed action | Rejected (D-01) |
| Parallel Oban worker / GenServer sweeper | Rejected |
| Changes to v1.5 hold/rollback decision paths | ROL-07 frozen |
| Auto-approve change requests in protected env | Explicitly forbidden (D-04) |
| Observability-backed threshold engine | Out of milestone |
| New `GuardrailDecision.action_type` atoms | Optional; advance action_type `:advance` sufficient with metadata |

---

## RESEARCH COMPLETE
