# `Rulestead.LiveView`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/live_view.ex#L1)

Explicit LiveView helpers for carrying `%Rulestead.Context{}` and eagerly
assigning runtime-backed flag values onto a socket.

# `flag_projection`

```elixir
@type flag_projection() ::
  String.t()
  | atom()
  | {:enabled, String.t() | atom()}
  | {:variant, String.t() | atom()}
  | {:value, String.t() | atom(), term()}
  | {:evaluate, String.t() | atom()}
  | %{
      :flag_key =&gt; String.t() | atom(),
      optional(:mode) =&gt; atom(),
      optional(:default) =&gt; term()
    }
```

# `assign_flags`

```elixir
@spec assign_flags(map(), map() | keyword() | [flag_projection()], keyword()) :: map()
```

Resolves a set of runtime-backed flag projections and writes them into socket
assigns in one pass.

# `context_from_socket`

```elixir
@spec context_from_socket(
  map(),
  keyword()
) :: Rulestead.Context.t()
```

Builds a normalized context from a socket-like map and explicit session data.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
