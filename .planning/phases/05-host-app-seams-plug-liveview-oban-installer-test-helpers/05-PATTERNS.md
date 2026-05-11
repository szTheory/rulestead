# Phase 5: Host-App Seams, Plug, LiveView, Oban, Installer, Test Helpers - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 10
**Analogs found:** 8 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead/plug.ex` | middleware | request-response | `rulestead/lib/rulestead/context.ex` | partial-match |
| `rulestead/lib/rulestead/phoenix.ex` | utility | transform | `rulestead/lib/rulestead/context.ex` | role-match |
| `rulestead/lib/rulestead/live_view.ex` | utility | request-response | `rulestead/lib/rulestead/runtime.ex` | partial-match |
| `rulestead/lib/rulestead/oban.ex` | utility | event-driven | `rulestead/lib/rulestead/context.ex` | partial-match |
| `rulestead/lib/rulestead/oban/middleware.ex` | middleware | event-driven | `rulestead/lib/rulestead/fake/control.ex` | partial-match |
| `rulestead/lib/rulestead/test_helpers.ex` | utility | transform | `rulestead/lib/rulestead/fake/control.ex` | role-match |
| `rulestead/lib/rulestead/install.ex` | service | file-I/O | `rulestead/lib/rulestead/install.ex` | exact |
| `rulestead/lib/rulestead/install/config_writer.ex` | service | file-I/O | `rulestead/lib/rulestead/install/config_writer.ex` | exact |
| `rulestead/lib/rulestead/install/file_injector.ex` | utility | file-I/O | `rulestead/lib/rulestead/install/config_writer.ex` | partial-match |
| `rulestead/lib/mix/tasks/rulestead.install.ex` | config | request-response | `rulestead/lib/mix/tasks/rulestead.install.ex` | exact |
| `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs` | test | file-I/O | `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs` | exact |
| `rulestead/test/rulestead/integration/install_golden_test.exs` | test | file-I/O | `rulestead/test/rulestead/integration/install_smoke_test.exs` | role-match |
| `rulestead/test/fixtures/install_golden/tree/**` | test | file-I/O | none in repo | none |
| `rulestead/test/rulestead/test_helpers_test.exs` | test | event-driven | `rulestead/test/rulestead/telemetry_test.exs` | role-match |

## Pattern Assignments

### `rulestead/lib/rulestead/plug.ex` (middleware, request-response)

**Analog:** `rulestead/lib/rulestead/context.ex`

Use the same "normalize all caller input into a single struct" pattern instead of leaking Phoenix or Plug types beyond the seam.

**Context normalization pattern** ([rulestead/lib/rulestead/context.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/context.ex:29), lines 29-50):
```elixir
@spec new(t() | keyword() | map()) :: t()
def new(%__MODULE__{} = context), do: normalize(context)

def new(attrs) when is_list(attrs) or is_map(attrs) do
  attrs = attrs |> Map.new() |> normalize_aliases()
  actor = normalize_actor(Map.get(attrs, :actor))

  %__MODULE__{
    actor: actor,
    targeting_key: normalize_scalar(Map.get(attrs, :targeting_key) || actor_key(actor)),
    tenant_key: normalize_scalar(Map.get(attrs, :tenant_key)),
    environment: normalize_scalar(Map.get(attrs, :environment)),
    attributes: normalize_attributes(Map.get(attrs, :attributes, %{})),
    request_id: normalize_scalar(Map.get(attrs, :request_id)),
    session_id: normalize_scalar(Map.get(attrs, :session_id)),
    strict?: normalize_boolean(Map.get(attrs, :strict?, false))
  }
end

@spec normalize(t() | keyword() | map()) :: t()
def normalize(%__MODULE__{} = context), do: new(Map.from_struct(context))
def normalize(attrs) when is_list(attrs) or is_map(attrs), do: new(attrs)
```

**Scalar sanitization pattern** ([rulestead/lib/rulestead/context.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/context.ex:74), lines 74-93):
```elixir
defp normalize_scalar(nil), do: nil

defp normalize_scalar(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> nil
    normalized -> normalized
  end
end

defp normalize_scalar(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_scalar()
defp normalize_scalar(value) when is_integer(value), do: Integer.to_string(value)
defp normalize_scalar(value) when is_float(value), do: :erlang.float_to_binary(value, [:compact])
defp normalize_scalar(_value), do: nil
```

**Planner note:** Phase 5 should keep `Plug.Conn` handling local to the seam, then emit only `%Rulestead.Context{}` into `conn.assigns[:rulestead_context]`.

---

### `rulestead/lib/rulestead/phoenix.ex` and `rulestead/lib/rulestead/live_view.ex` (utility, transform/request-response)

**Analogs:** `rulestead/lib/rulestead/context.ex`, `rulestead/lib/rulestead/runtime.ex`

These modules should look like facade/adapter layers, not direct cache callers.

**Explicit facade shape** ([rulestead/lib/rulestead/runtime.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime.ex:7), lines 7-18):
```elixir
@spec evaluate(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
        {:ok, Result.t()} | {:error, Rulestead.Error.t()}
def evaluate(environment_key, flag_key, context) do
  context = Context.normalize(context)

  with {:ok, runtime_metadata} <- Cache.runtime_metadata(environment_key) do
    lookup_result = Cache.lookup(environment_key, flag_key)
    start_metadata = runtime_start_metadata(lookup_result, flag_key, runtime_metadata, context)

    Telemetry.span(
```

**Projection helpers pattern** ([rulestead/lib/rulestead/runtime.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime.ex:42), lines 42-80):
```elixir
def enabled?(environment_key, flag_key, context) do
  with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
    {:ok, result.enabled?}
  end
end

def get_value(environment_key, flag_key, context, default) do
  with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
    value =
      cond do
        result.reason == :default and is_nil(result.value) -> default
        is_nil(result.value) -> default
        true -> result.value
      end

    {:ok, value}
  end
end
```

**Planner note:** `assign_flags/2`, `context_from_conn/1`, and `context_from_socket/1` should compose `Context.normalize/1` plus `Runtime.enabled?/3` or `Runtime.evaluate/3`; they should not reach into `Rulestead.Runtime.Cache` or `Evaluator`.

---

### `rulestead/lib/rulestead/oban.ex` and `rulestead/lib/rulestead/oban/middleware.ex` (utility/middleware, event-driven)

**Analogs:** `rulestead/lib/rulestead/context.ex`, `rulestead/lib/rulestead/fake/control.ex`

There is no existing job-middleware module, so copy the explicit boundary style already used for fake-only controls: helper surface separated from the shared production behavior, with small wrappers and explicit bang helpers only where needed.

**Boundary separation pattern** ([rulestead/lib/rulestead/fake/control.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake/control.ex:1), lines 1-7):
```elixir
defmodule Rulestead.Fake.Control do
  @moduledoc """
  Test-only controls for `Rulestead.Fake`.

  These helpers are intentionally separate from the shared `Rulestead.Store`
  behaviour so production callers cannot rely on fake-only affordances.
  """
```

**Small wrapper + ensure-started pattern** ([rulestead/lib/rulestead/fake/control.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake/control.ex:11), lines 11-34):
```elixir
@spec ensure_started() :: :ok
def ensure_started do
  case Process.whereis(Fake) do
    nil ->
      case Fake.start_link() do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, reason} -> raise "failed to start Rulestead.Fake: #{inspect(reason)}"
      end

    _pid ->
      :ok
  end
end

@spec reset!(keyword()) :: :ok
def reset!(opts \\ []) do
  ensure_started()

  case Fake.reset(opts) do
    :ok -> :ok
    {:error, error} -> raise error
  end
end
```

**Planner note:** keep Oban context serialization/deserialization in a dedicated seam module; do not add job-shape assumptions into `Rulestead.Context`.

---

### `rulestead/lib/rulestead/test_helpers.ex` (utility, transform)

**Analog:** `rulestead/lib/rulestead/fake/control.ex`

Phase 5 test helpers should extend the existing fake-control surface instead of bypassing it.

**Bang/non-bang helper convention** ([rulestead/lib/rulestead/fake/control.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake/control.ex:46), lines 46-60):
```elixir
@spec put_flag!(map()) :: map()
def put_flag!(attrs) do
  ensure_started()

  case Fake.put_flag(attrs) do
    {:ok, flag} -> flag
    {:error, error} -> raise error
  end
end

@spec put_flag(map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
def put_flag(attrs) do
  ensure_started()
  Fake.put_flag(attrs)
end
```

**Time/control helpers for deterministic tests** ([rulestead/lib/rulestead/fake/control.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake/control.ex:82), lines 82-100):
```elixir
@spec set_now!(DateTime.t()) :: DateTime.t()
def set_now!(%DateTime{} = now) do
  ensure_started()

  case Fake.set_now(now) do
    {:ok, updated_now} -> updated_now
    {:error, error} -> raise error
  end
end

@spec advance_time!(integer()) :: DateTime.t()
def advance_time!(seconds) when is_integer(seconds) do
  ensure_started()

  case Fake.advance_time(seconds) do
    {:ok, updated_now} -> updated_now
    {:error, error} -> raise error
  end
end
```

**Planner note:** `with_flag/3`, `put_flag/3`, `clear_flags/0`, and `seed_bucket/3` should delegate to `Rulestead.Fake.Control`; don’t build a second in-memory path.

---

### `rulestead/lib/rulestead/install.ex` (service, file-I/O)

**Analog:** `rulestead/lib/rulestead/install.ex`

Keep the installer as a thin orchestrator over small writer modules.

**Orchestration pattern** ([rulestead/lib/rulestead/install.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install.ex:4), lines 4-12):
```elixir
alias Rulestead.Install.{ConfigWriter, MigrationWriter, RepoLocator}

@spec run(keyword()) :: {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
def run(opts \\ []) do
  with {:ok, repo} <- RepoLocator.resolve(opts),
       {:ok, migration_messages} <- MigrationWriter.copy_migrations(repo, opts),
       {:ok, config_messages} <- ConfigWriter.write(repo, opts) do
    {:ok, migration_messages ++ config_messages}
  end
end
```

**Planner note:** extend this same reducer/orchestrator shape for endpoint/router/Oban injection; do not bury repo resolution or CLI output inside each writer.

---

### `rulestead/lib/rulestead/install/config_writer.ex` and new injector helpers (service/utility, file-I/O)

**Analog:** `rulestead/lib/rulestead/install/config_writer.ex`

This is the strongest idempotent file-injection analog in the repo.

**Template + write pipeline pattern** ([rulestead/lib/rulestead/install/config_writer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/config_writer.ex:4), lines 4-25):
```elixir
@template_path Application.app_dir(
                 :rulestead,
                 "priv/templates/rulestead.install/config/rulestead.exs"
               )
@import_line ~s(import_config "rulestead.exs")

@spec write(module(), keyword()) :: {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
def write(repo, opts \\ []) do
  config_dir = Keyword.get(opts, :config_path) || Path.join(File.cwd!(), "config")
  rulestead_path = Path.join(config_dir, "rulestead.exs")
  config_path = Path.join(config_dir, "config.exs")

  File.mkdir_p!(config_dir)

  rendered = render_template(repo)

  messages =
    []
    |> maybe_write_rulestead_config(rulestead_path, rendered)
    |> maybe_inject_import(config_path)

  {:ok, Enum.reverse(messages)}
end
```

**Idempotent decision pattern** ([rulestead/lib/rulestead/install/config_writer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/config_writer.ex:34), lines 34-64):
```elixir
defp maybe_write_rulestead_config(messages, path, rendered) do
  case File.read(path) do
    {:ok, ^rendered} ->
      ["skip #{Path.relative_to_cwd(path)} already present" | messages]

    {:ok, _existing} ->
      File.write!(path, rendered)
      ["write #{Path.relative_to_cwd(path)}" | messages]

    {:error, :enoent} ->
      File.write!(path, rendered)
      ["write #{Path.relative_to_cwd(path)}" | messages]
  end
end

defp maybe_inject_import(messages, config_path) do
  contents =
    case File.read(config_path) do
      {:ok, existing} -> existing
      {:error, :enoent} -> "import Config\n"
    end

  cond do
    String.contains?(contents, @import_line) ->
      ["skip #{Path.relative_to_cwd(config_path)} import already present" | messages]

    true ->
      updated = inject_import(contents)
      File.write!(config_path, updated)
      ["write #{Path.relative_to_cwd(config_path)} import" | messages]
  end
end
```

**String-only injection pattern** ([rulestead/lib/rulestead/install/config_writer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/config_writer.ex:67), lines 67-70):
```elixir
defp inject_import(contents) do
  trimmed = String.trim_trailing(contents)
  trimmed <> "\n\n" <> @import_line <> "\n"
end
```

**Planner note:** the new router/endpoint/Oban injectors should mirror this exact `skip`/`write` message contract and content-based idempotency check.

---

### `rulestead/lib/rulestead/install/migration_writer.ex` (service, file-I/O)

**Analog:** `rulestead/lib/rulestead/install/migration_writer.ex`

Use the existing copy-vs-skip pattern unchanged for migrations.

**Copy loop pattern** ([rulestead/lib/rulestead/install/migration_writer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/migration_writer.ex:6), lines 6-30):
```elixir
@spec copy_migrations(module(), keyword()) ::
        {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
def copy_migrations(repo, opts \\ []) do
  target_dir = Keyword.get(opts, :migrations_path) || target_path_for_repo(repo)
  File.mkdir_p!(target_dir)

  messages =
    @source_dir
    |> File.ls!()
    |> Enum.sort()
    |> Enum.map(fn filename ->
      source = Path.join(@source_dir, filename)
      target = Path.join(target_dir, filename)

      case File.exists?(target) do
        true ->
          "skip #{Path.relative_to_cwd(target)} already present"

        false ->
          File.cp!(source, target)
          "copy #{Path.relative_to_cwd(target)}"
      end
    end)

  {:ok, messages}
end
```

---

### `rulestead/lib/rulestead/install/repo_locator.ex` and `rulestead/lib/mix/tasks/rulestead.install.ex` (config, request-response)

**Analogs:** `rulestead/lib/rulestead/install/repo_locator.ex`, `rulestead/lib/mix/tasks/rulestead.install.ex`

Keep repo selection and shell output centralized.

**Repo resolution pattern** ([rulestead/lib/rulestead/install/repo_locator.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/repo_locator.ex:6), lines 6-26):
```elixir
@spec resolve(keyword()) :: {:ok, module()} | {:error, Rulestead.Error.t()}
def resolve(opts \\ []) do
  repo_override = Keyword.get(opts, :repo) || Keyword.get(opts, :"--repo")
  repos = configured_repos(opts)

  cond do
    is_binary(repo_override) ->
      repo_override |> String.split(".") |> Module.concat() |> validate_repo(repos)

    is_atom(repo_override) and not is_nil(repo_override) ->
      validate_repo(repo_override, repos)

    repos == [] ->
      {:error, ConfigError.repo_not_configured()}

    length(repos) == 1 ->
      {:ok, hd(repos)}

    true ->
      {:error, ConfigError.repo_ambiguous(metadata: %{repos: Enum.map(repos, &inspect/1)})}
  end
end
```

**Mix task output pattern** ([rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:10), lines 10-23):
```elixir
@impl Mix.Task
def run(args) do
  Mix.Task.run("app.start")

  {opts, _argv, _invalid} = OptionParser.parse(args, strict: @switches)

  case Install.run(opts) do
    {:ok, messages} ->
      shell = Mix.shell()
      Enum.each(messages, fn message -> shell.info(message) end)

    {:error, error} ->
      Mix.raise(error.message)
  end
end
```

**Planner note:** keep CLI messaging line-oriented and deterministic so golden tests can compare stdout directly.

---

### `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs` (test, file-I/O)

**Analog:** `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs`

This is the exact idempotency-test pattern for the installer.

**Temp-dir setup pattern** ([rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:8), lines 8-29):
```elixir
setup do
  tmp_dir =
    Path.join(System.tmp_dir!(), "rulestead-install-#{System.unique_integer([:positive])}")

  previous_repos = Application.get_env(:rulestead, :ecto_repos)

  File.mkdir_p!(Path.join(tmp_dir, "config"))
  File.write!(Path.join(tmp_dir, "config/config.exs"), "import Config\n")
  File.mkdir_p!(Path.join(tmp_dir, "priv/repo/migrations"))
  Application.put_env(:rulestead, :ecto_repos, [MyApp.Repo])

  on_exit(fn ->
    File.rm_rf!(tmp_dir)

    case previous_repos do
      nil -> Application.delete_env(:rulestead, :ecto_repos)
      repos -> Application.put_env(:rulestead, :ecto_repos, repos)
    end
  end)

  {:ok, tmp_dir: tmp_dir}
end
```

**Idempotency assertions** ([rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:43), lines 43-77):
```elixir
assert {:ok, first_messages} =
         MigrationWriter.copy_migrations(MyApp.Repo, migrations_path: target)

assert Enum.any?(first_messages, &String.starts_with?(&1, "copy "))

assert {:ok, second_messages} =
         MigrationWriter.copy_migrations(MyApp.Repo, migrations_path: target)

assert Enum.all?(second_messages, &String.starts_with?(&1, "skip "))
```

```elixir
assert {:ok, second_messages} = ConfigWriter.write(MyApp.Repo, config_path: config_path)

assert Enum.all?(
         second_messages,
         &(String.starts_with?(&1, "skip ") or String.starts_with?(&1, "write "))
       )

assert File.read!(Path.join(config_path, "config.exs")) == updated_config
```

---

### `rulestead/test/rulestead/integration/install_golden_test.exs` (test, file-I/O)

**Analog:** `rulestead/test/rulestead/integration/install_smoke_test.exs`

There is no existing golden-diff fixture tree, but this is the strongest existing end-to-end generator/install convention.

**Long-running integration test convention** ([rulestead/test/rulestead/integration/install_smoke_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/install_smoke_test.exs:1), lines 1-6):
```elixir
defmodule Rulestead.Integration.InstallSmokeTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 300_000
```

**`System.cmd/3` host-app orchestration pattern** ([rulestead/test/rulestead/integration/install_smoke_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/install_smoke_test.exs:15), lines 15-30 and 52-58):
```elixir
{generator_output, generator_status} =
  System.cmd(
    "mix",
    [
      "phx.new",
      "host_app",
      "--database",
      "postgres",
      "--no-assets",
      "--no-dashboard",
      "--no-mailer",
      "--no-install"
    ],
    cd: tmp_dir,
    stderr_to_stdout: true
  )
```

```elixir
{install_output, install_status} =
  System.cmd("mix", ["rulestead.install", "--repo", "HostApp.Repo"],
    cd: app_dir,
    stderr_to_stdout: true
  )

assert install_status == 0, install_output
```

**Planner note:** build the golden test on top of this exact `System.cmd/3` flow, then add fixture-tree comparison and timestamp normalization as a new Phase 5 convention.

---

### `rulestead/test/rulestead/test_helpers_test.exs` and telemetry-backed assertions (test, event-driven)

**Analog:** `rulestead/test/rulestead/telemetry_test.exs`

This file contains the strongest pattern for `assert_flag_evaluated/2`.

**Attach-many + send-to-self pattern** ([rulestead/test/rulestead/telemetry_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/telemetry_test.exs:472), lines 472-484):
```elixir
defp attach_test_handler(handler_id, events) do
  :ok =
    :telemetry.attach_many(
      handler_id,
      events,
      fn event, _measurements, metadata, test_pid ->
        send(test_pid, {:telemetry_event, event, metadata})
      end,
      self()
    )

  on_exit(fn -> :telemetry.detach(handler_id) end)
end
```

**Event-filtering assertion helper** ([rulestead/test/rulestead/telemetry_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/telemetry_test.exs:490), lines 490-512):
```elixir
defp assert_receive_event(event_name) do
  receive_matching_event(event_name, 1_000)
end

defp do_receive_matching_event(event_name, deadline) do
  remaining = max(deadline - System.monotonic_time(:millisecond), 0)

  receive do
    {:telemetry_event, ^event_name, metadata} ->
      metadata

    {:telemetry_event, _other_event, _metadata} ->
      do_receive_matching_event(event_name, deadline)
  after
    remaining ->
      flunk("expected telemetry event #{inspect(event_name)}")
  end
end
```

**Metadata assertions to copy** ([rulestead/test/rulestead/telemetry_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/telemetry_test.exs:124), lines 124-139):
```elixir
eval_start = assert_receive_event([:rulestead, :eval, :decide, :start])
assert eval_start.flag_key == "checkout-redesign"
assert eval_start.environment == environment_key
assert eval_start.flag_type == :release
assert eval_start.has_targeting_key? == true

cache_hit = assert_receive_event([:rulestead, :runtime, :cache, :hit])
assert cache_hit.reason == :cache_hit
assert is_integer(cache_hit.cache_age_ms)

eval_stop = assert_receive_event([:rulestead, :eval, :decide, :stop])
assert eval_stop.reason == :rule_match
assert eval_stop.snapshot_version == 1
assert eval_stop.matched_rule_count == 1
assert is_integer(eval_stop.cache_age_ms)
```

**Negative-shape assertions** ([rulestead/test/rulestead/telemetry_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/telemetry_test.exs:436), lines 436-442):
```elixir
stale_used = assert_receive_event([:rulestead, :runtime, :cache, :stale_used])
assert stale_used.reason == :stale_snapshot
refute Map.has_key?(stale_used, :attributes)
refute Map.has_key?(stale_used, :value)
refute Map.has_key?(stale_used, :conn)
refute Map.has_key?(stale_used, :socket)
refute Map.has_key?(stale_used, :job)
```

**Planner note:** `assert_flag_evaluated/2` should be a thin helper around `:telemetry.attach_many/4` plus the event-filtering receive loop above.

---

### Runtime facade consumption for all Phase 5 host seams

**Analogs:** `rulestead/lib/rulestead/runtime.ex`, `rulestead/lib/rulestead.ex`, `rulestead/test/rulestead/integration/runtime_hot_path_test.exs`

Phase 5 should consume the Phase 4 runtime facade, not bypass it.

**Bounded public forwarding** ([rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:256), lines 256-260):
```elixir
@doc """
Returns bounded runtime diagnostics for the local node.
"""
@spec diagnostics() :: map()
def diagnostics, do: Runtime.diagnostics()
```

**DB-free runtime use in tests** ([rulestead/test/rulestead/integration/runtime_hot_path_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/runtime_hot_path_test.exs:77), lines 77-107):
```elixir
worker =
  start_supervised!(
    {Refresh,
     name: nil,
     environment_key: "test",
     store: Rulestead.Store.Ecto,
     pubsub: nil,
     poll_interval_ms: 5_000,
     refresh_jitter_ms: 0,
     auto_tick?: false}
  )

assert :ok = Refresh.sync(worker)
assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
```

```elixir
assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
refute_receive {:repo_query, _query}, 200
```

**Planner note:** `LiveView.assign_flags/2`, Plug assigns, and Oban helpers should call `Runtime.enabled?/3`, `Runtime.get_value/4`, or `Runtime.evaluate/3`; they should never call `Rulestead.fetch_flag/2`, `Rulestead.Store.*`, `Rulestead.Runtime.Cache`, or `Evaluator` on the hot path.

## Shared Patterns

### Context Normalization
**Sources:** [rulestead/lib/rulestead/context.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/context.ex:29), [rulestead/lib/rulestead/runtime.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime.ex:9)
**Apply to:** `Plug`, `Phoenix`, `LiveView`, `Oban`, test helpers

```elixir
context = Context.normalize(context)
```

Phase 5 seams should accept host-framework input, normalize once, and pass `%Rulestead.Context{}` onward.

### Installer Message Contract
**Sources:** [rulestead/lib/rulestead/install/config_writer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/config_writer.ex:34), [rulestead/lib/rulestead/install/migration_writer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/install/migration_writer.ex:20)
**Apply to:** endpoint/router/Oban injectors and full installer task

```elixir
"skip #{Path.relative_to_cwd(path)} already present"
"write #{Path.relative_to_cwd(path)}"
"copy #{Path.relative_to_cwd(target)}"
```

The second installer run should emit `skip ...` lines and preserve file bytes.

### Telemetry Assertion Harness
**Sources:** [rulestead/test/rulestead/telemetry_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/telemetry_test.exs:472), [rulestead/lib/rulestead/telemetry.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/telemetry.ex:16)
**Apply to:** `assert_flag_evaluated/2`, telemetry-facing test helpers, any new `:telemetry` tests

```elixir
:telemetry.attach_many(handler_id, events, fn event, _measurements, metadata, test_pid ->
  send(test_pid, {:telemetry_event, event, metadata})
end, self())
```

```elixir
Telemetry.span([:rulestead, :eval, :decide], Telemetry.metadata(start_metadata), fn ->
```

Use the existing event families and metadata keys; assert on `flag_key`, `environment`, `reason`, `snapshot_version`, and `cache_age_ms`.

### Fake-Control Delegation
**Source:** [rulestead/lib/rulestead/fake/control.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake/control.ex:26)
**Apply to:** `with_flag/3`, `put_flag/3`, `clear_flags/0`, `seed_bucket/3`

```elixir
ensure_started()

case Fake.put_flag(attrs) do
  {:ok, flag} -> flag
  {:error, error} -> raise error
end
```

Build test helpers as a thin convenience layer over the fake adapter, not a parallel test store.

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead/test/fixtures/install_golden/tree/**` | test | file-I/O | Repo has no existing golden fixture tree or byte-for-byte stdout fixture convention yet. |
| `rulestead/lib/rulestead/plug.ex` as actual Plug implementation | middleware | request-response | Repo has no current Plug or Phoenix-facing module; use `Context` normalization plus `Runtime` facade patterns as the new seam. |

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead/test`, `.planning/phases/05-host-app-seams-plug-liveview-oban-installer-test-helpers`
**Files scanned:** 16
**Pattern extraction date:** 2026-04-23
