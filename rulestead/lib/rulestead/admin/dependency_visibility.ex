defmodule Rulestead.Admin.DependencyVisibility do
  @moduledoc false

  alias Rulestead.Admin.Authorizer

  @spec visibility_resolver(term()) :: (map() -> boolean())
  def visibility_resolver(actor) do
    fn entry ->
      flag_key = Map.get(entry, :flag_key) || Map.get(entry, "flag_key")
      environment_key = Map.get(entry, :environment_key) || Map.get(entry, "environment_key")

      case flag_key do
        key when is_binary(key) and key != "" ->
          resource = %{resource_type: :flag, resource_key: key}

          case Authorizer.authorize(actor, :read_flags, resource, environment_key) do
            :ok -> true
            {:error, _, _} -> false
          end

        _ ->
          true
      end
    end
  end
end
