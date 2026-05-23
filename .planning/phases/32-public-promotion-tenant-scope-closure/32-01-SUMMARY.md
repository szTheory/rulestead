# 32-01 Summary

## Status

Completed on 2026-05-22.

## Outcome

Fixed the public promotion-plan seam so `Rulestead.plan_promotion/3` now forwards explicit `tenant_key` alongside `flag_keys` into the existing compare command and copies the reviewed scope back into the saved plan artifact.

Focused public regression coverage now proves the façade keeps tenant scope bounded: tenant-aware compare previews still use the existing compare/apply contract, saved plans generated from the public API keep the top-level `tenant_key`, and omitted scope stays absent instead of being fabricated.

## Verification

- `cd rulestead && mix test test/rulestead/promotion/compare_test.exs`
- `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs`

## Notes

- The change stayed inside `rulestead`; no `rulestead_admin` scope or Phase 33 compare-drill-in work was pulled forward.
- The saved promote plan continues to use the existing top-level `tenant_key` field rather than a new tenant metadata dialect.
