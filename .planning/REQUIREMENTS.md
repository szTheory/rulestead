# Requirements: v1.1.0 - Tenancy Helpers & Validation

**Defined:** 2026-05-21
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.1.0 Requirements

### Tenancy Helpers & Scope (TEN)

- [x] **TEN-01**: Runtime and admin flows support explicit tenant scope without requiring environment-per-tenant or cloned flag topology.
- [x] **TEN-02**: Promotion and import validation detect tenant-sensitive dependency, scoping, or targeting issues before apply.
- [ ] **TEN-03**: Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata.

## Future Requirements

### Deferred Beyond v1.1.0

- **LIF-01**: Flag ownership metadata and expected-lifetime workflows become first-class operator and cleanup flows.
- **LIF-02**: Stale-flag cleanup and archive guidance become a more visible lifecycle system across docs and admin surfaces.
- **ROL-01**: Metric-linked guarded rollouts and automatic rollback foundations.
- **SEG-01**: Reusable targeting assets such as shared segments or templates.
- **TEN-04**: Tenant hierarchies, tenant-partitioned authored storage, environment-per-tenant topology, or tenant-specific manifest trees.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Environment-per-tenant topology | Too large a product jump for the first post-GA milestone and explicitly outside the bounded tenancy seam |
| Tenant-partitioned authored storage or snapshot tables | Widens the architecture far beyond helper seams and validation |
| Tenant inheritance or tenant-cloned manifest trees | Adds hidden precedence and topology complexity before the minimal tenancy contract is proven |
| Cross-tenant global dashboards | Pushes `rulestead_admin` toward a standalone control-plane shape |
| Implicit “all tenants” mutation behavior | Violates the explicit, fail-closed tenancy posture |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEN-01 | Phase 30 | Complete |
| TEN-02 | Phase 29 | Complete |
| TEN-03 | Phases 30, 31 | Pending |

**Coverage:**
- v1.1.0 requirements: 3 total
- Mapped to phases: 3
- Unmapped: 0

---
*Requirements defined: 2026-05-21*
*Last updated: 2026-05-22 after Phase 30 execution*
