defmodule Rulestead.Context do
  @moduledoc """
  Explicit evaluation context: who is asking, in which environment, and with what
  attributes.

  `Rulestead.Context` is the second argument to every evaluation call. It is a
  plain struct you build once per request (or once per job) and pass into
  `Rulestead.evaluate/3`, `Rulestead.Runtime.enabled?/3`, and the other evaluation
  functions. Evaluation never reads ambient process state — context is always
  explicit, which is what makes a decision reproducible and explainable.

  ## Building a context

      iex> ctx =
      ...>   Rulestead.Context.new(
      ...>     environment: "production",
      ...>     targeting_key: "user-123",
      ...>     attributes: %{plan: :pro}
      ...>   )
      iex> ctx.targeting_key
      "user-123"

  The `:targeting_key` is the stable identity used for deterministic, sticky
  bucketing — pass the same key and a flag resolves the same way every time.
  `:attributes` carry the traits your ordered rules match on.

  ## Stable fields

  See [API Stability](api_stability.md) for the frozen field list. The supported
  fields are `:actor`, `:targeting_key`, `:tenant_key`, `:environment`,
  `:attributes`, `:request_id`, `:session_id`, and `:strict?`.
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

  @doc """
  Builds a `%Rulestead.Context{}` from a keyword list, a map, or an existing
  context struct.

  Accepts the following input shapes:

  - `keyword()` — e.g. `[environment: "production", targeting_key: "u1"]`
  - `map()` — e.g. `%{environment: "production", targeting_key: "u1"}`
  - `%Rulestead.Context{}` — idempotent; re-normalizes the struct

  Normalizes legacy key aliases on the way in: `:subject` is promoted to `:actor`,
  and `:traits` is merged into `:attributes` (explicit `:attributes` wins on key
  conflicts).

  When `:targeting_key` is not supplied, it defaults to the `:key` or `:id` field
  of the `:actor` map or struct, if present.

  Returns a fully-normalized `%Rulestead.Context{}`.
  """
  @spec new(t() | keyword() | map()) :: t()
  def new(%__MODULE__{} = context), do: normalize(context)

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = attrs |> Map.new() |> normalize_aliases() |> promote_traits_to_attributes()
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

  @doc """
  Normalizes a keyword list, map, or existing `%Rulestead.Context{}` into a
  fully-normalized struct.

  Accepts the same input union as `new/1`. Ensures:

  - All scalar fields (`:targeting_key`, `:tenant_key`, `:environment`,
    `:request_id`, `:session_id`) are strings or `nil`
  - `:actor` is a map or struct, or `nil`
  - `:attributes` is a map
  - `:strict?` is a boolean

  This function is idempotent: calling it on an already-normalized
  `%Rulestead.Context{}` returns an equivalent struct.
  """
  @spec normalize(t() | keyword() | map()) :: t()
  def normalize(%__MODULE__{} = context), do: new(Map.from_struct(context))
  def normalize(attrs) when is_list(attrs) or is_map(attrs), do: new(attrs)

  defp normalize_aliases(attrs) do
    actor =
      Map.get(attrs, :actor) || Map.get(attrs, "actor") || Map.get(attrs, :subject) ||
        Map.get(attrs, "subject")

    attrs
    |> Map.delete("subject")
    |> Map.delete(:subject)
    |> Map.put(:actor, actor)
  end

  # Back-compat for docs/examples that used `traits:` before the canonical `:attributes` field.
  # Explicit `:attributes` wins on key conflicts.
  defp promote_traits_to_attributes(attrs) do
    traits = Map.get(attrs, :traits) || Map.get(attrs, "traits")

    if traits do
      from_traits = normalize_attributes(traits)

      from_attributes =
        normalize_attributes(Map.get(attrs, :attributes) || Map.get(attrs, "attributes") || %{})

      attrs
      |> Map.delete(:traits)
      |> Map.delete("traits")
      |> Map.put(:attributes, Map.merge(from_traits, from_attributes))
    else
      attrs
    end
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

  defp normalize_scalar(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_scalar()

  defp normalize_scalar(value) when is_integer(value), do: Integer.to_string(value)

  defp normalize_scalar(value) when is_float(value),
    do: :erlang.float_to_binary(value, [:compact])

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
