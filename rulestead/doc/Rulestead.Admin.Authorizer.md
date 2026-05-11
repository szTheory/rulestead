# `Rulestead.Admin.Authorizer`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/admin/authorizer.ex#L1)

Central policy gate for Phase 7 admin reads and writes.

# `audit_payload`

```elixir
@type audit_payload() :: %{
  action: atom(),
  result: :allowed | :denied,
  environment_key: String.t() | nil,
  resource: map(),
  actor: map()
}
```

# `authorize`

```elixir
@spec authorize(term(), atom(), term(), String.t() | atom() | nil) ::
  :ok | {:error, Rulestead.Error.t(), audit_payload()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
