defmodule Rulestead.Mix.Tasks.VerifyReleaseParityTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Verify.ReleaseParity

  test "compute reports parity when tag and tarball contents match" do
    tag_manifest = %{"README.md" => "abc123", "lib/rulestead.ex" => "def456"}
    tarball_manifest = %{"README.md" => "abc123", "lib/rulestead.ex" => "def456"}

    assert {:ok, %{status: :parity, drift: %{missing: [], extra: [], changed: []}}} =
             ReleaseParity.compute(tag_manifest, tarball_manifest)

    assert ReleaseParity.exit_code({:ok, %{status: :parity}}) == 0
  end

  test "compute reports drift with a dedicated exit code" do
    tag_manifest = %{"README.md" => "abc123", "lib/rulestead.ex" => "def456"}
    tarball_manifest = %{"README.md" => "abc123", "lib/rulestead.ex" => "zzz999", "extra.txt" => "111"}

    assert {:drift, %{status: :drift, drift: drift}} =
             ReleaseParity.compute(tag_manifest, tarball_manifest)

    assert drift.missing == []
    assert drift.extra == ["extra.txt"]
    assert drift.changed == ["lib/rulestead.ex"]
    assert ReleaseParity.exit_code({:drift, %{status: :drift}}) == 2
  end

  test "runtime failures map to exit code 1" do
    assert ReleaseParity.exit_code({:error, :hex_unavailable}) == 1
  end
end
