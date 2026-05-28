# Phase 65: Host Preview Evidence Contract - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Core accepts bounded, host-supplied sample cohorts and impression summaries through an explicit resolver behaviour with redaction, honest `preview_basis` / uncertainty labeling, and deterministic fingerprints that incorporate evidence metadata.

**In scope:** `Rulestead.Targeting.PreviewEvidence` behaviour + facade, bounded payload validation, `ImpactPreview` schema v2 extensions (samples + impression evidence in fingerprint), Fake/Ecto resolver wiring in `audience_preview_payload`, Fake test resolver, contract tests (redaction, fingerprint determinism, stale rejection with evidence, invalid/oversized fail-closed, adapter parity).

**Out of scope:** Mounted admin preview UI wiring (Phase 67), audit/change-request evidence carry-through (Phase 66), `mix verify.phase68` / host seam docs / release-contract (Phase 68), Rulestead-owned impression ingestion or warehouse queries, blast-radius scoring changes (GOV-05 stays reference-count only), population-authoritative claims.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Resolver seam (mirror guardrails provider)
- **D-01:** Add `Rulestead.Targeting.PreviewEvidence` behaviour with `@callback resolve(query :: map()) :: result()` where `result` accepts `{:ok, map()}`, `{:error, atom() | String.t()}`, or a normalized evidence map (same flexibility pattern as `Rulestead.Guardrails.Provider`).
- Add `Rulestead.Targeting.PreviewEvidence.resolve/2` facade reading `Keyword.get(opts, :resolver) || Application.get_env(:rulestead, :preview_evidence_resolver)`.
- **Opt-in:** When no resolver is configured, behavior is unchanged from today (authored references + optional explicit `command.samples` only).
- Host implements the behaviour; Rulestead does not ship observability queries.

### D-02 — Query struct and scope
- **D-02:** Resolver receives a normalized query map scoped to: `environment_key`, `tenant_key`, `audience_key`, `operation`, `before_definition`, `after_definition`, and `affected_reference_keys` (derived from `AudienceDependencies` before resolve).
- Resolver returns zero or more of: `samples` (list of cohort row maps), `impression_summary` (bounded map), optional `policy_denied` / error atoms.
- Synchronous resolve only in Phase 65 (no async/cache GenServer); matches guardrails `fetch_signal/1` posture.

### D-03 — Store integration point (I/O at store boundary)
- **D-03:** Invoke resolver from `audience_preview_payload/4` in **both** `Rulestead.Fake` and `Rulestead.Store.Ecto` **before** `ImpactPreview.build/1`.
- `ImpactPreview` remains pure (no resolver calls inside build/fingerprint).
- Merge policy: **union** explicit `command.samples` with resolver-returned samples; explicit command rows are preserved; resolver fills gaps; enforce a single **hard cap** on total sample rows after merge (default **25**, overridable in tests via opts only — not `Rulestead.Config` yet).

### D-04 — ImpactPreview schema v2
- **D-04:** Bump `ImpactPreview.schema_version` to **2**.
- Add `impression_evidence` field on built preview (redacted, possibly empty map).
- Extend `preview_fingerprint/1` token payload with `impression_fingerprint` (hash of normalized impression evidence) alongside existing `sample_fingerprint`.
- Apply/mutation commands continue to carry `preview_schema_version`; stale apply with v1 fingerprints rejected via existing schema-version gate.

### D-05 — preview_basis and uncertainty taxonomy
- **D-05:** `preview_basis` string values (existing style):
  - `authored_state_and_explicit_samples` — default when no resolver evidence (unchanged semantics)
  - `authored_state_with_host_evidence` — resolver returned bounded sample and/or impression summary
  - `authored_state_host_evidence_unavailable` — resolver configured but returned empty, denied, or errored; preview still shows authored refs with explicit fallback uncertainty (no upgrade to authoritative counts)
- `uncertainty.authoritative_population_count?` remains **false** for all bases in Phase 65.
- Update `uncertainty.message` per basis (support-safe, no exact affected-user language).

### D-06 — Impression summary shape (locked default)
- **D-06:** `impression_summary` is a bounded map with allowlisted keys only:
  - `window_label` (string, e.g. `"last_24h"`, `"last_7d"`)
  - `sampled_impressions` (non-negative integer)
  - `matched_impressions` (non-negative integer)
  - `variant_breakdown` (optional list of `%{variant: string, count: non_neg_integer}` — counts only, no actor identifiers)
- Reject unknown keys, oversize lists, and non-integer counts fail-closed before fingerprinting.

### D-07 — Bounded payloads and fail-closed validation
- **D-07:** Enforce in core (before `ImpactPreview.build/1`):
  - Max **25** sample rows after merge
  - Max serialized evidence payload size (recommend **16 KiB** term-normalized bound — planner may tune with tests)
  - Impression summary field allowlist + redaction pass
- Invalid, oversized, or policy-denied host evidence → actionable `Rulestead.Error` via existing `StoreError.invalid_command/2` / `%Rulestead.Error{type: :invalid_command}` — **no new public `:type` atom** unless `api_stability.md` is explicitly updated in planning.
- Stable finding/error codes (minimum): `preview_evidence_oversized`, `preview_evidence_invalid`, `preview_evidence_policy_denied`, `preview_evidence_resolver_failed`.

### D-08 — Redaction
- **D-08:** Reuse `Rulestead.Admin.Redaction.redact_metadata/2` for sample rows (existing `@sample_allowlist` in `ImpactPreview`).
- Impression summary uses a dedicated allowlist (D-06 fields only); strip email, IP, UA, phone, name, raw actor identifiers, session tokens.
- Never emit raw host resolver blobs into preview payload, audit metadata, or telemetry in Phase 65.

### D-09 — Stale fingerprint and IMP-06
- **D-09:** Any change to merged samples or impression evidence changes `preview_fingerprint`; `ensure_fresh_audience_preview/2` in Fake/Ecto treats evidence drift identically to authored-state drift.
- Regression tests must prove richer host evidence cannot bypass stale preview rejection on apply/CR paths.

### D-10 — Governance boundary (GOV-05)
- **D-10:** `Rulestead.Governance.BlastRadiusThreshold` scoring remains **reference_count-only**; impression summaries and cohort sizes are **not** inputs to `assess/2` or `validate_protected_apply/3`.
- Assessment may continue to set `authoritative_population_count?: false` for reporting honesty.

### D-11 — Fake adapter and contract tests
- **D-11:** `Rulestead.Fake` (or dedicated `Rulestead.Fake.PreviewEvidenceResolver`) implements a test resolver for contract tests.
- Contract tests follow `@adapters [Rulestead.Fake, Rulestead.Store.Ecto]` parity discipline in `audience_impact_contract_test.exs` / `impact_preview_test.exs` extensions.

### D-12 — Four-plan execution shape
- **D-12:** Mirror Phases 57/61 plan structure:
  - **65-01** — behaviour, query normalization, config, limits validator (IMP-05 seam)
  - **65-02** — `ImpactPreview` v2, basis/uncertainty, fingerprint + impression redaction (IMP-05 + IMP-06)
  - **65-03** — Fake/Ecto `audience_preview_payload` wiring + `Rulestead` facade helpers
  - **65-04** — contract tests: resolver, redaction, fingerprint with evidence, stale rejection, fail-closed oversized/invalid, adapter parity

### Claude's Discretion
- Exact module filenames under `lib/rulestead/targeting/`
- Precise byte limit constant and error metadata field names (within D-07 constraints)
- Whether test resolver lives in `fake.ex` or a dedicated submodule
- Merge deduplication key for sample rows (recommend `actor_key` + `targeting_key` when present)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/REQUIREMENTS.md` — IMP-05, IMP-06 acceptance criteria; out-of-scope table (no Rulestead-owned ingestion, no impression-weighted GOV)
- `.planning/ROADMAP.md` — Phase 65 goal, success criteria, phase boundary vs 66–68
- `.planning/PROJECT.md` — reusable targeting preview truth constraint; v1.9.0 activation decision
- `.planning/STATE.md` — GOV-05 blast-radius stays reference-count only
- `.planning/threads/2026-05-27-post-v1.7-milestone-assessment.md` — partial IMP-05 state (core samples, mounted unwired)

### Existing impact preview and governance
- `rulestead/lib/rulestead/targeting/impact_preview.ex` — schema v1, samples, fingerprint, redaction, uncertainty
- `rulestead/lib/rulestead/targeting/audience_dependencies.ex` — affected reference summarization
- `rulestead/lib/rulestead/governance/blast_radius_threshold.ex` — reference-count-only threshold (must not change scoring)
- `rulestead/lib/rulestead/store/command.ex` — `PreviewAudienceImpact`, `ApplyAudienceMutation` (`samples`, `preview_basis`)
- `rulestead/lib/rulestead/store/ecto.ex` — `audience_preview_payload`, `ensure_fresh_audience_preview`
- `rulestead/lib/rulestead/fake.ex` — adapter parity reference
- `rulestead/test/rulestead/targeting/impact_preview_test.exs` — fingerprint and redaction tests
- `rulestead/test/rulestead/store/audience_impact_contract_test.exs` — Fake + Ecto contract pattern

### Host seam patterns
- `rulestead/lib/rulestead/guardrails/provider.ex` — behaviour + config resolver pattern
- `rulestead/lib/rulestead/guardrails.ex` — facade `provider_module/1` pattern
- `prompts/rulestead-host-app-integration-seam.md` — host-owned observability posture (Phase 68 docs subsection deferred)

### Prior phase patterns
- `.planning/milestones/v1.7.0-phases/57-blast-radius-threshold-contract/57-CONTEXT.md` — pure policy + store gate; reference-count-only scoring
- `.planning/milestones/v1.8.0-phases/61-auto-advance-authored-contract/61-CONTEXT.md` — four-plan shape; Fake/Ecto parity discipline

### Operator and engineering policy
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — runtime purity, error struct conventions, Fake parity
- `prompts/rulestead-domain-language-field-guide.md` — audience vs cohort; impression vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — redaction, no PII in telemetry/logs
- `.planning/research/SUMMARY.md` — pitfall #2 false precision in previews

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Targeting.ImpactPreview` — `build/1`, `preview_fingerprint/1`, `redacted_samples/1`, `@sample_allowlist`
- `Rulestead.Admin.Redaction` — metadata redaction used by samples today
- `Rulestead.Guardrails.Provider` + `Rulestead.Guardrails` — config-driven host behaviour template
- `Command.PreviewAudienceImpact` / `Command.ApplyAudienceMutation` — already accept `samples` and `preview_basis`
- `Rulestead.Fake` + `Rulestead.Store.Ecto` — dual-adapter proof targets

### Established Patterns
- Pure preview/fingerprint module; store performs I/O and calls pure build
- `preview_schema_version` gate on apply; `ensure_fresh_audience_preview/2` on mutation
- Contract tests with `@adapters [Rulestead.Fake, StoreEcto]`
- `authoritative_population_count?: false` on all preview uncertainty maps

### Integration Points
- `audience_preview_payload/4` in Fake and Ecto — add resolver call before `ImpactPreview.build`
- `Rulestead.preview_audience_impact/2` — unchanged entry; evidence flows through store
- Phase 66 will embed evidence summaries in audit/CR payloads
- Phase 67 mounted LiveViews will call preview APIs (resolver configured at host app level)

</code_context>

<specifics>
## Specific Ideas

- No resolver configured → identical behavior to pre-v1.9 (integrator opt-in)
- Union merge: hosts can still pass explicit samples on the command; resolver supplements, does not silently replace operator-provided rows
- Impression summaries are warehouse-agnostic bounded summaries, not Rulestead impression ingestion

</specifics>

<deferred>
## Deferred Ideas

- Audit/change-request preview evidence summaries in mutation payloads — Phase 66 (IMP-07)
- Mounted audience edit/archive/delete preview rendering and fallback copy — Phase 67 (ADM-05)
- `mix verify.phase68`, host seam docs subsection, release-contract truth — Phase 68 (VER-01–03)
- Impression-weighted blast-radius thresholds — GOV-05 explicitly forbids
- Rulestead-owned impression ingestion or fleet dashboards — out of scope table
- Draft targeting presets (ADM-06) — defer

</deferred>

---

*Phase: 65-host-preview-evidence-contract*
*Context gathered: 2026-05-27*
