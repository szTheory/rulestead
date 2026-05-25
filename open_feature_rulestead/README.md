# OpenFeatureRulestead

`open_feature_rulestead` is the optional OpenFeature companion for Rulestead's
Elixir runtime.

Use it when a host application already uses the Elixir
[`open_feature`](https://hex.pm/packages/open_feature) SDK and wants
OpenFeature evaluations to resolve through `Rulestead.Runtime` instead of a
custom provider adapter.

## Current posture

- Repo GA shipped in `v1.0.0` on 2026-05-21, while this companion package
  remains on the installable `0.1.0` line with the rest of the sibling
  packages.
- This package is a secondary companion surface, not the primary front door.
- The package contract is the Elixir provider shown below. The browser demo in
  [../examples/demo/README.md](../examples/demo/README.md) is a secondary,
  host-owned example.

## Install

Add the Elixir OpenFeature SDK plus the Rulestead provider companion:

```elixir
defp deps do
  [
    {:open_feature, "~> 0.1.3"},
    {:open_feature_rulestead, "~> 0.1"}
  ]
end
```

Then fetch dependencies:

```bash
mix deps.get
```

Your host app is still responsible for configuring and booting `rulestead`
itself. This companion only provides the OpenFeature provider layer.

## Provider setup

Initialize the provider with an explicit OpenFeature domain that matches the
Rulestead environment you want to evaluate against. In this package, that
domain becomes the provider's `environment_key`.

```elixir
provider = %OpenFeatureRulestead.Provider{}

{:ok, provider} =
  OpenFeatureRulestead.Provider.initialize(provider, "production", %{})

OpenFeature.set_provider(provider, domain: "production")
```

Two setup footguns are intentional and should stay explicit:

- `environment_key` is required. `initialize/3` returns `{:error,
  :invalid_context}` when the domain/environment is missing or blank.
- OpenFeature context is translated into `%Rulestead.Context{}` rather than
  passed through opaquely.

## Context mapping boundary

`OpenFeatureRulestead.ContextMapper.translate/1` recognizes these standard
OpenFeature keys and maps them into the matching Rulestead fields:

- `targetingKey`
- `tenantKey`
- `environment`
- `sessionId`
- `requestId`
- `actor`

Any other keys stay available as custom context attributes under
`%Rulestead.Context{attributes: ...}`.

## Resolution metadata boundary

The provider returns OpenFeature `ResolutionDetails` values and exposes only
the documented scalar metadata from `Rulestead.Result`:

- `matched_rule`
- `flag_version`
- `cache_age_ms`

It does not promise the full internal Rulestead explanation payload through the
OpenFeature metadata surface.

## Package-local proof

The package-local proof command is:

```bash
mix test test/open_feature_rulestead/context_mapper_test.exs \
  test/open_feature_rulestead/provider_test.exs
```

Run it from `open_feature_rulestead/`. This is the primary proof bar for the
Elixir provider contract taught in this README.

## Demo and repo-level proof

If you also want a browser-facing example, see
[../examples/demo/README.md](../examples/demo/README.md). That path uses
host-owned HTTP and frontend glue on top of this package and should be treated
as a secondary demo surface, not the package contract.

For the shared repo support posture, start from [../README.md](../README.md)
and [../MAINTAINING.md](../MAINTAINING.md).
