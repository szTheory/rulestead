# Phase 7: Admin UI - Simulation, Rollouts, Kill Switch, Audit, Security & Redaction - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 18
**Analogs found:** 15 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead_admin/lib/rulestead_admin/router.ex` | route | request-response | `rulestead_admin/lib/rulestead_admin/router.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/session.ex` | middleware | request-response | `rulestead_admin/lib/rulestead_admin/live/session.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | liveview | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` | liveview | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` + `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` | liveview | CRUD | `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` | liveview | CRUD | `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` | liveview | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` | liveview | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/shell.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/shell.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` + `shell.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/components/simulate_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/rule_editor_components.ex` + `flag_components.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | role-match |
| `rulestead_admin/test/rulestead_admin/live/flag_live/*_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`, `rules_test.exs`, `index_test.exs` | exact |
| `rulestead/lib/rulestead.ex` | facade | request-response | `rulestead/lib/rulestead.ex` | exact |
| `rulestead/lib/rulestead/store/command.ex` | service | CRUD | `rulestead/lib/rulestead/store/command.ex` | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | `rulestead/lib/rulestead/store/ecto.ex` | exact |
| `rulestead/lib/rulestead/audit_event.ex` | model | CRUD | `rulestead/lib/rulestead/audit_event.ex` | exact |
| `rulestead/lib/rulestead/telemetry.ex` | utility | event-driven | `rulestead/lib/rulestead/telemetry.ex` | exact |
| `rulestead/lib/rulestead/auth_error.ex` | utility | request-response | `rulestead/lib/rulestead/auth_error.ex` | exact |
| `.credo.exs` and `rulestead/lib/rulestead/credo/*.ex` | config / utility | batch | `.credo.exs` | partial-match |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/router.ex` (route, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/router.ex`

**Mount + live session pattern** (lines 10-27):
```elixir
defmacro rulestead_admin(path, opts \\ []) do
  quote bind_quoted: [path: path, opts: opts] do
    policy = Keyword.fetch!(opts, :policy)
    live_session_name = Module.concat(policy, AdminSession)

    scope path, as: :rulestead_admin do
      live_session live_session_name,
        session: %{
          "policy" => policy,
          "mount_path" => path
        },
        on_mount: [{RulesteadAdmin.Live.Session, :default}] do
        live "/", RulesteadAdmin.Live.FlagLive.Index, :index
        live "/new", RulesteadAdmin.Live.FlagLive.Form, :new
        live "/:key", RulesteadAdmin.Live.FlagLive.Show, :show
        live "/:key/edit", RulesteadAdmin.Live.FlagLive.Form, :edit
        live "/:key/rules", RulesteadAdmin.Live.FlagLive.Rules, :index
      end
    end
  end
end
```

Use this exact expansion style when adding `/simulate`, `/rollouts`, `/kill`, `/timeline`, and `/admin/audit`. Keep everything inside the existing `live_session` and keep policy injection session-based.

### `rulestead_admin/lib/rulestead_admin/live/session.ex` (middleware, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/session.ex`

**Resolve-once mount pattern** (lines 19-36):
```elixir
def on_mount(:default, params, session, socket) do
  resolved = resolve(params, session, policy: session["policy"], mount_path: session["mount_path"])

  if allowed?(resolved) do
    socket =
      socket
      |> assign(:current_actor, resolved.actor)
      |> assign(:current_environment, resolved.environment)
      |> assign(:available_environments, resolved.environments)
      |> assign(:rulestead_admin_policy, resolved.policy)
      |> assign(:rulestead_admin_mount_path, resolved.mount_path)
      |> assign(:rulestead_admin_env_source, resolved.env_source)
      |> assign(:rulestead_admin_session, resolved)

    {:cont, socket}
  else
    {:halt, push_patch(socket, to: resolved.mount_path)}
  end
end
```

**URL-backed env selection pattern** (lines 39-70):
```elixir
def resolve(params, session, opts) when is_map(params) and is_map(session) and is_list(opts) do
  policy = Keyword.fetch!(opts, :policy)
  mount_path = Keyword.fetch!(opts, :mount_path)
  actor = Map.get(session, "current_actor")
  environments = normalize_environments(Map.get(session, "rulestead_admin_environments"))
  remembered_env = Map.get(session, "rulestead_admin_last_env")
  url_env = blank_to_nil(Map.get(params, "env"))

  {environment, env_source} =
    cond do
      selected = find_environment(environments, url_env) -> {selected, :url}
      present?(url_env) -> {default_environment(environments), :default}
      selected = find_environment(environments, remembered_env) -> {selected, :remembered}
      true -> {default_environment(environments), :default}
    end
```

Keep `?env=` canonical for all new screens. Reuse `allowed?/1` for page access and add per-mutation policy checks in the action handlers, not only at mount time.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` (liveview, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

**Route-backed `handle_params/3` pattern** (lines 20-34):
```elixir
def handle_params(params, uri, socket) do
  query = query_params(uri)
  env = query["env"] || socket.assigns.current_environment.key
  key = params["key"]

  current_path = build_path("/admin/flags/#{key}", env)

  socket =
    socket
    |> assign(:flag_key, key)
    |> assign(:current_path, current_path)
    |> assign(:env_links, detail_env_links(key, socket.assigns.available_environments))
    |> load_detail(key, env)

  {:noreply, socket}
end
```

**Detail hero + action rail pattern** (lines 50-69):
```elixir
<div :if={@detail} class="rs-detail">
  <div class="rs-detail__actions">
    <a href={"/admin/flags/#{@detail.flag.key}/edit?env=#{@detail.environment.key}"}>Edit metadata</a>
    <a href={"/admin/flags/#{@detail.flag.key}/rules?env=#{@detail.environment.key}"}>Open rules workspace</a>
  </div>

  <div class="rs-detail__hero">
    <div>
      <h2><code><%= @detail.flag.key %></code></h2>
      <p><%= @detail.flag.description %></p>
      <FlagComponents.tag_list tags={@detail.flag.tags} />
    </div>
    <div class="rs-detail__stats">
      <FlagComponents.stat title="Lifecycle" value={humanize(@detail.lifecycle.state)} tone="neutral" />
```

Phase 7 should keep this page calm and summary-first. Add only banner/summary links here; do not collapse simulation, rollout editing, kill switch, or timeline into the detail page itself.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` (liveview, request-response)

**Analogs:** `show.ex`, `rules.ex`, `shell.ex`

**State init pattern from show/rules**: use `mount/3` with explicit assigns for `flag_key`, `current_path`, result/error/status assigns, and `env_links`. Copy the assign pipeline from `show.ex` lines 9-16 and `rules.ex` lines 10-21.

**Submit flow pattern from `rules.ex`** (lines 160-193):
```elixir
if errors != [] do
  {:noreply,
   socket
   |> assign(:error_messages, errors)
   |> assign(:status_message, nil)}
else
  ...
  with {:ok, _payload} <- some_call(...) do
    {:noreply,
     socket
     |> assign(:status_message, message)
     |> load_workspace(detail.flag.key, detail.environment.key)}
  else
    {:error, error} ->
      {:noreply, assign(socket, :error_messages, normalize_store_errors(error))}
  end
end
```

**Explain text pattern from `rulestead/lib/rulestead/runtime.ex`** (lines 73-79):
```elixir
def explain(environment_key, flag_key, context) do
  with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context),
       {:ok, runtime_metadata} <- Cache.runtime_metadata(environment_key) do
    {:ok, Explainer.runtime_explain(result.debug_trace, runtime_metadata)}
  end
end
```

**Summary-first shell pattern** from `Shell.page/1` lines 14-46 and `FlagComponents.stat/1` lines 102-108. Use the summary card pattern for matched rule, value/variant, reason, bucket result, snapshot version, and cache age, then place raw trace behind expandable sections.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` (liveview, CRUD)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex`

**Draft/save/publish split** (lines 44-52, 160-200):
```elixir
def handle_event("save_draft", params, socket) do
  rules = event_rules(params, socket)
  save_rules(socket, rules, :draft)
end

def handle_event("publish", params, socket) do
  rules = event_rules(params, socket)
  save_rules(socket, rules, :publish)
end
...
with {:ok, _draft} <- Rulestead.save_draft_ruleset(...),
     {:ok, _published} <- maybe_publish(mode, detail.flag.key, detail.environment.key) do
```

**Ordered rule UI pattern** (lines 124-152):
```elixir
<form aria-label="Rules workspace form" phx-change="validate" phx-submit="save_draft">
  <div class="rs-rules-workspace__layout">
    <section class="rs-rules-workspace__editor">
      <div class="rs-rules-workspace__toolbar">
        <div>
          <h3>Ordered rules</h3>
          <p>Use the dedicated workspace to edit, reorder, and save one environment-scoped draft.</p>
        </div>
```

Use this pattern for rollout ladder editing and ordered first-match-wins context. Keep local preview responsive, but only persist through explicit draft save and explicit publish.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` (liveview, CRUD)

**Analogs:** `rules.ex`, `show.ex`, `auth_error.ex`

**Mutation result handling pattern** (rules lines 74-86):
```elixir
case Rulestead.archive_flag(Command.ArchiveFlag.new(socket.assigns.flag_key)) do
  {:ok, _payload} ->
    {:noreply,
     socket
     |> assign(:status_message, "Flag archived")
     |> load_workspace(socket.assigns.flag_key, env)}

  {:error, error} ->
    {:noreply, assign(socket, :error_messages, [error.message])}
end
```

**Typed auth error baseline** from `rulestead/lib/rulestead/auth_error.ex` lines 22-24:
```elixir
def unauthorized(opts \\ []) do
  new(:unauthorized, "caller is not authorized to perform this action", opts)
end
```

Build kill and release actions as explicit command submissions with typed-key confirmation enforced in the LiveView/UI layer for production. Show current override state first, then action controls, then recent events.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` and `live/audit_live/index.ex` (liveview, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`

**Canonical URL normalization pattern** (lines 30-47):
```elixir
merged_params = Map.merge(query_params(uri), stringify_keys(params))
filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
current_path = path_with_query(uri)
canonical_path = build_index_path(socket.assigns.base_path, filters)

if canonical_path != current_path do
  {:noreply, push_patch(socket, to: canonical_path)}
else
  socket =
    socket
    |> assign(:current_path, current_path)
    |> assign(:filters, filters)
    |> assign(:env_links, environment_links(socket.assigns.base_path, filters, socket.assigns.available_environments))
    |> load_flags(filters)
```

**Filter form pattern** (lines 81-125):
```elixir
<form aria-label="Flag filters" phx-change="filters_changed" class="rs-filter-grid">
  <input type="hidden" name="filters[env]" value={@current_environment.key} />
  <label>
    <span>Search</span>
    <input type="text" name="filters[query]" value={@filters["query"]} phx-debounce="300" />
  </label>
```

Use this exact query-param-driven filter and pagination style for per-flag and global audit timelines. The per-flag view should pin `flag_key`; the global view should add actor/result/date/mutation-type filters using the same canonical query-string approach.

### `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` and `components/shell.ex` (component, transform)

**Analogs:** same files

**Summary card pattern** from `flag_components.ex` lines 98-119:
```elixir
def stat(assigns) do
  ~H"""
  <article class="rs-stat" data-tone={@tone}>
    <p class="rs-stat__title"><%= @title %></p>
    <p class="rs-stat__value"><%= @value %></p>
  </article>
  """
end

def section_card(assigns) do
  ~H"""
  <section class="rs-card">
    <h2><%= @title %></h2>
    <div><%= render_slot(@inner_block) %></div>
  </section>
  """
end
```

**Shared page frame + env tone pattern** from `shell.ex` lines 14-25 and 50-52:
```elixir
def page(assigns) do
  assigns = assign(assigns, :env_tone, env_tone(assigns.current_environment))
  ...
end

defp env_tone(%{key: "prod"}), do: "production"
defp env_tone(%{key: "production"}), do: "production"
defp env_tone(_environment), do: "standard"
```

Phase 7 shared UI pieces (`rs-banner`, `rs-summary-grid`, `rs-trace-panel`, `rs-rollout-ladder`, `rs-confirm-modal`, `rs-audit-timeline`, `rs-diff-card`, `rs-policy-state`) should extend this namespace and composition style instead of introducing a second component vocabulary.

### `rulestead/lib/rulestead.ex` (facade, request-response)

**Analog:** `rulestead/lib/rulestead.ex`

**Telemetry-wrapped admin mutation pattern** (lines 534-545):
```elixir
defp admin_write(operation, command) do
  Telemetry.span(
    [:rulestead, :admin, :mutation],
    Telemetry.metadata(
      Telemetry.command_metadata(command, %{operation: Atom.to_string(operation), audit_action: Atom.to_string(operation)})
    ),
    fn ->
      result = run_store(operation, [command], command)
      {result, admin_stop_metadata(result, command)}
    end
  )
end
```

**Stop metadata pattern** (lines 521-532):
```elixir
defp admin_stop_metadata({:ok, value}, command) do
  command
  |> Telemetry.command_metadata()
  |> Map.merge(result_like_metadata(value))
  |> Map.put(:reason, :ok)
end

defp admin_stop_metadata({:error, %Error{} = error}, command) do
  command
  |> Telemetry.command_metadata()
  |> Map.put(:reason, error.type)
end
```

New Phase 7 verbs should land here first: kill/release override, rollback inverse write, audit list/read, simulation facade if needed. Keep bang/non-bang pairs and telemetry wrapping consistent with existing admin verbs.

### `rulestead/lib/rulestead/store/command.ex` (service, CRUD)

**Analog:** `rulestead/lib/rulestead/store/command.ex`

**Command struct pattern** (lines 169-218, representative):
```elixir
defmodule SaveDraftRuleset do
  @enforce_keys [:flag_key, :environment_key, :ruleset]
  defstruct [:flag_key, :environment_key, :ruleset, actor: nil, metadata: %{}]

  def new(flag_key, environment_key, ruleset, opts \\ []) when is_map(ruleset) do
    %__MODULE__{
      flag_key: flag_key,
      environment_key: environment_key,
      ruleset: ruleset,
      actor: Keyword.get(opts, :actor),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end
```

**Filter/list command pattern** (lines 245-295):
```elixir
defmodule ListFlags do
  defstruct environment_key: nil,
            query: nil,
            owner: nil,
            tags: [],
            lifecycle: nil,
            stale: nil,
            include_archived?: false,
            limit: 50,
            after: nil,
            before: nil,
            offset: 0,
            sort: :flag_key,
            page: nil
```

Use this family for `ListAuditEvents`, `FetchAuditEvent`, `EngageKillSwitch`, `ReleaseKillSwitch`, `RollbackAuditEvent`, and any rollout-preview command. Keep selectors key-first and include `actor`, `reason`, and bounded `metadata`.

### `rulestead/lib/rulestead/store/ecto.ex` (service, CRUD)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

**Ecto.Multi mutation discipline** (lines 178-196):
```elixir
Multi.new()
|> Multi.update(
  :ruleset,
  Ruleset.changeset(ruleset, %{status: :published, published_at: published_at})
)
|> Multi.update(
  :flag_environment,
  FlagEnvironment.changeset(flag_environment, %{
    active_ruleset_id: ruleset.id,
    status: :active,
    last_published_at: published_at
  })
)
|> Multi.update(:flag, Changeset.change(flag, updated_at: published_at))
|> Multi.run(:runtime_snapshot, fn repo, _changes ->
  insert_runtime_snapshot(repo, environment, published_at)
end)
|> audit_multi(:audit_event, command, ruleset, environment)
|> Repo.transact()
```

**Error normalization pattern** (lines 201-208, 758-763):
```elixir
{:error, :flag_environment, %Changeset{} = changeset, _changes} ->
  {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

{:error, _operation, reason, _changes} ->
  {:error, StoreError.unavailable(cause: reason)}
```

Use this exact transaction shape for all successful Phase 7 mutations, including kill-switch engage/release and rollback inverse writes. If a mutation should be audit-visible when denied, add a path that still writes an audit row rather than silently returning `{:error, unauthorized}`.

### `rulestead/lib/rulestead/audit_event.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/audit_event.ex`

**Schema baseline** (lines 13-29):
```elixir
schema "audit_events" do
  field(:event_type, :string)
  field(:resource_type, :string)
  field(:resource_id, :binary_id)
  field(:resource_key, :string)
  field(:environment_key, :string)
  field(:actor_id, :string)
  field(:actor_type, :string)
  field(:actor_display, :string)
  field(:reason, :string)
  field(:result, Ecto.Enum, values: @results, default: :ok)
  field(:metadata, :map, default: %{})
  field(:correlation_id, :string)
  field(:occurred_at, :utc_datetime_usec)
```

**Changeset normalization pattern** (lines 34-64):
```elixir
audit_event
|> cast(attrs, [...])
|> update_change(:event_type, &normalize_string/1)
|> update_change(:resource_type, &normalize_string/1)
|> update_change(:resource_key, &normalize_string/1)
|> update_change(:environment_key, &normalize_string/1)
|> update_change(:actor_id, &normalize_string/1)
|> update_change(:actor_type, &normalize_string/1)
|> update_change(:actor_display, &normalize_string/1)
|> update_change(:reason, &normalize_string/1)
|> update_change(:correlation_id, &normalize_string/1)
|> put_occurred_at()
|> validate_required([:event_type, :resource_type, :result, :occurred_at])
```

Extend this model rather than creating a second audit table. Add only redacted fields that support timeline filters, rollback linkage, and human-readable diff summaries.

### `rulestead/lib/rulestead/telemetry.ex` (utility, event-driven)

**Analog:** `rulestead/lib/rulestead/telemetry.ex`

**Allowlisted metadata pattern** (lines 58-66, 185-191):
```elixir
def metadata(attrs) when is_map(attrs) do
  attrs
  |> Map.take(@shared_keys ++ @optional_keys)
  |> Enum.reduce(%{}, fn
    {_key, nil}, acc -> acc
    {key, value}, acc -> Map.put(acc, key, sanitize_value(key, value))
  end)
end

defp sanitize_value(key, value) when key in [:flag_key, :environment, :operation, :audit_action], do: stringify(value)
defp sanitize_value(key, value) when key in [:flag_type, :reason, :source, :refresh_status, :error_kind], do: normalize_atom(value)
defp sanitize_value(_key, _value), do: nil
```

This is the repo’s strongest redaction precedent. Phase 7 telemetry and audit payload shaping should follow the same "take known keys, sanitize, drop the rest" model. Do not store or emit raw traits and do not rely on downstream renderers to redact later.

### `rulestead/lib/rulestead/auth_error.ex` (utility, request-response)

**Analog:** `rulestead/lib/rulestead/auth_error.ex`

**Typed error constructor pattern** (lines 8-24):
```elixir
def new(type, message, opts \\ []) do
  Error.new(
    Keyword.merge(
      [
        domain: :auth,
        type: type,
        message: message
      ],
      opts
    )
  )
end

def unauthorized(opts \\ []) do
  new(:unauthorized, "caller is not authorized to perform this action", opts)
end
```

Keep Phase 7 unauthorized failures typed and consistent. Add new constructors here if production/non-production denial reasons need distinct error types.

### `rulestead_admin/test/rulestead_admin/live/flag_live/*_test.exs` (test, request-response)

**Analogs:** `show_test.exs`, `rules_test.exs`, `index_test.exs`, `test/support/conn_case.ex`

**LiveView boot pattern** from `conn_case.ex` lines 44-58:
```elixir
defmodule RulesteadAdmin.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      import Phoenix.LiveViewTest

      @endpoint RulesteadAdmin.TestEndpoint
    end
  end
```

**Session seeding pattern** from `show_test.exs` lines 42-53:
```elixir
conn =
  conn
  |> Phoenix.ConnTest.init_test_session(%{
    "current_actor" => %{id: 7, email: "priya@example.com"},
    "rulestead_admin_last_env" => "prod",
    "rulestead_admin_environments" => [
      %{"key" => "dev", "name" => "Development"},
      %{"key" => "staging", "name" => "Staging"},
      %{"key" => "prod", "name" => "Production"}
    ]
  })
```

**Interaction assertion pattern** from `rules_test.exs` lines 56-71 and 74-116:
```elixir
{:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rules?env=prod")
assert html =~ "Rules workspace"

updated_html =
  view
  |> form("form[aria-label='Rules workspace form']", %{"ruleset" => %{...}})
  |> render_submit()

assert updated_html =~ "Draft saved for Production"
```

**Filter + patch assertion pattern** from `index_test.exs` lines 103-123:
```elixir
view
|> form("form[aria-label='Flag filters']", %{"filters" => %{...}})
|> render_change()

path = assert_patch(view)
assert path =~ "env=prod"
```

Use these same patterns for simulation, rollout, kill switch, per-flag timeline, and global audit tests. Prefer mounted LiveView tests over direct function tests for route/query-string behavior.

### `.credo.exs` and `rulestead/lib/rulestead/credo/*.ex` (config / utility, batch)

**Analog:** `.credo.exs`

**Current registration seam** (`.credo.exs` lines 1-16):
```elixir
%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: [
          "{mix,.formatter}.exs",
          "rulestead/{config,lib,test}/**/*.{ex,exs}",
          "rulestead_admin/{config,lib,test}/**/*.{ex,exs}"
        ],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      requires: []
    }
  ]
}
```

There is no in-repo analog yet for custom Credo checks themselves. Planner should treat the config registration seam as the pattern, but the check modules are first-of-type work and need fresh design. A flat `rulestead/lib/rulestead/credo/*.ex` layout is acceptable for this repo because there is no existing nested Credo-check namespace to preserve; wire them through `requires` plus explicit check config in `.credo.exs`.

### `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`, `simulate_components.ex`, `rollout_components.ex`, and `audit_components.ex` (component, transform)

**Analogs:** `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`, `shell.ex`, `rule_editor_components.ex`

These Phase 7 component modules are first-of-type by domain, but they should follow the existing component split: shared stat/card/tag primitives stay in `flag_components.ex`, page framing stays in `shell.ex`, and domain-heavy UI clusters get one focused module like `rule_editor_components.ex`.

**Stat/card primitive pattern** from `flag_components.ex` lines 102-149:
```elixir
def stat(assigns) do
  ~H"""
  <article class="rs-stat" data-tone={@tone}>
    <span class="rs-stat__title"><%= @title %></span>
    <strong class="rs-stat__value"><%= @value %></strong>
  </article>
  """
end
```

**Focused domain-component module pattern** from `rule_editor_components.ex`: keep one module per Phase 7 screen family when the markup shares stateful affordances, copy conventions, and CSS hooks.

Planner guidance:
- `operator_components.ex` should hold cross-screen primitives such as banners, confirm shells, and policy-state notices.
- `simulate_components.ex`, `rollout_components.ex`, and `audit_components.ex` should each own one screen-family cluster instead of bloating `flag_components.ex`.
- Reuse the existing `rs-*` class vocabulary and `Shell.page` framing; do not introduce a second component namespace.

## Shared Patterns

### Environment + Route State
**Sources:** `rulestead_admin/lib/rulestead_admin/live/session.ex:19-36`, `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex:30-47`
**Apply to:** All new Phase 7 LiveViews
```elixir
resolved = resolve(params, session, policy: session["policy"], mount_path: session["mount_path"])
...
filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
canonical_path = build_index_path(socket.assigns.base_path, filters)
if canonical_path != current_path do
  {:noreply, push_patch(socket, to: canonical_path)}
end
```

### Mutation Discipline
**Sources:** `rulestead/lib/rulestead.ex:534-545`, `rulestead/lib/rulestead/store/ecto.ex:178-196`
**Apply to:** Rollout publish/rollback, kill engage/release, any Phase 7 admin write
```elixir
Telemetry.span([:rulestead, :admin, :mutation], ..., fn ->
  result = run_store(operation, [command], command)
  {result, admin_stop_metadata(result, command)}
end)

Multi.new()
|> ...
|> audit_multi(:audit_event, command, ruleset, environment)
|> Repo.transact()
```

### Audit Row Construction
**Source:** `rulestead/lib/rulestead/store/ecto.ex:800-818`
**Apply to:** All successful writes, denied writes, inverse-write rollbacks
```elixir
AuditEvent.changeset(%AuditEvent{}, %{
  event_type: audit_event_type(command),
  resource_type: "flag",
  resource_key: audit_flag_key(command),
  environment_key: environment && environment.key,
  actor_id: get_in(command.actor || %{}, [:id]),
  actor_type: get_in(command.actor || %{}, [:type]),
  actor_display: get_in(command.actor || %{}, [:display]),
  reason: Map.get(command, :reason),
  result: :ok,
  metadata: audit_metadata(command, ruleset),
  correlation_id: correlation_id(command),
  occurred_at: now()
})
```

### Redaction Before Emit/Persist
**Source:** `rulestead/lib/rulestead/telemetry.ex:58-66,185-191`
**Apply to:** Telemetry metadata, audit metadata, simulation trace export
```elixir
attrs
|> Map.take(@shared_keys ++ @optional_keys)
|> Enum.reduce(%{}, fn
  {_key, nil}, acc -> acc
  {key, value}, acc -> Map.put(acc, key, sanitize_value(key, value))
end)
```

### UI Shell + Production Tone
**Sources:** `rulestead_admin/lib/rulestead_admin/components/shell.ex:14-25,50-52`, `flag_components.ex:102-119`
**Apply to:** All Phase 7 pages and shared panels
```elixir
<Shell.page ... current_environment={@current_environment} environments={@available_environments} env_links={@env_links}>
...
<article class="rs-stat" data-tone={@tone}>...</article>
<section class="rs-card">...</section>
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead/lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex` | utility | batch | No custom Credo checks exist in-repo yet |
| `rulestead/lib/rulestead/credo/no_raw_traits_in_logger.ex` | utility | batch | No logger hygiene check analog exists yet |
| `rulestead/lib/rulestead/credo/no_mutation_outside_multi.ex` and related checks | utility | batch | Transaction/static-analysis enforcement is new in this repo |

## Metadata

**Analog search scope:** `rulestead_admin/lib`, `rulestead/lib`, `rulestead_admin/test`, `rulestead/test`, `.credo.exs`, prior phase pattern maps
**Files scanned:** 24
**Pattern extraction date:** 2026-04-23
