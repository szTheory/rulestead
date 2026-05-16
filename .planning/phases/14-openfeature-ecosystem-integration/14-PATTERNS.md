# Phase 14: OpenFeature Ecosystem Integration - Pattern Map

**Mapped:** 2024-05-15
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `open_feature_rulestead/mix.exs` | config | configuration | `rulestead/mix.exs` | role-match |
| `open_feature_rulestead/lib/open_feature_rulestead/provider.ex` | provider | request-response | `rulestead/lib/rulestead/store/ecto.ex` | role-match |
| `open_feature_rulestead/lib/open_feature_rulestead/context_mapper.ex` | utility | transform | `rulestead/lib/rulestead/context.ex` | exact |
| `open_feature_rulestead/test/open_feature_rulestead/context_mapper_test.exs` | test | NA | `rulestead/test/rulestead/context_test.exs` | exact |

## Pattern Assignments

### `open_feature_rulestead/mix.exs` (config, configuration)

**Analog:** `rulestead/mix.exs`

**Project struct pattern** (lines 7-17):
```elixir
  def project do
    [
      app: :rulestead,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end
```

---

### `open_feature_rulestead/lib/open_feature_rulestead/provider.ex` (provider, request-response)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

**Behaviour implementation pattern** (lines 28-31):
```elixir
  @behaviour Store

  @impl Store
  def fetch_flag(%Command.FetchFlag{} = command) do
```

**Error handling and rescue pattern** (lines 62-63, 73-74):
```elixir
        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
```

---

### `open_feature_rulestead/lib/open_feature_rulestead/context_mapper.ex` (utility, transform)

**Analog:** `rulestead/lib/rulestead/context.ex`

**Transform initialization pattern** (lines 28-39):
```elixir
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
```

**Normalization pattern** (lines 48-52, 60-68):
```elixir
  defp normalize_actor(nil), do: nil
  defp normalize_actor(%_{} = actor), do: actor

  defp normalize_actor(actor) when is_map(actor) do
    Enum.into(actor, %{})
  end

  defp normalize_scalar(nil), do: nil

  defp normalize_scalar(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end
```

---

### `open_feature_rulestead/test/open_feature_rulestead/context_mapper_test.exs` (test, NA)

**Analog:** `rulestead/test/rulestead/context_test.exs`

**Testing structure pattern** (lines 1-7):
```elixir
defmodule Rulestead.ContextTest do
  use ExUnit.Case, async: true

  alias Rulestead.Context

  test "normalizes map and keyword input into the canonical context struct" do
```

## Shared Patterns

### Error Normalization
**Source:** `rulestead/lib/rulestead/store/ecto.ex`
**Apply to:** Provider implementation
```elixir
{:error, error} -> {:error, StoreError.unavailable(cause: error)}
```

## No Analog Found

Files with no close match in the codebase:
*None*

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead/test`
**Files scanned:** 4 candidate analogs
**Pattern extraction date:** 2024-05-15
