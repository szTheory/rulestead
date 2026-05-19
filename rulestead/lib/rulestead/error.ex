defmodule Rulestead.Error do
  @moduledoc """
  Stable public error envelope for all non-bang and bang APIs.

  `Rulestead` returns this struct in `{:error, error}` tuples and raises the same
  struct from bang variants. Typed helper modules such as `Rulestead.StoreError`
  construct this envelope instead of introducing competing public error structs.
  """

  @enforce_keys [:domain, :type, :message]
  defexception [
    :domain,
    :type,
    :message,
    metadata: %{},
    details: [],
    cause: nil,
    plug_status: nil
  ]

  @typedoc "Top-level error family used to group stable leaf error types."
  @type domain :: :evaluation | :ruleset | :kill_switch | :config | :store | :auth

  @typedoc """
  Closed Phase 2 leaf error atoms.

  Downstream phases should extend this list deliberately when they add new public
  failure modes rather than returning broad atoms such as `:invalid` or `:not_found`.
  """
  @type type ::
          :flag_not_found
          | :environment_not_found
          | :snapshot_not_found
          | :ruleset_not_found
          | :missing_targeting_key
          | :repo_not_configured
          | :repo_ambiguous
          | :store_not_configured
          | :store_adapter_invalid
          | :store_unavailable
          | :invalid_command
          | :invalid_ruleset
          | :variant_weights_invalid
          | :invalid_value_projection
          | :malformed_runtime_data
          | :flag_archived
          | :unauthorized
          | :kill_switch_active
          | :not_implemented

  @type metadata_scalar :: nil | boolean | integer | float | atom | String.t()
  @type metadata_key :: atom | String.t()
  @type metadata :: %{optional(metadata_key()) => metadata_scalar()}

  @type detail_key :: atom | String.t()
  @type detail_value :: nil | boolean | integer | float | atom | String.t()
  @type detail :: %{optional(detail_key()) => detail_value()}

  @type t :: %__MODULE__{
          domain: domain(),
          type: type(),
          message: String.t(),
          metadata: metadata(),
          details: [detail()],
          cause: term(),
          plug_status: nil | pos_integer()
        }

  @domains [:evaluation, :ruleset, :kill_switch, :config, :store, :auth]
  @leaf_types [
    :flag_not_found,
    :environment_not_found,
    :snapshot_not_found,
    :ruleset_not_found,
    :missing_targeting_key,
    :repo_not_configured,
    :repo_ambiguous,
    :store_not_configured,
    :store_adapter_invalid,
    :store_unavailable,
    :invalid_command,
    :invalid_ruleset,
    :variant_weights_invalid,
    :invalid_value_projection,
    :malformed_runtime_data,
    :flag_archived,
    :unauthorized,
    :kill_switch_active,
    :not_implemented
  ]

  @doc """
  Returns the stable top-level error domains.
  """
  @spec domains() :: [domain()]
  def domains, do: @domains

  @doc """
  Returns the closed Phase 2 leaf error atoms.
  """
  @spec leaf_types() :: [type()]
  def leaf_types, do: @leaf_types

  @doc """
  Builds a new normalized error struct.
  """
  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      domain: normalize_domain(Map.get(attrs, :domain)),
      type: normalize_type(Map.get(attrs, :type)),
      message: normalize_message(Map.get(attrs, :message), Map.get(attrs, :type)),
      metadata: normalize_metadata(Map.get(attrs, :metadata, %{})),
      details: normalize_details(Map.get(attrs, :details, [])),
      cause: Map.get(attrs, :cause),
      plug_status: Map.get(attrs, :plug_status)
    }
  end

  @doc """
  Normalizes a term into a `Rulestead.Error`.
  """
  @spec normalize(t() | keyword() | map()) :: t()
  def normalize(%__MODULE__{} = error), do: new(Map.from_struct(error))
  def normalize(attrs) when is_list(attrs) or is_map(attrs), do: new(attrs)

  @impl true
  def exception(attrs), do: new(attrs)

  @impl true
  def message(%__MODULE__{message: message}) when is_binary(message), do: message

  defp normalize_domain(domain) when domain in @domains, do: domain
  defp normalize_domain(_domain), do: :config

  defp normalize_type(type) when type in @leaf_types, do: type
  defp normalize_type(_type), do: :invalid_command

  defp normalize_message(message, _type) when is_binary(message) and byte_size(message) > 0,
    do: message

  defp normalize_message(_message, type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_message(_message, _type), do: "rulestead error"

  defp normalize_metadata(metadata) when is_map(metadata) do
    Enum.reduce(metadata, %{}, fn
      {key, value}, acc when is_atom(key) or is_binary(key) ->
        case normalize_metadata_value(value) do
          {:ok, safe_value} -> Map.put(acc, key, safe_value)
          :error -> acc
        end

      _, acc ->
        acc
    end)
  end

  defp normalize_metadata(_metadata), do: %{}

  defp normalize_metadata_value(value)
       when is_nil(value) or is_boolean(value) or is_integer(value) or is_float(value) or
              is_atom(value) or is_binary(value) do
    {:ok, value}
  end

  defp normalize_metadata_value(_value), do: :error

  defp normalize_details(details) when is_list(details) do
    Enum.flat_map(details, fn
      detail when is_map(detail) -> [normalize_detail(detail)]
      _other -> []
    end)
  end

  defp normalize_details(_details), do: []

  defp normalize_detail(detail) do
    Enum.reduce(detail, %{}, fn
      {key, value}, acc when is_atom(key) or is_binary(key) ->
        if valid_detail_value?(value) do
          Map.put(acc, key, value)
        else
          acc
        end

      _, acc ->
        acc
    end)
  end

  defp valid_detail_value?(value)
       when is_nil(value) or is_boolean(value) or is_integer(value) or is_float(value) or
              is_atom(value) or is_binary(value),
       do: true

  defp valid_detail_value?(_value), do: false
end

if Code.ensure_loaded?(Jason.Encoder) do
  defimpl Jason.Encoder, for: Rulestead.Error do
    def encode(error, opts) do
      Jason.Encode.map(
        %{
          domain: error.domain,
          type: error.type,
          message: error.message,
          metadata: error.metadata,
          details: error.details,
          plug_status: error.plug_status
        },
        opts
      )
    end
  end
end
