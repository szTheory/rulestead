defmodule Rulestead.Mix.Tasks.VerifyReleaseParityTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Verify.ReleaseParity

  test "compute reports parity when tag and tarball contents match" do
    tag_manifest = %{
      "README.md" => "abc123",
      "guides/flows/flag-lifecycle.md" => "life789",
      "lib/rulestead.ex" => "def456"
    }

    tarball_manifest = %{
      "README.md" => "abc123",
      "guides/flows/flag-lifecycle.md" => "life789",
      "lib/rulestead.ex" => "def456"
    }

    assert {:ok, %{status: :parity, drift: %{missing: [], extra: [], changed: []}}} =
             ReleaseParity.compute(tag_manifest, tarball_manifest)

    assert ReleaseParity.exit_code({:ok, %{status: :parity}}) == 0
  end

  test "compute reports drift with a dedicated exit code" do
    tag_manifest = %{
      "README.md" => "abc123",
      "guides/flows/flag-lifecycle.md" => "life789",
      "lib/rulestead.ex" => "def456"
    }

    tarball_manifest = %{
      "README.md" => "abc123",
      "guides/flows/flag-lifecycle.md" => "other000",
      "lib/rulestead.ex" => "zzz999",
      "extra.txt" => "111"
    }

    assert {:drift, %{status: :drift, drift: drift}} =
             ReleaseParity.compute(tag_manifest, tarball_manifest)

    assert drift.missing == []
    assert drift.extra == ["extra.txt"]
    assert drift.changed == ["guides/flows/flag-lifecycle.md", "lib/rulestead.ex"]
    assert ReleaseParity.exit_code({:drift, %{status: :drift}}) == 2
  end

  test "runtime failures map to exit code 1" do
    assert ReleaseParity.exit_code({:error, :hex_unavailable}) == 1
  end

  test "core_release_tag matches release-please component tag format" do
    assert ReleaseParity.core_release_tag("0.1.1") == "rulestead-v0.1.1"
    assert ReleaseParity.core_release_tag("1.0.0") == "rulestead-v1.0.0"
  end

  test "publishable_path? mirrors Hex package files whitelist" do
    files = ReleaseParity.publishable_paths(package: [files: ~w(lib guides mix.exs)])

    assert ReleaseParity.publishable_path?("lib/rulestead.ex", files)
    assert ReleaseParity.publishable_path?("guides/README.md", files)
    assert ReleaseParity.publishable_path?("mix.exs", files)
    refute ReleaseParity.publishable_path?("test/rulestead_test.exs", files)
    refute ReleaseParity.publishable_path?("config/config.exs", files)
  end
end
