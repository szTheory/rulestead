# Architecture Research: Rulestead v1.3.0 - Adopter Truth & Proof Closure

**Project:** Rulestead v1.3.0 - Adopter Truth & Proof Closure
**Researched:** 2026-05-24

## Architectural Focus

This milestone does not introduce a new product subsystem. It reconciles four existing truth surfaces so that the public release story, authored-state contract, mounted companion behavior, and optional bridge proof all describe the same product.

## Required Integration Points

### 1. Public Docs <-> Shipped Release Posture

- Root and sibling package READMEs must match the `v1.0.0` GA reality recorded in planning.
- Shared guides remain the canonical cross-package narrative, especially lifecycle and installation.
- Release messaging should continue to describe `rulestead_admin` as a mounted companion, never a standalone admin product.

### 2. Ecto Schema <-> Migrations <-> Installer Truth

- `rulestead/lib/rulestead/flag.ex` already expects explicit `ownership` and `lifecycle` embeds plus `expected_expiration`.
- The initial authoring migration and later lifecycle migration need to prove the same authored shape that runtime code and tests already assume.
- Installer and upgrade paths must remain reproducible for host apps; migration parity is part of the public contract.

### 3. Host-Facing Admin Contract <-> Mounted UI

- The mounted admin surface is public at the policy/session/route seam, not at the DOM implementation level.
- Contract tests should assert real host-facing expectations: lifecycle form fields, bounded permission degradation, and mounted-only operator flow posture.
- Fix the drift by reconciling either tests or intended behavior, but record one truth.

### 4. Companion Bridge <-> Runnable Proof

- `open_feature_rulestead` remains a companion package, not the product center.
- Its proof surface should be small but real: documented setup, stable dependency posture, and a runnable test path.
- Bridge proof must not force core package architecture changes.

## Packaging Ledger

| Surface | Classification | Notes |
|---------|----------------|-------|
| Runtime docs and migrations in `rulestead` | `core` | Canonical install and authored-state truth lives here. |
| Mounted admin docs and contract proof in `rulestead_admin` | `companion` | Mounted-only posture stays unchanged. |
| OpenFeature bridge docs and tests | `companion` | Support honestly or bound explicitly. |
| Demo, verification scripts, and shared guides | `core support surface` | Used to prove adoption and release coherence. |

## Suggested Build Order

1. Fix release language and support-truth claims so the intended surface is explicit.
2. Reconcile runtime schema and migration parity so installer/database truth matches runtime code.
3. Reconcile mounted admin contract expectations with actual host-facing behavior.
4. Close cross-package verification, including the OpenFeature bridge, and publish bounded support truth.

## Sources

- `.planning/threads/2026-05-24-proof-posture-drift.md`
- `prompts/rulestead-host-app-integration-seam.md`
- `prompts/rulestead-release-engineering-and-ci.md`
- `rulestead/lib/rulestead/flag.ex`
- `rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs`
- `rulestead/priv/repo/migrations/20260424210000_add_phase6_admin_lifecycle_fields.exs`
