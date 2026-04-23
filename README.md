# Rulestead

> **Runtime decisions, made clear.**
> Batteries-included Elixir-native feature flags, experimentation, and
> remote config, with a mountable Phoenix LiveView admin.

> ⚠️ **Pre-release.** v0.1.0 is in active development (Phase 1 of 8). The
> quickstart below describes the target API for v0.1.0 and will ship as
> tested against published Hex tarballs in Phase 8. Track progress in
> [ROADMAP](.planning/ROADMAP.md).

## What this is (60 seconds)

Rulestead gives Elixir apps typed flags, staged rollouts, and a built-in
LiveView admin with explainability baked in. Every decision is intended to
be deterministic, auditable, and explainable, so operators can answer
"why did this flip?" without guesswork.

The repository is structured as two sibling packages from day one:
`rulestead` for the evaluation/runtime surface and `rulestead_admin` for
the optional mountable admin UI. Phase 1 establishes that shape, the CI
surface, and the release engineering spine.

## Who it's for

- App Dev: `Rulestead.enabled?("checkout_v2", conn)` in 15 minutes.
- Tech Lead: staged rollouts, auditability, and a clear release path.
- PM / Operator: a calm admin UI instead of terminal-only flag control.
- Support: explain pages for "why did user X see Y?"
- SRE: fast kill switch and health-focused runtime controls.
- OSS Contributor: narrow behaviours, explicit docs, and reproducible CI.

## 15-minute quickstart

```elixir
# 1. Add to mix.exs
{:rulestead, "~> 0.1"},
{:rulestead_admin, "~> 0.1"}
```

```bash
# 2. Install
mix deps.get
mix rulestead.install
mix ecto.migrate
```

```elixir
# 3. Use it
if Rulestead.enabled?("checkout_v2", conn) do
  render_v2(conn)
else
  render_v1(conn)
end
```

```elixir
# 4. Optional admin UI in your router
import Rulestead.Admin.Router

rulestead_admin "/admin/flags",
  policy: MyApp.RulesteadAdminPolicy
```

```bash
# 5. Toggle from CLI or UI
mix rulestead.set_flag checkout_v2 true --env dev
```

The full walkthrough for Context builders, variants, testing, and
LiveView helpers lands in
[Getting Started](guides/introduction/getting-started.md).

## Feature highlights

- Typed flags for boolean, string, integer, float, JSON, and variants.
- Deterministic bucketing so the same actor stays in the same bucket.
- Structured explain traces for support and incident response.
- Mountable admin UI with Phoenix-native seams.
- Release engineering designed for linked-version sibling packages.

## Current Phase

Phase 1 is repo bootstrap. That means:

- The package layout, docs surface, and CI/release foundation are being
  created now.
- The intended v0.1 API is documented here to pressure-test the shape
  early.
- Phase 8 is the first release merge. Release Please PRs stay advisory
  until then.

## Repository Layout

- `rulestead/`: core package
- `rulestead_admin/`: optional admin package
- `guides/`: shared docs consumed by ExDoc
- `.planning/`: roadmap, requirements, and phase execution artifacts
- `prompts/`: anchor docs and research context for future phases

## Contributing

Start with [CONTRIBUTING.md](CONTRIBUTING.md) for local setup and
[MAINTAINING.md](MAINTAINING.md) for the release and branch-protection
rules that keep the repo honest while the library is still pre-1.0.
