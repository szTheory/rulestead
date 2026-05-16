# Phase 17: Analytics & Metrics Ingestion - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 5
**Analogs found:** 4 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rulestead/analytics/batcher.ex` | service / worker | batch | `rulestead/lib/rulestead/telemetry/cache.ex` | exact |
| `lib/rulestead/analytics/event.ex` | model | CRUD | `rulestead/lib/rulestead/audit_event.ex` | role-match |
| `lib/rulestead/analytics/event_mapper.ex` | utility | transform | No direct analog | none |
| `lib/rulestead/analytics/telemetry_handler.ex` | hook | event-driven | `rulestead/lib/rulestead/telemetry.ex` | partial |
| `lib/rulestead/analytics.ex` | api seam | request-response | `rulestead/lib/rulestead.ex` | exact |

## Pattern Assignments

### `lib/rulestead/analytics/batcher.ex` (service / worker, batch)

**Analog:** `rulestead/lib/rulestead/telemetry/cache.ex`

**GenServer & ETS Init pattern** (lines 1-13, 60-70):
```elixir
defmodule Rulestead.Telemetry.Cache do
  use GenServer

  @table :rulestead_telemetry_cache

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true])
      _ ->
        :ok
    end
    {:ok, %{}}
  end
```

**Non-blocking Write pattern** (lines 15-22):
```elixir
  def record_evaluation(flag_key, environment_key, variant, timestamp) do
    key = {flag_key, environment_key}
    try do
      :ets.insert(@table, {{key, :last_evaluated_at}, timestamp})
      # ... (omitted specifics)
    rescue
      ArgumentError -> :ok
    end
    :ok
  end
```

---

### `lib/rulestead/analytics/event.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/audit_event.ex`

**Schema and Types pattern** (lines 1-25):
```elixir
defmodule Rulestead.AuditEvent do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_events" do
    field(:event_type, :string)
    field(:resource_type, :string)
    field(:resource_id, :binary_id)
    field(:occurred_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @type t :: %__MODULE__{}
```

---

### `lib/rulestead/analytics/telemetry_handler.ex` (hook, event-driven)

**Analog:** `rulestead/lib/rulestead/telemetry.ex`

**Handler Attachment pattern** (lines 47-58):
```elixir
  @spec attach_many(term(), [event_name()], :telemetry.handler_function(), term()) :: :ok | {:error, term()}
  def attach_many(handler_id, events, function, config)
      when is_list(events) and is_function(function, 4) do
    ensure_handler_table()

    Enum.each(events, fn event ->
      ensure_dispatcher(event)
      :ets.insert(@handler_table, {{handler_id, event}, function, config})
    end)

    :ok
  end
```
*(Planner Note: Phase 17's hook will attach natively via `:telemetry.attach/4` and map `[:rulestead, :eval, :decide, :stop]` to the Analytics ETS batcher. See `RESEARCH.md` for explicit event map example.)*

---

### `lib/rulestead/analytics.ex` (api seam, request-response)

**Analog:** `rulestead/lib/rulestead.ex`

**Public Module Docs and Boundary pattern** (lines 1-20, 452-458):
```elixir
defmodule Rulestead do
  @moduledoc """
  Root public module for the `rulestead` package.
  ...
  """

  @doc """
  Evaluates an authored in-memory flag payload against an explicit context.
  """
  @spec evaluate(map(), Context.t() | keyword() | map(), keyword()) ::
          {:ok, Result.t()} | {:error, Error.t()}
  def evaluate(flag_payload, context, opts \\ []) do
```
*(Planner Note: Apply this same clean `@spec` boundary pattern to `Rulestead.track/3` by passing it through `Rulestead.Analytics.track/3` before putting it in the ETS buffer.)*

---

## Shared Patterns

### Non-blocking Concurrency
**Source:** `rulestead/lib/rulestead/telemetry/cache.ex`
**Apply to:** `Rulestead.Analytics.Batcher` and `Rulestead.Analytics.track/3`
All writes to the `:ets` table must be non-blocking. The ETS table must be created as `:public` and `:write_concurrency: true`.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/rulestead/analytics/event_mapper.ex` | utility | transform | Standard pure functional mapper for Ecto inserts; no structural equivalent. Use standard Elixir `Map.merge` and pure functional patterns from `RESEARCH.md`. |

## Metadata

**Analog search scope:** `rulestead/lib/**/*.ex`
**Files scanned:** 92
**Pattern extraction date:** 2026-05-17
