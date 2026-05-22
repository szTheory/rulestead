# Rulestead v0.6.0 Pitfalls Research

**Scope:** Multi-environment sync, promotion, drift detection, GitOps import/export, and tenancy helpers
**Project:** Rulestead
**Researched:** 2026-05-18
**Overall confidence:** MEDIUM-HIGH

## Executive Stance

The biggest v0.6.0 mistake would be treating environment sync, GitOps, and tenancy as three separate features. In every mature platform, the hard problems are the seams between them: who is allowed to write state, what exactly is being promoted, which dependencies must come along for the ride, what counts as drift, and whether tenant targeting is modeled as data or as topology.

The strongest cross-ecosystem lesson is that successful products reduce ambiguity before they add automation. LaunchDarkly, Unleash, and the GitOps ecosystem all put guardrails around promotion, version checks, approvals, and drift semantics. The failures come from optimistic UI affordances that imply "copy environment" or "sync from Git" is simple when the real state graph includes segments/audiences, variants, schedules, approvals, tokens, and runtime caches.

For Rulestead, v0.6.0 should not try to be a universal bi-directional control plane. It should ship a narrow, opinionated system:

1. Promotion is a reviewed, version-checked apply of an immutable environment bundle.
2. GitOps is import/export around that same bundle shape, not a second hidden data model.
3. Tenancy is an evaluation concern with explicit helpers and carefully bounded override seams, not a license to clone every flag per tenant.

That yields a coherent positive plan: deterministic bundles, previewable diffs, optimistic-concurrency applies, dependency-aware imports, and a tenancy model that keeps one logical flag definition while allowing scoped overrides where they are truly needed.

## What Successful Platforms Got Right

### 1. They separate shared identity from environment-specific behavior

- LaunchDarkly keeps the same flag identity across all environments in a project, while allowing environment-specific targeting and state. This is the right mental model for promotion because it makes "same flag, different config" explicit instead of requiring cross-environment key mapping.
- Unleash similarly treats flags as project-level resources with environment-specific activation strategies.

**Rulestead implication:** keep flag identity stable across environments. Promote rulesets and environment overlays, not cloned flag records with environment-specific keys.

### 2. They make approvals and safeguards environment-aware

- LaunchDarkly has critical-environment safeguards and environment-level approvals.
- Unleash has environment-level and project-level change requests, explicit approval counts, and documented scheduled-change conflict states.

**Rulestead implication:** production-grade promotion cannot just be "copy now." It needs preview, confirm, audit, and environment-specific guardrails.

### 3. They are explicit about import/export limits

- Unleash docs are unusually honest: segments and custom strategies are not fully included in export; release plans must be recreated; imports stop if references do not exist.
- That honesty is a feature. It prevents operators from assuming a "backup" or "promotion" file is complete when it is not.

**Rulestead implication:** if an export omits anything, the export must say so in-machine and in-UI. Silent partial exports are unacceptable.

### 4. The better GitOps-style systems test config as code, not just data shape

- Featurevisor treats feature configuration as declarative files, but pairs that with test specs, generated state files, and a revision file to preserve consistent bucketing.
- This is the strongest Git-native lesson outside the UI-first vendors: versioned config without config tests is not a safe operating model.

**Rulestead implication:** manifests need schema validation and behavioral validation. Dry-run diff alone is not enough; promotion should support simulation and assertions.

### 5. They treat drift and reconcile behavior as first-class semantics

- Argo CD documents self-heal, pruning, allow-empty, and ignore-differences semantics explicitly.
- Flux documents prune, wait, depends-on, suspend, and how reconciliation reverts out-of-band edits.

**Rulestead implication:** "drift detection" must answer: drift from what source of truth, on what fields, with what allowed exceptions, and what action follows detection.

### 6. They acknowledge degraded-state serving and cache reality

- LaunchDarkly documents entitlement risk when fallbacks are stale or generic.
- GO Feature Flag documents persistent last-known-good config, startup failure behavior, polling intervals, and jitter to avoid herd effects.

**Rulestead implication:** promotion and sync work is incomplete unless the runtime story covers last-known-good snapshot behavior, stale detection, and reconciliation jitter.

## Top 10 Footguns

1. **Two writers, no authority model**
   - UI edits and Git imports both acting as source-of-truth will create flapping drift and operator confusion.

2. **Promotion without dependency closure**
   - Copying a ruleset without its referenced audiences, variants, salts, or schema assumptions creates broken or subtly different behavior.

3. **Name-based matching across environments**
   - Same-named audiences or tenant labels are not safe identity. LaunchDarkly explicitly treats environment-specific targeting entities as distinct.

4. **No optimistic concurrency on apply**
   - If a promotion applies against a stale base version, you get last-write-wins clobbering disguised as success.

5. **Scheduled changes colliding with later edits**
   - Unleash documents this directly: later updates can suspend or invalidate scheduled changes. Scheduling is not "fire and forget."

6. **Treating export as backup when it is partial**
   - If import/export omits referenced entities or runtime-only data, recovery and promotion will be unreliable.

7. **Using environments as tenants**
   - This explodes environment count, token count, and operator surface area, and breaks the Dev/Staging/Prod mental model.

8. **Per-tenant flag cloning as the default tenancy model**
   - It looks easy early and becomes unmanageable once tenants need inheritance, defaults, and bulk change review.

9. **Ambiguous override precedence**
   - If global, environment, tenant, audience, actor, and emergency overrides do not have one canonical order, operators will not trust explanations.

10. **Changing rollout bucketing inputs during promotion**
   - If salts, targeting keys, or variant allocation state change, "promoting the same rule" can silently reshuffle users.

## Common Mistakes Around Promotion, Drift, Import/Export, and Tenancy

### Promotion mistakes

#### Mistake: Promoting row state instead of a coherent bundle

Teams often think in terms of "copy these fields from staging to prod." The actual unit that must move is usually:

- flag metadata relevant to evaluation
- active ruleset version
- variant definitions
- audience references
- rollout salt / bucketing parameters
- environment-scoped defaults
- kill-switch state or explicit exclusion of kill-switch state
- provenance metadata: source env, source version, exported at, schema version

**Recommendation:** define a single `environment_manifest` or `promotion_bundle` schema and make every promotion/import/export path use it.

#### Mistake: Promoting emergency state unintentionally

Kill switches, hold states, or temporary overrides can be correct in staging and disastrous in production.

**Recommendation:** default to excluding emergency/runtime state from promotion unless explicitly included with a loud warning.

#### Mistake: Assuming "same key" means "same semantics"

A flag key may be shared across environments while the referenced audience definitions, default values, or variant payload shapes have drifted.

**Recommendation:** diff referenced entities transitively, not just the top-level flag record.

### Drift mistakes

#### Mistake: Treating any difference as bad drift

GitOps systems had to learn this the hard way. Some differences are intentional: emergency overrides, local annotations, runtime counters, timestamps, generated fields.

**Recommendation:** separate:

- desired declarative state
- mutable operational state
- derived/runtime state

Rulestead drift detection should only compare declarative state by default.

#### Mistake: Treating no-diff as safe

If the desired manifest was built from stale source data, "no diff" can still mean wrong state.

**Recommendation:** include source hash, export timestamp, and base version in bundles. Show when a promotion preview is based on stale source.

### Import/export mistakes

#### Mistake: Building a format that is human-friendly but not machine-safe

YAML that is pleasant to edit but underspecified for IDs, ordering, or typed values will become brittle in CI.

**Recommendation:** prefer a strict JSON schema internally, with optional YAML rendering for operator ergonomics.

#### Mistake: Importing by side effect

Direct import-into-live-state removes the chance to validate, diff, and approve.

**Recommendation:** import should produce one of three outcomes:

- valid, no-op
- valid, changes pending review
- invalid, with reference and schema errors

Never "best effort" partial apply.

### Tenancy mistakes

#### Mistake: Modeling tenancy only in targeting attributes

Pure attribute-based tenancy is flexible but can become unsafe when admins need tenant-scoped overrides, operator views, quotas, and audit slicing.

**Recommendation:** keep tenant in the evaluation context and audit model as a first-class concept, while avoiding physically duplicating flags per tenant.

#### Mistake: Modeling tenancy only in topology

Making every tenant a project or environment gives isolation, but destroys manageability and makes broad rollout impossible.

**Recommendation:** for v0.6, keep Dev/Staging/Prod as environments and tenants as scoped evaluation/audit partitions within an environment.

## Where GitOps Integrations Go Wrong

### 1. They create a second product without admitting it

A GitOps integration is not just export/import. It implies:

- source-of-truth choice
- branch/review workflow
- merge conflict handling
- runtime reconcile semantics
- secret/token handling
- rollback semantics
- drift exceptions

Platforms that hide this complexity make operators trust the wrong abstraction.

**Rulestead recommendation:** in v0.6, ship GitOps as controlled import/export plus CI validation, not full continuous reconciliation from Git into prod.

### 2. They allow UI and Git mutation on the same objects without policy

This is the classic two-writers problem:

- Git says desired state is A.
- Operator hotfixes prod in UI to B.
- Reconciler later forces it back to A.
- Everyone sees "drift fixed"; production just regressed.

Argo CD and Flux both document self-heal/reconcile behavior because this is dangerous by default.

**Rulestead recommendation:** support two modes only:

- `ui_primary`: UI/admin is source of truth; Git export is downstream artifact.
- `git_primary`: imports are authoritative for declarative config; UI mutations for managed environments are blocked or forced through exportable change requests.

Do not ship mixed mode in v0.6.

### 3. They reconcile too much state

Pruning, auto-heal, and allow-empty are powerful because they can delete things. Feature config has analogous hazards:

- deleting flags absent from manifest
- removing variants no longer listed
- clearing audiences that were omitted accidentally

**Rulestead recommendation:** no destructive sync by default. Import should preview deletions separately and require explicit opt-in.

### 4. They lack dependency ordering

Flux's `dependsOn` and wait semantics exist because apply order matters. Feature config is similar:

- audiences before rules that reference them
- variant schema before rollout stages using those variants
- tenant override scopes after base flag creation

**Rulestead recommendation:** imports should compile to an ordered apply plan, not a flat list of updates.

### 5. They skip behavioral verification

A manifest can be schema-valid and still produce the wrong evaluations.

**Rulestead recommendation:** every import/promotion path should support:

- syntax/schema validation
- dependency validation
- diff preview
- simulation preview against sample contexts
- optional CI assertions

## Where Tenancy Models Go Wrong

### 1. Tenant identity is underspecified

If `tenant_id`, `organization_id`, and account plan semantics are not distinguished, flags become a shadow billing/authorization system.

**Recommendation:** define one canonical tenant identifier in Rulestead context and keep plan/entitlement attributes separate from tenant identity.

### 2. Tenancy and entitlements get mixed with release flags

LaunchDarkly explicitly treats entitlements as long-lived/permanent targeting. That is a different lifecycle from release flags.

**Recommendation:** make flag purpose explicit in metadata:

- release
- experiment
- operational
- entitlement
- migration

Entitlement flags should not be promoted, archived, or reviewed with the same assumptions as short-lived rollout flags.

### 3. Override precedence is ad hoc

The hardest operator bug class is "why did tenant X get value Y?" with multiple possible override layers.

**Recommendation:** publish and enforce one precedence order, for example:

`kill_switch -> actor override -> tenant override -> audience/ruleset -> environment default -> flag default -> SDK fallback`

If Rulestead chooses a different order, it still must be singular and explainable.

### 4. Bucketing is inconsistent across tenant scopes

If a rollout is supposed to be tenant-consistent but uses actor ID bucketing, users in one tenant will split unpredictably. If it is supposed to be user-consistent but uses tenant ID bucketing, rollout granularity is wrong.

**Recommendation:** make bucketing scope explicit per rule or per flag:

- by actor
- by tenant
- by custom targeting key

Never infer it silently.

### 5. Data model explodes into copies

A naive model creates:

- one base flag
- N tenant-specific clones
- M environment-specific clones of those clones

This destroys promotion, audit readability, and cleanup.

**Recommendation:** store one logical flag identity with optional scoped override layers. Avoid physical duplication as the default.

## Rulestead-Specific Data Model Traps

### Trap: No distinction between manifest, snapshot, and audit event

These are three different things:

- **Manifest**: declarative desired state for import/export/promotion
- **Snapshot**: compiled runtime evaluation artifact
- **Audit event**: immutable record of who changed what and why

If one table shape tries to serve all three, drift logic and explainability will get muddy.

**Recommendation:** keep them separate at the concept and storage layers.

### Trap: Audience identity tied to environment-local row IDs

Promotion becomes brittle if environments cannot safely map references.

**Recommendation:** use stable keys for promotable entities and explicit environment-local version metadata, not opaque local IDs in exported references.

### Trap: Implicit override merge semantics for JSON config values

Remote config values make "override" ambiguous:

- replace whole object?
- deep merge?
- merge arrays?

**Recommendation:** v0.6 should support replace semantics only for JSON config overrides unless a stronger merge contract is designed and tested.

### Trap: Promotion of partially compiled state

Promoting compiled snapshots instead of declarative source looks attractive for reproducibility, but it locks in runtime artifacts and hides intent.

**Recommendation:** export declarative state plus compile hash, not raw runtime snapshot blobs, for GitOps and promotion.

## Race Conditions and Hidden Complexity

### Scheduled change vs manual promotion

Unleash documents scheduled changes suspending on later edits for good reason. Rulestead has the same risk:

- draft scheduled from staging
- prod gets hotfix
- promotion bundle built from stale staging
- schedule fires later and undoes prod hotfix

**Recommendation:** every scheduled apply must re-check base version and fail closed on mismatch.

### Drift check vs live mutation

If the admin compares env A to env B while B changes mid-review, the preview can lie.

**Recommendation:** diff previews must include compared versions/hashes and invalidate on change.

### Git import vs runtime cache propagation

A successful import is not operationally complete until the new compiled snapshot propagates.

**Recommendation:** import/apply status should include:

- DB write committed
- snapshot compiled
- invalidation emitted
- nodes applied or timed out

### Promotion of changed rollout allocations

Featurevisor’s state-file and revision pattern exists to preserve consistent bucketing. If Rulestead rebuilds allocations without preserving stable bucketing inputs, actors can churn variants after promotion.

**Recommendation:** preserve rollout salts and allocation metadata as promotable state.

## UX Confusion Patterns To Avoid

### Bad pattern: "Sync" as a single button

"Sync" hides direction, scope, and authority.

**Use instead:**

- `Compare`
- `Export`
- `Import for review`
- `Promote to production`
- `Apply approved bundle`

### Bad pattern: showing green "In sync" without scope

Operators will assume everything matches.

**Use instead:** label exact scope:

- `Flags: in sync`
- `Audiences: drift detected`
- `Emergency overrides: excluded`
- `Compared against manifest sha256:...`

### Bad pattern: tenancy hidden in filters only

If tenant selection changes evaluation scope, it cannot be just a UI convenience filter.

**Use instead:** tenant scope should be visible in breadcrumbs, diffs, explain pages, and audit rows.

## What To Defer Until v1.0

These are real needs, but forcing them into v0.6 raises rewrite risk:

1. **Bi-directional continuous Git reconciliation**
   - Too many source-of-truth and hotfix edge cases for the current milestone.

2. **Cross-instance live promotion with automatic dependency creation**
   - Safe cross-instance migration is materially harder than same-instance environment promotion.

3. **Full tenant hierarchy and inheritance**
   - Parent org -> workspace -> sub-tenant override trees are a v1.0 authorization/data-governance problem.

4. **Per-tenant RBAC and tenant-admin delegation**
   - This belongs with the planned v1.0 RBAC/security hardening milestone.

5. **Deep-merge semantics for remote-config payload overrides**
   - Replace semantics are much safer initially.

6. **Automatic conflict resolution for scheduled changes**
   - Detect-and-block is safer than auto-merge.

7. **Destructive GitOps prune mode**
   - Preview-only deletion reporting is enough for v0.6.

8. **Environment-as-template inheritance trees**
   - Helpful later, but it complicates drift, explanations, and promotion semantics now.

## Positive Plan For Rulestead v0.6.0

### 1. Pick one core model

Rulestead should model:

- stable flag identity across environments
- environment-specific ruleset/config overlays
- explicit tenant context with optional scoped overrides
- immutable promotion bundles with base version/hash

### 2. Make promotion the center, not "sync"

Ship these verbs:

- `diff(source_env, target_env)`
- `export_env_manifest(env)`
- `import_manifest(manifest) -> pending_apply`
- `apply_bundle(bundle, target_env, expected_version)`

Every path should share the same compiler and validator.

### 3. Keep GitOps narrow and reliable

For v0.6:

- export manifest to CI-friendly JSON
- validate manifest in CI
- import manifest as reviewable pending change
- optionally lock specific environments into `git_primary`

Do not ship background reconcile loops unless the mutation policy is airtight.

### 4. Make drift explicit and bounded

Track three states:

- `in_sync`
- `drifted_declarative`
- `runtime_override_present`

That is more honest than one generic drift bit.

### 5. Keep tenancy minimal but first-class

Ship:

- canonical `tenant` in context
- tenant-aware audit filtering
- explicit bucketing scope choice
- optional tenant overrides with strict precedence

Do not ship:

- tenant hierarchies
- tenant-specific environment topologies
- tenant-admin autonomy

### 6. Require preview, version check, and audit on every production apply

Borrow the best platform pattern directly:

- preview diff
- confirm intent
- require reason
- apply only if base version still matches
- record immutable audit
- surface propagation status

## Milestone Recommendations

1. **Define a single manifest schema first**
   - One schema for promotion/import/export avoids three drifting implementations.

2. **Implement dependency-aware diffing before one-click promotion**
   - Promotion UX without reference-aware diffing will create false confidence.

3. **Add optimistic concurrency to all applies**
   - Promotion, import, and scheduled changes should all fail closed on base-version mismatch.

4. **Treat GitOps as reviewable import/export in v0.6**
   - CI validation and pending applies are enough; continuous bi-directional sync is not.

5. **Separate declarative state from runtime/emergency state**
   - Drift and promotion need different treatment for kill switches, holds, and caches.

6. **Ship explicit tenancy primitives, not tenant topology**
   - Tenant in context, audit, and overrides is enough for this release.

7. **Make bucketing scope and salts explicit**
   - Prevent silent reshuffles during promotion and tenant rollouts.

8. **Defer destructive prune and hierarchy features**
   - Detection and visibility are safer than automatic cleanup at v0.6.

## Sources

### High confidence

- LaunchDarkly docs: creating flags across environments, projects, environments, approvals, compare/copy, contexts, entitlements
  - https://launchdarkly.com/docs/home/flags/new
  - https://launchdarkly.com/docs/home/account/project
  - https://launchdarkly.com/docs/eu-docs/home/account/environment
  - https://launchdarkly.com/docs/home/releases/approval-config
  - https://launchdarkly.com/docs/home/flags/compare-copy
  - https://launchdarkly.com/docs/home/flags/contexts/intro
  - https://launchdarkly.com/docs/guides/flags/entitlements
- Unleash docs: change requests, environments, import/export
  - https://docs.getunleash.io/concepts/change-requests
  - https://docs.getunleash.io/concepts/environments
  - https://docs.getunleash.io/concepts/import-export
- Featurevisor docs: GitOps/IaC, state files, testing
  - https://featurevisor.com/docs/concepts/infrastructure-as-code/
  - https://featurevisor.com/docs/state-files/
  - https://featurevisor.com/docs/testing/
- Argo CD docs: automated sync, self-heal, prune, ignore differences
  - https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/
  - https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/
- Flux docs: Kustomization reconcile, prune, wait, dependsOn, suspend
  - https://fluxcd.io/flux/components/kustomize/kustomizations/
- GO Feature Flag docs: retrievers, persistent config, startup behavior, polling jitter
  - https://gofeatureflag.org/docs/relay-proxy/configure-relay-proxy

### Medium confidence synthesis

- The recommended Rulestead split between declarative drift and runtime override state is an inference from GitOps controller behavior plus feature-flag operator needs.
- The recommendation to avoid bi-directional Git reconciliation in v0.6 is a product judgment based on the documented complexity of reconcile/self-heal/prune systems and the current Rulestead milestone scope.
