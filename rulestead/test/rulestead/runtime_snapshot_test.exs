defmodule Rulestead.RuntimeSnapshotTest do
  use ExUnit.Case, async: true

  alias Rulestead.RuntimeSnapshot

  test "defines the persisted runtime snapshot boundary fields" do
    assert RuntimeSnapshot.__schema__(:fields) == [
             :id,
             :environment_key,
             :version,
             :payload,
             :payload_checksum,
             :metadata,
             :published_at,
             :inserted_at,
             :updated_at
           ]
  end

  test "accepts a bounded immutable snapshot payload" do
    changeset =
      RuntimeSnapshot.changeset(%RuntimeSnapshot{}, %{
        environment_key: "production",
        version: 3,
        payload: :erlang.term_to_binary(%{"flag_count" => 12}),
        payload_checksum: String.duplicate("a", 64),
        metadata: %{source: "publish"},
        published_at: ~U[2026-04-23 12:00:00Z]
      })

    assert changeset.valid?
  end

  test "rejects non-positive versions and oversized identity fields" do
    changeset =
      RuntimeSnapshot.changeset(%RuntimeSnapshot{}, %{
        environment_key: String.duplicate("p", 129),
        version: 0,
        payload: <<1, 2, 3>>,
        payload_checksum: String.duplicate("b", 65),
        metadata: %{},
        published_at: ~U[2026-04-23 12:00:00Z]
      })

    refute changeset.valid?
    assert "should be at most 128 character(s)" in errors_on(changeset).environment_key
    assert "must be greater than 0" in errors_on(changeset).version
    assert "should be at most 64 character(s)" in errors_on(changeset).payload_checksum
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
