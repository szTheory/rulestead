defmodule Rulestead.MixProject do
  use Mix.Project

  @version "0.1.7"
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
      dialyzer: dialyzer(),
      aliases: aliases()
    ]
  end

  def cli do
    [
      preferred_envs: [
        {:ci, :test},
        {:"verify.phase54", :test},
        {:"verify.phase55", :test},
        {:"verify.phase56", :test},
        {:"verify.phase60", :test},
        {:"verify.phase64", :test},
        {:"verify.phase68", :test},
        {:"verify.phase72", :test},
        {:"verify.phase73", :test},
        {:"verify.phase76", :test},
        {:"verify.phase82", :test},
        {:"verify.adopter", :test}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {Rulestead.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.14"},
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug, "~> 1.16"},
      {:postgrex, ">= 0.0.0"},
      {:redix, "~> 1.5"},
      {:telemetry, "~> 1.2"},
      {:stream_data, "~> 1.1", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: "rulestead",
      description:
        "Elixir-native feature management for safe rollout, multivariate config, and explainable runtime decisions.",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @homepage_url,
        "Changelog" => "#{@source_url}/blob/main/rulestead/CHANGELOG.md",
        "Guides" => "#{@source_url}/tree/main/guides"
      },
      files:
        ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md
           brandbook/assets/logo/*.svg brandbook/assets/specimens/readme-header.svg)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      logo: "brandbook/assets/logo/rs-mark.svg",
      favicon: "brandbook/assets/logo/rs-favicon.svg",
      assets: %{"brandbook/assets/logo" => "assets"},
      before_closing_head_tag: &before_closing_head_tag/1,
      extras: [
        "README.md",
        "../guides/introduction/why-rulestead.md",
        "../guides/introduction/installation.md",
        "../guides/introduction/getting-started.md",
        "../guides/introduction/phoenix-integration-spine.md",
        "../guides/introduction/domain_language.md",
        "../guides/introduction/product-boundary.md",
        "../guides/introduction/user-flows-and-jtbd.md",
        "../guides/introduction/adoption-lab.md",
        "../guides/flows/evaluation.md",
        "../guides/flows/rulesets.md",
        "../guides/flows/flag-lifecycle.md",
        "../guides/flows/rollout.md",
        "../guides/flows/admin-ui.md",
        "../guides/flows/explainability.md",
        "../guides/flows/multi-env.md",
        "../guides/flows/telemetry.md",
        "../guides/flows/extending-rulestead.md",
        "../guides/recipes/integrations-cookbook.md",
        "../guides/recipes/testing.md",
        "../guides/recipes/ecto-conventions.md",
        "../guides/recipes/oban-background-jobs.md",
        "../guides/recipes/deployment.md",
        "../guides/recipes/context-propagation.md",
        "../guides/recipes/footguns.md",
        "../guides/recipes/migrating-from-funwithflags.md",
        "../guides/recipes/troubleshooting.md",
        "../guides/api_stability.md",
        "../guides/introduction/upgrading.md",
        "../guides/cheatsheet.cheatmd",
        "../CONVENTIONS.md"
      ],
      groups_for_modules: [
        "Core API": [
          Rulestead,
          Rulestead.Context,
          Rulestead.Result,
          Rulestead.Error
        ],
        "Runtime (cached lookup)": [
          Rulestead.Runtime
        ],
        Testing: [
          Rulestead.TestHelpers
        ],
        "Behaviours & Seams": [
          Rulestead.Store,
          Rulestead.Admin.Policy
        ],
        "Store Adapters": [
          Rulestead.Store.Ecto,
          Rulestead.Store.Redis
        ],
        "Telemetry & Config": [
          Rulestead.Telemetry,
          Rulestead.Config
        ]
      ],
      groups_for_extras: [
        "API & Stability": [
          "../guides/api_stability.md",
          "../guides/introduction/upgrading.md",
          "../guides/cheatsheet.cheatmd"
        ],
        Introduction: ~r"guides/introduction/",
        "Concepts & Guides": ~r"guides/flows/",
        Recipes: ~r"guides/recipes/",
        Contributing: ~r"CONVENTIONS"
      ],
      skip_undefined_reference_warnings_on: fn ref ->
        is_binary(ref) and
          (String.starts_with?(ref, "lib/") or String.starts_with?(ref, "mix verify."))
      end,
      skip_code_autolink_to: fn ref ->
        is_binary(ref) and
          (String.starts_with?(ref, "Rulestead.") or
             String.starts_with?(ref, "mix rulestead.") or
             String.starts_with?(ref, "mix verify."))
      end
    ]
  end

  defp before_closing_head_tag(:html) do
    """
    <meta property="og:title" content="Rulestead — Runtime decisions, made clear.">
    <meta property="og:description" content="Elixir-native feature flags, experimentation, and remote config — deterministic, explainable runtime decisions for Phoenix.">
    <meta property="og:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.png">
    <meta property="og:type" content="website">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.png">
    <style>
      :root {
        --main:        hsl(203, 42%, 39%);  /* #3A6F8F Stead Blue */
        --mainDark:    hsl(202, 47%, 33%);  /* #2d5f7c */
        --mainDarkest: hsl(207, 49%, 19%);  /* #183247 ink */
        --mainLight:   hsl(202, 29%, 49%);  /* #5885a0 */
        --mainLightest:hsl(202, 29%, 60%);
        --searchBarFocusColor: #3A6F8F;
        --searchBarBorderColor: rgba(58, 111, 143, .25);
      }
      body.dark {
        --main:        hsl(202, 29%, 49%);  /* #5885a0 */
        --mainDark:    hsl(203, 36%, 45%);  /* #4a7d9c */
        --mainDarkest: hsl(203, 42%, 39%);  /* #3A6F8F */
        --mainLight:   hsl(203, 36%, 60%);
        --mainLightest:hsl(202, 29%, 72%);  /* AA on dark surface */
      }
    </style>
    """
  end

  defp before_closing_head_tag(:epub), do: ""

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

  defp aliases do
    [
      ci: ["cmd bash ../scripts/ci/contributor.sh"]
    ]
  end
end
