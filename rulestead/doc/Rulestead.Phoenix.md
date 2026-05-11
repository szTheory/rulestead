# `Rulestead.Phoenix`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/phoenix.ex#L1)

Explicit Phoenix-facing helpers for building `%Rulestead.Context{}` values.

This module keeps framework structs at the edge and only projects configured,
bounded fields into the runtime context.

# `source`

```elixir
@type source() ::
  {:assign, atom() | String.t()}
  | {:session, atom() | String.t()}
  | {:header, String.t()}
  | {:cookie, atom() | String.t()}
  | {:param, atom() | String.t()}
  | {:private, atom() | String.t()}
  | (map() -&gt; term())
  | term()
```

# `context_from_conn`

```elixir
@spec context_from_conn(
  map(),
  keyword()
) :: Rulestead.Context.t()
```

Builds a normalized context from a conn-like map.

Supported source descriptors are explicit and caller-visible:

- `{:assign, key}`
- `{:session, key}`
- `{:header, name}`
- `{:cookie, key}`
- `{:param, key}`
- `{:private, key}`
- `fn conn -> ... end`
- literal values

---

*Consult [api-reference.md](api-reference.md) for complete listing*
