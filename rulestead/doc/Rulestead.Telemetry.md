# `Rulestead.Telemetry`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/telemetry.ex#L1)

Shared telemetry helpers for the locked Phase 4 public event catalog.

# `event_name`

```elixir
@type event_name() :: [atom()]
```

# `event_prefix`

```elixir
@type event_prefix() :: [atom()]
```

# `metadata`

```elixir
@type metadata() :: map()
```

# `attach_many`

```elixir
@spec attach_many(term(), [event_name()], :telemetry.handler_function(), term()) ::
  :ok | {:error, term()}
```

# `base_metadata`

```elixir
@spec base_metadata(
  map() | nil,
  Rulestead.Context.t() | map() | keyword() | nil,
  map()
) :: map()
```

# `command_metadata`

```elixir
@spec command_metadata(
  struct(),
  map()
) :: map()
```

# `detach`

```elixir
@spec detach(term()) :: :ok
```

# `dispatch`

```elixir
@spec dispatch(event_name(), map(), metadata(), event_name()) :: :ok
```

# `execute`

```elixir
@spec execute(event_name(), map(), metadata()) :: :ok
```

# `metadata`

```elixir
@spec metadata(map()) :: map()
```

# `result_metadata`

```elixir
@spec result_metadata(
  Rulestead.Result.t(),
  Rulestead.Context.t() | map() | keyword() | nil,
  map()
) ::
  map()
```

# `runtime_metadata`

```elixir
@spec runtime_metadata(map(), map()) :: map()
```

# `span`

```elixir
@spec span(event_prefix(), metadata(), (-&gt; {term(), metadata()} | term())) :: term()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
