defmodule OpenFeatureRulestead.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/szTheory/rulestead"
  @homepage_url "https://hexdocs.pm/open_feature_rulestead"

  def project do
    [
      app: :open_feature_rulestead,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:open_feature, "~> 0.1.3"},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false},
      rulestead_dep()
    ]
  end

  defp rulestead_dep do
    if System.get_env("OPEN_FEATURE_RULESTEAD_HEX_RELEASE") == "1" do
      {:rulestead, "~> 1.0"}
    else
      {:rulestead, path: "../rulestead"}
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: "open_feature_rulestead",
      description:
        "OpenFeature provider for Rulestead — evaluate feature flags through the standard OpenFeature SDK backed by Rulestead's deterministic runtime.",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @homepage_url,
        "Changelog" => "#{@source_url}/blob/main/open_feature_rulestead/CHANGELOG.md"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "open_feature_rulestead-v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        "OpenFeature Provider": [
          OpenFeatureRulestead.Provider,
          OpenFeatureRulestead.ContextMapper
        ]
      ],
      skip_undefined_reference_warnings_on: fn ref ->
        is_binary(ref) and
          (String.starts_with?(ref, "Rulestead.") or
             String.starts_with?(ref, "OpenFeature."))
      end
    ]
  end
end
