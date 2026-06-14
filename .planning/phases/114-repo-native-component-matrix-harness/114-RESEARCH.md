# Phase 114: Repo-Native Component Matrix Harness - Research

**Researched:** 2026-06-14
**Domain:** Phoenix LiveView demo-host UI harness + Playwright browser evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Harness Placement

- **D-01:** Build the matrix as a dev/test-only Phoenix LiveView surface in the demo host, not as a route added to `RulesteadAdmin.Router.rulestead_admin/2`. The demo host already mounts the real admin and ships the admin CSS for browser evidence; keeping the matrix outside the package router avoids widening the mounted product contract.
- **D-02:** Use an internal, unambiguous demo route outside `/admin/flags` catch-all routes, for example `/dev/rulestead-admin/ui-matrix`, guarded so it is unavailable in production. The exact guard may be a demo-host config flag or `Mix.env()`-style dev/test gate, but the route must not become part of the public mounted admin route set.
- **D-03:** The matrix may live in `examples/demo/backend` and import real `RulesteadAdmin.Components.*` modules directly. Do not copy component HEEx into a static catalog or move matrix-only helpers into publishable package API docs.

### Matrix Content Model

- **D-04:** Organize the matrix by the Phase 113 taxonomy: foundations reference rows, primitives, composites, page patterns, and workflow states. The visible matrix should be easy for Phase 115-118 planners to map back to Phase 113 tables.
- **D-05:** Render real function components with centralized fixed assigns for component states. Use helper functions/modules for fixture data so long labels, long keys, dense records, denied states, unavailable states, destructive confirmations, and audit raw detail remain deterministic.
- **D-06:** Use seeded/demo route links or embedded route examples only where the full LiveView flow is the real source of truth, such as flag inventory, rules, rollouts, audit/timeline, command palette shell, and destructive preview -> confirm -> audit paths. Component examples remain direct component renders.
- **D-07:** Cover the required Phase 113 states explicitly: normal, dense, empty, loading, error, permission-denied/read-only, long-label/long-key, narrow-width/mobile, destructive-action, disabled/unavailable, focus, and keyboard-relevant cases.
- **D-08:** Include at least one matrix example for every operator lens: build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding/happy paths, and destructive actions.

### Browser Evidence

- **D-09:** Add curated Playwright coverage for the matrix across light, dark, system-dark, desktop, mobile/narrow, and reduced-motion contexts. Reuse the existing `brand-ui-evidence.spec.ts` loop shape where practical.
- **D-10:** Browser assertions should prove matrix reachability, `.rs-shell` rendering, representative section visibility, no horizontal page overflow, theme-mode rendering, selected focus/keyboard affordances, and screenshot artifact creation. Do not assert broad visual pixel equality.
- **D-11:** Keep static fixtures (`design-system.html`, `theme-control-harness.html`, `theme-harness.html`) available for low-level token/theme/contrast guard assertions. They remain supporting evidence, not the component contract.

### Verification and Scope Control

- **D-12:** Keep verification narrow to DSM-02: route/component reachability tests, matrix fixture health assertions, Playwright browser proof, and existing lint/brand guard chain. Do not expand the guard chain unless the matrix exposes a concrete repeatable drift class.
- **D-13:** Preserve the linked-version sibling-package release model. No package metadata, Hex publish posture, release workflow, or public documentation should imply a standalone `rulestead_admin` publish path.
- **D-14:** Treat the matrix as an evidence harness for later work, not the polish work itself. If the matrix reveals CSS, focus, responsive, or component consistency defects, record them for Phase 115 or Phase 116 instead of fixing them inside Phase 114 unless the defect prevents the matrix from rendering.

### Methodology

- **D-15:** Apply the project methodology lenses as recommendation-first defaults. Because the selected shape does not change public API, security/governance posture, package boundary, or release model, no additional user decision is required before planning.

### the agent's Discretion

The planner may choose the exact module names, fixture helper names, and route guard implementation, provided the result remains demo-hosted, dev/test-only, real-component-backed, deterministic, and easy for Playwright to visit. Prefer small, explicit fixture helpers over metaprogrammed component discovery; the point is reliable review coverage, not automatic exhaustive inventory.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Breakpoint, typography, spacing, radius, shadow/elevation, focus-ring, reduced-motion, and responsive table hardening belongs to Phase 115.
- Primitive/composite visual polish, raw `rs-*` consolidation, and mutation-confirm consistency tuning belongs to Phase 116.
- Full page-flow and IA changes belong to Phase 117.
- Milestone-wide screenshot/assertion closeout and any reusable guard-chain extensions belong to Phase 118.
- PhoenixStorybook, JavaScript Storybook, broad checked-in pixel baselines, external AI visual judging, forced-colors/high-contrast OS mode, v2 product wedges, FleetDesk rebranding, and `rulestead_admin` standalone publish preparation remain out of scope.

### Reviewed Todos (not folded)

None - no pending todos matched Phase 114.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DSM-02 | Maintainer can open a repo-native UI matrix that renders real `RulesteadAdmin.Components.*` components with fixed assigns instead of duplicated static HEEx. | Use a demo-host LiveView route under `examples/demo/backend`, direct imports of `RulesteadAdmin.Components.*`, centralized deterministic fixture helpers, ExUnit reachability/component checks, and Playwright evidence against the route. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Build Phase 114 as a small demo-host Phoenix LiveView, not as a package router feature. The demo backend already depends on `rulestead_admin`, mounts the real admin under `/admin/flags`, uses the demo root layout, and ships `rulestead_admin.css`, so a route like `/dev/rulestead-admin/ui-matrix` can render real admin components inside `.rs-shell` without widening `RulesteadAdmin.Router.rulestead_admin/2`. [VERIFIED: codebase grep]

Use explicit fixture helper functions instead of discovery or Storybook-style registries. The Phase 113 contract already names the matrix buckets, states, operator lenses, and source modules; the planner should turn those rows into direct component invocations with fixed assigns and route links to selected seeded flows. [VERIFIED: codebase grep]

Browser proof should extend the existing Playwright evidence style: create browser contexts for light, dark, system-dark, desktop, mobile, and reduced-motion; assert reachability, shell rendering, section visibility, overflow absence, selected keyboard/focus behavior, and screenshot creation. Playwright officially supports browser context `colorScheme` and `reducedMotion`, and `page.screenshot({ path })` writes image artifacts. [CITED: https://playwright.dev/docs/api/class-browser] [CITED: https://playwright.dev/docs/api/class-page]

**Primary recommendation:** Implement one dev/test-only demo LiveView route plus deterministic fixture helpers and one curated Playwright matrix spec; do not add packages, public admin routes, schema changes, CSS polish, or pixel baselines. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Rulestead is a sibling-package monorepo with `rulestead/` and `rulestead_admin/`. [VERIFIED: AGENTS.md]
- Use `.planning/` and `prompts/` as ground truth. [VERIFIED: AGENTS.md]
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: AGENTS.md]
- Keep Phase 8-only docs absent until the roadmap says they ship. [VERIFIED: AGENTS.md]
- Do not publish or prepare to publish the `rulestead_admin` stub. [VERIFIED: AGENTS.md]
- Keep edits aligned with the linked-version, two-package release design. [VERIFIED: AGENTS.md]
- Make the smallest coherent change that satisfies the active plan. [VERIFIED: AGENTS.md]
- Avoid speculative features from future phases. [VERIFIED: AGENTS.md]
- Preserve reproducibility and CI readability. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Matrix route gating | Frontend Server (Phoenix demo host) | Browser | The route belongs in `examples/demo/backend` and must be unavailable in production; browser only visits it. [VERIFIED: codebase grep] |
| Real component rendering | Frontend Server (Phoenix LiveView) | API / Backend | Phoenix function components render server-side HEEx; fixture data may represent backend outcomes but should be fixed, not fetched. [CITED: https://phoenix.hexdocs.pm/components.html] |
| Fixture assigns | Frontend Server (Phoenix demo host) | Database / Storage (none) | Fixed helper data keeps matrix deterministic and avoids schema/store changes. [VERIFIED: 114-CONTEXT.md] |
| Theme and motion evidence | Browser | Frontend Server | Playwright emulates color scheme and reduced motion at browser context level while Phoenix serves the same matrix route. [CITED: https://playwright.dev/docs/api/class-browser] |
| Static token/theme guard fixtures | CDN / Static | Browser | Existing static fixtures remain low-level guard inputs and are not the component contract. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.7 locked in demo backend | Demo route, router, layout, ConnTest surface | Existing demo backend uses Phoenix and already hosts admin browser evidence. [VERIFIED: `mix deps`] |
| Phoenix LiveView | 1.1.30 locked in demo backend | Matrix LiveView and server-rendered component surface | LiveViewTest supports function component and LiveView testing; project already compiles colocated hooks. [VERIFIED: `mix deps`] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |
| `@playwright/test` | 1.60.0 installed | Browser matrix evidence and screenshots | Existing evidence specs use Playwright; official API supports required contexts and screenshots. [VERIFIED: npm local install] [CITED: https://playwright.dev/docs/api/class-browser] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `lazy_html` | present as test-only demo dependency | HTML assertions in Elixir tests | Use only if the route/component smoke test needs structured HTML selection beyond string checks. [VERIFIED: `mix deps`] |
| PostgreSQL / Ecto test setup | PostgreSQL 14.17 available locally | Demo backend test database setup | Needed by the demo backend `ConnCase` test alias path; avoid new DB schema/data requirements. [VERIFIED: environment probe] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Demo-host LiveView route | `RulesteadAdmin.Router.rulestead_admin/2` route | Rejected by D-01 because it widens the mounted admin product contract. [VERIFIED: 114-CONTEXT.md] |
| Explicit fixture helpers | Metaprogrammed component discovery | Rejected by D-15 because reliable review coverage is preferred over automatic exhaustive inventory. [VERIFIED: 114-CONTEXT.md] |
| Playwright screenshots/assertions | Broad checked-in pixel baselines | Rejected by roadmap and D-10 because the project uses curated screenshots plus deterministic assertions. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| PhoenixStorybook or JS Storybook | External component framework | Out of scope for this phase and milestone. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Installation:**

No new packages should be installed for Phase 114. [VERIFIED: codebase grep]

**Version verification:**

```bash
cd examples/demo/backend && mix deps | rg 'phoenix|live_view|lazy_html'
cd examples/demo/frontend && npm list @playwright/test --depth=0
```

Verified locally: Phoenix 1.8.7, Phoenix LiveView 1.1.30, `@playwright/test` 1.60.0. [VERIFIED: local commands]

## Package Legitimacy Audit

Not applicable: Phase 114 should install no external packages. [VERIFIED: 114-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | none | n/a | n/a | n/a | n/a | No install planned |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no package installs planned]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package installs planned]

## Architecture Patterns

### System Architecture Diagram

```text
Playwright / maintainer browser
  -> GET /dev/rulestead-admin/ui-matrix
    -> RulesteadDemoWeb.Router dev/test gate
      -> RulesteadDemoWeb.UiMatrixLive
        -> RulesteadDemoWeb.UiMatrixFixtures fixed assigns
        -> RulesteadAdmin.Components.Shell.page/1
          -> RulesteadAdmin.Components.* direct function component renders
          -> Links to selected seeded /admin/flags flows where full LiveView flow is source truth
        -> Demo root layout + admin CSS + LiveView socket
  -> assertions: .rs-shell, sections, theme, focus/keyboard, no horizontal overflow, screenshots
```

### Recommended Project Structure

```text
examples/demo/backend/lib/rulestead_demo_web/live/
├── ui_matrix_live.ex          # dev/test-only matrix LiveView
└── ui_matrix_fixtures.ex      # centralized fixed assigns and stress data

examples/demo/backend/test/rulestead_demo_web/live/
└── ui_matrix_live_test.exs    # route gate + component reachability smoke tests

examples/demo/frontend/tests/
└── ui-matrix.spec.ts          # Playwright matrix evidence
```

If the project prefers keeping fixture helpers outside `live/`, `examples/demo/backend/lib/rulestead_demo_web/ui_matrix_fixtures.ex` is also acceptable; keep it demo-host-only. [ASSUMED]

### Pattern 1: Demo-Host Live Route Outside Mounted Admin

**What:** Add a Phoenix LiveView route in the demo router under a dev/test-only scope, separate from `scope "/admin"` and `rulestead_admin("/flags", ...)`. [VERIFIED: codebase grep]

**When to use:** Use for the matrix route because D-01 forbids adding this harness to the public mounted admin route set. [VERIFIED: 114-CONTEXT.md]

**Example:**

```elixir
# Source: existing demo router pattern + Phoenix LiveView route macro docs.
if Mix.env() in [:dev, :test] do
  scope "/dev/rulestead-admin", RulesteadDemoWeb do
    pipe_through :browser

    live "/ui-matrix", UiMatrixLive, :index
  end
end
```

Phoenix LiveView routes are standard Phoenix router entries for LiveViews. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html]

### Pattern 2: Shell-Wrapped Real Component Matrix

**What:** Render matrix sections inside `RulesteadAdmin.Components.Shell.page/1`, then call real `RulesteadAdmin.Components.*` function components with fixture assigns. [VERIFIED: codebase grep]

**When to use:** Use when the matrix needs real theme scope, command palette shell, navigation, focus styles, and admin CSS behavior. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: RulesteadAdmin.Components.Shell.page/1 attr contract in shell.ex.
defmodule RulesteadDemoWeb.UiMatrixLive do
  use RulesteadDemoWeb, :live_view

  import RulesteadAdmin.Components.OperatorComponents
  import RulesteadAdmin.Components.FlagComponents
  alias RulesteadAdmin.Components.Shell
  alias RulesteadDemoWeb.UiMatrixFixtures

  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Rulestead admin UI matrix"
      page_kicker="Design-system evidence"
      page_summary="Real admin components rendered with deterministic fixture assigns."
      current_environment={UiMatrixFixtures.environment()}
      environments={UiMatrixFixtures.environments()}
      base_path="/admin/flags"
      current_section={:home}
      policy_state={UiMatrixFixtures.policy_state()}
      flash={%{}}
    >
      <section id="matrix-primitives" data-matrix-section="primitives">
        <.banner tone="warning" title="Long-label warning">
          <%= UiMatrixFixtures.long_reason() %>
        </.banner>
        <.lifecycle_badge status={:active} />
      </section>
    </Shell.page>
    """
  end
end
```

### Pattern 3: Playwright Matrix Context Loop

**What:** Reuse the existing theme/viewport loop shape from `brand-ui-evidence.spec.ts` and add `reducedMotion: "reduce"` cases. [VERIFIED: codebase grep] [CITED: https://playwright.dev/docs/api/class-browser]

**When to use:** Use for browser evidence that must prove the matrix route is reachable across light, dark, system-dark, desktop, mobile, and reduced-motion contexts. [VERIFIED: 114-CONTEXT.md]

**Example:**

```typescript
// Source: existing brand-ui-evidence.spec.ts + Playwright Browser.newContext docs.
const context = await browser.newContext({
  colorScheme: theme.colorScheme,
  reducedMotion: motion.reducedMotion,
  viewport: { width: viewport.width, height: viewport.height },
});
const page = await context.newPage();
await page.goto(`${backendUrl}/dev/rulestead-admin/ui-matrix`);
await expect(page.locator(".rs-shell")).toBeVisible();
await expect(page.locator('[data-matrix-section="primitives"]')).toBeVisible();
await page.screenshot({
  fullPage: true,
  path: testInfo.outputPath(`ui-matrix-${theme.name}-${viewport.name}-${motion.name}.png`),
});
```

### Anti-Patterns to Avoid

- **Static HEEx component catalog:** It can drift from `RulesteadAdmin.Components.*`; render real function components instead. [VERIFIED: 113-UI-MATRIX-CONTRACT.md]
- **Adding matrix routes to `RulesteadAdmin.Router`:** It changes the mounted package contract and conflicts with D-01. [VERIFIED: 114-CONTEXT.md]
- **Fixing visual polish discovered by the matrix:** Route defects to Phase 115 or Phase 116 unless rendering is blocked. [VERIFIED: 114-CONTEXT.md]
- **Broad pixel equality assertions:** The project standard is curated screenshots plus deterministic assertions, not checked-in pixel baselines. [VERIFIED: `.planning/REQUIREMENTS.md`]
- **Adding Storybook/PhoenixStorybook:** Explicitly out of scope for this phase. [VERIFIED: 114-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Component rendering | Static duplicate HEEx snippets | Existing `RulesteadAdmin.Components.*` function components | Phoenix function components are the project component abstraction and LiveViewTest can render them. [CITED: https://phoenix.hexdocs.pm/components.html] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |
| Browser theme/motion emulation | Custom JS toggles for media features | Playwright `browser.newContext({ colorScheme, reducedMotion })` | Playwright natively emulates required media features. [CITED: https://playwright.dev/docs/api/class-browser] |
| Screenshot output | Custom image capture or visual diff infra | `page.screenshot({ path, fullPage })` | Playwright natively saves screenshot artifacts. [CITED: https://playwright.dev/docs/api/class-page] |
| Keyboard proof | Manual DOM event dispatch | Playwright locator `.press()` | Locator press focuses the target and sends a real keystroke path. [CITED: https://playwright.dev/docs/input] |
| Matrix inventory | Runtime introspection of components | Explicit fixture sections from Phase 113 taxonomy | The locked decision favors small explicit fixtures over discovery. [VERIFIED: 114-CONTEXT.md] |

**Key insight:** This harness is evidence infrastructure, not a component framework. Keep it explicit, deterministic, and close to existing Phoenix/Playwright patterns. [VERIFIED: 114-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Route Leaks Into Public Admin Contract

**What goes wrong:** The matrix is added inside `RulesteadAdmin.Router.rulestead_admin/2` or under `/admin/flags/:key`, making it look like product surface. [VERIFIED: codebase grep]
**Why it happens:** The mounted admin route macro owns many routes and has a catch-all `/:key` family after specific routes. [VERIFIED: codebase grep]
**How to avoid:** Add an explicit demo-host route under `/dev/rulestead-admin/ui-matrix`, outside `scope "/admin"`, guarded to dev/test only. [VERIFIED: 114-CONTEXT.md]
**Warning signs:** Router tests or source assertions show `/ui-matrix` in `rulestead_admin/2`, or Playwright reaches the matrix under `/admin/flags`. [VERIFIED: 114-CONTEXT.md]

### Pitfall 2: Fixture Markup Drifts From Real Components

**What goes wrong:** Matrix examples copy HEEx into custom static markup and stop reflecting package component changes. [VERIFIED: 113-UI-MATRIX-CONTRACT.md]
**Why it happens:** Static fixtures are easier to author than real assigns but are not the component contract. [VERIFIED: 113-DESIGN-SYSTEM-INVENTORY.md]
**How to avoid:** Directly import or alias `RulesteadAdmin.Components.*` and centralize assigns in fixture helpers. [VERIFIED: 114-CONTEXT.md]
**Warning signs:** Matrix source contains large copied `rs-*` HEEx blocks for components that already exist in `rulestead_admin/lib/rulestead_admin/components`. [VERIFIED: codebase grep]

### Pitfall 3: Browser Evidence Becomes Too Broad

**What goes wrong:** The plan adds pixel baselines, external visual AI, or many route-flow screenshots that belong to Phase 118. [VERIFIED: `.planning/REQUIREMENTS.md`]
**Why it happens:** A matrix naturally exposes many future polish defects. [VERIFIED: 114-CONTEXT.md]
**How to avoid:** For Phase 114, assert matrix reachability, sections, shell, overflow, theme/motion contexts, selected keyboard/focus, and screenshot artifacts only. [VERIFIED: 114-CONTEXT.md]
**Warning signs:** New screenshot baseline directories, snapshot comparisons, or visual-diff tooling appear. [VERIFIED: 114-CONTEXT.md]

### Pitfall 4: Colocated Hook Expectations Without LiveView Asset Context

**What goes wrong:** Shell command palette or theme hooks fail because the matrix is rendered outside the demo LiveView asset pipeline. [VERIFIED: codebase grep]
**Why it happens:** The demo `app.js` imports `phoenix-colocated/rulestead_demo`, while shell components include colocated hooks. [VERIFIED: codebase grep]
**How to avoid:** Use the demo root layout and LiveView route, not file-only static HTML. [VERIFIED: codebase grep]
**Warning signs:** `.rs-cmdk` never opens or theme control hooks do not initialize in Playwright. [ASSUMED]

## Code Examples

### Fast Component Smoke Test

```elixir
# Source: existing component tests and Phoenix.LiveViewTest docs.
defmodule RulesteadDemoWeb.UiMatrixLiveTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  test "matrix route renders shell and required sections", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/dev/rulestead-admin/ui-matrix")

    assert html =~ "rs-shell"
    assert html =~ ~s(data-matrix-section="primitives")
    assert html =~ ~s(data-matrix-section="destructive")
    assert html =~ "Rulestead admin UI matrix"
  end
end
```

LiveViewTest officially supports connected route testing with `live(conn, "/path")` and component testing with `render_component`. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html]

### No Horizontal Overflow Assertion

```typescript
// Source: existing brand-ui-evidence.spec.ts.
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

### Keyboard / Command Palette Probe

```typescript
// Source: existing Shell.page command palette markup + Playwright input docs.
await page.locator(".rs-shell__search").press("Enter");
await expect(page.locator("#rs-cmdk")).toBeVisible();
await page.getByRole("combobox", { name: "Search commands and pages" }).fill("audit");
await page.getByRole("combobox", { name: "Search commands and pages" }).press("ArrowDown");
await expect(page.getByRole("option").first()).toBeVisible();
```

Playwright recommends locator interactions for keyboard actions; `locator.press()` focuses the selected element and sends a keystroke. [CITED: https://playwright.dev/docs/input]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static `design-system.html` as broad UI reference | Repo-native Phoenix matrix renders real components; static fixtures stay low-level token/theme guards | Locked in Phase 113 and Phase 114 context on 2026-06-13 | Planner should build component examples in LiveView, not duplicate markup. [VERIFIED: 113-UI-MATRIX-CONTRACT.md] |
| JS Storybook for component docs | No component framework; explicit Phoenix/Playwright harness | v1.17 roadmap | Avoid package/tooling additions and drift from LiveView components. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Pixel baselines | Curated screenshots plus deterministic assertions | v1.17 roadmap and inherited v1.16 evidence posture | Playwright should write artifacts but not compare broad pixels. [VERIFIED: `.planning/STATE.md`] |

**Deprecated/outdated:**
- Treating static fixtures as the component contract is deprecated for Phase 114; they remain guard inputs only. [VERIFIED: 113-UI-MATRIX-CONTRACT.md]
- Adding package-public docs or publish preparation for `rulestead_admin` is forbidden by AGENTS.md and Phase 114 context. [VERIFIED: AGENTS.md] [VERIFIED: 114-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `examples/demo/backend/lib/rulestead_demo_web/live/` is the preferred folder for the new LiveView and fixture module. | Recommended Project Structure | Low: planner can choose an equivalent demo-host-only path. |
| A2 | Hook failure warning signs include command palette/theme hook initialization failures. | Common Pitfalls | Low: planner can verify with Playwright if route renders but hooks do not respond. |

## Open Questions

1. **Should the route guard use `Mix.env()` or application config?**
   - What we know: D-02 allows either a demo-host config flag or `Mix.env()` style dev/test gate. [VERIFIED: 114-CONTEXT.md]
   - What's unclear: The exact preferred implementation is left to planner discretion. [VERIFIED: 114-CONTEXT.md]
   - Recommendation: Use the smallest explicit guard, `if Mix.env() in [:dev, :test]`, unless existing config conventions make a flag clearer. [ASSUMED]

2. **How many route links should be embedded versus direct component examples?**
   - What we know: D-06 says component examples remain direct renders, while full flows can link to seeded routes. [VERIFIED: 114-CONTEXT.md]
   - What's unclear: Exact count of route examples is not locked. [VERIFIED: 114-CONTEXT.md]
   - Recommendation: Include a small "page patterns / route examples" section with links to inventory, rules, rollouts, audit/timeline, command palette shell context, and destructive preview/confirm flows; keep most matrix rows direct component renders. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Phoenix compile and ExUnit | yes | Elixir 1.19.5, Mix 1.19.5 | none |
| Erlang/OTP | Phoenix runtime | yes | OTP 28 | none |
| Node.js | Playwright runner | yes | v22.14.0 | none |
| npm | Frontend scripts | yes | 11.1.0 | none |
| `@playwright/test` | Browser evidence | yes | 1.60.0 | none |
| PostgreSQL | Demo backend test DB setup | yes | 14.17 accepting connections on `/tmp:5432` | none for demo `ConnCase` |
| Docker | Optional compose/browser proof | yes | Docker client 29.5.2 | Use local services if compose is unnecessary |
| Context7 CLI | Library docs lookup | no | n/a | Official docs via web search/open |

**Missing dependencies with no fallback:**
- None found for Phase 114 planning. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- Context7 CLI was unavailable; official Hexdocs and Playwright docs were used instead. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest, Playwright Test |
| Config file | `examples/demo/frontend/playwright.config.ts`; Mix configs per package |
| Quick run command | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |
| Full suite command | `scripts/ci/lint.sh && cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DSM-02 | Demo-host route renders real admin components and required sections | ExUnit LiveView route/component smoke | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | no - Wave 0 |
| DSM-02 | Matrix reachable across light/dark/system-dark, desktop/mobile/reduced-motion with screenshots and overflow assertions | Playwright e2e | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` | no - Wave 0 |
| DSM-02 | Static token/theme fixtures remain available | Existing Playwright/static guard regression | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | yes |

### Sampling Rate

- **Per task commit:** `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs`
- **Per wave merge:** `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts`
- **Phase gate:** `scripts/ci/lint.sh` plus the matrix Playwright spec green before `$gsd-verify-work`.

### Wave 0 Gaps

- [ ] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - route surface for DSM-02.
- [ ] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - deterministic fixture assigns.
- [ ] `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - route and component reachability.
- [ ] `examples/demo/frontend/tests/ui-matrix.spec.ts` - browser evidence.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Matrix is dev/test-only and should not change auth. [VERIFIED: 114-CONTEXT.md] |
| V3 Session Management | no | Do not alter mounted admin session keys. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Keep route unavailable in production and keep denied/read-only examples as fixtures, not policy weakening. [VERIFIED: 114-CONTEXT.md] |
| V5 Input Validation | yes | Fixed fixture assigns only; no user-submitted matrix mutations. [VERIFIED: 114-CONTEXT.md] |
| V6 Cryptography | no | No cryptographic operation is introduced. [VERIFIED: 114-CONTEXT.md] |

### Known Threat Patterns for Phoenix Demo Harness

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dev-only route exposed in production | Information Disclosure | Compile or config gate the route to dev/test and add a test/source assertion. [VERIFIED: 114-CONTEXT.md] |
| Package API widening | Elevation of Privilege / Tampering | Keep route and helpers in demo host; do not modify `RulesteadAdmin.Router.rulestead_admin/2`. [VERIFIED: 114-CONTEXT.md] |
| Copied sensitive fixture values | Information Disclosure | Use synthetic long labels/keys/reasons and avoid real secrets or host tokens. [ASSUMED] |
| Policy bypass through matrix links | Elevation of Privilege | Use links to existing seeded demo flows; do not weaken admin policy modules. [VERIFIED: 114-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md` - locked implementation decisions D-01 through D-15.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-UI-MATRIX-CONTRACT.md` - state matrix, evidence dimensions, operator lenses, fixture-data needs.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md` - source-backed component taxonomy and evidence gaps.
- `.planning/REQUIREMENTS.md` - DSM-02 and v1.17 scope/out-of-scope constraints.
- `.planning/STATE.md` - milestone history and inherited evidence posture.
- `AGENTS.md` - project execution constraints.
- `examples/demo/backend/lib/rulestead_demo_web/router.ex` - existing demo route boundaries.
- `examples/demo/backend/lib/rulestead_demo_web/components/layouts/root.html.heex` - demo root layout loads app CSS, admin CSS, and LiveView JS.
- `rulestead_admin/lib/rulestead_admin/router.ex` - mounted admin route macro and route order.
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` - shell component contract and command palette markup.
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` - existing browser evidence loop and overflow assertion.
- `https://phoenix.hexdocs.pm/components.html` - Phoenix function component docs.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html` - LiveViewTest component and route testing docs.
- `https://playwright.dev/docs/api/class-browser` - Playwright context options for color scheme and reduced motion.
- `https://playwright.dev/docs/api/class-page` - Playwright screenshot API.
- `https://playwright.dev/docs/input` - Playwright keyboard and locator input APIs.

### Secondary (MEDIUM confidence)

- Local environment probes for Mix, Elixir, Node, npm, PostgreSQL, Docker, and Playwright version.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified locally from Mix deps and npm install; no new packages planned.
- Architecture: HIGH - locked by Phase 114 context and confirmed against demo router/admin router source.
- Pitfalls: HIGH - drawn from locked scope decisions, Phase 113 contract, and existing route/test patterns.

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 for repo-local architecture; re-check Playwright/Phoenix docs if package versions change.
