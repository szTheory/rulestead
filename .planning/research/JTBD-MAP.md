# JTBD Map: Rulestead Post-GA

**Last reviewed:** 2026-05-21
**Purpose:** Maintain one current map of what user flows Rulestead already
supports, what serious gaps remain, and where further JTBD research stops being
worth the time.

## Current Shipped JTBD Map

Rulestead already covers a surprisingly broad feature-management loop for
Phoenix teams:

- **Build safely:** gate booleans, variants, and typed config with explicit
  context and deterministic evaluation.
- **Release safely:** author changes through the mounted admin, use staged
  rollouts, approvals, scheduling, protected-environment controls, and audit.
- **Explain safely:** inspect one actor's decision path and connect it to the
  authored ruleset and audit trail.
- **Operate safely:** use kill switch, diagnostics, webhook visibility, Redis
  caching, PubSub invalidation, and environment-aware controls.
- **Integrate safely:** use OpenFeature, demo stack proof, fake-backed tests,
  and documented host seams.

The product already feels like more than "flag evaluation plus an admin page."
It is now a release-control and decision-explanation system for Elixir/Phoenix
teams.

## Role-By-Role Flow Inventory

### Builder / App Developer

**Well covered now**

- runtime evaluation for booleans, variants, and config payloads
- explicit context construction and propagation
- test helpers and fake-backed workflows
- LiveView, Plug, and Oban seams
- migration path for FunWithFlags users

**Still weak or incomplete**

- flag ownership and lifecycle cleanup loops are documented but not yet a full
  first-class user-flow system
- tenancy-aware builder flow remains a pending post-GA completion area

### Tech Lead / Release Owner

**Well covered now**

- governed production mutations
- change requests and approval posture
- scheduled execution
- environment compare and governed promotion
- GitOps import/export/diff plan flow
- RBAC and audit posture

**Still weak or incomplete**

- no metric-driven guarded rollout or automatic rollback loop
- no stronger top-level flow for "which release strategy should I choose?"
- lifecycle debt management is present but not yet as visible or opinionated as
  leading platforms

### Operator / PM

**Well covered now**

- mounted flag list/detail/edit flows
- rollout, kill switch, audit, schedule, webhook, and diagnostics surfaces
- environment-aware URLs and host-owned authorization

**Still weak or incomplete**

- no explicit ownership-heavy workbench for team, maintainer, or stale-state
  triage
- no reusable segment/template system for scaling repeated targeting patterns

### Support / Success

**Well covered now**

- explainability is clearly part of the product promise
- audit and timeline support the "what changed?" story

**Still weak or incomplete**

- decision-lookup and support handoff are strong conceptually, but future docs
  and UX could make this a more prominent front-door flow

### SRE / On-call

**Well covered now**

- kill switch
- diagnostics and infrastructure health
- runtime telemetry and invalidation/cache posture
- audit evidence and demo proof

**Still weak or incomplete**

- no metric-linked progressive rollback or guarded release loop
- no broader "fleet health" or org-scale operational control surface, which may
  be acceptable for the current product shape

### Contributor / Platform Extender

**Well covered now**

- public/private API boundary
- store seam
- OpenFeature proof
- mounted-admin contract boundary

**Still weak or incomplete**

- the extension story is technically sound, but future capability expansion
  should stay disciplined to avoid exposing internal modules as product surface

## Gap Matrix Vs Mature Platforms

This comparison uses official docs from LaunchDarkly, Unleash, GrowthBook,
ConfigCat, and Flagsmith as the external expectation baseline reviewed on
2026-05-21.

### Immediate Product Fit

These gaps fit the existing architecture and materially improve the shipped user
flows.

#### 1. Tenancy flow completion

- **Why it matters:** Multi-tenant SaaS builders expect explicit tenant scope
  to carry through runtime, admin, and promotion flows.
- **Current state:** Phase 25 research is already prepared and tightly scoped.
- **Why it fits:** Extends explicit context and validation seams already in the
  product.
- **Priority:** Highest near-term candidate.

#### 2. Lifecycle hygiene as a first-class flow

- **Why it matters:** Mature platforms make stale flags, expected lifetimes,
  cleanup, and ownership visible. Unleash is especially strong here.
- **Current state:** Rulestead has pieces of lifecycle hygiene, but the
  end-to-end user flow is not yet prominent enough.
- **Why it fits:** Builds on existing code references, audit posture, and admin
  surfaces without changing the core package shape.
- **Priority:** High.

#### 3. Ownership and accountability metadata

- **Why it matters:** Teams eventually ask "who owns this flag?" before they ask
  for more rule power.
- **Current state:** Present in language and intent, not yet a fully shaped
  flow.
- **Why it fits:** Reinforces cleanup, audit, and operator workflows.
- **Priority:** High, likely bundled with lifecycle work.

### High-Value But Later

These are valuable, but not the best immediate post-GA move.

#### 4. Metric-driven guarded rollouts

- **Why it matters:** LaunchDarkly treats monitored progressive rollout as a
  serious safety workflow. This is one of the clearest "advanced maturity"
  expectations.
- **Current state:** Rulestead supports rollout and telemetry, but not
  automatic metric-based rollback decisions.
- **Why later:** This is a bigger product jump because it needs metric inputs,
  thresholds, automated reactions, and strong operator UX.
- **Priority:** Medium-high after tenancy and lifecycle.

#### 5. Reusable segments / targeting templates

- **Why it matters:** Unleash and similar systems reduce rule duplication with
  reusable segments and templates.
- **Current state:** Rulestead supports rich targeting, but reuse appears more
  authored-per-flag than centrally managed.
- **Why later:** Useful once flag volume rises; less urgent than lifecycle and
  tenancy for the current product.
- **Priority:** Medium.

#### 6. Deeper experimentation program flows

- **Why it matters:** GrowthBook makes experimentation feel like a full program,
  not just variants plus exposures.
- **Current state:** Rulestead has experimentation core and analytics
  foundations, but not the same maturity of decision support and program
  guidance.
- **Why later:** Valuable, but only if the product wants to compete more
  directly on experimentation rather than release control.
- **Priority:** Medium.

### Larger-Team / Enterprise Depth

These are real asks in the market, but not necessarily the right next moves for
Rulestead.

#### 7. Projects, portfolios, or org-scale partitions

- **Why it matters:** Larger vendors use projects/workspaces to separate teams,
  products, or security domains.
- **Current state:** Rulestead is environment-centric and sibling-package
  oriented.
- **Why caution:** This could widen the product from embedded library to
  platform administration suite.
- **Priority:** Low-medium.

#### 8. Universal holdouts and richer experiment governance

- **Why it matters:** GrowthBook-style program maturity eventually brings
  holdouts and experimentation governance questions.
- **Current state:** Not needed to satisfy the current core promise.
- **Why caution:** High complexity and narrower audience.
- **Priority:** Low.

### Not Worth Building Unless Product Direction Changes

These likely push Rulestead away from its strongest shape.

#### 9. Standalone control-plane drift

- **Why avoid it:** Conflicts directly with the mounted sibling-package design.

#### 10. Arbitrarily granular platform-style RBAC

- **Why avoid it:** The current Viewer/Editor/Admin posture is a deliberate
  simplification that fits embedded host ownership better.

#### 11. Overbuilt org administration features

- **Why avoid it:** Billing, global org policy planes, and giant admin-taxonomy
  features are not natural next steps for a Phoenix-mounted library.

## Ranked Milestone Opportunities

### 1. Tenancy Helpers And Validation

**Reason:** Highest pain relief for real SaaS adopters, already researched,
architecturally aligned, and strongly bounded.

### 2. Lifecycle Hygiene And Ownership

**Reason:** This is the clearest everyday JTBD gap once GA-level release control
exists. It directly helps builders, leads, and operators reduce flag debt.

Recommended flow targets:

- owner metadata and team/accountability cues
- stale and expected-lifetime workflows
- cleanup/archive guidance surfaced as an operator flow
- docs and admin polish around "flag from birth to retirement"

### 3. Guarded Rollout Foundations

**Reason:** High-value differentiator once the basics above are in place.

Recommended flow targets:

- attach monitored signals to rollout steps
- stop or roll back on explicit thresholds
- preserve auditability and preview posture

### 4. Reusable Targeting Assets

**Reason:** Useful after teams accumulate enough rules to feel duplication pain.

Recommended flow targets:

- reusable audience/segment definitions
- safer reuse across flags and environments
- clear dependency and preview behavior

### 5. Experimentation Maturity Pass

**Reason:** Best treated as a later "go deeper" choice, not the immediate
default path.

## Diminishing Returns Boundary

Further JTBD research is no longer high leverage once these conditions are met:

1. The shipped flows are mapped clearly for builder, lead, operator, support,
   and SRE personas.
2. The top 3 to 5 gap areas are ranked with evidence from both repo truth and
   mature-product expectations.
3. Each candidate is classified as core fit, later fit, enterprise depth, or
   misfit.
4. The next milestone ordering can be explained without reopening first
   principles every time.

At that point, more research mostly adds vocabulary and edge cases rather than
changing roadmap decisions.

For Rulestead, that line is effectively reached after:

- tenancy
- lifecycle/ownership
- guarded rollout feasibility
- reusable targeting asset assessment
- experimentation-depth assessment

After those are understood, additional effort should shift from broad JTBD
research to targeted milestone definition and implementation.

## Recommended Research Posture Going Forward

- Use this document as the planning delta surface.
- Revisit external product docs only when a candidate milestone touches a new
  problem category.
- Prefer "what specific flow is still broken or missing?" over "what features do
  big vendors have?"
- Update the public JTBD guide only when shipped product flows materially change.

## Delta Since Last Review

Initial version created after `v1.0.0` shipped on 2026-05-21.

Current conclusion:

- Rulestead already covers the core release-control chain well.
- The biggest immediate JTBD gap is tenancy completion for real SaaS adopters.
- The biggest broad post-GA product gap is lifecycle ownership and cleanup.
- The most tempting but still later-stage gap is guarded rollouts with
  automatic rollback.
