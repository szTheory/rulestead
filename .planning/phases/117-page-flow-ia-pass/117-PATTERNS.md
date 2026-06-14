# Phase 117: Page Flow + IA Pass - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 14 planned or likely new/modified files
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` | documentation | batch | `.planning/phases/116-primitive-composite-polish/116-PHASE-117-HANDOFF.md` | role-match |
| `examples/demo/frontend/tests/admin-flow-ia.spec.ts` | test | request-response | `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | exact |
| `examples/demo/frontend/tests/admin-flow-ia.spec.ts` | test | request-response | `examples/demo/frontend/tests/ui-matrix.spec.ts` | exact |
| `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` | fixture | batch | same file | exact |
| `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` | test | request-response | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex` | route / LiveView | request-response | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | route / LiveView | CRUD | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` | route / LiveView | CRUD | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` | route / LiveView | request-response | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/audience_live/index.ex` | route / LiveView | CRUD | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` | route / LiveView | CRUD | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex` | route / LiveView | request-response | same file | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` | route / LiveView | transform | same file | exact |
| `rulestead_admin/priv/static/css/rulestead_admin.css` | config / styling | transform | same file | exact |

## Pattern Assignments

### `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` (documentation, batch)

**Analog:** `.planning/phases/116-primitive-composite-polish/116-PHASE-117-HANDOFF.md`

**Artifact shape pattern** (lines 20-29):
```markdown
| Surface | Why It Stays Page-Owned | Phase 117 Review Focus |
| --- | --- | --- |
| Flag inventory filters and omnisearch | Owns URL tokens, transient suggestions, canonical query patching, pagination reset, and view switching. | Search/filter hierarchy, clear-query affordances, empty/error state placement, mobile scan order. |
| Kill-switch runbook | Emergency workflow with route-owned sequencing, diagnostics, audit history, and after-action handoff. | 3am decision order, typed-key placement, disabled-state escalation, diagnostics/audit return path. |
```

**Boundary pattern** (lines 40-44):
```markdown
- Do not reopen Phase 115 foundation rules for breakpoints, focus, reduced motion, radius/elevation, or dense-content containment unless Phase 117 finds a concrete route-level regression.
- Do not add Storybook, PhoenixStorybook, checked-in pixel baselines, public admin matrix exposure, release workflow changes, schema/migration changes, FleetDesk rebranding, or `rulestead_admin` publish preparation.
- Do not move authorization, governance, rollout eligibility, audit provenance, preview uncertainty, redaction, or authored-state semantics into page-flow code.
```

**Use for 117:** Build a compact table with columns: operator job, route cluster, page-owned surface, route/path evidence, state coverage, finding, action, proof, follow-on. Keep it issue/evidence based, not a redesign brief.

---

### `examples/demo/frontend/tests/admin-flow-ia.spec.ts` (test, request-response)

**Analogs:** `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` and `examples/demo/frontend/tests/ui-matrix.spec.ts`

**Imports and backend helper pattern** (`brand-ui-evidence.spec.ts` lines 1-3):
```typescript
import { expect, test, type Browser, type Page } from "@playwright/test";

import { backendUrl } from "./support/admin";
```

**Viewport/theme matrix pattern** (`brand-ui-evidence.spec.ts` lines 17-26):
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
```

**Admin route open pattern** (`brand-ui-evidence.spec.ts` lines 44-68):
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

**No-overflow + screenshot artifact pattern** (`brand-ui-evidence.spec.ts` lines 71-78 and 116-123):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

await expectNoHorizontalOverflow(page);
await page.screenshot({
  fullPage: true,
  path: testInfo.outputPath(
    `admin-${surface.name}-${theme.name}-${viewport.name}.png`,
  ),
});
```

**Command-palette browser evidence pattern** (`ui-matrix.spec.ts` lines 195-225):
```typescript
await expect(page.locator(".rs-shell__search")).toBeVisible();
await expect(page.locator("#rs-cmdk")).toBeAttached();
await expect(page.locator("#rs-cmdk-input")).toBeAttached();
await expect(page.locator("#rs-cmdk [role=option]").first()).toBeAttached();

const paletteState = await page.locator("#rs-cmdk").evaluate((element) => ({
  hidden: (element as HTMLElement).hidden,
  hook: element.getAttribute("phx-hook"),
}));

expect(paletteState.hidden).toBe(true);
expect(paletteState.hook).toContain("CmdK");
```

**Forbidden visual-baseline guard** (`ui-matrix.spec.ts` lines 72-81):
```typescript
const forbiddenSourceTerms = [
  "toHave" + "Screenshot",
  "match" + "Snapshot",
  "pixel" + "match",
  "visual" + "-diff",
  "pixel" + "-baseline",
  "Story" + "book",
  "Phoenix" + "Story" + "book",
  "phoenix" + "_" + "storybook",
] as const;
```

**Use for 117:** Cover home, flag inventory, rules, kill, audience, audit, explain, and simulate unless the plan records an equivalent route set. Assert route shell, rail/command-palette reachability, route-specific first answer, focus/keyboard path, mobile containment, and curated screenshots as generated artifacts. Do not use `toHaveScreenshot`.

---

### `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` (fixture, batch)

**Analog:** same file

**Deterministic shell and state fixture pattern** (lines 8-97):
```elixir
def shell_assigns do
  %{
    breadcrumbs: [
      %{label: "Admin", path: "/admin/flags"},
      %{label: "UI matrix", path: "/dev/rulestead-admin/ui-matrix"}
    ],
    current_environment: %{
      key: "production-eu-central-operations-with-an-intentionally-long-name",
      name: "Production EU Central Operations With An Intentionally Long Name",
      status: :healthy,
      production?: true
    },
    policy_state: %{
      capabilities: %{read?: true, propose?: false, execute?: false, admin?: false},
      denied_reason:
        "Fixture read-only policy: destructive writes are unavailable for this matrix example."
    }
  }
end
```

**Route example fixture pattern** (lines 125-145):
```elixir
def route_examples do
  [
    %{label: "Inventory", path: "/admin/flags?env=production-eu-central"},
    %{label: "Rules", path: "/admin/flags/#{@long_flag_key}/rules?env=production-eu-central"},
    %{label: "Destructive preview", path: "/admin/flags/#{@long_flag_key}/kill?env=production-eu-central"}
  ]
end
```

**Rare-state coverage pattern** (lines 515-557):
```elixir
def rare_state_examples do
  [
    %{state: :empty, label: "No matrix examples match this section", summary: "Valid empty fixture state."},
    %{state: :permission_denied, label: "Permission denied", summary: "Actor can preview but not mutate."},
    %{state: :unavailable, label: "Host evidence unavailable", summary: "Action is disabled with explanation."},
    %{state: :destructive, label: "Destructive action", summary: "Preview, confirm, audit handoff."}
  ]
end
```

**Use for 117:** Extend only if FLOW-04 lacks deterministic happy/error/boundary/rare coverage. Keep fixture-only semantics: no DB/cache/filesystem/network reads, no product seed expansion.

---

### `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` (test, request-response)

**Analog:** same file

**LiveViewTest import and marker assertion pattern** (lines 1-23 and 72-82):
```elixir
defmodule RulesteadDemoWeb.UiMatrixLiveTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  @matrix_path "/dev/rulestead-admin/ui-matrix"
  @sections [
    "overview-shell",
    "foundations-reference",
    "primitives",
    "composites"
  ]

  test "dev matrix route renders the real admin shell and required sections", %{conn: conn} do
    {:ok, view, html} = live(conn, @matrix_path)
    rendered = html <> render(view)

    assert rendered =~ "rs-shell"
    for section <- @sections do
      assert rendered =~ ~s(data-matrix-section="#{section}")
    end
  end
end
```

**Requirement evidence pattern** (lines 110-118):
```elixir
for {requirement, markers} <- @cmp_evidence do
  for marker <- markers do
    assert rendered =~ marker, "#{requirement} evidence missing marker #{inspect(marker)}"
  end
end
```

**Source-boundary guard pattern** (lines 61-70):
```elixir
@forbidden_source_terms [
  "Storybook",
  "PhoenixStorybook",
  "phoenix_storybook",
  "visual-diff",
  "pixel-baseline",
  "matchSnapshot",
  "toHaveScreenshot",
  "pixelmatch"
]
```

**Use for 117:** Add or extend source/fixture tests only for route-cluster coverage, fixture health, and forbidden tooling. Leave browser behavior to Playwright.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` (route / LiveView, CRUD)

**Analog:** same file

**Imports and route-owned state pattern** (lines 5-15 and 59-80):
```elixir
use Phoenix.LiveView

alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
alias RulesteadAdmin.Live.Session

@default_limit 10
@allowed_lifecycle ~w(active potentially_stale stale archived)
@allowed_views ~w(all needs_review archive_candidates recently_stale archived custom)

def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(:screen_action, :index)
    |> assign(:base_path, "#{socket.assigns.rulestead_admin_mount_path}/flags")
    |> assign(:filters, default_filters())
    |> assign(:page, empty_page())
    |> stream_configure(:flags, dom_id: &"flag-#{&1.flag.key}")
    |> stream(:flags, [])
end
```

**URL canonicalization and query-owned filter pattern** (lines 85-118):
```elixir
def handle_params(params, uri, socket) do
  merged_params = Map.merge(query_params(uri), stringify_keys(params))
  filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
  current_path = path_with_query(uri, socket.assigns.base_path)
  canonical_path = build_index_path(socket.assigns.base_path, filters, outcome)

  if canonical_path != current_path do
    {:noreply, push_patch(socket, to: canonical_path)}
  else
    socket =
      socket
      |> assign(:current_path, current_path)
      |> assign(:filters, filters)
      |> load_flags(filters)

    {:noreply, socket}
  end
end
```

**Filter event pattern** (lines 128-155):
```elixir
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

**Error + stream reset pattern** (lines 430-448):
```elixir
case Rulestead.list_flags(opts) do
  {:ok, page} ->
    socket
    |> assign(:page, page)
    |> assign(:error_message, nil)
    |> stream(:flags, page.entries, reset: true)

  {:error, error} ->
    socket
    |> assign(:page, empty_page())
    |> assign(:error_message, error.message)
    |> stream(:flags, [], reset: true)
end
```

**Use for 117:** Keep search, filters, suggestions, views, pagination, highlighted rows, and streams in the route. IA fixes should adjust hierarchy/copy/markup around this pattern, not move query state into a component.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` (route / LiveView, CRUD)

**Analog:** same file

**Route workspace state pattern** (lines 7-23 and 27-39):
```elixir
alias Rulestead.Store.Command
alias RulesteadAdmin.Components.{FlagComponents, RuleEditorComponents, Shell}
alias RulesteadAdmin.Live.Session

def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:flag_key, nil)
   |> assign(:detail, nil)
   |> assign(:audiences, [])
   |> assign(:rules, [])
   |> assign(:editable?, true)
   |> assign(:error_messages, [])
   |> assign(:env_links, %{})}
end

def handle_params(%{"key" => flag_key}, uri, socket) do
  env = query_params(uri)["env"] || socket.assigns.current_environment.key
  base_path = build_base_path(socket, flag_key)

  socket =
    socket
    |> assign(:flag_key, flag_key)
    |> assign(:current_path, Session.current_path(socket, base_path))
    |> assign(:env_links, Session.env_links(socket, base_path))
    |> load_workspace(flag_key, env)

  {:noreply, socket}
end
```

**Save/publish validation and command pattern** (lines 194-235):
```elixir
errors = validate_rules(rules, audiences, editable?: socket.assigns.editable?)

if errors != [] do
  {:noreply,
   socket
   |> assign(:error_messages, errors)
   |> assign(:status_message, nil)}
else
  with {:ok, _draft} <-
         Rulestead.save_draft_ruleset(
           Command.SaveDraftRuleset.new(detail.flag.key, detail.environment.key, ruleset,
             actor: socket.assigns.current_actor,
             metadata: command_metadata(socket, "rules.save_draft", rules_reason(detail, mode))
           )
         ),
       {:ok, _published} <- maybe_publish(mode, detail.flag.key, detail.environment.key, socket) do
    {:noreply, socket |> assign(:status_message, message) |> load_workspace(detail.flag.key, detail.environment.key)}
  else
    {:error, error} -> {:noreply, assign(socket, :error_messages, normalize_store_errors(error))}
  end
end
```

**Editable capability pattern** (lines 251-268):
```elixir
capability_editable? =
  socket.assigns.rulestead_admin_policy_state.capabilities.edit? or
    socket.assigns.rulestead_admin_policy_state.capabilities.admin? or
    socket.assigns.rulestead_admin_policy_state.capabilities.propose?

editable? = capability_editable? && detail && is_nil(detail.flag.archived_at)

socket
|> assign(:detail, detail)
|> assign(:rules, rules)
|> assign(:audiences, audiences)
|> assign(:editable?, editable?)
|> assign(:error_messages, errors)
```

**Use for 117:** Review route order and action hierarchy around draft/save/publish/archive/move/missing-audience states. Do not move command construction, validation, or draft/publish state out of the route.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` (route / LiveView, request-response)

**Analog:** same file

**Guard and route state pattern** (lines 28-45):
```elixir
def handle_params(%{"key" => key}, uri, socket) do
  capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

  if not capabilities.execute? and not capabilities.propose? and not capabilities.admin? do
    {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
  else
    env = query_params(uri)["env"] || socket.assigns.current_environment.key
    base_path = build_base_path(socket, key)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_detail(key, env)
  end
end
```

**Emergency runbook hierarchy pattern** (lines 71-139):
```elixir
<div :if={@detail} class="rs-runbook">
  <AuditComponents.kill_switch_banner ... />

  <section class="rs-runbook__state" aria-label="Kill switch state">
    <h2><%= if kill_switch_active?(@detail), do: "Override active", else: "Authored behavior active" %></h2>
    <OperatorComponents.signal label="Override state" ... />
    <OperatorComponents.signal label="Confirmation" value={confirmation_hint(@current_environment.key)} ... />
  </section>

  <section class="rs-runbook__action" aria-label={if(kill_switch_active?(@detail), do: "Release override", else: "Engage override")}>
    <AuditComponents.kill_switch_form ... />
  </section>

  <section class="rs-runbook__context" aria-label="After-action context">
    <a class="rs-button" href={path_for(assigns, "/diagnostics")}>Open diagnostics</a>
    <a class="rs-button" href={path_for(assigns, "/#{@detail.flag.key}/timeline")}>Open audit timeline</a>
  </section>
</div>
```

**Validation and error pattern** (lines 199-236):
```elixir
with :ok <- validate_reason(reason),
     :ok <- validate_confirmation(socket.assigns.flag_key, socket.assigns.current_environment.key, confirmation),
     {:ok, _payload} <- Rulestead.release_kill_switch(..., reason: reason) do
  {:noreply,
   socket
   |> assign(:confirmation_error, nil)
   |> assign(:confirmation_value, "")
   |> assign(:reason_value, "")
   |> assign(:notice, "Kill switch released for #{socket.assigns.current_environment.name}.")
   |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}
else
  {:error, error} ->
    {:noreply, assign(socket, :confirmation_error, error.message) |> assign(:reason_value, reason)}

  {:validation, message} ->
    {:noreply, assign(socket, :confirmation_error, message) |> assign(:reason_value, reason)}
end
```

**Use for 117:** Keep destructive sequencing as current state -> action/reason/typed confirmation -> diagnostics/audit handoff. IA edits should improve decision order and focus order without weakening server-side validation or capability checks.

---

### `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex` (route / LiveView, request-response)

**Analog:** same file

**Navigation-source alignment pattern** (lines 21-34 and 64-70):
```elixir
@launcher_summaries %{
  flags: "Inventory of every flag in this environment.",
  audiences: "Reusable targeting rules and their dependents.",
  audit: "Append-only history of every change, across all flags.",
  change_requests: "Review queue for governed mutations and approvals."
}

assigns =
  assigns
  |> assign(:caps, assigns.rulestead_admin_policy_state.capabilities)
  |> assign(:env_q, "?env=" <> env_key)
  |> assign(:base, base)
  |> assign(:launcher_groups, launcher_groups(base, env_key, assigns.current_environment))
```

**Attention-first page hierarchy pattern** (lines 100-120 and 158-175):
```elixir
<section class="rs-page-section" aria-label="Needs you now">
  <p class="rs-eyebrow">Needs you now</p>
  <h2>What needs attention in {@current_environment.name}</h2>

  <p :if={attention == []} class="rs-attention-empty">
    Nothing needs your attention in {@current_environment.name} right now.
  </p>

  <div :if={attention != []} class="rs-attention">
    <a :for={item <- attention} class="rs-attention__card" data-tone={item.tone} href={item.href}>
      <span class="rs-attention__count">{item.count}</span>
      <span class="rs-attention__label">{item.label}</span>
      <span class="rs-attention__hint">{item.hint}</span>
    </a>
  </div>
</section>

<nav class="rs-task-board" aria-label="Start a task">
  <section :for={group <- @launcher_groups} class="rs-task-group" aria-label={group.title}>
    <h2>{group.title}</h2>
    <OperatorComponents.task_link :for={item <- group.items} title={item.label} summary={item.summary} href={item.path} />
  </section>
</nav>
```

**Capped summary loader pattern** (lines 267-281):
```elixir
defp load_summary(mount_path, env_key, actor) do
  {kill_engaged, stale_candidates} = summarize_flags(env_key)
  executions = summarize_executions(env_key)

  %{
    pending_changes: count_pending(env_key),
    kill_engaged: kill_engaged,
    stale_candidates: stale_candidates,
    failed: executions.failed,
    upcoming: executions.upcoming,
    running: executions.running,
    high_impact: recent_high_impact(mount_path, env_key, actor)
  }
end
```

**Use for 117:** Keep home as a launcher/orientation route derived from `Navigation`. Do not create new top-level nav groups; improve attention/task-board order only if evidence shows FLOW-01/FLOW-02 confusion.

---

### `rulestead_admin/lib/rulestead_admin/live/audience_live/index.ex` (route / LiveView, CRUD)

**Analog:** same file

**Scoped route state pattern** (lines 21-31):
```elixir
def handle_params(_params, _uri, socket) do
  base_path = "#{socket.assigns.rulestead_admin_mount_path}/audiences"

  socket =
    socket
    |> assign(:current_path, Session.current_path(socket, base_path))
    |> assign(:env_links, Session.env_links(socket, base_path))
    |> assign(:tenant_links, Session.tenant_links(socket, base_path))
    |> load_audiences()

  {:noreply, socket}
end
```

**Inventory table pattern** (lines 37-79):
```elixir
<Shell.page
  page_title="Audiences"
  page_kicker="Reusable targeting"
  page_summary="Shared audience definitions referenced across flags. Open a row for used-by detail and governed mutations."
  current_section={:audiences}
>
  <FlagComponents.section_card title="Audience library">
    <table :if={@audiences != []} aria-label="Audience list" class="rs-table">
      <tr :for={audience <- @audiences}>
        <td><a href={Shared.path(assigns, "/audiences/#{audience.key}")}><code><%= audience.key %></code></a></td>
        <td><%= audience.description || "-" %></td>
        <td><span class="rs-badge" data-tone={audience_tone(audience)}>{audience_label(audience)}</span></td>
      </tr>
    </table>
    <p :if={@audiences == []}>No audiences found for this scope.</p>
  </FlagComponents.section_card>
</Shell.page>
```

**Use for 117:** Review density, archived/read-only distinction, dependency placement, and narrow viewport usability without extracting a generic inventory table unless evidence proves reuse.

---

### `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` (route / LiveView, CRUD)

**Analog:** same file

**Filter URL-state pattern** (lines 24-42 and 123-127):
```elixir
def handle_params(params, _uri, socket) do
  filters =
    socket.assigns.filters
    |> Map.merge(%{
      "actor" => Map.get(params, "actor", ""),
      "mutation" => Map.get(params, "mutation", ""),
      "from" => Map.get(params, "from", ""),
      "to" => Map.get(params, "to", ""),
      "env_filter" => Map.get(params, "env_filter", socket.assigns.current_environment.key)
    })

  socket =
    socket
    |> assign(:filters, filters)
    |> assign(:current_path, build_path(socket, filters))
    |> assign(:env_links, detail_env_links(socket, filters))
    |> load_entries(filters)
end

def handle_event("filter", %{"filters" => filters}, socket) do
  merged = Map.merge(socket.assigns.filters, filters)
  {:noreply, push_patch(socket, to: build_path(socket, merged))}
end
```

**Support-safe timeline pattern** (lines 62-118):
```elixir
<FlagComponents.section_card title="Filters">
  <form phx-change="filter" phx-submit="filter" aria-label="Audit filters" class="rs-filter-grid">
    <input id="audit_filter_actor" type="text" name="filters[actor]" value={@filters["actor"]} />
    <select id="audit_filter_mutation" name="filters[mutation]">...</select>
  </form>
</FlagComponents.section_card>

<OperatorComponents.empty_state
  :if={@entries == []}
  title="No audit events match these filters"
  body="Widen the actor, environment, mutation type, or date range filters to inspect more of the append-only ledger. For flag-scoped history, open the flag and use its Timeline tab."
  variant="compact"
/>

<div :for={entry <- @entries}>
  <AuditComponents.timeline_row entry={entry} show_flag={true} />
  <AuditComponents.diff_card :if={entry.show_diff?} entry={entry} />
</div>
```

**Redaction pattern** (lines 241-257):
```elixir
defp redacted_metadata(metadata) do
  metadata
  |> Redaction.redact_metadata(
    allow: [
      "before.status",
      "after.status",
      "diff.rules",
      "rollback_of_event_id",
      "links.inverse_event_type"
    ]
  )
  |> Map.fetch!(:audit)
end
```

**Use for 117:** Include audit in route evidence. Edit only for evidence-triggered hierarchy failures such as buried first answer, stranded audit rows, inaccessible raw detail, unclear redaction, or keyboard/mobile issues.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex` (route / LiveView, request-response)

**Analog:** same file

**Permalink/query form pattern** (lines 36-65 and 73-81):
```elixir
def handle_params(params, _uri, socket) do
  form =
    @empty_form
    |> Map.put("targeting_key", params["targeting_key"] || "")
    |> Map.put("tenant_key", params["tenant_key"] || (socket.assigns.current_tenant && socket.assigns.current_tenant.key) || "")
    |> Map.put("session_id", params["session_id"] || "")
    |> Map.put("request_id", params["request_id"] || "")

  {:noreply, socket |> assign(:form, form) |> maybe_run_explain(form, page)}
end

def handle_event("run_explain", %{"explain" => params}, socket) do
  form = normalize_form(params)
  page = socket.assigns.page

  {:noreply,
   socket
   |> assign(:form, form)
   |> push_patch(to: explain_path(socket, page.flag_key, form))
   |> maybe_run_explain(form, page)}
end
```

**Route links and support-safe form pattern** (lines 112-132):
```elixir
<:header_actions>
  <a href={flag_detail_path(assigns)}>Back to flag</a>
  <a href={simulate_path(assigns)}>Open simulate</a>
  <a href={timeline_path(assigns)}>Open timeline</a>
</:header_actions>

<FlagComponents.flag_sub_nav ... current={:explain} />

<FlagComponents.section_card title="Explain context">
  <p>Permalink fields stay in the query string. Traits are never stored in URLs.</p>
  <form class="rs-form" phx-change="validate" phx-submit="run_explain" aria-label="Explain lookup form">
```

**Error/result pattern** (lines 186-215):
```elixir
case Rulestead.simulate_flag(page.flag_key, page.current_environment.key, context,
       actor: socket.assigns.current_actor
     ) do
  {:ok, %{result: result}} ->
    socket
    |> assign(:simulation_result, result)
    |> assign(:explanation, explanation)
    |> assign(:error_message, nil)

  {:error, error} ->
    socket
    |> assign(:simulation_result, nil)
    |> assign(:explanation, nil)
    |> assign(:error_message, error.message)
end
```

**Use for 117:** Keep permalink fields route-owned and support-safe. Do not add traits to URLs. Edit only if route-flow evidence shows the first answer/sample/context/raw detail is buried or inaccessible.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` (route / LiveView, transform)

**Analog:** same file

**Archetype and form-state pattern** (lines 10-43 and 78-135):
```elixir
@archetypes [
  %{
    id: "support_case",
    label: "Support case",
    summary: "Known customer context with redaction-sensitive traits.",
    form: %{
      "targeting_key" => "support-user-42",
      "tenant_key" => "acme",
      "traits" => "plan=enterprise\nemail=sam@example.com\nip=203.0.113.8"
    }
  }
]

def handle_event("run_simulation", %{"simulation" => params}, socket) do
  form = normalize_form(params)
  context = build_context(form, socket.assigns.page.current_environment.key)

  case Rulestead.simulate_flag(socket.assigns.page.flag_key, socket.assigns.page.current_environment.key, context,
         actor: socket.assigns.current_actor
       ) do
    {:ok, %{result: result, redacted_context: redacted_context}} ->
      {:noreply, socket |> assign(:simulation_result, result) |> assign(:redacted_context, redacted_context)}
    {:error, error} ->
      {:noreply, socket |> assign(:simulation_result, nil) |> assign(:redacted_context, nil) |> assign(:error_message, error.message)}
  end
end
```

**Route hierarchy pattern** (lines 201-289):
```elixir
<OperatorComponents.banner
  title="Single-context simulation"
  body="Use one targeting key and one trait payload, read the decision summary first, then expand trace detail only if the summary does not answer the question."
  tone="accent"
/>

<section class="rs-tool-layout" aria-label="Simulation workspace">
  <div class="rs-tool-layout__main">
    <FlagComponents.section_card title="Context builder">
      <form class="rs-form" aria-label="Simulation form" phx-change="validate" phx-submit="run_simulation">
        ...
      </form>
    </FlagComponents.section_card>
  </div>
  <aside class="rs-tool-layout__side" aria-label="Simulation shortcuts">
    <SimulateComponents.archetype_chips ... />
  </aside>
</section>

<FlagComponents.section_card :if={@simulation_result} title="Decision summary">
  <OperatorComponents.summary_grid items={@summary_items} />
</FlagComponents.section_card>
```

**Transform/parser pattern** (lines 331-362):
```elixir
defp parse_traits(traits) do
  traits
  |> String.split("\n", trim: true)
  |> Enum.reduce(%{}, fn line, acc ->
    case String.split(line, "=", parts: 2) do
      [key, value] -> Map.put(acc, String.trim(key), coerce_scalar(String.trim(value)))
      _other -> acc
    end
  end)
end
```

**Use for 117:** Preserve the summary-first, raw-detail-later route hierarchy and redaction semantics. IA changes should improve route flow without widening simulation product semantics.

---

### `rulestead_admin/lib/rulestead_admin/components/shell.ex` (component, request-response)

**Analog:** same file

**Navigation derivation pattern** (lines 32-41 and 145-167):
```elixir
assigns =
  assigns
  |> assign(:nav_groups, nav_groups(assigns))
  |> assign(:nav_overview, nav_overview(assigns))
  |> assign(:palette_groups, palette_groups(assigns))
  |> assign(:brand_href, brand_href(assigns))

<nav :if={@nav_groups != []} class="rs-shell__rail" aria-label="Primary navigation">
  <div :if={@nav_overview} class="rs-shell__rail-group">
    <a href={@nav_overview.path} class="rs-shell__rail-link rs-shell__rail-link--overview" aria-current={if(@nav_overview.current?, do: "page", else: nil)}>
      <%= @nav_overview.label %>
    </a>
  </div>
  <div :for={group <- @nav_groups} class="rs-shell__rail-group">
    <p class="rs-shell__rail-group-title"><%= group.title %></p>
    <a :for={item <- group.items} href={item.path} class="rs-shell__rail-link" aria-current={if(item.current?, do: "page", else: nil)}>
      <%= item.label %>
    </a>
  </div>
</nav>
```

**Command palette semantics pattern** (lines 198-217 and 226-237):
```elixir
<div :if={@palette_groups != []} id="rs-cmdk" class="rs-cmdk" phx-hook=".CmdK" hidden>
  <div class="rs-cmdk__panel" role="dialog" aria-modal="true" aria-label="Command palette">
    <input
      id="rs-cmdk-input"
      type="text"
      role="combobox"
      aria-expanded="true"
      aria-controls="rs-cmdk-list"
      aria-label="Search commands and pages"
    />
    <ul id="rs-cmdk-list" data-rs-cmdk-list class="rs-cmdk__list" role="listbox" aria-label="Results">
      <a :for={item <- items} id={"rs-cmdk-opt-" <> item.id} role="option" aria-selected="false" href={item.href} data-keywords={item.keywords}>
        <span class="rs-cmdk__option-label"><%= item.label %></span>
      </a>
    </ul>
  </div>
</div>
```

**Focus-heavy JS exception pattern** (lines 285-325):
```javascript
const open = () => {
  lastFocus = document.activeElement
  root.hidden = false
  document.documentElement.style.overflow = "hidden"
  input.value = ""
  filter("")
  requestAnimationFrame(() => input.focus())
}
const close = () => {
  root.hidden = true
  document.documentElement.style.overflow = ""
  if (lastFocus && lastFocus.focus) lastFocus.focus()
}

root.addEventListener("keydown", (e) => {
  if (e.key === "Escape") { e.preventDefault(); close() }
  else if (e.key === "ArrowDown") { e.preventDefault(); select(index + 1) }
  else if (e.key === "ArrowUp") { e.preventDefault(); select(index - 1) }
  else if (e.key === "Enter") { e.preventDefault(); ... }
  else if (e.key === "Tab") { e.preventDefault(); input.focus() }
})
```

**Use for 117:** Do not invent new navigation arrays. If command-palette evidence fails, keep fixes inside this existing hook/semantic structure and derive options from `RulesteadAdmin.Navigation`.

---

### `rulestead_admin/lib/rulestead_admin/navigation.ex` (config / utility, request-response)

**Analog:** same file

**Single source of truth pattern** (lines 4-18 and 32-50):
```elixir
# Single source of truth for the admin's top-level navigation.
#
# Destinations are grouped by the operator's task rhythm ...
# Per-flag verbs (rules/simulate/explain/rollouts/kill/timeline) are a
# contextual sub-nav scoped to a flag, not global destinations.

@groups [
  {"Build & release",
   [
     %{key: :flags, label: "Flags", suffix: "/flags"},
     %{key: :experiments, label: "Experiments", suffix: "/experiments"},
     %{key: :audiences, label: "Audiences", suffix: "/audiences"},
     %{key: :schedule, label: "Schedule", suffix: "/schedule"}
   ]},
  {"Explain & diagnose",
   [
     %{key: :diagnostics, label: "Diagnostics", suffix: "/diagnostics"},
     %{key: :audit, label: "Audit", suffix: "/audit"},
     %{key: :compare, label: "Compare", suffix: "/compare"}
   ]},
  {"Review & approve",
   [
     %{key: :change_requests, label: "Change requests", suffix: "/change-requests"},
     %{key: :webhooks, label: "Webhooks", suffix: "/webhooks"}
   ]}
]
```

**Resolution pattern** (lines 73-100):
```elixir
def groups(base_path, env_key, current \\ nil) when is_binary(base_path) do
  env_q = env_query(env_key)

  for {title, items} <- @groups do
    %{
      title: title,
      items:
        for item <- items do
          %{key: item.key, label: item.label, path: base_path <> item.suffix <> env_q, current?: item.key == current}
        end
    }
  end
end

def items(base_path, env_key, current \\ nil) when is_binary(base_path) do
  base_path |> groups(env_key, current) |> Enum.flat_map(& &1.items)
end
```

**Use for 117:** Preserve Overview plus Build & release, Explain & diagnose, Review & approve. Do not add top-level Rulesets, Settings, Audit, Rollouts, or Destructive groups.

---

### `rulestead_admin/priv/static/css/rulestead_admin.css` (config / styling, transform)

**Analog:** same file

**Form and focus pattern** (lines 822-843 and 1315-1320):
```css
.rs-form-field > label {
  display: block;
  margin-bottom: 0.35rem;
  color: var(--rs-text);
  font-size: 0.86rem;
  font-weight: var(--rs-weight-semibold);
}

.rs-form-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.55rem;
}

.rs-shell input:focus-visible,
.rs-shell select:focus-visible,
.rs-shell textarea:focus-visible {
  box-shadow: var(--rs-focus-ring);
  border-color: var(--rs-primary);
}
```

**Filter/table containment pattern** (lines 2769-2835):
```css
.rs-filter-grid {
  display: grid;
  gap: 0.75rem;
  padding: 1rem;
  background: var(--rs-surface);
  border: 1px solid var(--rs-border);
  border-radius: var(--rs-radius-lg);
}

@media (min-width: 700px) {
  .rs-filter-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

.rs-table {
  display: block;
  width: 100%;
  table-layout: fixed;
  overflow-x: auto;
}

.rs-table th,
.rs-table td {
  overflow-wrap: anywhere;
}
```

**Route layout pattern** (lines 3294-3390 and 3662-3679):
```css
.rs-attention {
  display: grid;
  gap: var(--rs-space-3);
}

@media (min-width: 60rem) {
  .rs-attention {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

.rs-task-board {
  display: grid;
  gap: 0.85rem;
}

@media (min-width: 900px) {
  .rs-task-board {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

.rs-tool-layout {
  display: grid;
  gap: 1rem;
}

@media (min-width: 60rem) {
  .rs-tool-layout {
    grid-template-columns: minmax(0, 1fr) 20rem;
    align-items: start;
  }
}
```

**Destructive/runbook containment pattern** (lines 3078-3090 and 3133-3161):
```css
.rs-runbook__state,
.rs-runbook__action,
.rs-runbook__note,
.rs-runbook__history {
  border: 1px solid var(--rs-border);
  border-radius: var(--rs-radius-lg);
  background: var(--rs-surface);
  box-shadow: var(--rs-shadow-sm);
}

.rs-runbook__signals {
  display: grid;
  gap: 0.55rem;
}

.rs-signal strong {
  color: var(--rs-text);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
```

**Use for 117:** Prefer route-local markup/order fixes first. If CSS is required, reuse existing route classes, tokens, focus ring, responsive breakpoints, `minmax(0, 1fr)`, local scroll, and `overflow-wrap`. Do not introduce a new palette, breakpoint system, radius/elevation language, or checked-in visual baseline infrastructure.

## Shared Patterns

### Route-Owned URL State

**Source:** `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` lines 85-118, 128-155, 616-624

**Apply to:** inventory filters, audit filters, explain permalink fields, environment links, and route-specific subnav/query behavior.

```elixir
defp patch_filters(socket, filters) do
  push_patch(socket,
    to:
      build_index_path(
        socket.assigns.base_path,
        normalize_filters(filters, socket.assigns.current_environment.key)
      )
  )
end
```

### Shell And Navigation Consistency

**Source:** `rulestead_admin/lib/rulestead_admin/navigation.ex` lines 4-18, 32-50; `shell.ex` lines 32-41, 145-167

**Apply to:** rail, home launcher, command palette, breadcrumbs, and contextual subnav evidence.

Do not create per-test or per-page ad hoc nav groups. Use `RulesteadAdmin.Navigation` as source of truth and keep per-flag verbs contextual.

### Semantic Forms, Buttons, Links Before JavaScript

**Source:** route LiveViews and `shell.ex` command palette hook

**Apply to:** all route IA fixes.

Use semantic `<a>`, `<button>`, `<form>`, `phx-change`, `phx-submit`, `handle_params/3`, `push_patch`, and server validation. DOM-aware JavaScript is already accepted for focus-heavy shell widgets such as `.CmdK`; do not add route JS for ordinary hierarchy problems.

### Error Handling

**Source:** `flag_live/index.ex` lines 430-448; `flag_live/kill.ex` lines 199-236; `audit_live/index.ex` lines 129-155

**Apply to:** route fetches, route form submissions, and evidence-triggered route fixes.

Pattern is to keep failed data as empty route state plus an assigned `error_message` or `confirmation_error`, then render `role="alert"` in the route. Do not throw browser-only errors or hide errors in components.

### Destructive Flow

**Source:** `flag_live/kill.ex` lines 71-139, 199-236; `ui_matrix_fixtures.ex` lines 439-513

**Apply to:** kill switch and any route evidence for archive/delete/risky actions.

Keep preview/state evidence, reason, typed confirmation for production/high-risk paths, explicit unavailable/read-only copy, non-danger back link, diagnostics/audit handoff, and server-side validation.

### Evidence Posture

**Source:** `brand-ui-evidence.spec.ts` lines 95-129; `ui-matrix.spec.ts` lines 72-81, 160-192; `116-VERIFICATION.md` lines 37-55

**Apply to:** `admin-flow-ia.spec.ts`, fixture tests, and phase review artifacts.

Screenshots are generated artifacts under Playwright output paths. They are not checked-in baselines. Keep `toHaveScreenshot`, `matchSnapshot`, `pixelmatch`, `visual-diff`, Storybook, and PhoenixStorybook out of Phase 117.

### Phase 115/116 Boundary

**Source:** `116-PHASE-117-HANDOFF.md` lines 10-18 and 40-44; `117-UI-SPEC.md` lines 32-41 and 127-138

**Apply to:** every plan item.

Phase 117 validates polished components in route workflows. It should not reopen foundations, redo primitives/composites, add public APIs, add schemas/migrations, change release workflow, rebrand FleetDesk, introduce Storybook, or prepare `rulestead_admin` for standalone publishing.

## No Analog Found

All planned or likely Phase 117 files have close analogs in the codebase or prior phase artifacts.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | Existing route, fixture, Playwright, CSS, navigation, and planning artifact patterns cover the phase. |

## Metadata

**Analog search scope:** `.planning/phases`, `rulestead_admin/lib/rulestead_admin/live`, `rulestead_admin/lib/rulestead_admin/components`, `rulestead_admin/priv/static/css`, `examples/demo/backend/lib`, `examples/demo/backend/test`, `examples/demo/frontend/tests`

**Files scanned:** 90+ source, test, and planning files via `rg --files`, targeted `rg`, `wc -l`, and line-numbered reads.

**Pattern extraction date:** 2026-06-14

**Planner notes:**

- Start with `117-FLOW-IA-REVIEW.md`, then route-flow Playwright evidence, then only evidence-triggered route IA fixes.
- Preferred route evidence set: home/overview, flag inventory, rules workspace, kill switch, audience inventory, audit, explain, simulate.
- Keep fixes vertical and route-owned unless evidence proves a stable reusable subpattern.
