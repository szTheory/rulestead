defmodule Rulestead.Analytics do
  @moduledoc false
  # Public analytics tracking interface.

  alias Rulestead.Analytics.Batcher
  alias Rulestead.Context

  @doc """
  Tracks a custom analytics event.
  """
  @spec track(Context.t() | map() | String.t(), String.t(), map()) :: :ok
  def track(context_or_actor_id, event_name, metadata \\ %{}) do
    actor_id = extract_actor_id(context_or_actor_id)

    event = %{
      kind: "custom",
      actor_id: actor_id,
      event_name: event_name,
      metadata: metadata
    }

    Batcher.insert(event)
  end

  defp extract_actor_id(%Context{} = context) do
    context.targeting_key
  end

  defp extract_actor_id(actor_id) when is_binary(actor_id) do
    actor_id
  end

  defp extract_actor_id(context_map) when is_map(context_map) do
    Context.new(context_map).targeting_key
  end

  defp extract_actor_id(_), do: nil
end
