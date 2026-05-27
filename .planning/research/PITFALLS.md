# Domain Pitfalls: v1.6.0 Reusable Targeting Deepening

**Project:** Rulestead  
**Domain:** Existing reusable audience targeting, impact previews, dependency visibility, mounted operator ergonomics  
**Researched:** 2026-05-27  
**Confidence:** HIGH for project-specific risks from planning/prompts; MEDIUM for phase numbering until v1.6.0 requirements are created.

## Scope Boundary

This milestone should deepen an already-shipped audience surface. It should not reintroduce reusable targeting as a greenfield feature, add live inheritance graphs, build a standalone admin control plane, create tenant-partitioned authored storage, or make Rulestead own identity, observability, analytics, or team-directory truth.

Recommended roadmap shape:

| Phase | Focus | Main Pitfalls Addressed |
|-------|-------|-------------------------|
| Phase 53 | Core audience impact preview contract | stale previews, false precision, privacy leaks, deterministic drift |
| Phase 54 | Dependency graph, import/export, promotion validation | broken references, hidden blast radius, tenant/env mismatch |
| Phase 55 | Mounted admin operator ergonomics | unsafe affordances, noisy UX, policy bypass, support confusion |
| Phase 56 | Proof, docs, release/support truth | docs/test drift, sibling-package mismatch, unsupported claims |

## Critical Pitfalls

### 1. Silent Blast-Radius Expansion From Shared Audience Edits

**What goes wrong:** Editing one audience changes many flags, environments, tenants, rollouts, or experiments without a trustworthy preview.  
**Why it happens:** Reuse turns a local condition edit into a graph mutation, but the UI still treats it like editing a single object.  
**Consequences:** Operators publish high-impact targeting changes without understanding affected flags, guarded rollouts, audit narratives, or tenant scope.  
**Prevention:** Phase 53 must require a before-save impact preview that lists referenced flags/rulesets/rollouts, environment, tenant scope, active lifecycle state, and expected evaluation deltas where sample data exists. Phase 55 must require preview -> confirm -> audit for mounted edits.  
**Detection:** Audience save screens lack "used by" counts, affected environments, target version/hash, or reason-required confirmation.

### 2. Impact Previews That Pretend To Be Exact

**What goes wrong:** Previews imply exact production impact even though Rulestead only has authored state, snapshots, explicit sample contexts, and host-supplied telemetry seams.  
**Why it happens:** "Impact preview" is easily confused with analytics, identity-directory truth, or observability-backed population counts.  
**Consequences:** Operators overtrust estimates; support claims drift into "Rulestead knows all affected users."  
**Prevention:** Phase 53 must label preview basis explicitly: authored references, deterministic simulation sample, last-known impression summary, or unavailable. Never fetch host identity data or metrics directly. Missing data should show bounded fallback copy, not green/healthy or zero-impact states.  
**Detection:** Copy says "will affect N users" without naming the data source, timestamp, sample size, tenant scope, and uncertainty.

### 3. Runtime Evaluation Starts Depending On Live Authored Lookups

**What goes wrong:** Evaluator resolves audience dependencies from DB/admin state at request time instead of from immutable snapshots.  
**Why it happens:** Dependency visibility code is reused in runtime paths, or LiveView preview logic bleeds into evaluator internals.  
**Consequences:** Hot-path latency increases, evaluation becomes nondeterministic, cache invalidation gets fragile, and support can no longer explain which snapshot produced a result.  
**Prevention:** Phase 53 must compile audience references into immutable snapshot versions. Phase 54 can add graph queries for authored-state dependency visibility, but runtime evaluation remains local and snapshot-backed.  
**Detection:** New evaluator code calls Repo, admin contexts, dependency graph services, or host callbacks while deciding a flag.

### 4. Hidden Inheritance Graphs Masquerade As Ergonomics

**What goes wrong:** Templates or reusable assets become live parents whose future edits implicitly mutate child rules.  
**Why it happens:** Operator ergonomics tries to reduce repetition by adding generic presets, nested audiences, or live-linked templates.  
**Consequences:** Explain traces become opaque, promotion/import dependency closure becomes hard, and operators cannot reason from a flag to its effective rules.  
**Prevention:** Phase 55 should limit ergonomics to selection, previews, reference counts, and draft generation. If presets exist, they generate concrete draft rules; they do not remain live inheritance relationships.  
**Detection:** Docs/UI mention inherited targeting, parent templates, cascading edits, or nested audience resolution beyond explicit audience references.

### 5. Dependency Validation Ignores Promotion And Manifest Semantics

**What goes wrong:** Export/import or environment promotion applies a ruleset whose referenced audience is missing, incompatible, stale, tenant-mismatched, or same-named but semantically different.  
**Why it happens:** Dependency visibility is built only for the mounted UI, not for manifests, compare, replay, and governed apply.  
**Consequences:** Target environments evaluate differently than previews; rollback/reapply history becomes misleading; support cannot trust manifests.  
**Prevention:** Phase 54 must make dependency closure a core validation contract for compare, promotion, export/import, replay, and reapply. Use stable keys plus version/hash checks; fail closed on missing or incompatible dependencies.  
**Detection:** Manifest preview shows JSON diffs but does not list audience dependencies, dependency versions, or blocked apply reasons.

### 6. Tenant Scope Becomes Implicit Again

**What goes wrong:** "All tenants" audience shortcuts or global reference counts hide tenant-sensitive targeting changes.  
**Why it happens:** Shared audiences are treated as generic assets instead of scoped authored state with explicit tenant semantics.  
**Consequences:** A change intended for one tenant leaks into another; audit and promotion provenance lose tenant clarity.  
**Prevention:** Phase 53 preview payloads and Phase 54 validations must carry tenant scope explicitly. Phase 55 screens must preserve tenant/environment URL state and never apply implicit all-tenant mutations.  
**Detection:** Preview or confirm copy omits tenant scope, or queries count references without tenant/environment filters.

### 7. Explainability Loses The Reused Audience Step

**What goes wrong:** Explain traces say "rule matched" but omit that the rule matched because audience `X` matched or failed.  
**Why it happens:** Shared targeting is treated as a lower-level predicate detail rather than a user-facing decision reason.  
**Consequences:** Support cannot answer "why did this actor get this value?"; operator trust drops after the first surprising edit.  
**Prevention:** Phase 53 must extend explain traces to include audience key, audience version/hash, match result, and redacted predicate summary. Phase 55 should surface that path in mounted explain/simulate views.  
**Detection:** Simulation/explain tests only assert final variant/value and not the reusable audience trace path.

### 8. Guarded Rollout Interactions Are Treated As Unrelated

**What goes wrong:** Audience edits alter who is in a guarded rollout stage without showing rollout health, hold, rollback, or last-stable-stage implications.  
**Why it happens:** v1.6.0 focuses on targeting screens and forgets v1.5.0 staged rollout state.  
**Consequences:** A "targeting-only" edit can bypass operator mental models for guarded rollout safety.  
**Prevention:** Phase 53 impact previews should flag active rollout references. Phase 54 dependency graph should include rollout consumers. Phase 55 UI should link affected rollout status but not add new observability dashboards.  
**Detection:** An audience referenced by active rollouts can be saved without a warning, affected rollout list, or audit reason.

## Moderate Pitfalls

### 9. Privacy Leaks In Member Or Impact Previews

**What goes wrong:** Preview samples expose raw actor IDs, emails, IPs, traits, or tenant-sensitive attributes.  
**Prevention:** Phase 53 must run all preview and telemetry metadata through existing redaction boundaries. Member previews remain opt-in and sample-based; audit rows store reasons and dependency summaries, not raw PII sets.  
**Detection:** Test fixtures assert exact emails/IPs in preview output, logs, telemetry, or audit payloads.

### 10. Policy Checks Cover Mutation But Not Dependency Reads

**What goes wrong:** A viewer can infer sensitive flag, tenant, or audience relationships through "used by" screens even when they cannot view the underlying resources.  
**Prevention:** Phase 54 graph queries and Phase 55 mounted screens must authorize both the audience and every referenced resource before display. Unauthorized references can be counted as redacted/hidden, not leaked.  
**Detection:** Dependency APIs return full flag keys across environments regardless of `Rulestead.Admin.Policy`.

### 11. Audit Events Are Too Thin To Reconstruct The Change

**What goes wrong:** Audit says "audience updated" but lacks impacted references, preview fingerprint, actor, reason, dependency validation result, and tenant/environment scope.  
**Prevention:** Phase 53/54 mutation flows should write one audit narrative with preview hash, old/new audience version, reference summary, blocked warnings, and governed approval linkage when required.  
**Detection:** Audit tests verify event existence only, not replayable evidence.

### 12. Admin Ergonomics Turn Into Bulk Automation

**What goes wrong:** To be "ergonomic," the UI adds bulk edit, one-click propagate, auto-fix dependencies, or cross-environment sync shortcuts.  
**Prevention:** Phase 55 should improve scanning and review: reference counts, filters, dependency tabs, copyable context, and safer confirmation. Avoid new automation paths unless they go through existing governed mutation envelopes.  
**Detection:** UI accepts multi-audience destructive changes without per-change previews or governed confirmation.

### 13. Dependency Graph Queries Do Not Scale

**What goes wrong:** Audience list/detail pages run N+1 queries or compile full graph state on every LiveView render.  
**Prevention:** Phase 54 should use explicit reference tables or indexed authored-state joins for "used by" counts and keyset-paginated dependency lists. Phase 55 should stream/paginate large lists.  
**Detection:** Reference counts are computed by loading all rulesets or decoding every JSON rule blob per request.

### 14. Lifecycle And Ownership Signals Are Dropped

**What goes wrong:** Audience impact screens show usage but not owner, lifecycle state, stale/archive posture, or cleanup risk.  
**Prevention:** Phase 53 preview contract should include owner/lifecycle metadata where already shipped; Phase 55 should show it as context, not create a new work-management system.  
**Detection:** A stale or ownerless audience can be edited broadly with no ownership/lifecycle warning.

## Minor Pitfalls

### 15. Terminology Drift Between Audience And Segment

**What goes wrong:** User-facing UI/docs call reusable audiences "segments," "cohorts," or "groups."  
**Prevention:** Phase 56 docs and tests should preserve canonical language: `Audience` externally, `segment` only as internal implementation vocabulary.  
**Detection:** New docs or UI strings use "segment" in operator-facing copy.

### 16. Versioned Package Truth Falls Out Of Sync

**What goes wrong:** `rulestead` exposes core dependency contracts but `rulestead_admin` docs/screens imply unsupported behavior, or package docs mention Phase 8/future surfaces early.  
**Prevention:** Phase 56 must verify root docs, package docs, install guidance, migrations, and proof commands together under the linked-version sibling-package model. Do not prepare or publish the admin stub separately.  
**Detection:** README, Hex docs, or proof scripts disagree about required migrations, mounted routes, or supported preview behavior.

### 17. Telemetry Claims Become Observability Claims

**What goes wrong:** New events imply Rulestead measures real user populations or rollout health itself.  
**Prevention:** Phase 56 should document events as admin/audit/support signals only. Host apps still own metrics stores, baselines, dashboards, and identity resolution.  
**Detection:** Telemetry docs promise affected-user counts, anomaly detection, or dashboards owned by Rulestead.

## Phase-Specific Warning Map

| Phase Topic | Warning Signs | Prevention Strategy |
|-------------|---------------|---------------------|
| Phase 53: impact preview contract | exact-sounding user counts; no preview hash; no source timestamp; no active rollout warning | typed preview payload with basis, uncertainty, tenant/env scope, affected references, redaction, version/hash |
| Phase 54: dependency visibility and manifests | UI-only graph; no promotion/import closure; same-name dependency matching | core dependency validator used by compare, promotion, import/export, replay, and apply |
| Phase 55: mounted operator ergonomics | one-click bulk mutation; missing policy checks; empty happy-state fallbacks | preview -> confirm -> audit, progressive disclosure, authorized dependency views, fallback copy for missing data |
| Phase 56: proof and support truth | docs outrun tests; package docs disagree; Phase 8-only docs appear | repo-root proof commands, mounted contract tests, docs/support-truth checks, linked-version release verification |

## Support-Truth Boundaries

- Rulestead can show authored dependency references, deterministic simulation against supplied contexts, redacted sample previews, snapshot/explain traces, and audit evidence.
- Rulestead cannot claim authoritative affected-user counts unless the host provides bounded sample/impression data through existing seams.
- Rulestead must not fetch host identity directories, tenant catalogs, metrics warehouses, or observability backends to make targeting previews look smarter.
- `rulestead` owns domain contracts, validation, snapshot compilation, explain traces, manifests, and audit data.
- `rulestead_admin` owns mounted UX, policy-mediated views, confirmation flows, and operator copy.
- Host apps own auth, identity, tenant truth, observability, and production policy decisions.

## Sources

- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/ROADMAP.md`
- `.planning/milestones/v1.5.0-REQUIREMENTS.md`
- `.planning/research/v1.2.0-reusable-targeting-assets-memo.md`
- `prompts/rulestead-security-privacy-and-threat-model.md`
- `prompts/rulestead-telemetry-observability-and-audit.md`
- `prompts/rulestead-release-engineering-and-ci.md`
- `prompts/rulestead-domain-language-field-guide.md`
- `prompts/rulestead-admin-ux-and-operator-ia.md`
