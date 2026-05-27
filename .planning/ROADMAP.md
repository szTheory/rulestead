# Roadmap: Rulestead

## Current Milestone

- **v1.6.0 - Reusable Targeting Deepening**: active as of 2026-05-27. Phases 53-56 deepen already-shipped reusable audience targeting with impact previews, dependency visibility, explainability, mounted operator workflows, and support truth while preserving deterministic snapshots and the linked sibling-package release model.

## Latest Shipped Milestone

- **v1.5.0 - Guarded Rollout Foundations**: shipped on 2026-05-27. See [.planning/milestones/v1.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-ROADMAP.md) and [.planning/milestones/v1.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-REQUIREMENTS.md).

## Phases

**Phase Numbering:**

- Integer phases (53, 54, 55, 56): Planned milestone work
- Decimal phases (53.1, 53.2): Urgent insertions, if needed

- [x] **Phase 53: Impact Preview Contract** - Operators can preview, token-confirm, and audit reusable audience mutations without false precision or runtime lookup drift. (completed 2026-05-27)
- [x] **Phase 54: Dependency Truth And Promotion Safety** - Core dependency inventory, validation, promotion, compare, and manifest paths expose audience dependency truth and fail closed. (completed 2026-05-27)
- [ ] **Phase 55: Mounted Operator Workflows** - Mounted admin screens make reusable audience dependencies, previews, confirmations, and explain traces visible inside the existing policy envelope.
- [ ] **Phase 56: Proof, Docs, And Support Truth** - Verification, docs, and release-contract truth close the reusable targeting scope under the linked sibling-package model.

## Phase Details

### Phase 53: Impact Preview Contract

**Goal**: Operators can safely understand and confirm reusable audience mutations before apply while runtime evaluation remains snapshot-local and deterministic.
**Depends on**: Phase 52
**Requirements**: IMP-01, IMP-02, IMP-03, IMP-04
**Success Criteria** (what must be TRUE):

  1. Operator can request an audience impact preview that shows environment scope, tenant scope, referenced flags/rulesets, rollout/lifecycle context, preview basis, uncertainty, and redacted sample evidence.
  2. Audience edits, archive/delete attempts, and protected shared-targeting mutations fail closed unless the operator applies with a fresh preview token or fingerprint.
  3. Runtime evaluation uses compiled snapshot audience definitions only and never performs live database, mounted-admin, host identity, or observability lookups to resolve audience references.
  4. Support can reconstruct accepted, blocked, or denied audience mutations from audit evidence that includes preview fingerprint, affected-reference summary, actor, reason, and explicit scope.

**Plans**: 4 plans
Plans:

- [x] 53-01-PLAN.md — Pure impact preview contract and affected-reference summaries
- [x] 53-02-PLAN.md — Snapshot-local audience runtime evaluation
- [x] 53-03-PLAN.md — Public/store command surface and Fake adapter contract
- [x] 53-04-PLAN.md — Ecto enforcement, audit evidence, and snapshot publication

### Phase 54: Dependency Truth And Promotion Safety

**Goal**: Operators and support can trust one core dependency truth for audience usage, mutation blockers, promotion, compare, replay, and manifests.
**Depends on**: Phase 53
**Requirements**: DEP-01, DEP-02, DEP-03, DEP-04
**Success Criteria** (what must be TRUE):

  1. Operator or support tooling can query audience reference inventory with stable counts, affected flag/ruleset/rule metadata, lifecycle/rollout hints, and policy-safe redaction.
  2. Audience archive/delete and ruleset publish validation block unresolved, archived, incompatible, stale, or tenant-mismatched references before broken snapshots can publish.
  3. Environment compare, promotion preview/apply, replay/re-apply, manifest export, manifest import, and manifest validation show readable audience dependency findings and fail closed on missing or incompatible targeting assets.
  4. Dependency and impact outputs sort by stable semantic keys and always carry explicit environment and tenant scope so same-name or cross-scope audiences cannot be mistaken for equivalents.

**Plans**: 4 plans
Plans:

- [x] 54-01-PLAN.md — Canonical dependency inventory projection and public/read contract
- [x] 54-02-PLAN.md — Shared dependency validator and fail-closed publish/mutation gates
- [x] 54-03-PLAN.md — Promotion/replay/manifest dependency findings and revalidation
- [x] 54-04-PLAN.md — Deterministic proof, parity verification, and phase handoff checks

### Phase 55: Mounted Operator Workflows

**Goal**: Mounted admin users can inspect, edit, confirm, and explain reusable audience dependencies through bounded workflows that render core truth without adding a standalone control plane.
**Depends on**: Phase 54
**Requirements**: ADM-01, ADM-02, ADM-03, ADM-04
**Success Criteria** (what must be TRUE):

  1. Mounted audience list and detail screens show policy-aware reference counts, used-by tables, lifecycle/owner context, and affected rollout indicators.
  2. Mounted audience edit and archive/delete flows guide operators through preview, confirmation, and audit with clear fallback states for missing previews, stale tokens, denied reads, and protected-environment governance.
  3. Flag rule editing, simulation, and explanation screens show reusable audience summaries, matched/missed audience trace steps, missing-reference copy, and support-safe explain permalinks.
  4. Mounted compare, promotion, and manifest screens render reusable audience dependency blockers and links without adding graph visualization, bulk automation, or standalone `rulestead_admin` behavior.

**Plans**: 4 plans

Plans:
- [ ] 55-01-PLAN.md — Audience library routes, detail, policy-aware used-by tables (ADM-01)
- [ ] 55-02-PLAN.md — Preview → confirm → audit mutation flows and fail-closed delete (ADM-02)
- [ ] 55-03-PLAN.md — Flag explain, rules, simulate audience traces (ADM-03)
- [ ] 55-04-PLAN.md — Compare dependency findings, verify.phase55, handoff (ADM-04)

**UI hint**: yes

### Phase 56: Proof, Docs, And Support Truth

**Goal**: The reusable targeting deepening surface is verified, documented, and supportable without drifting beyond the linked sibling-package release model.
**Depends on**: Phase 55
**Requirements**: VER-01, VER-02, VER-03
**Success Criteria** (what must be TRUE):

  1. Maintainer can run repo-local proof for dependency inventory, preview determinism, stale-token rejection, fail-closed missing/archive behavior, audit evidence, explain trace carry-through, and promotion/manifest blockers.
  2. Public docs, package docs, release-contract checks, and mounted companion proof all describe the same supported reusable-targeting scope, preview-basis limits, tenant/environment semantics, and host-owned identity/observability responsibilities.
  3. Release evidence confirms `rulestead` owns domain contracts and validation, `rulestead_admin` owns mounted presentation, and no Phase 8-only docs or standalone `rulestead_admin` publish prep were introduced.

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 53 -> 54 -> 55 -> 56

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 53. Impact Preview Contract | v1.6.0 | 4/4 | Complete    | 2026-05-27 |
| 54. Dependency Truth And Promotion Safety | v1.6.0 | 4/4 | Complete    | 2026-05-27 |
| 55. Mounted Operator Workflows | v1.6.0 | 0/TBD | Not started | - |
| 56. Proof, Docs, And Support Truth | v1.6.0 | 0/TBD | Not started | - |

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMP-01 | Phase 53 | Complete |
| IMP-02 | Phase 53 | Complete |
| IMP-03 | Phase 53 | Complete |
| IMP-04 | Phase 53 | Complete |
| DEP-01 | Phase 54 | Pending |
| DEP-02 | Phase 54 | Pending |
| DEP-03 | Phase 54 | Pending |
| DEP-04 | Phase 54 | Pending |
| ADM-01 | Phase 55 | Pending |
| ADM-02 | Phase 55 | Pending |
| ADM-03 | Phase 55 | Pending |
| ADM-04 | Phase 55 | Pending |
| VER-01 | Phase 56 | Pending |
| VER-02 | Phase 56 | Pending |
| VER-03 | Phase 56 | Pending |

**Coverage:** 15/15 v1.6.0 requirements mapped. No orphaned requirements. No duplicate phase assignments.

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md), [.planning/milestones/v1.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-ROADMAP.md), [.planning/milestones/v1.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-ROADMAP.md), [.planning/milestones/v1.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-REQUIREMENTS.md), [.planning/milestones/v1.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-REQUIREMENTS.md), [.planning/milestones/v1.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-REQUIREMENTS.md), [.planning/milestones/v1.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-REQUIREMENTS.md)
