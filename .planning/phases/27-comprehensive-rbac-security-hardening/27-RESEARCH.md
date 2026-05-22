# Phase 27: Comprehensive RBAC & Security Hardening - Research

**Researched:** 2026-05-20 [VERIFIED: codebase + planning artifacts]
**Domain:** Closed-vocabulary RBAC for the core admin/API seam and the mounted LiveView admin UI. [VERIFIED: `.planning/ROADMAP.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 to D-05:** Keep the stable host-owned seam centered on `Rulestead.Admin.Policy.can?/4`; do not expand into a general authorization framework or DSL. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `rulestead/lib/rulestead/admin/policy.ex`]
- **D-06 to D-10:** Canonical roles are exactly `Viewer`, `Editor`, and `Admin`; current extra names are temporary compatibility mappings only. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `rulestead/lib/rulestead/admin/authorizer.ex`]
- **D-11 to D-14:** Hosts keep owning identity/session/auth mapping; Rulestead provides a closed authorization vocabulary and recommended role mapping, not a mandatory role engine. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `rulestead_admin/README.md`]
- **D-15 to D-19:** Viewer is read-only, Editor is flag-scoped author/proposer, Admin owns protected-environment and control-plane authority. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`]
- **D-20 to D-24:** UI posture is hybrid: deny mount only for actors with no read scope at all, keep useful read routes visible, disable blocked actions with environment-aware reasons, and derive capability display from the same backend vocabulary as enforcement. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`]
- **D-25 to D-28:** Keep env-sensitive fail-closed enforcement and recommendation-first planning; reopen only scope/security/public-contract questions. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`]

### Deferred Ideas
- Custom role builders, arbitrary permission graphs, policy DSLs, ABAC expansion, or standalone `rulestead_admin` posture are out of scope. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `AGENTS.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEC-01 | The system defines explicit, static roles (`Admin`, `Editor`, `Viewer`) for accessing and mutating feature flags. | Replace current fallback role truth with a canonical closed role/capability vocabulary and keep legacy names as temporary compatibility aliases only. [VERIFIED: `.planning/REQUIREMENTS.md`; `rulestead/lib/rulestead/admin/authorizer.ex`] |
| SEC-02 | RBAC is implemented using pure Elixir context-based boundaries without third-party dependencies. | Extend the existing `Rulestead.Admin.Policy` + `Rulestead.Admin.Authorizer` seam and normalize capabilities/resources in-core instead of adding a new auth library. [VERIFIED: `.planning/REQUIREMENTS.md`; `rulestead/lib/rulestead/admin/policy.ex`; `rulestead/lib/rulestead/admin/authorizer.ex`] |
| SEC-03 | The Admin UI and core API enforce RBAC policies and prevent unauthorized production changes. | Apply the same closed vocabulary to facade/store authorization and mounted-admin capability projection, with production/protected flows still governed and fail-closed. [VERIFIED: `.planning/REQUIREMENTS.md`; `rulestead/lib/rulestead.ex`; `rulestead_admin/lib/rulestead_admin/live/session.ex`; `rulestead_admin/lib/rulestead_admin/router.ex`] |
</phase_requirements>

## Summary

The existing codebase already has the right seam shape for Phase 27: a host-provided `Rulestead.Admin.Policy` behaviour, a central `Rulestead.Admin.Authorizer`, bounded governance hooks, and a mounted LiveView session gate. What is missing is a canonical RBAC vocabulary and a shared capability projection that can drive both backend enforcement and UI affordance state. [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`; `rulestead/lib/rulestead/admin/authorizer.ex`; `rulestead_admin/lib/rulestead_admin/live/session.ex`]

The largest correctness risk is that current fallback authorization is still implicitly defined by legacy roles (`auditor`, `operator`, `engineer`, `incident_commander`, `prod_operator`) and a small hard-coded action list. That means the public product story has already diverged from the actual fallback truth. Phase 27 should fix that by introducing a closed action/resource/environment capability layer, teaching `Viewer` / `Editor` / `Admin` as the only public vocabulary, and treating legacy names only as compatibility inputs. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `rulestead/lib/rulestead/admin/authorizer.ex`]

The second risk is UX drift. Today the mounted session only checks `:access_admin` and exposes coarse `policy_state`; it does not project route- or action-level capability truth. Since Phase 27 explicitly prefers a hybrid UI posture, the plan should add a shared capability snapshot in the session/authorizer layer and then consume that snapshot in route-level LiveViews/components so disabled controls and reason text stay derived from backend truth. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`; `rulestead_admin/lib/rulestead_admin/live/session.ex`; `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`]

**Primary recommendation:** split Phase 27 into three execution slices:
1. establish the closed RBAC vocabulary, canonical role mapping, and authorizer/policy capability contract;
2. apply that contract across core facade/store/admin routes and production/governance-sensitive actions with fail-closed regression coverage;
3. extend mounted-admin session/components/docs so capability summaries, disabled reasons, and host policy examples align with backend truth. [VERIFIED: `.planning/ROADMAP.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Closed action/resource/environment vocabulary | API / Backend | Documentation | The vocabulary must stay stable across policy callbacks, core writes, and tests before the UI can safely consume it. [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`; `rulestead/lib/rulestead/admin/authorizer.ex`] |
| Canonical role mapping and compatibility fallback | API / Backend | Documentation | Compatibility aliases belong in the authorizer seam, not in the LiveView layer. [VERIFIED: `rulestead/lib/rulestead/admin/authorizer.ex`] |
| Write-path and governed/protected enforcement | API / Backend | Database / Storage | Direct and governed writes already flow through the core facade/store pipeline. [VERIFIED: `rulestead/lib/rulestead.ex`; `rulestead/lib/rulestead/store/ecto.ex`] |
| Mounted capability projection and route gating | Frontend Server (SSR) | API / Backend | The admin package is LiveView-mounted and currently resolves environment/policy state server-side. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`; `rulestead_admin/lib/rulestead_admin/router.ex`] |
| Host adoption guidance and public contract examples | Documentation | API / Backend | The sibling-package design depends on clear docs and installer-facing examples rather than hidden default behavior. [VERIFIED: `rulestead/doc/admin-ui.md`; `rulestead/doc/api_stability.md`; `rulestead_admin/README.md`] |

## Standard Stack

### Core
| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Existing `Rulestead.Admin.Policy` behaviour | local code [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`] | host-owned authorization seam | Already matches the bounded mountable-library posture and avoids new dependencies. |
| Existing `Rulestead.Admin.Authorizer` | local code [VERIFIED: `rulestead/lib/rulestead/admin/authorizer.ex`] | canonical normalization, fallback roles, governed checks, denied audit payloads | The repo already centralizes authorization here; Phase 27 should deepen it, not replace it. |
| Existing core facade/store write pipeline | local code [VERIFIED: `rulestead/lib/rulestead.ex`; `rulestead/lib/rulestead/store/ecto.ex`] | admin/API enforcement | Unauthorized writes already append denied audit rows through this path. |
| Phoenix LiveView mounted admin | local code [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`; `rulestead_admin/lib/rulestead_admin/router.ex`] | route/session/capability UX | The current admin product is mounted and sibling-scoped, not standalone. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `Policy.can?/4` + authorizer vocabulary | Introduce Bodyguard, Permit, or a DSL layer | Violates the no-dependency and bounded-seam requirements while freezing too much surface for v1.0. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`] |
| Compatibility aliases inside authorizer only | Teach legacy role names throughout UI/docs | Makes accidental API debt permanent and conflicts with the locked role vocabulary. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`; `rulestead/lib/rulestead/admin/authorizer.ex`] |
| Shared capability projection from backend truth | Per-screen ad hoc checks and copy | Creates UI/backend drift and weakens fail-closed guarantees. [VERIFIED: `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`; `rulestead_admin/lib/rulestead_admin/live/session.ex`] |

## Architecture Patterns

### Pattern 1: Closed vocabulary on top of the existing policy seam
**What:** Keep `can?/4` stable, but narrow the action/resource/environment values that flow through it so docs, tests, fallback mapping, and capability projection all speak the same bounded language. [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`]
**When to use:** Plan `27-01`, before touching per-screen UI logic.

### Pattern 2: Fallback compatibility mapping is temporary normalization, not product truth
**What:** Normalize actor inputs into canonical `Viewer` / `Editor` / `Admin` capabilities, but continue accepting existing role atoms as compatibility aliases during transition. [VERIFIED: `rulestead/lib/rulestead/admin/authorizer.ex`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`]
**When to use:** Plan `27-01` and any release-contract/docs coverage that explains fallback behavior.

### Pattern 3: Server truth drives UI capability summaries
**What:** Extend the mounted session/authorizer flow with a capability snapshot that can answer route-level read access, direct execute access, proposal-only posture, and human-readable deny reasons. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`; `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`]
**When to use:** Plan `27-03`, after backend vocabulary is stable.

### Pattern 4: Governed and protected actions stay explicit
**What:** Reuse existing governed-action and approval-requirement seams rather than inventing a separate “sensitive action” system; production/protected differences remain environment-sensitive and fail closed. [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`; `rulestead/lib/rulestead/admin/authorizer.ex`; `rulestead/test/rulestead/admin_governance_policy_test.exs`] 
**When to use:** Plan `27-02`, for publish/rollout/kill/promote/settings/recovery coverage.

## Risks and Planning Implications

- **Public contract drift:** if legacy fallback roles remain the only actual enforcement truth, SEC-01 is not really satisfied even if docs change. [VERIFIED: `rulestead/lib/rulestead/admin/authorizer.ex`]
- **UI/backend drift:** if disabled controls are inferred per LiveView instead of using a shared capability model, reasons and enforcement will diverge. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`]
- **Over-scoping into custom auth:** adding builders, custom permissions, or DSLs would violate the explicit v1.0 boundary. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md`]
- **Missing route coverage:** the mounted router spans flag CRUD, rules, simulate, rollouts, kill, cleanup, audit, change requests, schedule, webhooks, diagnostics, and compare; the plan must cover route/action classes, not just one or two writes. [VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`]
- **Docs mismatch:** `rulestead_admin/README.md`, `rulestead/doc/admin-ui.md`, and public contract tests need to teach the same canonical role model and host policy examples as the code. [VERIFIED: `rulestead_admin/README.md`; `rulestead/doc/admin-ui.md`; `rulestead/test/rulestead/admin_security_contract_test.exs`]

## Recommended Slice Boundary

### Slice 1
- closed RBAC action/resource/environment vocabulary
- canonical Viewer/Editor/Admin role mapping
- legacy alias compatibility normalization
- authorizer capability snapshot helpers
- release-contract and policy seam regression tests

### Slice 2
- core facade/store/admin write enforcement updates
- governed/protected action matrix coverage
- deny/audit payload coverage for production/protected paths
- route-family/backend action mapping tests

### Slice 3
- mounted session capability projection
- UI policy summary / status-list / disabled-reason rendering
- read-only vs redirect route handling
- docs and host policy stub refresh for canonical roles
- LiveView integration/accessibility coverage

---
*Phase 27 research completed: 2026-05-20*
