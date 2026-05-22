# Rulestead v0.6.0 Product Shape Research

**Date:** 2026-05-18  
**Scope:** Operator-facing shape for multi-environment sync, promotion, GitOps import/export, and tenancy helpers  
**Overall confidence:** MEDIUM-HIGH

## Executive Take

The least surprising operator model for `rulestead_admin` is the same core shape used by the strongest flag platforms: one canonical flag object, environment-specific configuration on that object, explicit compare/apply promotion between environments, and protected-environment approvals layered on top. Unleash is the clearest expression of this model. LaunchDarkly reinforces it with compare/copy plus optimistic locking. GrowthBook reinforces the value of draft revisions, conflict handling, and explicit publish flows.

Rulestead should not make Git the primary authoring UX in `v0.6.0`. GitOps should be a deterministic import/export seam around the mounted admin, not a replacement for it. Operators want reviewable manifests, CI validation, and reproducible promotion. They do not want the admin UI to feel secondary, nor do they want two opaque sources of truth fighting each other.

Rulestead should also not build a full release-orchestration product in `v0.6.0`. LaunchDarkly and Flagsmith both show where that road leads: pipelines, guarded rollout automation, stage triggers, environment policies, approval routing, and workflow engines. That is real product surface, but it is too large and too surprising for this milestone. The correct milestone shape is compare, preview, promote, validate, export, import, audit.

## Ecosystem Findings

### LaunchDarkly

- Strong pattern: compare/copy between environments with a dedicated diff screen and approval handoff.
- Important operator expectation: promotion is from a source environment into a target environment, with an explicit preview of differences before apply.
- Important implementation detail: LaunchDarkly's copy API supports `currentVersion` checks to reject stale copy attempts and enforce optimistic locking.
- Important footgun surfaced by their docs: contexts and segments are environment-specific; same names do not mean same object.
- Important constraint: release pipelines are powerful, but they are workflow-heavy and their automated releases are limited to boolean flags.

Implication for Rulestead:
- Copy/promotion should be version-checked.
- Promotions must validate referenced audiences/tenants/dependencies in the target.
- Do not chase release-pipeline parity in this milestone.

### Unleash

- Best operator mental model for `v0.6.0`.
- Unleash explicitly argues for a unified flag model instead of per-environment duplicated flags.
- Environment config lives on one shared flag identity, which reduces drift and makes audit/history easier to reason about.
- Import/export is environment-aware, validates references, and can create a draft change request instead of applying immediately when protected environments require it.
- Clear tradeoff: import/export is strong for migration and CI, but still depends on prerequisite objects existing in the target.

Implication for Rulestead:
- Adopt unified flag identity plus environment overlays.
- Treat import as a validated apply path, not a blind overwrite.
- Reuse the existing governance model so protected imports land as reviewable change requests.

### GrowthBook

- Best evidence for draft-and-publish operator UX.
- Automatic draft revisions, explicit publish, revision compare, revert, and merge-conflict handling all reduce surprise in collaborative admin editing.
- Approval flows operate against draft changes, not as an unrelated workflow object.
- Environment inheritance exists, but it is a fork/snapshot model, not ongoing sync.

Implication for Rulestead:
- Promotion work should borrow the revision/diff mindset, even if full revision branching is deferred.
- "Draft promotion bundle" is a better operator concept than "run sync now."
- Environment inheritance is useful for later environment creation, but it is not a substitute for promotion.

### Flagsmith

- Strong evidence that platforms converge on approvals, versioning, Terraform/Git-style integration, and now release pipelines.
- Current docs show Release Pipelines in closed beta, plus change requests and feature versioning per environment.
- Terraform support confirms demand for IaC-style management, but that does not imply Terraform should become the primary operator UX.

Implication for Rulestead:
- GitOps and IaC compatibility are table stakes for serious operators.
- Pipeline automation is still maturing even in adjacent products; good signal to defer it.

### OpenFeature / flagd adjacent ecosystem

- OpenFeature's provider model and domain-scoped / multi-provider support matter for ecosystem fit, but not for operator UX directly.
- `flagd` is a useful adjacent signal for GitOps shape: file, HTTP, object storage, Kubernetes CRD, and mergeable flag sources are first-class sync inputs.
- The strongest lesson is not "become `flagd`." It is "a manifest/file-based source is a valid operator seam when deterministic and explicit."

Implication for Rulestead:
- Export/import manifests should be stable, machine-friendly, and composable with CI.
- Avoid multi-source merge logic in `v0.6.0`; it creates precedence complexity fast.

## Candidate Promotion Models

### Model A: Unified Flag + Environment Overlay + Compare/Apply

**Shape**

- A flag exists once.
- Each environment has its own mutable config for that flag.
- Operators compare source and target environments, review diffs, and apply selected flag configs to the target.

**Pros**

- Lowest-surprise model for experienced operators.
- Preserves one flag identity across dev, staging, and prod.
- Makes audit, explainability, and lifecycle tracking coherent.
- Fits mounted admin UX well.
- Compatible with existing governance and change-request flows.

**Cons**

- Needs careful diff modeling for references, prerequisites, and rollout state.
- Requires clear handling when target dependencies do not exist.

**Footguns**

- Treating same-named audiences or tenant artifacts as equivalent without stable keys.
- Copying operational state instead of desired config.
- Allowing blind overwrite without version checks.

**Ruling**

- Recommended primary model.

### Model B: Draft Revision Promotion Bundles

**Shape**

- A promotion creates a draft bundle of proposed target-environment changes.
- Operators review the bundle diff, resolve conflicts, then publish it.

**Pros**

- Strong collaboration story.
- Matches GrowthBook's calmer publish/review model.
- Good fit for protected environments and audit trails.

**Cons**

- Adds workflow state and conflict-resolution complexity.
- More implementation weight than pure compare/apply.

**Footguns**

- Letting draft semantics spread into all environments when only protected ones need the extra ceremony.

**Ruling**

- Use as the protected-environment wrapper around Model A, not as the base model everywhere.

### Model C: Automated Release Pipelines / Stage Engine

**Shape**

- Flags move automatically through stages with timers, approvals, rollout actions, and audience changes.

**Pros**

- Powerful for large teams and standardized releases.
- Can encode org-wide rollout policy.

**Cons**

- Big workflow engine.
- Hard to keep calm and unsurprising.
- High implementation cost across UI, scheduling, rollback, status, and audit semantics.
- Adjacent platforms still limit or beta-gate parts of this surface.

**Footguns**

- Conflating promotion with rollout orchestration.
- Copying rollout progress between environments.
- Surprising automatic changes in prod.

**Ruling**

- Reject for `v0.6.0`.

### Model D: Git-First / Declarative Reconciler

**Shape**

- Git manifests are the primary source of truth.
- UI becomes mostly a viewer or emergency override tool.

**Pros**

- Excellent CI reproducibility.
- Natural fit for infrastructure-heavy teams.

**Cons**

- Fights the mounted-admin value proposition.
- Creates dual-truth risk unless the UI is heavily constrained.
- Raises scope into reconciliation, drift status, merge policy, and conflict arbitration.

**Footguns**

- UI edits silently drifting from Git.
- Git apply bypassing governance expectations.
- Overly verbose manifests with unstable IDs.

**Ruling**

- Reject as the primary model.
- Keep as import/export seam only.

### Model E: Environment Clone / Inheritance

**Shape**

- New environments copy from a parent and then diverge independently.

**Pros**

- Useful for bootstrapping new or temporary environments.

**Cons**

- Not ongoing promotion.
- Encourages forked config if overused.

**Footguns**

- Teams assuming inheritance means live sync.

**Ruling**

- Nice future helper; not the core answer to promotion.

## Recommendation

### Recommended Core Model

Rulestead `v0.6.0` should ship **Unified Flag + Environment Overlay + Compare/Apply**, with **drafted promotion bundles only for protected environments**, and **manifest import/export as a separate deterministic seam**.

That means:

1. Operators edit environment config on the canonical flag.
2. Promotions are explicit source -> target compare/apply actions.
3. Protected targets convert the proposed apply into a governed change request or draft publish step.
4. GitOps uses exported manifests and validated imports, but the mounted admin remains first-class.

This is coherent with:

- mounted admin, not standalone `rulestead_admin`
- host-owned auth and layout
- existing governance and audit model
- deterministic evaluator
- linked-version monorepo release shape

## Operator UX Recommendation

### Primary workflow

1. Operator opens a source environment and chooses `Promote to...`.
2. UI shows a target environment picker.
3. UI computes a structured diff for selected flags.
4. Operator reviews flag-by-flag changes.
5. UI validates missing dependencies before apply.
6. Operator applies immediately in lower-risk envs or creates a governed promotion request for protected envs.
7. Result is audited as a promotion event with source env, target env, selected flags, manifest/version hash, actor, and reason.

### Diff UX shape

Use a **flag-centric diff list** first, not a raw JSON diff first.

Each row should show:

- flag key
- status: same / changed / only in source / only in target / blocked
- change summary: enabled state, default value, targeting rules, prerequisites, rollout config, kill switch state
- dependency warnings

The detail view should then show a structured side-by-side diff, with an optional raw manifest diff for CI-minded operators.

### Promotion granularity

For `v0.6.0`, promote at **whole flag environment-config granularity**.

Do:

- promote selected flags
- promote all changed flags in a filtered result set

Do not do yet:

- per-rule cherry-pick copy
- per-field selective promotion across many config subtypes

Reason:

- partial-copy UX is flexible but footgun-heavy.
- whole-flag promotion is much easier to explain, validate, audit, and reverse.

### Version safety

Every promotion/import apply should include an **expected target version** or equivalent environment config fingerprint.

If target changed since diff generation:

- reject apply
- re-run diff
- keep operator trust intact

This is a direct lesson from LaunchDarkly's copy API optimism checks and from GrowthBook's merge-conflict handling.

## GitOps Recommendation

### What GitOps should be in v0.6.0

- deterministic export of environment or selected flags to manifest
- dry-run import with validation
- import preview with structured diff
- CI-friendly non-interactive validation/apply entrypoints
- imports into protected environments create governed draft changes instead of mutating live immediately

### What GitOps should not be in v0.6.0

- continuous bi-directional reconciliation
- Git as exclusive source of truth
- automatic drift remediation
- multi-source merge precedence
- Kubernetes-operator-style controller inside the product

### Manifest shape recommendation

Use a manifest that is:

- environment-scoped
- key-based, not database-ID-based
- deterministically ordered
- explicit about schema version
- explicit about dependencies and referenced audiences
- easy to diff in Git

Recommended top-level sections:

- `schema_version`
- `project` or `namespace` if needed for host scoping
- `environment`
- `audiences`
- `flags`
- `tenancy` helpers or references if present
- `exported_at`
- `exported_from_version`

The export should represent **desired config**, not ephemeral runtime state.

Do not export:

- current rollout progress counters
- transient diagnostics
- ad hoc simulation results

## Tenancy Helpers Recommendation

`v0.6.0` should add tenancy helpers that make environment sync safer, without turning Rulestead into a tenant-management product.

Recommended helpers:

- explicit tenant-aware targeting helpers in rule authoring
- tenant key validation in import/export and promotion
- tenant-scoped audience references
- stable bucketing helper guidance for tenant-level rollouts where needed
- diff filters by tenant-scoped rules or tenant-scoped audiences

Do not do yet:

- per-tenant isolated admin workspaces
- tenant-specific auth domains inside `rulestead_admin`
- full tenant lifecycle CRUD product surface
- cross-tenant bulk override management UI

The tenancy goal for this milestone is **safer targeting and safer promotion**, not a standalone multi-tenant control plane.

## Table Stakes vs Differentiators

### Table stakes for v0.6.0

- One canonical flag with per-environment config
- Source/target environment comparison
- Promotion preview before apply
- Protected-environment approval path
- Deterministic export
- Dry-run import validation
- Dependency validation for audiences / prerequisites / tenant references
- Revertable audit trail for promotions and imports

### Good differentiators for Rulestead

- Calm, mounted Phoenix admin that fits host auth and layout instead of pretending to be a separate SaaS
- Structured promotion previews that speak in domain terms, not only JSON blobs
- Import/export that integrates directly with existing governance and audit semantics
- Deterministic evaluator-backed impact previews for promoted changes
- Tenant-aware promotion safety without overbuilding tenant administration

## Biggest Footguns

1. **Separate flag per environment**
   This creates drift, muddles audit, and breaks lifecycle hygiene.

2. **Blind copy without target-version checks**
   Operators lose trust fast when a promotion silently overwrites someone else's newer change.

3. **Copying references by display name**
   Audiences, prerequisites, or tenant artifacts need stable identifiers and validation.

4. **Promoting live rollout state instead of declarative config**
   Progress counters and runtime state should not be treated as promotion payload.

5. **Making Git and UI peers without explicit drift rules**
   Dual truth is worse than either model alone.

6. **Over-granular partial copy in the first release**
   Per-rule cherry-picking looks powerful and creates incoherent target configs.

7. **Turning promotion into a workflow engine**
   `v0.6.0` is not the moment to build release automation, stage timers, and auto-advancing pipelines.

8. **Broadening `rulestead_admin` into a standalone console**
   This conflicts directly with the product's mounted-admin design.

## Deliberate Non-Goals

- No standalone `rulestead_admin` product posture
- No full release pipeline engine
- No environment inheritance/live-sync model
- No automatic Git reconciliation loop
- No cross-instance federation as first-class product workflow
- No per-rule cherry-pick promotion UI
- No RBAC expansion beyond current milestone boundaries

## Cohesive v0.6.0 Scope Recommendation

1. **Environment compare/apply view**
   A mounted admin screen for source -> target diffing across selected flags.

2. **Promotion request object**
   A first-class audited object that records source, target, selection, diff fingerprint, actor, and reason.

3. **Protected-environment promotion gate**
   Promotion to sensitive environments routes through the existing governance flow instead of immediate mutation.

4. **Deterministic export**
   Export selected flags or full environment config to stable JSON or YAML for Git review and CI.

5. **Dry-run import**
   Import validates dependencies and renders a promotion-style diff before any apply.

6. **Conflict detection**
   Apply/import fails cleanly if target changed after preview generation.

7. **Tenant-aware validation helpers**
   Promotions and imports validate tenant-scoped references and surface blockers clearly.

8. **Minimal revert path**
   Operators can revert a promotion by re-applying the previous environment config version.

## Source Notes

### High-confidence primary sources

- LaunchDarkly compare/copy docs: https://launchdarkly.com/docs/home/flags/compare-copy
- LaunchDarkly copy API docs: https://launchdarkly.com/docs/api/feature-flags/copy-feature-flag
- LaunchDarkly approvals docs: https://launchdarkly.com/docs/home/releases/approvals
- LaunchDarkly release pipelines docs: https://launchdarkly.com/docs/home/releases/release-pipelines
- Unleash environments docs: https://docs.getunleash.io/concepts/environments
- Unleash import/export docs: https://docs.getunleash.io/concepts/import-export
- Unleash change requests docs: https://docs.getunleash.io/concepts/change-requests
- Unleash environment/project organization guide: https://docs.getunleash.io/guides/organize-feature-flags
- GrowthBook environments docs: https://raw.githubusercontent.com/growthbook/growthbook/main/docs/docs/features/environments.mdx
- GrowthBook publishing and approval flows docs: https://raw.githubusercontent.com/growthbook/growthbook/main/docs/docs/features/publishing-and-approval-flows.mdx
- GrowthBook safe rollouts docs: https://raw.githubusercontent.com/growthbook/growthbook/main/docs/docs/features/safe-rollouts.mdx
- Flagsmith change requests docs: https://raw.githubusercontent.com/Flagsmith/flagsmith-docs/main/docs/advanced-use/change-requests.md
- Flagsmith Terraform docs: https://raw.githubusercontent.com/Flagsmith/flagsmith-docs/main/docs/integrations/terraform.md
- Flagsmith current docs pages for release pipelines / import-export / feature versioning:
  - https://docs.flagsmith.com/managing-flags/release-pipeline
  - https://docs.flagsmith.com/administration-and-security/data-management/import-and-export
  - https://docs.flagsmith.com/managing-flags/feature-versioning
- OpenFeature provider concepts: https://openfeature.dev/docs/reference/concepts/provider/
- flagd sync concepts: https://flagd.dev/concepts/syncs/

### Confidence notes

- **HIGH:** unified flag + per-environment config, compare/apply promotion, approval gates, dry-run import validation, manifest export as operator expectation
- **MEDIUM:** exact best initial promotion granularity for Rulestead; recommendation is opinionated toward whole-flag environment config because it minimizes surprise and implementation risk
- **MEDIUM:** Flagsmith release-pipeline details are current but beta-stage, so they are better as direction signals than as parity targets
