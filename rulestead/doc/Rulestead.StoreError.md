# `Rulestead.StoreError`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/store_error.ex#L1)

Constructors for store-domain `Rulestead.Error` values.

# `archived`

```elixir
@spec archived(
  String.t() | atom(),
  keyword()
) :: Rulestead.Error.t()
```

# `environment_not_found`

```elixir
@spec environment_not_found(
  String.t() | atom(),
  keyword()
) :: Rulestead.Error.t()
```

# `flag_not_found`

```elixir
@spec flag_not_found(String.t() | atom(), String.t() | atom(), keyword()) ::
  Rulestead.Error.t()
```

# `invalid_command`

```elixir
@spec invalid_command(
  String.t(),
  keyword()
) :: Rulestead.Error.t()
```

# `new`

```elixir
@spec new(Rulestead.Error.type(), String.t(), keyword()) :: Rulestead.Error.t()
```

# `snapshot_not_found`

```elixir
@spec snapshot_not_found(
  String.t() | atom(),
  keyword()
) :: Rulestead.Error.t()
```

# `unavailable`

```elixir
@spec unavailable(keyword()) :: Rulestead.Error.t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
