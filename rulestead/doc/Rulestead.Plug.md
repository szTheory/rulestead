# `Rulestead.Plug`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/plug.ex#L1)

Plug-facing seam that assigns a normalized `%Rulestead.Context{}` onto
`conn.assigns[:rulestead_context]`.

# `call`

```elixir
@spec call(
  map(),
  keyword()
) :: map()
```

# `init`

```elixir
@spec init(keyword()) :: keyword()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
