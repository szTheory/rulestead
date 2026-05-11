# Phase 11: Mounted Admin Governance and Schedule UI - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning
**Research mode:** advisor-heavy one-shot synthesis across governance IA, review surface hierarchy, action flow, schedule visibility, and per-flag linking

<domain>
## Phase Boundary

Expose change requests, approval review, and scheduled-change visibility inside `rulestead_admin` without breaking the mounted sibling-package boundary. Phase 11 adds route-backed governance and schedule surfaces plus lightweight per-flag summaries inside the existing admin shell.

**In scope:**
- Mounted routes and navigation additions for change requests and schedule visibility
- A dedicated change-request inbox and detail/review surface
- A dedicated schedule list/detail surface for upcoming, completed, failed, quarantined, and cancelled scheduled changes
- Diff, simulation context, approval state, and explicit approval/execution actions on the review surface
- Compact per-flag summary cards linking into governance and schedule routes
- Accessibility and sibling-package verification for the new mounted flows

**Out of scope (explicitly deferred):**
- Changing the admin mount-path contract to shorter top-level URLs
- Turning `rulestead_admin` into a standalone app or broadening its package/release posture
- Calendar-first scheduling UX, full scheduler workbench interactions, or heavy custom JS calendar widgets
- Inline governance workbenches on the flag detail page
- Webhook visibility and delivery surfaces from Phase 12

</domain>

<decisions>
## Implementation Decisions

### Governance IA and routes
- **D-01:** Phase 11 uses a hub-and-spoke IA: add a dedicated route-backed change-request queue plus a dedicated route-backed schedule surface, while keeping per-flag pages as calm read surfaces with deep links.
- **D-02:** Under the current mounted router seam, the canonical Phase 11 paths should live inside the existing mount path rather than requiring a mount-path redesign. Concretely: `/admin/flags/change-requests`, `/admin/flags/change-requests/:id`, `/admin/flags/schedule`, and `/admin/flags/schedule/:scheduled_execution_id` with canonical `?env=` state.
- **D-03:** If the project later wants shorter URLs such as `/admin/change-requests` or `/admin/schedule`, treat that as a separate mount-path decision, not a Phase 11 dependency.
- **D-04:** Do not overload `/admin/flags/audit` with pending review work. Audit remains append-only history; change requests and scheduled executions remain actionable workflow objects.

### Change-request review surface
- **D-05:** Use one dedicated route-backed review/detail page per change request as the canonical governance review surface.
- **D-06:** The review page is diff-first. A compact summary band above the diff carries approval status, execution readiness, environment, actor chain, and conflict/staleness warnings.
- **D-07:** The page must answer “what changes, who requested it, what approvals are required, and what happens next?” without forcing operators to cross-reference multiple screens.
- **D-08:** Keep simulation context, approval history, and related audit references on the review page as secondary context beneath or beside the proposed change diff, not as separate mandatory navigation steps.

### Approval and execution action model
- **D-09:** Approval and execution remain separate actions, even when they occur on the same review route.
- **D-10:** `Approve` and `Reject` are the primary review actions while the request is awaiting review. Once approved, the same page reveals an explicit second-stage execution panel for `Execute now` or `Schedule`.
- **D-11:** Do not auto-execute on approval and do not ship a combined “approve and execute” primary path for governed production mutations.
- **D-12:** Every mutating action on the review path preserves the project’s interaction spine: `preview -> confirm -> audit`, with explicit reason capture where state changes.
- **D-13:** Copy and audit rendering must keep the actor chain honest and distinct: `requested by`, `approved by`, `scheduled by`, and `executed by scheduler`.

### Schedule visibility surface
- **D-14:** `/admin/flags/schedule` defaults to a dense, filterable operator list grouped and filterable by state, not a calendar-first experience.
- **D-15:** The schedule list is the canonical Phase 11 surface for scanning `scheduled`, `running`, `completed`, `failed`, `quarantined`, and `cancelled` items, with explicit row-level links back to both the flag and the linked change request when present.
- **D-16:** If a calendar appears in Phase 11 at all, it must be secondary and read-oriented only, such as a toolbar toggle or date-filter aid layered over the list. It must not replace the list as the primary workflow.
- **D-17:** Scheduled execution UI must treat the Phase 10 scheduled execution record as product truth rather than Oban job rows or ephemeral client state.

### Flag-detail linking posture
- **D-18:** Keep `/admin/flags/:key` as a calm read surface. Do not embed rich inline approval, reschedule, or conflict-resolution workflows there.
- **D-19:** Add two compact summary cards to flag detail: `Open change requests` and `Scheduled changes`.
- **D-20:** Each summary card should show a count plus the most actionable 1-3 preview rows and a single primary link into the dedicated route-backed workflow page.
- **D-21:** Card previews are read-only, truncated, and redaction-safe. They exist to improve discoverability and triage, not to duplicate the full review/schedule workbench.

### Interaction and copy posture
- **D-22:** Keep environment routing canonical through `?env=` on every new governance and schedule route, preserving the current session/mount conventions.
- **D-23:** Prefer calm operational copy: `change request`, `review`, `approve`, `reject`, `schedule`, `execute now`, `quarantined`, `failed`, `scheduled by`, `approved by`, `executed by scheduler`.
- **D-24:** Avoid ambiguous workflow language such as `apply`, `campaign`, `journey`, or `pipeline` when the system means a specific governed action.

### the agent's Discretion
- Exact LiveView/module split between queue/detail/list/detail screens, provided the route-backed workflow boundary stays intact
- Exact visual arrangement of summary bands, side rails, and action footers on the review page, provided the diff remains primary
- Exact filter control ordering and responsive collapse rules on the schedule list, provided the list stays the canonical surface
- Exact preview-row density and truncation rules for per-flag summary cards, provided they remain compact and read-only
- Exact calendar toggle implementation, provided it stays secondary and does not introduce an accessibility-hostile primary workflow

</decisions>

<specifics>
## Specific Ideas

- Use the current mount seam as-is and extend it with sibling governance routes rather than reopening the host integration contract in Phase 11.
- Treat change requests as review objects and scheduled executions as time-based operational objects. They are linked, but they should not be collapsed into one muddy UI abstraction.
- The review page should feel closer to a good PR review surface than to an approval inbox: proposed change first, governance state second, execution/scheduling readiness third.
- The schedule screen should feel closer to an operator console such as Oban Web or LiveDashboard than to a calendar app.
- Keep flag detail teachable and low-anxiety: surface that governance exists for this flag, but route operators into the canonical review/schedule pages for actual work.
- User preference for this project: shift recommendation work left in GSD and ask fewer decision questions unless a choice is truly high-impact or product-defining. Phase 11 context intentionally locks the above decisions so planning can proceed without reopening them.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 11 goal, plan slices, and explicit mounted-package boundary
- `.planning/PROJECT.md` — governance milestone goals, sibling-package constraints, and operator-trust posture
- `.planning/REQUIREMENTS.md` — source of truth for `GOV-05` and `SCH-03`
- `.planning/STATE.md` — confirms the milestone sequence and current frontier after Phase 10

### Prior locked decisions
- `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-CONTEXT.md` — calm flag detail surface, dedicated route-backed workspaces, and canonical `?env=` model
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — explicit route-backed operator flows, append-only audit posture, and preview/confirm/audit discipline
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-VERIFICATION.md` — governance core contracts, actor chain, approval lifecycle, and public/store boundary already proven in core
- `.planning/phases/10-scheduled-changes-and-durable-execution/10-CONTEXT.md` — scheduled execution model, durable state semantics, and actor/audit expectations the UI must preserve

### Product, UX, and language direction
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted operator IA, route direction, and schedule/change-request surface expectations
- `prompts/rulestead-domain-language-field-guide.md` — canonical vocabulary for change requests, approvals, scheduled changes, failures, and operator copy
- `prompts/rulestead-brand-book.md` — calm infrastructure-grade copy and visual posture
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned auth, least-surprise controls, and audit/redaction posture
- `prompts/rulestead-host-app-integration-seam.md` — mounted-package and host-owned integration seam constraints

### Existing code and contracts
- `rulestead_admin/lib/rulestead_admin/router.ex` — current mount seam and route shape that Phase 11 should extend
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — canonical env/session/policy resolution and `?env=` behavior
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — current admin shell and environment switching posture
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — calm flag detail pattern and existing link-out posture
- `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` — append-only per-flag audit rendering conventions
- `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` — global audit filtering posture that governance UI should complement, not overload
- `rulestead/lib/rulestead.ex` — public governance and scheduled execution facade functions already exposed
- `rulestead/lib/rulestead/store/command.ex` — command shapes for change-request approval/execution and scheduled execution list/fetch/cancel/requeue
- `rulestead/lib/rulestead/governance/change_request.ex` — canonical change-request contract and state/action vocabulary
- `rulestead/lib/rulestead/governance/approval.ex` — approval contract shape
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` — scheduled execution contract and state model
- `rulestead/doc/admin-ui.md` — current documented mounted admin navigation contract and public/stable host-facing expectations

### External ecosystem references
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — route-backed LiveView patterns, `handle_params/3`, and URL-driven state
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` — LiveView navigation semantics for route-backed workflows
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — mounted auth/policy posture through `live_session` and `on_mount`
- `https://launchdarkly.com/docs/home/releases/approvals` — approvals dashboard and local/global review surface lessons
- `https://launchdarkly.com/docs/home/releases/approval-reviews` — diff/review-first approval page lessons
- `https://launchdarkly.com/docs/home/releases/scheduled-changes` — scheduled change visibility lessons
- `https://launchdarkly.com/docs/home/releases/scheduled-changes-manage` — schedule conflict handling and operator warnings
- `https://docs.getunleash.io/concepts/change-requests` — explicit request lifecycle and centralized review lessons
- `https://docs.getunleash.io/api/get-scheduled-change-requests` — scheduled change request visibility patterns
- `https://oban.pro/docs/web/filtering.html` — list/filter-first operator console patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RulesteadAdmin.Router` already provides the correct mounted route seam. Phase 11 should add sibling routes beneath the existing mount path rather than inventing a second router model.
- `RulesteadAdmin.Live.Session` already centralizes actor, environment, env links, mount path, and policy state. Governance and schedule pages should reuse this directly.
- `RulesteadAdmin.Components.Shell` already establishes the calm page shell and env-switching pattern that the new routes should inherit.
- Existing audit and flag-detail components already show how to render append-only state and link out to dedicated workflows without stuffing everything into one page.
- Core contracts for change requests, approvals, and scheduled executions already exist in `rulestead`; Phase 11 can focus on projection and workflow presentation rather than inventing new domain nouns.

### Established Patterns
- The repo consistently prefers explicit route-backed workflows over hidden inline state machines.
- Environment state is URL-backed through `?env=` and should remain so on all new pages.
- Append-only audit and explicit actor-chain wording are already first-class concerns; governance UI should preserve and reinforce them.
- Mounted sibling-package architecture and host-owned policy/auth are non-negotiable; new UI work must not erode that seam.

### Integration Points
- The change-request queue/detail screens should consume the existing change-request fetch/list/approve/reject/execute public/store surfaces rather than bypassing them.
- The schedule list/detail screens should consume `list_scheduled_executions`, `fetch_scheduled_execution`, and related cancel/requeue operations against the scheduled execution record as source of truth.
- Flag detail summary cards should query lightweight governance/schedule summaries using the same underlying filters and environment semantics as the dedicated inbox/schedule pages so counts and previews do not drift.
- Accessibility and sibling-package verification should extend the existing `rulestead_admin` router/live-session integration tests and accessibility posture rather than inventing a separate verification style.

</code_context>

<deferred>
## Deferred Ideas

- Shorter mount-path URLs such as `/admin/change-requests` or `/admin/schedule`
- Calendar-first scheduling UI or a heavy interactive calendar widget
- Inline governance workbenches on flag detail
- Combined audit/ops center that collapses append-only history and actionable review into one surface
- Webhook visibility and delivery UI from Phase 12

</deferred>

---

*Phase: 11-mounted-admin-governance-and-schedule-ui*
*Context gathered: 2026-04-24*
