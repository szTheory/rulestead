# Phase 6: Admin UI - Flag List, Detail, Rule Editor, Environments, Lifecycle - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Research mode:** 5 parallel advisor passes across authoring workflow, editor workspace, lifecycle input model, environment switching, and list density

<domain>
## Phase Boundary

Ship the first operator-facing half of `rulestead_admin` as a mountable Phoenix LiveView package. Phase 6 covers the primary flag inventory, per-flag detail surface, dedicated rule editor, environment switching, lifecycle ownership/expiration capture, and the host-policy mount seam.

**In scope:**
- `rulestead_admin` mounted into a host Phoenix app via router macro
- Flag list with search/filter, pagination, keyboard navigation, lifecycle and owner visibility
- Flag detail surface for summary, current environment status, active/draft ruleset summary, and timeline placeholder
- Dedicated rule editor for create/edit/reorder/archive flows
- Environment selector with persistent preference and shareable URLs
- Lifecycle capture and display: owner, expected expiration, permanent state, stale indicators
- `Rulestead.Admin.Policy` seam and host-owned authorization integration

**Out of scope (explicitly deferred):**
- Simulation and explain workbench as full operator workflows
- Rollouts, kill switch UI, and operational controls
- Full audit timeline wiring and rich event drilldowns
- Security/redaction hardening beyond Phase 6 requirements
- Managed owner directory, approvals, scheduled changes, and broader governance features
- Alternate list view modes, autosaved persisted drafts, or other convenience chrome beyond the core operator workflow

</domain>

<decisions>
## Implementation Decisions

### Authoring Workflow
- **D-01:** Phase 6 uses a draft-first authoring model. Editing a flag's rules never mutates active runtime state directly.
- **D-02:** `Save draft` and `Publish` remain distinct user actions, matching the existing `save_draft_ruleset` and `publish_ruleset` store boundary.
- **D-03:** The UI must clearly surface `Active ruleset` versus `Draft ruleset` per environment so operators do not confuse saved work with live behavior.
- **D-04:** Do not persist autosaved drafts in Phase 6. Any richer autosave behavior stays client-side only until the user explicitly saves the draft.

### Workspace Shape
- **D-05:** Keep `/admin/flags/:key` as the calm read surface for a flag: summary, lifecycle, env state, recent changes placeholder, and compact rules snapshot.
- **D-06:** Put serious authoring in a dedicated `/admin/flags/:key/rules` workspace rather than overloading the detail page or relying on modals/drawers.
- **D-07:** The dedicated rules workspace is where drag-reorder, condition building, segment selection, and variant weight editing live.
- **D-08:** The detail page must link clearly into the rules workspace and reflect whether a draft exists for the current environment.

### Owner and Lifecycle Model
- **D-09:** Creating or editing a flag in Phase 6 requires both an `owner` value and either an `expected_expiration` date or an explicit `permanent` choice.
- **D-10:** Keep `owner` as a normalized free-text string in Phase 6. Do not introduce a managed owner directory yet.
- **D-11:** Permanent flags must be represented explicitly, not by abusing a fake far-future expiration date.
- **D-12:** Add lightweight UX assists only: normalization, recent-owner suggestions, and clear lifecycle copy. Defer directory-backed ownership to a later governance phase.

### Environment Model
- **D-13:** Use one global environment picker in the admin chrome as the primary environment model for Phase 6.
- **D-14:** The URL query param `env` is the canonical source of truth for current environment state on admin pages.
- **D-15:** A remembered last-used environment may be used only as a fallback when the URL omits `env`. URL state always wins.
- **D-16:** Do not encode environment primarily in the path. Rulestead flags are single identities with per-environment behavior, not separate per-env resources.
- **D-17:** Production must be visually explicit in the UI so remembered or switched env state does not become a hidden footgun.

### Flag List Defaults and Density
- **D-18:** The main `/admin/flags` surface is a dense operator table optimized for scanning, not a card-first interface.
- **D-19:** Default list scope is the current environment, non-archived flags only, with quick filters and URL-backed filter state.
- **D-20:** Prioritize columns/operators that support real operator work: key, type, owner, lifecycle state, environment state, stale indicator, and last changed.
- **D-21:** Do not ship alternate list view modes in Phase 6. One strong default table is preferable to a half-finished table/card split.
- **D-22:** Density should still feel calm, not cramped: readable row rhythm, strong status badges, and a clear monospace flag key.

### the agent's Discretion
- Exact LiveView/module/component split inside `rulestead_admin`
- Exact persistence mechanism for remembered env preference
- Exact schema representation for explicit permanent state, provided it does not use a sentinel date
- Exact table column ordering and responsive collapse rules, provided the scanning-first principle stays intact
- Exact wording of publish/draft banners and lifecycle helper copy, provided it stays calm and non-marketing

</decisions>

<specifics>
## Specific Ideas

- Treat the Phase 6 admin like an operator tool, not a marketing dashboard: dense list first, summary/detail second, dedicated editing workspace third.
- Match the existing core authoring contract instead of inventing a second model in the admin package. The current store already distinguishes draft from publish; the UI should make that model legible.
- Use Phoenix LiveView idioms that travel well inside a mountable package: route-backed screens, `handle_params`-driven filter/env state, and explicit actions rather than hidden magic.
- Keep the first version teachable to Priya and safe for Sam/Shiori: clear environment scope, visible owner/lifecycle data, explicit publish boundary.
- Defer optionality that multiplies UI and test surface without changing the core value: alternate list modes, autosaved persisted drafts, owner directory management.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 6 goal, scope, and explicit boundary against Phase 7 admin workflows
- `.planning/PROJECT.md` — product non-negotiables: calm admin UI, host-owned auth, sibling-package design, operator trust
- `.planning/REQUIREMENTS.md` — source of truth for `ADMIN-01`, `ADMIN-02`, `ADMIN-03`, `ADMIN-08` (UI), `ADMIN-10`, and `LIFE-01..04`
- `.planning/STATE.md` — confirms Phase 6 as the current frontier

### Prior Locked Decisions
- `.planning/phases/01-repo-bootstrap/01-CONTEXT.md` — sibling-package and release constraints for `rulestead_admin`
- `.planning/phases/03-context-rules-deterministic-bucketing-pure-evaluator/03-CONTEXT.md` — evaluator and explainability substrate the admin will present
- `.planning/phases/04-snapshot-cache-runtime-refresh-telemetry-explain-wiring/04-CONTEXT.md` — runtime/explain/diagnostics boundaries the admin must respect
- `.planning/phases/05-host-app-seams-plug-liveview-oban-installer-test-helpers/05-PATTERNS.md` — local Phoenix/LiveView seam patterns and router/install analogs

### Product and UX Direction
- `prompts/rulestead-admin-ux-and-operator-ia.md` — primary IA and operator interaction thesis for the mounted admin
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — persona goals for Priya, Sam, and Shiori that shape the admin defaults
- `prompts/rulestead-brand-book.md` — calm, infrastructure-grade visual and copy posture
- `prompts/rulestead-domain-language-field-guide.md` — canonical nouns and lifecycle terminology for flag, owner, environment, stale state, and audit language

### Existing Code and Contracts
- `rulestead_admin/lib/rulestead_admin/router.ex` — current router-macro seam the Phase 6 admin must replace/extend
- `rulestead/lib/rulestead/store.ex` — authoring-store behavior with draft/publish/list/archive verbs
- `rulestead/lib/rulestead/store/command.ex` — command structs and current list/search/publish selectors
- `rulestead/lib/rulestead/store/ecto.ex` — actual flag payload shape, active/draft ruleset exposure, and lifecycle/archive semantics
- `rulestead/lib/rulestead/flag.ex` — current owner/expiration fields and validation baseline
- `rulestead/lib/rulestead/flag_environment.ex` — current per-environment status model
- `rulestead/lib/rulestead/environment.ex` — environment identity surface the admin should present
- `rulestead/lib/rulestead/ruleset.ex` — draft/published ruleset shape
- `rulestead/lib/rulestead/ruleset/rule.ex` — rule authoring surface the Phase 6 editor must handle
- `rulestead/lib/rulestead.ex` — root public admin mutation entrypoints already exposed
- `rulestead/lib/rulestead/fake.ex` — test-facing fake store behavior that planning should preserve for admin tests

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Store` already exposes the correct Phase 6 authoring verbs: list, save draft, publish, archive. The admin should compose these rather than inventing a parallel workflow.
- `Rulestead.Store.Ecto` already returns both `active_ruleset` and `draft_rulesets` in flag payloads, which directly supports a draft-first UI.
- `Rulestead.Flag`, `Rulestead.Environment`, and `Rulestead.FlagEnvironment` already hold most of the lifecycle/environment vocabulary Phase 6 needs.
- `RulesteadAdmin.Router` already establishes the mount seam, even though it is still a stub.

### Established Patterns
- The repo favors explicit seams over hidden magic: host-owned auth, explicit context, explicit runtime APIs, explicit installer injection.
- Prior phases keep public behavior stable and visible. Phase 6 should do the same for admin actions: obvious env scope, obvious publish boundary, obvious lifecycle state.
- Existing host-app integration work in Phase 5 points toward route-backed LiveView surfaces rather than ad hoc embedded widgets.

### Integration Points
- The list page will lean on `list_flags` and likely need planning attention around pagination evolution from the current offset-based command shape toward the roadmap's keyset goal.
- The rules workspace should integrate with existing `save_draft_ruleset` and `publish_ruleset` entrypoints rather than bypassing them.
- Lifecycle and archive behavior should reflect current `archived_at` and `flag_environment.status` semantics instead of inventing new hidden state machines in the UI.
- Any Phase 6 tests should preserve fake-backed workflows so the admin package remains reproducible in CI and local development.

</code_context>

<deferred>
## Deferred Ideas

- Persisted autosave drafts and richer collaborative editing semantics
- Managed owner/team directory and tighter ownership-policy coupling
- Alternate list views, density toggles, or card-first browsing modes
- Environment-in-path routing or cross-environment compare workflows
- Full simulation, explain workbench, rollout controls, kill switch, and full audit timeline wiring
- Governance features: approvals, scheduled changes, and stronger change-request flows

</deferred>

---

*Phase: 06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle*
*Context gathered: 2026-04-23*
