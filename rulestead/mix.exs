defmodule Rulestead.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/rulestead"
  @homepage_url "https://hexdocs.pm/rulestead"

  def project do
    [
      app: :rulestead,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Rulestead.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.13"},
      {:jason, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:stream_data, "~> 1.1", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: "rulestead",
      description: "Runtime decisions, made clear.",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @homepage_url,
        "Changelog" => "#{@source_url}/blob/main/rulestead/CHANGELOG.md",
        "Guides" => "#{@source_url}/tree/main/guides"
      },
      files:
        ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      extras: [
        "README.md",
        "../guides/introduction/installation.md",
        "../guides/introduction/getting-started.md",
        "../guides/introduction/upgrading.md",
        "../guides/flows/evaluation.md",
        "../guides/flows/rulesets.md",
        "../guides/flows/rollout.md",
        "../guides/flows/admin-ui.md",
        "../guides/flows/explainability.md",
        "../guides/flows/multi-env.md",
        "../guides/recipes/testing.md",
        "../guides/recipes/telemetry.md",
        "../guides/recipes/ecto-conventions.md",
        "../guides/recipes/oban-background-jobs.md",
        "../guides/recipes/deployment.md",
        "../guides/recipes/context-propagation.md"
      ],
      # Original Phase 1 shape: skip_undefined_reference_warnings_on: &String.starts_with?(&1, "lib/")
      skip_undefined_reference_warnings_on: fn ref ->
        is_binary(ref) and String.starts_with?(ref, "lib/")
      end
    ]
  end

  defp dialyzer do
    [
      plt_local_path: "priv/plts",
      plt_core_path: "priv/plts",
      plt_add_apps: [:ex_unit, :mix, :eex],
      flags: [:error_handling, :extra_return, :missing_return],
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end
end
