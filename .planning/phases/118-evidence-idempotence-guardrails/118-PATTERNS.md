# Phase 118: Evidence + Idempotence Guardrails - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 10 planned or likely new/modified files
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/118-evidence-idempotence-guardrails/118-EVIDENCE.md` | documentation | batch | `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` | exact |
| `.planning/phases/118-evidence-idempotence-guardrails/118-VERIFICATION.md` | documentation | batch | `.planning/phases/117-page-flow-ia-pass/117-VERIFICATION.md` | exact |
| `examples/demo/frontend/tests/ui-matrix.spec.ts` | test | request-response | same file | exact |
| `examples/demo/frontend/tests/admin-flow-ia.spec.ts` | test | request-response | same file | exact |
| `examples/demo/frontend/tests/design-system.spec.ts` | test | transform | same file | exact |
| `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` | test | request-response | same file | exact |
| `scripts/check_admin_foundations.py` or new `scripts/check_*.py` | utility / guard | file-I/O | `scripts/check_admin_foundations.py` | role-match |
| `scripts/ci/lint.sh` | config / CI guard | batch | same file | exact |
| `.planning/REQUIREMENTS.md` | documentation | batch | same file | exact |
| `.planning/ROADMAP.md` and `.planning/STATE.md` | documentation | batch | same files | exact |

## Pattern Assignments

### `.planning/phases/118-evidence-idempotence-guardrails/118-EVIDENCE.md` (documentation, batch)

**Analog:** `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md`

**Scope guardrail pattern** (lines 3-15):
```markdown
- FLOW-03 records browser proof for keyboard, focus, mobile containment, narrow viewport behavior, route order, and generated screenshot artifacts.
- FLOW-04 keeps the deterministic matrix fixture layer broad enough for happy, error, boundary, and rare examples without changing product seed semantics.
- D-07, D-08, D-09, and D-18 define the evidence posture: deterministic assertions plus generated screenshots, no Storybook, PhoenixStorybook, checked-in pixel baselines, public route widening, schema changes, release changes, package changes, or broad seed semantics.
```

**Evidence table pattern** (lines 25-36):
```markdown
| Operator job | Route cluster | Route / surface | Path evidence | State coverage | Finding | Action | Proof | Follow-on |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Stop unsafe serving | Build & release | Kill-switch runbook, typed confirmation, reason, diagnostics, audit handoff | `/admin/flags/enable-new-dashboard/kill?env=staging` | destructive, permission-denied, unavailable, read-only, error, boundary via mutation-confirm and rare-state fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-03 sequenced current state, emergency evidence, destructive form, and after-action context without weakening confirmation, diagnostics, or audit links. | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/kill_test.exs test/rulestead_admin/live/flag_live/accessibility_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample kill screenshots and keyboard flow because this is the destructive route. |
```

**Phase handoff / artifact naming pattern** (lines 77-88):
```markdown
- Route coverage for Phase 118 sampling: overview, inventory, rules, kill, audience, audit, explain, and simulate.
- Screenshot artifact naming pattern: `flow-${route}-${theme}-${viewport}.png`, where route is one of `overview`, `inventory`, `rules`, `kill`, `audience`, `audit`, `explain`, or `simulate`; theme is `light`, `dark`, or `system-dark`; viewport is `desktop` or `mobile`.
- Intentional exceptions: no new public route, no schema or migration, no release workflow change, no package install, no standalone admin publish preparation, no checked-in visual baseline, no Storybook or PhoenixStorybook, no external AI visual review, no FleetDesk rebranding, no package publishing, and no product seed semantics.
```

**Use for 118:** Build a compact VER-01 through VER-04 evidence map with columns for requirement, surface, assertion type, command, artifact pattern, status, intentional exception, and residual risk. Preserve the Phase 117 route sample set and add the UI matrix surface rows from `ui-matrix.spec.ts`.

---

### `.planning/phases/118-evidence-idempotence-guardrails/118-VERIFICATION.md` (documentation, batch)

**Analog:** `.planning/phases/117-page-flow-ia-pass/117-VERIFICATION.md`

**Frontmatter and status pattern** (lines 1-11):
```markdown
---
phase: 117-page-flow-ia-pass
phase_number: 117
verified_at: 2026-06-14T21:16:55Z
status: passed
score: 4/4 must-haves verified
requirements: [FLOW-01, FLOW-02, FLOW-03, FLOW-04]
plans_complete: 4/4
review_status: clean
human_verification: []
---
```

**Observable truths pattern** (lines 25-34):
```markdown
| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 3 | Keyboard flow, focus order, mobile layout, and narrow viewport behavior remain usable across primary route clusters. | VERIFIED | `admin-flow-ia.spec.ts` loops route screenshots across light/dark/system-dark and desktop/mobile, checks no horizontal overflow, verifies command palette options, and tabs through kill-switch controls without focusing hidden palette controls. |
```

**Automated checks pattern** (lines 72-85):
```markdown
| Command | Result | Status |
| --- | --- | --- |
| `cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | 6 tests, 0 failures | PASS |
| `python3 scripts/check_admin_foundations.py` | `ADMIN FOUNDATIONS OK` | PASS |
| `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | 55 passed | PASS |
| `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- ui-matrix.spec.ts` | 15 passed | PASS |
| `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | 29 passed | PASS |
```

**Boundary and residual risk pattern** (lines 88-118):
```markdown
Playwright screenshots are generated artifacts, not checked-in visual baselines. `admin-flow-ia.spec.ts` writes screenshots with `testInfo.outputPath("flow-${route}-${theme}-${viewport}.png")` for each selected route, theme, and viewport.

| Boundary | Verdict | Evidence |
| --- | --- | --- |
| No Storybook or pixel baseline | PASS | Evidence files use generated screenshots only; forbidden-source guard terms appear only in guard/test assertions, not tooling adoption. |
```

**Use for 118:** Record actual commands, backend port, screenshot artifact patterns, guard outputs, exceptions, and residual risks after evidence exists. Update `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` only after this artifact has command evidence.

---

### `examples/demo/frontend/tests/ui-matrix.spec.ts` (test, request-response)

**Analog:** same file

**Imports and case-shape pattern** (lines 1-24):
```typescript
import { expect, test, type Browser, type Page } from "@playwright/test";
import fs from "fs";
import path from "path";

import { backendUrl } from "./support/admin";

type ViewportCase = {
  name: "desktop" | "mobile";
  width: number;
  height: number;
};

type ThemeCase = {
  name: "light" | "dark" | "system-dark";
  colorScheme: "light" | "dark";
  storedTheme: "light" | "dark" | null;
};
```

**Theme / viewport / reduced-motion matrix pattern** (lines 26-45 and 111-120):
```typescript
const viewports: ViewportCase[] = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const themes: ThemeCase[] = [
  { name: "light", colorScheme: "light", storedTheme: "light" },
  { name: "dark", colorScheme: "light", storedTheme: "dark" },
  { name: "system-dark", colorScheme: "dark", storedTheme: null },
];

const browserCases = [
  ...viewports.flatMap((viewport) =>
    themes.map((theme) => ({ viewport, theme, motion: standardMotion })),
  ),
  {
    viewport: viewports[0],
    theme: themes[0],
    motion: reducedMotion,
  },
];
```

**Open/sign-in/error-cleanup pattern** (lines 122-155):
```typescript
async function openMatrixSurface(
  browser: Browser,
  viewport: ViewportCase,
  theme: ThemeCase,
  motion: MotionCase,
) {
  const context = await browser.newContext({
    colorScheme: theme.colorScheme,
    viewport: { width: viewport.width, height: viewport.height },
    reducedMotion: motion.reducedMotion,
  });

  try {
    const page = await context.newPage();

    await page.goto(`${backendUrl}/demo/sign-in`);
    await page.waitForURL(/\/admin\/flags/);
    await page.evaluate((storedTheme) => {
      if (storedTheme) {
        localStorage.setItem("rulestead_admin.theme", storedTheme);
      } else {
        localStorage.removeItem("rulestead_admin.theme");
      }
    }, theme.storedTheme);

    await page.goto(`${backendUrl}${matrixPath}`);
    await expect(page.locator(".rs-shell")).toBeVisible();

    return { context, page };
  } catch (error) {
    await context.close();
    throw error;
  }
}
```

**No-overflow and screenshot artifact pattern** (lines 157-164 and 187-194):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

await page
  .locator(`[data-matrix-section="${sectionName}"]`)
  .screenshot({
    path: testInfo.outputPath(
      `ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png`,
    ),
  });
```

**Reduced-motion and source-posture pattern** (lines 237-260 and 401-410):
```typescript
const taskLink = page.locator(".rs-task-link").first();

await expect(taskLink).toBeVisible();
await taskLink.hover();

const transform = await taskLink.evaluate((element) =>
  window.getComputedStyle(element).transform,
);

expect(transform).toBe("none");

for (const term of forbiddenSourceTerms) {
  expect(source.includes(term)).toBe(false);
}
```

**Use for 118:** Extend only if VER-01 or VER-02 needs explicit traceability gaps filled. Keep screenshots under `testInfo.outputPath(...)`; do not add snapshot assertions or committed baselines. Target reduced motion instead of multiplying every route by motion mode.

---

### `examples/demo/frontend/tests/admin-flow-ia.spec.ts` (test, request-response)

**Analog:** same file

**Route set pattern** (lines 45-94):
```typescript
const adminFlowRoutes: AdminFlowRoute[] = [
  {
    name: "overview",
    path: "/admin/flags",
    heading: /What's happening in Staging/,
    evidence: "Needs you now",
  },
  {
    name: "kill",
    path: "/admin/flags/enable-new-dashboard/kill?env=staging",
    heading: "enable-new-dashboard kill switch",
    evidence: "Emergency evidence",
  },
  {
    name: "simulate",
    path: "/admin/flags/enable-new-dashboard/simulate?env=staging",
    heading: "enable-new-dashboard simulation",
    evidence: "Simulation",
  },
];
```

**Admin route open pattern** (lines 106-138):
```typescript
async function openAdminSurface(
  browser: Browser,
  viewport: ViewportCase,
  theme: ThemeCase,
  path: string,
) {
  const context = await browser.newContext({
    colorScheme: theme.colorScheme,
    viewport: { width: viewport.width, height: viewport.height },
  });

  try {
    const page = await context.newPage();

    await page.goto(`${backendUrl}/demo/sign-in`);
    await page.waitForURL(/\/admin\/flags/);
    await page.evaluate((storedTheme) => {
      if (storedTheme) {
        localStorage.setItem("rulestead_admin.theme", storedTheme);
      } else {
        localStorage.removeItem("rulestead_admin.theme");
      }
    }, theme.storedTheme);

    await page.goto(`${backendUrl}${path}`);
    await expect(page.locator(".rs-shell")).toBeVisible();

    return { context, page };
  } catch (error) {
    await context.close();
    throw error;
  }
}
```

**Full route/theme/viewport screenshot pattern** (lines 149-195):
```typescript
for (const viewport of viewports) {
  for (const theme of themes) {
    for (const route of adminFlowRoutes) {
      test(`route ${route.name} renders shell evidence: ${theme.name} / ${viewport.name}`, async ({
        browser,
      }, testInfo) => {
        const { context, page } = await openAdminSurface(
          browser,
          viewport,
          theme,
          route.path,
        );

        try {
          await expect(
            page.getByRole("heading", { name: route.heading }).first(),
          ).toBeVisible();
          await expect(page.getByText(route.evidence).first()).toBeVisible();
          await expectNoHorizontalOverflow(page);

          await page.screenshot({
            fullPage: true,
            path: testInfo.outputPath(
              `flow-${route.name}-${theme.name}-${viewport.name}.png`,
            ),
          });
        } finally {
          await context.close();
        }
      });
    }
  }
}
```

**Keyboard/focus pattern** (lines 310-354 and 461-462):
```typescript
for (let index = 0; index < 16; index += 1) {
  await page.keyboard.press("Tab");
  const focused = await page.evaluate(() => {
    const active = document.activeElement;

    if (!(active instanceof HTMLElement)) {
      return {
        insideBody: false,
        hiddenPaletteControl: false,
      };
    }

    return {
      insideBody: document.body.contains(active),
      hiddenPaletteControl: Boolean(active.closest("#rs-cmdk[hidden]")),
    };
  });

  expect(focused.insideBody).toBe(true);
  expect(focused.hiddenPaletteControl).toBe(false);
  await expectNoHorizontalOverflow(page);
}

await killPage.getByRole("textbox", { name: "Reason" }).focus();
await expect(killPage.getByRole("textbox", { name: "Reason" })).toBeFocused();
```

**Use for 118:** Preserve the eight-route set: overview, inventory, rules, kill, audience, audit, explain, and simulate. For VER-02, copy existing role locators, ordering checks, keyboard loop, focus assertion, and no-overflow helper rather than using CSS-only assertions.

---

### `examples/demo/frontend/tests/design-system.spec.ts` (test, transform)

**Analog:** same file

**Static literal contrast guard pattern** (lines 1-18 and 47-60):
```typescript
/**
 * These assertions use LITERAL hex values extracted from rulestead_admin.css
 * at Phase 91. If a future phase changes a token value, this spec FAILS —
 * that is the intended behavior. To update: change both the token value AND
 * the corresponding hex literal here.
 *
 * Do NOT use computed styles (getComputedStyle / getPropertyValue) in this
 * spec — static literals are the gate.
 */

test("light: text on surface passes AA", () => {
  assertAABatch([
    { label: "--rs-text on --rs-surface", fg: "#1a2332", bg: "#ffffff" },
    { label: "--rs-text-muted on --rs-surface", fg: "#5c6b7a", bg: "#ffffff" },
  ]);
});
```

**Known exception pattern** (lines 99-111):
```typescript
test("light: text placeholder ratio is documented (known sub-AA exception)", () => {
  const ratio = wcagRatio("#99a3af", "#ffffff");
  if (ratio < 2.4) {
    throw new Error(
      `--rs-text-placeholder on --rs-surface ratio regressed below 2.4:1: got ${ratio.toFixed(2)}`,
    );
  }
});
```

**Static fixture load pattern** (lines 193-210):
```typescript
test("design-system.html loads in both themes", async ({ browser }) => {
  const ctx = await browser.newContext({ colorScheme: "light" });
  const page = await ctx.newPage();
  await page.goto(dsUrl);
  await expect(page.locator(".rs-shell")).toBeVisible();
  await ctx.close();

  const ctx2 = await browser.newContext({ colorScheme: "dark" });
  const page2 = await ctx2.newPage();
  await page2.goto(dsUrl);
  await page2.evaluate(() =>
    (window as unknown as { setTheme: (t: string) => void }).setTheme("dark"),
  );
  await expect(page2.locator(".rs-shell")).toBeVisible();
  await ctx2.close();
});
```

**Use for 118:** Keep selected contrast coverage here and in `scripts/check_contrast.py`. Do not move to per-route pixel analysis. If VER-02 needs wording, document this as selected contrast evidence rather than expanding runtime checks.

---

### `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` (test, request-response)

**Analog:** same file

**LiveViewTest setup and matrix markers pattern** (lines 1-23 and 72-108):
```elixir
defmodule RulesteadDemoWeb.UiMatrixLiveTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias RulesteadDemoWeb.UiMatrixFixtures

  @matrix_path "/dev/rulestead-admin/ui-matrix"
  @sections [
    "overview-shell",
    "foundations-reference",
    "primitives",
    "composites",
    "static-fixtures"
  ]

  test "dev matrix route renders the real admin shell and required sections", %{conn: conn} do
    {:ok, view, html} = live(conn, @matrix_path)
    rendered = html <> render(view)

    assert rendered =~ "rs-shell"
    assert rendered =~ "Rulestead admin UI matrix"

    for section <- @sections do
      assert rendered =~ ~s(data-matrix-section="#{section}")
    end
  end
end
```

**Fixture health pattern** (lines 140-178):
```elixir
test "fixture helpers expose deterministic stress states" do
  assert UiMatrixFixtures.long_flag_key() ==
           "enterprise-checkout-redesign-rollout-experiment-long-key-for-wrapping-proof"

  assert length(UiMatrixFixtures.dense_records()) > 10
  assert length(UiMatrixFixtures.audit_entries()) > 0

  rare_states = Enum.map(UiMatrixFixtures.rare_state_examples(), & &1.state)

  assert :permission_denied in rare_states
  assert :read_only in rare_states
  assert :unavailable in rare_states
  assert :destructive in rare_states
  assert :loading in rare_states
  assert :error in rare_states
end
```

**Route and boundary source assertion pattern** (lines 180-271):
```elixir
test "phase 117 route examples cover primary flow IA routes" do
  route_examples = UiMatrixFixtures.route_examples()
  route_labels = Enum.map(route_examples, & &1.label)
  route_paths = Enum.map(route_examples, & &1.path)

  for label <- ["Overview", "Inventory", "Rules", "Kill switch", "Audiences", "Audit", "Explain", "Simulate"] do
    assert label in route_labels
  end

  for path_fragment <- ["/admin/flags", "/admin/flags/audit", "/admin/flags/enable-new-dashboard/simulate"] do
    assert Enum.any?(route_paths, &String.contains?(&1, path_fragment))
  end
end

test "source boundary stays demo-hosted and real-component backed" do
  router_source = read_source("lib/rulestead_demo_web/router.ex")
  admin_router_source = read_repo_source("rulestead_admin/lib/rulestead_admin/router.ex")

  assert router_source =~ "if Mix.env() in [:dev, :test] do"
  assert router_source =~ ~s(scope "/dev/rulestead-admin", RulesteadDemoWeb do)
  assert router_source =~ ~s(live "/ui-matrix", UiMatrixLive, :index)
  refute admin_router_source =~ "ui-matrix"
end
```

**Use for 118:** Use ExUnit/source assertions for fixture load health, UI matrix route isolation, route examples, real component usage, and forbidden tooling posture. Keep browser-only behavior in Playwright.

---

### `scripts/check_admin_foundations.py` or new `scripts/check_*.py` (utility / guard, file-I/O)

**Analog:** `scripts/check_admin_foundations.py`

**Guard header and deterministic scope pattern** (lines 1-11):
```python
#!/usr/bin/env python3
"""Source guard for Rulestead admin foundation invariants.

Checks deterministic facts only:
  - contract sections required by Phase 115 exist
  - every noncanonical @media width literal in admin CSS is documented
  - reduced-motion and focus exception source markers are present

Usage:
    python3 scripts/check_admin_foundations.py
"""
```

**Path/constants pattern** (lines 13-56):
```python
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
CSS_PATH = ROOT / "rulestead_admin/priv/static/css/rulestead_admin.css"
CONTRACT_PATH = ROOT / ".planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md"

REQUIRED_CSS_MARKERS = [
    "@media (prefers-reduced-motion: reduce)",
    "cmdk: inside modal",
    "--rs-focus-ring",
]
```

**Failure aggregation and CI output pattern** (lines 89-119):
```python
def main():
    failures = []

    css = read_text(CSS_PATH)
    contract = read_text(CONTRACT_PATH)

    if css is None:
        failures.append(f"missing CSS file: {CSS_PATH.relative_to(ROOT)}")
        css = ""

    for marker in REQUIRED_CSS_MARKERS:
        if marker not in css:
            failures.append(f"admin CSS missing required marker: {marker}")

    if failures:
        print("ADMIN FOUNDATION DRIFT DETECTED")
        for failure in failures:
            print(f"  {failure}")
        return 1

    print("ADMIN FOUNDATIONS OK")
    return 0
```

**Use for 118:** Add or extend a guard only for a concrete repeatable drift class uncovered by evidence. Prefer stdlib Python, explicit constants, aggregated failures, deterministic text output, and no network or package dependencies.

---

### `scripts/ci/lint.sh` (config / CI guard, batch)

**Analog:** same file

**Strict shell and root handling pattern** (lines 1-18):
```bash
#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

cd "${RULESTEAD_REPO}/rulestead"
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict

# Restore CWD to repo root — guard scripts use relative paths (rulestead_admin/..., brandbook/...)
cd "${RULESTEAD_REPO}"
```

**Guard-chain pattern** (lines 20-43):
```bash
# Synced-pair guard: Block 2/3 (dark) must be byte-identical in rulestead_admin.css
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"

# Static contrast targets from the brand palette and semantic foreground pairs.
python3 "${RULESTEAD_REPO}/scripts/check_contrast.py"

# Generated HTML brand book drift and size budget.
python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"

# Logo asset drift: copied admin/demo assets must stay byte-identical with
# brandbook sources, and the real shell must retain the theme-aware classes.
python3 "${RULESTEAD_REPO}/scripts/check_logo_assets.py"

# Admin foundations: documented breakpoints, reduced-motion floor, and focus markers.
python3 "${RULESTEAD_REPO}/scripts/check_admin_foundations.py"
```

**Use for 118:** Keep this as the durable guard spine. If a new guard is justified, add it near related guard scripts with a short comment and deterministic command. Do not add visual diff, Storybook, external AI, release, or publish-prep tooling.

---

### `.planning/REQUIREMENTS.md` (documentation, batch)

**Analog:** same file

**Requirement checklist pattern** (lines 38-43):
```markdown
### Verification

- [ ] **VER-01**: Playwright captures UI matrix and admin workflow screenshots across light, dark, system-dark, desktop, mobile, and reduced-motion cases.
- [ ] **VER-02**: Deterministic assertions cover horizontal overflow, focus visibility, key ARIA roles, keyboard flow, fixture load health, and selected contrast pairs.
- [ ] **VER-03**: Existing brand/token/logo/contrast/brandbook guard scripts remain green and are extended only where they prevent real design-system drift.
- [ ] **VER-04**: Planning docs record v1.17 decisions, verification evidence, requirement completion, and any intentional exceptions before milestone closeout.
```

**Traceability pattern** (lines 67-92):
```markdown
| Requirement | Phase | Status |
|-------------|-------|--------|
| FLOW-01 | Phase 117 | Complete |
| FLOW-02 | Phase 117 | Complete |
| FLOW-03 | Phase 117 | Complete |
| FLOW-04 | Phase 117 | Complete |
| VER-01 | Phase 118 | Pending |
| VER-02 | Phase 118 | Pending |
| VER-03 | Phase 118 | Pending |
| VER-04 | Phase 118 | Pending |
```

**Use for 118:** Flip VER-01 through VER-04 only after evidence commands pass and `118-VERIFICATION.md` records proof. Keep future requirements and out-of-scope rows unchanged.

---

### `.planning/ROADMAP.md` and `.planning/STATE.md` (documentation, batch)

**Analogs:** same files

**Roadmap phase status pattern** (`.planning/ROADMAP.md` lines 107-129):
```markdown
## Phase 118: Evidence + Idempotence Guardrails

**Goal:** Close the milestone with reusable evidence and guardrails that make future design-system passes additive rather than regressive.
**Depends on:** Phase 117
**Requirements:** VER-01, VER-02, VER-03, VER-04
**Success Criteria:**

1. Playwright screenshots cover the UI matrix and admin workflow surfaces across light, dark, system-dark, desktop, mobile, and reduced-motion cases.
2. Deterministic assertions cover horizontal overflow, focus visibility, key ARIA roles, keyboard flow, fixture load health, and selected contrast pairs.
3. Brand/token/logo/contrast/brandbook guard scripts remain green and are extended only where they prevent real design-system drift.
4. Planning docs record decisions, verification evidence, requirement completion, and intentional exceptions before milestone closeout.
5. The final evidence posture does not introduce broad pixel-baseline maintenance or external AI visual-review requirements.

| 118. Evidence + Idempotence Guardrails | 0/0 | Pending | - |
```

**State current-position pattern** (`.planning/STATE.md` lines 32-40):
```markdown
## Current Position

Phase: 118
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-14
Stopped at: Phase 118 UI-SPEC approved
Resume file: .planning/phases/118-evidence-idempotence-guardrails/118-UI-SPEC.md
```

**State latest verification pattern** (`.planning/STATE.md` lines 225-247):
```markdown
## Latest Verification

Current v1.17 planning proof:

- Requirements: `.planning/REQUIREMENTS.md` maps 22/22 v1.17 requirements to Phases 113-118.
- Roadmap: `.planning/ROADMAP.md` defines 6 sequential phases and preserves linked-version sibling-package constraints.
- Phase 117 Plan 04: audit, explain, and simulate hierarchy fixes plus final FLOW closeout are committed; targeted audit/explain/simulate ExUnit, accessibility ExUnit, final `admin-flow-ia.spec.ts`, FLOW/D-coverage source guards, forbidden visual-baseline guard, and whitespace checks passed.
- Baseline inherited from v1.16: brand/token/logo guard chain, frontend fixture specs, admin workflow screenshot evidence, compose/browser proof, core/admin/demo tests, and passed v1.16 milestone audit.
```

**Use for 118:** Update roadmap progress/status and state current-position/latest-verification after phase evidence and verification. Preserve the linked-version sibling-package constraints, Phase 8-only-doc absence, and no standalone `rulestead_admin` publish posture.

## Shared Patterns

### Generated Screenshot Artifacts

**Sources:** `examples/demo/frontend/tests/ui-matrix.spec.ts` lines 187-194; `examples/demo/frontend/tests/admin-flow-ia.spec.ts` lines 183-188

**Apply to:** Browser evidence specs and Phase 118 evidence docs

```typescript
path: testInfo.outputPath(
  `ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png`,
),

path: testInfo.outputPath(
  `flow-${route.name}-${theme.name}-${viewport.name}.png`,
),
```

Screenshots are generated test artifacts only. Do not use `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, or checked-in baselines.

### Backend URL And Theme Setup

**Sources:** `examples/demo/frontend/tests/ui-matrix.spec.ts` lines 128-148; `examples/demo/frontend/tests/admin-flow-ia.spec.ts` lines 112-131

**Apply to:** Playwright browser proof

```typescript
const context = await browser.newContext({
  colorScheme: theme.colorScheme,
  viewport: { width: viewport.width, height: viewport.height },
  reducedMotion: motion.reducedMotion,
});

await page.goto(`${backendUrl}/demo/sign-in`);
await page.waitForURL(/\/admin\/flags/);
await page.evaluate((storedTheme) => {
  if (storedTheme) {
    localStorage.setItem("rulestead_admin.theme", storedTheme);
  } else {
    localStorage.removeItem("rulestead_admin.theme");
  }
}, theme.storedTheme);
```

Record any explicit `DEMO_BACKEND_URL=http://localhost:<port>` used during verification.

### Deterministic Browser Assertions

**Sources:** `examples/demo/frontend/tests/admin-flow-ia.spec.ts` lines 177-181, 310-354, 468-585

**Apply to:** VER-02 browser-only evidence

```typescript
await expect(
  page.getByRole("heading", { name: route.heading }).first(),
).toBeVisible();
await expect(page.getByText(route.evidence).first()).toBeVisible();
await expectNoHorizontalOverflow(page);
```

Use role/text locators, route ordering checks, focus assertions, keyboard loops, and no-overflow checks. Keep fixture/source boundaries in ExUnit or scripts.

### Source Boundary And Fixture Health

**Source:** `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` lines 140-178 and 226-271

**Apply to:** VER-02 fixture health and D-15 matrix isolation

```elixir
assert length(UiMatrixFixtures.dense_records()) > 10
assert length(UiMatrixFixtures.audit_entries()) > 0

assert router_source =~ ~s(scope "/dev/rulestead-admin", RulesteadDemoWeb do)
assert router_source =~ ~s(live "/ui-matrix", UiMatrixLive, :index)
refute admin_router_source =~ "ui-matrix"
```

### Guard Chain

**Source:** `scripts/ci/lint.sh` lines 20-43

**Apply to:** VER-03 guard verification

```bash
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"
python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"
python3 "${RULESTEAD_REPO}/scripts/check_contrast.py"
python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"
python3 "${RULESTEAD_REPO}/scripts/check_logo_assets.py"
python3 "${RULESTEAD_REPO}/scripts/check_admin_foundations.py"
```

Default to documenting these existing guards. Extend only for a concrete repeatable drift class.

## No Analog Found

All likely Phase 118 files have direct or role-matched analogs in the current codebase and planning artifacts.

## Metadata

**Analog search scope:** `.planning/`, `examples/demo/frontend/tests/`, `examples/demo/backend/test/`, `scripts/`
**Files scanned:** 17 directly listed or discovered files, plus phase context and research
**Pattern extraction date:** 2026-06-14
