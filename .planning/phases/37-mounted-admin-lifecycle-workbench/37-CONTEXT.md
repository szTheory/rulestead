# Phase 37: Mounted Admin Lifecycle Workbench - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning
**Source:** discuss-all synthesis with advisor subagent research, prior phase context, prompt-anchor review, codebase inspection, and official ecosystem references

<domain>
## Phase Boundary

Deliver the mounted-admin lifecycle workbench for operators by turning the existing lifecycle/readiness surfaces into one coherent review-and-act workflow: URL-backed lifecycle filtering, owner-aware triage, detail-page lifecycle projection, and explicit archive/cleanup actions that preserve preview-before-mutation, reason capture, and audit continuity.

**In scope:**
- lifecycle/readiness/owner filtering as a shareable mounted-admin workbench
- detail and cleanup surfaces that support lifecycle triage without turning detail into an action hub
- explicit single-flag archive/cleanup actions with preview, reason capture, revalidation, and audit linkage
- post-action navigation that preserves operator queue context and archived visibility

**Out of scope:**
- standalone lifecycle console or separate admin product surface
- bulk archive or bulk cleanup mutation flows
- fuzzy owner identity truth or host-owned directory replication
- automatic archive, hidden cleanup mutations, or non-URL-backed workflow state

</domain>

<decisions>
## Implementation Decisions

### Product shape and recommendation posture
- **D-01:** Phase 37 should stay recommendation-first and narrow. Downstream planning should lock ordinary implementation tradeoffs in-agent and re-open only choices that materially change product scope, public contract, security/governance posture, release shape, package boundaries, or other unusually high-impact operator semantics.
- **D-02:** The lifecycle workbench remains inside the mounted sibling-package posture. No standalone control-plane drift, no alternate admin package behavior, and no widening beyond the linked-version two-package model.
- **D-03:** Phase 37 keeps the lifecycle story explicit and operator-led: review first, mutate second, audit always.

### Workbench information architecture
- **D-04:** The existing flag inventory is the **canonical lifecycle workbench**. Phase 37 should extend the existing `FlagLive.Index` surface rather than introduce a separate dedicated lifecycle LiveView.
- **D-05:** If a more discoverable lifecycle entrypoint is needed, use a **route-backed lifecycle preset or shortcut** that resolves into the same inventory/filter schema, not a second filter dialect or second list truth.
- **D-06:** The mounted admin should keep one canonical URL/query contract for lifecycle triage. Environment, lifecycle, stale/freshness, readiness, evidence quality, archived visibility, and owner filters must remain URL-backed and shareable.
- **D-07:** The detail page remains a calm read surface with lifecycle guidance and links into the cleanup/action flow. It must not become the primary mutation workbench.

### Owner filter contract
- **D-08:** The canonical owner filter should be **stable and exact** against `owner_ref` semantics, not loose identity-by-label matching.
- **D-09:** To avoid legacy/operator friction, Phase 37 should use a **split contract**:
  - one canonical exact owner filter for durable `owner_ref` matching
  - separate free-text discovery through the broader query/search surface for `owner_display`, legacy labels, or descriptive text
- **D-10:** Saved URLs and downstream command/store filters must preserve the stable meaning of owner filtering across display renames and host-side label changes.
- **D-11:** `owner_display` remains advisory readability data, never identity truth and never the canonical lifecycle filter contract.

### Mutation scope
- **D-12:** Phase 37 should ship **single-flag lifecycle actions only**. Archive/cleanup mutation flows remain per-flag so preview, reason capture, authorization, and audit attribution stay unambiguous.
- **D-13:** Bulk archive and bulk cleanup are explicitly deferred. Even a bounded batch archive flow would introduce preview freezing, partial-failure semantics, and batch audit vocabulary that this phase should avoid.
- **D-14:** The lifecycle workbench can still feel useful without bulk actions by optimizing queue continuity, filter quality, and clear action entrypoints.

### Preview, confirmation, and audit flow
- **D-15:** The existing `/cleanup` screen becomes the **canonical pre-mutation review surface** for lifecycle actions.
- **D-16:** Archive/cleanup actions should branch from cleanup into explicit **route-backed preview -> confirm -> audit** steps with required reason capture.
- **D-17:** Modal-only mutation from list/detail should be avoided for the main workflow. It weakens shareable state, reconnect resilience, and the existing calm-detail posture.
- **D-18:** Preview flows must surface the same bounded lifecycle evidence from Phase 36: readiness, evidence quality, reasons, unknowns, blockers, and recommended next action, plus a clear statement of what the mutation will change.
- **D-19:** Mutation confirmation should revalidate the flag’s current lifecycle state before apply so stale previews cannot silently archive based on drifted evidence or changed authored posture.

### Post-action navigation and visibility
- **D-20:** After a lifecycle action succeeds, operators should return to the **same filtered workbench URL state** they came from, not remain on detail/cleanup as the default landing page.
- **D-21:** The return path must keep archived visibility explicit, for example by preserving or adding an archived-inclusion param and surfacing an outcome banner or highlighted row with an audit link. The operator must not hit a “where did it go?” disappearance.
- **D-22:** `return_to` or equivalent origin state must be URL-backed and canonicalized in `handle_params/3`, not reconstructed from socket/session memory.
- **D-23:** Between different LiveViews, use route-backed navigation semantics that match LiveView idioms:
  - patch within the current workbench LiveView for filter changes
  - navigate between index/detail/cleanup/preview surfaces

### the agent's Discretion
- Exact lifecycle preset naming and copy, provided it resolves into the same inventory route/filter semantics
- Exact owner-filter UI labeling, provided the stable `owner_ref` contract and looser discovery/search path remain visibly distinct
- Exact preview-route structure and component split, provided the workflow stays route-backed, explicit, and audit-safe
- Exact outcome-banner/highlight rendering on return to the workbench, provided archived visibility and audit linkage remain explicit

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“one canonical flag workbench with lifecycle presets”**, not “a separate lifecycle app inside the admin.”
- The best adjacent operator pattern is:
  - dense filter-first inventory
  - calm per-resource detail
  - dedicated review surface for destructive or governed actions
- Keep owner semantics honest:
  - `owner_ref` for stable filtering and audit continuity
  - `owner_display` for readability only
  - free-text search for discovery, not identity
- The mounted-admin interaction spine stays: **scan -> drill in -> review on cleanup -> confirm with reason -> return to queue with audit-linked outcome**.
- Unleash-style bulk lifecycle tooling is a useful later reference, but importing it now would outrun the repo’s current audit and preview discipline.
- ConfigCat-style stale/zombie heuristics are useful cautionary examples: weak or simplified inactivity signals should never masquerade as lifecycle truth.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 37 goal, milestone framing, and explicit mounted-admin lifecycle workbench boundary
- `.planning/PROJECT.md` — `v1.2.0` milestone goals, operator-trust posture, and linked-version package constraints
- `.planning/REQUIREMENTS.md` — `LIF-03` and `LIF-04` requirements for lifecycle visibility and explicit archive/cleanup flows
- `.planning/STATE.md` — current milestone position and current active-phase handoff posture
- `.planning/METHODOLOGY.md` — recommendation-first planning lens and the “only escalate very impactful choices” rule

### Prior locked decisions
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — route-backed workflow IA, calm detail surfaces, and preview/confirm/audit interaction spine
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md` — mounted-admin URL/state discipline and host-bounded scope visibility
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-CONTEXT.md` — stable `owner_ref` contract, authored lifecycle truth, and no auto-archive posture
- `.planning/phases/36-archive-readiness-signals-cleanup-analysis/36-CONTEXT.md` — read-only archive-readiness guidance, recommended action vocabulary, and cleanup-screen advisory boundary

### Prompt anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted operator IA, route-backed workflows, and calm admin UX principles
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package discipline, recommendation-first engineering DNA, and operator-console design precedents
- `prompts/rulestead-host-app-integration-seam.md` — mounted-host seam constraints and least-surprise integration posture
- `prompts/rulestead-domain-language-field-guide.md` — canonical lifecycle, owner, archive, and operator vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — explicit authorization, immutable audit, and least-privilege operator flows
- `prompts/phoenix-live-view-best-practices-deep-research.md` — idiomatic route-backed LiveView state, function-component bias, and URL-owned workflow patterns

### Existing code seams
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` — current inventory filters, lifecycle/readiness columns, and canonical URL-backed workbench surface
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — calm flag detail surface and lifecycle/drill-in presentation
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` — current advisory cleanup screen that becomes the mutation review entrypoint
- `rulestead_admin/lib/rulestead_admin/router.ex` — mounted route contract and available lifecycle-related screen seams
- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` — shared lifecycle, stale, readiness, and evidence badges/components

### External ecosystem references
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` — patch vs navigate semantics and `handle_params/3` URL-state patterns
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — async/navigation callback semantics and routed LiveView behavior
- `https://launchdarkly.com/docs/home/releases/approvals/` — centralized review/workflow lessons for operator mutation flows
- `https://launchdarkly.com/docs/fed-docs/home/flags/archive` — explicit archive guidance and cleanup posture
- `https://docs.getunleash.io/reference/feature-toggles` — lifecycle/stale/archive workflow lessons and later-phase bulk archive inspiration
- `https://docs.getunleash.io/reference/technical-debt` — stale/technical-debt workflow framing and caution around cleanup semantics
- `https://oban.pro/docs/web/filtering.html` — dense filter-first operator-console patterns in the Elixir ecosystem
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` — route-backed operator surfaces and BEAM-native workbench expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FlagLive.Index` already exposes the right lifecycle/readiness/evidence filter vocabulary and should remain the single canonical inventory/workbench.
- `FlagLive.Show` already keeps detail calm while surfacing lifecycle guidance and links; it can stay the support surface rather than becoming an action hub.
- `FlagLive.Cleanup` already centralizes evidence and uncertainty; it is the natural place to expand into preview/confirm flows.
- `FlagComponents` already provides the badge/stat primitives needed for consistent lifecycle workbench and preview rendering.

### Established Patterns
- Mounted-admin filters and operator state are encoded in URL params and normalized through `handle_params/3`.
- The repo consistently prefers dedicated route-backed workflows for governed/destructive actions instead of heavy inline modal orchestration.
- Durable authored truth and derived operator guidance are intentionally separate; Phase 37 should consume the shared projector rather than inventing screen-local lifecycle logic.
- Audit-safe operator flows prefer explicit reason capture and deep-linkable surfaces over ephemeral UI state.

### Integration Points
- Workbench filtering should extend the existing `Rulestead.list_flags/1` vocabulary rather than introducing a parallel lifecycle-query path.
- Owner-filter semantics should be enforced in command/store/list contracts with adapter parity, then reflected in mounted-admin copy and params.
- Cleanup preview/confirm flows should plug into the existing mounted-admin lifecycle detail/cleanup surfaces and the shared audit envelope rather than invent a standalone lifecycle command model.
- Post-action queue continuity should be wired through explicit `return_to` URL params and existing session/path helpers.

</code_context>

<deferred>
## Deferred Ideas

- Separate dedicated lifecycle screen or alternate workbench route with its own filter dialect
- Bulk archive actions, even if bounded to strong-evidence archive candidates
- Mixed bulk cleanup/archive orchestration
- Loose owner filtering that treats display labels as canonical identity
- Session-memory-based “return to previous filters” behavior
- Any automatic archive or implicit lifecycle mutation based on heuristics

</deferred>

---

*Phase: 37-mounted-admin-lifecycle-workbench*
*Context gathered: 2026-05-23*
