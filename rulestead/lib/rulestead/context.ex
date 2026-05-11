defmodule Rulestead.Context do
  @moduledoc """
  Canonical runtime context used by the Phase 3 evaluator surface.
  """

  @enforce_keys []
  defstruct actor: nil,
            targeting_key: nil,
            tenant_key: nil,
            environment: nil,
            attributes: %{},
            request_id: nil,
            session_id: nil,
            strict?: false

  @type actor :: map() | struct() | nil

  @type t :: %__MODULE__{
          actor: actor(),
          targeting_key: String.t() | nil,
          tenant_key: String.t() | nil,
          environment: String.t() | nil,
          attributes: map(),
          request_id: String.t() | nil,
          session_id: String.t() | nil,
          strict?: boolean()
        }

  @spec new(t() | keyword() | map()) :: t()
  def new(%__MODULE__{} = context), do: normalize(context)

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = attrs |> Map.new() |> normalize_aliases()
    actor = normalize_actor(Map.get(attrs, :actor))

    %__MODULE__{
      actor: actor,
      targeting_key: normalize_scalar(Map.get(attrs, :targeting_key) || actor_key(actor)),
      tenant_key: normalize_scalar(Map.get(attrs, :tenant_key)),
      environment: normalize_scalar(Map.get(attrs, :environment)),
      attributes: normalize_attributes(Map.get(attrs, :attributes, %{})),
      request_id: normalize_scalar(Map.get(attrs, :request_id)),
      session_id: normalize_scalar(Map.get(attrs, :session_id)),
      strict?: normalize_boolean(Map.get(attrs, :strict?, false))
    }
  end

  @spec normalize(t() | keyword() | map()) :: t()
  def normalize(%__MODULE__{} = context), do: new(Map.from_struct(context))
  def normalize(attrs) when is_list(attrs) or is_map(attrs), do: new(attrs)

  defp normalize_aliases(attrs) do
    actor = Map.get(attrs, :actor) || Map.get(attrs, "actor") || Map.get(attrs, :subject) || Map.get(attrs, "subject")

    attrs
    |> Map.delete("subject")
    |> Map.delete(:subject)
    |> Map.put(:actor, actor)
  end

  defp normalize_actor(nil), do: nil
  defp normalize_actor(%_{} = actor), do: actor

  defp normalize_actor(actor) when is_map(actor) do
    Enum.into(actor, %{})
  end

  defp normalize_actor(actor), do: %{key: normalize_scalar(actor)}

  defp normalize_attributes(attributes) when is_map(attributes), do: attributes
  defp normalize_attributes(attributes) when is_list(attributes), do: Map.new(attributes)
  defp normalize_attributes(_attributes), do: %{}

  defp normalize_scalar(nil), do: nil

  defp normalize_scalar(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_scalar(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_scalar()
  defp normalize_scalar(value) when is_integer(value), do: Integer.to_string(value)
  defp normalize_scalar(value) when is_float(value), do: :erlang.float_to_binary(value, [:compact])
  defp normalize_scalar(_value), do: nil

  defp normalize_boolean(value) when is_boolean(value), do: value
  defp normalize_boolean("true"), do: true
  defp normalize_boolean("false"), do: false
  defp normalize_boolean(_value), do: false

  defp actor_key(nil), do: nil

  defp actor_key(%_{} = actor) do
    actor
    |> Map.from_struct()
    |> actor_key()
  end

  defp actor_key(actor) when is_map(actor) do
    actor[:key] || actor["key"] || actor[:id] || actor["id"]
  end

  defp actor_key(_actor), do: nil
end
