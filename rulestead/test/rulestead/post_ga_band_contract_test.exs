defmodule Rulestead.PostGaBandContractTest do
  use ExUnit.Case, async: true

  @root_readme Path.expand("../../../README.md", __DIR__)
  @maintaining Path.expand("../../../MAINTAINING.md", __DIR__)
  @product_boundary Path.expand("../../../guides/introduction/product-boundary.md", __DIR__)
  @footguns Path.expand("../../../guides/recipes/footguns.md", __DIR__)
  @demo_proof Path.expand("../../../scripts/demo/proof.sh", __DIR__)

  test "post-GA band closure docs exist" do
    for path <- [@product_boundary, @footguns, @demo_proof] do
      assert File.regular?(path), "missing #{path}"
    end

    boundary = File.read!(@product_boundary)
    assert boundary =~ "Runtime semver"
    assert boundary =~ "1.x"
  end

  test "operator docs do not claim pre-v1.8 gaps as open" do
    root_readme = File.read!(@root_readme)
    maintaining = File.read!(@maintaining)

    refute root_readme =~ "ROL-04 remains unbuilt"
    refute root_readme =~ "GOV-01 gap"
    refute root_readme =~ "IMP-05 partial"

    for doc <- [root_readme, maintaining] do
      refute doc =~ "auto-advance guarded rollouts | **Not built**"
      refute doc =~ "Protected-env audience governance (GOV-01) | **Still rough"
    end
  end

  test "quickstart does not teach Rulestead.enabled? with string key and conn" do
    root_readme = File.read!(@root_readme)

    getting_started =
      File.read!(Path.expand("../../../guides/introduction/getting-started.md", __DIR__))

    for doc <- [root_readme, getting_started] do
      refute doc =~ ~r/Rulestead\.enabled\?\("[^"]+",\s*conn\)/
      refute doc =~ ~r/Rulestead\.get_variant\("[^"]+",\s*conn\)/
      assert doc =~ "Rulestead.Runtime"
    end
  end
end
