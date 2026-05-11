defmodule Rulestead.Integration.InstallGoldenTest do
  use ExUnit.Case, async: false

  import Rulestead.Test.InstallFixture

  @moduletag :golden
  @moduletag timeout: 300_000

  @fixture_root Path.expand("../../fixtures/install_golden", __DIR__)
  @tree_fixture_root Path.join(@fixture_root, "tree")
  @stdout_fixture_path Path.join(@fixture_root, "STDOUT.txt")

  test "installer output matches the normalized golden tree and stdout" do
    result = setup_tmp_app!(rerun_install?: true)
    on_exit(fn -> cleanup_tmp_app!(result) end)

    assert normalize_stdout(result.stdout) == File.read!(@stdout_fixture_path)
    assert normalize_tree(result.app_dir) == read_tree_fixture!(@tree_fixture_root)
  end

  test "second installer run is idempotent against the same normalized contract" do
    result = setup_tmp_app!(rerun_install?: true)
    on_exit(fn -> cleanup_tmp_app!(result) end)

    rerun_output = normalize_stdout(result.rerun_stdout || "")

    assert rerun_output != ""

    assert rerun_output
           |> String.split("\n", trim: true)
           |> Enum.all?(&String.starts_with?(&1, "skip "))

    assert normalize_tree(result.app_dir) == read_tree_fixture!(@tree_fixture_root)
  end
end
