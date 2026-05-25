# credo:disable-for-this-file
defmodule Rulestead.Ruleset.Condition do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  @operators [:equals, :in, :not_in, :gt, :lt, :gte, :lte, :regex, :exists]

  embedded_schema do
    field(:attribute, :string)
    field(:operator, Ecto.Enum, values: @operators)
    field(:value, :map, default: %{})
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(condition, attrs) do
    condition
    |> cast(attrs, [:attribute, :operator, :value])
    |> update_change(:attribute, &normalize_string/1)
    |> validate_required([:attribute, :operator])
    |> validate_length(:attribute, min: 1, max: 255)
    |> validate_attribute_path()
    |> validate_operator_value()
  end

  @spec operators() :: [atom()]
  def operators, do: @operators

  defp validate_attribute_path(changeset) do
    attribute = get_field(changeset, :attribute)

    cond do
      is_nil(attribute) ->
        changeset

      Regex.match?(~r/\[\d+\]|\*|\(|\)|&&|\|\|/, attribute) ->
        add_error(changeset, :attribute, "must use dot-separated map paths only")

      Enum.any?(String.split(attribute, ".", trim: true), &(&1 == "")) ->
        add_error(changeset, :attribute, "must use dot-separated map paths only")

      true ->
        changeset
    end
  end

  defp validate_operator_value(changeset) do
    case get_field(changeset, :operator) do
      nil ->
        changeset

      :exists ->
        validate_exists_value(changeset)

      :regex ->
        validate_regex_value(changeset)

      operator when operator in [:in, :not_in] ->
        validate_list_value(changeset)

      operator when operator in [:gt, :lt, :gte, :lte] ->
        validate_scalar_value(changeset, operator, :number)

      :equals ->
        validate_scalar_value(changeset, :equals, :any)
    end
  end

  defp validate_exists_value(changeset) do
    value = get_field(changeset, :value) || %{}

    if value in [%{}, nil] do
      changeset
    else
      add_error(changeset, :value, "must be empty for exists")
    end
  end

  defp validate_regex_value(changeset) do
    value = get_field(changeset, :value) || %{}
    pattern = value[:pattern] || value["pattern"]
    options = value[:options] || value["options"] || ""

    cond do
      not is_map(value) ->
        add_error(changeset, :value, "must be a map for regex")

      not is_binary(pattern) or String.trim(pattern) == "" ->
        add_error(changeset, :value, "must include a binary pattern for regex")

      not is_binary(options) ->
        add_error(changeset, :value, "must include binary options for regex")

      regex_compile_error?(pattern, options) ->
        add_error(changeset, :value, "must contain a valid regex pattern and options")

      true ->
        changeset
    end
  end

  defp validate_list_value(changeset) do
    value = get_field(changeset, :value) || %{}
    list_value = value[:in] || value["in"] || value[:not_in] || value["not_in"]

    cond do
      not is_map(value) ->
        add_error(changeset, :value, "must be a map with a homogeneous list payload")

      not is_list(list_value) or list_value == [] ->
        add_error(changeset, :value, "must contain a non-empty list")

      not homogeneous?(list_value) ->
        add_error(changeset, :value, "must contain values of a single type")

      true ->
        changeset
    end
  end

  defp validate_scalar_value(changeset, key, lane) do
    value = get_field(changeset, :value) || %{}
    scalar = value[key] || value[Atom.to_string(key)]

    cond do
      not is_map(value) ->
        add_error(changeset, :value, "must be a map with a scalar payload")

      is_nil(scalar) ->
        add_error(changeset, :value, "must include #{key}")

      lane == :number and not is_number(scalar) ->
        add_error(changeset, :value, "must use a numeric comparison payload")

      true ->
        changeset
    end
  end

  defp regex_compile_error?(pattern, options) do
    case Regex.compile(pattern, options) do
      {:ok, _regex} -> false
      {:error, _reason} -> true
    end
  end

  defp homogeneous?([head | tail]) do
    head_type = scalar_type(head)
    head_type != :invalid and Enum.all?(tail, &(scalar_type(&1) == head_type))
  end

  defp homogeneous?([]), do: false

  defp scalar_type(value) when is_binary(value), do: :string
  defp scalar_type(value) when is_integer(value), do: :integer
  defp scalar_type(value) when is_float(value), do: :float
  defp scalar_type(value) when is_boolean(value), do: :boolean
  defp scalar_type(value) when is_atom(value), do: :atom
  defp scalar_type(nil), do: nil
  defp scalar_type(_value), do: :invalid

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end
