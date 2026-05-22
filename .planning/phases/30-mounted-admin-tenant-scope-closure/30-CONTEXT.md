# Phase 30: Mounted Admin Tenant Scope Closure - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning
**Source:** roadmap gap-closure synthesis from Phase 29 artifacts and live code inspection

<domain>
## Phase Boundary

Close the remaining mounted-admin tenant-scoping gap by making real operator session and compare flows preserve explicit `tenant_key` outside the already-covered local simulation path.

**In scope:**
- mounted-admin session resolution for tenant scope using host-provided allowed tenants and defaults
- explicit tenant scope propagation in mounted compare routes, page state, and shared compare calls
- targeted verification that mounted operator flows keep tenant and environment as separate, visible, fail-closed scope axes

**Out of scope:**
- automatic audit provenance merging on mutation and apply paths
- new tenant catalogs, tenant discovery, or standalone `rulestead_admin` tenancy management
- environment-per-tenant topology, tenant-partitioned authored storage, or cross-tenant operator views
- Phase 31 closure work that makes callers stop passing tenant provenance manually

</domain>

<decisions>
## Implementation Decisions

### Product shape and phase discipline
- **D-01:** Phase 30 is a narrow gap-closure phase. Reuse the Phase 29 tenancy seam and mounted-admin patterns rather than introducing new product surface area.
- **D-02:** Preserve the linked-version sibling-package design. Do not prepare `rulestead_admin` for standalone publishing.
- **D-03:** Keep Phase 31 work out of scope. This phase preserves explicit tenant scope in mounted-admin flows; it does not automate tenant provenance on writes.

### Mounted-admin tenant session resolution
- **D-04:** Mounted-admin tenant resolution must follow the same precedence posture already used for environments: URL tenant first if allowed, remembered tenant second if allowed, otherwise host default or first allowed tenant, otherwise fail closed.
- **D-05:** The host session remains the source of truth for allowed tenant choices and optional default tenant. Rulestead must not derive tenants from authored storage.
- **D-06:** Invalid tenant params must not silently broaden scope. If a requested tenant is not allowed, mounted flows must fall back only within the bounded allowed set or halt back to the mount root.
- **D-07:** Tenant scope remains separate from environment scope in assigns, helper APIs, route params, and visible shell chrome.

### Compare flow carry-through
- **D-08:** Environment compare pages must pass explicit `tenant_key` through the existing shared compare seam so compare tokens, findings, and reviewed scope reflect the mounted-admin tenant choice.
- **D-09:** Route helpers for mounted-admin compare flows must preserve both `env` and `tenant` params together so scope does not drift across navigation.
- **D-10:** The compare page should surface the active tenant scope alongside environment scope, but must not introduce an implicit all-tenant compare mode.

### Verification posture
- **D-11:** Verification should focus on mounted-admin session helpers, compare route generation, and compare invocation with explicit `tenant_key`.
- **D-12:** Reuse targeted tests in both packages instead of broad E2E expansion. The goal is to prove the mounted path, not to widen the release shape.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and milestone state
- `.planning/ROADMAP.md` — Phase 30 goal, success criteria, and dependency on Phase 29
- `.planning/REQUIREMENTS.md` — active `TEN-01` and `TEN-03` traceability for v1.1.0
- `.planning/STATE.md` — current milestone status and latest tenancy completion notes

### Prior phase decisions
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` — locked tenancy decisions, especially host-bounded mounted-admin scope and fail-closed posture
- `.planning/phases/29-tenancy-helpers-validation/29-RESEARCH.md` — reusable mounted-admin and compare pattern recommendations
- `.planning/phases/29-tenancy-helpers-validation/29-VERIFICATION.md` — what Phase 29 already proved and what remains for mounted real-operator paths

### Product and security anchors
- `prompts/rulestead-host-app-integration-seam.md` — mounted admin remains host-owned at session and routing boundaries
- `prompts/rulestead-admin-ux-and-operator-ia.md` — operator-facing scope visibility and mounted flow UX posture
- `prompts/rulestead-security-privacy-and-threat-model.md` — least-privilege, explicit scope, and fail-closed requirements
- `prompts/rulestead-domain-language-field-guide.md` — canonical tenant/environment/operator vocabulary
- `prompts/rulestead-testing-and-e2e-strategy.md` — targeted verification posture

### Existing code seams
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — current mounted environment resolution and shared route helpers
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — mounted scope chrome that currently shows environment only
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` — compare page that currently omits `tenant_key` propagation
- `rulestead_admin/test/rulestead_admin/live/session_test.exs` — existing session helper coverage to extend for tenant scope
- `rulestead/test/rulestead/promotion/compare_test.exs` — compare command/public seam contract
- `rulestead/test/rulestead/store/compare_contract_test.exs` — shared compare adapter contract, including `tenant_key` in compare-token semantics
- `rulestead/lib/rulestead/store/command.ex` — canonical compare command shape with `tenant_key`
- `rulestead/lib/rulestead/promotion/compare.ex` — compare result and token behavior for explicit tenant scope

</canonical_refs>

<code_context>
## Existing Code Insights

### What is already true
- Mounted admin already has a reusable environment-resolution and route-helper seam in `RulesteadAdmin.Live.Session`.
- The compare command already accepts `tenant_key`, and compare-token generation already includes it.
- The local simulation path already exercises explicit tenant input, so the remaining gap is mounted operator flow carry-through, not core compare semantics.

### Current gap
- `RulesteadAdmin.Live.Session.resolve/3` only resolves environment state today.
- `Session.current_path/3` and `Session.env_links/3` only preserve `env`.
- `RulesteadAdmin.Live.EnvironmentCompareLive.Index` builds pages and compare calls without reading or passing tenant scope.
- `Shell.page/1` only renders environment scope, so operator-visible tenant scope is missing outside local simulation.

### Desired integration points
- Extend mounted session assigns and helper APIs so tenant scope is available anywhere the shell and compare pages already consume environment scope.
- Thread `tenant_key` through compare route params and `Rulestead.compare_environments/3` options.
- Add the minimum shell rendering needed to keep tenant scope visible and separate from environment scope.

</code_context>

<deferred>
## Deferred Ideas

- Automatic tenant provenance injection in audit mutation/apply paths
- Cross-tenant compare or dashboard views
- Tenant lifecycle or catalog management inside Rulestead
- Broad admin UI redesign beyond the mounted scope chrome needed for tenant visibility

</deferred>

---

*Phase: 30-mounted-admin-tenant-scope-closure*
*Context gathered: 2026-05-22*
