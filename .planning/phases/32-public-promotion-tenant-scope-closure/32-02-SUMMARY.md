# 32-02 Summary

## Status

Completed on 2026-05-22.

## Outcome

Extended Phase 32 through the replay boundary so tenant-scoped public promote plans now stay authoritative across direct apply normalization, governed protected-target handoff, adapter-contract coverage, and the programmatic `mix rulestead.promote` wrapper.

The replay and release-surface suites now prove the saved plan’s existing top-level `tenant_key` is reused consistently when commands are rebuilt, change requests are queued, and Mix helpers call into the public `Rulestead` façade without widening the public API or introducing new CLI tenant UX.

## Verification

- `cd rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs`
- `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_promote_test.exs test/rulestead/release_contract_test.exs`
- `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs test/rulestead/release_contract_test.exs`

## Notes

- Adapter parity remains covered without widening the persisted tenancy surface beyond the saved plan’s existing `tenant_key`.
- Governed replay continues to use the bounded change-request payload shape, now with tenant scope preserved end to end.
