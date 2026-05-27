# Feature Research: Rulestead v1.6.0 - Reusable Targeting Deepening

**Domain:** Impact previews, dependency visibility, and bounded operator ergonomics for shipped reusable `Audience` targeting  
**Researched:** 2026-05-27  
**Confidence:** HIGH for repo-local scope; MEDIUM for ecosystem prioritization based on prior memo

## Scope Position

Reusable audience targeting is already shipped across runtime rules, admin compare, promotion, manifest import/export, explainability, tenancy, lifecycle, audit, and guarded rollout foundations. v1.6.0 should not introduce audiences as a new product wedge. It should make existing audience reuse safer to edit, easier to inspect, and harder to misunderstand.

The central product rule: editing one `Audience` must never feel like editing one isolated row when it can change many flags. Operators need preview, dependency visibility, confirmation, and audit context before mutation. Runtime evaluation must remain deterministic and snapshot-local.

## Table Stakes

Missing these makes reusable targeting feel unsafe or incomplete.

| Feature | Category | Why Expected | Complexity | Existing Dependencies | Package Boundary |
|---------|----------|--------------|------------|-----------------------|------------------|
| Audience reference inventory | Dependency visibility | Operators must see every flag/ruleset/environment that references an audience before editing it. | Med | `audience_key` on rules, promotion `dependency_closure_keys`, manifest dependency closure | `rulestead` computes references; `rulestead_admin` renders list/detail |
| Audience impact preview before save | Impact preview | Shared targeting creates blast radius; edits need a pre-commit "what changes" review. | High | authored-state reads, ruleset simulation/compare concepts, audit reason requirements | `rulestead` produces preview result; `rulestead_admin` owns review/confirm UI |
| Reference counts on audience list/detail | Dependency visibility | A list that says "used by 14 flags" prevents accidental cleanup or edits. | Low | existing list audiences store command, ruleset authored state | `rulestead` exposes count metadata; `rulestead_admin` displays and filters |
| Blocking archive/delete when referenced | Operator safety | Archiving an audience still referenced by active rules would break or fail closed unexpectedly. | Med | audience lifecycle/archive event, manifest missing/archived dependency validation | `rulestead` validates; `rulestead_admin` explains blocker and links dependents |
| Explicit dependency findings in promotion/import UI | Dependency visibility | Promotion and import already compute closures; operators need readable audience names, not only counts. | Med | `Promotion.Compare`, `Manifest.Import`, compare token metadata | `rulestead` enriches findings; `rulestead_admin` displays dependency rows |
| Explain traces include audience match detail | Explainability | Support needs to answer "why did this actor match?" without mentally expanding hidden audience logic. | Med | evaluator explain trace, `segment_match` strategy, canonical `Audience` language | `rulestead` emits trace data; `rulestead_admin` renders plain-English and technical trace |
| Tenant/environment scope displayed everywhere | Operator safety | Audience impact differs by tenant and environment; hidden scope causes false confidence. | Med | v1.1 tenancy helpers, environment compare state, URL-scoped admin context | Both packages preserve scope; admin keeps it visible in flows |
| Stale preview token / concurrency guard | Impact preview | An audience can change between preview and apply; confirmed edits need drift detection. | Med | compare/import token patterns, authored fingerprints | `rulestead` creates and validates token; `rulestead_admin` handles stale state |
| Audit event includes preview summary | Operator safety | After the change, reviewers need to know what impact was accepted, not only field diffs. | Med | audit event contract, reason fields, governed mutation pattern | `rulestead` writes audit metadata; `rulestead_admin` shows it in timeline |

## Differentiators

These make the feature feel mature without widening Rulestead into a workflow or observability product.

| Feature | Value Proposition | Complexity | Dependencies | Boundary |
|---------|-------------------|------------|--------------|----------|
| Actor sample delta preview | Shows how a proposed audience edit changes sample actors or saved preview contexts. | High | existing simulate/explain paths; host-provided context samples if available | Core preview engine accepts explicit samples; admin manages sample input/results |
| "Used by" graph as a flat dependency map | Helps tech leads understand blast radius without creating live inheritance semantics. | Med | dependency closure, rule metadata, flag ownership/lifecycle metadata | Core returns one-level edges; admin renders grouped table/map |
| Safe edit modes | Separate low-risk metadata edits from definition edits that affect evaluation. | Med | audience schema, audit classifications, preview engine | Core classifies impact; admin uses clearer confirmation tiers |
| Audience drift callouts in compare | Shows when same audience key differs across environments before promotion. | High | manifest export/import, promotion compare, audience authored state | Core compare adds audience-level findings; admin renders alongside flag results |
| Explain permalink that expands audience predicates | Support can share evidence showing matched rule plus matched audience definition at snapshot version. | Med | explain page, snapshot versioning, redaction rules | Core trace payload; admin permalink and redacted presentation |
| Governed audience updates for protected environments | Reuses existing governed-change posture for high-blast-radius audience edits. | High | change requests, approvals, protected environment logic, audit | Core command validation; admin routes through existing governance envelope |
| Bounded targeting presets as draft generators | Speeds common authoring patterns only by generating editable draft rules/audiences. | Med | existing draft rulesets/audience create flow | Admin authoring convenience; core only sees normal drafts |

## Anti-Features

Do not build these in v1.6.0.

| Anti-Feature | Why Avoid | Do Instead |
|--------------|-----------|------------|
| Hidden audience inheritance graphs | Operators cannot reason about blast radius or final evaluation order. Violates quality gate. | Keep `Audience -> Rule` references one-level and explicit. |
| Live-linked rollout or targeting templates | Turns a reusable asset into a workflow engine and creates surprise propagation. | Presets may generate drafts only; no ongoing inheritance. |
| Cross-environment automatic audience creation | Same key can hide different definitions and scope assumptions. | Promotion/import must validate dependencies and surface blockers. |
| Tenant hierarchy or "all tenants" shortcuts | Conflicts with explicit, fail-closed tenancy posture. | Require visible tenant scope and explicit tenant-aware preview. |
| Runtime admin lookups during evaluation | Breaks local deterministic snapshot evaluation. | Compile audience definitions into immutable snapshots. |
| Observability-backed impact estimates | Pulls Rulestead into analytics/observability ownership. | Preview authored dependencies and explicit samples only. |
| AI-generated audience rules | Too much hidden intent and policy risk for this milestone. | Provide clear predicates, previews, and audit reasons. |
| Full graph visualizer | High polish cost and encourages graph mental model. | Use grouped tables, filters, and one-level dependency map. |

## Feature Dependencies

```text
Audience reference inventory -> Reference counts
Audience reference inventory -> Blocking archive/delete when referenced
Audience reference inventory -> Impact preview before save
Impact preview before save -> Preview token / concurrency guard
Impact preview before save -> Audit event includes preview summary
Impact preview before save -> Governed audience updates
Dependency closure enrichment -> Promotion/import readable dependency findings
Explain trace audience detail -> Explain permalink that expands audience predicates
Audience authored state compare -> Audience drift callouts in compare
```

## MVP Recommendation

Prioritize:

1. Audience reference inventory with reference counts on list/detail.
2. Audience impact preview before definition save, including scope, affected flags, changed rule paths, stale-token validation, and audit summary.
3. Blocking archive/delete for referenced audiences with links to dependents.
4. Promotion/import dependency visibility upgraded from counts to readable audience rows and blockers.
5. Explain trace carry-through for matched audiences.

Defer:

- Actor sample delta preview: valuable, but only after dependency inventory and mutation safety are reliable.
- Governed audience updates: likely needed for protected production edits, but can be a second slice after preview tokens exist.
- Draft targeting presets: optional convenience; should not ship until the safety surface is complete.
- Graph visualization: not needed; a grouped table/map is clearer and safer.

## Package Boundaries

| Package | Owns | Must Not Own |
|---------|------|--------------|
| `rulestead` | Audience reference queries, impact preview result shape, dependency closure enrichment, validation, snapshot compilation, explain trace data, audit metadata. | Admin-specific copy, visual graph UI, host identity/team directory, observability-derived estimates. |
| `rulestead_admin` | Audience list/detail ergonomics, preview/confirm workflows, dependency tables, compare/import presentation, explain UI, progressive disclosure. | Runtime evaluation semantics, dependency truth, hidden state not represented in core commands. |

## Roadmap Slicing Guidance

1. **Dependency Inventory Foundation** - Add core reference query/counts and admin "used by" display. Low-to-med risk and unlocks all other work.
2. **Mutation Safety Preview** - Add audience edit preview, token validation, audit summary, and archive blockers. Highest-risk but central value.
3. **Dependency Visibility Everywhere** - Enrich promotion/import/compare surfaces with readable audience dependency rows and drift findings.
4. **Explainability and Operator Polish** - Expand explain traces and admin ergonomics after the core safety loop is stable.
5. **Optional Draft Presets** - Only if prior slices stay bounded and no hidden inheritance semantics are introduced.

## Sources

- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/ROADMAP.md`
- `.planning/research/v1.2.0-reusable-targeting-assets-memo.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/rulestead-domain-language-field-guide.md`
- `rulestead/lib/rulestead/ruleset/rule.ex`
- `rulestead/lib/rulestead/promotion/compare.ex`
- `rulestead/lib/rulestead/manifest/import.ex`
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`
