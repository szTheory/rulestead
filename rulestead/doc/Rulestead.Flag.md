# `Rulestead.Flag`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/flag.ex#L1)

# `t`

```elixir
@type t() :: %Rulestead.Flag{
  __meta__: term(),
  archived_at: term(),
  default_value: term(),
  description: term(),
  expected_expiration: term(),
  flag_environments: term(),
  flag_type: term(),
  id: term(),
  inserted_at: term(),
  key: term(),
  owner: term(),
  permanent: term(),
  tags: term(),
  updated_at: term(),
  value_type: term()
}
```

# `changeset`

```elixir
@spec changeset(t(), map()) :: Ecto.Changeset.t()
```

# `flag_types`

```elixir
@spec flag_types() :: [atom()]
```

# `value_types`

```elixir
@spec value_types() :: [atom()]
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
