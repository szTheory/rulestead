# Phase 33: Compare Drill-in Preview Identity Closure - Research

**Researched:** 2026-05-22
**Domain:** Mounted compare summary-to-drill-in navigation in `rulestead_admin`, with preview identity preserved via `compare_token`.
**Confidence:** HIGH

## User Constraints

- Phase scope is limited to Phase 33 in `.planning/ROADMAP.md`; this phase closes only the mounted compare drill-in preview identity gap and must not widen into milestone-backfill work from Phase 34.
- Keep the change aligned with the linked-version, two-package monorepo shape and do not introduce standalone-admin drift or publish preparation for `rulestead_admin`.
- Make the smallest coherent change that preserves reviewed preview identity from compare summary into flag drill-in routes.
- Reuse the existing route-backed mounted compare posture and the existing compare-token stale-preview contract instead of introducing hidden session state or a second preview identifier.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEN-03 | Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata. | Phase 33 closes the remaining mounted compare gap under `TEN-03` by keeping `compare_token` attached to the same tenant-scoped preview identity already produced by the compare engine. |
</phase_requirements>

## Summary

The defect is narrow and already confirmed by the milestone audit. The mounted compare summary page builds flag drill-in URLs with `env`, `tenant`, `source_env`, and `target_env`, but drops `compare_token`. The drill-in page already reads `compare_token` from route params and passes it into `Rulestead.compare_environments/3`, so stale-preview handling and reviewed-preview continuity are only broken at the summary-to-detail handoff.

The existing architecture already does the right work once the token is preserved. Both compare LiveViews are URL-backed through `handle_params/3`, the mounted session helpers generate canonical env and tenant links, and `Rulestead.Promotion.Compare` remains the single source of truth for preview identity and staleness detection. Phase 33 should therefore be an admin-route carry-through fix plus targeted regressions, not a compare-engine redesign.

**Primary recommendation:** keep Phase 33 as one bounded plan that updates compare-summary drill-in URL generation to include the current `compare_token`, then extend the mounted compare tests to prove reviewed and stale preview identity survive summary-to-detail navigation without changing package boundaries or compare semantics.

## Recommended Plan Split

1. **Plan slice 33-01: Preserve compare preview identity across mounted summary-to-detail navigation.** Update compare-summary drill-in URL generation to carry `compare_token`, and extend mounted compare regressions so reviewed-preview and stale-preview drill-ins stay bound to the intended compare result.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Summary-to-detail route param carry-through | Admin / LiveView | — | The broken seam is in `rulestead_admin` URL generation, not in `rulestead` compare calculation. |
| Drill-in preview identity consumption | Admin / LiveView | Core compare engine | `show.ex` already accepts `compare_token`; it only needs the summary route to preserve it. |
| Stale-preview enforcement | Core compare engine | Admin / LiveView | `Rulestead.Promotion.Compare` computes token identity and stale findings; the UI only forwards and renders that result. |

## Project Constraints

- Treat `.planning/` as the roadmap and phase-boundary source of truth.
- Preserve the sibling-package layout.
- Do not introduce Phase 34 artifact cleanup into this phase.
- Prefer narrow, auditable changes with targeted verification.

## Architecture Patterns

### Pattern 1: Route-backed compare scope owns preview identity
Keep `env`, `tenant`, `source_env`, `target_env`, and `compare_token` in URL params so `handle_params/3` can fully reconstruct compare state after mount, live patch, refresh, and deep link.

### Pattern 2: Reuse mounted session helpers for canonical scope links
`Session.current_path/3`, `Session.env_links/3`, and `Session.tenant_links/3` already preserve mounted scope through canonical URLs. Phase 33 should keep `compare_token` aligned with that posture instead of inventing a page-local identity store.

### Pattern 3: Stale-preview state is compare-driven
The UI should continue to rely on compare findings, especially `:staleness_conflict`, rather than introducing a second stale flag. The compare engine stays authoritative for preview identity validity.

### Anti-Patterns to Avoid

- Do not fix this by creating session-only or hidden assign state for preview identity.
- Do not reimplement compare-token validation in `rulestead_admin`.
- Do not widen the change into tenant-resolution work, public promotion-plan work, or milestone artifact backfill.

## Root Cause Trace

1. `EnvironmentCompareLive.Index.handle_params/3` reads `compare_token` from the summary route and stores it on the socket.
2. `EnvironmentCompareLive.Index.load_compare/1` already passes that token into `Rulestead.compare_environments/3`.
3. `EnvironmentCompareLive.Index.flag_path/2` omits `compare_token` when generating drill-in links.
4. `EnvironmentCompareLive.Show.handle_params/3` expects `compare_token` so drill-in pages can re-run compare against the reviewed preview identity.
5. `Rulestead.Promotion.Compare` already reports stale preview via `:staleness_conflict` when the provided token no longer matches the expected compare identity.

## Common Pitfalls

### Pitfall 1: Fixing only the drill-in page
The drill-in page already forwards `compare_token`; changing it alone does not repair summary-to-detail navigation.

### Pitfall 2: Replacing URL identity with hidden state
That would break refresh/deep-link resilience and conflict with the mounted route-backed compare posture established earlier.

### Pitfall 3: Over-expanding verification
Phase 33 only needs targeted mounted compare coverage. It does not need new end-to-end browser tests or core compare-engine production changes unless a targeted test exposes one.

## Likely Verification Targets

- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/show_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`

## Key Insight

Phase 33 is a preview-identity carry-through bug in mounted navigation, not a missing compare capability. The compare token already exists and the drill-in page already knows how to use it; the summary link simply needs to stop dropping it.
