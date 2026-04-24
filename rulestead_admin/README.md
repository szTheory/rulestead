# rulestead_admin

`rulestead_admin` is the optional mounted LiveView admin package for Rulestead.

Phase 6 ships the mounted list, detail, metadata form, and dedicated rules
workspace surfaces. The package remains unpublished until Phase 8.

## Mount seam

Mount the admin routes from the host router with the package macro:

```elixir
scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The `policy:` option is required. The policy module owns host authorization
through the `Rulestead.Admin.Policy` behaviour.

## Session and environment model

The mounted package expects the host session to provide:

- `"current_actor"` for policy checks
- `"rulestead_admin_environments"` as the environment picker source
- `"rulestead_admin_last_env"` as the remembered fallback when the URL omits `?env=`

The URL query param `env` is the canonical environment selector for all Phase 6
screens, including the dedicated `/admin/flags/:key/rules` workspace.

## Rules workspace

The rules workspace keeps `Save draft` and `Publish` as distinct actions and
loads reusable audience definitions through `Rulestead.list_audiences/1`. This
lets segment-match rules reference shared audiences instead of repeating inline
conditions for every flag.

## Not in this package yet

Phase 7 workflows are still absent here. The package does not yet ship:

- simulation or explain workbenches
- rollout controls
- kill switch UI
- audit timeline drilldowns
