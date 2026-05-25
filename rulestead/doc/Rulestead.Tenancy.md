# `Rulestead.Tenancy`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/tenancy.ex#L1)

Explicit seam for resolving and bounding tenant scope across runtime helpers.

# `tenant_scope`

```elixir
@type tenant_scope() :: String.t() | atom() | nil
```

# `compose_bucket_identity`

```elixir
@callback compose_bucket_identity(
  context :: Rulestead.Context.t(),
  bucket_by :: atom() | String.t(),
  default_identity :: String.t() | nil
) :: String.t() | nil
```

# `resolve_tenant`

```elixir
@callback resolve_tenant(conn_or_socket_or_params :: term()) :: tenant_scope()
```

# `same_tenant?`

```elixir
@callback same_tenant?(a :: tenant_scope(), b :: tenant_scope()) :: boolean()
```

# `tenant_topic`

```elixir
@callback tenant_topic(base_topic :: String.t(), tenant :: tenant_scope()) :: String.t()
```

# `compose_bucket_identity`

```elixir
@spec compose_bucket_identity(
  Rulestead.Context.t(),
  atom() | String.t(),
  String.t() | nil
) ::
  String.t() | nil
```

# `module`

```elixir
@spec module() :: module()
```

# `normalize_tenant`

```elixir
@spec normalize_tenant(term()) :: tenant_scope()
```

# `resolve_tenant`

```elixir
@spec resolve_tenant(term()) :: tenant_scope()
```

# `same_tenant?`

```elixir
@spec same_tenant?(tenant_scope(), tenant_scope()) :: boolean()
```

# `tenant_topic`

```elixir
@spec tenant_topic(String.t(), tenant_scope()) :: String.t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
