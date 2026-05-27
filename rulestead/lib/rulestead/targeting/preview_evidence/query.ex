defmodule Rulestead.Targeting.PreviewEvidence.Query do
  @moduledoc false

  alias Rulestead.Store.Command.GovernanceSupport

  @spec new(map() | keyword()) :: map()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %{
      environment_key: optional_string(attrs, :environment_key),
      tenant_key: optional_string(attrs, :tenant_key),
      audience_key: optional_string(attrs, :audience_key),
      operation: optional_string(attrs, :operation),
      before_definition: optional_value(attrs, :before_definition),
      after_definition: optional_value(attrs, :after_definition),
      affected_reference_keys: normalize_reference_keys(attrs)
    }
  end

  defp optional_string(attrs, key) do
    attrs
    |> optional_value(key)
    |> GovernanceSupport.normalize_string()
  end

  defp optional_value(attrs, key),
    do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp normalize_reference_keys(attrs) do
    case optional_value(attrs, :affected_reference_keys) do
      keys when is_list(keys) ->
        keys
        |> Enum.map(&GovernanceSupport.normalize_string/1)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end
end
