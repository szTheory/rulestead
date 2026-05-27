# Phase 62 — Pattern Map

**Mapped:** 2026-05-27  
**Sources:** 62-CONTEXT.md, 62-RESEARCH.md, Phase 57/61 plans

---

## Schedule co-location (advance → tick)

**Analog:** `schedule_change_request/1` in Ecto (lines ~1540–1570) — schedules after CR approval with deterministic idempotency key `"scheduled_execution:change_request:#{id}"`.

**Excerpt pattern:**
```elixir
idempotency_key: "scheduled_execution:change_request:#{change_request.id}"
insert_scheduled_execution(attrs, command)
```

**Phase 62 adaptation:** Hook after `advance_rollout` Multi success; use `"scheduled_execution:auto_advance:#{flag}:#{env}:#{rule}:#{stage}:#{iso8601(window_ends)}"`.

---

## Execute lifecycle branch

**Analog:** `execute_direct_scheduled_action("advance_rollout", ...)` — direct snapshot replay today.

**Excerpt (ecto.ex ~4787):**
```elixir
defp execute_direct_scheduled_action("advance_rollout", scheduled_execution, command) do
  advance_rollout(Command.AdvanceRollout.new(...))
end
```

**Phase 62 adaptation:** Guard on `metadata["source"] == "guardrail_automation"` → delegate to `RolloutAutoAdvance.execute_scheduled_tick/3`.

---

## Completed replay (ORC-02)

**Analog:** `execute_scheduled_execution/1` state `"completed"` short-circuit (~1728).

**Pattern:** Second execute returns `{:ok, ...}` without mutation — contract tests in `scheduled_execution_adapter_contract_test.exs`.

---

## Adapter parity loop

**Analog:** `rollout_auto_advance_contract_test.exs` — `@adapters [Rulestead.Fake, StoreEcto]`, `async: false`.

**Setup:** `ensure_phase50_schema!/0`, seed rollout via `StoreFixtures`, stub `:guardrails_provider`.

---

## Blocked vs failed finalize

**Analog:** Eligibility `:blocked` from Phase 61 — expected outcome, not operator error.

**Phase 62 pattern:** `finalize_scheduled_execution_success/4` with `execution_result: %{outcome: :blocked, eligibility: ...}` — avoid quarantine retry loop.

---

## Protected env CR path

**Analog:** `execute_bounded_governed_action("advance_rollout", change_request, command)` (~4627).

**Phase 62 adaptation:** At tick execute, `Authorizer.approval_requirement/4` → `submit_change_request/1` when `change_request_required?` — never auto-approve.

---

## PATTERN MAPPING COMPLETE
