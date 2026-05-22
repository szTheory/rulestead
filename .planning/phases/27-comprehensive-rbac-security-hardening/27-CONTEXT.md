# Phase 27: Comprehensive RBAC & Security Hardening - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning
**Source:** roadmap boundary, prior phase context, prompt anchors, local code inspection, and five parallel advisor passes across contract shape, role model, UI enforcement, admin-only boundaries, and host integration posture

<domain>
## Phase Boundary

Enforce strict, dependency-free role-based access control for the mounted admin UI and core admin/API operations without breaking the host-owned auth seam or the sibling-package release design.

**In scope:**
- a coherent v1.0 role model for operators
- explicit authorization rules for admin reads, mutations, governance, promotion, scheduling, diagnostics, and webhook/admin settings surfaces
- pure Elixir, context-based authorization through the existing mounted-policy and core-authorizer seams
- UX hardening so authorization is explicit, teachable, and least-surprise for operators
- documentation and examples that make the RBAC model easy for host apps to adopt

**Out of scope (explicitly deferred):**
- custom arbitrary role builders or user-defined permission graphs
- third-party authorization framework dependencies
- replacing host identity, session, or router ownership
- turning `rulestead_admin` into a standalone control-plane product
- broad ABAC/policy-language expansion beyond the bounded admin/domain actions needed for v1.0

</domain>

<decisions>
## Implementation Decisions

### RBAC Contract Shape
- **D-01:** Keep the stable host-facing authorization seam centered on `Rulestead.Admin.Policy.can?/4`. Host apps continue to own identity, session, and final authorization decisions.
- **D-02:** Do **not** expand Phase 27 into a Bodyguard-style policy DSL or a broader framework-shaped authorization system. That is over-scoped for v1.0 and would freeze too much surface too early.
- **D-03:** Phase 27 should standardize a **closed action/resource/environment vocabulary** for admin authorization and use that vocabulary consistently across `rulestead`, `rulestead_admin`, docs, installer scaffolds, and tests.
- **D-04:** Rulestead may ship a **reference policy shape** or generated host stub for DX, but the product contract remains the host-owned policy callback, not a mandatory library-owned role engine.
- **D-05:** Any reference policy or generated scaffold must be framed as the recommended default mapping for v1.0, not as a requirement that hosts rename their auth model to match Rulestead internals.

### Role Model and Compatibility
- **D-06:** Formal product truth for v1.0 is exactly three static roles: **Viewer**, **Editor**, and **Admin**.
- **D-07:** Existing richer role names in current fallback behavior are **not** first-class permanent product roles. They are, at most, compatibility or example mappings during transition.
- **D-08:** Compatibility posture:
  - `viewer` and temporary `auditor` map to **Viewer**
  - `operator` and `engineer` map to **Editor**
  - `admin` maps to **Admin**
  - `incident_commander` and `prod_operator` are not base product roles; they are host-side or example policy concepts for environment-specific elevated actions
- **D-09:** UI copy, docs, and examples should teach only **Viewer / Editor / Admin** as the canonical vocabulary. Legacy names should not leak into the core product language.
- **D-10:** The fallback compatibility layer should be explicitly temporary and documented so it does not become accidental long-term API debt.

### Host Integration Posture
- **D-11:** Host apps should not be forced to model identity exactly as Rulestead roles internally. They should map their users/groups/claims into Rulestead authorization outcomes at the policy seam.
- **D-12:** The recommended adoption model is hybrid:
  - stable contract stays action/resource/environment-oriented
  - Rulestead provides a recommended Viewer/Editor/Admin mapping in docs and generated stubs
  - hosts may wrap or replace that mapping to fit their own auth model
- **D-13:** Phase 27 must preserve the mounted-library norm already established in the repo and broader Phoenix ecosystem: host router + host session + host auth pipeline outside, bounded policy seam inside.
- **D-14:** Internal fallback role behavior should be demoted from implied product truth to bounded compatibility behavior, so the public contract is clearer than the current codebase state.

### Permission Boundary for Viewer, Editor, and Admin
- **D-15:** **Viewer** is read-only across current observational and review-oriented surfaces:
  - flag inventory/detail
  - ruleset and rollout read surfaces
  - simulation/explain read results
  - audit/timeline
  - change-request detail
  - schedule detail
  - webhook visibility
  - diagnostics
  - compare previews
- **D-16:** **Editor** is flag-scoped and proposal-capable, not control-plane-capable. Editors may mutate authored flag state and create proposals/schedules only where the environment/policy already permits the underlying action.
- **D-17:** Editor scope includes:
  - create/update/archive flags
  - save drafts
  - publish or directly mutate in non-protected contexts when policy allows
  - non-protected rollout and kill-switch operations when policy allows
  - submit and cancel their own change requests before approval
  - create schedules for actions they are already allowed to perform
  - compare and direct promotion for non-protected targets when policy allows
- **D-18:** **Admin** owns elevated control-plane and protected-environment authority:
  - approve/reject/execute governed actions
  - protected-environment publish/kill/rollout/promotion authority
  - cancel/requeue/recover scheduled executions
  - audit rollback/export
  - webhook destination and ingress-secret management
  - environment/policy/redaction/hook/integration settings
  - any cross-environment or system-level action that changes the control plane rather than one flag’s authored state
- **D-19:** “Admin-only” should mean **system or governance authority**, not simply “sensitive feeling action.” Flag-scoped authoring belongs to Editors; control-plane and protected-target decisions belong to Admin.

### UI Enforcement Posture
- **D-20:** Use a **hybrid enforcement posture** in the mounted admin UX:
  - deny session entry for actors with no admin read scope at all
  - keep read-oriented routes visible when they provide operational context
  - render unauthorized mutating affordances as disabled with a precise explanation
  - continue to enforce every action server-side and preserve denied-action audit visibility
  - redirect or hard-deny mutation-first routes that have no useful read-only value
- **D-21:** Do **not** default to hide-everything or deny-only-on-submit as the main operator UX. Both create unnecessary confusion for mounted operator tooling.
- **D-22:** Authorization explanations in UI should be environment-aware and concrete, for example:
  - `Requires Admin in production`
  - `Change request required in production`
  - `Editors can propose this change but cannot execute it`
- **D-23:** Capability display must be derived from the same underlying policy/authorizer vocabulary as server enforcement, so UI state and backend truth do not drift.
- **D-24:** Accessibility matters here: disabled affordances must be real disabled controls or `aria-disabled` equivalents with readable reason text, not merely dimmed visuals.

### Security and Least-Surprise Posture
- **D-25:** Preserve environment-sensitive authorization as a first-class rule. The same action may be Editor-allowed in lower-risk environments and Admin- or governance-gated in protected ones.
- **D-26:** Keep default-deny behavior on all security-critical mutation paths. Policy errors or missing mappings fail closed.
- **D-27:** Denied actions remain part of the audit/security story, but the UI should not rely on trial-and-error denial as the primary operator experience.
- **D-28:** Phase 27 should bias toward recommendation-first downstream planning and implementation. Re-open questions only if they materially change product scope, security posture, public contract, or release shape.

### the agent's Discretion
- Exact module and file split for policy helpers, capability projection, and admin affordance rendering, provided the stable seam remains host-owned and the role model stays small.
- Exact action/resource enum names, provided they remain closed, teachable, and shared across code/docs/tests.
- Exact compatibility/deprecation mechanics for legacy fallback role names, provided Viewer/Editor/Admin become the only canonical public vocabulary.
- Exact page-level read-only vs redirect behavior per route, provided the overall posture stays hybrid and least-surprise.

</decisions>

<specifics>
## Specific Ideas

- The best Elixir/Phoenix fit here is not “Rulestead becomes an auth framework.” It is “Rulestead becomes very clear about the bounded actions it asks the host to authorize.”
- Learn from Bodyguard’s strongest idea without inheriting its whole surface area: one explicit policy decision point is better than hidden rules or sprawling callback trees.
- Learn from LaunchDarkly and Unleash on environment-sensitive governance and clear operator role tiers, but avoid their more expansive custom-role/product-policy surface for v1.0.
- Learn from mountable Phoenix tools such as LiveDashboard/Oban Web/Kaffy on the integration seam: host controls access to the mount, library controls bounded internal actions and affordances.
- Avoid freezing organization-specific job-title roles like `incident_commander` into the formal product contract. Those are good examples and policy inputs, not universal base roles.
- Preserve the project’s calm operator posture:
  - visible read surfaces
  - explicit disabled mutating affordances with reasons
  - server-side deny as final enforcement, not primary UX
  - clear distinction between “can propose” and “can execute”
- Preference note from the user for this repo: shift recommendations left within GSD unless a choice is unusually high-impact. Phase 27 context intentionally locks the major RBAC posture so planning can proceed without reopening ordinary tradeoffs.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active roadmap and requirements
- `.planning/ROADMAP.md` — Phase 27 goal, success criteria, and explicit UI hint
- `.planning/REQUIREMENTS.md` — `SEC-01`, `SEC-02`, and `SEC-03`
- `.planning/PROJECT.md` — linked-version release shape, mounted admin posture, and host-owned integration philosophy
- `.planning/STATE.md` — current milestone state and current phase frontier

### Prior locked decisions
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — existing admin policy seam, denied audit posture, route-backed workflows, and explicit security envelope
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — route-backed governance/schedule surfaces and explicit approval/execution split
- `.planning/phases/12-webhook-ingress-outbound-notifications-and-operator-visibili/12-CONTEXT.md` — webhook visibility, settings/control-plane posture, and recommendation-left preference
- `.planning/phases/21-infrastructure-observability-ui/21-RESEARCH.md` — diagnostics page truth model and read-oriented operator posture
- `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md` — compare preview posture and recommendation-heavy planning preference
- `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md` — protected-target governance flow, approval/execution separation, and environment promotion authority model
- `.planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md` — explicit host seam and fail-closed safety posture
- `.planning/phases/26-api-lockdown-and-documentation-perfection/26-CONTEXT.md` — current API stability boundary and public-surface discipline

### Product, security, and integration direction
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned identity, default-deny admin posture, env-sensitive authorization, and immutable audit requirements
- `prompts/rulestead-host-app-integration-seam.md` — host policy stub, installer seam, and mounted-package contract
- `prompts/rulestead-admin-ux-and-operator-ia.md` — calm operator UX, route-backed surfaces, and settings/control-plane IA
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package design, API stability discipline, and mountable-admin patterns
- `prompts/rulestead-domain-language-field-guide.md` — canonical nouns/verbs for flags, governance, operators, and audit language
- `prompts/rulestead-brand-book.md` — calm, infrastructure-grade operator tone

### Existing code and public seams
- `rulestead/lib/rulestead/admin/policy.ex` — current public policy behavior seam
- `rulestead/lib/rulestead/admin/authorizer.ex` — current fallback role logic, governed-action checks, and deny payload semantics
- `rulestead/lib/rulestead.ex` — admin read/write entrypoints and authorization wiring
- `rulestead/doc/api_stability.md` — current stable API contract and explicit public seam posture
- `rulestead/doc/admin-ui.md` — mounted admin host-facing contract and current stable route family
- `rulestead_admin/README.md` — required host `policy:` seam and session contract
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — current session-entry `:access_admin` gate and environment/policy-state assign model
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` — operator-facing policy state and status components
- `rulestead_admin/lib/rulestead_admin/router.ex` — mounted route family that Phase 27 permissions must cover
- `rulestead/test/rulestead/admin_security_contract_test.exs` — current deny semantics, fallback role behavior, and audit expectations
- `rulestead/test/rulestead/admin_governance_policy_test.exs` — governed-action approval hooks and production self-approval posture
- `rulestead_admin/test/rulestead_admin/live/session_test.exs` — session/env contract and production policy-state behavior
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` — current mounted admin contract and route expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Admin.Policy` already gives the right bounded public seam for host-owned authorization. Phase 27 should deepen and clarify it, not replace it.
- `Rulestead.Admin.Authorizer` already centralizes admin authorization, governed-action checks, and denied-audit payload creation. This is the right place to reconcile formal v1.0 role vocabulary with compatibility behavior.
- `RulesteadAdmin.Live.Session` already enforces a mount-time `:access_admin` gate and exposes policy-state assigns. Phase 27 can extend this into a richer capability/affordance projection without changing the host mount model.
- Existing governance, schedule, compare, diagnostics, and webhook routes already define the surfaces the RBAC matrix must cover. No new product surface is needed to make Phase 27 coherent.

### Established Patterns
- The repo consistently prefers host-owned seams over bundled auth stacks.
- The admin package is mounted and sibling-scoped, not a standalone product; authorization must respect that boundary.
- Governance, promotion, and scheduling already distinguish proposal/review/execution phases; RBAC should reinforce that distinction rather than flatten it.
- Audit-visible denied actions are already part of the security story, but the broader UX direction favors calm, explicit operator flows over “click and get denied” as the main teaching mechanism.

### Integration Points
- Phase 27 should introduce a shared capability vocabulary that both the authorizer and the admin UI can use, so read-only pages, disabled affordances, and backend denies stay consistent.
- Installer/generator outputs should be updated to emit a recommended Viewer/Editor/Admin host policy stub that shows env-sensitive examples without forcing hosts into a rigid identity schema.
- API/documentation work should explicitly distinguish:
  - stable seam: `can?/4` plus bounded actions/resources/environments
  - recommended semantics: Viewer/Editor/Admin
  - compatibility behavior: temporary alias or mapping logic

</code_context>

<deferred>
## Deferred Ideas

- user-defined custom roles or arbitrary permission builders
- policy DSLs, query-scoping frameworks, or OPA-style expansion
- formalizing org-specific roles like `incident_commander` as first-class product roles
- replacing host-owned identity/session ownership with library-owned auth
- standalone `rulestead_admin` control-plane posture

</deferred>

---

*Phase: 27-comprehensive-rbac-security-hardening*
*Context gathered: 2026-05-19*
