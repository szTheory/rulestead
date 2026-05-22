# Phase 23: Governed Promotion Apply - Research

**Researched:** 2026-05-18
**Domain:** Whole-flag authored-state promotion apply, governed promotion execution, immutable environment-version history, and transactional snapshot regeneration. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Apply entrypoint and granularity
- **D-01:** Promotion starts from the existing compare summary route, not a new release console. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-02:** Promotion is whole-flag only, with a bounded selected set rather than per-rule or unbounded bulk apply. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-03:** The primary flow is `compare -> review selected set -> confirm -> direct apply or governed request -> audit`. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-04:** Per-flag drill-in remains an inspection/fallback surface, not the only entrypoint. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-05:** The apply surface must stay bounded and explicit, not release-console-like. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-06:** Promotion copies authored desired state only, not runtime snapshots, counters, telemetry, or kill-switch truth. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Promotion bundle and validation
- **D-07:** Promotion apply is a first-class domain action, not a UI macro over unrelated per-flag commands. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-08:** The canonical bundle must include source/target env keys, selected flag keys, compare token, compare schema version, source/target fingerprints, dependency closure, and normalized proposed target state. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-09:** Apply must re-run compare/revalidation against the supplied token and fail before mutation on stale previews, blockers, or dependency drift. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-10:** Admin, CLI, and manifest/import flows should converge on one promotion bundle shape. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Protected-target workflow shape
- **D-11:** Protected-target promotion uses a new first-class governed promotion action, not disguised `publish_ruleset`. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-12:** Governed requests store the exact promotion bundle snapshot and compare-token context for review. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-13:** Approval and execution remain separate actions, with `Execute now` and `Schedule` after approval. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-14:** Scheduled promotion persists the same proposal snapshot and re-runs stale/conflict/dependency checks at execution time. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-15:** Do not recompute latest source state at execution time for protected targets. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-16:** Change-request and scheduled-execution metadata must link source env, target env, compare token, promoted flag set, and related governance ids. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Revert posture
- **D-17:** Revert means re-applying a prior environment configuration version as a new promotion, not mutating history. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-18:** Every successful promotion/apply produces an immutable environment-version artifact. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-19:** Re-apply-from-history uses the same compare/apply/governance flow as forward promotion. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-20:** `rollback_audit_event/1` is not the promotion revert model. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-21:** Environment-version artifacts must fingerprint dependency closure and preserve promotion linkage. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-22:** Product language should prefer “Re-apply version”. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Snapshot regeneration and propagation
- **D-23:** Apply success means authored target state committed and canonical target runtime snapshot generated. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-24:** Target snapshot regeneration is part of the authoritative apply transaction; snapshot failure rolls back authored mutation. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-25:** Distributed invalidation/runtime refresh happen after commit. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-26:** Notifier/PubSub failure after commit is degraded propagation, not a reason to undo committed authored changes. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-27:** Operator truth must distinguish authored apply status, snapshot version/timing, and runtime propagation state. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-28:** Do not imply cluster-wide freshness without evidence. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Recommendation-heavy posture
- **D-29:** Downstream planning should default to recommendation-first decisions. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **D-30:** Escalate only product-scope, public-contract, security-posture, or release-shape decisions. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROM-03 | Operator can promote whole-flag environment configuration from a source environment to a target environment while preserving authored intent rather than cloning runtime snapshots. [VERIFIED: `.planning/REQUIREMENTS.md`] | Build one first-class promotion bundle and apply command that reuses Phase 22 compare payload semantics, mutates authored target state in one bounded transaction, regenerates the target runtime snapshot inside that transaction, and emits an immutable environment-version artifact for later re-apply. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| PROM-04 | Promotions into protected environments flow through existing governance, audit, and approval surfaces instead of bypassing them. [VERIFIED: `.planning/REQUIREMENTS.md`] | Introduce promotion as a new governed action using existing change-request, approval, execution, and scheduling contracts; persist the exact promotion bundle in the governed snapshots and revalidate it at execution time instead of recomputing current source state. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`][VERIFIED: `rulestead/lib/rulestead/governance/scheduled_execution.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`] |
</phase_requirements>

## Summary

Phase 23 should be planned as one promotion domain action with two execution modes, not as separate direct-apply and governed-apply products. The repo already has the right substrate: Phase 22’s compare token and proposed-target payload, a store-command/facade architecture, existing governed mutation review routes, append-only audit enrichment, and transactional runtime snapshot generation. [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `rulestead/lib/rulestead.ex`][VERIFIED: `rulestead/lib/rulestead/store/command.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`]

The highest-risk failure mode is semantic drift between preview and apply. The promotion bundle therefore needs to be a durable, exact snapshot of reviewed intent: selected flag keys, dependency closure, compare token, source/target fingerprints, and normalized proposed target authored state. Direct apply can execute from that bundle immediately for lower-risk targets. Protected targets should store the same bundle in `command_snapshot` and later execute or schedule from that stored snapshot after re-running compare-token and dependency validation. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`][VERIFIED: `rulestead/lib/rulestead/governance/scheduled_execution.ex`]

The most pragmatic slice order is: first establish the backend promotion bundle/apply transaction and immutable environment-version history in `rulestead`, then wire protected-target governance/audit/re-apply semantics plus the minimal admin handoff surfaces in `rulestead_admin`. That keeps the first plan focused on correctness-critical domain behavior and the second plan focused on governance, audit truth, and operator workflow continuity. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `.planning/phases/23-governed-promotion-apply/23-PATTERNS.md`]

**Primary recommendation:** Plan Phase 23 as two slices:
1. backend promotion apply, compare-token revalidation, environment-version artifacts, and transactional snapshot regeneration;
2. first-class governed promotion action, protected-target review/execute/schedule routing, audit linkage, and re-apply-version operator path. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Promotion bundle construction and validation | API / Backend | Database / Storage | The exact reviewed contract must be deterministic and reusable across admin, CLI, and later import flows. [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`] |
| Authored target mutation + target snapshot regeneration | Database / Storage | API / Backend | The transactional boundary already lives in `Rulestead.Store.Ecto` via `Ecto.Multi`, and snapshot insertion is already coupled to authored writes there. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| Governed promotion snapshotting, approval, and scheduled execution | API / Backend | Database / Storage | Existing change-request and scheduled-execution models own exact command snapshots and later execution routing. [VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`][VERIFIED: `rulestead/lib/rulestead/governance/scheduled_execution.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| Audit linkage and operator-visible mutation history | API / Backend | Frontend Server (SSR) | Audit metadata normalization is centralized already and admin review routes consume that truth. [VERIFIED: `rulestead/lib/rulestead/audit_event.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`] |
| Compare review and handoff into governed routes | Frontend Server (SSR) | API / Backend | The mounted compare, change-request, and schedule LiveViews already implement explicit route-backed operator review. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex`] |

## Project Constraints (from planning state and repo instructions)

- Keep work inside the active Phase 23 boundary. [VERIFIED: `AGENTS.md`][VERIFIED: `.planning/ROADMAP.md`]
- Preserve the linked-version sibling-package monorepo shape. [VERIFIED: `AGENTS.md`][VERIFIED: `.planning/PROJECT.md`]
- Do not publish or turn `rulestead_admin` into a standalone orchestration product. [VERIFIED: `AGENTS.md`]
- Keep apply bounded and recommendation-heavy; avoid speculative Phase 24 GitOps or Phase 25 tenancy features. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `.planning/REQUIREMENTS.md`]

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Existing `Rulestead` facade + store command pattern | local code [VERIFIED: `rulestead/lib/rulestead.ex`][VERIFIED: `rulestead/lib/rulestead/store/command.ex`] | first-class promotion apply/public API | All current domain actions already flow through key-first commands and public facade verbs. |
| `Ecto.Multi` via `ecto_sql` | `3.13.5` [VERIFIED: `rulestead/mix.lock`] | transactional target mutation + snapshot regeneration + audit | Current publish/governance paths already use `Ecto.Multi` for authoritative mutation boundaries. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| Existing governance contracts | local code [VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`][VERIFIED: `rulestead/lib/rulestead/governance/scheduled_execution.ex`] | exact proposal review, approval, execution, and scheduling | Protected-target promotion should extend these exact seams rather than bypass them. |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Rulestead.Promotion.Compare` | local code [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`] | compare token, dependency closure, and proposed-target payload | Use as the canonical preview contract that promotion bundle generation must reuse. |
| `Rulestead.AuditEvent` | local code [VERIFIED: `rulestead/lib/rulestead/audit_event.ex`] | append-only audit metadata with governance/scheduling links | Use for promotion-specific source/target/token/version linkage rather than inventing a second audit shape. |
| `Rulestead.RuntimeSnapshot` + refresh/notifier path | local code [VERIFIED: `rulestead/lib/rulestead/runtime_snapshot.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`] | canonical runtime snapshot truth and degraded propagation posture | Use for target runtime regeneration and honest post-commit propagation status. |
| Mounted admin review routes | local code [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex`] | review/approve/execute/schedule screens | Extend these routes instead of creating a standalone promotion console. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One first-class promotion action | Reuse `publish_ruleset` and stuff promotion state into metadata | That would blur environment-level apply semantics and make review/audit harder to reason about. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`] |
| Persist exact promotion bundle snapshot | Recompute current source state at execution time | Violates reviewed-intent guarantees and breaks stale-preview protection. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`] |
| Environment-version artifact for revert | `rollback_audit_event/1` inverse writes | Existing rollback is event-local operational repair, not safe environment-level restore. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead.ex`] |
| Reuse existing admin compare/change-request/schedule routes | New promotion console | Conflicts with the mounted, calm admin IA and expands scope into a release product. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`] |

**Installation:** No new dependency is required for Phase 23. Reuse the existing `rulestead` and `rulestead_admin` stack. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
compare summary selection
  -> canonical compare payload + compare token from Phase 22
  -> build promotion bundle:
       source_env
       target_env
       selected flag_keys
       dependency_closure_keys
       compare token/schema version
       source + target fingerprints
       proposed target authored state
  -> lower-risk target:
       validate bundle against current compare truth
       apply authored changes in one Ecto.Multi
       insert immutable environment-version artifact
       regenerate target runtime snapshot in same transaction
       commit
       post-commit invalidation / refresh propagation
  -> protected target:
       submit first-class governed promotion action
       store exact bundle in change_request.command_snapshot
       approve
       execute now or schedule
       revalidate bundle at execution time
       run same apply transaction
       link audit + scheduled execution + version artifact
  -> later revert:
       select prior environment version
       compare historical version -> current target
       re-apply version through same direct/governed flow
```

### Recommended Project Structure

```text
rulestead/
├── lib/rulestead.ex
├── lib/rulestead/store.ex
├── lib/rulestead/store/command.ex
├── lib/rulestead/store/ecto.ex
├── lib/rulestead/fake.ex
├── lib/rulestead/promotion/compare.ex
├── lib/rulestead/promotion/...
├── lib/rulestead/governance/change_request.ex
├── lib/rulestead/governance/scheduled_execution.ex
├── lib/rulestead/audit_event.ex
└── test/rulestead/...

rulestead_admin/
├── lib/rulestead_admin/live/environment_compare_live/index.ex
├── lib/rulestead_admin/live/environment_compare_live/show.ex
├── lib/rulestead_admin/live/change_request_live/show.ex
├── lib/rulestead_admin/live/schedule_live/show.ex
└── test/rulestead_admin/live/...
```

### Pattern 1: Promotion Bundle as the Canonical Apply Contract

**What:** Construct one normalized promotion bundle from the compare payload and use it for both direct and governed apply. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`]

**When to use:** Every apply path, including immediate lower-risk promotion, protected-target change requests, scheduled execution, and later re-apply-version. [VERIFIED: `.planning/REQUIREMENTS.md`]

**Example direction:**

```elixir
%{
  source_environment_key: "staging",
  target_environment_key: "prod",
  flag_keys: ["checkout-redesign"],
  compare_token: "cmp_...",
  compare_schema_version: 1,
  source_fingerprint: "...",
  target_fingerprint: "...",
  dependency_closure_keys: ["audience:vip-buyers"],
  proposed_target_state: [...]
}
```

### Pattern 2: Governed Execution from Stored Snapshot, Not Recomputed Source

**What:** Persist the exact bundle in `command_snapshot` and later reconstruct execution from that snapshot, just as current governance and scheduling flows do for existing actions. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`]

**When to use:** Protected-target promotions that require approval or scheduling. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Pattern 3: One Transaction for Authored Mutation + Target Snapshot Regeneration

**What:** Reuse the current publish-style `Ecto.Multi` pattern so promotion either commits authored target state and its new snapshot together or fails wholly. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`]

**When to use:** Any successful direct or governed promotion apply. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

### Pattern 4: Re-apply Version as Forward Promotion from Immutable History

**What:** Treat revert as a new promotion whose source side is an immutable historical environment-version artifact. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]

**When to use:** Minimal operator rollback/recovery posture in Phase 23. [VERIFIED: `.planning/ROADMAP.md`]

## Risks and Planning Implications

- **Preview/apply drift:** Plans must enforce compare-token and dependency revalidation immediately before any mutation. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`]
- **Governance shape drift:** Plans must add promotion as a first-class governed action instead of overloading `publish_ruleset`. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`]
- **Runtime-truth confusion:** Plans must distinguish environment-version history artifacts from runtime snapshots; both matter, but for different truths. [VERIFIED: `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/runtime_snapshot.ex`]
- **Scope creep into GitOps or tenancy:** Plans must stop at admin + core apply/governance/revert seams and avoid CLI/import/export or tenant-aware validation. [VERIFIED: `.planning/REQUIREMENTS.md`]
- **Admin-product sprawl:** Plans must extend mounted compare/change-request/schedule routes rather than inventing a standalone orchestration hub. [VERIFIED: `AGENTS.md`][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`]

## Recommended Slice Boundary

### Slice 1
- promotion bundle contract
- direct apply command/facade
- Ecto/Fake apply implementation
- compare-token revalidation
- immutable environment-version artifact
- transactional target snapshot regeneration
- backend contract tests

### Slice 2
- first-class governed promotion action
- change-request/scheduled-execution integration
- promotion-specific audit metadata and route handoff
- protected-target admin review/submit/execute/schedule flow
- re-apply-version operator path
- governance/admin regression tests

---
*Phase 23 research completed: 2026-05-18*
