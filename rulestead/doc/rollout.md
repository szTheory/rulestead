# Rollout

Rulestead rollouts are staged changes to authored rulesets, operated through
the mounted admin package and enforced by the same ordered-rules runtime model.
The stable contract is the host mount seam, the environment selector, and the
operator-facing routes. Internal LiveView modules and DOM details are not part
of the public promise.

## Mount The Admin First

Host apps mount the package in their router:

```elixir
scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The `policy:` option is required. Authorization remains host-owned through the
`Rulestead.Admin.Policy` behaviour.

## Stable Operator Paths

For rollouts, operators should expect these mounted URL shapes:

- `/admin/flags`
- `/admin/flags/:key`
- `/admin/flags/:key/rules`
- `/admin/flags/:key/rollouts`
- `/admin/flags/:key/kill`
- `/admin/flags/:key/timeline`

The `env` query parameter is the canonical environment selector for those
screens:

- `/admin/flags/checkout_v2/rollouts?env=staging`
- `/admin/flags/checkout_v2/rollouts?env=prod`

## Session Inputs The Host Must Provide

The mounted package expects bounded session data from the host app:

- `"current_actor"` for policy checks
- `"rulestead_admin_environments"` for the environment picker
- `"rulestead_admin_last_env"` for the remembered fallback when `?env=` is
  absent

That is the public host contract for operator flow. Do not couple your app to
internal admin module names or assigns.

## Recommended Rollout Loop

Use the same loop for every staged release:

1. Open the flag in the target environment.
2. Review the current rule order and default outcome.
3. Save draft changes until the rollout step looks right.
4. Publish the ruleset for that environment.
5. Verify the result through explainability or application telemetry.
6. Repeat for the next percentage or cohort expansion.

This keeps authored intent, publish moments, and verification steps separate.

## Design Rollout Steps Around Rules

The safest rollout steps are explicit rule changes, for example:

- internal users first
- one tenant or audience first
- a small percentage rule before a larger percentage rule
- default backstop remaining safe if the rollout rule is disabled

Because evaluation is first-match-wins, place emergency overrides and
high-priority cohorts above broader rollout rules.

## Explain Before Advancing

Before moving from one rollout stage to the next, confirm that a few canonical
subjects resolve as expected:

- a subject that should stay on control
- a subject that should move to treatment
- a subject outside all targeted cohorts

Use the explain flow for that spot check instead of inferring behavior from the
UI alone. The explain route keeps the reasoning human-readable and redacted.

## Kill Switch Is Part Of The Rollout Story

Every staged rollout should assume there is a fast stop path. The mounted admin
package exposes a dedicated kill screen at `/:key/kill` for that reason.

Use it when you need to:

- disable a bad rollout without editing several rules by hand
- halt treatment in one environment only
- give on-call operators a bookmarkable emergency path

After the incident, use the timeline route to document what changed and why.

## Keep Runtime And UI Contracts Separate

The runtime contract for a rollout is still the authored ruleset plus the
public `Rulestead` evaluation APIs. The admin package gives operators a mounted
workflow around that runtime. It does not make internal LiveView callbacks,
assign names, or HTML selectors part of the supported surface.
