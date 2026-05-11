# `Rulestead.Context`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/context.ex#L1)

Canonical runtime context used by the Phase 3 evaluator surface.

# `actor`

```elixir
@type actor() :: map() | struct() | nil
```

# `t`

```elixir
@type t() :: %Rulestead.Context{
  actor: actor(),
  attributes: map(),
  environment: String.t() | nil,
  request_id: String.t() | nil,
  session_id: String.t() | nil,
  strict?: boolean(),
  targeting_key: String.t() | nil,
  tenant_key: String.t() | nil
}
```

# `new`

```elixir
@spec new(t() | keyword() | map()) :: t()
```

# `normalize`

```elixir
@spec normalize(t() | keyword() | map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
