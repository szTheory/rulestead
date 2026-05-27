# Phase 61 — Research: Auto-Advance Authored Contract

**Researched:** 2026-05-27  
**Source:** CONTEXT.md (assumptions mode), v1.5 guardrail code, Phase 57 blast-radius pattern, post-v1.7 assessment thread  
**Skip rationale:** STATE.md defers parallel research; synthesis from existing shipped patterns is sufficient.

---

## Decision Summary

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Persistence | Dedicated `rollout_auto_advance_policies` table | Keeps automation config out of ruleset embeds and rollback targets (D-01) |
| Evaluator | `Rulestead.Guardrails.AutoAdvance` pure module | Mirrors `BlastRadiusThreshold` / `Decision.evaluate` composition (D-02, Phase 57) |
| Phase boundary | Contract + eligibility only; no `ScheduledExecution` | Phase 62 owns ORC-01 (D-03) |
| v1.5 paths | No edits to `execute_guardrail_decision` hold/rollback | ROL-07 non-regression (D-04) |
| Store API | upsert / fetch / evaluate on Fake + Ecto | `guarded_rollout_test.exs` adapter parity (D-05) |
| Window semantics | Reuse `monitoring_window_*` on advance/evaluate commands | `Decision.monitoring_window_closed?/2` authoritative (D-06) |
| Eligibility shape | `%AutoAdvance.Eligibility{}`; no new `action_type` | Phase 62 audit rows (D-07) |
| Facade | Thin `Rulestead` wrappers like `advance_rollout` | Host + Phase 62 worker (D-08) |

---

## Codebase Anchors

### Pure evaluation (compose, do not duplicate)

- `Rulestead.Guardrails.Decision.evaluate/2` — fail-closed states: `:healthy`, `:pending_data`, `:held`, `:rollback_triggered`
- `monitoring_window_closed?/2` — compares `evaluated_at` vs `monitoring_window_ends_at`
- Empty facts + closed window → `:held` with `"monitoring_window_expired"`

### Store / command patterns

- `Command.AdvanceRollout` — `stage`, `percentage`, `monitoring_window_started_at`, `monitoring_window_ends_at`, `signal_facts`
- `Command.EvaluateGuardedRollout` — evaluation without stage mutation
- `Rulestead.GuardedRolloutTest` — `@adapters [Rulestead.Fake, StoreEcto]`, `ensure_phase50_schema!/0` in setup
- Migration style: `20260526110000_add_guardrail_decisions.exs` — uuid PK, text keys, jsonb metadata, check constraints

### Prior pure-policy milestone

- `Rulestead.Governance.BlastRadiusThreshold` — `assess/2`, no I/O, ExUnit matrix for verdict paths
- Phase 57 plans: wave 1 pure module, wave 2 Fake/Ecto integration, wave 3 contract tests

---

## Eligibility Logic (fail-closed matrix)

**Eligible** (`status: :eligible`) only when ALL:

1. Policy `enabled: true` with complete `observation_window_seconds`, `next_stage`, `next_percentage` (0..100)
2. `Decision.evaluate(signal_facts, opts)` returns `state: :healthy`
3. `monitoring_window_closed?` is true (`evaluated_at >= monitoring_window_ends_at`)
4. `signal_facts` non-empty after window close

**Blocked** (`status: :blocked`) with explicit `reasons` strings for:

| Condition | Example reason |
|-----------|----------------|
| Policy disabled | `"auto_advance_disabled"` |
| Incomplete policy fields when enabled | `"auto_advance_policy_incomplete"` |
| `:pending_data` | `"guardrail_pending_data"` |
| `:held` | `"guardrail_held:{reason}"` |
| `:rollback_triggered` | `"guardrail_rollback_triggered"` |
| Empty facts after close | `"monitoring_window_expired"` |
| Missing `monitoring_window_ends_at` | `"monitoring_window_unset"` |
| Recoverable reasons while closed | `"guardrail_held:stale"` etc. |

Store `evaluate_rollout_auto_advance/1` accepts explicit `signal_facts`, `monitoring_window_ends_at`, `evaluated_at` (default truncated UTC now). Optionally loads policy only — does **not** call `advance_rollout` or enqueue ticks.

---

## Schema Sketch

```elixir
# rollout_auto_advance_policies
# unique index: [:flag_key, :environment_key, :rule_key]
# fields: enabled, observation_window_seconds, next_stage, next_percentage, metadata, timestamps
```

Commands:

- `Command.UpsertRolloutAutoAdvancePolicy` — upsert by composite key
- `Command.FetchRolloutAutoAdvancePolicy` — fetch or `{:error, not_found}`
- `Command.EvaluateRolloutAutoAdvance` — flag/env/rule + signal_facts + window timestamps

---

## Out of Scope (Phase 62+)

- `ScheduledExecution` / Oban tick on window close
- Governed `advance_rollout` on eligibility
- `guardrail_automation` audit `action_type`
- Admin toggle UI (`rulestead_admin`)
- `mix verify.phase64`

---

## Validation Architecture

| Layer | Command | When |
|-------|---------|------|
| Unit | `mix test test/rulestead/guardrails/auto_advance_test.exs` | After 61-02 tasks |
| Compile | `mix compile --warnings-as-errors` | Every plan |
| Contract | `mix test test/rulestead/rollout_auto_advance_contract_test.exs` | After 61-04 |
| Regression | `mix test test/rulestead/guarded_rollout_test.exs` | 61-03 ROL-07 guard |

Nyquist: quick run = auto_advance unit tests; full = contract + guarded_rollout subset.

---

## RESEARCH COMPLETE
