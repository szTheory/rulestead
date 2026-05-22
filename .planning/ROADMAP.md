# Roadmap: v1.1.0 - Tenancy Helpers & Validation

## Phases

- [x] **Phase 29: Tenancy Helpers & Validation** - Add the smallest coherent tenant-aware scope, bucketing, audit, and validation seams that fit the shipped linked-version product shape.
- [x] **Phase 30: Mounted Admin Tenant Scope Closure** - Close the mounted-admin tenant-scoping gap so operator flows preserve explicit tenant scope outside local simulation.
- [ ] **Phase 31: Audit Tenant Provenance Enforcement** - Close the remaining audit-provenance gap so tenant context is attached automatically on mutation and apply paths.

## Phase Details

### Phase 29: Tenancy Helpers & Validation
**Goal**: Rulestead supports explicit tenant-aware scoping and validation for real SaaS adopters without introducing tenant-partitioned storage, environment-per-tenant topology, or standalone admin drift.
**Depends on**: Phase 28
**Requirements**: TEN-01, TEN-02, TEN-03
**Plans**: 2 plans
- [x] 29-01-PLAN.md — Tenancy Seam, SingleTenant Default, and Bucketing Hooks
- [x] 29-02-PLAN.md — Tenant-aware Validation, Audit Metadata, and Admin Scope
**Success Criteria** (what must be TRUE):
  1. Tenant scope is explicit in runtime and admin flows where it matters, with a bounded `Rulestead.Tenancy` seam and a safe `SingleTenant` default.
  2. Promotion and import paths reject tenant-sensitive invalid states before apply and persist only bounded tenant scope metadata in saved plans and audit trails.
  3. The shipped tenancy support remains minimal, composable, fail-closed, and aligned with the current two-package release model.

### Phase 30: Mounted Admin Tenant Scope Closure
**Goal**: Mounted-admin session and compare flows preserve explicit tenant scope in real operator paths instead of relying on environment-only context.
**Depends on**: Phase 29
**Requirements**: TEN-01, TEN-03
**Plans**: 2 plans
- [x] 30-01-PLAN.md — Mounted session tenant resolution and shell scope chrome
- [x] 30-02-PLAN.md — Compare route tenant carry-through and targeted verification
**Gap Closure**: Closes audit gaps `TEN-01`, `TEN-03`, and flow `admin-tenant-scope`.
**Success Criteria** (what must be TRUE):
  1. Mounted-admin session resolution derives and preserves explicit tenant scope for operator flows beyond local simulation.
  2. Environment compare pages pass `tenant_key` through the shared compare seam so tenant-aware comparisons stay explicit and fail-closed.
  3. Targeted verification proves the mounted-admin tenancy path without changing the linked-version two-package release shape.

### Phase 31: Audit Tenant Provenance Enforcement
**Goal**: Audit mutation and apply paths always emit tenant provenance automatically instead of requiring callers to provide it manually.
**Depends on**: Phase 30
**Requirements**: TEN-03
**Gap Closure**: Closes audit gap `TEN-03` and flow `audit-tenant-provenance`.
**Success Criteria** (what must be TRUE):
  1. Ecto and fake-store audit builders merge bounded tenant provenance from command context automatically.
  2. Audit-event serialization and mutation/apply paths preserve tenant provenance consistently across persisted audit rows.
  3. Verification covers both real store and fake adapter seams so tenant provenance cannot silently drop in shipped paths.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 29. Tenancy Helpers & Validation | 2/2 | Complete | 2026-05-21 |
| 30. Mounted Admin Tenant Scope Closure | 2/2 | Complete | 2026-05-22 |
| 31. Audit Tenant Provenance Enforcement | 0/0 | Pending | |

## Why This Milestone Now

`v1.1.0` is the first deliberate post-GA milestone. The new JTBD gap review confirmed that tenancy is still the strongest near-term fit:

- it relieves real SaaS adopter pain immediately
- it reuses explicit context, preview/apply, and mounted-admin seams already in the product
- it can ship without widening into tenant-partitioned topology or standalone control-plane work

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md)

## Next Step

Plan the remaining tenancy provenance phase with `$gsd-plan-phase 31`.
