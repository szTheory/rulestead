# Phase 66: Evidence Carry-Through And Governance Boundary - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit events and change-request payloads for audience mutations carry support-safe preview evidence summaries derived from Phase 65 `ImpactPreview` v2 (basis, bounded sample/impression metadata, redaction posture, uncertainty). Blast-radius governance routing remains reference-count based and does not consume impression summaries or host cohort evidence (GOV-05).

**In scope:** Central audit evidence summary helper, Fake+Ecto audit wiring parity for accepted/blocked/denied audience mutation paths, frozen preview evidence in change-request submit metadata and terminal audit carry-through, GOV-05 contract regression proof (no scoring changes to `BlastRadiusThreshold`).

**Out of scope:** Mounted admin preview UI rendering (Phase 67), docs/release-contract/`mix verify.phase68` (Phase 68), new `Rulestead.Error` `:type` atoms, impression-weighted blast-radius thresholds, Rulestead-owned observability ingestion, changes to `BlastRadiusThreshold.assess/2` scoring logic.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Central audit evidence helper
- **D-01:** Add `Rulestead.Targeting.ImpactPreview.audit_evidence_summary/1` accepting a built preview map and returning a bounded, already-redacted summary map with keys: `preview_basis`, `preview_schema_version`, `preview_fingerprint`, `uncertainty`, `sample_evidence`, `impression_evidence`, `affected_reference_keys`.
- Helper reads fields already produced by `ImpactPreview.build/1` — no re-resolution, no raw resolver blobs, no full `affected_references` graph (keys only for bounded audit size).
- Single source of truth for audit + change-request metadata embedding to prevent field drift.

### D-02 — AuditEvent allowlist and audience audit wiring (IMP-07)
- **D-02:** Extend `AuditEvent.audience_preview_metadata/1` allowlist to include `"impression_evidence"`.
- Update `audience_audit_event_changeset/5` in `Rulestead.Store.Ecto` to pass `impression_evidence` from preview (alongside existing `sample_evidence`, `preview_basis`, `uncertainty`).
- Refactor `Rulestead.Fake` audience mutation audit paths to use the same evidence summary shape as Ecto — pass built preview through a shared extraction path instead of manual partial metadata overrides that omit sample/impression evidence on success paths.
- Cover all audience mutation audit event types: accepted (`audience.updated` / archive), blocked (`audience.mutation_blocked`, blast-radius, stale, dependency), denied (authorization).

### D-03 — Change-request frozen evidence (IMP-07)
- **D-03:** Extend `Rulestead.Governance.AudienceMutationChangeRequest.build_submission_metadata/2` to embed a nested `"preview_evidence_summary"` key (parallel to existing `"blast_radius_assessment"` / `"affected_reference_summary"` nesting from Phase 58).
- Summary is frozen from `current_preview` at submit time via `ImpactPreview.audit_evidence_summary/1` — captures what the submitter saw, including host-resolver evidence when present.
- Extend `audience_mutation_terminal_metadata/2` in Fake and Ecto to carry `"preview_evidence_summary"` from stored change-request metadata on reject/cancel terminal audit events (alongside existing blast-radius assessment fields).
- `fetch_change_request/1` returns frozen summary in persisted `metadata` — sufficient for support reconstruction; no admin UI changes in this phase.

### D-04 — GOV-05 regression proof (no scoring changes)
- **D-04:** **No changes** to `Rulestead.Governance.BlastRadiusThreshold.assess/2` or `validate_protected_apply/3` scoring logic — reference_count-only verdicts remain.
- Phase 65 unit test (`assess ignores impression_evidence and sample_evidence`) is necessary but not sufficient for GOV-05 acceptance.
- Phase 66 contract tests MUST prove:
  - `validate_protected_apply/3` verdict parity with and without huge impression/sample evidence on attrs
  - Full governed submit path with `Fake.PreviewEvidenceResolver` configured still yields same blast-radius verdict as without resolver
  - Direct-apply and change-request routing unchanged when richer preview evidence is present
- Fake + Ecto adapter parity via `@adapters` discipline.

### D-05 — Redaction and support-safe posture
- **D-05:** All carried evidence uses Phase 65 redaction (`ImpactPreview.redacted_samples/1`, `redacted_impression_summary/1`) — never raw resolver blobs, never email/IP/UA/phone/name/session tokens in audit or CR metadata.
- `uncertainty.authoritative_population_count?` remains **false** in all carried summaries.
- Audit and CR payloads must pass existing PII contract tests (extend `audience_mutation_audit_test.exs` patterns with impression evidence + resolver paths).

### D-06 — Four-plan execution shape
- **D-06:** Mirror Phases 58/65 plan structure:
  - **66-01** — `ImpactPreview.audit_evidence_summary/1`, `AuditEvent` allowlist extension, unit tests
  - **66-02** — Fake/Ecto audience audit wiring parity (accepted/blocked/denied paths)
  - **66-03** — Change-request submit metadata + terminal audit carry-through + fetch contract tests
  - **66-04** — GOV-05 contract regression + adapter parity with host evidence resolver configured

### Claude's Discretion
- Exact module location for shared Fake audit extraction (inline helper vs dedicated submodule)
- Test file organization: extend `audience_mutation_audit_test.exs` / `audience_mutation_change_request_contract_test.exs` vs dedicated `preview_evidence_audit_contract_test.exs` if duplication grows
- Whether `change_request.submitted` audit context should also embed flat preview keys vs relying on stored CR metadata only

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/REQUIREMENTS.md` — IMP-07, GOV-05 acceptance criteria; out-of-scope table
- `.planning/ROADMAP.md` — Phase 66 goal, success criteria, dependency on Phase 65
- `.planning/PROJECT.md` — v1.9.0 milestone scope; preview evidence truth constraint
- `.planning/STATE.md` — GOV-05 locked; Phase 65 completion decisions

### Prior phase context
- `.planning/phases/65-host-preview-evidence-contract/65-CONTEXT.md` — ImpactPreview v2, resolver seam, redaction, GOV boundary D-10
- `.planning/milestones/v1.7.0-phases/58-change-request-integration/58-CONTEXT.md` — CR metadata nesting pattern (`blast_radius_assessment`, `affected_reference_summary`)
- `.planning/milestones/v1.7.0-phases/57-blast-radius-threshold-contract/57-CONTEXT.md` — reference-count-only scoring contract

### Core implementation surfaces
- `rulestead/lib/rulestead/targeting/impact_preview.ex` — build output, redaction, fingerprint (extend with audit summary)
- `rulestead/lib/rulestead/audit_event.ex` — `audience_preview_metadata/1` allowlist
- `rulestead/lib/rulestead/store/ecto.ex` — `audience_audit_event_changeset/5`, `prepare_audience_mutation_change_request/1`
- `rulestead/lib/rulestead/fake.ex` — audience mutation audit paths, CR terminal metadata
- `rulestead/lib/rulestead/governance/audience_mutation_change_request.ex` — `build_submission_metadata/2`
- `rulestead/lib/rulestead/governance/blast_radius_threshold.ex` — scoring logic (must not change)
- `rulestead/lib/rulestead/fake/preview_evidence_resolver.ex` — test resolver for contract tests

### Test patterns
- `rulestead/test/rulestead/audience_mutation_audit_test.exs` — accepted/blocked/denied audit + PII redaction
- `rulestead/test/rulestead/governance/audience_mutation_change_request_contract_test.exs` — Fake+Ecto CR parity
- `rulestead/test/rulestead/governance/blast_radius_threshold_test.exs` — Phase 65 GOV boundary seed test
- `rulestead/test/rulestead/targeting/preview_evidence_contract_test.exs` — resolver + evidence build patterns

### Policy
- `prompts/rulestead-security-privacy-and-threat-model.md` — no PII in audit/telemetry
- `prompts/rulestead-domain-language-field-guide.md` — audience, cohort, impression vocabulary
- `.planning/METHODOLOGY.md` — recommendation-first lens (assumptions mode)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImpactPreview.build/1` — produces redacted `sample_evidence`, `impression_evidence`, `preview_basis`, `uncertainty`
- `AuditEvent.metadata/1` + `audience_preview_metadata/1` — existing allowlist extraction (missing `impression_evidence`)
- `AudienceMutationChangeRequest.build_submission_metadata/2` — blast-radius embedding at CR submit
- `Fake.PreviewEvidenceResolver` — test resolver for host evidence contract tests

### Established Patterns
- Phase 58 nested CR metadata keys (`blast_radius_assessment`, `affected_reference_summary`)
- Flat audit metadata keys for audience mutations (`preview_fingerprint`, `sample_evidence`, etc. in `audience_mutation_audit_test.exs`)
- Fake + Ecto `@adapters` contract test discipline
- Pure preview module; store performs I/O and embeds summaries at audit/CR boundaries

### Integration Points
- `audience_audit_event_changeset/5` in Ecto — primary audit metadata assembly for audience mutations
- `append_audit_event/5` + manual metadata in Fake — parity gap on success paths (no sample/impression today)
- `prepare_audience_mutation_change_request/1` in Fake/Ecto — merges submission metadata before CR insert
- `audience_mutation_terminal_metadata/2` — reject/cancel audit context from stored CR metadata

### Known Gaps (Phase 66 closes)
- `AuditEvent.audience_preview_metadata/1` allowlists `sample_evidence` but not `impression_evidence`
- Ecto `audience_audit_event_changeset` passes `sample_evidence` but not `impression_evidence`
- Fake success-path audit omits sample/impression evidence entirely
- `build_submission_metadata/2` has no frozen preview evidence summary

</code_context>

<specifics>
## Specific Ideas

- Nested `"preview_evidence_summary"` in CR metadata mirrors Phase 58's `"blast_radius_assessment"` nesting; flat keys remain in direct audit event metadata for backward compatibility with existing tests
- Frozen at submit — reviewers see submitter-time evidence even if resolver data changes before execute
- GOV-05 proof extends Phase 65 unit test into full contract/regression coverage, not new scoring logic

</specifics>

<deferred>
## Deferred Ideas

- Mounted change-request review UI rendering of preview evidence — Phase 67 (ADM-05) or later admin polish
- `mix verify.phase66` merge gate — defer to Phase 68 (VER-01) unless planning finds a lightweight interim verifier
- Impression-weighted blast-radius thresholds — explicitly forbidden (GOV-05)
- Telemetry events carrying raw impression counts — out of scope; audit/CR summaries only

</deferred>

---

*Phase: 66-evidence-carry-through-and-governance-boundary*
*Context gathered: 2026-05-27*
