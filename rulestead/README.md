# rulestead

> **Runtime decisions, made clear.**

Typed feature flags, variants, and remote config for Elixir and Phoenix apps —
deterministic evaluation, explainable decisions, and fake-backed tests without
Postgres on the hot path.

Install `{:rulestead, "~> 0.1"}` (currently **0.1.x** on Hex).

> **Two version lines:** GitHub repo milestones (e.g. `v1.0.0` GA, May 2026)
> track project delivery. **Hex packages** use `0.1.x` semver until a future `1.0`
> API freeze.

## What you get (60 seconds)

- Pure `Rulestead.evaluate/3` on flag payloads + `%Rulestead.Context{}`
- Keyed snapshot runtime via `Rulestead.Runtime.*` for Phoenix apps
- Ordered rules, sticky bucketing, first-match-wins precedence
- Explain API for support and incident response
- Installer, migrations, and `Rulestead.Fake` for tests

Optional sibling package [`rulestead_admin`](https://hexdocs.pm/rulestead_admin)
adds a mounted LiveView operator UI — only when your app needs it.

## Install

Host apps need `ecto_sql ~> 3.14`.

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:ecto_sql, "~> 3.14"}
  ]
end
```

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

Phoenix integrators: follow the
[Phoenix Integration Spine](https://hexdocs.pm/rulestead/phoenix-integration-spine.html)
for supervision → Plug → `Rulestead.Runtime` → lifecycle-honest flag create.

## Runtime entrypoints

**Keyed lookup** (typical Phoenix path):

- `Rulestead.Runtime.enabled?/3`
- `Rulestead.Runtime.evaluate/3`
- `Rulestead.Runtime.explain/3`

**Payload-first** (tests and tools):

- `Rulestead.evaluate/3`
- `Rulestead.explain/2`

See [Evaluation](https://hexdocs.pm/rulestead/evaluation.html).

## Choose your path

| You are… | Start here |
|----------|------------|
| **Evaluating** before install | [Adoption Lab demo](https://github.com/szTheory/rulestead/blob/main/guides/introduction/adoption-lab.md) — `docker compose up --build` |
| **Integrating** into Phoenix | [Getting Started](https://hexdocs.pm/rulestead/getting-started.html) → [Installation](https://hexdocs.pm/rulestead/installation.html) |
| **Operating** flags | [Flag Lifecycle](https://hexdocs.pm/rulestead/flag-lifecycle.html) → [Admin UI](https://hexdocs.pm/rulestead/admin-ui.html) |
| **Supporting** users | [Explainability](https://hexdocs.pm/rulestead/explainability.html) |
| **Testing** | [Testing recipes](https://hexdocs.pm/rulestead/testing.html) |

## Monorepo and docs

Full guide index: [hexdocs.pm/rulestead](https://hexdocs.pm/rulestead)

GitHub monorepo (demo app, contributing, maintainer docs):
[github.com/szTheory/rulestead](https://github.com/szTheory/rulestead)
