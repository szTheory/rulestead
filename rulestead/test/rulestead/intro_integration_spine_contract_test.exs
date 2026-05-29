defmodule Rulestead.IntroIntegrationSpineContractTest do
  use ExUnit.Case, async: true

  @spine_path Path.expand("../../../guides/introduction/phoenix-integration-spine.md", __DIR__)
  @getting_started_path Path.expand("../../../guides/introduction/getting-started.md", __DIR__)
  @installation_path Path.expand("../../../guides/introduction/installation.md", __DIR__)
  @root_readme_path Path.expand("../../../README.md", __DIR__)
  @evaluation_path Path.expand("../../../guides/flows/evaluation.md", __DIR__)

  test "phoenix integration spine documents first-hour Phoenix path" do
    spine = File.read!(@spine_path)

    assert spine =~ "Rulestead.Runtime"
    assert spine =~ "Rulestead.Plug"
    assert spine =~ "owner_ref"
    assert spine =~ "expected_expiration"
    assert spine =~ "Rulestead.create_flag"
    assert spine =~ "environment_key"
    assert spine =~ "flag-lifecycle"
  end

  test "intro hubs link spine and lifecycle-required fields" do
    getting_started = File.read!(@getting_started_path)
    installation = File.read!(@installation_path)

    for hub <- [getting_started, installation] do
      assert hub =~ "phoenix-integration-spine"
      assert hub =~ "owner_ref"
      assert hub =~ "expected_expiration"
    end
  end

  test "getting-started deep-links spine section 6 with numbered heading slug" do
    getting_started = File.read!(@getting_started_path)

    assert getting_started =~
             "phoenix-integration-spine.md#6-create-your-first-flag-lifecycle-required"

    refute getting_started =~
             "phoenix-integration-spine.md#create-your-first-flag-lifecycle-required"
  end

  test "root readme routes Phoenix integrators to the spine" do
    root_readme = File.read!(@root_readme_path)

    assert root_readme =~ "phoenix-integration-spine"
  end

  test "evaluation.md documents Runtime keyed lookup APIs (DOC-01)" do
    evaluation = File.read!(@evaluation_path)

    assert evaluation =~ "Rulestead.Runtime.enabled?/3"
    assert evaluation =~ "Rulestead.Runtime.evaluate/3"
    assert evaluation =~ "Rulestead.evaluate/3"
  end
end
