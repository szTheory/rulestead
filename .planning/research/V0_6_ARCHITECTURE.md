# Rulestead v0.6.0 Architecture and Data Model Research

**Project:** Rulestead  
**Date:** 2026-05-18  
**Scope:** Multi-environment sync, GitOps import/export, tenancy helpers  
**Overall confidence:** MEDIUM-HIGH

## Executive Recommendation

Rulestead should keep its current **database-first authoring model** and add a **manifest seam as a projection/import boundary**, not as a second live source of truth. The current code already has the right split for this: authoring data is normalized around `flags`, `environments`, `flag_environments`, and `rulesets`, while runtime distribution is already compiled into immutable per-environment `runtime_snapshots` and fanned out through cache/PubSub. That is the right spine to preserve.

For v0.6.0, environment promotion should be implemented as **explicit copy/apply of authoring intent from one environment to another**, with a preview diff and governance integration, not as snapshot cloning, environment inheritance, or background reconciliation. Snapshot cloning is too low-level and can smuggle compiled/runtime-only details into authoring semantics. Inheritance/overlay models are attractive on paper, but they would force Rulestead to grow a layered resolution engine across admin, store, diffing, audit, and runtime compilation all at once.

The safest GitOps seam is **one-way import/export through manifests**:

- `export`: project state or environment state -> manifest document
- `import`: manifest document -> preview diff -> governed apply through the existing store/admin path

That keeps GitOps friendly, reproducible, and CI-usable without committing Rulestead to early two-way-sync promises. v0.6.0 should support **drift detection against a declared source manifest or source environment**, but should not yet run an always-on reconciler or write back to Git.

For tenancy, v0.6.0 should ship **helpers, not a full tenancy storage model rewrite**. The current `Rulestead.Context` already carries `tenant_key`; the right next step is to formalize a `Rulestead.Tenancy` behaviour and a few narrow helpers for scoping, bucketing, PubSub naming, and admin guardrails. Per-tenant authoring copies, per-tenant snapshots, or tenant-owned environment trees are overbuilt for this milestone.

## Current Architecture Fit

The existing codebase already constrains the best answer:

- Authoring is normalized around shared flags plus environment-specific state.
  - `rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs`
  - `rulestead/lib/rulestead/flag.ex`
  - `rulestead/lib/rulestead/environment.ex`
  - `rulestead/lib/rulestead/flag_environment.ex`
  - `rulestead/lib/rulestead/ruleset.ex`
- Runtime distribution is already per-environment and immutable by version.
  - `rulestead/lib/rulestead/runtime_snapshot.ex`
  - `rulestead/lib/rulestead/runtime/snapshot.ex`
  - `rulestead/lib/rulestead/store/ecto.ex`
  - `rulestead/lib/rulestead/runtime/cache.ex`
  - `rulestead/lib/rulestead/runtime/refresh.ex`
  - `rulestead/lib/rulestead/runtime/notifier.ex`
- Governance is already mutation-centric and environment-aware, which is a strong fit for promotion/import as governed actions.
  - `rulestead/lib/rulestead/store.ex`
  - `rulestead/lib/rulestead/store/command.ex`

This means v0.6.0 should extend the **authoring plane** and **governed mutation plane**, then let runtime snapshots continue to be compiled outputs.

## Research Questions

## 1. Viable architecture patterns for environment promotion and drift detection

### Pattern A: Independent environment state with explicit promotion

**What it is**

Each environment keeps its own effective flag state. Promotion means copying selected authoring state from source to target after showing a diff.

**How it maps to Rulestead**

- `flags` remain shared catalog objects
- `flag_environments` remain the environment-specific attachment/status record
- `rulesets` remain versioned within each `flag_environment`
- runtime snapshots stay derived from the target environment after apply

**Pros**

- Matches the current schema almost exactly
- Keeps runtime compilation unchanged
- Keeps audit/governance meaningful at mutation boundaries
- Makes diffing a pure authoring concern
- Easy to explain in admin UI

**Cons**

- Duplicates rulesets across environments
- Drift is expected unless managed explicitly
- Segment/audience references need careful validation when copied

**Assessment**

Best fit for v0.6.0.

### Pattern B: Base plus environment overlays/inheritance

**What it is**

Shared baseline definitions are inherited by environments, which only store overrides.

**Pros**

- Smaller diffs
- Feels natural to GitOps users familiar with Kustomize overlays
- Can reduce duplication

**Cons**

- Requires layered resolution rules across admin, diff, import, export, audit, and runtime
- Makes “what is active in prod?” harder to answer without full materialization
- Promotion semantics become ambiguous: copy override only, or collapse resolved state?
- Increases rework risk because current store/runtime code is not layer-aware

**Assessment**

Good long-term idea only if the product later proves that environment duplication is the main scaling pain. Wrong default for v0.6.0.

### Pattern C: Event-sourced promotion/replay

**What it is**

Environments are reconstructed from change events. Promotion means replaying or translating events from one environment to another.

**Pros**

- Rich audit lineage
- Strong time-travel story

**Cons**

- Promotion intent and effective state diverge
- Requires event canonicalization before import/export
- Harder to produce deterministic manifests without extra projection machinery

**Assessment**

Too heavy. Rulestead has append-only audit, but not event-sourced authoring. Keep it that way.

### Pattern D: Snapshot-level promotion

**What it is**

Promote the compiled environment snapshot directly.

**Pros**

- Simple runtime artifact copy
- Fast

**Cons**

- Promotes compiled output, not authoring intent
- Loses draft/published semantics and admin editability
- Risks importing transient/runtime-only metadata
- Fights the current distinction between manifest, authoring, and snapshot

**Assessment**

Do not use as the primary authoring model. Snapshots are for runtime distribution only.

### Recommendation

Use **Pattern A** for v0.6.0:

- independent effective environment authoring state
- explicit promotion plans
- diff before apply
- governance/change-request integration on target environment
- runtime snapshots regenerated only after target apply

### Drift detection recommendation

Implement **three narrow drift concepts**, not one overloaded “drift” feature:

| Drift type | Compare | Why it matters | v0.6.0 |
|---|---|---|---|
| Promotion drift | source environment vs target environment | “Has prod diverged from staging?” | Yes |
| Manifest drift | imported/exported manifest vs current DB authoring state | “Has Git fallen behind or ahead?” | Yes |
| Runtime freshness drift | latest authoring snapshot version vs applied runtime snapshot version | “Did nodes apply the right snapshot?” | Already mostly present |

Do **not** implement “continuous Git reconciliation drift” yet. Export/import plus explicit drift check is enough.

## 2. Conceptual relationships: manifests, snapshots, environments, tenants, overrides

### Recommended noun model

| Noun | Meaning | Persistence role | Runtime role |
|---|---|---|---|
| Manifest | Declarative import/export document | External file boundary | None directly |
| Snapshot | Immutable compiled environment artifact | `runtime_snapshots` | Primary runtime input |
| Environment | Isolated authoring and runtime release space | DB record | Snapshot partition key |
| Tenant | Organizational/request scope used during evaluation and admin filtering | Context/helper layer in v0.6.0 | Input to rules, bucketing, auth |
| Override | Higher-precedence explicit mutation or evaluation specialization | Limited authoring/runtime concept | Changes effective result |

### Recommended relationships

#### Manifest

A manifest should describe **shared catalog state plus environment-specific effective state**.

Recommended shape:

- shared flag metadata at the flag level
- shared audience definitions at the project/package level
- per-environment state nested beneath each flag or in a parallel environment section
- no runtime snapshot bytes in the manifest

Conceptually:

```text
Manifest
  -> Flags
    -> shared metadata
    -> environment states
      -> status
      -> active ruleset
      -> optional draft rulesets
      -> explicit overrides
  -> Audiences
  -> metadata/checksums
```

#### Snapshot

A snapshot should remain:

- per environment
- compiled
- immutable by version
- unsuitable as the editable interchange format

This matches the current implementation in `Rulestead.RuntimeSnapshot` and `Rulestead.Runtime.Snapshot`.

#### Environment

An environment should stay the main boundary for:

- promotion
- approval requirements
- runtime snapshot generation
- admin comparisons

Environment is not just a label. It is the boundary where rules become deployable state.

#### Tenant

For v0.6.0, tenant should be:

- part of context and helper APIs
- part of admin scoping helpers
- part of bucketing/salt composition when configured
- not yet a first-class authoring partition that duplicates flags/environments

That keeps the system cohesive with the existing mounted-admin model and avoids turning `rulestead_admin` into a cross-org control plane too early.

#### Overrides

Rulestead already has an environment-level override concept in practice via kill-switch state on `flag_environments`. v0.6.0 should keep overrides narrow:

- environment kill switch override
- optional manifest-declared environment override blocks
- optional tenant evaluation helpers, but not tenant-authored per-tenant flag copies

Avoid a general-purpose arbitrary override stack. That is where systems become impossible to reason about.

## 3. Safest import/export seam for GitOps

### Recommended seam

**Manifest import/export should sit above the authoring store and below admin presentation.**

Concretely:

- `Rulestead.Manifest.Export` builds a declarative document from normalized DB authoring state
- `Rulestead.Manifest.Import` parses a manifest into an internal plan
- `Rulestead.Manifest.Diff` compares manifest intent against current authoring state
- `Rulestead.Manifest.Apply` converts approved changes into existing store/governance operations

That keeps the seam library-first and reusable by:

- mounted admin
- Mix tasks
- CI jobs
- future API endpoints

### Why this seam is safer than alternatives

| Seam | Why not |
|---|---|
| Snapshot import/export | wrong abstraction level; compiled runtime artifact |
| Direct table dump/load | leaks internal schema and upgrade complexity into users’ repos |
| Admin-only import/export | too coupled to mounted UI, weak for CI |
| Bi-directional sync agent now | creates hidden ownership and conflict rules too early |

### Recommended v0.6.0 import/export contract

Support:

- `export manifest --environment prod`
- `export manifest --project all`
- `import manifest --dry-run`
- `import manifest --apply`
- `diff manifest path/to/file`
- `diff environments dev prod`
- `promote environment dev -> staging`

But keep import semantics explicit:

- import is **pull into Rulestead**
- export is **write from Rulestead**
- no automatic push back to Git
- no daemon that continuously mutates DB from repo changes

### GitOps posture

GitOps primary sources stress declarative desired state, versioning/immutability, and reconciliation. That supports manifests as the seam, but it does **not** force v0.6.0 to run a reconciler. The right early posture is:

- Git can be the desired-state source for teams that choose it
- Rulestead can import that desired state safely
- Rulestead can show drift
- humans or CI still trigger apply

That is GitOps-friendly without pretending to be Argo CD for flags.

### Import/export format boundary

Recommend **YAML as the primary authoring format**, JSON as a machine-format alternative.

YAML benefits:

- reviewable in PRs
- natural fit for GitOps
- common in config ecosystems

JSON benefits:

- easier machine round-trip
- easier strict validation and deterministic hashing

Best compromise:

- internal canonical form: maps/structs
- stable export ordering
- YAML and JSON frontends over one schema
- schema version required in manifest root

### Persisted data model additions for GitOps

Keep additions light:

1. Add manifest metadata to audit/change-request records
   - source path
   - source revision
   - manifest checksum
   - import mode
2. Optionally add a small `environment_sync_receipts` table later if audit rows prove too coarse
3. Do not add a first-class `manifests` table in v0.6.0 unless reconciliation becomes a requirement

The current audit/governance model is already strong enough to hold import/export provenance.

## 4. Minimal-but-powerful tenancy helpers

### Recommended v0.6.0 tenancy package

Add a small `Rulestead.Tenancy` seam:

- `Rulestead.Tenancy` behaviour
- `Rulestead.Tenancy.SingleTenant` default implementation
- `Rulestead.Tenancy.Scope` struct or helper functions

Recommended callbacks/helpers:

```elixir
tenant_key(context_or_conn_or_socket) :: String.t() | nil
scope(queryable, tenant_scope) :: Ecto.Queryable.t()
bucketing_key(%Rulestead.Context{}, opts) :: String.t()
pubsub_topic(base_topic, tenant_key) :: String.t()
same_tenant?(left, right) :: boolean()
```

### What these helpers should do

| Helper | Purpose | Why it is enough for v0.6.0 |
|---|---|---|
| `tenant_key/1` | resolve tenant from request/context | standardizes host seam |
| `scope/2` | apply tenant-aware filters where needed | matches Phoenix scope discipline |
| `bucketing_key/2` | optionally compose actor + tenant for rollout stability | avoids cross-tenant bleed |
| `pubsub_topic/2` | partition notification topics when host wants it | additive, not invasive |
| `same_tenant?/2` | admin/resource guard helper | good defensive default |

### What not to build yet

Do not add in v0.6.0:

- per-tenant copies of every environment
- tenant-owned runtime snapshot tables
- fully tenant-keyed schema on all authoring tables
- global multi-tenant admin dashboards across many organizations
- tenant-specific manifest inheritance

Those are product-expanding moves, not helper moves.

### Phoenix/Ecto alignment

Phoenix 1.8 scopes are explicit that scoped access should be carried through context boundaries. That aligns with a narrow tenancy helper seam: pass a scope/tenant object into context and store functions where needed, rather than hiding tenant behavior in process globals. OpenFeature’s evaluation-context model also supports layered context input, which fits keeping tenant as explicit evaluation input rather than as hidden ambient state.

## 5. Recommended phased path for v0.6.0 through v1.0

### v0.6.0 recommendation

Ship these in order:

1. **Authoring diff engine**
   - compare two environments in normalized domain terms
   - diff flags, rulesets, audience references, status, and overrides
2. **Promotion plan/apply**
   - source env -> target env
   - preview first
   - apply through governance-aware mutation path
3. **Manifest schema plus export**
   - deterministic YAML/JSON export
   - environment-scoped and project-scoped modes
4. **Manifest import dry-run and apply**
   - validation
   - diff preview
   - governed apply
5. **Minimal tenancy helpers**
   - `Rulestead.Tenancy`
   - `SingleTenant`
   - bucketing/scoping helpers

### Defer until after v0.6.0

- background Git reconciliation loops
- bidirectional Git sync
- environment inheritance/overlay storage model
- persistent source-of-truth arbitration between DB and Git
- hard multi-tenant authoring partitioning
- RBAC-heavy tenancy administration

## Concrete data model recommendations

### Keep

- `flags` as shared catalog objects
- `environments` as deployable spaces
- `flag_environments` as environment-local status/attachment records
- `rulesets` versioned per `flag_environment`
- `runtime_snapshots` immutable and per environment

### Add

#### In-memory / library structs

- `Rulestead.Manifest`
- `Rulestead.Manifest.FlagState`
- `Rulestead.Manifest.EnvironmentState`
- `Rulestead.Promotion.Plan`
- `Rulestead.Diff.Change`
- `Rulestead.Tenancy.Scope`

These should likely be plain structs or embedded schemas, not tables.

#### Possible persisted fields

Prefer metadata additions over new tables first:

- import/export provenance in audit metadata
- promotion source metadata in change requests
- manifest checksum metadata on applied imports

If a new table becomes necessary, prefer a narrow receipt table:

```text
environment_sync_receipts
  id
  environment_key
  source_type        # environment | manifest
  source_ref         # env key or git ref/path
  source_checksum
  applied_by
  applied_at
  metadata
```

This is safer than introducing a durable manifest registry.

## Recommended manifest schema boundary

A cohesive v0.6.0 manifest should describe **authoring intent**, not storage internals:

- `schema_version`
- optional `project`
- `audiences`
- `flags`
  - shared metadata
  - `environments`
    - status
    - active ruleset
    - optional draft rulesets
    - explicit overrides
- metadata
  - export timestamp
  - exporter version
  - checksums

Do not expose:

- internal UUIDs as the primary linkage
- `runtime_snapshots.payload`
- raw audit rows
- compiled cache metadata

Use stable keys as the public boundary. Internal IDs remain adapter-private.

## Recommended tradeoff table

| Decision point | Recommended | Rejected alternative | Why |
|---|---|---|---|
| Environment model | independent effective state | inheritance/overlay storage | matches current schema and runtime |
| Promotion unit | authoring diff/apply | snapshot clone | preserves editable intent |
| Drift basis | source env or manifest vs target authoring state | runtime-only drift | catches the important operator cases |
| Manifest seam | library-level import/export module | admin-only or SQL dump | works for CI and mounted admin |
| GitOps direction | one-way explicit import/export | early bi-directional sync | avoids hidden ownership conflicts |
| Tenancy scope | helper seam on context/query/bucketing | per-tenant authoring partition now | minimal power, low rework |

## Primary sources

### Local project sources

- `.planning/PROJECT.md`
- `.planning/research/EPIC_ARC.md`
- `prompts/rulestead-host-app-integration-seam.md`
- `prompts/rulestead-engineering-dna-from-prior-libs.md`
- `prompts/rulestead-domain-language-field-guide.md`
- `prompts/rulestead-release-engineering-and-ci.md`
- `rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs`
- `rulestead/lib/rulestead/environment.ex`
- `rulestead/lib/rulestead/flag_environment.ex`
- `rulestead/lib/rulestead/ruleset.ex`
- `rulestead/lib/rulestead/runtime_snapshot.ex`
- `rulestead/lib/rulestead/runtime/snapshot.ex`
- `rulestead/lib/rulestead/runtime/cache.ex`
- `rulestead/lib/rulestead/runtime/refresh.ex`
- `rulestead/lib/rulestead/store/ecto.ex`

### External sources

- OpenFeature evaluation context spec
  - https://openfeature.dev/specification/sections/evaluation-context/
- Ecto.Multi docs
  - https://hexdocs.pm/ecto/Ecto.Multi.html
- Phoenix scopes docs
  - https://hexdocs.pm/phoenix/scopes.html
- Unleash import/export
  - https://docs.getunleash.io/concepts/import-export
- Unleash change requests
  - https://docs.getunleash.io/concepts/change-requests
- Unleash segments
  - https://docs.getunleash.io/concepts/segments
- LaunchDarkly environments
  - https://launchdarkly.com/docs/eu-docs/home/account/environment
- LaunchDarkly compare/copy
  - https://launchdarkly.com/docs/home/flags/compare-copy
- LaunchDarkly clone environments
  - https://launchdarkly.com/docs/home/account/environment/clone
- OpenGitOps principles
  - https://opengitops.dev/
- Kubernetes Kustomize bases and overlays
  - https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/

## Confidence notes

| Area | Confidence | Notes |
|---|---|---|
| Promotion architecture | HIGH | Strong fit to current schema/runtime split and supported by competitor patterns |
| Manifest seam | HIGH | Strong support from GitOps principles and current library architecture |
| Tenancy helpers | MEDIUM-HIGH | Strong Elixir/Phoenix fit, but exact host-app needs may vary |
| Long-term avoidance of overlay model | MEDIUM | A later overlay model could still become useful, but it is not the right v0.6.0 default |

## Bottom line

For v0.6.0, Rulestead should act like a **governed authoring system that can project to Git-friendly manifests**, not like a continuously reconciling control plane. Keep environments as explicit authoring spaces, keep snapshots as immutable runtime artifacts, add promotion/diff/import/export above the store, and add tenancy as a disciplined helper seam rather than a storage rewrite.
