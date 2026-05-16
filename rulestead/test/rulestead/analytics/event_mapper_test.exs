defmodule Rulestead.Analytics.EventMapperTest do
  use ExUnit.Case, async: true

  alias Rulestead.Analytics.EventMapper

  describe "to_insert_map/1" do
    test "transforms exposure event with string keys" do
      raw = %{
        "kind" => "exposure",
        "actor_id" => "usr_123",
        "event_name" => "feature_xyz_evaluated",
        "env" => "production",
        "metadata" => %{"flag_key" => "feature_xyz", "value" => true}
      }

      result = EventMapper.to_insert_map(raw)

      assert is_binary(result.id)
      assert String.length(result.id) > 10
      assert result.kind == "exposure"
      assert result.actor_id == "usr_123"
      assert result.event_name == "feature_xyz_evaluated"
      assert result.env == "production"
      assert result.metadata == %{"flag_key" => "feature_xyz", "value" => true}
      assert %DateTime{} = result.occurred_at
      assert %DateTime{} = result.inserted_at
      assert %DateTime{} = result.updated_at
      
      # Ensure it's truncated to microseconds
      assert result.occurred_at.microsecond |> elem(1) == 6
    end

    test "transforms custom event with atom keys and explicit occurred_at" do
      dt = DateTime.utc_now() |> DateTime.truncate(:second)

      raw = %{
        kind: :custom,
        actor_id: "usr_456",
        event_name: "checkout_completed",
        env: "staging",
        metadata: %{amount: 100},
        occurred_at: dt
      }

      result = EventMapper.to_insert_map(raw)

      assert result.kind == "custom"
      assert result.actor_id == "usr_456"
      assert result.event_name == "checkout_completed"
      assert result.env == "staging"
      assert result.metadata == %{amount: 100}
      assert result.occurred_at == dt
      assert %DateTime{} = result.inserted_at
      assert %DateTime{} = result.updated_at
    end

    test "handles missing fields gracefully" do
      raw = %{}

      result = EventMapper.to_insert_map(raw)

      assert is_binary(result.id)
      assert result.kind == "custom"
      assert result.actor_id == nil
      assert result.event_name == nil
      assert result.env == nil
      assert result.metadata == %{}
      assert %DateTime{} = result.occurred_at
      assert %DateTime{} = result.inserted_at
      assert %DateTime{} = result.updated_at
    end
  end
end
