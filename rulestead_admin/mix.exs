defmodule RulesteadAdmin.MixProject do
  use Mix.Project

  @version "0.1.5"
  @source_url "https://github.com/szTheory/rulestead"
  @homepage_url "https://hexdocs.pm/rulestead_admin"

  def project do
    [
      app: :rulestead_admin,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: docs(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RulesteadAdmin.Application, []}
    ]
  end

  defp deps do
    [
      {:a11y_audit, "~> 0.3.4", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:lazy_html, ">= 0.0.0", only: :test},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_view, "~> 1.1"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      rulestead_dep()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp rulestead_dep do
    if System.get_env("RULESTEAD_ADMIN_HEX_RELEASE") == "1" do
      {:rulestead, "~> #{@version}"}
    else
      {:rulestead, path: "../rulestead"}
    end
  end

  defp package do
    [
      name: "rulestead_admin",
      description: "Mountable admin UI package for Rulestead.",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @homepage_url,
        "Changelog" => "#{@source_url}/blob/main/rulestead_admin/CHANGELOG.md"
      },
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
