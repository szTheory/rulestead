# credo:disable-for-this-file
defmodule Rulestead.Analytics.EventMapper do
  @moduledoc false
  # # Pure mapping functions to format raw incoming metrics before they hit the database.

  # @doc """
  # Transforms a raw event map into an Ecto insertable map.
  # Ensures explicit :id, :occurred_at, :inserted_at, and :updated_at.

  @spec to_insert_map(map()) :: map()
  def to_insert_map(raw_event) when is_map(raw_event) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    occurred_at =
      case Map.get(raw_event, :occurred_at) || Map.get(raw_event, "occurred_at") do
        %DateTime{} = dt -> dt |> DateTime.truncate(:microsecond)
        _ -> now
      end

    %{
      id: Ecto.UUID.generate(),
      kind: extract_kind(raw_event),
      actor_id: Map.get(raw_event, :actor_id) || Map.get(raw_event, "actor_id"),
      event_name: Map.get(raw_event, :event_name) || Map.get(raw_event, "event_name"),
      env: Map.get(raw_event, :env) || Map.get(raw_event, "env"),
      metadata: extract_metadata(raw_event),
      occurred_at: occurred_at,
      inserted_at: now,
      updated_at: now
    }
  end

  defp extract_kind(raw_event) do
    kind = Map.get(raw_event, :kind) || Map.get(raw_event, "kind")

    case kind do
      "exposure" -> "exposure"
      "custom" -> "custom"
      :exposure -> "exposure"
      :custom -> "custom"
      # Default fallback or should we return nil? The task says "handles both 'exposure' and 'custom' kinds". Let's assume fallback to "custom" or "unknown".
      _ -> "custom"
    end
  end

  defp extract_metadata(raw_event) do
    meta = Map.get(raw_event, :metadata) || Map.get(raw_event, "metadata")

    if is_map(meta) do
      meta
    else
      %{}
    end
  end
end
