# Phase 55: Mounted Operator Workflows - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Mounted admin users can inspect, edit, confirm, and explain reusable audience dependencies through bounded workflows that render core truth without adding a standalone control plane.

</domain>

<decisions>
## Implementation Decisions

### Audience IA and routing
- **D-01:** Dedicated `/audiences` routes register before `/:key` catch-all; env and tenant travel as query params via `Session`.
- **D-02:** Audience CRUD and impact flows use route-backed preview and confirm steps (not modal-only mutations).

### Presentation-only boundary
- **D-03:** `rulestead_admin` calls only public Rulestead admin APIs; no Repo access or duplicated dependency/impact validation in LiveView.
- **D-04:** LiveView validation (reason, typed confirmation) is UX-only; core `apply_audience_mutation` remains authoritative.

### Preview, confirm, and audit
- **D-05:** Audience mutations follow preview → confirm → audit, mirroring flag cleanup navigation.
- **D-06:** Confirm routes thread core-issued `preview_fingerprint` (`audprev_*`) and `preview_schema_version` from `preview_audience_impact` — not locally recomputed signatures.
- **D-07:** Stale or missing preview surfaces explicit operator copy and redirects back to preview routes.

### Policy-aware dependency display
- **D-08:** Used-by tables consume `list_audience_dependencies` with partial redacted truth (`hidden_reference_count`, optional placeholders).
- **D-09:** Core applies `visibility_resolver` checking `:read_flags` per referenced flag before row display; redacted placeholders do not leak flag keys.
- **D-10:** Every dependency row shows explicit `environment_key` and `tenant_key` scope.

### Rules, simulate, and explain
- **D-11:** Add `/:key/explain` LiveView with support-safe permalinks (`env`, `tenant`, `targeting_key`, optional `session_id`/`request_id` — never traits or PII).
- **D-12:** Simulate and explain render structured `audience_trace` steps from evaluation traces; rules workspace links to audience detail and surfaces missing-reference copy.
- **D-13:** `Explainer` gains optional audience sentences for CLI parity; mounted UI uses structured traces as primary.

### Compare, promotion, and manifest
- **D-14:** `EnvironmentCompareLive` index and show render `compare.dependency_findings` with scoped links to flags and audiences.
- **D-15:** No manifest LiveView in v1.6.0; ADM-04 manifest slice satisfied by core APIs + compare presentation + Phase 56 verification.
- **D-16:** Compare remains preview-only (no inline Apply/Publish); promotion handoff stays governed plan/CLI path.

### Claude's Discretion
- Exact HEEx component factoring (`AudienceComponents`, trace helpers).
- Offset vs keyset pagination for first ship when fixture sizes are small.
- Whether explain LiveView calls `simulate_flag` or an enriched `explain_flag` returning `debug_trace`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` — Phase 55 goal and success criteria
- `.planning/REQUIREMENTS.md` — ADM-01 through ADM-04
- `.planning/phases/54-dependency-truth-and-promotion-safety/54-HANDOFF-CHECKLIST.md`
- `.planning/phases/54-dependency-truth-and-promotion-safety/54-CONTEXT.md`

### Operator UX and engineering DNA
- `prompts/rulestead-admin-ux-and-operator-ia.md` — audiences IA, explain, mutation lifecycle
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — mountable admin, sibling packages
- `.planning/research/PITFALLS.md` — Phase 55 pitfalls (policy reads, bulk automation)

### Core contracts
- `rulestead/lib/rulestead/targeting/impact_preview.ex`
- `rulestead/lib/rulestead/targeting/dependency_inventory.ex`
- `rulestead/lib/rulestead/admin/redaction.ex`
- `rulestead/lib/rulestead.ex` — audience dependency and impact APIs

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RulesteadAdmin.Live.FlagLive.CleanupPreview` / `CleanupConfirm` — route-backed preview/confirm pattern
- `RulesteadAdmin.Live.Session` — env/tenant/return_to path helpers
- `RulesteadAdmin.Components.OperatorComponents` — policy banners, status lists
- `RulesteadAdmin.Live.EnvironmentCompareLive` — compare findings rendering (extend for dependency_findings)

### Established Patterns
- Admin reads/writes go through `Rulestead.list_*` / `preview_*` / `apply_*` with actor on commands
- Compare index/show already forbid Apply/Publish controls in tests

### Integration Points
- Router macro `rulestead_admin/2` — add audience routes before `/:key`
- Flag rules, simulate, explain, and compare link into `/audiences/:audience_key`

</code_context>

<specifics>
## Specific Ideas

Assumptions confirmed from Phase 55 research plan without user corrections.

</specifics>

<deferred>
## Deferred Ideas

- Mounted manifest import/export wizard — future phase
- Dependency graph visualization — out of scope
- Bulk audience mutation automation — out of scope

</deferred>

---

*Phase: 55-mounted-operator-workflows*
*Context gathered: 2026-05-27*
