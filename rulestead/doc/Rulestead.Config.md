# `Rulestead.Config`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/config.ex#L1)

Validated Phase 5 host-app seam configuration.

This schema owns the explicit defaults for the Plug, LiveView, and Oban
integration points added in Phase 5, along with the runtime facade module the
generated host code is expected to target.

# `t`

```elixir
@type t() :: keyword()
```

# `defaults`

```elixir
@spec defaults() :: t()
```

# `load`

```elixir
@spec load(keyword()) :: t()
```

# `schema`

```elixir
@spec schema() :: keyword()
```

# `validate`

```elixir
@spec validate(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
```

# `validate!`

```elixir
@spec validate!(keyword()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
