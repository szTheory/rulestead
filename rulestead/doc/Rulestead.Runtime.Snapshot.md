# `Rulestead.Runtime.Snapshot`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/runtime/snapshot.ex#L1)

# `flag_entry`

```elixir
@type flag_entry() :: %{flag_key: String.t(), flag_payload: map()}
```

# `t`

```elixir
@type t() :: %Rulestead.Runtime.Snapshot{
  environment_key: String.t(),
  flag_keys: [String.t()],
  flags: %{required(String.t()) =&gt; flag_entry()},
  generated_at: DateTime.t() | nil,
  metadata: map(),
  published_at: DateTime.t(),
  version: pos_integer()
}
```

# `compile`

```elixir
@spec compile(map()) :: {:ok, t()} | {:error, Rulestead.Error.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
