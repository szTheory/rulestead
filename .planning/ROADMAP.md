# Roadmap: v0.6.0 - Multi-environment Sync & Tenancy

## Phases

- [ ] **Phase 22: Environment Compare & Conflict Model** - Establish the authored-state diff model, dependency checks, and operator-facing compare semantics for environment promotion.
- [ ] **Phase 23: Governed Promotion Apply** - Apply whole-flag environment promotion through existing governance, audit, and safety boundaries.
- [ ] **Phase 24: GitOps Manifests & CLI Surface** - Ship deterministic manifest export, validation, diffing, import, and promotion automation tasks.
- [ ] **Phase 25: Tenancy Helpers & Validation** - Add the minimal tenant-aware scope, bucketing, audit, and validation seams that fit the current linked-version product shape.

## Phase Details

### Phase 22: Environment Compare & Conflict Model
**Goal**: Operators can compare source and target environment configuration with clear dependency and drift feedback before any apply happens.
**Depends on**: Phase 21
**Requirements**: PROM-01, PROM-02
**Plans**: 2 plans
- [ ] 22-01-PLAN.md — Authored-state Diff Engine & Dependency Closure
- [ ] 22-02-PLAN.md — Admin Compare View & Conflict Presentation
**Success Criteria** (what must be TRUE):
  1. A source and target environment can be compared using authored flag state rather than runtime snapshots.
  2. The compare result surfaces dependency gaps, target drift, and stale-preview conflicts before mutation.
  3. Operators can review a clear compare view without the admin package becoming an independent release-orchestration product.

### Phase 23: Governed Promotion Apply
**Goal**: Whole-flag environment configuration can be promoted safely into a target environment through the existing mutation, approval, and audit envelope.
**Depends on**: Phase 22
**Requirements**: PROM-03, PROM-04
**Plans**: 2 plans
- [ ] 23-01-PLAN.md — Transactional Promotion Apply & Snapshot Regeneration
- [ ] 23-02-PLAN.md — Governance, Audit, and Revert Path
**Success Criteria** (what must be TRUE):
  1. Promotion applies authored configuration changes transactionally and regenerates target runtime state afterward.
  2. Protected target environments require the same governed mutation path as other high-impact admin changes.
  3. Operators have a minimal revert path by re-applying a prior environment configuration version.

### Phase 24: GitOps Manifests & CLI Surface
**Goal**: Teams can export, validate, diff, import, and promote deterministic manifests from local workflows and CI.
**Depends on**: Phase 23
**Requirements**: MAN-01, MAN-02, MAN-03, MAN-04
**Plans**: 3 plans
- [ ] 24-01-PLAN.md — Canonical Manifest Schema & Export
- [ ] 24-02-PLAN.md — Validation, Diffing, and Machine-readable Output
- [ ] 24-03-PLAN.md — Dry-run Import / Promote CLI
**Success Criteria** (what must be TRUE):
  1. Exported manifests are deterministic, semantic, and suitable for code review.
  2. Validation and diff commands work in both human-readable and machine-readable modes.
  3. Import and promote operations support preview/dry-run before explicit apply.

### Phase 25: Tenancy Helpers & Validation
**Goal**: Rulestead supports tenant-aware scoping and validation without introducing tenant-partitioned storage or environment-per-tenant topology.
**Depends on**: Phase 24
**Requirements**: TEN-01, TEN-02, TEN-03
**Plans**: 2 plans
- [ ] 25-01-PLAN.md — Tenancy Seam, SingleTenant Default, and Bucketing Hooks
- [ ] 25-02-PLAN.md — Tenant-aware Validation, Audit Metadata, and Admin Scope
**Success Criteria** (what must be TRUE):
  1. Tenant scope is explicit in runtime and admin flows where it matters.
  2. Promotion and import paths reject tenant-sensitive invalid states before apply.
  3. The shipped tenancy seam remains minimal, composable, and aligned with the current two-package release model.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 22. Environment Compare & Conflict Model | 0/2 | Pending | — |
| 23. Governed Promotion Apply | 0/2 | Pending | — |
| 24. GitOps Manifests & CLI Surface | 0/3 | Pending | — |
| 25. Tenancy Helpers & Validation | 0/2 | Pending | — |
