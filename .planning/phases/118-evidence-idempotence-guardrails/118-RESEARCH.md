# Phase 118: Evidence + Idempotence Guardrails - Research

**Researched:** 2026-06-14  
**Domain:** Playwright evidence, Phoenix LiveView source assertions, design-system drift guards, milestone closeout  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Evidence Bundle Shape

- **D-01:** Treat Phase 118 as the milestone evidence and idempotence capstone, not as a new UI polish or visual-regression infrastructure phase.
- **D-02:** Reuse the existing Playwright artifact pattern from `ui-matrix.spec.ts` and `admin-flow-ia.spec.ts`: screenshots are generated artifacts written through `testInfo.outputPath(...)`, not committed baselines or pixel-diff gates.
- **D-03:** Cover both proof surfaces required by VER-01: the repo-native UI matrix and the selected mounted-admin workflow routes handed off by Phase 117.
- **D-04:** Preserve the Phase 117 route sampling set for workflow evidence: overview, inventory, rules, kill, audience, audit, explain, and simulate.
- **D-05:** Include light, dark, system-dark, desktop, mobile, and reduced-motion evidence where those dimensions affect the surface. The reduced-motion case can stay targeted rather than multiplying every route by every motion mode.

### Deterministic Assertions

- **D-06:** Keep browser assertions DOM/behavior based: rendered `.rs-shell`, visible matrix sections or route evidence text, no page-level horizontal overflow, focus/keyboard behavior, key ARIA roles/regions, route ordering, and generated screenshot artifacts.
- **D-07:** Use Playwright for browser-only concerns and ExUnit/source assertions for component/source boundaries, fixture health, route exposure, forbidden tooling posture, and planning traceability.
- **D-08:** Keep selected contrast coverage in the existing static fixture and script layer. Do not turn Phase 118 into exhaustive runtime contrast auditing for every route pixel.
- **D-09:** Browser proof may use an isolated test-mode Phoenix backend and explicit `DEMO_BACKEND_URL` when local port or dev-database state makes the default backend unreliable. The exact command and environment should be recorded in the verification artifact.

### Guardrail Extension Policy

- **D-10:** Keep the current guard chain in `scripts/ci/lint.sh` as the normal durable drift gate: synced theme pairs, brand tokens, token CSS mirror, contrast, generated brandbook HTML, logo assets, admin foundations, package whitelist, and SVG budgets.
- **D-11:** Extend guard scripts only for concrete, repeatable design-system drift classes uncovered by v1.17 evidence. New guards should stay deterministic, stdlib-oriented where practical, and readable in CI output.
- **D-12:** Preserve existing source-posture guards against Storybook, PhoenixStorybook, `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, and checked-in pixel-baseline maintenance.

### Idempotence And Scope Boundaries

- **D-13:** Make reruns additive and safe. Generated Playwright screenshots and test output stay in test artifacts; committed source should be limited to durable tests, source guards, and planning/verification docs.
- **D-14:** Do not add product seed semantics, public routes, package metadata, release workflows, schemas, migrations, runtime APIs, FleetDesk rebranding, or `rulestead_admin` publish-prep work.
- **D-15:** Keep the demo-host UI matrix dev/test-only and outside `RulesteadAdmin.Router.rulestead_admin/2`. Phase 118 may assert that boundary; it should not move the route.
- **D-16:** Preserve the linked-version two-package release design. Phase 118 may document evidence for the sibling packages but must not publish or prepare to publish the `rulestead_admin` stub independently.

### Planning Traceability

- **D-17:** Produce a final Phase 118 verification or evidence artifact that maps VER-01 through VER-04 to proof commands, screenshot artifact patterns, guard outputs, intentional exceptions, and residual risks.
- **D-18:** Update planning truth only after evidence exists. Requirement completion should be recorded in `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and phase artifacts as appropriate during execution/verification, not guessed during planning.
- **D-19:** No external research is required before planning. The repo already contains the relevant Playwright, Phoenix, guard-chain, and planning-trace patterns for this capstone.

### Methodology

- **D-20:** Apply the project methodology lenses as recommendation-first defaults. The selected capstone shape does not change public API, security/governance posture, package boundary, release model, product scope, FleetDesk branding, or publish posture, so no additional high-impact user decision is required before planning.

### the agent's Discretion

The planner may choose the exact plan split and final artifact names, provided VER-01 through VER-04 receive explicit evidence coverage. Prefer compact evidence maps, source assertions, and command lists over broad new infrastructure. If a guard extension is not clearly preventing real drift, document the existing guard instead of adding a new one.

### Deferred Ideas (OUT OF SCOPE)

- Broad checked-in pixel baselines, Playwright visual snapshot assertions, pixelmatch/visual-diff tooling, and external AI visual judging remain out of scope.
- PhoenixStorybook or JavaScript Storybook remains deferred until a future maintainer-facing design-system docs need proves the repo-native matrix insufficient.
- Forced-colors/high-contrast OS mode remains `FUT-03`, not Phase 118 scope.
- v2 product wedges, public runtime APIs, schema/migration work, release workflow changes, package publishing, FleetDesk rebranding, and `rulestead_admin` standalone publish preparation remain out of scope.
- Further component polish, foundation redesign, route IA redesign, palette/logo changes, and product seed semantics are out of scope unless a future roadmap explicitly reopens them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VER-01 | Playwright captures UI matrix and admin workflow screenshots across light, dark, system-dark, desktop, mobile, and reduced-motion cases. | Reuse `ui-matrix.spec.ts` and `admin-flow-ia.spec.ts`; both already create screenshots under Playwright output paths for matrix/workflow surfaces. [VERIFIED: `examples/demo/frontend/tests/ui-matrix.spec.ts`; `examples/demo/frontend/tests/admin-flow-ia.spec.ts`] |
| VER-02 | Deterministic assertions cover horizontal overflow, focus visibility, key ARIA roles, keyboard flow, fixture load health, and selected contrast pairs. | Keep DOM assertions split between Playwright, static fixture contrast tests, and ExUnit fixture/source tests. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`; `design-system.spec.ts`; `ui_matrix_live_test.exs`] |
| VER-03 | Existing brand/token/logo/contrast/brandbook guard scripts remain green and are extended only where they prevent real design-system drift. | `scripts/ci/lint.sh` already chains synced-pair, brand-token, tokens mirror, contrast, brandbook, logo, foundation, package whitelist, and SVG budget guards. [VERIFIED: `scripts/ci/lint.sh`] |
| VER-04 | Planning docs record v1.17 decisions, verification evidence, requirement completion, and intentional exceptions before milestone closeout. | Use a final Phase 118 evidence/verification artifact and then update requirements, roadmap, and state only after commands run. [VERIFIED: `118-CONTEXT.md`; `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`] |
</phase_requirements>

## Summary

Phase 118 should be planned as a closeout and guardrail consolidation phase, not as new UI implementation. [VERIFIED: `118-CONTEXT.md`] The repo already contains the core evidence stack: Playwright browser specs for matrix and mounted workflow surfaces, static fixture contrast checks, Phoenix LiveViewTest/source assertions for fixture and route boundaries, and Python/Bash guard scripts wired through `scripts/ci/lint.sh`. [VERIFIED: repo inspection]

The primary planning move is to create a compact evidence map and possibly add narrow source/assertion coverage where VER-01 through VER-04 are not explicitly tied together yet. [VERIFIED: `118-CONTEXT.md`] Do not introduce Storybook, Playwright snapshot baselines, pixel-diff libraries, external AI visual review, new package installs, public routes, migrations, schemas, release workflow changes, or standalone `rulestead_admin` publish work. [VERIFIED: `118-CONTEXT.md`; `.planning/REQUIREMENTS.md`]

**Primary recommendation:** Plan one evidence consolidation wave and one closeout/docs wave; add code only when it makes existing Playwright/ExUnit/guard evidence more deterministic or traceable. [VERIFIED: `118-CONTEXT.md`; repo inspection]

## Project Constraints (from AGENTS.md)

- Rulestead is a sibling-package monorepo with `rulestead/` and `rulestead_admin/`. [VERIFIED: `AGENTS.md`]
- Agents must consult `.planning/` and `prompts/` as ground truth. [VERIFIED: `AGENTS.md`]
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: `AGENTS.md`]
- Keep Phase 8-only docs absent until the roadmap says they ship. [VERIFIED: `AGENTS.md`]
- Do not publish or prepare to publish the `rulestead_admin` stub. [VERIFIED: `AGENTS.md`]
- Keep edits aligned with the linked-version, two-package release design. [VERIFIED: `AGENTS.md`]
- Make the smallest coherent change, avoid speculative future-phase features, and preserve reproducibility/CI readability. [VERIFIED: `AGENTS.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| UI matrix screenshot evidence | Browser / Client | Frontend Server / Phoenix demo backend | Playwright owns browser media/theme/viewport proof while the Phoenix demo route renders real components. [VERIFIED: `ui-matrix.spec.ts`; `ui_matrix_live_test.exs`] |
| Mounted admin workflow evidence | Browser / Client | Frontend Server / LiveView | Playwright proves rendered workflow routes, keyboard, focus, overflow, roles, and screenshots against mounted admin paths. [VERIFIED: `admin-flow-ia.spec.ts`] |
| Fixture load health | Frontend Server / LiveView | Browser / Client | ExUnit proves deterministic fixtures and route boundaries; Playwright proves static fixture pages load in real browser contexts. [VERIFIED: `ui_matrix_live_test.exs`; `design-system.spec.ts`] |
| Selected contrast pairs | Static browser fixture/test layer | Guard scripts | The current selected contrast checks live in `design-system.spec.ts` and `scripts/check_contrast.py`, not per-route pixel analysis. [VERIFIED: `design-system.spec.ts`; `scripts/check_contrast.py`] |
| Design-system drift guards | CI / Scripts | Source tree | `scripts/ci/lint.sh` owns durable token/logo/brandbook/foundation/package/SVG drift checks. [VERIFIED: `scripts/ci/lint.sh`] |
| Milestone traceability | Planning docs | Verification artifacts | Requirement completion belongs in `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and phase evidence after proof exists. [VERIFIED: `118-CONTEXT.md`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@playwright/test` | Installed `1.60.0`; manifest allows `^1.56.1`; registry current `1.60.0`, modified 2026-06-14. | Browser evidence, screenshots, media/theme/viewport emulation, locators, keyboard assertions. | Existing repo test runner; official docs support `testInfo.outputPath`, context media options, and role locators. [VERIFIED: local package-lock + npm registry; CITED: https://playwright.dev/docs/api/class-testinfo; CITED: https://playwright.dev/docs/emulation; CITED: https://playwright.dev/docs/locators] |
| Phoenix LiveViewTest | Project dependency via backend/admin Mix apps; current official docs page reports Phoenix LiveView v1.2.1. | Fast route/source/fixture assertions without browser overhead. | Official docs describe LiveView tests as process communication in substitution of a browser and support connected/disconnected mount checks. [VERIFIED: local tests; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Python stdlib scripts | Python `3.14.4` available locally. | Deterministic token/logo/brandbook/foundation guard checks. | Existing guard chain is readable, deterministic, and already wired into CI lint. [VERIFIED: local environment; `scripts/ci/lint.sh`] |
| Bash guard spine | Bash via existing scripts. | Runs Mix checks and project guard scripts in one CI-readable sequence. | `scripts/ci/lint.sh` is the normal durable drift gate for Phase 118. [VERIFIED: `scripts/ci/lint.sh`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `next` | Installed `16.2.6`; registry current `16.2.9`, modified 2026-06-13. | Demo frontend server used by existing browser proof infrastructure. | Use only as already configured; Phase 118 should not upgrade or widen frontend dependencies. [VERIFIED: local package-lock + npm registry; `examples/demo/frontend/package.json`] |
| `typescript` | Installed and registry current `6.0.3`, modified 2026-04-16. | TypeScript Playwright specs and helper modules. | Use existing TS specs/helpers; no new TS build tooling needed. [VERIFIED: local package-lock + npm registry] |
| ExUnit / Mix | Elixir/Mix `1.19.5`, Erlang/OTP `28`. | Phoenix backend/admin source and LiveView tests. | Use for fixture health, route boundary, and source posture assertions. [VERIFIED: local environment; local tests] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generated Playwright artifacts | `toHaveScreenshot` / snapshot baselines | Rejected by locked decision; would introduce broad pixel-baseline maintenance. [VERIFIED: `118-CONTEXT.md`; CITED: https://playwright.dev/docs/api/class-testinfo] |
| Repo-native matrix | Storybook or PhoenixStorybook | Deferred; would duplicate LiveView component reality and create docs/tooling drift for this milestone. [VERIFIED: `118-CONTEXT.md`; `.planning/REQUIREMENTS.md`] |
| Static selected contrast checks | Exhaustive runtime per-route pixel contrast audit | Rejected by locked decision; selected contrast belongs in static fixture/script layer. [VERIFIED: `118-CONTEXT.md`; `design-system.spec.ts`] |

**Installation:**

```bash
# No new package installation recommended for Phase 118.
# Use existing dependencies from examples/demo/frontend/package-lock.json and existing Mix deps.
```

**Version verification:**

```bash
cd examples/demo/frontend && npm ls @playwright/test next typescript --depth=0
npm view @playwright/test version time.modified repository.url scripts.postinstall --json
npm view next version time.modified repository.url scripts.postinstall --json
npm view typescript version time.modified repository.url scripts.postinstall --json
```

## Package Legitimacy Audit

Phase 118 should not install external packages. [VERIFIED: `118-CONTEXT.md`] Slopcheck was not required because the recommended plan uses only existing repo dependencies and scripts. [VERIFIED: repo inspection]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@playwright/test` | npm | Existing locked dependency | Not needed for no-install phase | `github.com/microsoft/playwright` | Not run: no install recommended | Approved as existing project dependency. [VERIFIED: local package-lock + npm registry] |
| `next` | npm | Existing locked dependency | Not needed for no-install phase | `github.com/vercel/next.js` | Not run: no install recommended | Use only as existing demo frontend dependency. [VERIFIED: local package-lock + npm registry] |
| `typescript` | npm | Existing locked dependency | Not needed for no-install phase | `github.com/microsoft/TypeScript` | Not run: no install recommended | Use only as existing project dependency. [VERIFIED: local package-lock + npm registry] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no new packages recommended]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new packages recommended]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 118 proof command
  |
  +--> Phoenix demo backend / mounted admin routes
  |       |
  |       +--> /dev/rulestead-admin/ui-matrix
  |       |       -> real RulesteadAdmin.Components.* in demo-host shell
  |       |       -> deterministic UiMatrixFixtures
  |       |
  |       +--> /admin/flags... selected workflow routes
  |               -> overview/inventory/rules/kill/audience/audit/explain/simulate
  |
  +--> Playwright specs
  |       |
  |       +--> browser contexts: light, dark, system-dark, desktop, mobile, targeted reduced motion
  |       +--> DOM assertions: shell, roles, headings, route text, keyboard/focus, no overflow
  |       +--> screenshots via testInfo.outputPath(...) into test-results artifacts
  |
  +--> ExUnit/source assertions
  |       |
  |       +--> fixture health, real-component usage, dev/test-only matrix route
  |       +--> forbidden tooling posture
  |
  +--> Static/CI guard scripts
          |
          +--> token/logo/contrast/brandbook/foundation/package/SVG drift gates
          +--> final Phase 118 evidence map and planning closeout
```

### Recommended Project Structure

```text
.planning/phases/118-evidence-idempotence-guardrails/
├── 118-RESEARCH.md          # this file
├── 118-01-PLAN.md           # evidence consolidation plan
├── 118-02-PLAN.md           # closeout/docs plan if split
├── 118-EVIDENCE.md          # recommended compact evidence map
└── 118-VERIFICATION.md      # final verifier artifact after execution

examples/demo/frontend/tests/
├── ui-matrix.spec.ts        # extend only if VER-01/VER-02 traceability gap remains
├── admin-flow-ia.spec.ts    # extend only for selected workflow evidence gaps
└── design-system.spec.ts    # selected contrast/static fixture evidence

scripts/
├── check_*.py               # extend only for concrete design-system drift class
└── ci/lint.sh               # keep as durable guard-chain entry point
```

### Pattern 1: Generated Screenshots As Test Artifacts

**What:** Use `page.screenshot()` or locator screenshots with paths under `testInfo.outputPath(...)`. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`]  
**When to use:** Evidence screenshots for human review where deterministic DOM assertions are the merge gate. [VERIFIED: `118-CONTEXT.md`]  
**Example:**

```typescript
// Source: https://playwright.dev/docs/api/class-testinfo and existing ui-matrix.spec.ts
await page.screenshot({
  fullPage: true,
  path: testInfo.outputPath(`flow-${route.name}-${theme.name}-${viewport.name}.png`),
});
```

Official Playwright documents `testInfo.outputPath(...)` as a safe path inside the test output directory and notes it avoids interference for parallel tests. [CITED: https://playwright.dev/docs/api/class-testinfo]

### Pattern 2: Browser Media Matrix Via Context Options

**What:** Create explicit browser contexts with viewport, `colorScheme`, localStorage theme, and targeted `reducedMotion`. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`]  
**When to use:** Browser proof for light/dark/system-dark, desktop/mobile, and targeted reduced-motion behavior. [VERIFIED: `118-CONTEXT.md`]  
**Example:**

```typescript
// Source: https://playwright.dev/docs/emulation and existing ui-matrix.spec.ts
const context = await browser.newContext({
  colorScheme: theme.colorScheme,
  viewport: { width: viewport.width, height: viewport.height },
  reducedMotion: motion.reducedMotion,
});
```

Official Playwright docs support emulating `colorScheme` via configuration, `test.use`, `browser.newContext`, `browser.newPage`, and `page.emulateMedia`. [CITED: https://playwright.dev/docs/emulation]

### Pattern 3: Role-Based Assertions For Accessibility-Relevant Proof

**What:** Prefer `getByRole(...)`, visible headings/regions, and keyboard state assertions for browser-only accessibility behavior. [VERIFIED: `admin-flow-ia.spec.ts`]  
**When to use:** Key ARIA role/region, route heading, form, table, and navigation checks. [VERIFIED: `admin-flow-ia.spec.ts`]  
**Example:**

```typescript
// Source: https://playwright.dev/docs/locators and existing admin-flow-ia.spec.ts
await expect(page.getByRole("region", { name: "Emergency evidence" })).toBeVisible();
await page.getByRole("textbox", { name: "Reason" }).focus();
await expect(page.getByRole("textbox", { name: "Reason" })).toBeFocused();
```

Playwright locators support locating elements by implicit accessibility role and accessible name. [CITED: https://playwright.dev/docs/locators]

### Pattern 4: ExUnit For Fixture And Boundary Truth

**What:** Use Phoenix LiveViewTest/source assertions to prove matrix route existence, fixture health, route examples, real component usage, and forbidden source posture. [VERIFIED: `ui_matrix_live_test.exs`]  
**When to use:** Anything that does not require a real browser: fixture values, router boundaries, source marker presence, and no forbidden tooling strings. [VERIFIED: `ui_matrix_live_test.exs`]  
**Example:**

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html and existing ui_matrix_live_test.exs
{:ok, view, html} = live(conn, @matrix_path)
rendered = html <> render(view)

assert rendered =~ "rs-shell"
refute admin_router_source =~ "ui-matrix"
```

Phoenix LiveViewTest docs state LiveView tests interact with views through process communication in substitution of a browser. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Anti-Patterns to Avoid

- **Pixel-baseline expansion:** Do not add `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, or checked-in screenshot baselines. [VERIFIED: `118-CONTEXT.md`; `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`]
- **New documentation surface:** Do not add Storybook or PhoenixStorybook for this milestone. [VERIFIED: `118-CONTEXT.md`; `.planning/REQUIREMENTS.md`]
- **Route/package/schema widening:** Do not move the UI matrix into `RulesteadAdmin.Router.rulestead_admin/2`, publish `rulestead_admin`, alter package metadata, or add migrations/schemas/runtime APIs. [VERIFIED: `118-CONTEXT.md`; `ui_matrix_live_test.exs`]
- **Exhaustive runtime contrast audit:** Do not convert selected contrast checks into per-route pixel inspection. [VERIFIED: `118-CONTEXT.md`; `design-system.spec.ts`]
- **Guard sprawl:** Do not add a guard unless it prevents a concrete repeatable design-system drift class. [VERIFIED: `118-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser automation and screenshots | Custom Puppeteer-like runner or shell screenshot script | Existing Playwright specs | Existing stack already handles contexts, locators, screenshots, and test output paths. [VERIFIED: local tests; CITED: https://playwright.dev/docs/api/class-testinfo] |
| Visual regression diffing | Pixelmatch/custom image compare | Generated screenshot artifacts plus deterministic DOM assertions | Locked evidence posture rejects broad pixel-baseline maintenance. [VERIFIED: `118-CONTEXT.md`] |
| Accessible role discovery | Manual CSS selector-only checks for semantic elements | Playwright `getByRole` / `getByText` / role locators | Official Playwright locator docs support role/name-based checks. [CITED: https://playwright.dev/docs/locators] |
| Fixture health | Browser-only probing of all fixture internals | ExUnit and source assertions | Existing LiveViewTest file verifies deterministic fixture data faster than browser tests. [VERIFIED: `ui_matrix_live_test.exs`] |
| Token/logo/brandbook drift | New Node build or generator layer | Existing Python guard scripts and `scripts/ci/lint.sh` | The repo already has deterministic stdlib-oriented guards. [VERIFIED: `scripts/ci/lint.sh`] |

**Key insight:** Phase 118 is about making the existing proof spine legible and rerunnable; custom infrastructure would increase maintenance without satisfying a locked requirement. [VERIFIED: `118-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Treating Screenshot Evidence As Snapshot Testing

**What goes wrong:** A plan adds `toHaveScreenshot`, `matchSnapshot`, pixelmatch, or checked-in baseline images. [VERIFIED: `118-CONTEXT.md`]  
**Why it happens:** Playwright supports snapshot assertions, but Phase 118 explicitly chose generated artifacts plus deterministic assertions. [CITED: https://playwright.dev/docs/api/class-testinfo; VERIFIED: `118-CONTEXT.md`]  
**How to avoid:** Use `testInfo.outputPath(...)` and source guards that reject snapshot/baseline tooling. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`]  
**Warning signs:** New `*-snapshots/`, `toHaveScreenshot`, `matchSnapshot`, image diff dependencies, or committed PNG baselines. [VERIFIED: repo scans]

### Pitfall 2: Multiplying Every Route By Reduced Motion

**What goes wrong:** The matrix explodes into route x theme x viewport x motion combinations and slows/fragilizes evidence. [VERIFIED: `118-CONTEXT.md`]  
**Why it happens:** VER-01 names reduced motion, but D-05 allows targeted reduced-motion evidence where motion affects the surface. [VERIFIED: `118-CONTEXT.md`]  
**How to avoid:** Keep broad theme/viewport coverage and one targeted reduced-motion behavior such as neutralized task-link transforms. [VERIFIED: `ui-matrix.spec.ts`]

### Pitfall 3: Hiding Backend Port Assumptions

**What goes wrong:** Browser proof fails or becomes non-reproducible because the backend port differs from the default. [VERIFIED: `118-CONTEXT.md`; `tests/support/admin.ts`]  
**Why it happens:** Specs default to `http://localhost:4000` but Phase 117 used explicit `DEMO_BACKEND_URL=http://localhost:4061`. [VERIFIED: `tests/support/admin.ts`; `117-VERIFICATION.md`]  
**How to avoid:** Plan commands with explicit `DEMO_BACKEND_URL` and record backend startup/port in evidence docs. [VERIFIED: `118-CONTEXT.md`]

### Pitfall 4: Guard Extensions Without Drift Class

**What goes wrong:** The phase adds broad or noisy guards that fail unrelated work. [VERIFIED: `118-CONTEXT.md`]  
**Why it happens:** VER-03 says guards may be extended, but D-11 limits extension to concrete repeatable drift classes. [VERIFIED: `118-CONTEXT.md`]  
**How to avoid:** Default to documenting current guards; add a guard only when a v1.17 evidence gap proves a repeatable failure mode. [VERIFIED: `118-CONTEXT.md`; `scripts/ci/lint.sh`]

### Pitfall 5: Updating Planning Truth Before Evidence Exists

**What goes wrong:** Requirements are marked complete before proof commands run. [VERIFIED: `118-CONTEXT.md`]  
**Why it happens:** Phase closeout touches docs, but D-18 says completion should follow evidence. [VERIFIED: `118-CONTEXT.md`]  
**How to avoid:** Plan docs update tasks after test/guard tasks, and require command output in `118-VERIFICATION.md` before changing requirement checkboxes. [VERIFIED: `118-CONTEXT.md`]

## Code Examples

### No Horizontal Overflow Assertion

```typescript
// Source: existing ui-matrix.spec.ts and admin-flow-ia.spec.ts
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

This pattern is already shared by the matrix and flow specs and directly supports VER-02. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`]

### Targeted Reduced Motion

```typescript
// Source: existing ui-matrix.spec.ts
const taskLink = page.locator(".rs-task-link").first();
await expect(taskLink).toBeVisible();
await taskLink.hover();
const transform = await taskLink.evaluate((element) =>
  window.getComputedStyle(element).transform,
);
expect(transform).toBe("none");
```

This is the right shape for reduced-motion proof because it asserts behavior instead of multiplying every route. [VERIFIED: `ui-matrix.spec.ts`; `118-CONTEXT.md`]

### Fixture Boundary Check

```elixir
# Source: existing ui_matrix_live_test.exs
router_source = read_source("lib/rulestead_demo_web/router.ex")
admin_router_source = read_repo_source("rulestead_admin/lib/rulestead_admin/router.ex")

assert router_source =~ ~s(scope "/dev/rulestead-admin", RulesteadDemoWeb do)
refute admin_router_source =~ "ui-matrix"
```

This supports D-15 by proving the matrix remains demo-hosted and outside the public admin router. [VERIFIED: `ui_matrix_live_test.exs`; `118-CONTEXT.md`]

### Evidence Map Row Shape

```markdown
| Requirement | Surface | Assertion Type | Command | Artifact Pattern | Status | Intentional Exception |
|-------------|---------|----------------|---------|------------------|--------|-----------------------|
| VER-01 | UI matrix overview shell | Playwright screenshot artifact | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:<port> npm run test:e2e -- ui-matrix.spec.ts` | `ui-matrix-overview-shell-${theme}-${viewport}-${motion}.png` | pending until run | Screenshots are generated artifacts, not baselines. |
```

This row shape matches the Phase 118 context recommendation for compact evidence maps. [VERIFIED: `118-CONTEXT.md`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad checked-in visual baselines for UI proof | Generated Playwright screenshots plus DOM/source assertions | Locked across v1.17 context and prior phases | Keeps visual evidence useful without pixel-maintenance burden. [VERIFIED: `STATE.md`; `118-CONTEXT.md`] |
| Component-docs-first design-system proof | Repo-native Phoenix matrix rendering real admin components | Phase 114 | Avoids Storybook duplication and proves actual LiveView component output. [VERIFIED: `114-CONTEXT.md`; `ui_matrix_live_test.exs`] |
| Browser-only verification of all behavior | Split browser-only concerns to Playwright and source/fixture boundaries to ExUnit/scripts | Phases 114-117 | Keeps deterministic checks fast and focused. [VERIFIED: `117-VERIFICATION.md`; repo tests] |

**Deprecated/outdated:**

- `toHaveScreenshot` / `matchSnapshot` / pixelmatch for this milestone: explicitly out of scope for Phase 118. [VERIFIED: `118-CONTEXT.md`]
- Storybook/PhoenixStorybook adoption for this milestone: deferred until a future maintainer-facing docs need proves the repo-native matrix insufficient. [VERIFIED: `118-CONTEXT.md`; `.planning/REQUIREMENTS.md`]
- External AI visual review: deferred future requirement, not a Phase 118 dependency. [VERIFIED: `.planning/REQUIREMENTS.md`; `118-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Browser artifacts will land under Playwright's default `test-results` tree when using `testInfo.outputPath(...)`. [ASSUMED] | Architecture Patterns / Validation Architecture | If local reporter/output settings differ, evidence docs must record the actual artifact path from the run. |

## Open Questions

1. **Should Phase 118 create both `118-EVIDENCE.md` and `118-VERIFICATION.md`, or only one combined artifact?**
   - What we know: D-17 requires a final Phase 118 verification or evidence artifact mapping requirements to commands, artifacts, guard outputs, exceptions, and risks. [VERIFIED: `118-CONTEXT.md`]
   - What's unclear: The exact artifact split is left to planner discretion. [VERIFIED: `118-CONTEXT.md`]
   - Recommendation: Use `118-EVIDENCE.md` during execution and `118-VERIFICATION.md` for final verifier truth if the plan has two waves; use one `118-VERIFICATION.md` if the phase stays compact. [ASSUMED]

2. **Which backend port should execution use for browser proof?**
   - What we know: Specs default to `http://localhost:4000`, but Phase 117 evidence used `DEMO_BACKEND_URL=http://localhost:4061`. [VERIFIED: `tests/support/admin.ts`; `117-VERIFICATION.md`]
   - What's unclear: The execution-time free port is environment-specific. [VERIFIED: local environment]
   - Recommendation: Planner should include a backend startup step that records the chosen port and passes it through `DEMO_BACKEND_URL`. [VERIFIED: `118-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Playwright/frontend specs | yes | `v22.14.0` | None needed. [VERIFIED: local environment] |
| npm | Frontend test scripts and registry verification | yes | `11.1.0` | None needed. [VERIFIED: local environment] |
| Elixir | ExUnit/Phoenix backend/admin tests | yes | `1.19.5` with Erlang/OTP `28` | None needed. [VERIFIED: local environment] |
| Mix | ExUnit/Phoenix commands | yes | `1.19.5` | None needed. [VERIFIED: local environment] |
| Python 3 | Guard scripts | yes | `3.14.4` | None needed. [VERIFIED: local environment] |
| Context7 CLI (`ctx7`) | Optional docs lookup | no | unavailable | Official web docs were used instead. [VERIFIED: local environment; CITED: Playwright/Phoenix docs URLs] |

**Missing dependencies with no fallback:**
- None found for planning. [VERIFIED: local environment]

**Missing dependencies with fallback:**
- `ctx7` is absent; official web documentation was used as the fallback. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Playwright Test `1.60.0`, ExUnit/Mix `1.19.5`, Python guard scripts. [VERIFIED: local package-lock + local environment] |
| Config file | `examples/demo/frontend/playwright.config.ts`; Mix project configs under `rulestead/`, `rulestead_admin/`, and `examples/demo/backend`. [VERIFIED: repo inspection] |
| Quick run command | `python3 scripts/check_admin_foundations.py && cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` [VERIFIED: `118-CONTEXT.md`; local files] |
| Browser matrix command | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:<port> npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts` [VERIFIED: `118-CONTEXT.md`; `117-VERIFICATION.md`] |
| Static fixture command | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` [VERIFIED: `117-VERIFICATION.md`] |
| Full guard command | `bash scripts/ci/lint.sh` when practical. [VERIFIED: `scripts/ci/lint.sh`; `118-CONTEXT.md`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VER-01 | Matrix and workflow screenshots across theme/viewport/system-dark/reduced-motion evidence. | e2e/browser | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:<port> npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts` | yes. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`] |
| VER-02 | Overflow, focus, roles, keyboard, fixture health, selected contrast pairs. | browser + unit/source | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts design-system.spec.ts` plus `cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes. [VERIFIED: local files] |
| VER-03 | Brand/token/logo/contrast/brandbook/foundation guards green; extensions only for concrete drift. | script/CI | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_contrast.py && python3 scripts/check_brandbook_html.py && python3 scripts/check_logo_assets.py && python3 scripts/check_admin_foundations.py` | yes. [VERIFIED: scripts] |
| VER-04 | Planning docs record decisions, evidence, completion, and exceptions. | source/doc assertion | `rg -n "VER-01|VER-02|VER-03|VER-04|intentional exception|artifact|118" .planning/phases/118-evidence-idempotence-guardrails .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` | Wave 0 gap for final artifacts. [VERIFIED: current phase dir] |

### Sampling Rate

- **Per task commit:** Run the narrow command for touched tier: Playwright spec for browser changes, ExUnit for fixture/source changes, or the specific `scripts/check_*.py` guard for script/docs changes. [VERIFIED: repo patterns]
- **Per wave merge:** Run the browser matrix/workflow command and static fixture command with explicit `DEMO_BACKEND_URL`. [VERIFIED: `118-CONTEXT.md`; `117-VERIFICATION.md`]
- **Phase gate:** Run final selected Playwright/ExUnit/static fixture checks, relevant guard-chain scripts or `bash scripts/ci/lint.sh`, `git diff --check`, and source scans for forbidden tooling. [VERIFIED: `118-CONTEXT.md`; `117-VERIFICATION.md`]

### Wave 0 Gaps

- [ ] `.planning/phases/118-evidence-idempotence-guardrails/118-EVIDENCE.md` or `.planning/phases/118-evidence-idempotence-guardrails/118-VERIFICATION.md` — maps VER-01 through VER-04 to commands, artifacts, guard outputs, exceptions, and risks. [VERIFIED: `118-CONTEXT.md`]
- [ ] Optional source/doc assertion in an existing or new focused test if planner wants automated VER-04 traceability before final closeout. [ASSUMED]
- [ ] Browser backend startup command/port capture for execution evidence. [VERIFIED: `118-CONTEXT.md`; `tests/support/admin.ts`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes, indirectly | Browser specs sign in through `/demo/sign-in`; Phase 118 should not change auth. [VERIFIED: `ui-matrix.spec.ts`; `admin-flow-ia.spec.ts`; `118-CONTEXT.md`] |
| V3 Session Management | yes, indirectly | Preserve existing mounted-admin session behavior; do not add session APIs. [VERIFIED: `118-CONTEXT.md`] |
| V4 Access Control | yes, indirectly | Keep matrix dev/test-only and outside `RulesteadAdmin.Router.rulestead_admin/2`. [VERIFIED: `ui_matrix_live_test.exs`; `118-CONTEXT.md`] |
| V5 Input Validation | limited | No new runtime inputs planned; existing route forms are only asserted for evidence. [VERIFIED: `118-CONTEXT.md`; `admin-flow-ia.spec.ts`] |
| V6 Cryptography | no | Phase 118 does not introduce crypto, secrets, or signing. [VERIFIED: `118-CONTEXT.md`] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental public exposure of demo matrix route | Information Disclosure | ExUnit/source assertion that `/dev/rulestead-admin/ui-matrix` remains demo-hosted and absent from `RulesteadAdmin.Router.rulestead_admin/2`. [VERIFIED: `ui_matrix_live_test.exs`] |
| Evidence overclaim without reproducible commands | Repudiation | Final evidence artifact must record commands, environment, generated artifact patterns, guard outputs, and exceptions. [VERIFIED: `118-CONTEXT.md`] |
| Fixture data becoming runtime seed/product semantics | Tampering | Keep `UiMatrixFixtures` deterministic and source/assertion-backed; do not add DB/network/seed reads. [VERIFIED: `ui_matrix_live_test.exs`; `118-CONTEXT.md`] |
| Visual review dependency changing release posture | Denial of Service | Keep screenshots as artifacts and avoid external AI/pixel-baseline gates. [VERIFIED: `118-CONTEXT.md`; `.planning/REQUIREMENTS.md`] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` — project constraints, phase boundary, linked-version sibling-package posture. [VERIFIED: local file]
- `.planning/phases/118-evidence-idempotence-guardrails/118-CONTEXT.md` — locked Phase 118 decisions and boundaries. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — requirements, phase goal, current state. [VERIFIED: local files]
- `examples/demo/frontend/tests/ui-matrix.spec.ts` — matrix evidence patterns. [VERIFIED: local file]
- `examples/demo/frontend/tests/admin-flow-ia.spec.ts` — workflow evidence patterns. [VERIFIED: local file]
- `examples/demo/frontend/tests/design-system.spec.ts` and `tests/support/contrast-check.ts` — static fixture and selected contrast checks. [VERIFIED: local files]
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` — LiveView fixture/source/boundary checks. [VERIFIED: local file]
- `scripts/ci/lint.sh` and `scripts/check_*.py` — guard-chain entry points. [VERIFIED: local files]
- Playwright TestInfo docs — `testInfo.outputPath`, attachments, snapshot path distinction. [CITED: https://playwright.dev/docs/api/class-testinfo]
- Playwright emulation docs — `colorScheme` browser context/media emulation. [CITED: https://playwright.dev/docs/emulation]
- Playwright locators docs — role/text locator patterns. [CITED: https://playwright.dev/docs/locators]
- Phoenix LiveViewTest docs — LiveView testing lifecycle and browser-substitute process communication. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Secondary (MEDIUM confidence)

- npm registry metadata for `@playwright/test`, `next`, and `typescript` current versions and repositories. [VERIFIED: npm registry]
- `prompts/rulestead-testing-and-e2e-strategy.md`, `prompts/rulestead-admin-ux-and-operator-ia.md`, and `prompts/phoenix-live-view-best-practices-deep-research.md` — project anchor guidance on curated browser evidence and LiveView testing. [VERIFIED: local files]

### Tertiary (LOW confidence)

- None used as deciding evidence. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing dependencies, lockfile, local environment, npm registry, and official docs agree. [VERIFIED: local package-lock + npm registry + official docs]
- Architecture: HIGH — Phase 118 context and prior Phase 117 handoff directly name proof surfaces, route set, artifact patterns, and guard boundaries. [VERIFIED: `118-CONTEXT.md`; `117-FLOW-IA-REVIEW.md`]
- Pitfalls: HIGH — pitfalls are locked out by context and reinforced by existing source guards. [VERIFIED: `118-CONTEXT.md`; repo scans]

**Research date:** 2026-06-14  
**Valid until:** 2026-07-14 for repo-local architecture; 2026-06-21 for npm/browser-tool version assumptions. [ASSUMED]
