# 31-01 Summary

## Status

Completed on 2026-05-22.

## Outcome

Added one shared tenant-provenance normalizer on the command seam and taught `Rulestead.AuditEvent.metadata/1` to persist that bounded shape as first-class audit metadata under `metadata["tenant"]` instead of relying on freeform `context`.

Promotion apply replay commands now keep the reviewed `tenant_key`, governed `command_snapshot` payloads are self-describing about tenant provenance before execution, and persisted environment-version metadata carries the same bounded tenant block.

## Verification

- `cd rulestead && mix test test/rulestead/audit_event_governance_test.exs`
- `cd rulestead && mix test test/rulestead/promotion/apply_test.exs`
- `cd rulestead && mix test test/rulestead/store/governance_adapter_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs`

## Notes

- The normalized bounded vocabulary now covers explicit tenant scope, host-resolved unscoped paths, and `SingleTenant` bypass semantics without fabricating tenant identity.
- Governed replay snapshots keep `tenant_key` plus the bounded `tenant` block so later audit builders can reuse one contract.
