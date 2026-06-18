# rulestead_admin

> Mountable Phoenix LiveView admin for Rulestead.

Optional sibling package for host apps that need an operator surface — flag
inventory, rollouts, kill switch, audit, audiences, and governance workflows.
Your app owns auth, policy, and session; this package renders inside your router.

Install `{:rulestead_admin, "~> 1.0"}` alongside `rulestead` from Hex.

This is a **mounted companion**, not a standalone control plane.

## Install

```elixir
defp deps do
  [
    {:rulestead, "~> 1.0"},
    {:rulestead_admin, "~> 1.0"}
  ]
end
```

Mount from your host router (the `policy:` option is required):

```elixir
import RulesteadAdmin.Router

scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

Include the packaged stylesheet in your root layout:

```heex
<link phx-track-static rel="stylesheet" href={~p"/assets/css/rulestead_admin.css"} />
```

Copy `priv/static/css/rulestead_admin.css` from this package into your asset
pipeline during build. See the
[Admin UI guide](https://hexdocs.pm/rulestead/admin-ui.html).

## Host session contract

The mounted UI expects your session to provide:

- `"current_actor"` — for `Rulestead.Admin.Policy.can?/4`
- `"rulestead_admin_environments"` — environment picker source
- `"rulestead_admin_last_env"` — remembered fallback when URL omits `env`

The host owns authentication, actor identity, and authorization. The admin
package consumes those seams; it does not ship an auth stack.

## URL contract

`?env=` is the canonical environment selector on mounted pages. When present in
the URL, it wins over remembered session state. Preserve it in links and
redirects when building adjacent tooling.

## Roles

The UI maps to three conceptual roles enforced by your policy module:

1. **Viewer** — read flags, audit, diagnostics
2. **Editor** — propose changes and drafts; no direct prod publish
3. **Admin** — publish, execute change requests, kill switch

## Choose your path

| You are… | Start here |
|----------|------------|
| **Mounting** the admin | [Admin UI guide](https://hexdocs.pm/rulestead/admin-ui.html) |
| **Lifecycle** workflows | [Flag Lifecycle](https://hexdocs.pm/rulestead/flag-lifecycle.html) |
| **Evaluating** the full stack | [Adoption Lab demo](https://github.com/szTheory/rulestead/blob/main/guides/introduction/adoption-lab.md) |
| **Installing** both packages | [Installation](https://hexdocs.pm/rulestead/installation.html) |

Package docs: [hexdocs.pm/rulestead_admin](https://hexdocs.pm/rulestead_admin)

Monorepo: [github.com/szTheory/rulestead](https://github.com/szTheory/rulestead)
