# Phase 21: Infrastructure Observability UI - Validation Plan

## Goal
Verify that Phase 21 adds a truthful infrastructure observability surface across `rulestead` and `rulestead_admin`, exposing bounded cache freshness, sync health, and adapter status without inventing undiscoverable cluster state or breaking Phase 20 telemetry consumers.

## Dimension 1: Functional Correctness (INF-01)
- [ ] **Bounded health snapshot:** Verify the core projection reports `snapshot_version`, `cache_age_ms`, `sync_latency_ms`, `refresh_status`, and adapter health for each environment from bounded runtime state.
- [ ] **Truthful topology scope:** Verify the default snapshot is explicitly current-node scoped and does not imply undiscovered peers are healthy.
- [ ] **Admin diagnostics rendering:** Verify the mounted diagnostics page renders summary-first health information, scope labeling, and degraded/empty states for operators.

## Dimension 2: Telemetry Compatibility (INF-02)
- [ ] **Phase 20 contract preserved:** Verify `[:rulestead, :runtime, :invalidation, ...]` events still emit unchanged for received, ignored, refresh-triggered, and refresh-failed outcomes.
- [ ] **Alias events are additive:** Verify any `[:rulestead, :cache, :invalidation]` or `[:rulestead, :sync, :delta_received]` compatibility events emit alongside the Phase 20 family rather than replacing it.
- [ ] **Bounded metadata only:** Verify telemetry aliases remain limited to environment, snapshot version, reason, and refresh status.

## Dimension 3: Reliability & Regression Safety
- [ ] **Cluster invalidation regression:** Verify the existing cross-node convergence harness still passes after the Phase 21 observability changes.
- [ ] **Connected-only diagnostics loading:** Verify the LiveView does not depend on blocking disconnected mount for health loading.
- [ ] **Safe degraded behavior:** Verify missing, stale, or degraded health states render warning/critical operator copy instead of crashing or silently implying success.

## Dimension 4: Accessibility & Operator Safety
- [ ] **Mounted-admin behavior preserved:** Verify `/diagnostics` stays inside the existing `rulestead_admin` session/policy envelope and keeps the environment picker semantics.
- [ ] **Accessible diagnostics surface:** Verify the page exposes landmarks, labels, and refresh/navigation controls that are readable without depending on color alone.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/runtime/diagnostics_test.exs test/rulestead/runtime/health_test.exs test/rulestead/runtime/health_telemetry_test.exs test/rulestead/telemetry_test.exs test/rulestead/runtime/cluster_refresh_test.exs -x`
- `cd rulestead_admin && mix test test/rulestead_admin/live/diagnostics_live/index_test.exs test/rulestead_admin/live/diagnostics_live/accessibility_test.exs -x`
