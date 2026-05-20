# rulestead_admin

`rulestead_admin` is the optional mounted admin package for Rulestead.

The first public Hex release for `rulestead_admin` is planned for after
`v0.6.0`, and the package will stay documented as the mounted admin companion
rather than a standalone control-plane product.

This README documents the host-facing contract only. Internal LiveView modules,
socket assigns, CSS/DOM structure, and other implementation details are not
part of the public package promise.

## Mount seam

Mount the admin routes from the host router with the package macro:

```elixir
import RulesteadAdmin.Router

scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The `policy:` option is required. The host policy module owns authorization via
the `Rulestead.Admin.Policy.can?/4` behaviour.

## Canonical Role Model

`rulestead_admin` maps its views and capabilities to three conceptual roles. Your `Rulestead.Admin.Policy.can?/4` implementation enforces these boundaries:

1. **Viewer**: Can read flags, review change requests, explore environments, and inspect infrastructure diagnostics.
2. **Editor**: Can propose changes, create/update flags, submit change requests, and author draft state. Editors cannot publish directly to production.
3. **Admin**: Can publish flag changes, execute approved change requests, bypass approval rules (if configured), and manage webhook settings.

The UI gracefully degrades based on the actor's capabilities in the requested environment.

## Host session contract

The mounted package expects the host session to provide:

- `"current_actor"` for policy checks
- `"rulestead_admin_environments"` as the environment picker source
- `"rulestead_admin_last_env"` as the remembered fallback when the URL omits `env`

## URL contract

The query param `?env=` is the canonical environment selector for mounted admin
pages. Host apps should preserve it in links and redirects when they build
adjacent tooling around the admin surface.

## When to install this package

Add `rulestead_admin` only when your Phoenix app needs the mounted operator UI.
Applications that only evaluate flags at runtime can depend on `rulestead`
alone.

## Next docs

- Root overview: [../README.md](../README.md)
- Installation choices: [../guides/introduction/installation.md](../guides/introduction/installation.md)
- Operator guidance: [../guides/flows/admin-ui.md](../guides/flows/admin-ui.md)
