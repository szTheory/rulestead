# Phase 6: Admin UI - Flag List, Detail, Rule Editor, Environments, Lifecycle - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 15
**Analogs found:** 12 / 15

## Reusable Assets

- `rulestead_admin/lib/rulestead_admin/router.ex` already defines the mount macro seam Phase 6 should extend rather than replace with installer-only string injection.
- `rulestead/lib/rulestead/live_view.ex` is the closest existing "explicit Phoenix seam" analog: route/socket input normalized locally, then delegated into stable core APIs.
- `rulestead/lib/rulestead/store/ecto.ex` and `rulestead/lib/rulestead/fake.ex` already expose the admin-facing authored payload shape: `flag`, `environment`, `flag_environment`, `active_ruleset`, `draft_rulesets`.
- `rulestead/lib/rulestead.ex` already wraps authoring mutations with telemetry and public bang/non-bang entrypoints; admin workflows should compose these verbs instead of reaching into adapters.
- `rulestead/test/support/store_contract_case.ex` and `rulestead/test/support/store_fixtures.ex` are the strongest existing cross-adapter test pattern for any new admin-facing core contract.
- `rulestead/lib/rulestead/install.ex` plus its tests establish the host-app seam expectation: compile-safe router macro, single mount line, and installer assertions that verify generated host wiring.

## Established Patterns

- Phoenix seams are explicit and local. Normalize framework input near the boundary, then pass plain maps/structs into `Rulestead` APIs.
- Host integration uses compile-safe router macros, not runtime magic. Installer tests assert source injection and mount strings directly.
- Core authoring flows are draft-first and command-driven: save draft, publish specific/latest draft, archive flag.
- Real and fake adapters are expected to expose the same serialized payload shape. Planner should treat fake parity as a release gate for admin-facing store additions.
- Tests prefer deterministic, package-local seams over full framework boot unless the behavior specifically requires a mounted host app.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead_admin/lib/rulestead_admin/router.ex` | route | request-response | `rulestead_admin/lib/rulestead_admin/router.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/*.ex` | liveview | request-response | `rulestead/lib/rulestead/live_view.ex` | partial-match |
| `rulestead_admin/lib/rulestead_admin/components/*.ex` | component | transform | `rulestead/lib/rulestead/live_view.ex` | partial-match |
| `rulestead_admin/lib/rulestead_admin/policy.ex` or equivalent seam module | behaviour/utility | request-response | `rulestead/lib/rulestead/store.ex` | role-match |
| `rulestead_admin/mix.exs` | config | request-response | `rulestead_admin/mix.exs` | exact |
| `rulestead_admin/test/rulestead_admin/router_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/router_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/*_test.exs` | test | request-response | `rulestead/test/rulestead/live_view_test.exs` | role-match |
| `rulestead_admin/test/support/*` | test | request-response | `rulestead/test/support/store_contract_case.ex` | partial-match |
| `rulestead/lib/rulestead/store/command.ex` | service | CRUD | `rulestead/lib/rulestead/store/command.ex` | exact |
| `rulestead/lib/rulestead/store.ex` | behaviour | CRUD | `rulestead/lib/rulestead/store.ex` | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | `rulestead/lib/rulestead/store/ecto.ex` | exact |
| `rulestead/lib/rulestead/fake.ex` | service | CRUD | `rulestead/lib/rulestead/fake.ex` | exact |
| `rulestead/lib/rulestead/flag.ex` | model | CRUD | `rulestead/lib/rulestead/flag.ex` | exact |
| `rulestead/lib/rulestead/flag_environment.ex` | model | CRUD | `rulestead/lib/rulestead/flag_environment.ex` | exact |
| `rulestead/lib/rulestead.ex` | facade | request-response | `rulestead/lib/rulestead.ex` | exact |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/router.ex` and mounted admin routes (route, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/router.ex`

Keep the admin package mountable through a small macro seam that expands safely inside the host router.

**Macro import pattern** ([rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:4), lines 4-7):
```elixir
defmacro __using__(_opts) do
  quote do
    import RulesteadAdmin.Router, only: [rulestead_admin: 1, rulestead_admin: 2]
  end
end
```

**Compile-safe scope pattern** ([rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:10), lines 10-16):
```elixir
defmacro rulestead_admin(path, opts \\ []) do
  quote bind_quoted: [path: path, opts: opts] do
    _ = opts

    scope path, as: :rulestead_admin do
    end
  end
end
```

**Router seam test pattern** ([rulestead_admin/test/rulestead_admin/router_test.exs](/Users/jon/projects/rulestead/rulestead_admin/test/rulestead_admin/router_test.exs:17), lines 17-28):
```elixir
mount_ast =
  quote do
    RulesteadAdmin.Router.rulestead_admin("/flags", [])
  end
  |> Macro.expand(__ENV__)

rendered = Macro.to_string(mount_ast)

assert rendered =~ "scope(path, as: :rulestead_admin)"
refute rendered =~ "raise"
```

**Planner note:** Phase 6 should keep this as the single mount seam and expand it to `live_session`/`live` routes plus policy hooks. Do not move route generation into the installer or require host apps to copy route definitions manually.

---

### Admin LiveViews and components under `rulestead_admin/lib/rulestead_admin/live/*` (liveview/component, request-response)

**Analog:** `rulestead/lib/rulestead/live_view.ex`

Use the same explicit seam pattern: read socket/params/session locally, normalize once, delegate to stable APIs.

**Boundary-local context resolution** ([rulestead/lib/rulestead/live_view.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/live_view.ex:27), lines 27-32):
```elixir
@spec context_from_socket(map(), keyword()) :: Context.t()
def context_from_socket(socket, opts \\ []) when is_map(socket) and is_list(opts) do
  socket
  |> base_context(opts)
  |> merge_context(socket_attrs(socket, opts))
end
```

**Handle-explicit-options pattern** ([rulestead/lib/rulestead/live_view.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/live_view.ex:77), lines 77-82):
```elixir
defp resolve_context(socket, opts) do
  case Keyword.get(opts, :context) do
    %Context{} = context -> Context.normalize(context)
    nil -> context_from_socket(socket, opts)
    context -> Context.normalize(context)
  end
end
```

**Projection-through-facade pattern** ([rulestead/lib/rulestead/live_view.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/live_view.ex:85), lines 85-106):
```elixir
defp resolve_projection(environment_key, context, {:enabled, flag_key}) do
  unwrap_runtime!(:enabled?, Runtime.enabled?(environment_key, flag_key, context), flag_key)
end

defp resolve_projection(environment_key, context, {:evaluate, flag_key}) do
  unwrap_runtime!(:evaluate, Runtime.evaluate(environment_key, flag_key, context), flag_key)
end
```

**Planner note:** admin LiveViews should use `mount/3` + `handle_params/3` for URL-backed `env`, search, filter, and pagination state. They should call `Rulestead.list_flags/1`, `Rulestead.fetch_flag/3`, `Rulestead.save_draft_ruleset/1`, and `Rulestead.publish_ruleset/1` rather than talking to `Rulestead.Store.Ecto` directly.

---

### Core admin mutations in `rulestead/lib/rulestead.ex` and new admin-facing facades (facade, request-response)

**Analog:** `rulestead/lib/rulestead.ex`

Keep admin UI mutations on the public facade with telemetry-wrapped bang/non-bang pairs.

**Telemetry-wrapped mutation pattern** ([rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:67), lines 67-79):
```elixir
@spec save_draft_ruleset(Command.SaveDraftRuleset.t()) :: Store.result(map())
def save_draft_ruleset(%Command.SaveDraftRuleset{} = command) do
  Telemetry.span(
    [:rulestead, :admin, :mutation],
    Telemetry.metadata(
      Telemetry.command_metadata(command, %{operation: "save_draft_ruleset", audit_action: "save_draft_ruleset"})
    ),
    fn ->
      result = run_store(:save_draft_ruleset, [command], command)
      {result, admin_stop_metadata(result, command)}
    end
  )
end
```

**Bang/non-bang pairing pattern** ([rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:111), lines 111-143):
```elixir
@spec publish_ruleset!(Command.PublishRuleset.t()) :: map()
def publish_ruleset!(%Command.PublishRuleset{} = command) do
  command
  |> publish_ruleset()
  |> unwrap!()
end

@spec archive_flag!(Command.ArchiveFlag.t()) :: map()
def archive_flag!(%Command.ArchiveFlag{} = command) do
  command
  |> archive_flag()
  |> unwrap!()
end
```

**List facade pattern** ([rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:145), lines 145-171):
```elixir
@spec list_flags(Command.ListFlags.t()) :: Store.result([map()])
def list_flags(%Command.ListFlags{} = command) do
  run_store(:list_flags, [command], command)
end

@spec list_flags!() :: [map()]
@spec list_flags!(Command.ListFlags.t()) :: [map()]
def list_flags!(command \\ Command.ListFlags.new()) do
  command
  |> list_flags()
  |> unwrap!()
end
```

**Planner note:** if Phase 6 needs new authoring verbs like create/update flag metadata, add them beside these facades first, then implement both adapters. Do not make the UI depend on adapter-private helpers.

---

### Store command and behavior additions for list/detail/editor flows (service/behaviour, CRUD)

**Analogs:** `rulestead/lib/rulestead/store.ex`, `rulestead/lib/rulestead/store/command.ex`

Follow the existing key-first command pattern. Keep selectors on `flag_key`/`environment_key`, not internal IDs.

**Behavior contract pattern** ([rulestead/lib/rulestead/store.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store.ex:10), lines 10-17):
```elixir
@callback fetch_flag(Command.FetchFlag.t()) :: result(map())
@callback fetch_snapshot(Command.FetchSnapshot.t()) :: result(map())
@callback save_draft_ruleset(Command.SaveDraftRuleset.t()) :: result(map())
@callback publish_ruleset(Command.PublishRuleset.t()) :: result(map())
@callback archive_flag(Command.ArchiveFlag.t()) :: result(map())
@callback list_flags(Command.ListFlags.t()) :: result([map()])
```

**Command struct pattern** ([rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:51), lines 51-74):
```elixir
@enforce_keys [:flag_key, :environment_key, :ruleset]
defstruct [:flag_key, :environment_key, :ruleset, actor: nil, metadata: %{}]

@spec new(String.t() | atom(), String.t() | atom(), map(), keyword()) :: t()
def new(flag_key, environment_key, ruleset, opts \\ []) when is_map(ruleset) do
  %__MODULE__{
    flag_key: flag_key,
    environment_key: environment_key,
    ruleset: ruleset,
    actor: Keyword.get(opts, :actor),
    metadata: Keyword.get(opts, :metadata, %{})
  }
end
```

**Filter command pattern** ([rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:127), lines 127-156):
```elixir
defstruct environment_key: nil,
          query: nil,
          include_archived?: false,
          limit: 50,
          offset: 0,
          sort: :flag_key
```

**Planner note:** extend this command family for Phase 6 filters and metadata updates instead of inventing ad hoc parameter maps in LiveViews. Current `ListFlags` is too small for lifecycle state, owner, stale status, and URL-backed quick filters.

---

### Store payload serialization in `rulestead/lib/rulestead/store/ecto.ex` and `rulestead/lib/rulestead/fake.ex` (service, CRUD)

**Analogs:** `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`

The admin UI should consume the authored payload shape already produced by both adapters.

**Canonical authored payload shape** ([rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:368), lines 368-380):
```elixir
defp build_flag_payload(flag, environment, flag_environment, include_ruleset?) do
  %{
    flag: flag_summary(flag),
    environment: environment_summary(environment),
    flag_environment: flag_environment_summary(flag_environment),
    active_ruleset:
      if(include_ruleset?, do: active_ruleset_payload(flag_environment), else: nil),
    draft_rulesets:
      if(include_ruleset?,
        do: draft_ruleset_payloads(flag_environment),
        else: []
      )
  }
end
```

**List row payload pattern** ([rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:445), lines 445-451):
```elixir
defp entry_to_payload(entry) do
  %{
    flag: flag_summary(entry.flag),
    environment: environment_summary(entry.environment),
    flag_environment: flag_environment_summary(entry.flag_environment),
    active_ruleset: active_ruleset_payload(entry.flag_environment)
  }
end
```

**Adapter parity pattern** ([rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:735), lines 735-749):
```elixir
defp build_flag_payload(flag, environment, flag_environment, include_ruleset?) do
  %{
    flag: flag_summary(flag),
    environment: environment,
    flag_environment: flag_environment_summary(flag_environment),
    active_ruleset:
      if(include_ruleset?,
        do:
          active_ruleset_payload(flag, environment.key, flag_environment.active_ruleset_version)
      ),
    draft_rulesets:
      if(include_ruleset?,
        do: draft_ruleset_payloads(flag, environment.key),
        else: []
      )
  }
end
```

**Planner note:** new lifecycle/admin fields must be added to both serializers in the same phase. The fake is not optional; Phase 6 tests should fail if the admin package depends on fields only Ecto exposes.

---

### List filtering and search for `/admin/flags` (service, CRUD)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

Keep list filters explicit in the store query layer; avoid post-query filtering in LiveViews.

**Environment/archive/search filter pattern** ([rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:542), lines 542-568):
```elixir
defp maybe_filter_environment(query, nil), do: query

defp maybe_filter_environment(query, environment_key),
  do: where(query, [_, _, env], env.key == ^environment_key)

defp maybe_filter_archived(query, false),
  do: where(query, [flag, _, _], is_nil(flag.archived_at))

defp maybe_filter_query(query, search) do
  normalized = "%" <> String.downcase(String.trim(to_string(search))) <> "%"

  where(
    query,
    [flag, _, _],
    ilike(flag.key, ^normalized) or
      ilike(fragment("coalesce(?, '')", flag.description), ^normalized)
  )
end
```

**Planner note:** add owner/lifecycle/stale filters here, not in the LiveView. The current API supports environment + text + archived + basic sort only, so planner should reserve core work before the Phase 6 list UI can fully satisfy `ADMIN-01` and `LIFE-02..03`.

---

### Schema validation for lifecycle fields and rule editor payloads (model, CRUD)

**Analogs:** `rulestead/lib/rulestead/flag.ex`, `rulestead/lib/rulestead/ruleset.ex`, `rulestead/lib/rulestead/ruleset/rule.ex`

Use schema-driven validation and normalized strings, not UI-only validation.

**Flag normalization and required-field pattern** ([rulestead/lib/rulestead/flag.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/flag.ex:35), lines 35-53):
```elixir
flag
|> cast(attrs, [
  :key,
  :description,
  :flag_type,
  :value_type,
  :default_value,
  :owner,
  :expected_expiration,
  :tags,
  :archived_at
])
|> update_change(:key, &normalize_key/1)
|> update_change(:owner, &normalize_string/1)
|> update_change(:tags, &normalize_tags/1)
|> validate_required([:key, :flag_type, :value_type, :default_value, :owner])
```

**Published/draft state invariant pattern** ([rulestead/lib/rulestead/ruleset.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset.ex:48), lines 48-61):
```elixir
case status do
  :published when published_at == nil ->
    add_error(changeset, :published_at, "must be present for published rulesets")

  :draft when published_at != nil ->
    add_error(changeset, :published_at, "must be empty for draft rulesets")

  _status ->
    changeset
end
```

**Nested rule validation pattern** ([rulestead/lib/rulestead/ruleset/rule.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/rule.ex:31), lines 31-45):
```elixir
rule
|> cast(attrs, [:key, :name, :description, :strategy, :value, :audience_id, :audience_key])
|> update_change(:key, &normalize_string/1)
|> update_change(:name, &normalize_string/1)
|> update_change(:description, &normalize_string/1)
|> update_change(:audience_key, &normalize_string/1)
|> cast_embed(:conditions, with: &Condition.changeset/2)
|> cast_embed(:variants, with: &Variant.changeset/2)
|> cast_embed(:rollout, with: &Rollout.changeset/2)
|> validate_required([:key, :strategy])
|> validate_rule_shape()
```

**Planner note:** Phase 6 should put lifecycle correctness in core schemas and store commands, then let the UI render errors from typed core validation. Current schema requires `owner` but does not enforce "expiration or permanent" yet.

---

### Testing patterns for a mountable admin package (test, request-response)

**Analogs:** `rulestead/test/rulestead/live_view_test.exs`, `rulestead/test/support/store_contract_case.ex`, `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs`, `rulestead/test/rulestead/integration/install_smoke_test.exs`

Phase 6 needs three layers of tests, each already implied by existing patterns.

**Package-local seam test pattern** ([rulestead/test/rulestead/live_view_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/live_view_test.exs:23), lines 23-57):
```elixir
context =
  LiveView.context_from_socket(
    socket,
    actor: {:assign, :current_actor},
    environment: {:assign, :current_environment},
    tenant_key: {:assign, :tenant_key},
    request_id: {:assign, :request_id},
    session_id: {:session, "session_id"},
    attributes: {:assign, :rulestead_attributes},
    session: %{"targeting_key" => " user-2 ", "session_id" => " socket-session "}
  )
```

**Fake-backed contract test pattern** ([rulestead/test/support/store_contract_case.ex](/Users/jon/projects/rulestead/rulestead/test/support/store_contract_case.ex:20), lines 20-35):
```elixir
setup do
  previous_store = Application.get_env(:rulestead, :store)
  @store_control.ensure_started()
  @store_control.reset!()
  Application.put_env(:rulestead, :store, @store_module)

  on_exit(fn ->
    @store_control.reset!()
    ...
  end)

  :ok
end
```

**Installer-host seam assertion pattern** ([rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:196), lines 196-202):
```elixir
router = File.read!(Path.join(tmp_dir, "lib/my_app_web/router.ex"))
assert router =~ "use RulesteadAdmin.Router"
assert router =~ ~s(rulestead_admin "/flags")
```

**Mounted-host smoke pattern** ([rulestead/test/rulestead/integration/install_smoke_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/install_smoke_test.exs:21), lines 21-38):
```elixir
config_config = File.read!(Path.join(app_dir, "config/config.exs"))
endpoint = File.read!(Path.join(app_dir, "lib/host_app_web/endpoint.ex"))
router = File.read!(Path.join(app_dir, "lib/host_app_web/router.ex"))

assert endpoint =~ "plug Rulestead.Plug"
assert router =~ "use RulesteadAdmin.Router"
assert router =~ ~s(rulestead_admin "/flags")
```

**Planner note:** for Phase 6, add admin-package tests in this order:
1. router macro expansion tests
2. package-local LiveView tests against fake-backed core APIs
3. one mounted-host smoke test proving the package boots inside a Phoenix app in the monorepo shape

## Shared Patterns

### Host Router Seam
**Sources:** [rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:4), [rulestead/lib/rulestead/install.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install.ex:30)

Phase 6 routes should remain consumable as:
```elixir
scope "/admin", MyAppWeb do
  pipe_through :browser
  rulestead_admin "/flags"
end
```

### Draft/Publish Authoring Boundary
**Sources:** [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:67), [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:44)

Apply to all admin editing flows:
```elixir
Rulestead.save_draft_ruleset(command)
Rulestead.publish_ruleset(command)
```

The UI should never mutate `active_ruleset` directly.

### Shared Payload Shape Across Adapters
**Sources:** [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:368), [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:735)

Apply to list/detail/editor loaders:
```elixir
%{
  flag: ...,
  environment: ...,
  flag_environment: ...,
  active_ruleset: ...,
  draft_rulesets: ...
}
```

### Typed Validation and Error Surfacing
**Sources:** [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:570), [rulestead/lib/rulestead/ruleset/rule.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/rule.ex:47)

Core should return typed ruleset/store errors with nested details; the admin package should render them instead of duplicating validation logic client-side.

## Planner Notes

### Foundational Core/Admin Contracts Phase 6 Must Add Before Screens

1. `rulestead_admin` does not yet depend on Phoenix, Phoenix LiveView, or Phoenix HTML in [rulestead_admin/mix.exs](/Users/jon/projects/rulestead/rulestead_admin/mix.exs:1). The planner should treat package runtime/test bootstrapping as prerequisite work, not incidental page polish.
2. There is no current `Rulestead.Admin.Policy` seam in the inspected code. `ADMIN-10` and future auth requirements need a core/admin behavior contract before mounted routes can enforce host-owned authorization.
3. `Rulestead.Flag` currently supports `owner` and `expected_expiration` but has no explicit permanent-state field or invariant enforcing "expiration or permanent" ([rulestead/lib/rulestead/flag.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/flag.ex:20)). Phase 6 needs a foundational lifecycle contract first.
4. `Rulestead.Store.Command.ListFlags` only supports `environment_key`, text `query`, `include_archived?`, `limit`, `offset`, and basic sort ([rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:127)). `ADMIN-01` needs owner, lifecycle, stale-status, and possibly tags filters added in core.
5. Current serialized payloads expose `owner`, `expected_expiration`, `archived_at`, `flag_environment.status`, and `last_published_at`, but they do not expose lifecycle-derived fields like `permanent?`, `lifecycle_state`, `stale?`, `potentially_stale?`, or `last_changed_by`.
6. Current search only matches `flag.key` and `flag.description` in Ecto/fake adapters. Planner should budget core query changes before promising list filters by owner/tags/stale state.
7. There is no core create/update flag metadata command in the inspected public facade. If Phase 6 includes create/edit flows for description, owner, expiration, tags, or type metadata, new facade + command + adapter work must land ahead of LiveView forms.
8. The current per-environment model is enough for environment switching, but there is no explicit "production is visually dangerous" contract in code. That is a UI concern and should stay in admin package presentation, not leak into store semantics.
9. Audit timeline is still a placeholder at this phase boundary. Planner should keep any detail-page timeline implementation shallow or stubbed rather than inventing undocumented audit contracts early.

## Likely New/Modified Files

- `rulestead_admin/lib/rulestead_admin/router.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_index_live.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_show_live.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_rules_live.ex`
- `rulestead_admin/lib/rulestead_admin/live/admin_layout.ex` or equivalent shared chrome module
- `rulestead_admin/lib/rulestead_admin/components/*.ex`
- `rulestead_admin/lib/rulestead_admin/policy.ex` and/or `rulestead/lib/rulestead/admin/policy.ex`
- `rulestead_admin/mix.exs`
- `rulestead_admin/test/rulestead_admin/router_test.exs`
- `rulestead_admin/test/rulestead_admin/live/*_test.exs`
- `rulestead_admin/test/support/*`
- `rulestead/lib/rulestead.ex`
- `rulestead/lib/rulestead/store.ex`
- `rulestead/lib/rulestead/store/command.ex`
- `rulestead/lib/rulestead/store/ecto.ex`
- `rulestead/lib/rulestead/fake.ex`
- `rulestead/lib/rulestead/flag.ex`
- `rulestead/lib/rulestead/flag_environment.ex`

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Mounted admin LiveView package bootstrapping in `rulestead_admin` | config/liveview | request-response | No Phoenix LiveView package code exists yet in `rulestead_admin`; only a router macro stub exists |
| `Rulestead.Admin.Policy` contract | behaviour | request-response | Requirement exists, but no implementation or behavior module was found in inspected code |
| Lifecycle-derived fields like `permanent?`, `stale?`, `potentially_stale?`, `lifecycle_state` | model/service | transform | Current schemas expose raw timestamps/status only; derived lifecycle contract does not exist yet |

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead/test`, `rulestead_admin/lib`, `rulestead_admin/test`, `.planning/phases/*`
**Files scanned:** 22
**Pattern extraction date:** 2026-04-23
