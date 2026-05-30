# Upgrading

Repo GA shipped in `v1.0.0` on 2026-05-21, while the current installable
packages on Hex are at **`0.1.5`** (`~> 0.1`). Most teams will still be adopting rather
than upgrading, but the compatibility posture is still important:

> **Two version lines:** GitHub repo milestones track project delivery. **Hex
> packages** use `0.1.x` semver until a future `1.0` API freeze.

- Patch releases in `v0.1.x` should preserve documented behavior and fix bugs
- Minor releases before `1.0` may tighten or reshape public contracts when the
  release notes call that out explicitly
- Anything not documented as public should be treated as internal

## What to review before upgrading

- The package `CHANGELOG.md` files in `rulestead/` and `rulestead_admin/`
- The installation and getting-started guides if your host integration changed
- The [rulestead_admin HexDocs](https://hexdocs.pm/rulestead_admin) if your host app mounts the admin UI

## Public contract posture

Treat the package READMEs and shipped guides as the supported contract set for
the current `0.1.x` package line.

## Practical rule

If your app depends on internal module names, socket assigns, or DOM/CSS
details inside `rulestead_admin`, you are outside the supported upgrade
boundary for `v0.1.x`. Keep host integrations on the documented router seam,
`policy:` behavior, session keys, and `?env=` URL convention.

Maintainers: proof bars and release verification are documented in
[MAINTAINING.md](https://github.com/szTheory/rulestead/blob/main/MAINTAINING.md).
