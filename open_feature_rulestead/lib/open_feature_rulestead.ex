defmodule OpenFeatureRulestead do
  @moduledoc """
  OpenFeature provider for Rulestead — evaluate feature flags through the
  standard [OpenFeature](https://openfeature.dev/) SDK backed by
  `Rulestead.Runtime`'s deterministic, auditable evaluation engine.

  Use this package when your host application already uses the Elixir
  [`open_feature`](https://hex.pm/packages/open_feature) SDK and wants
  OpenFeature evaluations to resolve through Rulestead instead of a custom
  provider adapter.

  ## Install

  Add the OpenFeature SDK and the Rulestead provider companion to your
  `mix.exs`:

      defp deps do
        [
          {:open_feature, "~> 0.1.3"},
          {:open_feature_rulestead, "~> 1.0"}
        ]
      end

  Then fetch dependencies:

      mix deps.get

  Your host application is still responsible for configuring and booting
  `rulestead` itself. This companion only provides the OpenFeature provider
  layer.

  ## Provider setup

  Initialize the provider with an OpenFeature domain matching the Rulestead
  environment you want to evaluate against:

      provider = %OpenFeatureRulestead.Provider{}
      {:ok, provider} =
        OpenFeatureRulestead.Provider.initialize(provider, "production", %{})
      OpenFeature.set_provider(provider, domain: "production")

  See `OpenFeatureRulestead.Provider` for full API details and
  `OpenFeatureRulestead.ContextMapper` for context translation rules.
  """
end
