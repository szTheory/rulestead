# credo:disable-for-this-file
defmodule Rulestead.Runtime.AudienceSnapshotTest do
  use ExUnit.Case, async: true

  alias Rulestead.Runtime.Snapshot

  @published_at ~U[2026-05-27 09:00:00Z]
  @generated_at ~U[2026-05-27 09:00:01Z]

  describe "compiled audience snapshots" do
    test "compile carries snapshot-local audiences and stable audience_keys" do
      assert {:ok, snapshot} =
               Snapshot.compile(
                 runtime_snapshot(%{
                   audiences: %{
                     "vip-users" => %{
                       definition: %{
                         clauses: [
                           %{attribute: "attributes.plan", operator: "equals", value: %{equals: "vip"}}
                         ]
                       },
                       archived_at: nil
                     }
                   }
                 })
               )

      assert snapshot.audience_keys == ["vip-users"]

      assert snapshot.audiences["vip-users"] == %{
               audience_key: "vip-users",
               definition: %{
                 clauses: [
                   %{attribute: "attributes.plan", operator: "equals", value: %{equals: "vip"}}
                 ]
               },
               archived_at: nil
             }
    end

    test "compile rejects malformed audience definitions through runtime data errors" do
      assert {:error, %Rulestead.Error{type: :malformed_runtime_data}} =
               Snapshot.compile(
                 runtime_snapshot(%{
                   audiences: %{
                     "vip-users" => %{definition: "not a definition", archived_at: nil}
                   }
                 })
               )
    end

    test "compile keeps old payloads without audiences backward compatible" do
      assert {:ok, snapshot} = Snapshot.compile(runtime_snapshot(%{}))

      assert snapshot.audiences == %{}
      assert snapshot.audience_keys == []
    end
  end

  defp runtime_snapshot(payload_overrides) do
    payload =
      %{
        schema_version: 1,
        environment_key: "production",
        generated_at: @generated_at,
        flags: %{}
      }
      |> Map.merge(payload_overrides)

    %{
      environment_key: "production",
      version: 1,
      published_at: @published_at,
      payload: :erlang.term_to_binary(payload),
      metadata: %{}
    }
  end
end
