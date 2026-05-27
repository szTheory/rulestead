# Phase 54: Dependency Truth And Promotion Safety - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver one core dependency-truth contract for reusable audiences so operators and support can trust inventory reads, mutation blockers, promotion/compare/replay paths, and manifest paths to fail closed with explicit scope semantics.

</domain>

<decisions>
## Implementation Decisions

### Dependency Inventory Model
- **D-01:** Phase 54 will establish a persisted, core-owned audience dependency inventory/read model as the canonical dependency source, rather than relying on ad hoc per-request reconstruction.
- **D-02:** Inventory rows must carry stable reference identity (`environment_key`, `tenant_key`, `flag_key`, `ruleset_version`, `rule_key`, `audience_key`) plus lifecycle and rollout hints needed by operator/support workflows.

### Fail-Closed Validation Contract
- **D-03:** Audience archive/delete and ruleset publish paths must route through one shared dependency validator contract.
- **D-04:** The validator must fail closed on unresolved, archived, incompatible, stale, and tenant-mismatched references before runtime snapshots can publish.

### Promotion, Compare, Replay, And Manifest Dependency Truth
- **D-05:** Environment compare, promotion preview/apply, replay/re-apply, manifest export, manifest import, and manifest validation will read dependency findings from the same dependency-truth contract and fail closed on incompatibilities.

### Scope Semantics And Deterministic Output
- **D-06:** All dependency and impact outputs must include explicit environment and tenant scope fields and use stable semantic sorting so same-name/cross-scope audiences cannot be misread as equivalent.

### Authorization-Safe Read Behavior
- **D-07:** Dependency inventory reads will enforce policy checks and return redacted partial truth for unauthorized resources instead of over-disclosing or fully discarding useful authorized data.

### Public Surface For Downstream Operator Workflows
- **D-08:** Phase 54 will add explicit store/API dependency-inventory read surface(s) with Fake and Ecto parity so Phase 55 does not depend on internal-only seams.

### Claude's Discretion
- Use the narrowest persistence shape that satisfies stable identity, pagination, and indexability requirements (`audience_references` projection table or equivalent indexed projection).
- Choose exact return envelope fields and pagination mechanics, provided they preserve deterministic sorting and explicit scope semantics.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` — Phase 54 goal and success criteria boundary.
- `.planning/REQUIREMENTS.md` — DEP-01 through DEP-04 contracts.
- `.planning/METHODOLOGY.md` — recommendation-first and architect-default discuss lenses used to lock decisions.

### Prior Phase Contracts To Reuse
- `.planning/phases/53-impact-preview-contract/53-RESEARCH.md` — prior recommendation baseline and identified Phase 54 gap around dependency read model.
- `.planning/phases/53-impact-preview-contract/53-PATTERNS.md` — preview fingerprint, transactional apply/audit, and snapshot-local runtime patterns to preserve.
- `.planning/phases/53-impact-preview-contract/53-04-SUMMARY.md` — completed Ecto/Fake/runtime guarantees that Phase 54 should extend, not replace.

### Risk And Pitfall Guidance
- `.planning/research/SUMMARY.md` — dependency-truth focus for v1.6.0.
- `.planning/research/PITFALLS.md` — fail-closed promotion/manifest semantics, tenant scope explicitness, policy-safe reads, and query-scale warnings.

### Core Runtime And Store Integration Seams
- `rulestead/lib/rulestead/store.ex` — store behavior contract to extend.
- `rulestead/lib/rulestead.ex` — public API surface and wrappers.
- `rulestead/lib/rulestead/store/ecto.ex` — Ecto command enforcement, environment version persistence, snapshot publication.
- `rulestead/lib/rulestead/fake.ex` — Fake adapter parity requirements.
- `rulestead/lib/rulestead/targeting/audience_dependencies.ex` — existing dependency key extraction and semantic sorting behavior.
- `rulestead/lib/rulestead/targeting/impact_preview.ex` — preview fingerprint contract for stale-resistance patterns.
- `rulestead/lib/rulestead/promotion/compare.ex` — dependency closure and finding generation.
- `rulestead/lib/rulestead/promotion/apply.ex` — compare-token/fingerprint guardrails for fail-closed apply.
- `rulestead/lib/rulestead/manifest/plan.ex` — manifest dependency closure capture.
- `rulestead/lib/rulestead/manifest/import.ex` — tenant/dependency safety enforcement on import/apply.
- `rulestead/lib/rulestead/manifest/validate.ex` — manifest dependency validation surface.
- `rulestead/lib/rulestead/admin/policy.ex` — policy action boundary.
- `rulestead/lib/rulestead/admin/authorizer.ex` — authorization enforcement seam.
- `rulestead/lib/rulestead/admin/redaction.ex` — redaction strategy utilities.
- `rulestead/lib/rulestead/environment_version.ex` — dependency closure persistence contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Targeting.AudienceDependencies` already produces normalized, deduped, semantically sorted audience reference keys.
- `Rulestead.Promotion.Compare` and `Rulestead.Promotion.Apply` already enforce compare-token/fingerprint-style fail-closed safety that Phase 54 can mirror for dependency truth.
- `Rulestead.Manifest.Plan` and `Rulestead.Manifest.Import` already carry dependency closure and tenant findings, offering a direct integration seam.
- `Rulestead.Store.Ecto` already persists environment versions with `dependency_closure_keys` and publishes runtime snapshots with compiled audience definitions.

### Established Patterns
- Command surfaces return structured result/findings envelopes rather than ad hoc errors, enabling support-readable blocker output.
- Ecto write paths use `Ecto.Multi` + audit inserts for transactional mutation evidence.
- Runtime evaluation remains snapshot-local; dependency validation must happen before publish/apply, not during evaluation.
- Fake and Ecto adapters are kept in behavior parity and must remain lockstep.

### Integration Points
- Extend store behavior and root API for dependency-inventory reads and shared validation entrypoints.
- Wire shared dependency validator into ruleset publish, audience mutation apply, promotion apply, and manifest apply/validate paths.
- Reuse admin policy + redaction seams when returning dependency inventory/finding data.
- Preserve compare/import/export plan artifacts as the transport for dependency findings across CLI/automation paths.

</code_context>

<specifics>
## Specific Ideas

No additional user corrections were required; the recommendation-first assumption set was confirmed as the implementation baseline.

</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

</deferred>

---

*Phase: 54-dependency-truth-and-promotion-safety*
*Context gathered: 2026-05-27*
