# `Rulestead.Error`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/error.ex#L1)

Stable public error envelope for all non-bang and bang APIs.

`Rulestead` returns this struct in `{:error, error}` tuples and raises the same
struct from bang variants. Typed helper modules such as `Rulestead.StoreError`
construct this envelope instead of introducing competing public error structs.

# `detail`

```elixir
@type detail() :: %{optional(detail_key()) =&gt; detail_value()}
```

# `detail_key`

```elixir
@type detail_key() :: atom() | String.t()
```

# `detail_value`

```elixir
@type detail_value() :: nil | boolean() | integer() | float() | atom() | String.t()
```

# `domain`

```elixir
@type domain() :: :evaluation | :ruleset | :kill_switch | :config | :store | :auth
```

Top-level error family used to group stable leaf error types.

# `metadata`

```elixir
@type metadata() :: %{optional(metadata_key()) =&gt; metadata_scalar()}
```

# `metadata_key`

```elixir
@type metadata_key() :: atom() | String.t()
```

# `metadata_scalar`

```elixir
@type metadata_scalar() :: nil | boolean() | integer() | float() | atom() | String.t()
```

# `t`

```elixir
@type t() :: %Rulestead.Error{
  __exception__: true,
  cause: term(),
  details: [detail()],
  domain: domain(),
  message: String.t(),
  metadata: metadata(),
  plug_status: nil | pos_integer(),
  type: type()
}
```

# `type`

```elixir
@type type() ::
  :flag_not_found
  | :environment_not_found
  | :ruleset_not_found
  | :missing_targeting_key
  | :repo_not_configured
  | :repo_ambiguous
  | :store_not_configured
  | :store_adapter_invalid
  | :store_unavailable
  | :invalid_command
  | :invalid_ruleset
  | :variant_weights_invalid
  | :invalid_value_projection
  | :malformed_runtime_data
  | :flag_archived
  | :unauthorized
  | :kill_switch_active
  | :not_implemented
```

Closed Phase 2 leaf error atoms.

Downstream phases should extend this list deliberately when they add new public
failure modes rather than returning broad atoms such as `:invalid` or `:not_found`.

# `domains`

```elixir
@spec domains() :: [domain()]
```

Returns the stable top-level error domains.

# `leaf_types`

```elixir
@spec leaf_types() :: [type()]
```

Returns the closed Phase 2 leaf error atoms.

# `new`

```elixir
@spec new(keyword() | map()) :: t()
```

Builds a new normalized error struct.

# `normalize`

```elixir
@spec normalize(t() | keyword() | map()) :: t()
```

Normalizes a term into a `Rulestead.Error`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
