# rulestead_admin

`rulestead_admin` is the optional mounted admin package for Rulestead.

Repo GA shipped in `v1.0.0` on 2026-05-21, and the current installable package
line for `rulestead_admin` is `0.1.0`. This package stays documented as the
mounted companion rather than a standalone control-plane product; the broader
release and proof posture lives in [../README.md](../README.md).

The canonical flag from birth to retirement guide lives in the shared root docs
at [../guides/flows/flag-lifecycle.md](../guides/flows/flag-lifecycle.md). Use
this README for the mounted companion contract, not as a second lifecycle
walkthrough.

This README documents the host-facing contract only. Internal LiveView modules,
socket assigns, CSS/DOM structure, and other implementation details are not
part of the public package promise.

## Mount seam

## Install

Add `rulestead_admin` only when a Phoenix host app needs the mounted companion
surface alongside the runtime package:

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:rulestead_admin, "~> 0.1"}
  ]
end
```

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

The host must also provide the documented actor/session inputs and environment
list that the mounted companion consumes. If the host omits required
prerequisites or presents an unsupported combination, the mounted surface
fails closed instead of inventing package-owned auth or environment truth.

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
- `"rulestead_admin_last_env"` as a remembered fallback only when the URL omits
  `env`

The host continues to own authentication, actor identity, session lifecycle,
and policy enforcement. `rulestead_admin` consumes those seams; it does not
replace them with a package-owned auth model. The host owns auth, identity,
policy, and session truth; `rulestead_admin` only renders that host-owned
contract.

## URL contract

The query param `?env=` is the canonical environment selector for mounted admin
pages. Host apps should preserve it in links and redirects when they build
adjacent tooling around the admin surface.

Remembered env/session values are fallback-only convenience when URL scope is
absent. When `?env=` is present, it wins over remembered state and should be
treated as the supportable, shareable route contract.

Lifecycle review links should also preserve `return_to` when operators move
from the queue into cleanup, preview, confirm, and back to audit or the queue.
That keeps the mounted workflow shareable without freezing every internal route
detail as public API.

## When to install this package

Add `rulestead_admin` only when your Phoenix app needs the mounted operator UI.
Applications that only evaluate flags at runtime can depend on `rulestead`
alone.

The host still owns actor identity, session truth, and owner truth for the
lifecycle workflow. The mounted companion surfaces that data; it does not
replace it.

The supported lifecycle workflow is `cleanup -> preview -> confirm -> audit`.
Treat that as the documented operator path. The stable contract remains
narrower: mount seam, `policy:`, required session keys, `?env=`, and
queue-preserving `return_to`.

The bounded verification proof for this mounted companion surface lives at
`RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`. That
proof bar covers the mounted lifecycle/admin contract only; it should not be
read as a claim that every admin-facing screen or future companion workflow is
fully closed.

Use the root docs at [../README.md](../README.md) for the broader release and
proof posture. Use this package README for the exact mounted host seam:
required `policy:`, host-owned actor/session/environment prerequisites,
fail-closed behavior, canonical `?env=`, and fallback-only remembered env
state.

## Next docs

- Root overview: [../README.md](../README.md)
- Installation choices: [../guides/introduction/installation.md](../guides/introduction/installation.md)
- Lifecycle guide: [../guides/flows/flag-lifecycle.md](../guides/flows/flag-lifecycle.md)
- Operator guidance: [../guides/flows/admin-ui.md](../guides/flows/admin-ui.md)
