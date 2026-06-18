# Upgrading

Repo GA shipped in `v1.0.0` on 2026-05-21, and the current installable
packages on Hex are on the **`1.x`** line (`~> 1.0`). Most teams will still be adopting rather
than upgrading, but the compatibility posture is still important:

- Patch releases in `1.x` should preserve documented behavior and fix bugs
- Minor releases on `1.x` may add public contracts but will not break them
  outside an explicit, release-noted major bump
- Anything not documented as public should be treated as internal

## Upgrading 0.1.x → 1.0

**Promotion, not rewrite.** The `1.0.0` release is the *same* battle-tested code
that shipped on the earlier line — just honestly versioned. There are **zero
breaking changes** and **no code changes** required on your side. Nothing in the
public surface moved, renamed, or changed behavior.

The entire upgrade is a single **dependency-pin bump** — point your `mix.exs`
at the `1.x` line:

```elixir
def deps do
  [
    {:rulestead, "~> 1.0"},
    {:rulestead_admin, "~> 1.0"}
  ]
end
```

Then run `mix deps.get`. That is the whole upgrade. Because this is a promotion
and not a rewrite, you do **not** need to audit call sites, adjust configuration,
or change any host-app integration — the documented router seam, `policy:`
behavior, session keys, and `?env=` convention are all unchanged.

## What to review before upgrading

- The package `CHANGELOG.md` files in `rulestead/` and `rulestead_admin/`
- The installation and getting-started guides if your host integration changed
- The [rulestead_admin HexDocs](https://hexdocs.pm/rulestead_admin) if your host app mounts the admin UI

## Public contract posture

Treat the package READMEs and shipped guides as the supported contract set for
the current `1.x` package line.

## Practical rule

If your app depends on internal module names, socket assigns, or DOM/CSS
details inside `rulestead_admin`, you are outside the supported upgrade
boundary for `1.x`. Keep host integrations on the documented router seam,
`policy:` behavior, session keys, and `?env=` URL convention.

Maintainers: proof bars and release verification are documented in
[MAINTAINING.md](https://github.com/szTheory/rulestead/blob/main/MAINTAINING.md).
