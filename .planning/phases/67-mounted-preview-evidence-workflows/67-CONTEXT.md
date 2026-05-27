# Phase 67: Mounted Preview Evidence Workflows - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Mounted admin audience edit, archive, and delete preview flows surface host-supplied sample cohort and impression summary evidence when the host configures the Phase 65 resolver seam, render honest uncertainty copy, and fail closed with actionable errors when evidence is missing, invalid, or policy-denied — without widening the admin product shape.

**In scope:** Extend `AudienceComponents.impact_preview/1` for sample/impression evidence and basis-specific uncertainty; mounted LiveView tests for edit/archive/delete preview (and confirm where applicable) with `Fake.PreviewEvidenceResolver`; parity with existing preview→confirm→audit fingerprint carry-through; no new routes or observability surfaces.

**Out of scope:** Core resolver contract changes (Phase 65), audit/CR evidence carry-through (Phase 66), `mix verify.phase68` / host seam docs / release-contract (Phase 68), change-request review UI for frozen evidence summaries, Rulestead-owned impression ingestion, fleet dashboards or metrics product language, blast-radius scoring changes.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Evidence presentation (extend component, no new routes)
- **D-01:** Extend `RulesteadAdmin.Components.AudienceComponents.impact_preview/1` with bounded **Sample cohort** and **Impression summary** sections when `sample_evidence` / `impression_evidence` are non-empty on the preview map.
- Sample table columns: `actor_key`, `targeting_key`, `matched?`, `reason` (support-safe allowlist fields only); cap display rows with “+N more” when list exceeds display limit (planner picks threshold; default align with core cap awareness).
- Impression block: `window_label`, `sampled_impressions`, `matched_impressions`, optional `variant_breakdown` (variant + count only).
- Omit sections when evidence maps/lists are empty; never render raw resolver blobs or non-allowlisted trait fields.

### D-02 — Uncertainty and preview basis copy
- **D-02:** Replace hardcoded uncertainty paragraph in `impact_preview/1` with `@preview.uncertainty[:message]` (or string-key equivalent) from core `ImpactPreview.build/1`.
- Extend `humanize_preview_basis/1` for Phase 65 basis values:
  - `authored_state_and_explicit_samples` → “Authored state and explicit samples”
  - `authored_state_with_host_evidence` → “Authored state with host-supplied evidence”
  - `authored_state_host_evidence_unavailable` → “Authored state (host evidence unavailable)”
- Always surface `authoritative_population_count?: false` honestly; never imply fleet-wide or authoritative population counts.

### D-03 — Preview route behavior (minimal LiveView changes)
- **D-03:** `EditPreview`, `ArchivePreview`, and `DeletePreview` keep calling `Rulestead.preview_audience_impact/3` with `Shared.scope_opts/1` — no admin-side resolver configuration or duplicate resolve logic.
- `{:error, error}` → existing `role="alert"` with `error.message` (invalid/oversized/policy-denied host evidence fail-closed from core).
- `{:ok, preview}` with `authored_state_host_evidence_unavailable` → render preview with fallback uncertainty copy (authored refs still shown).
- **Delete preview:** retain unsupported-delete callout; still render `impact_preview` when core returns a preview map (parity with edit/archive).

### D-04 — Confirm and governance carry-through (tests, no confirm refactors)
- **D-04:** No changes required to confirm LiveViews for evidence field plumbing — `preview_fingerprint`, `preview_schema_version`, and `preview_basis` already flow through confirm URLs and apply attrs.
- Phase 67 mounted tests configure `Application.put_env(:rulestead, :preview_evidence_resolver, Rulestead.Fake.PreviewEvidenceResolver)` to prove UI renders evidence and confirm links preserve fingerprints (mirror core `audience_mutation_audit_test.exs` patterns).
- Governance blast-radius panel and change-request routing unchanged (GOV-05).

### D-05 — Product shape guardrails
- **D-05:** Copy and layout must not imply Rulestead-owned observability, population analytics, or fleet dashboards — bounded sample/impression language only.
- No new LiveView routes, global evidence screens, or metrics widgets (same envelope as Phase 63 mounted auto-advance: extend existing preview surfaces only).

### D-06 — Four-plan execution shape
- **D-06:** Mirror Phases 63/65/66 plan structure:
  - **67-01** — `AudienceComponents.impact_preview/1` evidence sections + basis/uncertainty copy
  - **67-02** — Edit + archive preview LiveView tests (resolver on/off, fail-closed errors, drift copy unchanged)
  - **67-03** — Delete preview + prod governance preview tests with evidence visible where configured
  - **67-04** — Mounted contract sweep: confirm fingerprint query params, no observability-product copy regressions

### Claude's Discretion
- Exact sample display row cap and “+N more” threshold
- Impression `variant_breakdown` as sub-table vs inline list
- Whether delete preview should add governance panel (currently omitted on `DeletePreview`)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/REQUIREMENTS.md` — ADM-05 acceptance criteria; companion-surface table
- `.planning/ROADMAP.md` — Phase 67 goal, success criteria, dependency on Phase 66
- `.planning/PROJECT.md` — v1.9.0 milestone; preview evidence truth constraint
- `.planning/STATE.md` — Phase 65–66 completion decisions

### Prior phase context
- `.planning/phases/65-host-preview-evidence-contract/65-CONTEXT.md` — resolver seam, ImpactPreview v2, basis/uncertainty taxonomy, redaction
- `.planning/phases/66-evidence-carry-through-and-governance-boundary/66-CONTEXT.md` — audit/CR evidence summaries; GOV-05 boundary
- `.planning/milestones/v1.8.0-phases/63-mounted-auto-advance-workflows/63-CONTEXT.md` — mounted surface extension pattern (no new routes)

### Core implementation surfaces
- `rulestead/lib/rulestead/targeting/impact_preview.ex` — `sample_evidence`, `impression_evidence`, `uncertainty`, `preview_basis`
- `rulestead/lib/rulestead/targeting/preview_evidence.ex` — resolver behaviour + facade
- `rulestead/lib/rulestead/fake/preview_evidence_resolver.ex` — test resolver for mounted tests
- `rulestead/lib/rulestead.ex` — `preview_audience_impact/3`

### Admin implementation surfaces
- `rulestead_admin/lib/rulestead_admin/components/audience_components.ex` — `impact_preview/1` (primary UI change)
- `rulestead_admin/lib/rulestead_admin/live/audience_live/edit_preview.ex`
- `rulestead_admin/lib/rulestead_admin/live/audience_live/archive_preview.ex`
- `rulestead_admin/lib/rulestead_admin/live/audience_live/delete_preview.ex`
- `rulestead_admin/lib/rulestead_admin/live/audience_live/edit_confirm.ex` — fingerprint query contract (verify only)
- `rulestead_admin/lib/rulestead_admin/live/audience_live/governance.ex` — governance assigns (unchanged semantics)

### Test patterns
- `rulestead_admin/test/rulestead_admin/live/audience_live/edit_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/audience_live/archive_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/audience_live/delete_preview_test.exs`
- `rulestead/test/rulestead/audience_mutation_audit_test.exs` — resolver + impression_evidence patterns
- `rulestead/test/rulestead/targeting/preview_evidence_contract_test.exs`

### Policy and UX
- `prompts/rulestead-admin-ux-and-operator-ia.md` — preview→confirm→audit envelope; no observability product
- `prompts/rulestead-security-privacy-and-threat-model.md` — no PII in rendered evidence
- `prompts/rulestead-domain-language-field-guide.md` — audience, cohort, impression vocabulary
- `.planning/METHODOLOGY.md` — recommendation-first lens (assumptions mode)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.preview_audience_impact/3` — already invoked from all three audience preview LiveViews; returns full ImpactPreview v2 map including evidence fields
- `AudienceComponents.impact_preview/1` — single render site for edit/archive/delete previews
- `GovernanceComponents.blast_radius_panel/1` + `AudienceLive.Governance` — prod change-request path on edit/archive preview (unchanged)
- `Rulestead.Fake.PreviewEvidenceResolver` — configure via `Application.put_env(:rulestead, :preview_evidence_resolver, ...)` in tests

### Established Patterns
- Phase 63: extend existing mounted surfaces, no new routes
- Phase 65: three `preview_basis` strings + `uncertainty.message` per basis
- Flag cleanup “Evidence and uncertainty” section_card — reference for support-safe labeling tone (not reused verbatim for audience impact preview)
- Confirm URLs pass `preview_fingerprint` + `preview_schema_version` query params (`edit_preview.ex` `confirm_path/1`)

### Integration Points
- Preview load: `load_preview/2` or `load_preview/3` in each LiveView → `Rulestead.preview_audience_impact/3`
- Render: `<AudienceComponents.impact_preview preview={@preview} />` after governance panel
- Confirm: separate LiveViews re-preview on load; apply attrs carry fingerprint/basis

### Known Gaps (Phase 67 closes)
- `impact_preview/1` does not render `sample_evidence` or `impression_evidence`
- `humanize_preview_basis/1` only handles `authored_state_and_explicit_samples`
- Uncertainty copy hardcoded to explicit-samples-only wording
- Mounted tests do not configure preview evidence resolver

</code_context>

<specifics>
## Specific Ideas

- Component-only UI change keeps ADM-05 scoped to presentation; core resolver invocation already works through existing preview API
- Mirror core audit test resolver setup for mounted HTML assertions (window_label, matched_impressions, sample rows)
- Delete preview remains educational/fail-closed for unsupported delete; evidence display still proves resolver path when preview succeeds

</specifics>

<deferred>
## Deferred Ideas

- Change-request show/review UI for frozen `preview_evidence_summary` — future admin polish (Phase 66 deferred)
- `mix verify.phase67` dedicated merge gate — defer to Phase 68 VER-01
- Fleet dashboards, metrics widgets, or “population impact” authoritative language — explicitly forbidden

</deferred>

---

*Phase: 67-mounted-preview-evidence-workflows*
*Context gathered: 2026-05-27*
