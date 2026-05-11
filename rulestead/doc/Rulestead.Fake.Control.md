# `Rulestead.Fake.Control`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/fake/control.ex#L1)

Test-only controls for `Rulestead.Fake`.

These helpers are intentionally separate from the shared `Rulestead.Store`
behaviour so production callers cannot rely on fake-only affordances.

# `advance_time!`

```elixir
@spec advance_time!(integer()) :: DateTime.t()
```

# `disconnect!`

```elixir
@spec disconnect!() :: :ok
```

# `ensure_started`

```elixir
@spec ensure_started() :: :ok
```

# `latest_snapshot!`

```elixir
@spec latest_snapshot!(String.t() | atom()) :: map()
```

# `now!`

```elixir
@spec now!() :: DateTime.t()
```

# `publish!`

```elixir
@spec publish!(module() | atom(), String.t() | atom(), pos_integer()) :: :ok
```

# `put_environment!`

```elixir
@spec put_environment!(map()) :: map()
```

# `put_flag`

```elixir
@spec put_flag(map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

# `put_flag!`

```elixir
@spec put_flag!(map()) :: map()
```

# `put_test_flag!`

```elixir
@spec put_test_flag!(String.t() | atom(), term(), keyword()) :: map()
```

# `reconnect!`

```elixir
@spec reconnect!() :: :ok
```

# `reset!`

```elixir
@spec reset!(keyword()) :: :ok
```

# `restore!`

```elixir
@spec restore!(map()) :: :ok
```

# `seed_bucket!`

```elixir
@spec seed_bucket!(String.t() | atom(), String.t() | atom(), String.t() | atom()) ::
  map()
```

# `set_now!`

```elixir
@spec set_now!(DateTime.t()) :: DateTime.t()
```

# `snapshot!`

```elixir
@spec snapshot!() :: map()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
