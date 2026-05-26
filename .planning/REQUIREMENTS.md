# Requirements: v1.5.0 - Guarded Rollout Foundations

**Defined:** 2026-05-26
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions - booleans, variants, and remote config - with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.5.0 Requirements

### Guardrail Signal Contract (`ROL`)

- [ ] **ROL-01**: Operators can attach one or more host-supplied guardrail signals to a staged rollout with explicit threshold, freshness, sample-size, environment, and tenant semantics without making Rulestead fetch or own observability data directly.
- [ ] **ROL-02**: Each rollout stage evaluates guardrail facts inside an explicit monitoring window and resolves to fail-closed decision states such as `healthy`, `pending_data`, `held`, or `rollback_triggered` instead of assuming health from weak or stale signals.
- [ ] **ROL-03**: Guarded rollout automation preserves deterministic sticky rollout semantics and restores the last stable stage snapshot rather than introducing time-based or non-sticky user-routing behavior.

### Audited Intervention Workflow (`AUD`)

- [ ] **AUD-01**: Automatic hold and rollback actions execute through the existing governed mutation and audit envelope with exact breached-signal evidence, triggering source, and replayable stage history.
- [ ] **AUD-02**: Operators can distinguish automatic guardrail actions from manual rollout actions with clear remediation guidance while preserving environment and tenant scope in every audit and timeline entry.

### Mounted Rollout Status (`ADM`)

- [ ] **ADM-01**: Mounted rollout screens show per-stage guardrail status, thresholds, freshness, and intervention reasons inside the existing workflow without implying standalone admin support or a built-in observability dashboard.

### Verification & Support Truth (`VER`)

- [ ] **VER-01**: Repo-local proof and docs cover stale-signal, insufficient-sample, hold, rollback, and bounded host-seam behavior so guarded rollout support claims stay explicit, rerunnable, and fail closed.

## Future Requirements

### Deferred Beyond v1.5.0

- **ROL-04**: Rollouts can auto-advance between stages when guardrails remain healthy for a configured observation window.
- **ROL-05**: Guardrails can compare rollout health against bounded baselines or cohorts without embedding a bespoke statistics engine.
- **SEG-01**: Reusable targeting deepening adds impact previews and dependency visibility for the already-shipped audience surface.
- **SEG-02**: Shared targeting assets preserve explainability, compare correctness, import/export validity, and promotion safety without hidden inheritance graphs.

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| Host-supplied rollout signal seam | Host app owns metrics, baselines, and freshness truth | low-frequency semantic | high | high | merge-blocking seam and fail-closed proof | `core` |
| Guarded rollout decision engine | `rulestead` owns deterministic stage decision logic | low-frequency semantic | high | high | merge-blocking decision and audit proof | `core` |
| Mounted rollout guardrail status and timeline UX | `rulestead_admin` owns mounted operator presentation only | native screen | high | medium | bounded mounted UI/workflow proof | `companion` |
| Metrics warehouse, alerting backend, or fleet observability dashboards | no route owner inside current product boundary | defer | high | high | n/a | `defer` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| Guardrail authored-state and runtime signal seam in `rulestead` | `core` | In scope |
| Hold and rollback decision policy plus audit evidence in `rulestead` | `core` | In scope |
| Mounted rollout guardrail status, timeline, and explanation surfaces in `rulestead_admin` | `companion` | In scope |
| Root/package docs and proof scripts for bounded guarded rollout support | `example/docs-only` | In scope |
| Metrics storage, dashboards, anomaly detection, or provider adapters owned by Rulestead | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| Guardrail signal seam and fail-closed decisions | deterministic tests for stale, missing, insufficient, healthy, held, and rollback-triggered states | host-app smoke run against a wired metrics seam |
| Audit and governed rollout actions | transaction and audit-history proof for automatic hold and rollback actions | operator walkthrough of timeline and remediation copy |
| Mounted rollout status surfaces | targeted mounted workflow tests for stage status, reasons, and fallback copy | demo-path guardrail walkthrough |
| Docs and support truth | release-contract checks around proof commands and supported host responsibilities | maintainer spot-check against rollout guides |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Rebuild / Setup Expectation | Rough-Edge Docs Required |
|---------|----------------------------|-------------------------------|-----------------------------|--------------------------|
| Host-supplied guardrail signal seam | Guarded decisions stay `pending_data` or `held`; they never assume healthy | Missing or stale signal providers fail closed with explicit reasons | Host app must wire one supported signal behaviour before guarded automation is expected to work | yes |
| Automatic hold and rollback behavior | Automatic actions remain bounded to supported staged rollouts only | Weak sample, stale data, or unsupported scope blocks automation and records the reason | No native rebuild surface; runtime and mounted package updates follow the linked-version release model | yes |
| Mounted rollout status UI | UI shows bounded guardrail health and reasons only, not fleet-wide observability | Missing prerequisites render explanatory fallback copy instead of empty "healthy" state | Mounted host app must expose the documented rollout route and policy seam | yes |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rulestead-owned metrics ingestion, storage, or dashboards | Violates the host-owned observability boundary and would widen the product into an observability platform |
| Standalone `rulestead_admin` rollout control plane | Conflicts with the mounted sibling-package design |
| Time-based or non-sticky gradual rollout semantics | Breaks deterministic user experience and contradicts the existing rollout posture |
| Automatic stage advancement based on healthy guardrails | Valuable later, but too broad for the first bounded guarded-rollout milestone |
| Reframing reusable audiences as a new milestone wedge | The audience surface already shipped; later work should deepen safety and ergonomics instead |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROL-01 | Phase 49 | Pending |
| ROL-02 | Phase 50 | Pending |
| ROL-03 | Phase 50 | Pending |
| AUD-01 | Phase 50 | Pending |
| AUD-02 | Phase 50 | Pending |
| ADM-01 | Phase 51 | Pending |
| VER-01 | Phase 52 | Pending |

**Coverage:**
- v1.5.0 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-05-26*
*Last updated: 2026-05-26 after milestone initialization*
