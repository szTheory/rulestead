# Extending Rulestead

This guide is normative for `v0.1.0`.

The main body documents only the seams that ship today and are intended to be
supported for extenders:

- `Rulestead.Store`
- `Rulestead.Admin.Policy`
- the host-facing admin mount seam in `RulesteadAdmin.Router`

Anything else is either an application usage API or an internal implementation
detail unless this guide or `guides/api_stability.md` says otherwise.

## Start with the narrowest seam

Before extending Rulestead, decide which change you actually need:

- persistence or authoring backend change: implement `Rulestead.Store`
- host-owned admin authorization policy: implement `Rulestead.Admin.Policy`
- host Phoenix app mounting and routing: use `RulesteadAdmin.Router`

Do not start by depending on internal modules just because they exist in
source. `v0.1.0` is intentionally narrow about what it stabilizes.

## Supported seam: `Rulestead.Store`

[`Rulestead.Store`](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store.ex:1)
is the main extension seam for replacing or adapting the authoring backend.

Its contract is semantic rather than CRUD-shaped. The store is responsible for
operations such as fetching authored flag detail, publishing rulesets, listing
flags and environments, and returning normalized `{:ok, value}` or
`{:error, %Rulestead.Error{}}`.

### What an implementation must preserve

Your store implementation should:

- accept the published command structs expected by the public facade
- never return `nil` for not-found cases
- normalize failures into `{:error, %Rulestead.Error{}}`
- keep environment-scoped authoring behavior explicit
- return payloads that the public facade and docs already describe

At minimum, extenders should study the callbacks directly:

- `fetch_flag/1`
- `publish_ruleset/1`
- `list_flags/1`

### What this seam is for

Use `Rulestead.Store` when you need to:

- swap the persistence backend
- adapt Rulestead to an existing authoring system
- add a different storage strategy while keeping the same public facade

Do not use it when you only need to evaluate flags in your application code.

## Supported seam: `Rulestead.Admin.Policy`

[`Rulestead.Admin.Policy`](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/policy.ex:1)
is the host-owned authorization seam for mounted admin actions.

The contract is intentionally narrow:

```elixir
@callback can?(actor, action, resource, environment_key) :: boolean()
```

That means the host app owns auth decisions. Rulestead does not ship a bundled
role system, session stack, or opinionated authorization framework.

### What to implement

```elixir
defmodule MyApp.RulesteadPolicy do
  @behaviour Rulestead.Admin.Policy

  @impl true
  def can?(actor, action, _resource, environment_key) do
    MyApp.Authorizer.allowed?(actor, action, environment_key)
  end
end
```

Build richer auth in your host app and keep `can?/4` as the boundary.

## Supported seam: `RulesteadAdmin.Router`

The public admin integration seam is the mount macro exposed by
`RulesteadAdmin.Router`.

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use RulesteadAdmin.Router

  scope "/" do
    pipe_through :browser

    rulestead_admin "/flags", policy: MyApp.RulesteadPolicy
  end
end
```

This is a host-app seam, not an invitation to couple your app to internal
LiveView module names, CSS selectors, or socket assigns.

### What is stable here

For `v0.1.0`, the supported contract is:

- host apps mount via `rulestead_admin/2`
- `policy:` is required
- the package behaves like a mountable Phoenix UI package

### What is not stable here

The following remain internal unless documented elsewhere:

- `RulesteadAdmin.Live.*` module names
- component module names
- socket assign shapes
- DOM structure and CSS classes
- internal on-mount/session plumbing

Treat the router macro as the boundary, not the internals behind it.

## Extension design rules for `v0.1.0`

If you are extending Rulestead:

- extend through documented behavior or router seams first
- keep context propagation explicit across request, LiveView, and Oban
- do not depend on raw traits or PII flowing through telemetry metadata
- do not bypass the runtime with request-path store queries
- do not turn roadmap prose into an implied support promise

## How to decide whether a seam is public

A seam is public in `v0.1.0` only if it is backed by all three:

1. shipped code
2. documentation that treats it as supported
3. tests or release verification that exercise it as contract material

If one of those is missing, treat the seam as non-public.

## Appendix: Planned Seams Excluded From `v0.1.0` API Stability

The names below may appear in roadmap or planning material, but they are not
part of the supported `v0.1.0` extension contract and are excluded from
`guides/api_stability.md` until they ship as documented, tested seams.

### `Rulestead.RuleEngine`

Planned or experimental name only. Not a shipped public behavior in `v0.1.0`.

### `Rulestead.EvaluationCache`

Planned or experimental name only. Runtime cache internals are not a public
extension seam in `v0.1.0`.

### `Rulestead.AuditStore`

Planned or experimental name only. Audit behavior remains behind the existing
store and admin surfaces in `v0.1.0`.

### `Rulestead.ActorResolver`

Planned or experimental name only. Actor shaping remains host-owned application
logic plus the narrow `Rulestead.Admin.Policy` seam.
