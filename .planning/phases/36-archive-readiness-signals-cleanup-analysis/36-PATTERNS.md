# Phase 36: Archive-Readiness Signals & Cleanup Analysis - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 19
**Analogs found:** 19 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead/admin/lifecycle.ex` | service | transform | `rulestead/lib/rulestead/admin/lifecycle.ex` | exact |
| `rulestead/lib/rulestead/code_refs/scan_receipt.ex` | model | request-response | `rulestead/lib/rulestead/code_refs/code_reference.ex` | role-match |
| `rulestead/lib/rulestead/webhooks/code_refs_plug.ex` | service | request-response | `rulestead/lib/rulestead/webhooks/code_refs_plug.ex` | exact |
| `rulestead/lib/rulestead/store/command.ex` | model | request-response | `rulestead/lib/rulestead/store/command.ex` | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | request-response | `rulestead/lib/rulestead/store/ecto.ex` | exact |
| `rulestead/lib/rulestead/fake.ex` | service | request-response | `rulestead/lib/rulestead/fake.ex` | exact |
| `rulestead/lib/mix/tasks/rulestead.lifecycle.ex` | utility | request-response | `rulestead/lib/mix/tasks/rulestead.promote.ex` | role-match |
| `rulestead/priv/repo/migrations/20260523130000_create_rulestead_code_reference_scans.exs` | migration | persistence | `rulestead/priv/repo/migrations/20260516193701_create_rulestead_code_references.exs` | role-match |
| `rulestead/test/rulestead/admin_lifecycle_test.exs` | test | transform | `rulestead/test/rulestead/admin_lifecycle_test.exs` | exact |
| `rulestead/test/rulestead/store_ecto_admin_test.exs` | test | request-response | `rulestead/test/rulestead/store_ecto_admin_test.exs` | exact |
| `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` | test | request-response | `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` | exact |
| `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` | test | request-response | `rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs` | role-match |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` | exact |

## Pattern Assignments

### `rulestead/lib/rulestead/admin/lifecycle.ex` (service, transform)

**Analog:** `rulestead/lib/rulestead/admin/lifecycle.ex`

**Imports and public seam** ([lines 1-11](../../../../rulestead/lib/rulestead/admin/lifecycle.ex:1)):
```elixir
defmodule Rulestead.Admin.Lifecycle do
  @moduledoc false
  alias Rulestead.Admin.LifecycleDefaults

  @default_stale_after_seconds 30 * 24 * 60 * 60
  @spec classify(map() | struct(), map() | struct(), keyword()) :: %{...}
```

**Pure classifier shape** ([lines 27-59](../../../../rulestead/lib/rulestead/admin/lifecycle.ex:27)):
```elixir
def classify(flag, flag_environment, opts \\ []) do
  flag = Map.new(flag)
  flag_environment = Map.new(flag_environment)
  ownership = normalize_nested_map(flag[:ownership])
  lifecycle = normalize_nested_map(flag[:lifecycle])

  %{
    state: state(flag, flag_environment, last_evaluated_at, opts),
    mode: mode,
    ownership: ownership,
    suggestion: suggestion,
    last_evaluated_at: last_evaluated_at
  }
end
```

**Rule ladder / freshness helpers** ([lines 62-103](../../../../rulestead/lib/rulestead/admin/lifecycle.ex:62)):
```elixir
defp state(flag, flag_environment, _last_evaluated_at, opts) do
  if not is_nil(flag[:archived_at]) or flag_environment[:status] == :archived do
    :archived
  else
    flag_type = to_string(flag[:flag_type])
    if flag_type in ["kill_switch", "operational"], do: :active, else: state_from_freshness(flag_environment, opts)
  end
end
```

Use this file as the primary home for the new `archive_readiness` payload. Keep the computation pure and option-driven; do not push readiness logic into LiveView.

---

### `rulestead/lib/rulestead/code_refs/scan_receipt.ex` (model, request-response)

**Analog:** `rulestead/lib/rulestead/code_refs/code_reference.ex`

**Schema pattern** ([lines 1-23](../../../../rulestead/lib/rulestead/code_refs/code_reference.ex:1)):
```elixir
defmodule Rulestead.CodeRefs.CodeReference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
```

**Changeset shape** ([lines 14-23](../../../../rulestead/lib/rulestead/code_refs/code_reference.ex:14)):
```elixir
def changeset(code_reference, attrs) do
  code_reference
  |> cast(attrs, [:flag_key, :file, :line])
  |> validate_required([:flag_key, :file, :line])
end
```

Model the scan receipt as a small Ecto schema in the same bounded style: one focused table, explicit fields, and a validating changeset. Keep it as ingestion metadata, not a second code-ref payload format.

---

### `rulestead/lib/rulestead/webhooks/code_refs_plug.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead/webhooks/code_refs_plug.ex`

**Token and JSON handling** ([lines 9-28](../../../../rulestead/lib/rulestead/webhooks/code_refs_plug.ex:9)):
```elixir
case get_req_header(conn, "authorization") do
  ["Bearer " <> token] when token == expected_token and not is_nil(expected_token) ->
    case read_body_json(conn) do
      {:ok, body, conn} -> handle_payload(conn, body)
```

**Transactional replace pattern** ([lines 30-49](../../../../rulestead/lib/rulestead/webhooks/code_refs_plug.ex:30)):
```elixir
Ecto.Multi.new()
|> Ecto.Multi.delete_all(:delete_old, CodeReference)
|> Ecto.Multi.insert_all(:insert_new, CodeReference, valid_references)
|> Repo.transact()
```

Keep the webhook shape and auth behavior intact. Extend the existing `Ecto.Multi` transaction so the scan receipt is written in the same success path as the code-ref replacement, including empty `references` payloads.

---

### `rulestead/lib/rulestead/store/command.ex` (model, request-response)

**Analog:** `rulestead/lib/rulestead/store/command.ex`

**Filter command struct** ([lines 1064-1117](../../../../rulestead/lib/rulestead/store/command.ex:1064)):
```elixir
defmodule ListFlags do
  defstruct environment_key: nil,
            query: nil,
            owner: nil,
            tags: [],
            lifecycle: nil,
            stale: nil,
            flag_type: nil,
            include_archived?: false,
            limit: 50,
            after: nil,
            before: nil,
            offset: 0,
            sort: :flag_key,
            page: nil

  def new(opts \\ []) do
    %__MODULE__{
      environment_key: Keyword.get(opts, :environment_key),
      lifecycle: Keyword.get(opts, :lifecycle),
      stale: Keyword.get(opts, :stale),
      include_archived?: Keyword.get(opts, :include_archived?, false)
    }
  end
end
```

Add any new readiness/evidence-quality filters here first so Ecto, Fake, LiveView, and CLI all share one command contract.

---

### `rulestead/lib/rulestead/store/ecto.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

**Imports and seam wiring** ([lines 1-38](../../../../rulestead/lib/rulestead/store/ecto.ex:1)):
```elixir
defmodule Rulestead.Store.Ecto do
  import Ecto.Query
  alias Ecto.{Changeset, ConstraintError, Multi}

  alias Rulestead.{
    Admin.Lifecycle,
    Environment,
    Flag,
    FlagEnvironment,
    Repo,
    Store,
    StoreError
  }
```

**List pipeline** ([lines 462-492](../../../../rulestead/lib/rulestead/store/ecto.ex:462)):
```elixir
def list_flags(%Command.ListFlags{} = command) do
  with {:ok, environment_filter} <- list_environment_filter(command.environment_key) do
    entries =
      from(flag in Flag, ...)
      |> maybe_filter_environment(environment_filter)
      |> maybe_filter_archived(command.include_archived?)
      |> maybe_filter_query(command.query)
      |> Repo.all()
      |> Enum.flat_map(...)
      |> maybe_filter_owner(command.owner)
      |> maybe_filter_tags(command.tags)
      |> maybe_filter_lifecycle(command.lifecycle)
      |> maybe_filter_stale(command.stale)
      |> maybe_filter_flag_type(command.flag_type)
      |> sort_entries(command.sort)

    {:ok, paginate_entries(entries, command)}
  end
end
```

**Decorator seam and shared lifecycle call** ([lines 4215-4255](../../../../rulestead/lib/rulestead/store/ecto.ex:4215)):
```elixir
defp decorate_payload(payload, flag, environment, flag_environment) do
  environment_cards = environment_cards(flag)

  payload
  |> Map.put(:lifecycle, lifecycle(flag, flag_environment))
  |> Map.put(:has_draft_ruleset?, payload.draft_rulesets != [])
  |> Map.put(:environment_cards, environment_cards)
  |> Map.put(:environment_status, flag_environment.status)
  |> Map.put(:environment_key, environment.key)
end

defp lifecycle(flag, flag_environment) do
  Lifecycle.classify(flag_summary(flag), flag_environment_summary(flag_environment), lifecycle_opts())
end
```

**In-memory post-query filters** ([lines 4280-4327](../../../../rulestead/lib/rulestead/store/ecto.ex:4280)):
```elixir
defp maybe_filter_lifecycle(entries, lifecycle_state) do
  Enum.filter(entries, fn entry -> entry.lifecycle.state == lifecycle_state end)
end

defp maybe_filter_stale(entries, stale_state) do
  Enum.filter(entries, fn entry ->
    case entry.lifecycle.state do
      :active -> stale_state == :fresh
      :potentially_stale -> stale_state == :potentially_stale
      :stale -> stale_state == :stale
      :archived -> false
    end
  end)
end
```

Phase 36 should extend this decorator/filter seam, not add a second projector elsewhere.

---

### `rulestead/lib/rulestead/fake.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead/fake.ex`

**Imports and adapter parity** ([lines 1-36](../../../../rulestead/lib/rulestead/fake.ex:1)):
```elixir
defmodule Rulestead.Fake do
  @moduledoc false
  use GenServer

  alias Rulestead.{
    Admin.Lifecycle,
    Flag,
    Store,
    StoreError
  }
```

**List pipeline mirrors Ecto** ([lines 649-668](../../../../rulestead/lib/rulestead/fake.ex:649)):
```elixir
with_list_environment(state, command.environment_key, fn environment_filter ->
  entries =
    state.flags
    |> Map.values()
    |> Enum.flat_map(&list_entries_for_flag(&1, state.environments, environment_filter))
    |> Enum.reject(fn entry -> archived?(entry.flag) and not command.include_archived? end)
    |> Enum.filter(&matches_query?(&1, command.query))
    |> Enum.map(&build_list_entry(state, &1))
    |> maybe_filter_owner(command.owner)
    |> maybe_filter_tags(command.tags)
    |> maybe_filter_lifecycle(command.lifecycle)
    |> maybe_filter_stale(command.stale)
end)
```

**Decorator and lifecycle parity** ([lines 4196-4243](../../../../rulestead/lib/rulestead/fake.ex:4196)):
```elixir
defp decorate_payload(payload, state, flag, environment, flag_environment) do
  environment_cards = environment_cards(state, flag)

  payload
  |> Map.put(:lifecycle, lifecycle(flag, flag_environment))
  |> Map.put(:environment_cards, environment_cards)
  |> Map.put(:environment_status, flag_environment.status)
  |> Map.put(:environment_key, environment.key)
end
```

Mirror every new readiness field and filter here. Planner should treat Ecto/Fake parity as mandatory, not follow-up work.

---

### `rulestead/priv/repo/migrations/20260523130000_create_rulestead_code_reference_scans.exs` (migration, persistence)

**Analog:** `rulestead/priv/repo/migrations/20260516193701_create_rulestead_code_references.exs`

**Table creation pattern** ([lines 1-13](../../../../rulestead/priv/repo/migrations/20260516193701_create_rulestead_code_references.exs:1)):
```elixir
def change do
  create table(:code_references, primary_key: false) do
    add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
    ...
    timestamps(type: :utc_datetime_usec)
  end
```

Follow the same migration style: one focused table, explicit timestamps, and only the columns needed to prove latest successful scan freshness. Avoid schema sprawl or any computed readiness persistence.

---

### `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` (test, request-response)

**Analog:** `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs`

**Authorized request setup** ([lines 8-27](../../../../rulestead/test/rulestead/webhooks/code_refs_plug_test.exs:8)):
```elixir
conn(:post, "/api/webhooks/rulestead/code_refs", payload)
|> put_req_header("authorization", "Bearer test_secret_token")
|> put_req_header("content-type", "application/json")
|> CodeRefsPlug.call(@opts)
```

**Validation pattern** ([lines 46-75](../../../../rulestead/test/rulestead/webhooks/code_refs_plug_test.exs:46)):
```elixir
assert conn.status == 200
assert Jason.decode!(conn.resp_body)["count"] == 1
assert Repo.aggregate(CodeReference, :count) == 1
```

Extend this existing test module instead of creating a parallel webhook suite. Add cases for empty successful scans advancing the receipt and malformed or unauthorized payloads leaving the receipt unchanged.

---

### `rulestead/lib/mix/tasks/rulestead.lifecycle.ex` (utility, request-response)

**Analog:** `rulestead/lib/mix/tasks/rulestead.promote.ex`

**Task structure and parsing** ([lines 1-25](../../../../rulestead/lib/mix/tasks/rulestead.promote.ex:1)):
```elixir
defmodule Mix.Tasks.Rulestead.Promote do
  use Mix.Task
  @switches [source: :string, target: :string, file: :string, out: :string, format: :string, ...]

  def run(args) do
    Mix.Task.run("app.start")
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate_args!(opts, argv, invalid)
```

**Validation and usage errors** ([lines 63-97](../../../../rulestead/lib/mix/tasks/rulestead.promote.ex:63)):
```elixir
defp validate_args!(opts, argv, invalid) do
  if argv != [] or invalid != [] do
    Mix.raise("usage: ...")
  end

  if Keyword.get(opts, :plan) do
    unless Keyword.get(opts, :source), do: Mix.raise("...")
  end
end
```

**Text vs JSON rendering** ([lines 116-120](../../../../rulestead/lib/mix/tasks/rulestead.promote.ex:116)):
```elixir
defp emit(result, "json"), do: IO.write(Render.render_json(result) <> "\n")
defp emit(result, _other), do: Mix.shell().info(Render.render_text(result))
```

Use `rulestead.code_refs.ex` for the simpler read-only shell messaging style if needed, but copy text/json contract behavior from `rulestead.promote.ex`.

---

### `rulestead/test/rulestead/admin_lifecycle_test.exs` (test, transform)

**Analog:** `rulestead/test/rulestead/admin_lifecycle_test.exs`

**Classifier assertions** ([lines 41-76](../../../../rulestead/test/rulestead/admin_lifecycle_test.exs:41)):
```elixir
assert %{state: :active, mode: :permanent} =
         Lifecycle.classify(flag, %{status: :active, last_evaluated_at: ...}, now: now, ...)

assert %{state: :potentially_stale} = Lifecycle.classify(flag, %{status: :active, last_evaluated_at: nil}, now: now)
assert %{state: :archived} = Lifecycle.classify(flag, %{status: :archived, last_evaluated_at: now}, now: now)
```

**Advisory-only contract checks** ([lines 161-189](../../../../rulestead/test/rulestead/admin_lifecycle_test.exs:161)):
```elixir
overridden = LifecycleDefaults.suggest(:permission, authored_mode: :expiring, ...)
assert overridden.default_overridden
refute Map.has_key?(overridden, :state)
refute Map.has_key?(overridden, :archive_ready)
```

Extend this file for readiness categories, evidence quality, unknowns, blockers, and recommendation withholding.

---

### `rulestead/test/rulestead/store_ecto_admin_test.exs` (test, request-response)

**Analog:** `rulestead/test/rulestead/store_ecto_admin_test.exs`

**Setup with deterministic classifier clock** ([lines 8-30](../../../../rulestead/test/rulestead/store_ecto_admin_test.exs:8)):
```elixir
Application.put_env(:rulestead, :admin_lifecycle,
  warning_after_seconds: 1_800,
  stale_after_seconds: 3_600,
  now: ~U[2026-04-23 16:00:00Z]
)
```

**List/detail payload assertions** ([lines 83-122](../../../../rulestead/test/rulestead/store_ecto_admin_test.exs:83)):
```elixir
assert {:ok, %Command.Page{} = page} = StoreEcto.list_flags(Command.ListFlags.new(...))
assert [%{flag: %{key: "checkout-redesign"}, lifecycle: %{state: :active}}] = page.entries

assert {:ok, detail} = StoreEcto.fetch_flag(...)
assert detail.lifecycle.state == :active
assert detail.recent_owners == ["growth", "ops"]
```

Use this file for readiness payload presence plus new filter semantics.

---

### `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` (test, request-response)

**Analog:** `rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs`

**Task-module unit entrypoints** ([lines 36-73](../../../../rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs:36)):
```elixir
assert {:ok, result} = Promote.compute_plan("staging", "test", tenant_key: "acme")
assert result["status"] == "changes"
assert Result.exit_code(result) == 2
```

**Environment setup for Mix task tests** ([lines 9-34](../../../../rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs:9)):
```elixir
Rulestead.Fake.Control.ensure_started()
Rulestead.Fake.Control.reset!()
Application.put_env(:rulestead, :store, Fake)
```

Copy this test style for `compute/1`-style pure helpers and deterministic CLI contract assertions.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` (component, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`

**URL-driven filters** ([lines 29-58](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex:29)):
```elixir
def handle_params(params, uri, socket) do
  merged_params = Map.merge(query_params(uri), stringify_keys(params))
  filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
  current_path = path_with_query(uri)
  canonical_path = build_index_path(socket.assigns.base_path, filters)

  if canonical_path != current_path do
    {:noreply, push_patch(socket, to: canonical_path)}
  else
    ...
  end
end
```

**Filter form and read-only list surface** ([lines 85-175](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex:85)):
```elixir
<form aria-label="Flag filters" phx-change="filters_changed" class="rs-filter-grid">
  <select name="filters[lifecycle]">...</select>
  <select name="filters[stale]">...</select>
</form>

<tbody id="flags" phx-update="stream">
  <tr :for={{dom_id, entry} <- @streams.flags} ...>
    <td><FlagComponents.lifecycle_badge state={entry.lifecycle} /></td>
    <td><FlagComponents.stale_badge state={stale_state(entry.lifecycle)} ... /></td>
  </tr>
</tbody>
```

**Filter normalization and command mapping** ([lines 199-275](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex:199)):
```elixir
defp list_opts(filters) do
  [
    environment_key: filters["env"],
    lifecycle: maybe_atom(filters["lifecycle"]),
    stale: maybe_atom(filters["stale"]),
    include_archived?: filters["include_archived"] == "true",
    limit: String.to_integer(filters["limit"])
  ]
end
```

Add readiness/evidence-quality filters here by following the same `normalize_filters` -> `build_index_path` -> `list_opts` flow.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` (component, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

**Detail loading and error handling** ([lines 23-36](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:23), [216-230](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:216)):
```elixir
def handle_params(params, uri, socket) do
  ...
  socket
  |> assign(:flag_key, key)
  |> assign(:current_path, Session.current_path(socket, base_path))
  |> assign(:env_links, Session.env_links(socket, base_path))
  |> load_detail(key, env)
end

defp load_detail(socket, key, env) do
  case Rulestead.fetch_flag(key, env) do
    {:ok, detail} -> assign(socket, :detail, detail) |> assign(:error_message, nil)
    {:error, error} -> socket |> assign(:detail, nil) |> assign(:error_message, error.message)
  end
end
```

**Lifecycle card style** ([lines 94-118](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:94)):
```elixir
<FlagComponents.section_card title="Lifecycle">
  <p>
    <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
    <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
    <span>Owner: <%= @detail.lifecycle.owner %></span>
  </p>
  <p>Lifecycle posture: <%= humanize(@detail.lifecycle.mode) %></p>
  <p>Review by: <%= @detail.lifecycle.review_by || "Not scheduled" %></p>
</FlagComponents.section_card>
```

Use this screen’s section-card pattern for reasons, unknowns, blockers, and next-action explanation.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` (component, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`

**Capability gate and read-surface loading** ([lines 27-45](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex:27)):
```elixir
def handle_params(%{"key" => key}, uri, socket) do
  capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

  if not capabilities.edit? and not capabilities.execute? and not capabilities.admin? do
    {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
  else
    ...
    |> load_detail(key, env)
    |> load_code_references(key)
  end
end
```

**Current code-reference loading seam** ([lines 144-156](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex:144)):
```elixir
defp load_code_references(socket, key) do
  if Code.ensure_loaded?(Rulestead.Repo) do
    try do
      query = from(c in Rulestead.CodeRefs.CodeReference, where: c.flag_key == ^key, order_by: [asc: c.file, asc: c.line])
      refs = Rulestead.Repo.all(query)
      assign(socket, :code_references, refs)
    rescue
      _ -> assign(socket, :code_references, [])
    end
  else
    assign(socket, :code_references, [])
  end
end
```

**Important boundary** ([lines 103-127](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex:103)):
```elixir
def handle_event("archive", params, socket) do
  ...
  Rulestead.archive_flag(...)
end
```

Use this file as the mutation-boundary reference. Phase 36 may deepen the read-only advisory view, but should not widen the existing archive action surface.

---

### `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` (component, transform)

**Analog:** `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`

**Badge component pattern** ([lines 6-25](../../../../rulestead_admin/lib/rulestead_admin/components/flag_components.ex:6)):
```elixir
attr :state, :any, required: true

def lifecycle_badge(assigns) do
  assigns =
    assign(assigns,
      label: assigns.state |> normalize_state() |> humanize_state(),
      tone: assigns.state |> normalize_state() |> state_tone()
    )
```

**Freshness badge pattern** ([lines 28-45](../../../../rulestead_admin/lib/rulestead_admin/components/flag_components.ex:28)):
```elixir
attr :state, :any, required: true
attr :last_evaluated_at, :any, default: nil

def stale_badge(assigns) do
  state = normalize_state(assigns.state)
  assigns = assign(assigns, label: if(state == :fresh, do: "Fresh", else: humanize_state(state)))
```

**Tone vocabulary** ([lines 143-176](../../../../rulestead_admin/lib/rulestead_admin/components/flag_components.ex:143)):
```elixir
@known_states %{"active" => :active, "fresh" => :fresh, "potentially_stale" => :potentially_stale, "stale" => :stale, ...}
defp state_tone(:active), do: "positive"
defp state_tone(:potentially_stale), do: "warning"
defp state_tone(:stale), do: "critical"
defp state_tone(_state), do: "neutral"
```

Add new readiness/evidence-quality badges here rather than rendering raw text in each LiveView.

---

### `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` (test, request-response)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`

**Shared setup** ([lines 12-78](../../../../rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs:12)):
```elixir
Application.put_env(:rulestead, :store, Rulestead.Fake)
Application.put_env(:rulestead, :admin_lifecycle, ...)
Control.reset!(now: now)
Control.set_now!(now)
conn = Phoenix.ConnTest.init_test_session(conn, %{...})
```

**URL-state assertions** ([lines 97-165](../../../../rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs:97)):
```elixir
view
|> form("form[aria-label='Flag filters']", %{"filters" => %{...}})
|> render_change()

path = assert_patch(view)
assert path =~ "lifecycle=potentially_stale"
assert path =~ "stale=potentially_stale"
```

Extend this test with readiness/evidence filters and badge rendering, keeping query-string assertions explicit.

---

### `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` (test, request-response)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`

**Detail-page content assertions** ([lines 93-110](../../../../rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs:93)):
```elixir
{:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")
assert html =~ "Lifecycle"
assert html =~ "Active"
assert html =~ "Lifecycle posture"
```

**Policy-sensitive rendering** ([lines 129-159](../../../../rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs:129)):
```elixir
Application.put_env(:rulestead, :admin_policy, AuditRestrictedPolicy)
{:ok, _view, html} = live(restricted_conn, "/admin/flags/checkout-redesign?env=prod")
assert html =~ "Kill switch active"
refute html =~ "incident bridge"
```

Use this file for reasons/unknowns/blockers visibility and copy-tone assertions.

---

### `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` (test, request-response)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`

**Validation-flow assertions** ([lines 85-99](../../../../rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs:85)):
```elixir
{:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/cleanup?env=prod")
assert view |> element("form") |> render_submit(%{"confirmation" => "wrong", "reason" => "Cleaning up"}) =~
         "Type the exact flag key to confirm this production action."
```

Treat this file as the cautionary baseline: Phase 36 should add advisory assertions on the cleanup page, but should not add more mutation paths.

## Shared Patterns

### Shared Projection Seam
**Sources:** `rulestead/lib/rulestead/store/ecto.ex` [4215-4255](../../../../rulestead/lib/rulestead/store/ecto.ex:4215), `rulestead/lib/rulestead/fake.ex` [4196-4243](../../../../rulestead/lib/rulestead/fake.ex:4196)
**Apply to:** All payload-producing core/store changes
```elixir
payload
|> Map.put(:lifecycle, lifecycle(flag, flag_environment))
|> Map.put(:environment_cards, environment_cards)
|> Map.put(:environment_status, flag_environment.status)
```

Compute once in the shared decorator, then let LiveView and Mix task consume the same payload.

### Freshness Evidence Inputs
**Sources:** `rulestead/lib/rulestead/admin/stale_tracker.ex` [45-77](../../../../rulestead/lib/rulestead/admin/stale_tracker.ex:45), `rulestead/lib/rulestead/telemetry/cache.ex` [20-56](../../../../rulestead/lib/rulestead/telemetry/cache.ex:20), `rulestead/lib/rulestead/code_refs/code_reference.ex` [9-24](../../../../rulestead/lib/rulestead/code_refs/code_reference.ex:9)
**Apply to:** Lifecycle/readiness classification
```elixir
GenServer.cast(tracker, {:record, flag_key, environment_key, recorded_at})

:ets.insert(@table, {{key, :last_evaluated_at}, timestamp})

schema "code_references" do
  field(:flag_key, :string)
  field(:file, :string)
  field(:line, :integer)
end
```

Evaluation and code-ref evidence are already bounded inputs. Reuse them; do not add new persistence or background recompute.

### LiveView URL-State Pattern
**Source:** `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` [29-58](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex:29)
**Apply to:** Any new readiness/evidence-quality filters in mounted admin
```elixir
filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
canonical_path = build_index_path(socket.assigns.base_path, filters)
if canonical_path != current_path, do: {:noreply, push_patch(socket, to: canonical_path)}
```

Filter state belongs in URL params, not ephemeral assigns.

### Read-Only CLI Contract
**Sources:** `rulestead/lib/mix/tasks/rulestead.promote.ex` [21-49](../../../../rulestead/lib/mix/tasks/rulestead.promote.ex:21), `rulestead/lib/mix/tasks/rulestead.promote.ex` [116-120](../../../../rulestead/lib/mix/tasks/rulestead.promote.ex:116)
**Apply to:** `mix rulestead.lifecycle`
```elixir
Mix.Task.run("app.start")
{opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
emit(envelope, Keyword.get(opts, :format, "text"))
```

JSON should be the canonical machine contract; text should be a renderer over the same result envelope.

### Capability / Mutation Boundary
**Source:** `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` [27-45](../../../../rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex:27)
**Apply to:** Admin advisory surfaces that sit near dangerous actions
```elixir
capabilities = socket.assigns.rulestead_admin_policy_state.capabilities
if not capabilities.edit? and not capabilities.execute? and not capabilities.admin? do
  {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
end
```

Keep Phase 36 advisory and read-only even when rendered beside an existing destructive flow.

## No Analog Found

None. Every strongly implied Phase 36 file has a current in-repo analog or an exact file to extend.

## Metadata

**Analog search scope:** `rulestead/lib/`, `rulestead/test/`, `rulestead_admin/lib/`, `rulestead_admin/test/`, `prompts/`, `.planning/phases/36-*`
**Files scanned:** 19
**Pattern extraction date:** 2026-05-23
