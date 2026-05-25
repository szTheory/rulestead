# Admin UI

`rulestead_admin` is the mounted operator package for Rulestead. Its stable
host-facing surface is deliberately narrow: mount the package, supply a policy
module, provide bounded session inputs, and treat the documented route and
query conventions as the operator contract.

## Mount Seam

Mount the package from the host Phoenix router:

```elixir
scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The `policy:` option is required. Host apps own authorization through
`Rulestead.Admin.Policy.can?/4`.

## Canonical Role Model

`rulestead_admin` maps its views and capabilities to three conceptual roles. Your `Rulestead.Admin.Policy.can?/4` implementation enforces these boundaries:

1. **Viewer**: Can read flags, review change requests, explore environments, and inspect infrastructure diagnostics.
2. **Editor**: Can propose changes, create/update flags, submit change requests, and author draft state. Editors cannot publish directly to production.
3. **Admin**: Can publish flag changes, execute approved change requests, bypass approval rules (if configured), and manage webhook settings.

The UI gracefully degrades based on the actor's capabilities in the requested environment.

## What The Host Owns

The mounted package expects the host session to provide:

- `"current_actor"`
- `"rulestead_admin_environments"`
- `"rulestead_admin_last_env"`

The host application also owns:

- browser authentication
- actor identity and session lifecycle
- `can?/4` policy decisions defining viewer, editor, and admin capabilities per environment

That split is intentional. `rulestead_admin` is a mounted package, not a
bundled auth system.

## Stable Operator Navigation

Operators can treat these URL shapes as the stable v0.1.0 navigation layer:

- `/admin/flags`
- `/admin/flags/new`
- `/admin/flags/audit`
- `/admin/flags/:key`
- `/admin/flags/:key/edit`
- `/admin/flags/:key/rules`
- `/admin/flags/:key/simulate`
- `/admin/flags/:key/rollouts`
- `/admin/flags/:key/kill`
- `/admin/flags/:key/timeline`

The `env` query parameter is the canonical environment selector across the
mounted UI.

## What Operators Can Do

The shipped package supports these bounded workflows:

- browse and filter flags
- review one flag's details and environment state
- create and edit flag metadata
- save draft and publish rulesets
- simulate and explain one flag decision in one environment
- stage rollout changes
- engage or release a kill switch
- review redacted audit timeline entries and roll back supported changes

These are package-level workflows. They do not freeze the internal LiveView
implementation.

## What Is Not Public API

The following are intentionally not stable contracts:

- `RulesteadAdmin.Live.*` modules
- `RulesteadAdmin.Components.*` modules
- internal helper modules
- socket assigns
- CSS classes, DOM structure, and test selectors

If you need a stable integration point, use the router seam, policy behaviour,
session keys, and documented URL conventions instead.

## Operational Guidance

Treat the admin package as the control surface around runtime truth:

1. author or review the ruleset
2. publish the environment-specific change
3. verify outcome through explainability or telemetry
4. use timeline and rollback when you need to retrace or reverse a change

That keeps the operator story aligned with the core package's deterministic
runtime behavior.

## Related Guides

- [Rollout](rollout.md) for staged release workflows
- [Explainability](explainability.md) for support and simulation usage
- [Multi-env](multi-env.md) for environment selection and promotion habits
- [rulestead_admin README](../../rulestead_admin/README.md) for the package-local
  host contract
