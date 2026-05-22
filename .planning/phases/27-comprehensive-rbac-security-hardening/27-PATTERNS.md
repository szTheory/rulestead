# Phase 27: Comprehensive RBAC & Security Hardening - Pattern Map

**Mapped:** 2026-05-20
**Scope:** Reusable implementation and plan-writing patterns for Phase 27 RBAC, enforcement, and mounted-admin capability UX.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead/admin/policy.ex` | public seam / behaviour | request-response | itself plus existing optional governance callbacks | exact |
| `rulestead/lib/rulestead/admin/authorizer.ex` | normalization + enforcement service | request-response | itself; current governed action + deny payload logic | exact |
| `rulestead/lib/rulestead.ex` | public facade | request-response | existing `admin_write`-backed verbs and read helpers | exact |
| `rulestead/lib/rulestead/store/command.ex` | normalized command inputs | request-response | governed command normalization and approval requirement snapshots | exact |
| `rulestead/lib/rulestead/store/ecto.ex` / `fake.ex` | real/fake enforcement parity | transaction + request-response | existing direct/governed write callbacks | exact |
| `rulestead_admin/lib/rulestead_admin/live/session.ex` | mounted route/session gate | request-response | current `:access_admin` resolve + policy state helper | exact |
| `rulestead_admin/lib/rulestead_admin/router.ex` | route family registry | routing | current mounted admin route list | exact |
| `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | operator-facing status components | render | `banner/1`, `policy_state/1`, `status_list/1`, `summary_grid/1` | exact |
| `rulestead_admin/lib/rulestead_admin/live/**/*.ex` | route-backed capability consumers | request-response + render | compare/governance/schedule LiveViews | strong |
| `rulestead/test/rulestead/admin_security_contract_test.exs` | core contract tests | request-response | denied audit + fallback role tests | exact |
| `rulestead/test/rulestead/admin_governance_policy_test.exs` | governed posture tests | request-response | optional policy hook and approval requirement coverage | exact |
| `rulestead_admin/test/rulestead_admin/live/session_test.exs` | mounted helper tests | request-response | env resolution/path-building/policy-state tests | exact |
| `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` | mount integration tests | route/integration | existing admin mount contract | strong |

## Pattern Assignments

### 1. Stable public seam with additive bounded callbacks

**Copy from:** `rulestead/lib/rulestead/admin/policy.ex`

**Pattern**
- Keep a small behaviour with `can?/4` as the main stable contract.
- Add narrowly-scoped optional callbacks only when the governed workflow truly needs them.
- Keep action/resource/environment explicit instead of inferring from actor roles inside the UI.

**Apply to Phase 27**
- Expand the closed vocabulary around `can?/4` without changing its arity.
- If a capability snapshot helper is added, keep it internal or additive so the host contract remains stable.

### 2. Centralized actor/resource normalization and denied audit payloads

**Copy from:** `rulestead/lib/rulestead/admin/authorizer.ex`

**Pattern**
- Normalize actor, environment, and resource once before evaluating policy.
- Keep deny creation centralized so metadata and denied audit payloads stay consistent.
- Resolve governance posture through one place (`approval_requirement/4` and friends), not per-write-path custom logic.

**Apply to Phase 27**
- Introduce canonical role/capability normalization here.
- Build capability projection and human-readable reason codes from the same normalized inputs.
- Keep compatibility aliases here instead of leaking them to docs/UI.

### 3. Public facade -> admin write -> store parity

**Copy from:** `rulestead/lib/rulestead.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`

**Pattern**
- Public verbs delegate through bounded write helpers and append denied audit rows on authorization failure.
- Real and fake adapters keep contract parity for direct and governed operations.

**Apply to Phase 27**
- Any new action/resource vocabulary used for authorization must be reflected consistently across facade, Ecto, and Fake paths.
- Route-to-action coverage should be tested via existing contract suites rather than only via LiveView smoke tests.

### 4. Route-backed mounted scope helpers

**Copy from:** `rulestead_admin/lib/rulestead_admin/live/session.ex`, `rulestead_admin/test/rulestead_admin/live/session_test.exs`

**Pattern**
- Resolve URL-backed scope first, remembered scope second, default last.
- Keep path helpers deterministic so capability-linked reasons survive refresh and deep links.
- Build small helper assigns (`policy_state`, env links, current path) that all screens can reuse.

**Apply to Phase 27**
- Extend the session layer with capability summaries and route-level access posture rather than per-screen ad hoc checks.
- Keep `:access_admin` as the mount-time preflight, then layer richer route/action capability state on top.

### 5. Operator-facing status UI from shared primitives

**Copy from:** `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`

**Pattern**
- Use `policy_state/1`, `banner/1`, `status_list/1`, and `summary_grid/1` to teach operational state.
- Put the explanatory text next to the blocked or elevated action, not behind hidden interactions.

**Apply to Phase 27**
- Reuse these components for Viewer/Editor/Admin capability summaries, protected-environment warnings, and disabled-action reasons.
- Avoid inventing a parallel component vocabulary when the UI-SPEC explicitly extends the existing `rs-*` system.

### 6. Governance and protected-environment truth stays explicit

**Copy from:** `rulestead/test/rulestead/admin_governance_policy_test.exs`, governed-action execution code in `rulestead/lib/rulestead/store/ecto.ex`

**Pattern**
- Production/protected actions reuse explicit approval requirement state.
- Self-approval, change-request-required, and direct execution are all asserted through typed snapshots rather than implied by copy.

**Apply to Phase 27**
- Treat `Admin-only` and `proposal-only` as first-class capability states.
- Keep protected-environment authority grounded in approval requirement and policy callbacks, not in CSS state or client-only checks.

### 7. Recent plan-writing analogs

**Copy from:** `.planning/phases/25-tenancy-helpers-validation/25-01-PLAN.md`, `.planning/phases/25-tenancy-helpers-validation/25-02-PLAN.md`, `.planning/phases/26-api-lockdown-and-documentation-perfection/26-01-PLAN.md`, `.planning/phases/26-api-lockdown-and-documentation-perfection/26-03-PLAN.md`

**Pattern**
- Use 2-3 plans with explicit wave ordering.
- Keep each plan bounded by one dominant responsibility: seam/domain, enforcement parity, or docs/UI surface.
- Include concrete `files_modified`, requirement mapping, must-have truths, task verification commands, and a small threat model.

**Apply to Phase 27**
- Prefer three plans:
  - `27-01` vocabulary + authorizer/policy contract
  - `27-02` enforcement parity across core/governed/protected paths
  - `27-03` mounted-admin capability UX + docs/stubs/tests

## Shared Patterns

### Compatibility mapping belongs in backend normalization
- Source: `rulestead/lib/rulestead/admin/authorizer.ex`
- Why: the same actor can hit facade writes, governed actions, and mounted-admin screens.

### Denied audit is part of the security contract
- Source: `rulestead/test/rulestead/admin_security_contract_test.exs`
- Why: unauthorized operations should stay observable even when blocked.

### Read routes and mutating routes are different classes
- Source: `rulestead_admin/lib/rulestead_admin/router.ex`; `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`
- Why: Phase 27 needs route-family classification to preserve read context while gating execution.

### Accessibility rules are structural, not visual polish
- Source: `.planning/phases/27-comprehensive-rbac-security-hardening/27-UI-SPEC.md`; `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
- Why: blocked actions need readable reason text and focus-safe disabled states.

## Do Not Duplicate

- Do not duplicate role semantics in docs, LiveViews, and authorizer separately; keep canonical mapping in backend code.
- Do not introduce a second policy engine or a builder DSL.
- Do not teach legacy compatibility roles in operator-facing copy.
- Do not hide blocked actions that have instructional value when the UI-SPEC explicitly wants disabled + explained affordances.
- Do not bypass Ecto/Fake parity by implementing enforcement only in LiveView event handlers.

## Minimal Planner Notes

- `27-01` should anchor on `policy.ex`, `authorizer.ex`, release-contract tests, and any shared capability module/helper it introduces.
- `27-02` should anchor on `rulestead/lib/rulestead.ex`, store enforcement touchpoints, route/action matrix coverage, and denied/governed regression tests.
- `27-03` should anchor on `session.ex`, `operator_components.ex`, the highest-impact LiveViews, docs, README/policy stub examples, and accessibility/integration coverage.
