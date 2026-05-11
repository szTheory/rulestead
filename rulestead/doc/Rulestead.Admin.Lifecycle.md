# `Rulestead.Admin.Lifecycle`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/admin/lifecycle.ex#L1)

Derives persisted admin lifecycle state from authored flag data.

# `state`

```elixir
@type state() :: :active | :potentially_stale | :stale | :archived
```

# `classify`

```elixir
@spec classify(map() | struct(), map() | struct(), keyword()) :: %{
  state: state(),
  mode: :permanent | :expiring,
  owner: term(),
  expected_expiration: Date.t() | nil,
  permanent: boolean(),
  last_evaluated_at: DateTime.t() | nil
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
