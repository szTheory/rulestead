# Roadmap: v1.1.0 - Tenancy Helpers & Validation

## Phases

- [x] **Phase 29: Tenancy Helpers & Validation** - Add the smallest coherent tenant-aware scope, bucketing, audit, and validation seams that fit the shipped linked-version product shape.
- [x] **Phase 30: Mounted Admin Tenant Scope Closure** - Close the mounted-admin tenant-scoping gap so operator flows preserve explicit tenant scope outside local simulation.
- [x] **Phase 31: Audit Tenant Provenance Enforcement** - Close the remaining audit-provenance gap so tenant context is attached automatically on mutation and apply paths.
- [x] **Phase 32: Public Promotion Tenant Scope Closure** - Close the public promotion-plan tenant-scope gap so saved plans preserve explicit tenant scope end to end.
- [x] **Phase 33: Compare Drill-in Preview Identity Closure** - Close the mounted compare drill-in gap so reviewed preview identity survives summary-to-detail navigation. (completed 2026-05-22)
- [x] **Phase 34: Milestone Auditability Backfill** - Backfill the missing verification and summary artifacts required to close out the milestone audit cleanly. (completed 2026-05-23)

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
- **Plans**: 3 plans
- [x] 31-01-PLAN.md — Normalize tenant provenance at the command and replay boundary
- [x] 31-02-PLAN.md — Automatic audit-builder provenance enforcement and adapter parity
- [x] 31-03-PLAN.md — Scheduled execution and release-contract provenance verification
**Gap Closure**: Closes audit gap `TEN-03` and flow `audit-tenant-provenance`.
**Success Criteria** (what must be TRUE):
  1. Ecto and fake-store audit builders merge bounded tenant provenance from command context automatically.
  2. Audit-event serialization and mutation/apply paths preserve tenant provenance consistently across persisted audit rows.
  3. Verification covers both real store and fake adapter seams so tenant provenance cannot silently drop in shipped paths.

### Phase 32: Public Promotion Tenant Scope Closure
**Goal**: Public promotion-plan generation preserves explicit tenant scope through compare, saved-plan serialization, and apply handoff instead of silently dropping it.
**Depends on**: Phase 31
**Requirements**: TEN-01, TEN-03
**Plans**: 2 plans
- [x] 32-01-PLAN.md — Public plan-generation seam fix plus façade regression coverage
- [x] 32-02-PLAN.md — Saved-plan/apply, governed replay, Mix-task, and release-surface verification
**Gap Closure**: Closes audit gaps `TEN-01`, `TEN-03`, integration gap `saved-promotion-plan-tenant-scope`, and flow `public-plan-promotion-with-tenant`.
**Success Criteria** (what must be TRUE):
  1. `Rulestead.plan_promotion/3` forwards explicit `tenant_key` through compare and saved-plan generation without widening the tenancy surface.
  2. Saved promotion plans generated from public APIs preserve tenant scope for later apply flows and fail closed when scope is invalid or missing.
  3. Verification proves the explicit-tenant public promotion flow end to end in the shipped two-package design.

### Phase 33: Compare Drill-in Preview Identity Closure
**Goal**: Mounted compare summary pages carry preview identity into drill-in routes so detailed review stays bound to the intended compare result.
**Depends on**: Phase 32
**Requirements**: TEN-03
**Plans**: 1 plan
- [x] 33-01-PLAN.md — Preserve compare preview identity across mounted summary-to-detail navigation
**Gap Closure**: Closes audit gap `TEN-03`, integration gap `compare-drill-in-token-carry-through`, and flow `mounted-compare-summary-to-drill-in`.
**Success Criteria** (what must be TRUE):
  1. Compare summary links preserve `compare_token` when routing into drill-in pages.
  2. Drill-in pages continue to handle stale-preview and reviewed-preview states against the same preview identity.
  3. Verification covers the mounted compare summary-to-detail path without changing the release boundary or introducing standalone-admin drift.

### Phase 34: Milestone Auditability Backfill
**Goal**: Milestone audit artifacts and requirement traceability are brought back into sync so v1.1.0 can be re-audited and closed with complete evidence.
**Depends on**: Phase 33
**Requirements**: None
**Plans**: 2 plans
- [x] 34-01-PLAN.md — Reconstruct missing Phase 30 summary and verification artifacts
- [x] 34-02-PLAN.md — Refresh the v1.1.0 milestone audit and active planning state
**Gap Closure**: Closes Phase 30 verification and summary artifact debt from the v1.1.0 milestone audit.
**Success Criteria** (what must be TRUE):
  1. Phase 30 has the required verification artifact in the expected planning location.
  2. Phase-level summary/frontmatter artifacts needed for milestone cross-checks exist and match requirement completion claims.
  3. The milestone audit inputs no longer disagree about tenancy requirement status because planning artifacts are internally consistent.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 29. Tenancy Helpers & Validation | 2/2 | Complete | 2026-05-21 |
| 30. Mounted Admin Tenant Scope Closure | 2/2 | Complete | 2026-05-22 |
| 31. Audit Tenant Provenance Enforcement | 3/3 | Complete | 2026-05-22 |
| 32. Public Promotion Tenant Scope Closure | 2/2 | Complete | 2026-05-22 |
| 33. Compare Drill-in Preview Identity Closure | 1/1 | Complete | 2026-05-22 |
| 34. Milestone Auditability Backfill | 2/2 | Complete | 2026-05-23 |

## Why This Milestone Now

`v1.1.0` is the first deliberate post-GA milestone. The new JTBD gap review confirmed that tenancy is still the strongest near-term fit:

- it relieves real SaaS adopter pain immediately
- it reuses explicit context, preview/apply, and mounted-admin seams already in the product
- it can ship without widening into tenant-partitioned topology or standalone control-plane work

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md)

## Next Step

Close out milestone `v1.1.0` with `$gsd-complete-milestone`.
