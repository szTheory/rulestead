defmodule Rulestead.EnvironmentVersionTest do
  use ExUnit.Case, async: true

  alias Rulestead.EnvironmentVersion

  test "defines the immutable environment-version boundary fields" do
    assert EnvironmentVersion.__schema__(:fields) == [
             :id,
             :environment_key,
             :version,
             :authored_snapshot,
             :source_environment_key,
             :target_environment_key,
             :compare_token,
             :source_fingerprint,
             :target_fingerprint,
             :dependency_closure_keys,
             :applied_flag_keys,
             :tenant_key,
             :metadata,
             :inserted_at,
             :updated_at
           ]
  end

  test "accepts a persisted authored snapshot with promotion linkage metadata" do
    changeset =
      EnvironmentVersion.changeset(%EnvironmentVersion{}, %{
        environment_key: "production",
        version: 4,
        authored_snapshot: %{
          "checkout-redesign" => %{
            "flag" => %{"key" => "checkout-redesign"},
            "flag_environment" => %{"environment_key" => "production"},
            "active_ruleset" => %{"version" => 7}
          }
        },
        source_environment_key: "staging",
        target_environment_key: "production",
        compare_token: "cmp_123",
        source_fingerprint: "sha256:source",
        target_fingerprint: "sha256:target",
        dependency_closure_keys: ["audience:vip-users"],
        applied_flag_keys: ["checkout-redesign"],
        metadata: %{promotion_kind: "direct_apply"}
      })

    assert changeset.valid?
  end

  test "rejects non-positive versions and oversized environment identifiers" do
    changeset =
      EnvironmentVersion.changeset(%EnvironmentVersion{}, %{
        environment_key: String.duplicate("p", 129),
        version: 0,
        authored_snapshot: %{},
        source_environment_key: String.duplicate("s", 129),
        target_environment_key: String.duplicate("t", 129),
        compare_token: String.duplicate("c", 257),
        source_fingerprint: String.duplicate("f", 257),
        target_fingerprint: String.duplicate("g", 257),
        dependency_closure_keys: [],
        applied_flag_keys: []
      })

    refute changeset.valid?

    assert "should be at most 128 character(s)" in errors_on(changeset).environment_key
    assert "must be greater than 0" in errors_on(changeset).version
    assert "should be at most 128 character(s)" in errors_on(changeset).source_environment_key
    assert "should be at most 128 character(s)" in errors_on(changeset).target_environment_key
    assert "should be at most 256 character(s)" in errors_on(changeset).compare_token
    assert "should be at most 256 character(s)" in errors_on(changeset).source_fingerprint
    assert "should be at most 256 character(s)" in errors_on(changeset).target_fingerprint
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
