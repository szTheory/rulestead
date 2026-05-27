# Phase 59: Mounted Governance Workflows - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Mounted admin (`rulestead_admin`) routes **protected-environment** audience **edit** and **archive** mutations through governed change-request flows when blast radius is above threshold, with calm operator copy and policy-aware evidence on audience and change-request surfaces.

**In scope:** LiveView routing/CTA branching on confirm + preview, `GovernanceComponents.blast_radius_panel`, CR show audience-mutation evidence, visibility tiers reusing existing redaction seams, LiveView + integration tests.

**Out of scope:** Core threshold/CR semantics changes (Phases 57–58), docs/release-contract (Phase 60), new `Rulestead.Error` types, host threshold profiles, bulk audience automation, standalone admin, audit timeline redesign.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Unified routing model (above / below / indeterminate)

- On **preview** and **confirm** load in protected environments, call `Rulestead.assess_audience_blast_radius/2` (with preview + `hidden_reference_count` from dependency inventory when available).
- Assign `@governance_mode`:
  - `:direct_apply` — protected + `verdict == :below_threshold`
  - `:change_request` — protected + `verdict == :above_threshold`
  - `:blocked` — protected + `verdict == :indeterminate` **or** assess error
  - `:unrestricted` — non-protected (no threshold gate UI; existing preview/apply)
- **Non-protected:** No governance panel beyond optional informational assess; Apply unchanged.

### D-02 — Above-threshold confirm: replace Apply, not a new route

- **Do not** add a fourth “governance proposal” LiveView route.
- Reuse existing `/edit/confirm` and `/archive/confirm` routes; swap primary action when `@governance_mode == :change_request`.
- **Hide/disable** “Apply update/archive”; primary CTA: **Submit change request** (`phx-submit="submit_change_request"`).
- Require reason (same field as today); build `SubmitChangeRequest` with `governed_action: :apply_audience_mutation` and Phase 58 metadata (`AudienceMutationChangeRequest.build_submission_metadata/2` or equivalent).
- Re-assess on confirm load (enforcement boundary); preview may assess earlier for expectation-setting only.

### D-03 — Preview copy and CTA when governed

- On preview, when `@governance_mode == :change_request`, show callout above impact evidence:
  - “This change exceeds the direct-apply limit for **[Environment]**. You will submit a change request instead of applying immediately.”
- Link text: **Continue to submit** (not “Continue to confirm”) when governed; **Continue to confirm** when direct apply.
- Archive flow: mirror edit wording (“archive” vs “update”).

### D-04 — Post-submit navigation

- On successful `submit_change_request`, `push_navigate` to **`ChangeRequestLive.Show`** for the new id (not queue index, not audience show).
- Flash: “Change request submitted. Audience definition is unchanged until this request is approved and executed.”
- Use `Session.current_path/3` for mount-prefixed URLs (`?env=` preserved).

### D-05 — Approval expectations on governed confirm

- Before submit, resolve and display `ApprovalRequirement` for the scoped actor (same seams as CR show):
  - Required approval count
  - Self-approval: “You **may** / **cannot** approve your own request” from `self_approval_allowed?`
- If `:submit_change_request` denied: `OperatorComponents.capability_explanation` — title “Change request required”, host reason; no submit form.
- **Never** auto-approve or auto-execute on submit (admin UX §9: AI/governance suggestive, not autopilot).

### D-06 — Indeterminate UX (fail-closed, matches Phase 58)

- Verdict label: **“Cannot evaluate safely”** (critical tone) — distinct from **“Governance required”** (above threshold).
- **No** Apply button; **no** Submit change request (Phase 58 rejects `:indeterminate` submit).
- Show remediation from top `breach_reason` + link **Back to preview** / cancel; stale fingerprint → existing `?drifted=true` redirect pattern.
- Do not imply approval can override missing preview or hidden dependency truth.

### D-07 — Blast-radius evidence component

- Add `RulesteadAdmin.Components.GovernanceComponents.blast_radius_panel/1` (sibling to `AudienceComponents`).
- Assigns: `assessment` (live map or frozen CR metadata), `variant` (`:operator` | `:reviewer`), `visibility` (`:full` | `:redacted`), optional nested `impact_preview` on audience routes only.
- **Do not** fold verdict/breach UI into `impact_preview` — keep impact references separate from governance verdict.
- **Audience preview/confirm:** panel **above** `impact_preview`.
- **ChangeRequestLive.Show** for `apply_audience_mutation`: panel between “Proposed change” and “Review context”; render from frozen `metadata["blast_radius_assessment"]` + `affected_reference_summary` — **do not re-assess** on approve (execute re-validates in core).

### D-08 — Information hierarchy per surface

**Preview (`:operator`, live assess):**
1. Verdict strip + threshold summary (reference_count vs limit; operation-specific)
2. Preview basis limit line (`authoritative_population_count?: false`)
3. Primary CTA (per D-03)
4. `impact_preview` (existing)
5. Collapsible breach_reasons + rollout/lifecycle hints

**Confirm (`:operator`, live assess):**
1. Verdict strip (re-assess)
2. Fingerprint + scope (existing)
3. Action fork (Apply vs Submit CR vs blocked)
4. Compact top breach + link to preview for full list
5. Omit full reference list duplication (preview already showed it)

**CR show (`:reviewer`, frozen metadata):**
1. Proposed change diff (unchanged, above fold)
2. Frozen blast-radius panel (“Evidence frozen at submission” + submit fingerprint)
3. Review context + actions (unchanged preview → confirm → audit on approve/execute)

### D-09 — Operator copy (extends Phase 57 D-09)

- Above threshold CTA: “Submit change request”
- Threshold line: observed vs limit — e.g. “Exceeds direct-apply limit (update limit: 2, found: 5 references).”
- Basis: “Population impact is estimated from authored references and explicit samples only.”
- Indeterminate: use core `@indeterminate_remediation` / breach remediation strings — do not paraphrase into population language.

### D-10 — Partial visibility tiers (ADM-03)

Derive tier from existing dependency inventory redaction (no new auth stack):

| Tier | Condition | Confirm / preview evidence | Direct apply | CR submit |
|------|-----------|---------------------------|--------------|-----------|
| **Full** | `hidden_reference_count == 0`, not auth-denied | Full reference table + breach detail | Per verdict | Per verdict |
| **Partial** | `hidden_reference_count > 0` | Counts + “At least N hidden by your permissions” + redacted rows (`[REDACTED]` / “Hidden reference”) — **no hidden flag keys in breach observed fields** | Blocked (`:indeterminate`) | **Blocked** (Phase 58 — no core change in 59) |
| **Denied** | dependency list `{:error, :auth}` | `capability_explanation` only | Blocked | Blocked |

- Reuse `Rulestead.Admin.Redaction.redact_dependency_inventory/2`, `DependencyVisibility.visibility_resolver/1`, and `AudienceComponents` redaction patterns; extract shared `impact_references_table` if needed.
- **Approve/execute** on CR show: require **Full** tier for current actor (re-fetch dependencies on load); otherwise `capability_explanation` — “Broader flag read access required to approve this change.”
- **Never** render audience predicate/conditions on governance panels.

### D-11 — Below-threshold protected path

- Unchanged operator flow: preview → confirm → **Apply** → audience show + flash.
- Optional subtle panel: “Direct apply allowed for this environment” (neutral tone) — planner discretion.

### D-12 — Tests and DX

- LiveView tests: production env, seeded refs, policy modules with `change_request_required?` / `self_approval_allowed?` variants.
- Assert HTML for governed confirm (no Apply, Submit CR present), post-submit redirect to CR show, indeterminate blocked state.
- Contract-level: continue using `Rulestead.submit_change_request/1` in tests — UI calls same facade.
- No new standalone routes; no bulk mutation UI.

### Claude's Discretion

- Exact `blast_radius_panel` markup/CSS (use existing `FlagComponents.callout`, `section_card`, `summary_grid` patterns).
- Whether below-threshold shows optional “direct apply allowed” callout.
- Collapsible breach UI (`<details>` vs always-visible on CR show).
- Extract vs inline `impact_references_table` helper.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and prior phases
- `.planning/ROADMAP.md` — Phase 59 goal, success criteria, ADM-01–03
- `.planning/REQUIREMENTS.md` — ADM-01, ADM-02, ADM-03
- `.planning/phases/57-blast-radius-threshold-contract/57-CONTEXT.md` — verdict semantics, copy principles, assessment shape
- `.planning/phases/58-change-request-integration/58-CONTEXT.md` — CR submit/execute, metadata embedding
- `.planning/phases/58-change-request-integration/58-VERIFICATION.md` — shipped CR contract evidence

### Product and UX anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` — preview → confirm → audit, mounted posture, change-request review IA
- `prompts/elixir_feature_flags_research_brief.md` §4.1, §4.7 — governance not luxury; runtime vs control-plane separation
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned Policy, fail-closed, no predicate leakage
- `prompts/rulestead-domain-language-field-guide.md` — audience, change request, environment vocabulary
- `prompts/rulestead-host-app-integration-seam.md` — mount path, host auth ownership

### Code (integration points)
- `rulestead/lib/rulestead.ex` — `assess_audience_blast_radius/2`, `submit_change_request/1`, `apply_audience_mutation/1`
- `rulestead/lib/rulestead/governance/blast_radius_threshold.ex`
- `rulestead/lib/rulestead/governance/audience_mutation_change_request.ex`
- `rulestead/lib/rulestead/admin/redaction.ex`, `rulestead/lib/rulestead/admin/dependency_visibility.ex`
- `rulestead_admin/lib/rulestead_admin/live/audience_live/{edit_preview,edit_confirm,archive_preview,archive_confirm}.ex`
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`
- `rulestead_admin/lib/rulestead_admin/components/audience_components.ex`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AudienceComponents.impact_preview/1` — preview basis, fingerprint, affected references (extend via composition, not merge)
- `AudienceComponents.used_by_table/1` — redacted dependency row pattern for ADM-03
- `OperatorComponents.capability_explanation/1` — policy-denied actions
- `AudienceLive.Shared` — scope opts, stale preview redirect, query params for fingerprint
- `ChangeRequestLive.Show` — review hub; approve/execute confirm chain already exists
- `Session.current_path/3`, `Session.policy_state/1` — mount + capability assigns

### Established Patterns
- Preview → confirm → outcome; drift via `?drifted=true` push to preview
- `[REDACTED]` flag keys; `policy_denied` visibility on dependency entries
- CR show: diff first, simulation/audit secondary
- Tests use `conn_case` policy modules (`change_request_required?`, `allow_self_approval?`)

### Integration Points
- Branch `handle_event` on confirm: `"apply"` vs `"submit_change_request"`
- `load_preview` / `load_confirm`: assess + dependency hidden count
- CR show: match `governed_action == "apply_audience_mutation"` for governance panel

</code_context>

<specifics>
## Specific Ideas

- **GitHub PR mental model:** Submit CR → land on request detail (CR show), not queue hunt.
- **LaunchDarkly / Flagsmith:** Primary CTA becomes “request approval” when gate trips — not silent apply failure.
- **Terraform plan + policy:** Evidence-bound gate with named breach reasons; indeterminate = fix inputs, not “request exception.”
- **GrowthBook revision flow:** Explicitly **not** adopted — would add a fourth step and parallel draft state.
- **Unleash env-wide CR:** Rulestead stays **threshold-scored**, not “all prod edits need CR.”

</specifics>

<deferred>
## Deferred Ideas

- **Propose CR with partial visibility** (hidden refs → indeterminate but allow submit): requires Phase 58 submit validation change + metadata `visibility_incomplete` — defer to backlog (GOV-02-ext / ADM-03-ext).
- Blast-radius panel on audit timeline / generic CR types (ruleset publish).
- Host-configurable threshold profiles UI (Phase 60 docs only).
- Keyboard shortcuts for CR submit (not required for 59).

</deferred>

---

*Phase: 59-mounted-governance-workflows*
*Context gathered: 2026-05-27*
