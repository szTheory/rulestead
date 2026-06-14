# Phase 117: page-flow-ia-pass - Research

**Researched:** 2026-06-14 [VERIFIED: gsd init.phase-op]
**Domain:** Phoenix LiveView admin information architecture, route-flow evidence, keyboard/focus/mobile verification [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase grep + official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Navigation And Route Clusters

- **D-01:** Preserve the current top-level navigation model from `RulesteadAdmin.Navigation`: Overview, Build & release, Explain & diagnose, and Review & approve.
- **D-02:** Treat audiences, rollouts, audit, destructive actions, onboarding/happy paths, denied states, unavailable states, and rare states as operator lenses inside the current route clusters, not as new top-level navigation groups.
- **D-03:** Do not add a flat entity rail, role/mode-based navigation, top-level Rulesets, top-level Settings, or a top-level destructive/emergency destination in Phase 117. Home launcher, rail, command palette, breadcrumbs, and contextual subnav should stay consistent with the existing grouped model.

### Route-Owned IA Surfaces

- **D-04:** Drive Phase 117 through route-owned IA review, not component extraction or broad page redesign.
- **D-05:** Prioritize the page-owned surfaces handed off by Phase 116: flag inventory search/cards, rules workspace shell/sidebar/action hierarchy, kill-switch runbook sequencing, home attention/task-board composition, and audience inventory/dependency placement.
- **D-06:** Keep these surfaces route-owned unless the IA pass discovers a genuinely stable subpattern worth extracting. Inventory URL filters/search, LiveView streams, rules draft/publish state, kill-switch emergency sequencing, and home/audience page orientation should remain visible in their route modules.

### Workflow Evidence Strategy

- **D-07:** Validate workflows with deterministic UI matrix fixtures plus selected real mounted-admin route evidence. Use the Phase 114 matrix for fixed component/state stress and real routes for route order, keyboard paths, mobile scan order, and workflow sequencing.
- **D-08:** Keep screenshots as generated artifacts for human review, not checked-in baselines or pixel-diff gates.
- **D-09:** Do not add broad demo seed semantics, product data assumptions, public routes, schemas, migrations, release workflow changes, Storybook, PhoenixStorybook, or pixel-baseline infrastructure for Phase 117 evidence.

### Mobile, Keyboard, And Focus

- **D-10:** Add route-level evidence for keyboard flow, focus order, command palette behavior, destructive-flow sequencing, and narrow viewport behavior across representative primary route clusters.
- **D-11:** Preserve the Phase 115 foundation contract for breakpoints, focus ring, reduced motion, radius/elevation, and dense technical containment unless multiple route failures prove a concrete shared foundation regression.
- **D-12:** Prefer semantic links, buttons, and forms in route fixes. Use DOM-aware JavaScript only for focus-heavy widgets that already require it, such as the command palette.

### Explain, Simulate, And Audit

- **D-13:** Include audit, explain, and simulate in route-cluster evidence so FLOW-01 through FLOW-04 cover explain/diagnose and audit jobs.
- **D-14:** Edit audit, explain, and simulate only when route evidence shows a hierarchy failure: missing first-glance answer, buried permalink/sample/context, unclear redaction, inaccessible raw detail, poor mobile/keyboard flow, or audit rows that strand Support/SRE instead of linking back to the next useful surface.
- **D-15:** Do not treat audit/explain/simulate forms as remaining Phase 116 component debt. Their URL state, redaction boundaries, fixture export, raw detail, and support-safe trace copy remain route-owned.

### Ecosystem Lessons Applied

- **D-16:** Borrow external-product lessons at the concept level only. Successful flag/admin tools make flags, audiences/segments, kill switches, approvals, and audit history reachable; Phase 117 should improve reachability and route hierarchy without copying standalone-console rail sprawl.
- **D-17:** Keep emergency and destructive workflows contextual. Kill-switch and archive/delete paths should remain guarded flows with clear evidence, reason, typed confirmation where needed, back links, disabled/unavailable explanations, and audit handoff.
- **D-18:** Keep evidence pragmatic and CI-readable. Playwright should prove browser-only concerns such as focus, keyboard, overflow, roles, screenshots, and route sequencing; ExUnit/source assertions remain preferable for component/source boundary checks.

### the agent's Discretion

The planner may choose the exact plan split, route evidence set, and names for any Phase 117 review artifacts. Prefer a compact route-cluster IA review artifact that maps operator job, route, page-owned surface, state coverage, issue found, action taken, and proof command. Keep fixes vertical and small: evidence first, then route-level IA adjustment, then focused verification.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Flat entity navigation, role/mode-based navigation, top-level Rollouts/Audiences/Audit/Destructive groups, top-level Rulesets, and top-level Settings remain deferred until a future explicit IA/product milestone.
- Component extraction for inventory/cards/rules/kill/home/audience remains deferred unless Phase 117 route evidence proves a stable reusable subpattern.
- Broad product-wide page redesign, mobile-first admin redesign, Phase 115 foundation rewrite, and Phase 116 primitive/composite re-polish are out of scope.
- Broad demo seed expansion, product seed semantics, checked-in pixel baselines, Storybook, PhoenixStorybook, and external AI visual judging remain deferred.
- Full audit/explain/simulate redesign remains deferred unless Phase 117 evidence proves those routes block explain/diagnose or audit jobs.
- Public runtime APIs, schemas/migrations, release workflow changes, palette/logo redesign, FleetDesk rebranding, v2 product wedges, and `rulestead_admin` standalone publish preparation remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLOW-01 | Admin route clusters are mapped to operator jobs-to-be-done for build/release, explain/diagnose, review/approve, audiences, rollouts, audit, and destructive actions. [VERIFIED: .planning/REQUIREMENTS.md] | Use `RulesteadAdmin.Navigation` as the source of truth and produce a route-cluster IA review artifact. [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex] |
| FLOW-02 | Page sections and component groups follow least-surprise information hierarchy for onboarding, intermediate, and advanced operator paths. [VERIFIED: .planning/REQUIREMENTS.md] | Review home, inventory, rules, kill, audience, audit, explain, and simulate for first-glance answer, next action, and progressive detail. [VERIFIED: 116-PHASE-117-HANDOFF.md] |
| FLOW-03 | Keyboard, focus order, mobile layout, and narrow viewport behavior remain usable across primary admin route clusters. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse Playwright route evidence loops for desktop/mobile, themes, command palette, focus order, and no horizontal overflow. [VERIFIED: examples/demo/frontend/tests/brand-ui-evidence.spec.ts] |
| FLOW-04 | Demo/fixture data includes enough happy-path, error, boundary, and rare-state examples to exercise the design system without changing product semantics. [VERIFIED: .planning/REQUIREMENTS.md] | Extend deterministic matrix fixtures only for missing state coverage; do not add product seed semantics. [VERIFIED: examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex] |
</phase_requirements>

## Summary

Phase 117 should be planned as a route-flow IA and evidence phase, not a component-polish phase. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md] The existing admin already has a central grouped navigation source, route-owned URL/query state, deterministic UI matrix fixtures, and Playwright evidence patterns that can be extended without adding Storybook, pixel baselines, schemas, migrations, or release workflow changes. [VERIFIED: codebase grep]

The highest-leverage plan shape is: first create a compact `117-FLOW-IA-REVIEW.md`, then add selected route-level browser evidence, then make only evidence-triggered route IA fixes. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md] The route set should cover home/overview, flag inventory, rules workspace, kill switch, audience inventory, audit, explain, and simulate because those surfaces collectively exercise onboarding, build/release, emergency/destructive, audience, audit, and explain/diagnose jobs. [VERIFIED: 116-PHASE-117-HANDOFF.md]

**Primary recommendation:** Plan a two-wave phase: Wave 1 creates route-cluster IA mapping plus deterministic route evidence; Wave 2 applies small route-owned IA fixes and updates proof commands. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Rulestead is a sibling-package monorepo with `rulestead/` and `rulestead_admin/`. [VERIFIED: AGENTS.md]
- `.planning/` and `prompts/` are ground truth inputs for roadmap, state, requirements, and engineering DNA. [VERIFIED: AGENTS.md]
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: AGENTS.md]
- Keep Phase 8-only docs absent until the roadmap says they ship. [VERIFIED: AGENTS.md]
- Do not publish or prepare to publish the `rulestead_admin` stub. [VERIFIED: AGENTS.md]
- Keep edits aligned with the linked-version, two-package release design. [VERIFIED: AGENTS.md]
- Before `/gsd-execute-phase`, select Auto in Cursor so implementation subagents inherit Auto. [VERIFIED: AGENTS.md]
- Make the smallest coherent change that satisfies the active plan. [VERIFIED: AGENTS.md]
- Avoid speculative future-phase features. [VERIFIED: AGENTS.md]
- Preserve reproducibility and CI readability. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Grouped admin route-cluster mapping | Frontend Server (Phoenix LiveView) | Browser / Client | `RulesteadAdmin.Navigation` derives rail, launcher, and command-palette grouping server-side; browser evidence verifies rendered order and keyboard behavior. [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex] |
| Route-owned IA review and fixes | Frontend Server (Phoenix LiveView) | API / Backend | Route modules own URL/query params, streams, breadcrumbs, subnav, forms, and page hierarchy; domain APIs should remain underneath. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex] |
| Keyboard, focus, command palette, and mobile proof | Browser / Client | Frontend Server (Phoenix LiveView) | Playwright is the correct tier for browser-only concerns such as focus order, overflow, roles, screenshots, and viewport behavior. [VERIFIED: examples/demo/frontend/tests/ui-matrix.spec.ts] |
| Deterministic matrix fixture coverage | Frontend Server (Phoenix demo host) | Browser / Client | The UI matrix renders real admin components with fixed fixture assigns, and Playwright asserts rendered stress states. [VERIFIED: examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex] |
| Audit/explain/simulate redaction and trace semantics | Frontend Server (Phoenix LiveView) | API / Backend | Routes render support-safe forms and trace details while backend APIs own evaluation, simulation, explanation, and redaction semantics. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | `rulestead_admin` locked `1.1.31`; demo backend locked `1.1.30`; Hex latest observed `1.2.1` on 2026-06-14. [VERIFIED: mix deps + mix hex.info phoenix_live_view] | Mounted admin routes, `handle_params/3`, streams, async states, HEEx rendering. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] | Existing app stack; official docs define LiveView lifecycle, async assigns, `push_patch`, streams, and untrusted event-payload validation. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| Phoenix function components | Phoenix LiveView `1.1.x` project usage. [VERIFIED: mix deps + codebase grep] | Reusable markup primitives and composites. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/operator_components.ex] | Official LiveComponent docs say function components are preferred unless encapsulated event handling plus local state is needed. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| Playwright Test | Installed `@playwright/test@1.60.0`; npm latest observed `1.60.0`. [VERIFIED: npm ls + npm view] | Browser route evidence, screenshots as artifacts, no-overflow checks, role/focus checks. [VERIFIED: examples/demo/frontend/tests/ui-matrix.spec.ts] | Existing browser test stack; official visual-comparison docs show `toHaveScreenshot()` creates snapshot expectations, which Phase 117 should avoid per locked evidence posture. [CITED: https://playwright.dev/docs/test-snapshots] |
| WAI-ARIA APG patterns | Current W3C APG pages read 2026-06-14. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/] | Combobox/listbox and modal-dialog semantics for command palette and search suggestions. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] | APG documents expected combobox popup roles/expanded state and modal-dialog inert-background behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/] |

### Supporting

| Library / Asset | Version | Purpose | When to Use |
|-----------------|---------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | Elixir/Mix `1.19.5`; Phoenix LiveViewTest from project deps. [VERIFIED: elixir --version + mix --version + test files] | Source assertions, route rendering, fixture health, and forbidden-tooling checks. [VERIFIED: examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs] | Use for route/source contracts and deterministic fixture markers before browser tests. [VERIFIED: codebase grep] |
| `UiMatrixFixtures` | Project-local module. [VERIFIED: examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex] | Fixed stress states for long labels, dense records, audit entries, rare states, mutation confirms, and route links. [VERIFIED: examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex] | Extend only when FLOW-04 lacks happy/error/boundary/rare coverage. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md] |
| Existing Playwright helpers | Project-local `backendUrl` helper. [VERIFIED: examples/demo/frontend/tests/support/admin.ts] | Demo sign-in and configured backend URL access. [VERIFIED: examples/demo/frontend/tests/brand-ui-evidence.spec.ts] | Use in a new route-flow evidence spec so commands work with `DEMO_BACKEND_URL`. [VERIFIED: examples/demo/frontend/tests/support/admin.ts] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Route-level Playwright evidence | Broad checked-in pixel baselines | Rejected: Phase 117 locks screenshots as artifacts and forbids pixel-baseline infrastructure. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md] |
| Existing grouped navigation | Flat entity rail or new top-level Settings/Rulesets/Audit groups | Rejected: locked decisions preserve `RulesteadAdmin.Navigation` grouped JTBD model. [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex] |
| Route-owned IA fixes | New component framework or Storybook/PhoenixStorybook | Rejected: Phase 117 forbids Storybook/PhoenixStorybook and component framework adoption. [VERIFIED: .planning/REQUIREMENTS.md] |

**Installation:** No new external packages should be installed for Phase 117. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md]

**Version verification commands run:**
```bash
cd rulestead_admin && mix deps | rg 'phoenix_live_view|phoenix |ecto|jason|telemetry'
cd examples/demo/backend && mix deps | rg 'phoenix_live_view|phoenix |rulestead'
cd examples/demo/frontend && npm ls @playwright/test --depth=0
cd examples/demo/frontend && npm view @playwright/test version
cd rulestead_admin && mix hex.info phoenix_live_view
```

## Package Legitimacy Audit

No new package installs are recommended for Phase 117. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md] Existing packages were inspected for version context only, so the Package Legitimacy Gate is not required for a new install plan. [VERIFIED: package_legitimacy_protocol + command history] `slopcheck` is available in this environment if a future plan adds a package. [VERIFIED: slopcheck --help]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| None newly recommended | — | — | — | — | — | No install work for planner. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no packages recommended]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no packages recommended]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 117 input
  -> CONTEXT locked decisions + FLOW requirements
  -> Route-cluster IA review artifact
       -> Map JTBD lens to current nav group and route-owned surface
       -> Record state coverage: happy / error / boundary / rare
       -> Record finding: none / evidence gap / IA issue
  -> Evidence branch
       -> ExUnit/LiveViewTest for source, fixture, route contract
       -> Playwright for browser flow, focus, keyboard, viewport, screenshots
  -> Fix branch
       -> If evidence gap: extend deterministic matrix fixture or route seed fixture
       -> If route IA issue: make small route-owned HEEx/CSS/LiveView adjustment
       -> If shared foundation issue appears repeatedly: record as exception; do not rewrite Phase 115 foundation by default
  -> Proof
       -> Update 117-FLOW-IA-REVIEW.md
       -> Run focused ExUnit + Playwright commands
       -> Hand Phase 118 a route evidence map and proof commands
```

### Recommended Project Structure

```text
.planning/phases/117-page-flow-ia-pass/
├── 117-RESEARCH.md              # This research artifact. [VERIFIED: output path]
├── 117-FLOW-IA-REVIEW.md        # Recommended compact IA/evidence matrix. [VERIFIED: 117-CONTEXT.md]
└── 117-VERIFICATION.md          # Optional phase closeout summary if execution follows prior pattern. [VERIFIED: prior phase artifacts]

examples/demo/frontend/tests/
└── admin-flow-ia.spec.ts        # Recommended route-level browser evidence spec. [ASSUMED]

examples/demo/backend/test/rulestead_demo_web/live/
└── ui_matrix_live_test.exs      # Existing fixture/source assertions to extend only for FLOW-04 gaps. [VERIFIED: codebase grep]
```

### Pattern 1: Route-Owned URL State

**What:** Keep filters, route view, pagination, environment, and permalink fields in query params handled by `handle_params/3` and patch navigation. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex]

**When to use:** Inventory filters, explain permalink fields, audit filters, environment links, and route-specific subnav. [VERIFIED: source files]

**Example:**
```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex
def handle_event("filters_changed", %{"filters" => filters}, socket) do
  merged_filters =
    socket.assigns.filters
    |> Map.merge(filters)
    |> Map.put("after", nil)
    |> Map.put("before", nil)

  {:noreply,
   push_patch(socket,
     to: build_index_path(socket.assigns.base_path, normalize_filters(merged_filters, socket.assigns.current_environment.key))
   )}
end
```

Official LiveView docs state `push_patch/2` invokes `handle_params/3` for current-LiveView URL state without reloading the page. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]

### Pattern 2: Evidence First, Then Small Route Fix

**What:** Add a failing or gap-revealing evidence row/spec before editing the route. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md]

**When to use:** Keyboard order, mobile scan order, missing first-glance answer, buried raw detail, weak return path, or incomplete fixture coverage. [VERIFIED: .planning/phases/117-page-flow-ia-pass/117-CONTEXT.md]

**Example:**
```typescript
// Source: examples/demo/frontend/tests/brand-ui-evidence.spec.ts
await expect(page.locator(".rs-shell__brand").first()).toBeVisible();
await expect(page.locator(".rs-theme-control__group").first()).toBeVisible();
await expectNoHorizontalOverflow(page);
await page.screenshot({ fullPage: true, path: testInfo.outputPath("admin-inventory-light-mobile.png") });
```

### Pattern 3: Prefer Function Components; Keep Page Shells in Routes

**What:** Use existing function components for reusable primitives and composites, but keep route-specific workflow state visible in LiveView modules. [VERIFIED: 116-RAW-MARKUP-CONSOLIDATION.md]

**When to use:** Inventory filters, rules workspace, kill runbook, audience inventory, home task board, audit/explain/simulate route forms. [VERIFIED: 116-PHASE-117-HANDOFF.md]

Official LiveComponent docs recommend function components by default and LiveComponents only when local state plus event handling are both needed. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]

### Anti-Patterns to Avoid

- **Adding new top-level navigation for every lens:** This violates D-01 through D-03; map lenses inside existing groups. [VERIFIED: 117-CONTEXT.md]
- **Fixing audit/explain/simulate as component debt:** These routes stay route-owned unless evidence shows an IA failure. [VERIFIED: 117-CONTEXT.md]
- **Introducing screenshot baselines:** Playwright `toHaveScreenshot()` creates golden expectations; Phase 117 requires generated artifacts only. [CITED: https://playwright.dev/docs/test-snapshots]
- **Moving URL/search/filter state into extracted components:** Phase 116 explicitly kept these page-owned to preserve URL state, streams, and route semantics. [VERIFIED: 116-RAW-MARKUP-CONSOLIDATION.md]
- **Using JavaScript for ordinary route hierarchy:** Phase 117 prefers semantic links, buttons, and forms; JS is reserved for focus-heavy widgets such as command palette. [VERIFIED: 117-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser focus, keyboard, mobile, and overflow evidence | Manual checklist only or custom screenshot diff harness | Playwright Test with existing helpers and artifact screenshots. [VERIFIED: examples/demo/frontend/tests/ui-matrix.spec.ts] | Browser behavior needs real layout, focus, and viewport checks; pixel baselines are out of scope. [VERIFIED: 117-CONTEXT.md] |
| Component/state stress catalog | Static duplicated HEEx catalog | Existing `/dev/rulestead-admin/ui-matrix` with real components and fixed assigns. [VERIFIED: examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex] | Static duplicated markup can drift from admin components. [VERIFIED: 113-UI-MATRIX-CONTRACT.md] |
| Navigation regrouping | Ad hoc route arrays in tests or pages | `RulesteadAdmin.Navigation` groups and `Shell.page/1` derived nav. [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex] | Single source prevents rail, launcher, and command palette drift. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/home_live/index.ex] |
| Combobox/dialog keyboard semantics | Custom ARIA invention | Existing command palette hook plus WAI-ARIA APG combobox/dialog expectations. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/] | APG defines expected roles and expanded/modal behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Large route state abstractions | New state manager or component framework | LiveView `handle_params`, `push_patch`, streams, forms, and function components. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] | Existing stack already solves route URL state and large lists. [VERIFIED: codebase grep] |

**Key insight:** Phase 117 risk is not missing a UI library; it is misassigning route-owned workflow semantics into reusable components or broad navigation redesign. [VERIFIED: 117-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Operator Lenses As New Nav Groups

**What goes wrong:** Audiences, rollouts, audit, destructive actions, denied states, and rare states become new top-level destinations. [VERIFIED: 117-CONTEXT.md]
**Why it happens:** The Phase 113 lens map is mistaken for shipped navigation. [VERIFIED: 113-UI-MATRIX-CONTRACT.md]
**How to avoid:** Keep `RulesteadAdmin.Navigation` groups; document lenses in `117-FLOW-IA-REVIEW.md`. [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex]
**Warning signs:** New top-level Rulesets, Settings, Audit, Rollouts, or Destructive rail items appear. [VERIFIED: 117-CONTEXT.md]

### Pitfall 2: Over-Broad Visual Evidence

**What goes wrong:** The plan adds pixel snapshots, visual diff tooling, or checked-in screenshot baselines. [VERIFIED: 117-CONTEXT.md]
**Why it happens:** Playwright screenshot artifacts are confused with Playwright snapshot assertions. [CITED: https://playwright.dev/docs/test-snapshots]
**How to avoid:** Use `page.screenshot({ path: testInfo.outputPath(...) })` for review artifacts and deterministic DOM/overflow/focus assertions for gates. [VERIFIED: examples/demo/frontend/tests/brand-ui-evidence.spec.ts]
**Warning signs:** `toHaveScreenshot`, `matchSnapshot`, `pixelmatch`, `visual-diff`, or `*-snapshots` appear in Phase 117 sources. [VERIFIED: examples/demo/frontend/tests/ui-matrix.spec.ts]

### Pitfall 3: Reopening Phase 115 Foundation Work

**What goes wrong:** Route failures trigger token, breakpoint, radius, shadow, focus-ring, or reduced-motion redesign. [VERIFIED: 117-CONTEXT.md]
**Why it happens:** Mobile/focus defects can look like foundation defects before route evidence is compared across surfaces. [VERIFIED: 115-FOUNDATIONS-CONTRACT.md]
**How to avoid:** First fix route hierarchy or route-owned layout; only record a foundation exception if multiple route failures prove a shared regression. [VERIFIED: 117-CONTEXT.md]
**Warning signs:** New breakpoints, token hierarchy changes, palette changes, or broad CSS foundation edits. [VERIFIED: 115-FOUNDATIONS-CONTRACT.md]

### Pitfall 4: Hiding URL State In Components

**What goes wrong:** Inventory filters, explain permalinks, audit filters, or rules workspace state move behind components that obscure `handle_params`, `push_patch`, streams, or form state. [VERIFIED: 116-RAW-MARKUP-CONSOLIDATION.md]
**Why it happens:** Route-owned raw markup is mistaken for unresolved component duplication. [VERIFIED: 116-PHASE-117-HANDOFF.md]
**How to avoid:** Keep route-owned shells in route modules; extract only stable subpatterns after evidence proves reuse. [VERIFIED: 117-CONTEXT.md]
**Warning signs:** New generic filter/workspace/runbook component owns route query or mutation state. [VERIFIED: source files]

### Pitfall 5: Audit/Explain/Simulate Redesign Without Trigger

**What goes wrong:** The phase turns into full explain/simulate/audit redesign. [VERIFIED: 117-CONTEXT.md]
**Why it happens:** These routes are important and visibly route-owned. [VERIFIED: prompts/rulestead-personas-jtbd-and-onboarding.md]
**How to avoid:** Edit only if evidence shows buried first answer, unclear redaction, inaccessible raw detail, missing permalink/sample/context, or stranded audit row. [VERIFIED: 117-CONTEXT.md]
**Warning signs:** Large form redesigns without a failing route-flow evidence row. [VERIFIED: 117-CONTEXT.md]

## Code Examples

### Route-Flow Evidence Spec Shape

```typescript
// Source pattern: examples/demo/frontend/tests/brand-ui-evidence.spec.ts
const adminSurfaces = [
  { name: "overview", path: "/admin/flags" },
  { name: "inventory", path: "/admin/flags/flags?env=staging&view=all" },
  { name: "explain", path: "/admin/flags/enable-new-dashboard/explain" },
  { name: "kill", path: "/admin/flags/enable-new-dashboard/kill" },
];

for (const surface of adminSurfaces) {
  test(`route flow evidence: ${surface.name}`, async ({ browser }, testInfo) => {
    const { context, page } = await openAdminSurface(browser, mobileViewport, lightTheme, surface.path);
    await expect(page.locator(".rs-shell")).toBeVisible();
    await expectNoHorizontalOverflow(page);
    await page.screenshot({ fullPage: true, path: testInfo.outputPath(`flow-${surface.name}-mobile.png`) });
    await context.close();
  });
}
```

### IA Review Artifact Row Shape

```markdown
| Operator job | Route cluster | Route / surface | Path evidence | State coverage | Finding | Action | Proof |
|--------------|---------------|-----------------|---------------|----------------|---------|--------|-------|
| Explain/diagnose | Explain & diagnose | Explain route | `/admin/flags/:key/explain?targeting_key=...` | happy, empty, error, redacted | First answer visible | none | `npm run test:e2e -- admin-flow-ia.spec.ts` |
```

### LiveView Route-Owned Patch Pattern

```elixir
# Source: official LiveView push_patch pattern + local inventory implementation.
{:noreply, push_patch(socket, to: build_index_path(socket.assigns.base_path, filters))}
```

Official docs state `handle_event/3` payloads are untrusted and must be authorized/validated before resource access or mutation. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static duplicated component catalog | Repo-native Phoenix matrix rendering real admin components | Phase 114, 2026-06-14. [VERIFIED: 114-02-SUMMARY.md] | Phase 117 should reuse matrix fixtures instead of adding Storybook or static HEEx catalogs. [VERIFIED: 114-02-SUMMARY.md] |
| Component polish as route redesign | Route-owned IA pass after primitives/composites are complete | Phase 116 handoff, 2026-06-14. [VERIFIED: 116-PHASE-117-HANDOFF.md] | Phase 117 should validate workflows and only make issue-triggered route fixes. [VERIFIED: 116-PHASE-117-HANDOFF.md] |
| Pixel baselines as visual gate | Generated screenshots plus deterministic assertions | v1.17 milestone posture. [VERIFIED: .planning/STATE.md] | Screenshots are human-review artifacts, not checked-in baselines. [VERIFIED: 117-CONTEXT.md] |
| Broad flat admin rail | Grouped JTBD navigation plus contextual subnav | Existing `RulesteadAdmin.Navigation`. [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex] | Operator lenses map inside current clusters. [VERIFIED: 117-CONTEXT.md] |

**Deprecated/outdated:**
- Storybook/PhoenixStorybook for this milestone: deferred because repo-native matrix evidence is the selected v1.17 strategy. [VERIFIED: .planning/REQUIREMENTS.md]
- Checked-in pixel baselines: deferred because curated artifacts plus deterministic assertions are the selected evidence posture. [VERIFIED: .planning/REQUIREMENTS.md]
- LiveComponents for ordinary markup organization: official docs prefer function components unless local state plus event handling are needed. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The new route-level Playwright spec should be named `admin-flow-ia.spec.ts`. [ASSUMED] | Recommended Project Structure | Low; planner can choose a different filename without changing strategy. |

## Open Questions (RESOLVED)

1. **Which exact route subset should be the Phase 117 browser evidence gate?** [VERIFIED: 117-CONTEXT.md]
   - What we know: Context requires representative primary route clusters and names the priority surfaces. [VERIFIED: 117-CONTEXT.md]
   - RESOLVED: Use overview, inventory, rules, kill, audiences, audit, explain, and simulate as the Phase 117 browser evidence set. This route set covers the grouped JTBD navigation, the Phase 116 page-owned handoff surfaces, and FLOW-01 through FLOW-04 without widening product seed semantics. [VERIFIED: 116-PHASE-117-HANDOFF.md]

2. **Should execution create `117-VERIFICATION.md` or only `117-FLOW-IA-REVIEW.md`?** [ASSUMED]
   - What we know: Prior phases use verification artifacts and Phase 118 needs handoff evidence. [VERIFIED: .planning/STATE.md]
   - RESOLVED: Plan `117-FLOW-IA-REVIEW.md` as the required route-flow IA artifact. Allow execution to add a concise verification summary only if it follows the established phase closeout pattern, but do not make `117-VERIFICATION.md` a substitute for the route-flow review artifact. [VERIFIED: 117-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Phoenix/ExUnit/LiveViewTest route checks | yes [VERIFIED: elixir --version] | 1.19.5 / OTP 28 [VERIFIED: elixir --version] | none |
| Mix | Dependency/test commands | yes [VERIFIED: mix --version] | 1.19.5 [VERIFIED: mix --version] | none |
| Node.js | Playwright frontend tests | yes [VERIFIED: node --version] | 22.14.0 [VERIFIED: node --version] | none |
| npm | Playwright command runner | yes [VERIFIED: npm --version] | 11.1.0 [VERIFIED: npm --version] | none |
| Playwright Test | Browser route evidence | yes [VERIFIED: npx playwright --version] | 1.60.0 [VERIFIED: npx playwright --version] | Use ExUnit/source checks for non-browser claims only; no full browser fallback. [VERIFIED: test strategy] |
| Demo backend | Mounted admin route evidence | needs runtime start [VERIFIED: examples/demo/frontend/tests/support/admin.ts] | configured by `DEMO_BACKEND_URL`, default `http://localhost:4000` [VERIFIED: support/admin.ts] | Use an alternate port and set `DEMO_BACKEND_URL`. [VERIFIED: 116-VERIFICATION.md] |

**Missing dependencies with no fallback:**
- None detected for research; execution must start a demo backend before Playwright route evidence. [VERIFIED: test files]

**Missing dependencies with fallback:**
- Default port `4000` may be occupied in this environment; prior verification used an alternate backend URL. [VERIFIED: 116-VERIFICATION.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix.LiveViewTest plus Playwright Test `1.60.0`. [VERIFIED: test files + npm ls] |
| Config file | `examples/demo/frontend/playwright.config.ts`; ExUnit config via project test helpers. [VERIFIED: file listing] |
| Quick run command | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` [VERIFIED: existing command pattern] |
| Full route evidence command | `cd examples/demo/frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- admin-flow-ia.spec.ts` [ASSUMED] |
| Existing matrix command | `cd examples/demo/frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- ui-matrix.spec.ts` [VERIFIED: 116-VERIFICATION.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FLOW-01 | Route clusters map to operator JTBD and current navigation groups. [VERIFIED: .planning/REQUIREMENTS.md] | source/doc + ExUnit | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` plus review artifact checks. [ASSUMED] | Partial; review artifact missing. [VERIFIED: file listing] |
| FLOW-02 | Page hierarchy supports onboarding/intermediate/advanced paths. [VERIFIED: .planning/REQUIREMENTS.md] | doc + Playwright route evidence | `cd examples/demo/frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- admin-flow-ia.spec.ts` [ASSUMED] | No, Wave 0. [VERIFIED: file listing] |
| FLOW-03 | Keyboard/focus/mobile/narrow viewports usable across route clusters. [VERIFIED: .planning/REQUIREMENTS.md] | Playwright | `cd examples/demo/frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- admin-flow-ia.spec.ts` [ASSUMED] | No, Wave 0. [VERIFIED: file listing] |
| FLOW-04 | Deterministic fixtures cover happy/error/boundary/rare route states without product semantics changes. [VERIFIED: .planning/REQUIREMENTS.md] | ExUnit + Playwright | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs && cd ../frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- ui-matrix.spec.ts` [VERIFIED: existing pattern] | Partial; extend only if review finds gaps. [VERIFIED: ui_matrix_fixtures.ex] |

### Sampling Rate

- **Per task commit:** Run the focused ExUnit test for touched route/fixture files and, for browser-facing route changes, the new Phase 117 Playwright spec. [ASSUMED]
- **Per wave merge:** Run `ui_matrix_live_test.exs`, `ui-matrix.spec.ts`, and the new route-flow spec. [ASSUMED]
- **Phase gate:** Ensure `117-FLOW-IA-REVIEW.md` covers FLOW-01 through FLOW-04 and focused ExUnit/Playwright commands are green. [VERIFIED: 117-CONTEXT.md]

### Wave 0 Gaps

- [ ] `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` — maps operator job, route cluster, surface, state coverage, finding, action, proof. [VERIFIED: 117-CONTEXT.md]
- [ ] `examples/demo/frontend/tests/admin-flow-ia.spec.ts` — route-level browser evidence for selected clusters. [ASSUMED]
- [ ] Optional ExUnit/source assertion for navigation cluster review artifact coverage if planner wants machine-readable FLOW-01 proof. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct Phase 117 change [VERIFIED: phase scope] | Host app owns auth/session for mounted admin. [VERIFIED: prompts/rulestead-admin-ux-and-operator-ia.md] |
| V3 Session Management | no direct Phase 117 change [VERIFIED: phase scope] | Do not widen mounted route/session contract. [VERIFIED: 117-CONTEXT.md] |
| V4 Access Control | yes, preserve existing policy-gated route behavior. [VERIFIED: source files] | Do not move authorization into browser-only checks; LiveView events must validate untrusted payloads. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| V5 Input Validation | yes, forms/search/filters are in scope for evidence. [VERIFIED: source files] | Keep form/query validation in route modules and context APIs; preserve redaction boundaries. [VERIFIED: explain.ex + simulate.ex] |
| V6 Cryptography | no direct Phase 117 change [VERIFIED: phase scope] | Do not add crypto, signing, or audit export changes. [VERIFIED: 117-CONTEXT.md] |
| V9 Communications | no direct Phase 117 change [VERIFIED: phase scope] | No new network/public API surfaces. [VERIFIED: 117-CONTEXT.md] |
| V10 Malicious Code | yes for dependency/tooling discipline. [ASSUMED] | No new packages; keep no Storybook/pixel-baseline tooling source guards. [VERIFIED: ui-matrix.spec.ts] |
| V14 Configuration | yes for route exposure. [ASSUMED] | Keep UI matrix dev/test-only and do not expose it through `RulesteadAdmin.Router.rulestead_admin/2`. [VERIFIED: ui_matrix_live_test.exs] |

### Known Threat Patterns for Phoenix LiveView Admin IA

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Route evidence accidentally expands public admin surface | Elevation of privilege | Do not add public routes; keep matrix under demo-host dev/test route. [VERIFIED: 114-VERIFICATION.md] |
| Browser-only disabled/unavailable controls treated as authorization | Elevation of privilege | Server-side LiveView events and context APIs must validate payloads and capabilities. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| Explain/simulate/audit leaks raw trait or metadata detail | Information disclosure | Preserve existing redaction boundaries and support-safe trace copy. [VERIFIED: explain.ex + audit_live/index.ex] |
| Destructive workflow loses reason/evidence/audit handoff under IA edits | Tampering / Repudiation | Keep preview/confirm/reason/typed key/back link/audit handoff visible in route evidence. [VERIFIED: 117-CONTEXT.md] |
| Keyboard trap or hidden modal background interaction | Denial of service / accessibility failure | Test command palette/dialog behavior against WAI-ARIA modal and combobox expectations. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/117-page-flow-ia-pass/117-CONTEXT.md` — locked Phase 117 decisions, route surfaces, evidence posture, and deferred scope. [VERIFIED: codebase read]
- `.planning/REQUIREMENTS.md` — FLOW-01 through FLOW-04 descriptions and v1.17 constraints. [VERIFIED: codebase read]
- `.planning/STATE.md` — v1.17 phase sequence, prior decisions, current position, and evidence posture. [VERIFIED: codebase read]
- `AGENTS.md` — project constraints. [VERIFIED: codebase read]
- `rulestead_admin/lib/rulestead_admin/navigation.ex` — grouped navigation source of truth. [VERIFIED: codebase read]
- `rulestead_admin/lib/rulestead_admin/live/**` route modules — route-owned IA surfaces. [VERIFIED: codebase read]
- `examples/demo/frontend/tests/ui-matrix.spec.ts` and `brand-ui-evidence.spec.ts` — existing Playwright evidence patterns. [VERIFIED: codebase read]
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` — deterministic fixture coverage. [VERIFIED: codebase read]
- Phoenix LiveView official docs — lifecycle, async, `push_patch`, streams, event security. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]
- Phoenix LiveComponent official docs — function component preference. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]
- Playwright official snapshot docs — snapshot behavior and pixelmatch use for screenshot comparisons. [CITED: https://playwright.dev/docs/test-snapshots]
- WAI-ARIA APG combobox/dialog pages — command palette/search role semantics. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/]

### Secondary (MEDIUM confidence)

- `prompts/rulestead-admin-ux-and-operator-ia.md` — admin UX north-star, preview-confirm-audit, keyboard-first, progressive disclosure. [VERIFIED: codebase read]
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — operator personas and jobs-to-be-done. [VERIFIED: codebase read]
- `prompts/rulestead-testing-and-e2e-strategy.md` — test pyramid and curated browser evidence posture. [VERIFIED: codebase read]
- `prompts/rulestead-domain-language-field-guide.md` — canonical flag/audience/rollout/kill switch/audit vocabulary. [VERIFIED: codebase read]
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit and redaction principles. [VERIFIED: codebase read]
- `prompts/phoenix-live-view-best-practices-deep-research.md` — local LiveView best-practice synthesis, cross-checked against official docs where used. [VERIFIED: codebase read + official docs]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: source log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing packages and versions were verified locally; official docs were checked for LiveView, Playwright, and WAI-ARIA claims. [VERIFIED: command history + official docs]
- Architecture: HIGH — route ownership and navigation boundaries are explicit in Phase 117 context, Phase 116 handoff, and source modules. [VERIFIED: codebase read]
- Pitfalls: HIGH — pitfalls map directly to locked decisions and prior phase handoffs. [VERIFIED: 117-CONTEXT.md + 116-PHASE-117-HANDOFF.md]
- Validation: MEDIUM — existing test infrastructure is verified, but the new Phase 117 route evidence spec filename and exact route set remain planner discretion. [ASSUMED]

**Research date:** 2026-06-14 [VERIFIED: environment current_date]
**Valid until:** 2026-07-14 for local architecture and phase scope; re-check official package/docs versions if planning happens after that date. [ASSUMED]
