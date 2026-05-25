defmodule Rulestead.Manifest.Serializer do
  @moduledoc false

  alias Rulestead.Manifest

  @spec serialize(map()) :: {:ok, binary()} | {:error, Rulestead.Error.t()}
  def serialize(manifest) do
    with {:ok, loaded_manifest} <- Manifest.load(manifest) do
      {:ok, encode(loaded_manifest)}
    end
  end

  defp encode(map) when is_map(map) do
    encoded_entries =
      map
      |> Enum.map(fn {key, value} -> {to_string(key), encode(value)} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join(",", fn {key, value} ->
        Jason.encode!(key) <> ":" <> value
      end)

    "{" <> encoded_entries <> "}"
  end

  defp encode(list) when is_list(list) do
    "[" <> Enum.map_join(list, ",", &encode/1) <> "]"
  end

  defp encode(value) when is_binary(value), do: Jason.encode!(value)
  defp encode(value) when is_boolean(value), do: Jason.encode!(value)
  defp encode(value) when is_integer(value), do: Jason.encode!(value)
  defp encode(value) when is_float(value), do: Jason.encode!(value)
  defp encode(value) when is_atom(value), do: Jason.encode!(value)
  defp encode(nil), do: "null"
end
