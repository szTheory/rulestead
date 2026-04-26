# Roadmap: Rulestead

## Current Milestone: v0.2.0 Governance and Operator Confidence

**Status:** Phase 11 complete (4 of 4 plans complete)
**Phases:** 9-13
**Requirements:** [.planning/REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/REQUIREMENTS.md)

## Overview

`v0.2.0` is the governance milestone. It builds on the archived `v0.1.0` runtime, admin, documentation, and release foundation by making high-impact mutations safer and more legible for operators: change requests, approvals, scheduled execution, and webhook-connected workflows.

This milestone also closes the two bounded carryover items from `v0.1.0`:

- The remaining Phase 7 sibling-package verification gap.
- The live post-publish evidence capture for `0.1.0`, once Hex visibility permits the verifier to run successfully.

## Prior Milestone History

- [x] `v0.1.0` — first polished Hex release archived in [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md)

## Phases

### Phase 9: Governance Core Contracts, Change Requests, and Approval Policy

**Goal:** Establish the storage, domain contracts, policy hooks, and audit correlation model for governed mutations.
**Depends on:** 8
**Plans:** 6 planned slices

Plans:

- [x] 09-01-PLAN.md — Lock governance domain contracts for change requests, approvals, and governed mutation states
- [x] 09-02-PLAN.md — Add store schema, command contracts, and audit correlation fields for governed changes
- [x] 09-03-PLAN.md — Expand the host-owned policy seam for change-request requirements and self-approval guards
- [x] 09-04-PLAN.md — Wire the root facade and adapter parity for governed submit/approve/reject/cancel/execute flows
- [x] 09-05-PLAN.md — Prove governance safety rules with contract tests and a scripts-first verifier

**Details:**

- Requirements: GOV-01, GOV-02, GOV-03, GOV-04.
- Preserve the current host-owned auth seam; governance augments the admin mutation path but does not introduce bundled identity.
- Keep direct runtime evaluation untouched; this phase is about authoring and operator safety.

### Phase 10: Scheduled Changes and Durable Execution

**Goal:** Add future-dated mutation scheduling with durable execution, idempotent retries, and rollout-aware job orchestration.
**Depends on:** 9
**Plans:** 4 planned slices

Plans:

- [x] 10-01-PLAN.md — Scheduled-change schema, command contracts, and lifecycle state model
- [x] 10-02-PLAN.md — Oban-backed executor for due changes with idempotent retry and recovery semantics
- [x] 10-03-PLAN.md — Rollout-stage and kill-switch scheduling integration through the governed command path
- [x] 10-04-PLAN.md — Audit, telemetry, and focused failure-handling verification for scheduled execution

**Details:**

- Requirements: SCH-01, SCH-02, SCH-04.
- Use the existing Oban seam rather than inventing a second execution substrate.
- Every scheduled mutation must remain previewable, auditable, and replay-safe.

### Phase 11: Mounted Admin Governance and Schedule UI

**Goal:** Expose change requests, approval review, and scheduled-change visibility inside `rulestead_admin` without breaking the mounted package boundary.
**Depends on:** 9, 10
**Plans:** 4 planned slices

Plans:

- [x] 11-01: Mounted routes, navigation, and operator IA additions for change requests and schedule views
- [x] 11-02: Change-request detail/review screens with diff, simulation context, and approval actions
- [x] 11-03: Schedule list/calendar surfaces with status, cancellation, and failure details
- [x] 11-04: Accessibility and sibling-package verification for the new governance UI flows

**Details:**

- Requirements: GOV-05, SCH-03.
- Follow the existing preview -> confirm -> audit interaction model and mounted host-app conventions.
- Do not turn the admin package into a standalone app or broaden its release posture.

### Phase 12: Webhook Ingress, Outbound Notifications, and Operator Visibility

**Goal:** Normalize webhook-driven governance events into the same trusted mutation path and expose delivery visibility for operators.
**Depends on:** 9
**Parallel with:** 11 after governance contracts settle
**Plans:** 6 planned slices

Plans:

- [ ] 12-01: Signed inbound webhook verifier, replay protection, and normalized change-event boundary
- [x] 12-02: Governed inbound execution path with audit metadata and failure handling
- [ ] 12-03: Outbound webhook destinations, event contracts, and command surface
- [ ] 12-04: Retry-safe outbound delivery worker, signing, telemetry, and exhausted-state handling
- [ ] 12-05: Mounted admin visibility and accessibility for webhook status, rejections, and delivery history
- [ ] 12-06: Mounted verifier script and route docs for shipped webhook visibility

**Details:**

- Requirements: HOOK-01, HOOK-02, HOOK-03, HOOK-04.
- Reuse the existing security posture: fail closed on malformed signatures and preserve immutable audit history.
- Keep webhook work within the mounted admin + core-package release design.

### Phase 13: Operational Carryover Closure and Milestone Verification

**Goal:** Close `v0.1.0` carryover items and verify the governance milestone without scope creep into broader platform work.
**Depends on:** 10, 11, 12
**Plans:** 4 planned slices

Plans:

- [ ] 13-01: Close the remaining Phase 7 simulation helper verification gap from `rulestead_admin`
- [ ] 13-02: Execute or stage the live `0.1.0` published-release evidence capture, depending on Hex visibility
- [ ] 13-03: Governance-flow verification and release/readiness docs limited to shipped `v0.2.0` behavior
- [ ] 13-04: Milestone audit, traceability closure, and archive prep

**Details:**

- Requirements: OPS-01, OPS-02, OPS-03.
- `OPS-02` stays externally blocked until Hex serves the published packages; the roadmap keeps it explicit rather than pretending it does not exist.
- Keep verification scripts-first and aligned with the linked-version sibling-package release workflow.

## Milestone Summary

**Decimal Phases:** None

**Key Decisions:**

- Continue phase numbering from the archived `v0.1.0` milestone; `v0.2.0` starts at Phase 9.
- Treat governance as the next coherent release slice, not as scattered follow-up work.
- Keep the two `v0.1.0` deferred items in scope as bounded operational closure work, not as open-ended cleanup.
- Preserve the mounted two-package architecture and avoid speculative experimentation or platform-expansion scope.

**Deferred Beyond This Milestone:**

- Experiment analytics and guardrail metrics.
- Redis and other expanded store/runtime topologies.
- Import/export expansion, OpenFeature bridge, and broader ecosystem integration.
- Multi-tenant helper work beyond what the existing package model already supports.

**Risks To Watch:**

- Governance can sprawl into a much larger permissions/product workflow if the requirement boundary is not enforced.
- Scheduled execution must remain idempotent and observable or it will create operator distrust.
- Webhook ingress and outbound delivery have a high blast radius; they must stay on the same authorization and audit rails as direct admin actions.

## Backlog

### Phase 999.1: rulestead_sigra optional Sigra integration sibling package (BACKLOG)

**Goal:** [Captured for future planning] Optional Sigra integration via a third sibling hex package (`rulestead_sigra`). Bridge plug + LiveView `on_mount` + AdminPolicy adapter (shape-bridge only — host supplies roles callback, no default). Reads Sigra `current_scope`/`admin_scope`, writes Rulestead's `current_actor` + `correlation_id` into the Phoenix session. Audit tables stay separate, joined via `correlation_id`. Impersonation: `actor.id` is the impersonator with impersonated user recorded in `metadata.context`. Defer org→environment mapping. Lean on `Sigra.Plug.RequireSudo` for step-up. Ship after v0.2.0, not mid-milestone. Architecture and risks captured at `/Users/jon/.claude/plans/so-i-m-considering-shimmering-kitten.md`.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)

---
*Last updated: 2026-04-25 after capturing rulestead_sigra backlog item*
