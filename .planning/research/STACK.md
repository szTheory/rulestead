# Stack: v1.6.0 Reusable Targeting Deepening

**Project:** Rulestead
**Milestone:** v1.6.0 - Reusable Targeting Deepening
**Researched:** 2026-05-27
**Question:** What stack additions or changes are needed for reusable targeting impact previews, dependency visibility, and explainability?
**Confidence:** HIGH for repo-local stack guidance; MEDIUM for ecosystem analogies from prior research.

## Recommendation

Do **not** add a new external library stack for v1.6.0. The current Elixir/Phoenix/Ecto/LiveView stack already has the right primitives. The needed "stack changes" are internal domain surfaces in `rulestead`, mounted workflow surfaces in `rulestead_admin`, and a small authored-state/indexing migration so previews and dependency visibility are cheap, deterministic, and auditable.

The milestone should deepen the existing audience reuse model. The repo already has `Rulestead.Audience`, `segment_match` rules with `audience_key`, snapshot-backed runtime reads, promotion/manifest dependency closure, mounted rules UI audience picking, audit/governance patterns, and code-reference precedent. Build on those; do not introduce a second targeting abstraction.

## Carry Forward

| Technology | Current Posture | Use for v1.6.0 | Why |
|------------|-----------------|----------------|-----|
| Elixir | `~> 1.17` | Pure impact/dependency/explain modules | Keeps preview logic testable and deterministic without service dependencies. |
| Ecto / Ecto SQL | `ecto_sql ~> 3.14`, locked `3.14.0` | Transactional audience edits, reference indexing, audit rows, snapshot publish | `Ecto.Multi` is the right fit for "validate dependencies -> write authored state -> write audit -> publish snapshot" in one mutation envelope. |
| PostgreSQL via Postgrex | Existing runtime/admin persistence | Indexed audience reference table or derived reference rows | Dependency visibility should be queryable, not repeatedly inferred from opaque JSON in every admin render. |
| Jason | `~> 1.4`, locked `1.4.5` | Manifest/export/import and preview payloads | Existing JSON contract is sufficient; no schema registry dependency needed. |
| Phoenix / LiveView | admin locked Phoenix `1.8.7`, LiveView `1.1.30` | Impact preview screens, "used by" lists, async sample previews | LiveView already supports async assigns/streams and cancellation, which matches bounded preview jobs. |
| Telemetry | locked `1.4.2` | Preview duration/count/error events only | Use existing event discipline for operator/debug visibility without making Rulestead an observability product. |
| StreamData / ExUnit | existing test stack | Property tests for dependency closure, deterministic snapshots, explain trace stability | Reusable targeting adds indirection; property tests should guard equivalence and fail-closed behavior. |

## Add Internally

### `rulestead` Core Surfaces

| Addition | Shape | Rationale |
|----------|-------|-----------|
| `Rulestead.Targeting.ImpactPreview` | Pure service module returning counts, referenced flags/rules, before/after decision deltas, blockers, warnings | Centralizes preview semantics for admin, CLI, promotion, and tests. LiveViews should call this; they should not compute impact themselves. |
| `Rulestead.Targeting.Dependencies` | Query/build module for audience -> flag/ruleset/rule references and transitive manifest closure | Makes "used by N flags in env/tenant" a domain fact, not UI scraping. |
| `Rulestead.Targeting.Explain` or extension to `Rulestead.Explainer` | Structured explain trace nodes for `audience_key`, audience match/miss, missing/archived audience failures | Preserves one-click explainability when shared audiences add indirection. |
| Audience mutation command(s) | Existing command/store style with actor, environment, tenant, reason, and expected version/fingerprint | Keeps shared-audience edits inside the established governed/audited mutation model. |
| Reference index migration | `audience_references`-style table or materialized rows maintained at ruleset publish/import time | Querying dependencies from normalized rows is safer and faster than scanning every ruleset JSON at render time. |
| Snapshot schema bump | Compile audience definitions and reference metadata into runtime snapshots | Runtime evaluation must stay local and deterministic; missing dependencies should fail closed before publish/import. |

### `rulestead_admin` Companion Surfaces

| Addition | Shape | Rationale |
|----------|-------|-----------|
| Audience impact preview route | Mounted LiveView under existing admin router | Operators need blast-radius preview before saving shared targeting edits. |
| Audience dependency detail | "Used by" list with flag, environment, tenant, ruleset version, rule key, lifecycle/rollout hints | Dependency visibility is the main safety feature; keep it scannable and shareable through URL params. |
| Rules editor explain carry-through | Show selected audience summary and warn on archived/missing references | Prevents `segment_match` from becoming a hidden rule path. |
| Async preview execution | `assign_async` / `stream_async` with cancel behavior | Large previews should not block mount or imply background automation. |

## Package Boundaries

| Package | Owns | Must Not Own |
|---------|------|--------------|
| `rulestead` | Schemas, migrations, store commands, dependency closure, impact-preview computation, snapshot compilation, runtime evaluation, structured explain data, manifest/promotion validation, telemetry events | Mounted copy, admin navigation, visual diff layout, standalone dashboards |
| `rulestead_admin` | Mounted LiveViews, operator IA, preview/confirm/audit screens, reference-count presentation, fallback copy, policy-aware actions | Targeting semantics, runtime evaluation rules, persistence invariants, dependency graph truth |
| Host app | Auth, RBAC policy implementation, actor/context data, tenant catalog truth, observability/metrics data | Rulestead-owned identity graph, hidden tenant expansion, remote evaluation dependency |

Keep both sibling packages linked-versioned. Do not prepare or publish `rulestead_admin` as a standalone product.

## Integration Points

- **Evaluation:** keep ordered-rule evaluation shape; `segment_match` remains a rule strategy that resolves against compiled snapshot audience data.
- **Snapshots:** bump snapshot payload schema only as needed to include referenced audience definition fingerprints and explain metadata. Runtime reads must not query authored tables or admin state.
- **Authoring:** audience edits run through an `Ecto.Multi` path that validates references, computes impact, writes audit evidence, and publishes/queues a snapshot update.
- **Promotion/import/export:** reuse existing manifest dependency closure. Extend it to surface impact and incompatible audience-definition drift, not just missing/archived dependencies.
- **Explainability:** return structured trace data first, then render human copy in admin/docs. Copy-only explanations will become brittle as dependency surfaces grow.
- **Tenancy/environment:** dependency and impact queries must be scoped explicitly by environment and tenant. No implicit all-tenant preview.
- **Audit:** shared-audience edits need exact impacted references and preview fingerprint in the audit payload, so later operators can replay why a broad edit was allowed.

## Non-Recommendations

| Do Not Add | Why |
|------------|-----|
| Graph libraries such as `libgraph` | Audience dependencies are a small bounded DAG/list problem; adding graph infrastructure increases API surface without meaningful leverage. |
| Broadway, Oban, or a new background-job requirement | Previews should be bounded request-time/admin async work for v1.6.0. Existing snapshot/governance paths can publish changes without a new runtime prerequisite. |
| Search/indexing systems | Reference counts and "used by" lists should come from Ecto/Postgres indexes. External search is disproportionate. |
| D3/Vega/charting libraries | Impact preview is mostly counts, lists, and before/after tables. Keep mounted admin lightweight and static-asset-simple. |
| Nx/statistics engines | This is targeting impact preview, not experimentation analysis or guardrail baseline modeling. |
| OpenTelemetry/backend adapters | Emit existing telemetry-style events only. Host apps own observability backends. |
| Template/workflow engine | Templates, if ever justified, should generate draft rules. v1.6.0 should not create live inheritance or release orchestration. |
| Standalone admin/control plane | Violates the mounted sibling-package release design and current project constraints. |
| Phase 8 docs or publishing prep | Explicitly out of scope for this research and contrary to the current phase boundary. |

## Verification Stack

| Proof | Tooling | Scope |
|-------|---------|-------|
| Dependency closure correctness | ExUnit + property tests | Referenced audiences are complete, stable, environment/tenant scoped, and fail closed when missing/archived. |
| Impact preview determinism | ExUnit + StreamData | Same snapshot/context sample yields same before/after delta and fingerprint. |
| Explain trace carry-through | ExUnit golden-ish assertions | Segment/audience match and miss paths are present in structured trace and rendered admin copy. |
| Mounted workflow | LiveViewTest | Preview -> confirm -> audit for audience edits; missing dependency fallback copy; reference lists. |
| Manifest/promotion safety | Existing manifest/import/promotion tests | Plans block incompatible or unresolved audience dependencies and show actionable findings. |

## Sources

- Repo: `rulestead/mix.exs`, `rulestead/mix.lock`, `rulestead_admin/mix.exs`, `rulestead_admin/mix.lock`
- Repo: `rulestead/lib/rulestead/audience.ex`, `rulestead/lib/rulestead/ruleset/rule.ex`, `rulestead/lib/rulestead/manifest/plan.ex`, `rulestead/lib/rulestead/manifest/import.ex`, `rulestead/lib/rulestead/promotion/compare.ex`
- Planning: `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `.planning/milestones/v1.5.0-REQUIREMENTS.md`
- Prior research: `.planning/research/v1.2.0-reusable-targeting-assets-memo.md`
- Anchor docs: `prompts/rulestead-engineering-dna-from-prior-libs.md`, `prompts/rulestead-admin-ux-and-operator-ia.md`
- Context7 / official docs: Ecto `Ecto.Multi` docs, Phoenix LiveView `assign_async` / `stream_async` / `cancel_async`, Phoenix Router `forward/4`
