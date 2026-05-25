defmodule Rulestead.Manifest do
  @moduledoc false

  alias Rulestead.Error
  alias Rulestead.Manifest.{Export, Load, Serializer}

  @schema_version 1
  @kind "rulestead_environment_manifest"

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec kind() :: String.t()
  def kind, do: @kind

  @spec export(String.t() | atom(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def export(environment_key, opts \\ []), do: Export.export(environment_key, opts)

  @spec load(binary() | map()) :: {:ok, map()} | {:error, Error.t()}
  def load(content), do: Load.load(content)

  @spec serialize(map()) :: {:ok, binary()} | {:error, Error.t()}
  def serialize(manifest), do: Serializer.serialize(manifest)

  @spec normalize_string(term()) :: String.t() | nil
  def normalize_string(nil), do: nil
  def normalize_string(value) when is_binary(value), do: value |> String.trim() |> blank_to_nil()

  def normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  def normalize_string(value) when is_integer(value), do: Integer.to_string(value)
  def normalize_string(value), do: to_string(value) |> normalize_string()

  @spec normalize_string_list(term()) :: [String.t()]
  def normalize_string_list(nil), do: []

  def normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def normalize_string_list(value), do: normalize_string_list([value])

  @spec normalize_map(term()) :: map()
  def normalize_map(nil), do: %{}
  def normalize_map(value) when is_list(value), do: value |> Map.new() |> normalize_map()

  def normalize_map(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested_value} ->
      {to_string(key), normalize_value(nested_value)}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Map.new()
  end

  def normalize_map(_value), do: %{}

  @spec normalize_value(term()) :: term()
  def normalize_value(%Date{} = value), do: Date.to_iso8601(value)
  def normalize_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  def normalize_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  def normalize_value(value) when is_map(value), do: normalize_map(value)
  def normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)

  def normalize_value(value) when is_atom(value) and value not in [true, false, nil],
    do: Atom.to_string(value)

  def normalize_value(value), do: value

  @spec invalid(String.t(), keyword()) :: Error.t()
  def invalid(message, opts \\ []) do
    Error.new(
      Keyword.merge(
        [
          domain: :config,
          type: :invalid_command,
          message: message
        ],
        opts
      )
    )
  end

  @spec unwrap!({:ok, term()} | {:error, Error.t()}) :: term()
  def unwrap!({:ok, value}), do: value
  def unwrap!({:error, %Error{} = error}), do: raise(error)

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
