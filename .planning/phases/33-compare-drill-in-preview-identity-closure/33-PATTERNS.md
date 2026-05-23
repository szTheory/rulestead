# Phase 33: Compare Drill-in Preview Identity Closure - Patterns

## Canonical Patterns

### Pattern 1: `handle_params/3` is the compare-state seam
- Both compare LiveViews rebuild state from route params and then call `load_compare/1`.
- Preserve preview identity by keeping `compare_token` in the same route-backed param set as `env`, `tenant`, `source_env`, and `target_env`.

### Pattern 2: Mounted scope links flow through `Session`
- `Session.current_path/3`, `Session.env_links/3`, and `Session.tenant_links/3` are the canonical helpers for visible scope-preserving URLs.
- Summary-to-detail links should follow the same explicit, deep-linkable posture rather than inventing hidden navigation state.

### Pattern 3: Compare requests use explicit opt forwarding
- Summary compare uses explicit opts built from current mounted scope.
- Drill-in compare narrows that scope with `flag_keys: [flag_key]` and forwards `tenant_key` plus `compare_token`.
- Keep this contract unchanged; Phase 33 only needs the token to survive navigation into the existing drill-in flow.

### Pattern 4: Stale-preview semantics come from compare findings
- The compare engine recomputes expected preview identity and reports `:staleness_conflict` when a provided `compare_token` is stale.
- The drill-in page should keep rendering stale state from compare findings, not a UI-local stale flag.

## File Anchors

- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`
  - `handle_params/3` consumes summary-route `compare_token`.
  - `build_page/4` establishes the current param-building style.
  - `flag_path/2` is the Phase 33 gap point.
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex`
  - `handle_params/3` and `load_compare/1` already consume and forward `compare_token`.
  - `trace_rows/2` is the preview-identity disclosure surface on drill-in pages.
- `rulestead_admin/lib/rulestead_admin/live/session.ex`
  - Canonical mounted-scope URL helpers.
- `rulestead/lib/rulestead/promotion/compare.ex`
  - Canonical compare-token generation and stale-preview detection.

## Reusable Helpers

- `Session.current_path/3`
- `Session.env_links/3`
- `Session.tenant_links/3`
- `blank_to_nil/1`
- `maybe_put_param/3`
- `maybe_put_opt/3`
- `current_tenant_key/1`
- `admin_base_path/2`

## Anti-Patterns

- Hand-building drill-in URLs without `compare_token`.
- Creating a second preview identity source outside `compare_token`.
- Reinterpreting stale-preview state in the UI instead of using compare findings.
- Broadening this phase into tenant-resolution, public promotion, or milestone-auditability work.

## Test Anchors

- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs`
  - Natural home for summary-link preservation assertions, including `compare_token`.
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs`
  - Natural home for reviewed-preview and stale-preview drill-in assertions once the token reaches the route.

## Practical Direction

- Preserve `compare_token` on summary drill-in links.
- Keep drill-in compare loading and stale-preview rendering semantics unchanged.
- Verify the mounted summary-to-detail path directly with targeted LiveView tests.
