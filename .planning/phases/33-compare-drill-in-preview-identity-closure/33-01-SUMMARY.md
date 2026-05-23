# 33-01 Summary

## Status

Completed on 2026-05-22.

## Outcome

Mounted compare summary links now carry the active compare preview identity into flag drill-in routes by preserving the generated `compare_token` alongside the existing environment and tenant scope params.

The mounted LiveView regressions now prove both sides of that contract: summary drill-in URLs keep the reviewed preview token, and drill-in pages still distinguish reviewed-preview and stale-preview states against the shared compare engine semantics without introducing apply controls.

## Verification

- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/show_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`

## Notes

- The summary page now forwards the compare token produced by the compare payload itself, not just any incoming route param, so reviewed previews remain deep-linkable after the initial compare run.
- Verification stayed inside the mounted `rulestead_admin` compare route boundary and did not widen the public promotion or core compare surfaces.
