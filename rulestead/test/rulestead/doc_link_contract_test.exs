defmodule Rulestead.DocLinkContractTest do
  use ExUnit.Case, async: true

  @runtime_readme_path Path.expand("../../README.md", __DIR__)
  @admin_readme_path Path.expand("../../../rulestead_admin/README.md", __DIR__)
  @getting_started_path Path.expand("../../../guides/introduction/getting-started.md", __DIR__)
  @guides_dir Path.expand("../../../guides", __DIR__)

  defp guide_paths do
    @guides_dir
    |> Path.join("**/*.md")
    |> Path.wildcard()
  end

  test "package READMEs use no parent-relative markdown links" do
    for path <- [@runtime_readme_path, @admin_readme_path] do
      content = File.read!(path)
      refute content =~ ~r/\]\(\.\.\//
    end
  end

  test "package READMEs omit maintainer phase verify commands" do
    for path <- [@runtime_readme_path, @admin_readme_path] do
      content = File.read!(path)
      refute content =~ "mix verify.phase"
    end
  end

  test "Hex extras guides avoid monorepo-only relative paths" do
    bad_patterns = ["../../examples/", "../../rulestead_admin/README.md"]

    for path <- guide_paths() do
      content = File.read!(path)
      basename = Path.basename(path)

      for pattern <- bad_patterns do
        refute content =~ pattern, "#{basename} still links via #{pattern}"
      end
    end
  end

  test "adopter docs mention current Hex version family" do
    for path <- [@runtime_readme_path, @getting_started_path] do
      content = File.read!(path)
      assert content =~ "~> 1.0"
    end
  end
end
