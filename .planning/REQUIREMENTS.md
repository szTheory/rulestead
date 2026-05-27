# Requirements: v1.7.0 - Blast-Radius Governance

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions - booleans, variants, and remote config - with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.7.0 Requirements

### Blast-Radius Threshold Contract (`GOV`)

- [x] **GOV-01**: Protected-environment audience edits that exceed configurable blast-radius thresholds require governed approval through the existing change-request envelope instead of direct apply.
- [x] **GOV-02**: Blast-radius evaluation consumes v1.6 preview fingerprints, dependency reference counts, affected flag/ruleset metadata, and active rollout or lifecycle hints without claiming observability-backed population counts.
- [x] **GOV-03**: Below-threshold audience mutations in protected environments may still direct-apply with fresh preview confirmation; above-threshold mutations fail closed until a change request is approved and executed.
- [x] **GOV-04**: Threshold evaluation fails closed when preview data is stale, dependency truth is unresolved, protected-environment policy is ambiguous, or required threshold inputs are missing.

### Change Request Integration (`CRQ`)

- [x] **CRQ-01**: High-blast-radius audience mutation proposals submit change requests that embed preview fingerprint, affected-reference summary, threshold breach context, and intended operation scope.
- [x] **CRQ-02**: Approved change requests execute audience apply through the existing governed mutation path with frozen preview evidence and reject stale or drifted preview state at execution time.
- [x] **CRQ-03**: Rejected, cancelled, or expired audience change requests leave authored audience state unchanged and emit auditable denial or cancellation evidence.

### Mounted Governance Workflows (`ADM`)

- [ ] **ADM-01**: Mounted audience edit and archive flows detect threshold breaches in protected environments and route operators to proposal or change-request review instead of silent direct apply.
- [x] **ADM-02**: Change-request detail and audience mutation surfaces show blast-radius summary, threshold breach reasons, preview basis limits, and remediation copy inside the existing mounted policy envelope.
- [x] **ADM-03**: Operators with insufficient permission see policy-aware partial visibility for dependency and blast-radius evidence without leaking raw predicates or unauthorized resource detail.

### Verification And Support Truth (`VER`)

- [ ] **VER-01**: Repo-local proof covers threshold evaluation, change-request proposal and execution, stale-preview rejection, fail-closed missing-input behavior, and audit evidence for governed audience mutations.
- [ ] **VER-02**: Public docs, package docs, and release-contract checks describe blast-radius governance scope, threshold semantics, protected-environment behavior, and host-owned policy responsibilities.
- [ ] **VER-03**: README and getting-started quickstart teach payload-first evaluation (`Rulestead.evaluate/3`, explicit context) consistent with `guides/flows/evaluation.md`; linked-version sibling-package release model unchanged.

## Future Requirements

### Deferred Beyond v1.7.0

- **ROL-04**: Rollouts can automatically advance between stages when guardrails remain healthy for a configured observation window.
- **IMP-05**: Audience previews can compare richer host-supplied impression summaries or sample cohorts when the host explicitly provides bounded, redacted evidence through an existing seam.
- **ADM-05**: Optional targeting presets can generate concrete draft audiences or rules for common patterns without live inheritance or ongoing propagation.
- **GOV-02-ext**: Host-configurable threshold profiles per environment or tenant beyond the milestone's bounded default contract.

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| Blast-radius threshold evaluation | `rulestead` owns threshold semantics over preview/dependency payloads | low-frequency semantic | high | high | merge-blocking deterministic threshold and fail-closed proof | `core` |
| Audience change-request integration | `rulestead` owns proposal/execute validation on existing governance envelope | low-frequency semantic | high | high | merge-blocking change-request and audit proof | `core` |
| Mounted governance workflows | `rulestead_admin` owns presentation inside host-mounted policy envelope | native screen | high | medium | mounted proposal/review/execute proof | `companion` |
| Quickstart and support truth | root/package docs and release-contract checks | docs-only | medium | high | release-contract and doc parity proof | `example/docs-only` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| Blast-radius threshold contract and evaluation in `rulestead` | `core` | In scope |
| Audience mutation change-request proposal and execute paths in `rulestead` | `core` | In scope |
| Mounted proposal, review, threshold copy, and permission-aware fallbacks in `rulestead_admin` | `companion` | In scope |
| README, guides, proof commands, release-contract checks | `example/docs-only` | In scope |
| Parallel governance workflow, blast-radius dashboards, observability-backed counts, standalone admin | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| Threshold contract | deterministic tests for above/below threshold, missing inputs, stale preview, unresolved dependency truth | host-app walkthrough with protected environment policy |
| Change-request integration | proposal, approve, execute, reject, cancel, and stale-at-execute proof with audit evidence | operator walkthrough of change-request timeline |
| Mounted workflows | LiveView tests for threshold routing, proposal copy, denied reads, and change-request handoff | browser smoke for audience edit in protected env |
| Docs and support truth | release-contract checks, quickstart API parity with evaluation guide | maintainer spot-check against README and package docs |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Rebuild / Setup Expectation | Rough-Edge Docs Required |
|---------|----------------------------|-------------------------------|-----------------------------|--------------------------|
| Blast-radius threshold evaluation | Above-threshold direct apply blocked with actionable threshold breach reasons | Missing preview or dependency inputs fail closed; no zero-blast-radius assumption | Normal linked-version package update | yes |
| Change-request execution | Stale preview at execute time rejected; authored state unchanged | Missing change-request policy wiring surfaces existing setup guidance | Host policy seam unchanged | yes |
| Mounted governance UX | Policy-denied reads redacted; mutation disabled without permission | Missing governance routes render bounded fallback copy | Mounted admin under linked packages as before | yes |

## Out of Scope

| Feature | Reason |
|---------|--------|
| A parallel governance workflow outside change requests | Conflicts with existing governed-action envelope used for flags, rollouts, and promotion |
| Observability-backed blast-radius or affected-user counts | Pulls Rulestead into identity/observability ownership beyond current scope |
| Automatic audience mutation approval | Approvals remain explicit and host-policy driven |
| Standalone `rulestead_admin` control plane | Conflicts with mounted sibling-package design |
| Draft targeting presets (ADM-05) | Deferred until governance safety loop is complete |
| Auto-advance guarded rollouts (ROL-04) | Queued for v1.8.0 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GOV-01 | Phase 57 | Complete |
| GOV-02 | Phase 57 | Complete |
| GOV-03 | Phase 57 | Complete |
| GOV-04 | Phase 57 | Complete |
| CRQ-01 | Phase 58 | Complete |
| CRQ-02 | Phase 58 | Complete |
| CRQ-03 | Phase 58 | Complete |
| ADM-01 | Phase 59 | Pending |
| ADM-02 | Phase 59 | Complete |
| ADM-03 | Phase 59 | Complete |
| VER-01 | Phase 60 | Pending |
| VER-02 | Phase 60 | Pending |
| VER-03 | Phase 60 | Pending |

**Coverage:**

- v1.7.0 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after roadmap creation*
