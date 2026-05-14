defmodule OpenFeatureRulestead.ContextMapper do
  @moduledoc """
  Translates an OpenFeature evaluation context map into a `Rulestead.Context` struct.
  """

  alias Rulestead.Context

  @known_keys ["targetingKey", "tenantKey", "environment", "sessionId", "requestId", "actor"]

  @spec translate(map()) :: Context.t()
  def translate(of_context) when is_map(of_context) do
    {known_attrs, custom_attrs} = Map.split(of_context, @known_keys)

    mapped_known =
      %{
        targeting_key: known_attrs["targetingKey"],
        tenant_key: known_attrs["tenantKey"],
        environment: known_attrs["environment"],
        session_id: known_attrs["sessionId"],
        request_id: known_attrs["requestId"],
        actor: known_attrs["actor"]
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    attrs = Map.put(mapped_known, :attributes, custom_attrs)

    Context.new(attrs)
  end
end
