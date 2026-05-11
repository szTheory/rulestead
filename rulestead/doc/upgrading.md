# Upgrading

`v0.1.0` is the first public release, so most teams will be adopting rather
than upgrading. The compatibility posture is still important:

- Patch releases in `v0.1.x` should preserve documented behavior and fix bugs
- Minor releases before `1.0` may tighten or reshape public contracts when the
  release notes call that out explicitly
- Anything not documented as public should be treated as internal

## What to review before upgrading

- The package `CHANGELOG.md` files in `rulestead/` and `rulestead_admin/`
- The installation and getting-started guides if your host integration changed
- The admin package README if your host app mounts the admin UI

## Public contract posture

Later in Phase 8, `guides/api_stability.md` will become the explicit inventory
for the locked `v0.1.x` public surface. Until that guide lands, treat the root
README, package READMEs, and shipped guides as the supported contract set.

## Practical rule

If your app depends on internal module names, socket assigns, or DOM/CSS
details inside `rulestead_admin`, you are outside the supported upgrade
boundary for `v0.1.x`. Keep host integrations on the documented router seam,
`policy:` behavior, session keys, and `?env=` URL convention.
