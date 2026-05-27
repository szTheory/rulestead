# Project Research Summary

**Project:** Rulestead v1.6.0 - Reusable Targeting Deepening
**Domain:** Elixir-native feature flag platform; reusable audience targeting safety, dependency visibility, and mounted operator workflows
**Researched:** 2026-05-27
**Confidence:** HIGH for repo-local direction; MEDIUM for exact phase split until requirements are frozen

## Executive Summary

Rulestead is a linked sibling-package feature-management platform: `rulestead` owns deterministic runtime/domain contracts, while `rulestead_admin` owns mounted operator workflows. v1.6.0 should deepen already-shipped reusable `Audience` targeting, not introduce a new targeting primitive or standalone control plane. The product gap is blast-radius safety: shared audiences are useful only if operators can see dependencies, preview impact, confirm risky edits, and explain outcomes.

The recommended approach is to add internal domain surfaces, not new external stack. Build a pure dependency/reference projection over authored state, use it for impact previews and mutation blockers, compile resolved audience data into snapshots for runtime evaluation, and thread richer audience findings through promotion, manifest, compare, explain, audit, and mounted admin screens.

The main risks are silent broad edits, false precision in impact previews, runtime DB/admin lookups, hidden inheritance graphs, tenant/environment ambiguity, and support claims that imply Rulestead owns identity or observability truth. Mitigate by keeping previews scoped and basis-labeled, using stale tokens and fingerprints before mutation, failing closed on missing/archived/incompatible references, preserving snapshot-local evaluation, and keeping host-owned truth boundaries explicit.

## Key Findings

### Recommended Stack

No new external library or service stack should be added for v1.6.0. Existing Elixir, Ecto, PostgreSQL, Phoenix LiveView, Jason, Telemetry, ExUnit, and StreamData are sufficient. The "stack additions" should be internal modules, command contracts, reference rows/indexes, snapshot schema metadata, and mounted LiveViews.

**Core technologies:**
- Elixir: pure dependency, preview, and explain modules - deterministic, testable, service-free.
- Ecto / Ecto SQL: mutation envelopes - validate dependencies, verify tokens, write authored state, audit, and trigger snapshot publication in one transaction.
- PostgreSQL: reference index/read model - query "used by" counts and dependency lists without scanning JSON on every render.
- Phoenix LiveView: mounted preview and dependency workflows - async request-time previews, confirmation screens, and policy-aware dependency display.
- Jason: manifest/import/export and preview payloads - existing JSON contracts are enough.
- Telemetry: bounded preview duration/count/error events - host apps still own observability.
- ExUnit / StreamData: property and contract tests - prove dependency closure, snapshot determinism, trace stability, and fail-closed behavior.

**Do not add:** graph libraries, Broadway/Oban as a new requirement, external search/indexing, charting libraries, Nx/statistics engines, OpenTelemetry adapters, template/workflow engines, standalone admin/control-plane infrastructure, Phase 8 docs, or admin publishing prep.

### Expected Features

**Must have (table stakes):**
- Audience reference inventory and counts on list/detail.
- Impact preview before audience definition save, archive/delete, or protected mutation.
- Blocking archive/delete when active references exist, with links to dependents.
- Stale preview token and concurrency guard over audience, referenced rulesets, scope, and intended change.
- Audit events containing preview summary, impacted references, actor, reason, fingerprints, tenant/environment scope, and blockers/warnings.
- Promotion/import/compare findings that show readable audience dependencies, drift, missing/archived/incompatible refs, and blockers.
- Explain traces that include audience key, version/hash, match/miss/failure reason, and redacted predicate summary.
- Tenant and environment scope visible in every preview, dependency query, confirmation, and audit path.

**Should have (differentiators):**
- Actor sample delta preview from explicit sample contexts, clearly labeled as sample-based rather than population truth.
- Flat "used by" dependency map grouped by flag, ruleset, rollout/lifecycle state, environment, and tenant.
- Safe edit modes that distinguish metadata-only edits from evaluation-affecting definition edits.
- Audience drift callouts in compare/promotion.
- Explain permalink that expands matched audience predicates at snapshot version.
- Governed audience updates for protected environments once preview tokens exist.

**Defer:**
- Draft targeting presets unless safety surfaces are already stable; presets must generate drafts only.
- Full graph visualization.
- Live-linked rollout/targeting templates.
- Hidden audience inheritance or nested audience graphs.
- Cross-environment automatic audience creation.
- Tenant hierarchy or implicit "all tenants" shortcuts.
- Observability-backed impact estimates or authoritative affected-user counts.
- AI-generated audience rules.

### Architecture Approach

Build a read-only dependency projection first, then reuse it everywhere. Runtime evaluation must remain snapshot-backed and local: dependency visibility and admin previews may query authored state, but the evaluator must consume compiled audience definitions from immutable snapshots and produce structured explain traces.

**Major components:**
1. `Rulestead.Targeting.DependencyGraph` or equivalent - authored-state projection for references, reverse references, counts, missing/archived refs, tenant/env scope, and rollout/lifecycle context.
2. `Rulestead.Targeting.ImpactPreview` - deterministic before/after preview with blockers, warnings, affected flags/rulesets, optional explicit sample deltas, preview basis, and impact token.
3. Audience mutation commands - Ecto.Multi-backed edit/archive/apply paths that validate token freshness, dependency closure, policy, audit evidence, and snapshot publication.
4. Snapshot/explain enrichment - compiled audience definitions and structured trace nodes for audience match/miss/failure without runtime DB lookups.
5. Promotion/manifest/compare integration - stable dependency closure and drift/blocker findings for import/export, promotion preview/apply, replay, and reapply.
6. Mounted admin workflows - used-by lists, reference counts, preview-confirm-audit flows, safe fallback copy, authorized dependency display, and explain/simulate carry-through.

### Critical Pitfalls

1. **Silent blast-radius expansion** - require before-save preview, used-by counts, affected flags/rollouts, tenant/env scope, and reasoned confirmation.
2. **False precision in previews** - label preview basis: authored refs, explicit samples, host-supplied impression summary, or unavailable. Never claim exact affected users unless the host supplied bounded evidence.
3. **Runtime DB/admin lookups** - compile audience definitions into snapshots; evaluator code must not call Repo, admin contexts, dependency graph services, or host callbacks while deciding a flag.
4. **Hidden inheritance graphs** - keep one-level explicit `audience_key` references; presets, if any, generate drafts only.
5. **Promotion/manifest bypass** - dependency closure must be core validation, not UI-only; fail closed on missing, archived, stale, incompatible, or tenant-mismatched audience refs.
6. **Policy/privacy leaks** - authorize dependency reads per referenced resource and redact hidden references, raw actor identifiers, emails, IPs, and sensitive traits.
7. **Support-truth drift** - docs, tests, mounted contract proof, telemetry copy, and package boundaries must agree before release claims are made.

## Implications for Roadmap

Based on research, suggested v1.6.0 phase structure:

### Phase 53: Impact Preview Contract
**Rationale:** Preview semantics define the safety contract and must be stable before admin UX or mutation flows rely on them.
**Delivers:** `ImpactPreview` result shape, basis/uncertainty labeling, tenant/env scope, affected references, stale token/fingerprint design, redaction rules, active rollout/lifecycle warnings, and tests for deterministic previews.
**Addresses:** impact preview before save, token guard, audit summary basis, explain trace requirements.
**Avoids:** false precision, privacy leaks, stale previews, runtime nondeterminism.

### Phase 54: Dependency Truth And Promotion Safety
**Rationale:** Dependency visibility must be core truth used by compare, manifests, promotion, and archive blockers, not a mounted UI convenience.
**Delivers:** dependency graph/read model, reference counts, reverse-reference lists, missing/archived/incompatible validation, archive/delete blockers, promotion/import/export/compare dependency findings, and stable sorting by semantic keys.
**Uses:** Ecto/PostgreSQL reference rows or indexed projection; ExUnit/StreamData for closure invariants.
**Avoids:** broken references, hidden blast radius, same-name drift, tenant/environment mismatch, JSON-scan scaling problems.

### Phase 55: Mounted Operator Workflows
**Rationale:** Once core truth is available, the admin should make it scannable and actionable without creating new automation paths.
**Delivers:** used-by badges and detail pages, preview-confirm-audit flow for audience edits, authorized dependency views, readable blockers, promotion/import UI rows, explain/simulate audience carry-through, and bounded fallback copy.
**Addresses:** reference counts, dependency detail, safe edit modes, explain permalink foundations, guarded rollout warnings.
**Avoids:** bulk automation, policy bypass, support confusion, noisy graph visualizations, hidden all-tenant actions.

### Phase 56: Proof, Docs, And Support Truth
**Rationale:** Reusable targeting touches runtime, admin, manifests, audit, and support copy; release truth must be closed after implementation.
**Delivers:** repo-root proof commands, mounted contract tests, manifest/promotion tests, docs that define support boundaries, telemetry wording, migration/install truth, and linked-version package verification.
**Addresses:** support-truth boundaries and release readiness.
**Avoids:** docs outrunning tests, Phase 8-only docs, unsupported observability/identity claims, sibling-package mismatch.

### Phase Ordering Rationale

- Start with the preview contract because every risky mutation and support claim depends on the result shape, token semantics, redaction rules, and preview basis.
- Build dependency truth next so archive blockers, promotion/import validation, compare findings, and admin "used by" surfaces share one core source.
- Add mounted ergonomics after core semantics are stable; UI should render truth and guide review, not invent dependency logic.
- Close with proof/docs because the milestone crosses package boundaries and can easily drift into unsupported claims.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 53:** token/fingerprint composition, preview basis copy, redaction boundaries, and active rollout interaction details.
- **Phase 54:** schema/read-model choice for reference rows versus derived queries, manifest compatibility checks, and promotion drift semantics.
- **Phase 55:** policy-mediated dependency display and LiveView workflow details for stale preview/conflict recovery.

Phases with standard patterns (skip research-phase unless scope changes):
- **Phase 56:** proof/docs/support-truth closure follows established v1.3-v1.5 patterns.
- **Basic stack selection:** no new library research needed unless a future requirement explicitly demands graphing, jobs, analytics, or external search.

## Candidate Requirement Categories for v1.6.0

- **DEP:** Core audience dependency truth, reference counts, reverse references, and fail-closed validation.
- **PRE:** Bounded impact preview contract, basis/uncertainty labeling, stale-token validation, sample-delta semantics, and redaction.
- **MUT:** Safe audience edit/archive/delete commands with blockers, audit evidence, snapshot publication, and protected-environment handling.
- **PROM:** Promotion, compare, manifest import/export, replay, and reapply dependency closure with drift/blocker findings.
- **EXP:** Snapshot-local explain trace enrichment for reusable audiences.
- **ADM:** Mounted admin used-by views, preview-confirm flows, readable blockers, policy-aware dependency display, and simulation/explain carry-through.
- **TEN:** Explicit tenant/environment scope in all dependency, preview, mutation, promotion, and audit payloads.
- **SUP:** Docs, telemetry wording, package-boundary truth, proof commands, and support boundaries.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Repo-local dependency files and current architecture show existing Elixir/Ecto/Phoenix/LiveView stack is enough. |
| Features | HIGH | All research agrees table stakes are dependency inventory, previews, blockers, explainability, promotion/import visibility, and audit evidence. |
| Architecture | HIGH | Existing audience, ruleset, snapshot, manifest, promotion, audit, and mounted admin seams give clear integration points. |
| Pitfalls | HIGH | Risks are repeated across project constraints and prior milestones: deterministic runtime, host-owned truth, support-truth closure, and mounted sibling-package boundaries. |
| Phase split | MEDIUM | Phase 53-56 shape is strongly suggested but final numbering and grouping should be confirmed during requirements. |

**Overall confidence:** HIGH

### Gaps to Address

- Reference read model design: decide whether to persist `audience_references` rows, derive rows at publish/import, or use indexed authored-state joins.
- Preview token details: define exact fingerprint inputs and stale/conflict behavior.
- Sample preview semantics: define allowed explicit sample inputs, redaction, and copy for unavailable/partial data.
- Authorization for dependency reads: specify how hidden references are counted without leaking forbidden flag/tenant details.
- Guarded rollout linkage: decide which rollout/lifecycle metadata appears in preview without adding observability dashboards.
- Snapshot schema bump: define minimal payload additions for compiled audience definitions and trace metadata.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` - stack posture, package boundaries, integration points, non-recommendations.
- `.planning/research/FEATURES.md` - table stakes, differentiators, anti-features, MVP slicing.
- `.planning/research/ARCHITECTURE.md` - component boundaries, data flow, build order, determinism requirements.
- `.planning/research/PITFALLS.md` - critical watch-outs, phase warnings, support-truth boundaries.
- `.planning/PROJECT.md` - active v1.6.0 goal, requirements posture, constraints, key decisions.
- `.planning/MILESTONE-ARC.md` - active milestone rationale, guardrails, cross-candidate architecture guidance.

### Secondary (MEDIUM confidence)
- `.planning/research/v1.2.0-reusable-targeting-assets-memo.md` - prior reusable targeting context referenced by current research.
- `prompts/rulestead-*` anchor docs - inherited engineering, admin UX, testing, host integration, security/privacy, telemetry, release guidance.
- Repo files cited by research: `rulestead/lib/rulestead/audience.ex`, `ruleset/rule.ex`, `explainer.ex`, `promotion/compare.ex`, `manifest/*`, and mounted admin LiveViews.

---
*Research completed: 2026-05-27*
*Ready for requirements and roadmap: yes*
