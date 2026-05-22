# Phase 19: Redis Storage & Caching Adapter - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead/lib/rulestead/store/redis.ex` | adapter | request-response | `rulestead/lib/rulestead/store/ecto.ex` | role-match |
| `rulestead/lib/rulestead/redis/publisher.ex` | service | event-driven | `rulestead/lib/rulestead/runtime/refresh.ex` | role-match |

## Pattern Assignments

### `rulestead/lib/rulestead/store/redis.ex` (adapter, request-response)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

**Imports and Behaviour pattern** (lines 1-28):
```elixir
defmodule Rulestead.Store.Redis do
  @moduledoc false

  alias Rulestead.{
    Environment,
    RuntimeSnapshot,
    Store,
    StoreError
  }
  
  alias Rulestead.Store.Command

  @behaviour Store
```

**Core Fetch Pattern** (lines 39-55):
```elixir
  @impl Store
  def fetch_snapshot(%Command.FetchSnapshot{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key) do
      # In Ecto: command |> runtime_snapshot_query(environment.key) |> Repo.one()
      # In Redis: Query Redis for the environment's snapshot
      case fetch_from_redis(environment.key) do
        nil ->
          {:error,
           StoreError.snapshot_not_found(
             environment.key,
             metadata: %{version: command.version}
           )}

        snapshot ->
          {:ok, serialize_runtime_snapshot(snapshot)}
      end
    end
  end
```

**Unsupported Mutation Pattern** (lines 58-61):
All other mutations must return standard `StoreError`:
```elixir
  @impl Store
  def create_flag(%Command.CreateFlag{} = _command) do
    {:error, StoreError.invalid_command("Redis adapter is read-only")}
  end
```

---

### `rulestead/lib/rulestead/redis/publisher.ex` (service, event-driven)

**Analog:** `rulestead/lib/rulestead/runtime/refresh.ex`

**Imports and Init pattern** (lines 1-45):
```elixir
defmodule Rulestead.Redis.Publisher do
  @moduledoc false

  use GenServer

  alias Rulestead.Telemetry
  
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    # Subscribe to telemetry or pubsub events that indicate a snapshot was published
    :telemetry.attach(
      "redis-publisher",
      [:rulestead, :runtime, :snapshot, :published],
      &__MODULE__.handle_telemetry_event/4,
      nil
    )
    {:ok, %{}}
  end
```

**Telemetry Event Handler Pattern** (lines 145-155, adapted):
```elixir
  def handle_telemetry_event(_event_name, measurements, metadata, _config) do
    # Cast to self to handle the push async, or push directly depending on scale
    GenServer.cast(__MODULE__, {:push_snapshot, metadata.environment})
  end

  @impl true
  def handle_cast({:push_snapshot, environment_key}, state) do
    # Fetch latest from Ecto and push to Redis
    {:noreply, state}
  end
```

## Shared Patterns

### Error Handling
**Source:** `rulestead/lib/rulestead/store_error.ex`
**Apply to:** `rulestead/lib/rulestead/store/redis.ex`
Always use `StoreError.snapshot_not_found/2` and `StoreError.invalid_command/2` for adapter errors.

### Telemetry Subscription
**Source:** `rulestead/lib/rulestead/runtime/refresh.ex`
**Apply to:** `rulestead/lib/rulestead/redis/publisher.ex`
Listening to the existing `[:rulestead, :runtime, :snapshot, :published]` event ensures the Redis sync happens implicitly upon any successful mutation in Ecto.

## Metadata

**Analog search scope:** `rulestead/lib/rulestead/**/*.ex`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-24
