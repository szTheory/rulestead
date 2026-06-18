defmodule RulesteadAdmin.MixProject do
  use Mix.Project

  @version "0.1.7"
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
      description:
        "Optional mounted Phoenix LiveView operator companion for Rulestead feature management.",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @homepage_url,
        "Changelog" => "#{@source_url}/blob/main/rulestead_admin/CHANGELOG.md"
      },
      files:
        ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md
           brandbook/assets/logo/*.svg)
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
        "CHANGELOG.md",
        "../guides/flows/admin-ui.md",
        "../guides/flows/explainability.md"
      ],
      groups_for_extras: [
        "Operator Guides": ~r"guides/flows/"
      ],
      groups_for_modules: [
        "Public Admin Seam": [RulesteadAdmin.Router]
      ],
      skip_undefined_reference_warnings_on: fn ref ->
        # Cross-doc refs to core extras (rollout.md, multi-env.md, adoption-lab.md)
        # and cross-package callback refs (Rulestead.Admin.Policy.can?/4) — these
        # resolve in the full rulestead docs but are outside admin's narrower extras.
        is_binary(ref) and
          (String.ends_with?(ref, ".md") or
             String.ends_with?(ref, ".md#operator--admin-feel") or
             String.starts_with?(ref, "Rulestead.Admin.Policy."))
      end,
      skip_code_autolink_to: fn ref ->
        is_binary(ref) and String.starts_with?(ref, "RulesteadAdmin.Live.")
      end
    ]
  end

  defp before_closing_head_tag(:html) do
    """
    <meta property="og:title" content="Rulestead Admin — Operator companion for Rulestead.">
    <meta property="og:description" content="Mounted Phoenix LiveView operator UI for Rulestead feature management — safe mounting, explainable decisions.">
    <meta property="og:image" content="https://hexdocs.pm/rulestead_admin/assets/rs-social-card.png">
    <meta property="og:type" content="website">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="https://hexdocs.pm/rulestead_admin/assets/rs-social-card.png">
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
end
