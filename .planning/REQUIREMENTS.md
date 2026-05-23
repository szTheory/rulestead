# Requirements: v1.2.0 - Lifecycle Hygiene & Ownership

**Defined:** 2026-05-23
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.2.0 Requirements

### Lifecycle Metadata & Ownership (LIF)

- [ ] **LIF-01**: Flags expose first-class ownership and lifecycle metadata that remain explicit across authored-state reads, writes, audit events, and mounted-admin presentation without creating a Rulestead-owned identity directory.
- [ ] **LIF-02**: Rulestead classifies lifecycle state and archive readiness from bounded signals such as flag type, expected lifetime, last evaluation evidence, and code-reference coverage instead of a single blunt stale heuristic.
- [ ] **LIF-03**: Operators can review lifecycle and cleanup posture through shareable admin filters and CLI/reporting surfaces that highlight owner, lifecycle state, last evaluated, code-reference status, and recommended next action.
- [ ] **LIF-04**: Archive and cleanup flows stay explicit, previewable, and audited; Rulestead never auto-archives flags and never hides uncertainty behind false precision.
- [ ] **LIF-05**: Docs and runbooks teach the “flag from birth to retirement” lifecycle clearly for Phoenix teams, including least-surprise defaults and host-owned integration expectations.

## Future Requirements

### Deferred Beyond v1.2.0

- **ROL-01**: Rollouts can attach host-supplied guardrail signals to staged progression and stop or roll back on explicit thresholds without widening Rulestead into an observability product.
- **ROL-02**: Guarded rollout decisions remain deterministic, tenant-aware, audited, and fail-closed when signals are weak, stale, or missing.
- **SEG-01**: Reusable targeting begins with shared audiences and impact previews before any broader targeting-template system.
- **SEG-02**: Shared targeting assets preserve explainability, compare correctness, import/export validity, and promotion safety without hidden inheritance graphs.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rulestead-owned user/team directory or owner sync engine | Host applications own identity truth; lifecycle ownership must stay opaque and host-friendly |
| Automatic archival or automatic code removal | Violates least-surprise and risks destructive cleanup from advisory signals |
| Standalone lifecycle control-plane product in `rulestead_admin` | Conflicts with the mounted sibling-package design |
| Built-in metrics platform or anomaly detector for rollout health | Belongs to a later guarded-rollout milestone and should stay host-supplied |
| Generic inheritance-heavy targeting template system | Adds hidden dependency complexity before the lifecycle loop is fully credible |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LIF-01 | Phase 35 | Pending |
| LIF-02 | Phase 36 | Pending |
| LIF-03 | Phase 37 | Pending |
| LIF-04 | Phase 37 | Pending |
| LIF-05 | Phase 38 | Pending |

**Coverage:**
- v1.2.0 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-05-23*
*Last updated: 2026-05-23 after milestone definition*
