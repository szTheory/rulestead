---
phase: 61-auto-advance-authored-contract
plan: 61-04
status: complete
completed: 2026-05-27
requirements: [ROL-04, ROL-05, ROL-07]
---

# Plan 61-04 Summary: Adapter Parity Contract Tests

## Objective

Prove deterministic auto-advance policy contract across `Rulestead.Fake` and `Rulestead.Store.Ecto` per ROADMAP success criteria #4, ROL-04, ROL-05, ROL-07.

## Tasks Completed

1. **Contract test module** — Added `rollout_auto_advance_contract_test.exs` with six `@adapters` tests covering policy round-trip, disabled/ineligible/eligible paths, no stage mutation on evaluate, and ROL-07 rollback coexistence. Added `StoreFixtures.guarded_rollout_ruleset_attrs/1` for audience-free publish seeds.
2. **Regression guard** — Verified `guarded_rollout_test.exs` and `auto_advance_test.exs` pass; updated guarded rollout seed to use shared ruleset helper after dependency validation blocked default `valid_ruleset_attrs` publish.

## Key Files

| Path | Role |
|------|------|
| `rulestead/test/rulestead/rollout_auto_advance_contract_test.exs` | Fake + Ecto adapter parity contract |
| `rulestead/test/support/store_fixtures.ex` | `guarded_rollout_ruleset_attrs/1` shared seed |
| `rulestead/test/rulestead/guarded_rollout_test.exs` | ROL-07 regression seed fix |

## Deviations

- Added `guarded_rollout_ruleset_attrs/1` and updated `guarded_rollout_test.exs` seed — required because `valid_ruleset_attrs` references `vip-users` audience missing at publish time; not caused by 61-03 hold/rollback changes.

## Verification

```bash
cd rulestead && mix test test/rulestead/rollout_auto_advance_contract_test.exs
cd rulestead && mix test test/rulestead/guarded_rollout_test.exs
cd rulestead && mix test test/rulestead/guardrails/auto_advance_test.exs
```

## Self-Check: PASSED

- Contract test file defines `@adapters [Rulestead.Fake, StoreEcto]`
- Six tests each iterate both adapters
- Test name contains "evaluate does not advance rollout stage"
- Eligible path requires healthy guardrails after closed window
- Disabled policy blocks with `auto_advance_disabled`
- Pending window blocks with `monitoring_window_active`
- Evaluate when eligible does not change rollout percentage or guardrail stage
- ROL-07 rollback path passes with auto-advance policy enabled
- `mix test test/rulestead/rollout_auto_advance_contract_test.exs` exits 0
- `mix test test/rulestead/guarded_rollout_test.exs` exits 0
- Phase 61 ready for Phase 62 orchestration to call `evaluate_rollout_auto_advance` then governed `advance_rollout`
