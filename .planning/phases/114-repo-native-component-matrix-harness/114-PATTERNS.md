# Phase 114: Repo-Native Component Matrix Harness - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/demo/backend/lib/rulestead_demo_web/router.ex` | route | request-response | `examples/demo/backend/lib/rulestead_demo_web/router.ex` | exact |
| `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/components/shell.ex` + `examples/demo/backend/lib/rulestead_demo_web.ex` | role-match |
| `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` | utility | transform | `rulestead_admin/test/rulestead_admin/components/audience_components_test.exs` | role-match |
| `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs` + component tests | role-match |
| `examples/demo/frontend/tests/ui-matrix.spec.ts` | test | request-response | `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | exact |

## Pattern Assignments

### `examples/demo/backend/lib/rulestead_demo_web/router.ex` (route, request-response)

**Analog:** `examples/demo/backend/lib/rulestead_demo_web/router.ex`

**Imports / router macro pattern** (lines 1-5):
```elixir
defmodule RulesteadDemoWeb.Router do
  use RulesteadDemoWeb, :router

  use RulesteadAdmin.Router
```

**Browser pipeline pattern** (lines 6-13):
```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {RulesteadDemoWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
end
```

**Mounted admin boundary to stay outside** (lines 40-43):
```elixir
scope "/admin" do
  pipe_through :browser
  rulestead_admin("/flags", policy: RulesteadDemo.AdminPolicy, mount_path: "/admin/flags")
end
```

**Copy guidance:** add the matrix as a separate dev/test-gated `live "/ui-matrix", UiMatrixLive, :index` route under an explicit `/dev/rulestead-admin` scope using `pipe_through :browser`. Do not add it inside the `/admin` scope or `rulestead_admin("/flags", ...)`.

---

### `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` (component, request-response)

**Analogs:** `examples/demo/backend/lib/rulestead_demo_web.ex`, `rulestead_admin/lib/rulestead_admin/components/shell.ex`, `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`, `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`

**LiveView use pattern** (`examples/demo/backend/lib/rulestead_demo_web.ex` lines 49-55):
```elixir
def live_view do
  quote do
    use Phoenix.LiveView

    unquote(html_helpers())
  end
end
```

**HTML helpers available to LiveViews** (`examples/demo/backend/lib/rulestead_demo_web.ex` lines 78-91):
```elixir
defp html_helpers do
  quote do
    import Phoenix.HTML
    import RulesteadDemoWeb.CoreComponents

    alias Phoenix.LiveView.JS
    alias RulesteadDemoWeb.Layouts

    unquote(verified_routes())
  end
end
```

**Shell wrapper contract** (`rulestead_admin/lib/rulestead_admin/components/shell.ex` lines 8-30):
```elixir
attr(:page_title, :string, required: true)
attr(:page_kicker, :string, required: true)
attr(:page_summary, :string, required: true)
attr(:breadcrumbs, :list, default: [])
attr(:current_environment, :map, required: true)
attr(:environments, :list, default: [])
attr(:base_path, :string, default: nil)
attr(:current_section, :atom, default: nil)
attr(:policy_state, :map, default: nil)
attr(:flash, :map, default: %{})
attr(:theme_default, :string, default: "system")
slot(:header_actions)
slot(:inner_block, required: true)
```

**Shell render target and command palette/focus hooks** (`shell.ex` lines 43-65, 198-215):
```elixir
<div class="rs-shell" data-env-tone={@env_tone} data-theme-pending>
  <header class="rs-shell__header">
    ...
    <button
      :if={@palette_groups != []}
      type="button"
      class="rs-shell__search"
      data-rs-cmdk-open
      aria-haspopup="dialog"
      aria-keyshortcuts="Meta+K Control+K"
    >
```

```elixir
<div :if={@palette_groups != []} id="rs-cmdk" class="rs-cmdk" phx-hook=".CmdK" hidden>
  ...
  <input
    id="rs-cmdk-input"
    data-rs-cmdk-input
    class="rs-cmdk__input"
    type="text"
    role="combobox"
    aria-label="Search commands and pages"
```

**Primitive/component render style** (`operator_components.ex` lines 11-18, 24-31, 41-58):
```elixir
def banner(assigns) do
  ~H"""
  <section class="rs-banner" data-tone={@tone} aria-label={@aria_label}>
    <h2><%= @title %></h2>
    <p><%= @body %></p>
  </section>
  """
end
```

```elixir
def page_section(assigns) do
  ~H"""
  <section class="rs-page-section">
    <h2><%= @title %></h2>
    <p :if={@summary}><%= @summary %></p>
    <%= render_slot(@inner_block) %>
  </section>
  """
end
```

**Badge/stat component pattern** (`flag_components.ex` lines 8-26, 144-151):
```elixir
def lifecycle_badge(assigns) do
  assigns =
    assign(assigns,
      label: assigns.state |> normalize_state() |> humanize_state(),
      tone: assigns.state |> normalize_state() |> state_tone()
    )

  ~H"""
  <span class="rs-badge rs-badge--lifecycle" data-tone={@tone}>
    <%= @label %>
  </span>
  """
end
```

```elixir
def stat(assigns) do
  ~H"""
  <article class="rs-stat" data-tone={@tone}>
    <p class="rs-stat__title"><%= @title %></p>
    <p class="rs-stat__value"><%= @value %></p>
  </article>
  """
end
```

**Copy guidance:** implement `use RulesteadDemoWeb, :live_view`, import/alias real `RulesteadAdmin.Components.*`, alias the fixture helper, and render matrix sections inside `RulesteadAdmin.Components.Shell.page/1`. Mark each section with stable selectors such as `data-matrix-section="primitives"` for Playwright and ExUnit assertions.

---

### `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` (utility, transform)

**Analog:** `rulestead_admin/test/rulestead_admin/components/audience_components_test.exs`

**Fixed nested fixture shape** (lines 8-36):
```elixir
@full_preview %{
  preview_basis: "authored_state_with_host_evidence",
  preview_fingerprint: "audprev_test123",
  environment_scope: %{environment_key: "test"},
  tenant_scope: %{tenant_key: "tenant-a"},
  affected_references: [%{reference_key: "flag:example:ruleset:1:rule:vip"}],
  uncertainty: %{
    message:
      "authored state with bounded host-supplied evidence; not an authoritative population count",
    authoritative_population_count?: false
  },
  sample_evidence: [
    %{
      actor_key: "actor-1",
      targeting_key: "t-1",
      matched?: true,
      reason: "segment_match"
    }
  ],
  impression_evidence: %{
    window_label: "last_24h",
    sampled_impressions: 100,
    matched_impressions: 12,
    variant_breakdown: [
      %{variant: "control", count: 8},
      %{"variant" => "treatment", "count" => 4}
    ]
  }
}
```

**Boundary-state fixture mutation** (lines 52-64, 67-79):
```elixir
preview =
  Map.merge(@full_preview, %{
    sample_evidence: [],
    impression_evidence: %{},
    preview_basis: "authored_state_and_explicit_samples"
  })
```

```elixir
samples =
  for i <- 1..11 do
    %{actor_key: "actor-#{i}", targeting_key: "t-#{i}", matched?: true, reason: "ok"}
  end
```

**Mutation-confirm defaults pattern** (`confirm_components_test.exs` lines 8-20):
```elixir
defp render_confirm(assigns) do
  assigns =
    Map.merge(
      %{
        submit_event: "apply",
        submit_label: "Apply update",
        evidence: [],
        extra_fields: []
      },
      assigns
    )

  render_component(&ConfirmComponents.mutation_confirm/1, assigns)
end
```

**Copy guidance:** keep fixtures synthetic and deterministic. Prefer explicit functions such as `environment/0`, `environments/0`, `policy_state/0`, `long_reason/0`, `impact_preview/0`, and `dense_records/0`; use simple `Map.merge/2` variants for denied, unavailable, empty, destructive, dense, and long-label states.

---

### `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` (test, request-response)

**Analogs:** `examples/demo/backend/test/support/conn_case.ex`, `rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs`, component tests

**Demo ConnCase pattern** (`examples/demo/backend/test/support/conn_case.ex` lines 18-37):
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    @endpoint RulesteadDemoWeb.Endpoint

    use RulesteadDemoWeb, :verified_routes

    import Plug.Conn
    import Phoenix.ConnTest
    import RulesteadDemoWeb.ConnCase
  end
end

setup tags do
  RulesteadDemo.DataCase.setup_sandbox(tags)
  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

**Live route assertion pattern** (`diagnostics_live/index_test.exs` lines 44-65):
```elixir
test "diagnostics renders a summary-first current-node health page for the selected environment",
     %{conn: conn} do
  {:ok, view, html} = live(conn, "/admin/flags/diagnostics?env=prod")

  loaded_html = render_async(view)

  assert html =~ "Infrastructure health"
  assert loaded_html =~ "Current node only"
  assert loaded_html =~ "Infrastructure health"
  assert has_element?(view, "a[href='/admin/flags/diagnostics?env=staging']")
end
```

**Component smoke assertion pattern** (`confirm_components_test.exs` lines 23-33):
```elixir
test "renders a primary confirm with a required reason and the submit label" do
  html = render_confirm(%{reason_value: "Promoting checkout"})

  assert html =~ "rs-mutation-confirm"
  assert html =~ ~s(phx-submit="apply")
  assert html =~ "rs-button--primary"
  assert html =~ "Apply update"
  assert html =~ ~s(name="reason")
  assert html =~ "Promoting checkout"
  refute html =~ "rs-button--danger"
end
```

**Shell render_component pattern** (`session_test.exs` lines 231-270):
```elixir
html =
  render_component(&Shell.page/1,
    page_title: "Flags",
    page_kicker: "Flag inventory",
    page_summary: "Compile-safe placeholder",
    current_environment: %{key: "prod", name: "Production"},
    current_tenant: %{key: "acme", name: "Acme"},
    environments: [
      %{key: "dev", name: "Development"},
      %{key: "prod", name: "Production"}
    ],
    inner_block: [
      %{
        inner_block: fn _changed, _slot_value -> "Flag list placeholder" end
      }
    ]
  )
```

**Copy guidance:** use `RulesteadDemoWeb.ConnCase, async: false` and `import Phoenix.LiveViewTest`. Assert the dev/test route renders `.rs-shell`, the matrix title, and required `data-matrix-section` buckets. Add source/route assertions that the matrix is not mounted under `RulesteadAdmin.Router.rulestead_admin/2`.

---

### `examples/demo/frontend/tests/ui-matrix.spec.ts` (test, request-response)

**Analog:** `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`

**Imports and backend URL pattern** (lines 1-4 plus `support/admin.ts` lines 1-12):
```typescript
import { expect, test, type Browser, type Page } from "@playwright/test";

import { backendUrl } from "./support/admin";
```

```typescript
const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

export async function openAdminPage(browser: Browser): Promise<Page> {
  const adminPage = await browser.newPage();
  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  return adminPage;
}
```

**Viewport/theme cases** (lines 5-26):
```typescript
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

const viewports: ViewportCase[] = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const themes: ThemeCase[] = [
  { name: "light", colorScheme: "light", storedTheme: "light" },
  { name: "dark", colorScheme: "light", storedTheme: "dark" },
  { name: "system-dark", colorScheme: "dark", storedTheme: null },
];
```

**Context open and shell assertion pattern** (lines 44-69):
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
}
```

**No-overflow assertion** (lines 71-78):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

**Screenshot artifact loop** (lines 95-126):
```typescript
for (const viewport of viewports) {
  for (const theme of themes) {
    for (const surface of adminSurfaces) {
      test(`admin ${surface.name} renders branded shell: ${theme.name} / ${viewport.name}`, async ({
        browser,
      }, testInfo) => {
        const { context, page } = await openAdminSurface(
          browser,
          viewport,
          theme,
          surface.path,
        );

        await expect(page.locator(".rs-shell__brand").first()).toBeVisible();
        await expectNoHorizontalOverflow(page);

        await page.screenshot({
          fullPage: true,
          path: testInfo.outputPath(
            `admin-${surface.name}-${theme.name}-${viewport.name}.png`,
          ),
        });

        await context.close();
      });
    }
  }
}
```

**Copy guidance:** create a `ui-matrix.spec.ts` loop for light, dark, system-dark, desktop, mobile, and reduced-motion cases. Visit `/dev/rulestead-admin/ui-matrix`, assert `.rs-shell`, representative `[data-matrix-section="..."]` sections, no horizontal overflow, selected focus/keyboard behavior, and screenshots named with matrix section/theme/viewport/motion. Do not add pixel baselines.

## Shared Patterns

### Route Boundary / Production Guard

**Source:** `examples/demo/backend/lib/rulestead_demo_web/router.ex`
**Apply to:** router and route tests

Use the existing browser pipeline and keep the matrix route outside:
```elixir
scope "/admin" do
  pipe_through :browser
  rulestead_admin("/flags", policy: RulesteadDemo.AdminPolicy, mount_path: "/admin/flags")
end
```

Planner should require a dev/test guard such as `if Mix.env() in [:dev, :test] do ... end` around the new `/dev/rulestead-admin/ui-matrix` route, with no public admin router changes.

### Real Shell / Theme Scope

**Source:** `rulestead_admin/lib/rulestead_admin/components/shell.ex`
**Apply to:** `ui_matrix_live.ex`, Playwright assertions

```elixir
<div class="rs-shell" data-env-tone={@env_tone} data-theme-pending>
...
<section class="rs-shell__context" aria-label="Theme">
  <p class="rs-shell__context-label" id="rs-theme-label">Theme</p>
  <div
    id="rs-theme-control"
    role="radiogroup"
    aria-labelledby="rs-theme-label"
    phx-hook=".ThemeControl"
    data-theme-default={@theme_default}
    class="rs-theme-control__group"
  >
```

### Demo Layout Asset Context

**Source:** `examples/demo/backend/lib/rulestead_demo_web/components/layouts/root.html.heex`
**Apply to:** matrix LiveView route

```heex
<link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
<link phx-track-static rel="stylesheet" href={~p"/assets/css/rulestead_admin.css"} />
<script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
</script>
```

### Fixed Assigns and Boundary Fixtures

**Source:** component tests under `rulestead_admin/test/rulestead_admin/components/`
**Apply to:** fixture helper and ExUnit smoke tests

```elixir
Map.merge(
  %{
    submit_event: "apply",
    submit_label: "Apply update",
    evidence: [],
    extra_fields: []
  },
  assigns
)
```

### Browser Evidence

**Source:** `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`
**Apply to:** `ui-matrix.spec.ts`

```typescript
const context = await browser.newContext({
  colorScheme: theme.colorScheme,
  viewport: { width: viewport.width, height: viewport.height },
});
...
await expect(page.locator(".rs-shell")).toBeVisible();
await expectNoHorizontalOverflow(page);
await page.screenshot({
  fullPage: true,
  path: testInfo.outputPath(`admin-${surface.name}-${theme.name}-${viewport.name}.png`),
});
```

## No Analog Found

No planned file lacks an analog. The fixture helper is new production/demo code, but existing component tests provide the fixed-assign and boundary-state fixture pattern.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| none | n/a | n/a | All planned files have exact or role-match analogs |

## Metadata

**Analog search scope:** `examples/demo/backend/lib`, `examples/demo/backend/test`, `examples/demo/frontend/tests`, `rulestead_admin/lib/rulestead_admin/components`, `rulestead_admin/test`
**Files scanned:** 80+ repo files from targeted `rg --files` and `rg` searches
**Pattern extraction date:** 2026-06-14
**Phase boundary:** Phase 114 only; no Phase 8 docs, publish preparation, package metadata, schema/migration, Storybook, broad pixel baseline, or CSS polish changes.
