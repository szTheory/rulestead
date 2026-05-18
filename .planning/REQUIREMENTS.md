# Requirements: v0.6.0 - Multi-environment Sync & Tenancy

**Defined:** 2026-05-18
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v0.6.0 Requirements

### Promotion & Diffing (PROM)

- [ ] **PROM-01**: Operator can compare authored flag configuration between a source and target environment before making changes.
- [ ] **PROM-02**: Promotion preview reports dependency gaps, target drift, and conflict conditions before any target mutation occurs.
- [ ] **PROM-03**: Operator can promote whole-flag environment configuration from a source environment to a target environment while preserving authored intent rather than cloning runtime snapshots.
- [ ] **PROM-04**: Promotions into protected environments flow through existing governance, audit, and approval surfaces instead of bypassing them.

### GitOps Manifests (MAN)

- [ ] **MAN-01**: Team can export deterministic environment manifests with stable semantic keys suitable for code review and CI usage.
- [ ] **MAN-02**: Team can validate and diff manifests offline or in CI with stable human-readable and machine-readable output.
- [ ] **MAN-03**: Team can import manifests through a dry-run preview and an explicit apply step instead of a hidden one-shot mutation.
- [ ] **MAN-04**: The public automation surface includes `mix rulestead.export`, `mix rulestead.validate`, `mix rulestead.diff`, `mix rulestead.import`, and `mix rulestead.promote`.

### Tenancy Helpers (TEN)

- [ ] **TEN-01**: Runtime and admin flows support an explicit `tenant_key` / tenant scope without requiring environment-per-tenant or cloned flag topology.
- [ ] **TEN-02**: Promotion and import validation detect tenant-sensitive dependency or targeting issues before apply.
- [ ] **TEN-03**: Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata.

## Future Requirements

### Deferred Beyond v0.6.0

- **SYNC-01**: Continuous bidirectional Git reconciliation between manifests and authored state.
- **SYNC-02**: Destructive prune mode that removes target state absent from the source bundle.
- **PROM-05**: Per-rule or partial-rule cherry-pick promotion as a primary UX.
- **TEN-04**: Tenant hierarchies, tenant-partitioned authoring/storage, or environment-per-tenant topology.
- **GA-01**: RBAC, API lockdown, and GA hardening reserved for `v1.0.0`.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Standalone `rulestead_admin` control plane | The admin package remains a mounted sibling package inside the host app envelope |
| Bidirectional sync or hidden reconciler | Too much ownership ambiguity and drift risk for the first multi-environment release |
| Environment inheritance as the primary sync model | Useful for bootstrapping but too surprising as the default operational model |
| Deep-merge remote-config semantics | Adds hidden precedence and drift complexity before the core compare/apply contract is stable |
| Tenant-cloned flags or env-per-tenant topology | Explodes operator complexity and violates the smallest-coherent tenancy-helper goal |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROM-01 | Phase 22 | Pending |
| PROM-02 | Phase 22 | Pending |
| PROM-03 | Phase 23 | Pending |
| PROM-04 | Phase 23 | Pending |
| MAN-01 | Phase 24 | Pending |
| MAN-02 | Phase 24 | Pending |
| MAN-03 | Phase 24 | Pending |
| MAN-04 | Phase 24 | Pending |
| TEN-01 | Phase 25 | Pending |
| TEN-02 | Phase 25 | Pending |
| TEN-03 | Phase 25 | Pending |

**Coverage:**
- v0.6.0 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-05-18*
*Last updated: 2026-05-18 after v0.6.0 milestone definition*
