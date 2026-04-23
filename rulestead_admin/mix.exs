defmodule RulesteadAdmin.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/rulestead"
  @homepage_url "https://hexdocs.pm/rulestead_admin"

  def project do
    [
      app: :rulestead_admin,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
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
      rulestead_dep()
    ]
  end

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
      extras: ["README.md"]
    ]
  end
end
