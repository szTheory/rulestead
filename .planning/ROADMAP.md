# Roadmap

## Current Status

- [x] **v1.1.0 — Tenancy Helpers & Validation**: shipped on 2026-05-23 across Phases 29-34. Archive: [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md).
- [x] **v1.2.0 — Lifecycle Hygiene & Ownership**: shipped on 2026-05-24 across Phases 35-40. Archive: [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md).

## Active Milestone

### v1.3.0 — Adopter Truth & Proof Closure

**Status:** active on 2026-05-24
**Why now:** The strongest remaining adopter gap is support truth: docs, install path, migrations, and verification need to agree with the shipped post-GA surface before new differentiated features are added.
**Requirements covered:** `DOC-01`, `DOC-02`, `PAR-01`, `PAR-02`, `ADM-01`, `VER-01`, `OFE-01`

| Phase | Goal | Requirements |
|-------|------|--------------|
| 41 | Align the root and sibling release story with the actual post-`v1.0.0` shipped posture and bounded support claims. | `DOC-01`, `DOC-02` |
| 42 | Reconcile runtime schema, migrations, and installer truth for lifecycle and ownership authored-state parity. | `PAR-01`, `PAR-02` |
| 43 | Close mounted-admin contract drift and restore core/admin verification truth without widening the product shape. | `ADM-01`, `VER-01` |
| 44 | Establish a runnable bounded OpenFeature bridge proof path and finish milestone-wide support-truth verification. | `OFE-01` |

### Phase 41: Release Truth Alignment

**Goal:** Public-facing docs and release language tell the same post-GA story the repo can actually support today.
**Depends on:** Phase 40
**Success criteria:**
1. Root and sibling package READMEs no longer claim the first public Hex release is merely planned after `v0.6.0`.
2. Installation and onboarding docs point readers to the real current package, demo, and verification posture.
3. Support-facing language stays bounded where proof is incomplete instead of implying a stronger surface.

### Phase 42: Runtime Contract Parity

**Goal:** Runtime schema, migrations, and installer truth agree on lifecycle and ownership authored-state fields.
**Depends on:** Phase 41
**Success criteria:**
1. The `flags` authored-state contract represented in runtime code is backed by matching migration truth.
2. Installer and migration guidance describe the same database shape adopters actually receive.
3. Targeted runtime tests prove lifecycle and ownership parity end to end.

**Plans:** 3/3 plans executed
- [x] 42-01-PLAN.md — Squosh 16 legacy migrations into a single GA-ready migration baseline
- [x] 42-02-PLAN.md — Update Rulestead.Flag and internal data stores to drop legacy columns
- [x] 42-03-PLAN.md — Update rulestead_admin views and sync Golden tests to squoshed installer behavior

### Phase 43: Mounted Contract & Verification Closure

**Goal:** Mounted-admin lifecycle and permission behavior expose one deliberate host-facing contract and the core/admin verification surface returns to honest green or bounded truth.
**Depends on:** Phase 42
**Success criteria:**
1. Lifecycle form field expectations and permission behavior are aligned across code, tests, and docs.
2. Mounted-admin remains clearly documented as a companion surface with host-owned auth and identity seams.
3. `rulestead` and `rulestead_admin` verification surfaces are green again, or any remaining caveats are explicitly bounded in release truth.

**Plans:** 3/3 plans executed
- [x] 43-01-PLAN.md — Clarify the mounted companion contract and lock the public host-facing route seam in docs and integration proof
- [x] 43-02-PLAN.md — Repair stale lifecycle/admin-contract proof so the mounted suites encode the current authored-state contract and permission split
- [x] 43-03-PLAN.md — Restore honest cross-package verification truth for the mounted lifecycle/admin contract surface

### Phase 44: OpenFeature Bridge Proof & Final Support Audit

**Goal:** The optional OpenFeature bridge has a runnable documented proof path and the milestone closes with one coherent support-truth posture.
**Depends on:** Phase 43
**Success criteria:**
1. `open_feature_rulestead` has a documented setup and runnable proof path that maintainers and adopters can follow.
2. Bridge test/dependency posture is either green or explicitly bounded with no ambiguous dead-end state.
3. Milestone docs, requirements traceability, and verification evidence agree on the final supported surface.

## Next Candidate

- `v1.4.0 — Guarded Rollout Foundations` remains the next differentiated follow-on once `v1.3.0` restores support-truth credibility.

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-REQUIREMENTS.md)

## Next Step

Run `$gsd-secure-phase 43` to satisfy the mounted companion security gate, or move to `$gsd-plan-phase 44` after that review if you want to stage the OpenFeature bridge proof work next.
