# `Rulestead.Admin.Policy`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/admin/policy.ex#L1)

Host-owned authorization seam for mounted admin actions.

`rulestead_admin` calls `can?/4` with explicit actor, action, resource,
and environment scope rather than inferring authorization from roles.

# `can?`

```elixir
@callback can?(
  actor :: term(),
  action :: atom(),
  resource :: term(),
  environment_key :: String.t() | atom() | nil
) :: boolean()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
