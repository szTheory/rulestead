# `Rulestead.Result`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/result.ex#L1)

Stable Phase 3 evaluation result.

# `debug_trace`

```elixir
@type debug_trace() :: map() | nil
```

# `reason`

```elixir
@type reason() :: :rule_match | :default | :targeting_key_missing | :flag_off | :error
```

# `t`

```elixir
@type t() :: %Rulestead.Result{
  cache_age_ms: integer() | nil,
  debug_trace: debug_trace(),
  enabled?: boolean(),
  flag_key: String.t() | nil,
  flag_version: integer() | nil,
  matched_rule: String.t() | nil,
  reason: reason(),
  value: term(),
  variant: String.t() | nil
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
