# `Rulestead.Oban`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/oban.ex#L1)

Explicit Oban-facing helpers for serializing and restoring
`%Rulestead.Context{}` values across job boundaries.

# `context_from_job`

```elixir
@spec context_from_job(
  map(),
  keyword()
) :: Rulestead.Context.t()
```

Restores a normalized context from a job-like map.

# `put_context`

```elixir
@spec put_context(map(), Rulestead.Context.t() | keyword() | map(), keyword()) ::
  map()
```

Attaches a serialized context payload to a job-like map.

# `serialize_context`

```elixir
@spec serialize_context(Rulestead.Context.t() | keyword() | map()) :: map()
```

Produces the bounded, serializable context payload used by Oban seams.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
