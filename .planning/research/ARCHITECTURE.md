# Architecture Research: v1.6.0 Reusable Targeting Deepening

**Project:** Rulestead v1.6.0 - Reusable Targeting Deepening  
**Researched:** 2026-05-27  
**Confidence:** HIGH for repo-local integration points; MEDIUM for exact phase split until requirements are frozen.

## Architectural Thesis

Reusable audiences already exist in the runtime, mounted rules UI, compare, and manifest surfaces. v1.6.0 should not introduce a new targeting subsystem. It should add a small dependency/impact read model over existing authored state, then thread that projection into admin review, explainability, promotion, and manifest validation.

The runtime hot path should remain deterministic and snapshot-backed. Audience definitions may become more visible and safer to edit, but evaluation must continue to consume compiled snapshot payloads rather than live database lookups or inheritance graphs.

## Current Integration Points

| Surface | Existing Component | v1.6.0 Integration |
|---------|--------------------|--------------------|
| Audience authored state | `Rulestead.Audience` | Keep as the canonical shared targeting asset. Add dependency metadata/projections outside evaluation. |
| Rule references | `Rulestead.Ruleset.Rule` with `:segment_match`, `audience_key` | Preserve explicit key references. Do not add nested audience inheritance or templates. |
| Runtime explanation | `Rulestead.Explainer` and evaluation traces | Extend traces/summaries to name matched/skipped reusable audience references and missing-audience failures. |
| Impact/dependency preview | New read-only domain projection | Add `Rulestead.Targeting.DependencyGraph` or equivalent read service over authored flags/rulesets/audiences. |
| Mutations | Existing `Ecto.Multi` command/store patterns | Audience edits/archive/publish should compute impact before mutation and audit the accepted preview token. |
| Promotion compare | `Rulestead.Promotion.Compare` dependency closure | Expand `audience:*` closure from key list into reference counts, affected flags, blockers, and stale preview detection. |
| Manifest import/export | `Rulestead.Manifest.*` | Include/validate audience dependency closure deterministically; fail preview/apply on missing or incompatible audience refs. |
| Mounted rules UI | `RulesteadAdmin.Live.FlagLive.Rules` and `RuleEditorComponents` | Add usage badges, affected flags links, and pre-save warnings near audience picker. |
| Simulation | `RulesteadAdmin.Live.FlagLive.Simulate` | Show audience-level match explanation inside existing trace, not a separate debugger. |
| Audit/timeline | Existing append-only audit surfaces | Record audience edit impact summary and automatic denied/blocked decisions with redacted details. |

## New vs Modified Components

### New

| Component | Package | Responsibility |
|-----------|---------|----------------|
| `Rulestead.Targeting.DependencyGraph` | `rulestead` | Pure projection from authored flags/rulesets/audiences to references, reverse references, missing refs, archived refs, and impact counts. |
| `Rulestead.Targeting.ImpactPreview` | `rulestead` | Builds deterministic before/after preview for audience changes using authored state fingerprints and optional bounded sample contexts. |
| Audience impact command structs | `rulestead` | Commands such as preview/edit/archive audience with compare-token style staleness protection. |
| Audience dependency fixtures/tests | both | Contract fixtures proving snapshot determinism, missing-ref fail-closed behavior, and admin visibility. |

### Modified

| Component | Package | Change |
|-----------|---------|--------|
| `Rulestead.Audience` | `rulestead` | Add validations needed for edit/archive safety; avoid adding runtime-only fields. |
| Ruleset validation | `rulestead` | Reuse dependency graph checks so `segment_match` remains explicit and fail-closed. |
| Snapshot compiler/store publication | `rulestead` | Ensure compiled snapshots include enough audience definition data for local deterministic evaluation and explain traces. |
| `Rulestead.Explainer` | `rulestead` | Include audience reference names and match/miss reasons in concise operator language. |
| `Rulestead.Promotion.Compare` | `rulestead` | Replace flat audience dependency list with richer, stable dependency findings while keeping schema-versioned output. |
| `Rulestead.Manifest.Validate/Diff/Import/Export` | `rulestead` | Validate declared and implied audience dependencies with stable semantic keys. |
| Mounted rules and compare LiveViews | `rulestead_admin` | Surface impact/dependency data inside existing mounted workflows and policy state. |
| Timeline/audit components | `rulestead_admin` | Render audience impact summaries without raw condition payload overload. |

## Data Flow Changes

### Audience Edit Preview

```text
operator edits audience draft
  -> rulestead_admin validates form and asks rulestead for impact preview
  -> ImpactPreview loads authored audiences + active/draft rulesets
  -> DependencyGraph computes reverse references and affected flags
  -> optional sample contexts are evaluated against before/after compiled payloads
  -> preview returns impact_token, affected flags, changed decisions, blockers
  -> operator confirms
  -> Ecto.Multi verifies impact_token/fingerprint, writes audience change, audit row, snapshot publication trigger
```

### Runtime Evaluation

```text
published authored state
  -> snapshot compiler embeds resolved audience definitions by key
  -> local evaluator consumes snapshot only
  -> explain trace records audience_key, audience_found?, audience_matched?, condition reasons
  -> runtime_explain adds existing environment/snapshot metadata
```

No runtime database dependency should be introduced for audience lookups.

### Promotion and Manifest

```text
compare/export/import input
  -> collect flag ruleset audience_key refs
  -> resolve against source/target/manifest audience catalog
  -> emit deterministic dependency closure and findings
  -> block apply on missing, archived, incompatible, or stale audience refs
  -> apply through existing governed/audited mutation path
```

## Patterns to Follow

### Read-Only Projection First

Build dependency visibility as a pure projection before adding mutation UX. It can be tested with authored payload fixtures, reused by compare/manifest/admin, and kept out of the runtime evaluator.

### Tokened Preview Before Mutation

Mirror compare-token behavior for audience edits: preview returns a token over audience key, current audience fingerprint, referenced ruleset fingerprints, environment/tenant scope, and intended change. Apply refuses stale tokens.

### Snapshot-Compiled Resolution

Audience references should resolve at snapshot compile/publication time. Missing or incompatible references should fail closed in validation/publication paths and explain clearly at runtime if an older snapshot contains a bad reference.

## Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | Use Instead |
|--------------|---------|-------------|
| Live audience inheritance graph | Creates hidden blast radius and hard-to-debug precedence | Explicit `audience_key` refs plus reverse-reference projection |
| Runtime DB lookup for audience definitions | Breaks local deterministic snapshot evaluation | Embed resolved definitions in snapshots |
| Template engine for targeting | Expands scope beyond deepening shipped audiences | Draft-only audience edits with previews |
| Separate audience control plane | Violates mounted companion boundary | Add audience visibility inside existing admin IA |
| Silent archive of referenced audiences | Breaks flags unexpectedly | Block or require explicit confirm with impact token and audit reason |

## Suggested Build Order

1. **Dependency projection in `rulestead`** - implement pure graph/reference functions and tests over audiences, rulesets, tenant scope, archived state, and missing refs.
2. **Runtime explain enrichment** - extend snapshot payload/trace shape so audience match/miss reasons are deterministic and local.
3. **Impact preview commands** - add before/after preview and staleness token; keep mutation behind existing `Ecto.Multi` and audit patterns.
4. **Compare/manifest integration** - upgrade dependency findings and validation so promotion/import cannot bypass audience safety.
5. **Mounted admin ergonomics** - add reference counts, affected flag lists, preview-confirm flow, and simulation explanation in existing LiveViews.
6. **Proof/docs closure** - add bounded proof scope for reusable targeting deepening and keep support truth aligned across both packages.

## Determinism Requirements

- Preview samples must be explicit inputs or stable fixtures, never analytics-derived hidden cohorts.
- Snapshot compilation remains the only runtime resolution boundary.
- Dependency output must sort by stable semantic keys, not database IDs.
- Tokens/fingerprints must include audience definitions, referencing rulesets, environment key, tenant key, and requested operation.
- Promotion/import/export must preserve authored intent, not compiled snapshot bytes.

## Sources

- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/milestones/v1.5.0-ROADMAP.md`
- `prompts/rulestead-host-app-integration-seam.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `rulestead/lib/rulestead/audience.ex`
- `rulestead/lib/rulestead/ruleset/rule.ex`
- `rulestead/lib/rulestead/explainer.ex`
- `rulestead/lib/rulestead/promotion/compare.ex`
- `rulestead/lib/rulestead/manifest/export.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex`
