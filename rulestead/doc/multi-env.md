# Multi-environment Operation

Rulestead keeps one flag identity with environment-specific authored behavior.
Operators should think in terms of the same flag moving through `dev`,
`staging`, and `prod`, not three unrelated flags.

## Canonical Environment Selector

In the mounted admin package, the URL query parameter `env` is the canonical
environment selector:

- `/admin/flags?env=dev`
- `/admin/flags/checkout_v2?env=staging`
- `/admin/flags/checkout_v2/rollouts?env=prod`

If `env` is missing, the package may fall back to the host-provided
`"rulestead_admin_last_env"` session value. The host also provides the available
picker options through `"rulestead_admin_environments"`.

## Why The Query Param Matters

Treat `?env=` as part of the operator contract because it keeps workflows:

- bookmarkable
- shareable across operators
- explicit in incident notes and rollout reviews

That is a better seam than reaching into internal admin state.

## Recommended Promotion Pattern

Use the same flag across environments, but advance it deliberately:

1. author and verify in `dev`
2. publish and rehearse in `staging`
3. promote and monitor in `prod`

Keep the authored intent recognizable across environments even when the exact
rule values differ. For example, the same rollout rule may be `100%` in staging
 but `10%` in prod while the rollout is still live.

## Environment-Specific Work

The environment selector matters for every operator workflow:

- list and detail views show one environment's current truth at a time
- rules drafts and publish actions apply in the selected environment
- explain and simulation should always name the environment explicitly
- kill switch actions are per-flag and per-environment
- timeline review should be read in the environment where the change happened

This is how the package preserves a single flag identity without losing
operational clarity.

## Runtime Perspective

Outside the admin UI, keyed runtime APIs also require the environment:

- `Rulestead.Runtime.evaluate(environment_key, flag_key, context)`
- `Rulestead.Runtime.enabled?(environment_key, flag_key, context)`
- `Rulestead.Runtime.get_value(environment_key, flag_key, context, default)`
- `Rulestead.Runtime.get_variant(environment_key, flag_key, context)`
- `Rulestead.Runtime.explain(environment_key, flag_key, context)`

That mirrors the operator flow: environment is always explicit.

## Keep Secrets And Policies Out Of The Guide

Multi-environment support does not imply built-in auth or tenant policy. The
host app still owns:

- which environments appear in the picker
- who may read or change each environment
- how environment names map to deployment or compliance boundaries

Rulestead documents the mount seam and environment convention, then leaves those
authorization choices to the host policy module.
