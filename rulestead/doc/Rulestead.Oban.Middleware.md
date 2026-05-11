# `Rulestead.Oban.Middleware`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/oban/middleware.ex#L1)

Explicit enqueue seam for attaching a serialized rulestead context to jobs.

# `attach`

```elixir
@spec attach(
  map(),
  keyword()
) :: map()
```

Attaches the caller-provided context to a job-like map.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
