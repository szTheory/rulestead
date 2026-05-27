# Phase 54: Dependency Truth And Promotion Safety - Research

**Researched:** 2026-05-27 [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/STATE.md`; `54-CONTEXT.md`]  
**Domain:** Core-owned reusable audience dependency inventory, fail-closed publish/mutation/promotion/manifest safety, policy-safe dependency reads  
**Confidence:** HIGH for repo-local seams and risk posture; MEDIUM for exact command names until plan locking

## User Constraints

- Stay inside Phase 54 boundary: dependency truth and promotion safety, not mounted workflow polish. [VERIFIED: `.planning/ROADMAP.md`]
- Directly satisfy DEP-01 through DEP-04 and Phase 54 success criteria. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`]
- Preserve runtime purity: no DB/admin/host lookups in hot-path evaluation. [VERIFIED: project rules; `rulestead/lib/rulestead/runtime/snapshot.ex`; `rulestead/lib/rulestead/evaluator.ex`]
- Keep host-owned auth model and mounted admin boundary; no standalone auth/admin stack. [VERIFIED: project rules; `rulestead/lib/rulestead/admin/policy.ex`]
- Keep PII out of telemetry/audit surfaces and use redaction seams. [VERIFIED: project rules; `rulestead/lib/rulestead/admin/redaction.ex`; `rulestead/lib/rulestead/audit_event.ex`]
- Preserve linked sibling-package contract: core domain truth in `rulestead`, presentation in `rulestead_admin`. [VERIFIED: `.planning/REQUIREMENTS.md`; project rules]

<phase_requirements>

## Phase Requirements

| ID | Requirement | Recommended Core Seams | Proof Targets |
|----|-------------|------------------------|---------------|
| DEP-01 | Queryable audience reference inventory with stable counts, metadata, rollout/lifecycle hints, policy-safe redaction. | Add explicit inventory read command/callback/API over canonical dependency projection; reuse `AudienceDependencies` normalization and admin policy/redaction seams. [VERIFIED: `rulestead/lib/rulestead/store.ex`; `rulestead/lib/rulestead.ex`; `rulestead/lib/rulestead/targeting/audience_dependencies.ex`; `rulestead/lib/rulestead/admin/policy.ex`; `rulestead/lib/rulestead/admin/redaction.ex`] | New contract tests for Ecto/Fake parity and redacted partial-truth behavior; release-contract export updates. |
| DEP-02 | Archive/delete and ruleset publish validation fail closed on unresolved/archived/incompatible/stale/tenant mismatch refs. | Introduce one shared dependency validator and call it from audience mutation + publish paths (and keep compare/import validators aligned). [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`; `rulestead/lib/rulestead/fake.ex`; `rulestead/lib/rulestead/promotion/apply.ex`; `rulestead/lib/rulestead/manifest/import.ex`; `rulestead/lib/rulestead/manifest/validate.ex`] | Publish and audience mutation blocker tests for both adapters; stale + tenant mismatch cases. |
| DEP-03 | Compare/promotion/replay/re-apply/manifest export-import-validate show readable dependency findings and fail closed on incompatible assets. | Extend compare/promotion/manifest seams to consume same dependency contract and emit scoped findings; validate saved plans against live dependency truth before apply. [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`; `rulestead/lib/rulestead/promotion/apply.ex`; `rulestead/lib/rulestead/manifest/plan.ex`; `rulestead/lib/rulestead/manifest/import.ex`; `rulestead/lib/rulestead/manifest/validate.ex`; `rulestead/lib/rulestead/environment_version.ex`; `rulestead/lib/rulestead.ex`] | Extend promotion + manifest tests for missing/archived/incompatible audience dependencies and stale plan replay. |
| DEP-04 | Stable semantic sorting with explicit environment/tenant scope in all dependency/impact outputs. | Enforce canonical sort tuple and mandatory scope fields in inventory/findings envelopes and tokens. [VERIFIED: `rulestead/lib/rulestead/targeting/audience_dependencies.ex`; `rulestead/lib/rulestead/promotion/compare.ex`; `rulestead/lib/rulestead/manifest/result.ex`] | Property/contract tests for deterministic ordering and scope-carry-through across adapters and envelopes. |

</phase_requirements>

## Summary

Phase 53 established preview-confirm safety for audience mutations, but dependency truth is still partially reconstructed and path-specific. The repo currently has strong primitives (`AudienceDependencies.summarize/2`, compare fingerprints/tokens, manifest plan tokens, dependency closure in `environment_versions`) but no single canonical dependency inventory surface that all write/read/promotion/manifest paths reuse. [VERIFIED: `rulestead/lib/rulestead/targeting/audience_dependencies.ex`; `rulestead/lib/rulestead/promotion/compare.ex`; `rulestead/lib/rulestead/manifest/plan.ex`; `rulestead/lib/rulestead/store/ecto.ex`; `rulestead/lib/rulestead/environment_version.ex`]

The biggest correctness gap is fail-closed reuse: `publish_ruleset/1` does not currently run reusable-audience dependency existence/archive/tenant compatibility checks, and manifest validation only enforces presence of `audience_key`, not compatibility with live reusable targeting assets. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`; `rulestead/lib/rulestead/manifest/validate.ex`; `rulestead/lib/rulestead/ruleset/rule.ex`]

**Primary recommendation:** Create one core dependency-truth contract (inventory + validator), persist/index it for stable reads, and make all publish/apply/import/compare entrypoints consume that same contract before any snapshot publication.

## Current Seam Assessment

| Seam | What Exists | Gap To Close In Phase 54 |
|------|-------------|--------------------------|
| `AudienceDependencies` | Deterministic extraction, semantic sort tuple, stable reference keys per audience. | Works from provided payload slices only; not persisted/global inventory and not policy-aware by itself. |
| `Store.Ecto` / `Fake` audience mutation | Revalidates preview fingerprint + affected reference keys before mutation; writes audit evidence. | Uses ad hoc per-environment reference payload scans; does not expose a canonical inventory read contract. |
| `publish_ruleset` | Publishes rulesets and snapshots transactionally with audit. | Missing shared dependency validator gate for referenced audiences prior to publish. |
| Promotion compare/apply | Deterministic tokens/fingerprints + dependency closure checks on apply. | Findings are not yet backed by canonical inventory metadata/redaction model for support inventory truth. |
| Manifest plan/import/validate | Plan/apply tokens and dependency closure checks exist. | Validation surface lacks robust live dependency compatibility checks and scoped finding richness. |
| Admin policy/redaction | Action-based authorization and allowlist redaction seam already in place. | No explicit audience dependency inventory read action and no dedicated redacted dependency envelope contract. |

## Architecture Recommendations

1. **Establish canonical dependency projection**
   - Add persisted projection (for example `audience_references`) keyed by semantic identity: `environment_key`, `tenant_key`, `flag_key`, `ruleset_version`, `rule_key`, `audience_key`.
   - Rebuild/update projection at ruleset publish, promotion apply, manifest apply, and audience mutation paths that affect references.
   - Keep projection strictly authored-state/support-read concern; never used by runtime evaluator.

2. **Add explicit dependency inventory public/store contract**
   - Add a dedicated command/callback/API for inventory reads (audience-centric and/or environment-centric filters, stable sort, pagination).
   - Return both visible references and redacted placeholders (`hidden_reference_count` and redacted entries) rather than all-or-nothing errors.
   - Route through `admin_read` and policy actions specific to dependency reads.

3. **Centralize dependency validation**
   - Introduce one validator module that checks missing, archived, incompatible, stale, and tenant-mismatched dependencies.
   - Invoke the same validator from:
     - audience archive/delete attempt + update mutation confirmation,
     - ruleset publish,
     - promotion apply / saved promotion apply,
     - manifest import apply and manifest validate.
   - Ensure validator output uses a common finding schema so support tooling reads one contract everywhere.

4. **Normalize scope + deterministic ordering everywhere**
   - Require explicit scope fields (`environment_key`, `tenant_key`) in inventory records, preview outputs, compare findings, promotion/manifest findings, and audit metadata.
   - Sort by canonical tuple (`environment_key`, `tenant_key`, `flag_key`, `ruleset_version`, `rule_key`, `audience_key`) and severity/code for findings.
   - Include scope fields in staleness fingerprints/tokens where dependency findings are consumed.

5. **Keep runtime purity and package boundaries intact**
   - Do not add runtime dependency lookups; continue compiling audiences into snapshots.
   - Keep all dependency truth/validation in core `rulestead`; reserve mounted rendering changes for Phase 55.
   - Keep redaction and policy checks host-owned and action-based; no embedded auth stack.

## Candidate Plan Slicing (Planning-Ready)

### Slice 54-01: Canonical Dependency Inventory Projection
- Add projection schema + migration + query APIs.
- Add command/store/root API surface for dependency inventory reads.
- Implement Ecto/Fake parity for deterministic sorted responses.
- Add release-contract updates for new public exports/callbacks.

### Slice 54-02: Shared Dependency Validator at Mutation/Publish Gates
- Build validator module and normalized finding envelope.
- Wire into `publish_ruleset`, audience mutation apply/archive/delete_attempt checks.
- Ensure blocked outcomes fail closed and include actionable reasons.
- Persist audit evidence for blocked dependency outcomes without leaking PII.

### Slice 54-03: Promotion/Manifest/Replay-Apply Dependency Truth
- Reuse validator/findings in compare/promotion and manifest plan/import/validate flows.
- Enrich findings with explicit scope and compatibility reason codes.
- Require saved plan apply paths to revalidate against live dependency truth before apply.
- Preserve environment-version dependency closure provenance.

### Slice 54-04: Policy-Safe Read Behavior + Deterministic Output Proof
- Add policy action(s) for dependency inventory reads and command action/resource mapping.
- Apply redaction strategy for partially unauthorized dependency inventories.
- Add deterministic ordering/property tests and cross-adapter contract tests.
- Finalize out-of-scope guard checks and docs/test contract updates needed for Phase 55 handoff.

## DEP Mapping: Seams And Tests

### DEP-01 (Inventory + redaction)
- **Implementation seams**
  - `rulestead/lib/rulestead/store/command.ex` (new dependency inventory command struct)
  - `rulestead/lib/rulestead/store.ex` (new callback)
  - `rulestead/lib/rulestead.ex` (new root wrapper through `admin_read`)
  - `rulestead/lib/rulestead/store/ecto.ex` and `rulestead/lib/rulestead/fake.ex` (inventory implementation parity)
  - `rulestead/lib/rulestead/admin/policy.ex`, `admin/authorizer.ex`, `admin/redaction.ex` (policy-safe partial truth)
- **Tests**
  - New: `rulestead/test/rulestead/store/audience_dependency_inventory_contract_test.exs`
  - New: `rulestead/test/rulestead/targeting/dependency_inventory_test.exs`
  - Update: `rulestead/test/rulestead/release_contract_test.exs`

### DEP-02 (Fail-closed validation on archive/delete/publish)
- **Implementation seams**
  - `rulestead/lib/rulestead/targeting/audience_dependencies.ex` (canonical key extraction helpers)
  - New validator module under `rulestead/lib/rulestead/targeting/`
  - `rulestead/lib/rulestead/store/ecto.ex` + `fake.ex` (`publish_ruleset`, audience mutation apply)
  - `rulestead/lib/rulestead/store/command.ex` (if publish command needs dependency evidence input)
- **Tests**
  - New: `rulestead/test/rulestead/store/publish_ruleset_dependency_contract_test.exs`
  - Extend: `rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs`
  - Extend: `rulestead/test/rulestead/store/audience_impact_contract_test.exs`

### DEP-03 (Compare/promotion/replay/manifest dependency truth)
- **Implementation seams**
  - `rulestead/lib/rulestead/promotion/compare.ex`
  - `rulestead/lib/rulestead/promotion/apply.ex`
  - `rulestead/lib/rulestead/manifest/plan.ex`
  - `rulestead/lib/rulestead/manifest/import.ex`
  - `rulestead/lib/rulestead/manifest/validate.ex`
  - `rulestead/lib/rulestead/environment_version.ex` (dependency provenance continuity)
  - `rulestead/lib/rulestead.ex` (`apply_promotion_plan`, `apply_manifest_plan` revalidation envelope)
- **Tests**
  - Extend: `rulestead/test/rulestead/store/compare_contract_test.exs`
  - Extend: `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`
  - Extend: `rulestead/test/rulestead/store/manifest_import_contract_test.exs`
  - Extend: `rulestead/test/rulestead/manifest/import_test.exs`
  - Extend: `rulestead/test/rulestead/manifest/validate_test.exs`

### DEP-04 (Stable sorting + explicit scope semantics)
- **Implementation seams**
  - `rulestead/lib/rulestead/targeting/audience_dependencies.ex` (canonical sort key extension if needed)
  - `rulestead/lib/rulestead/promotion/compare.ex` (finding scope + stable sorting)
  - `rulestead/lib/rulestead/manifest/result.ex` (scope-aware finding sorting)
  - `rulestead/lib/rulestead/store/ecto.ex` + `fake.ex` (stable inventory ordering and explicit scope fields)
- **Tests**
  - New property test: `rulestead/test/rulestead/targeting/dependency_sort_property_test.exs`
  - Extend compare/manifest contract tests to assert exact sorted order and scope fields.

## Testing Strategy

- **Adapter parity first:** every new dependency inventory/validator behavior should be asserted in shared Ecto/Fake contract tests.
- **Determinism checks:** add order-sensitive assertions and StreamData properties for scope/sort key stability.
- **Fail-closed matrix:** cover missing, archived, incompatible, stale-token, and tenant-mismatch blockers across publish, audience mutation, promotion apply, and manifest apply/validate.
- **Authorization + redaction matrix:** verify visible-only, mixed visibility, and fully denied cases produce policy-safe envelopes without leaking forbidden identifiers.
- **No-hot-path-regression guard:** keep runtime snapshot/evaluator tests proving no new DB/admin lookup path was introduced for audience resolution.

## Common Pitfalls For Planners

1. Building dependency reads as ad hoc scans in each path instead of one canonical projection.
2. Adding publish/import blockers in one path but not reusing them in promotion and plan-apply paths.
3. Returning fully hidden results on policy mismatch and losing actionable partial truth for authorized resources.
4. Omitting explicit scope fields and allowing same-key audiences to be misread across environment/tenant contexts.
5. Letting dependency validation drift into runtime evaluator paths (violates runtime purity).
6. Treating `manifest.validate` as syntax-only and skipping live dependency compatibility checks.

## Out-Of-Scope Guardrails (Must Hold)

- No new targeting primitive, inheritance graph, or template propagation system.
- No runtime DB/admin/host identity/observability lookup for audience resolution.
- No standalone `rulestead_admin` control-plane behavior or publish prep.
- No graph visualizer or bulk automation surfaces in this phase.
- No PII/raw traits in telemetry, logs, or audit metadata.
- No package-boundary drift: core owns dependency contracts and validation; mounted UI remains Phase 55.

## Concrete File Targets

### Core changes (expected)
- `rulestead/lib/rulestead/store/command.ex`
- `rulestead/lib/rulestead/store.ex`
- `rulestead/lib/rulestead.ex`
- `rulestead/lib/rulestead/store/ecto.ex`
- `rulestead/lib/rulestead/fake.ex`
- `rulestead/lib/rulestead/targeting/audience_dependencies.ex`
- `rulestead/lib/rulestead/promotion/compare.ex`
- `rulestead/lib/rulestead/promotion/apply.ex`
- `rulestead/lib/rulestead/manifest/plan.ex`
- `rulestead/lib/rulestead/manifest/import.ex`
- `rulestead/lib/rulestead/manifest/validate.ex`
- `rulestead/lib/rulestead/admin/policy.ex`
- `rulestead/lib/rulestead/admin/authorizer.ex`
- `rulestead/lib/rulestead/admin/redaction.ex`
- `rulestead/lib/rulestead/environment_version.ex`

### Likely new files
- `rulestead/lib/rulestead/targeting/dependency_inventory.ex` (or equivalent)
- `rulestead/lib/rulestead/targeting/dependency_validator.ex` (or equivalent)
- `rulestead/lib/rulestead/audience_reference.ex` (if persisted projection table is chosen)
- `rulestead/priv/repo/migrations/*_create_audience_references.exs` (if persisted projection table is chosen)

### Test updates/new files
- `rulestead/test/rulestead/store/audience_dependency_inventory_contract_test.exs` (new)
- `rulestead/test/rulestead/store/publish_ruleset_dependency_contract_test.exs` (new)
- `rulestead/test/rulestead/targeting/dependency_inventory_test.exs` (new)
- `rulestead/test/rulestead/targeting/dependency_sort_property_test.exs` (new)
- `rulestead/test/rulestead/store/compare_contract_test.exs` (extend)
- `rulestead/test/rulestead/store/promotion_apply_contract_test.exs` (extend)
- `rulestead/test/rulestead/store/manifest_import_contract_test.exs` (extend)
- `rulestead/test/rulestead/manifest/import_test.exs` (extend)
- `rulestead/test/rulestead/manifest/validate_test.exs` (extend)
- `rulestead/test/rulestead/release_contract_test.exs` (extend)

## Open Questions For Planning

1. Should dependency truth be fully persisted (`audience_references` projection) in Phase 54, or can a transitional indexed query path satisfy DEP-01 without future churn?
2. What is the exact redacted partial-truth envelope for unauthorized references (count-only vs redacted row placeholders)?
3. How is tenant mismatch defined while `audiences` table itself is currently unscoped (no tenant column): command scope only, metadata scope, or schema extension?
4. What minimum compatibility checks are required for "incompatible reusable targeting assets" beyond missing/archived (definition schema/version hash, strategy compatibility, or both)?
5. Should stable finding scopes use machine-readable structured fields in addition to current `scope` string to prevent downstream parsing drift?

## Sources

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/54-dependency-truth-and-promotion-safety/54-CONTEXT.md`
- `.planning/phases/53-impact-preview-contract/53-RESEARCH.md`
- `.planning/phases/53-impact-preview-contract/53-PATTERNS.md`
- `.planning/phases/53-impact-preview-contract/53-04-SUMMARY.md`
- `.planning/research/SUMMARY.md`
- `.planning/research/PITFALLS.md`
- `rulestead/lib/rulestead/store.ex`
- `rulestead/lib/rulestead.ex`
- `rulestead/lib/rulestead/store/ecto.ex`
- `rulestead/lib/rulestead/fake.ex`
- `rulestead/lib/rulestead/targeting/audience_dependencies.ex`
- `rulestead/lib/rulestead/promotion/compare.ex`
- `rulestead/lib/rulestead/promotion/apply.ex`
- `rulestead/lib/rulestead/manifest/plan.ex`
- `rulestead/lib/rulestead/manifest/import.ex`
- `rulestead/lib/rulestead/manifest/validate.ex`
- `rulestead/lib/rulestead/admin/policy.ex`
- `rulestead/lib/rulestead/admin/authorizer.ex`
- `rulestead/lib/rulestead/admin/redaction.ex`
- `rulestead/lib/rulestead/environment_version.ex`

## Metadata

**Research validity window:** until major Phase 54 plan decisions lock command names and projection schema.  
**Planner readiness:** yes, with open questions above resolved first.
