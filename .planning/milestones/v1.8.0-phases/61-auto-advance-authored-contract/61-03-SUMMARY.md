---
phase: 61-auto-advance-authored-contract
plan: 61-03
status: complete
completed: 2026-05-27
requirements: [ROL-04, ROL-07]
---

# Plan 61-03 Summary: Store Integration And Facade

## Objective

Wire `upsert_rollout_auto_advance_policy`, `fetch_rollout_auto_advance_policy`, and `evaluate_rollout_auto_advance` into Fake + Ecto stores and add thin `Rulestead` facade wrappers per CONTEXT D-03, D-04, D-05, D-08.

## Tasks Completed

1. **Fake store callbacks** — Added GenServer handlers and in-memory `auto_advance_policies` map with upsert validation, fetch not-found errors, and evaluation via `AutoAdvance.evaluate_eligibility/2` without stage mutation.
2. **Ecto store callbacks** — Added `RolloutAutoAdvancePolicy` upsert/fetch/evaluate with composite-key `on_conflict` insert and shared eligibility evaluator; Store behaviour callbacks and Redis read-only stubs included.
3. **Rulestead facade wrappers** — Added public upsert/fetch/evaluate functions with 3-arity helpers, `admin_write` for policy mutation (mapped to `:advance_rollout` auth), and `run_store` for fetch/evaluate.

## Key Files

| Path | Role |
|------|------|
| `rulestead/lib/rulestead/fake.ex` | In-memory policy CRUD + eligibility |
| `rulestead/lib/rulestead/store/ecto.ex` | Postgres policy CRUD + eligibility |
| `rulestead/lib/rulestead/store.ex` | Store behaviour callbacks |
| `rulestead/lib/rulestead/store/redis.ex` | Read-only stubs |
| `rulestead/lib/rulestead.ex` | Public facade wrappers |

## Deviations

- Used `StoreError.invalid_command("rollout_auto_advance_policy_not_found", ...)` instead of non-existent `StoreError.not_found/1` to preserve stable not-found message.
- `@impl Store` on Fake/Ecto and Store behaviour callbacks landed in task 2 commit alongside Ecto implementation so `--warnings-as-errors` passes per commit.

## Verification

```bash
cd rulestead && mix compile --warnings-as-errors
git diff rulestead/lib/rulestead/store/ecto.ex  # no execute_guardrail_decision changes
git diff 20e5da9^..HEAD -- rulestead/lib/rulestead/fake.ex  # no hold/rollback handler changes
```

## Self-Check: PASSED

- Fake and Ecto expose `upsert_rollout_auto_advance_policy`, `fetch_rollout_auto_advance_policy`, `evaluate_rollout_auto_advance`
- `evaluate_rollout_auto_advance` returns `{:ok, %{eligibility: struct}}` via `AutoAdvance.evaluate_eligibility/2` only
- No `advance_rollout`, `ScheduledExecution`, or ruleset mutation on evaluate path
- `execute_guardrail_decision` and fake hold/rollback handlers unchanged (ROL-07)
- Facade 3-arity helpers exist for upsert, fetch, and evaluate
- `mix compile --warnings-as-errors` exits 0
