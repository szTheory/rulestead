# Upgrading

Repo GA shipped in `v1.0.0` on 2026-05-21, while the current installable
packages on Hex are at **`0.1.1`** (`~> 0.1`). Most teams will still be adopting rather
than upgrading, but the compatibility posture is still important:

- Patch releases in `v0.1.x` should preserve documented behavior and fix bugs
- Minor releases before `1.0` may tighten or reshape public contracts when the
  release notes call that out explicitly
- Anything not documented as public should be treated as internal

## Proof today

Support truth is intentionally bounded to the seams we can verify today:

- [../../examples/demo/README.md](../../examples/demo/README.md) is the primary
  runnable demo proof path.
- `cd rulestead && mix verify.adopter` (delegates to `mix verify.phase76`) is the
  integrator proof bar for the post-GA doc band.
- `mix verify.release_publish <version>` proves a published consumer can install
  the current package line and reach the published docs.
- `mix verify.release_parity <version>` proves the git tag and Hex tarball stay
  aligned for that release.

Anything outside those seams should be read as guidance, not as a broader
closed support guarantee.

## What to review before upgrading

- The package `CHANGELOG.md` files in `rulestead/` and `rulestead_admin/`
- The installation and getting-started guides if your host integration changed
- The admin package README if your host app mounts the admin UI

## Public contract posture

Treat the root README, package READMEs, and shipped guides as the supported
contract set for the current `0.1.x` package line. This phase keeps the support
story bounded instead of pointing at future documentation that has not shipped.

## Practical rule

If your app depends on internal module names, socket assigns, or DOM/CSS
details inside `rulestead_admin`, you are outside the supported upgrade
boundary for `v0.1.x`. Keep host integrations on the documented router seam,
`policy:` behavior, session keys, and `?env=` URL convention.
