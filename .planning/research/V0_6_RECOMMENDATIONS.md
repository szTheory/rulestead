# Rulestead v0.6.0 Recommendations

**Date:** 2026-05-18
**Purpose:** Synthesize the pre-definition research pass for `v0.6.0` into one coherent recommendation set before milestone requirements and roadmap work.

## Bottom line

Rulestead `v0.6.0` should ship **multi-environment compare/apply promotion**, **deterministic manifest export/import**, and **minimal tenant-aware helpers**.

It should **not** ship a full Git reconciler, bidirectional sync, environment inheritance, or tenant-partitioned authoring/storage.

The milestone should preserve the current product shape:

- `rulestead` remains the runtime and automation core.
- `rulestead_admin` remains a mounted operator UI, not a standalone product.
- The host app still owns auth, layout, environment policy, and deployment workflow.

## Cohesive recommendation set

### 1. Promotion model

Use **unified flag identity with per-environment config**.

Promotion should be:

- source environment -> target environment
- preview diff first
- governed apply second
- target snapshot regenerate last

Do **not** model promotion as:

- snapshot cloning
- environment inheritance
- hidden background reconciliation
- per-rule cherry-picking as the default UX

Why:

- It matches the current Rulestead architecture and operator expectations.
- It preserves authoring intent instead of copying runtime artifacts.
- It composes cleanly with existing change-request, approval, scheduling, and audit flows.

### 2. GitOps model

Start with **one-way deterministic import/export**.

Recommended shape:

- `mix rulestead.export`
- `mix rulestead.validate`
- `mix rulestead.diff`
- `mix rulestead.import --plan`
- `mix rulestead.import --apply`
- `mix rulestead.promote --plan`
- `mix rulestead.promote --apply`

The admin UI should act as:

- review console
- diff viewer
- simulation/validation surface
- source of copyable CLI commands

It should **not** become a second independent automation system.

Why:

- Phoenix teams expect reproducible CLI surfaces for CI.
- Stable text plus JSON output is better for CI readability and scripting.
- A narrow GitOps seam avoids dual-truth drift between Git and the admin UI.

### 3. Manifest contract

Ship a **versioned canonical manifest** around stable semantic keys, not internal IDs.

Include:

- flags
- per-environment config
- rulesets/rules
- audience references
- variants
- environment status
- metadata needed for audit/provenance

Do not pretend the first export is a full-fidelity backup of every runtime concern.

Be explicit about exclusions, especially:

- runtime snapshot internals
- emergency runtime state if not declarative
- incomplete dependency closure
- ephemeral scheduling/runtime execution state

### 4. Tenancy model

Treat tenancy as a **first-class helper seam**, not as a new top-level storage topology.

Recommended `v0.6.0` scope:

- explicit `tenant_key` support in context and admin scope
- tenant-aware bucketing helpers
- tenant-aware audit metadata
- query-scoping helpers
- promotion/import validation for tenant-sensitive references
- a `Rulestead.Tenancy` seam with a `SingleTenant` default

Do **not** ship:

- environment-per-tenant
- per-tenant cloned flags as the default model
- full tenant-partitioned authoring/storage
- tenant hierarchies
- tenant-specific RBAC beyond existing host/governance seams

### 5. Safety defaults

Every apply path should have:

- preview -> confirm -> audit
- optimistic concurrency / fingerprint check
- dependency closure validation
- explicit source and target environment selection
- explicit tenant scope where relevant
- deterministic dry-run output

Protected environments should route through existing governed mutation flows.

## Idiomatic ecosystem fit

This recommendation set is the most idiomatic fit for:

- **Elixir/Ecto**: explicit domain state, transactional apply flows, optimistic locking, audit-first mutations
- **Phoenix/LiveView**: mounted admin as operator console, not platform silo
- **Plug/Phoenix host integration**: host app owns auth, policy, and deployment conventions
- **Elixir library DX**: Mix tasks as the automation surface; optional admin UI for visibility and review

## What successful tools got right

- **Unleash**: unified flag model, environment-specific config, change-request wrapping for protected changes, import/export with validation
- **LaunchDarkly**: environment safeguards, compare/copy ergonomics, explicit critical-environment controls
- **GrowthBook**: draft/revision mindset and strong emphasis on local evaluation and operator clarity
- **GitOps tools like Argo CD / Flux**: drift must have explicit ownership semantics; hidden two-way magic is a footgun

## What to avoid

- Two equal writers with no source-of-truth policy
- Name-based promotion matching without stable identities
- Promotion that copies runtime state instead of desired config
- Destructive import/prune as the default
- Ambiguous precedence across environment, tenant, audience, actor, and kill-switch layers
- Bucketing changes that silently reshuffle users during promotion

## Recommended milestone slice

### Table stakes for `v0.6.0`

1. Environment compare/apply with diff preview
2. Conflict detection on apply/import/promotion
3. Deterministic export format
4. Dry-run import with validation
5. CLI-first automation surface with JSON output option
6. Governance/audit integration for protected environments
7. Minimal tenant-aware helpers and validation

### Defer until `v1.0.0` or later

- bidirectional Git reconciliation
- automatic continuous sync
- environment inheritance as the main model
- per-rule cherry-pick promotion as the primary UX
- tenant-partitioned storage/authoring
- full management API parity with the admin UI and CLI
- deep-merge remote-config semantics

## Suggested milestone framing

**Milestone v0.6.0: Multi-environment Sync & Tenancy**

**Goal:** Let teams safely compare, promote, export, import, and validate flag configuration across environments while introducing tenant-aware helper seams that preserve the current linked-version, mounted-admin design.

**Target features:**

- Environment compare/apply promotion with governed preview
- Deterministic manifest export/import for GitOps-style workflows
- Tenant-aware scoping, validation, and bucketing helpers

**Non-goals:**

- Standalone `rulestead_admin`
- Full Git reconciler / continuous sync engine
- Full multi-tenant topology redesign

## Inputs

This synthesis is based on:

- [V0_6_PRODUCT_SHAPE.md](/Users/jon/projects/rulestead/.planning/research/V0_6_PRODUCT_SHAPE.md)
- [V0_6_ARCHITECTURE.md](/Users/jon/projects/rulestead/.planning/research/V0_6_ARCHITECTURE.md)
- [V0_6_DX.md](/Users/jon/projects/rulestead/.planning/research/V0_6_DX.md)
- [V0_6_PITFALLS.md](/Users/jon/projects/rulestead/.planning/research/V0_6_PITFALLS.md)
