defmodule OpenFeatureRulestead.MixProject do
  use Mix.Project

  @version "0.1.0"
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
      package: package()
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
      {:rulestead, path: "../rulestead"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: "open_feature_rulestead",
      description: "OpenFeature provider for Rulestead",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @homepage_url
      }
    ]
  end
end
