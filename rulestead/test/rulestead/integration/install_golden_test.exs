defmodule Rulestead.Integration.InstallGoldenTest do
  use ExUnit.Case, async: false

  import Rulestead.Test.InstallFixture

  @moduletag :golden
  @moduletag timeout: 300_000

  @fixture_root Path.expand("../../fixtures/install_golden", __DIR__)
  @tree_fixture_root Path.join(@fixture_root, "tree")
  @stdout_fixture_path Path.join(@fixture_root, "STDOUT.txt")

  test "installer output matches the normalized golden tree and stdout" do
    result = setup_tmp_app!()
    on_exit(fn -> cleanup_tmp_app!(result) end)

    assert normalize_stdout(result.stdout) == File.read!(@stdout_fixture_path)

    normalized_tree = normalize_tree(result.app_dir)
    rulestead_config = Map.fetch!(normalized_tree, "config/rulestead.exs")

    assert normalized_tree == read_tree_fixture!(@tree_fixture_root)
    assert rulestead_config =~ "notifier: Rulestead.Runtime.Notifier.PhoenixPubSub"
    assert rulestead_config =~ "pubsub: HostApp.PubSub"
    assert rulestead_config =~ ~s(pubsub_topic: "rulestead:runtime_snapshot")
  end

  test "fresh installer runs produce the same normalized golden contract" do
    first_result = setup_tmp_app!()
    second_result = setup_tmp_app!()

    on_exit(fn ->
      cleanup_tmp_app!(first_result)
      cleanup_tmp_app!(second_result)
    end)

    assert normalize_tree(first_result.app_dir) == read_tree_fixture!(@tree_fixture_root)
    assert normalize_tree(second_result.app_dir) == read_tree_fixture!(@tree_fixture_root)
    assert normalize_stdout(first_result.stdout) == normalize_stdout(second_result.stdout)
  end
end
