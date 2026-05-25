# `Rulestead.Ruleset`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/ruleset.ex#L1)

# `t`

```elixir
@type t() :: %Rulestead.Ruleset{
  __meta__: term(),
  flag_environment: term(),
  flag_environment_id: term(),
  id: term(),
  inserted_at: term(),
  metadata: term(),
  published_at: term(),
  rules: term(),
  salt: term(),
  status: term(),
  updated_at: term(),
  version: term()
}
```

# `changeset`

```elixir
@spec changeset(t(), map()) :: Ecto.Changeset.t()
```

# `statuses`

```elixir
@spec statuses() :: [atom()]
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
