# Phase 15: Lifecycle Hygiene & Code References - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rulestead/oban/stale_flag_worker.ex` | worker | batch/event-driven | `lib/rulestead/oban/scheduled_execution_worker.ex` | exact |
| `lib/mix/tasks/rulestead.code_refs.ex` | script | file I/O | `lib/mix/tasks/rulestead.install.ex` | role-match |
| `lib/rulestead/webhooks/code_refs_plug.ex` | route/plug | request-response | `lib/rulestead/webhooks/ingress_plug.ex` | role-match |
| `lib/rulestead_admin/live/flag_live/cleanup.ex` | controller/LiveView | request-response | `lib/rulestead_admin/live/flag_live/kill.ex` | exact |

## Pattern Assignments

### `lib/rulestead/oban/stale_flag_worker.ex` (worker, batch/event-driven)

**Analog:** `lib/rulestead/oban/scheduled_execution_worker.ex`

**Imports pattern** (lines 3-7):
```elixir
  use Rulestead.Oban.Worker

  alias Rulestead.{Context, Telemetry}
  alias Rulestead.Store.Command
```

**Core execution pattern** (lines 9-45):
```elixir
  @spec perform(map()) :: {:ok, map()} | {:error, term()}
  def perform(job) when is_map(job) do
    context = rulestead_context(job)
    args = Map.get(job, :args, %{})
    
    # ... setup command ...

    case configured_store().execute_scheduled_execution(command) do
      {:ok, %{scheduled_execution: completed} = result} ->
        # ... emit success telemetry ...
        {:ok, result}

      {:error, _reason} = error ->
        # ... emit failure telemetry ...
        error
    end
  end
```

---

### `lib/mix/tasks/rulestead.code_refs.ex` (script, file I/O)

**Analog:** `lib/mix/tasks/rulestead.install.ex`

**Imports pattern** (lines 1-8):
```elixir
defmodule Mix.Tasks.Rulestead.Install do
  use Mix.Task

  alias Rulestead.Install

  @shortdoc "Copies rulestead migrations and config into the host app"

  @switches [repo: :string, yes: :boolean]
```

**Core Task pattern** (lines 10-22):
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

---

### `lib/rulestead/webhooks/code_refs_plug.ex` (route/plug, request-response)

**Analog:** `lib/rulestead/webhooks/ingress_plug.ex`

**Imports pattern** (lines 1-7):
```elixir
defmodule Rulestead.Webhooks.IngressPlug do
  @moduledoc """
  Library-owned Plug for inbound webhook ingress.
  Captures the raw body, verifies signatures, and records receipts.
  """
  import Plug.Conn
  alias Rulestead.Webhooks.Verifier
  alias Rulestead.Store.Command
```

**Core Plug execution pattern** (lines 11-40):
```elixir
  def call(conn, opts) do
    case get_raw_body(conn) do
      {:ok, raw_body, conn} ->
        headers = Map.new(conn.req_headers)

        case Verifier.verify(raw_body, headers, secret, provider_adapter, opts) do
          {:ok, event} ->
            # ... store success ...
            conn
            |> assign(:rulestead_inbound_event, event)

          {:error, {state, reason}} ->
            # ... store rejection ...
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: reason}))
            |> halt()
        end
```

---

### `lib/rulestead_admin/live/flag_live/cleanup.ex` (controller/LiveView, request-response)

**Analog:** `lib/rulestead_admin/live/flag_live/kill.ex`

**Imports pattern** (lines 3-6):
```elixir
  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}
  alias RulesteadAdmin.Live.Session
```

**Action workflow pattern** (lines 78-99):
```elixir
  @impl true
  def handle_event("engage", params, socket) do
    reason = String.trim(Map.get(params, "reason", ""))
    confirmation = String.trim(Map.get(params, "confirmation", ""))

    with :ok <- validate_reason(reason),
         :ok <- validate_confirmation(socket.assigns.flag_key, socket.assigns.current_environment.key, confirmation),
         {:ok, _payload} <-
           Rulestead.engage_kill_switch(
             socket.assigns.flag_key,
             socket.assigns.current_environment.key,
             socket.assigns.current_actor,
             reason: reason
           ) do
      {:noreply,
       socket
       # ... reset state ...
       |> assign(:notice, "Kill switch engaged.")
       |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}
    else
      {:error, error} ->
        {:noreply, assign(socket, :confirmation_error, error.message)}

      {:validation, message} ->
        {:noreply, assign(socket, :confirmation_error, message)}
    end
  end
```

**Validation pattern** (lines 162-167):
```elixir
  defp validate_confirmation(flag_key, environment_key, confirmation) do
    if production_env?(environment_key) and confirmation != flag_key do
      {:validation, "Type the exact flag key to confirm this production action."}
    else
      :ok
    end
  end
```

## Shared Patterns

### Error Handling
**Source:** `lib/rulestead_admin/live/flag_live/kill.ex`
**Apply to:** All LiveView action handlers
```elixir
    else
      {:error, error} ->
        {:noreply, assign(socket, :confirmation_error, error.message)}

      {:validation, message} ->
        {:noreply, assign(socket, :confirmation_error, message)}
    end
```

### Authorization/Permissions Context
**Source:** `lib/rulestead/oban/scheduled_execution_worker.ex`
**Apply to:** Oban workers
```elixir
  defp execution_actor(%Context{actor: nil}),
    do: %{"id" => "system:scheduler", "type" => "system", "display" => "Scheduler"}
```

## No Analog Found

None. All Phase 15 file implementations correspond closely to existing architecture primitives.

## Metadata

**Analog search scope:** `lib/**/*.ex`
**Files scanned:** 111 (across rulestead and rulestead_admin)
**Pattern extraction date:** 2024-05-24
