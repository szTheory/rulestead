---
phase: 61-auto-advance-authored-contract
plan: 61-01
status: complete
completed: 2026-05-27
requirements: [ROL-04]
---

# Plan 61-01 Summary: Policy Persistence And Command Structs

## Objective

Add `rollout_auto_advance_policies` migration, Ecto schema, and store command structs (`UpsertRolloutAutoAdvancePolicy`, `FetchRolloutAutoAdvancePolicy`, `EvaluateRolloutAutoAdvance`) per CONTEXT D-01, D-05, D-06.

## Tasks Completed

1. **Migration and Ecto schema** — Created `rollout_auto_advance_policies` table with composite unique index, DB check constraints, and `RolloutAutoAdvancePolicy` changeset with enabled-policy field requirements.
2. **Store command structs** — Added three command modules after `EvaluateGuardedRollout` with `GovernanceSupport` normalization and `validate_required_fields/1` on upsert when enabled.

## Key Files

| Path | Role |
|------|------|
| `rulestead/priv/repo/migrations/20260527120000_add_rollout_auto_advance_policies.exs` | Durable policy table |
| `rulestead/lib/rulestead/rollout_auto_advance_policy.ex` | Ecto schema + changeset |
| `rulestead/lib/rulestead/store/command.ex` | Upsert/Fetch/Evaluate command structs |

## Deviations

None.

## Verification

```bash
cd rulestead && MIX_ENV=test mix ecto.migrate
cd rulestead && mix compile --warnings-as-errors
cd rulestead && mix run -e 'cs = Rulestead.RolloutAutoAdvancePolicy.changeset(%Rulestead.RolloutAutoAdvancePolicy{}, %{enabled: true}); IO.inspect(not cs.valid?)'
```

## Self-Check: PASSED

- Migration applies cleanly on test DB
- `mix compile --warnings-as-errors` exits 0
- Enabled policy changeset fails validation without required next-stage fields
- Three command structs compile with expected fields
