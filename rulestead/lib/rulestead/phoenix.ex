defmodule Rulestead.Phoenix do
  @moduledoc """
  Explicit Phoenix-facing helpers for building `%Rulestead.Context{}` values.

  This module keeps framework structs at the edge and only projects configured,
  bounded fields into the runtime context.
  """

  alias Rulestead.Context

  @default_context_assign :rulestead_context
  @default_targeting_key_sources [
    {:session, "targeting_key"},
    {:cookie, "rulestead_targeting_key"},
    {:header, "x-rulestead-targeting-key"}
  ]

  @type source ::
          {:assign, atom() | String.t()}
          | {:session, atom() | String.t()}
          | {:header, String.t()}
          | {:cookie, atom() | String.t()}
          | {:param, atom() | String.t()}
          | {:private, atom() | String.t()}
          | (map() -> term())
          | term()

  @doc """
  Builds a normalized context from a conn-like map.

  Supported source descriptors are explicit and caller-visible:

  - `{:assign, key}`
  - `{:session, key}`
  - `{:header, name}`
  - `{:cookie, key}`
  - `{:param, key}`
  - `{:private, key}`
  - `fn conn -> ... end`
  - literal values
  """
  @spec context_from_conn(map(), keyword()) :: Context.t()
  def context_from_conn(conn, opts \\ []) when is_map(conn) and is_list(opts) do
    conn
    |> base_context(opts)
    |> merge_context(conn_attrs(conn, opts))
  end

  @doc false
  @spec source_value(map(), source(), keyword()) :: term()
  def source_value(host, {:assign, key}, opts) do
    host |> Map.get(:assigns, %{}) |> fetch_key(key, opts)
  end

  def source_value(host, {:session, key}, opts) do
    host
    |> session_data(opts)
    |> fetch_key(key, opts)
  end

  def source_value(host, {:header, name}, _opts) do
    header_name = name |> to_string() |> String.downcase()

    host
    |> Map.get(:req_headers, [])
    |> Enum.find_value(fn
      {key, value} when is_binary(key) ->
        if String.downcase(key) == header_name, do: value

      _header ->
        nil
    end)
  end

  def source_value(host, {:cookie, key}, opts) do
    host |> Map.get(:cookies, %{}) |> fetch_key(key, opts)
  end

  def source_value(host, {:param, key}, opts) do
    host |> Map.get(:params, %{}) |> fetch_key(key, opts)
  end

  def source_value(host, {:private, key}, opts) do
    host |> Map.get(:private, %{}) |> fetch_key(key, opts)
  end

  def source_value(host, resolver, _opts) when is_function(resolver, 1), do: resolver.(host)
  def source_value(_host, literal, _opts), do: literal

  @doc false
  @spec build_context(map(), keyword(), (map(), source(), keyword() -> term())) :: Context.t()
  def build_context(host, opts, resolver) when is_function(resolver, 3) do
    host
    |> base_context(opts)
    |> merge_context(
      %{}
      |> maybe_put(:actor, host, opts, :actor, resolver)
      |> maybe_put(:targeting_key, resolve_targeting_key(host, opts, resolver))
      |> maybe_put(:tenant_key, host, opts, :tenant_key, resolver)
      |> maybe_put(:environment, host, opts, :environment, resolver)
      |> maybe_put(:attributes, host, opts, :attributes, resolver)
      |> maybe_put(:request_id, host, opts, :request_id, resolver)
      |> maybe_put(:session_id, host, opts, :session_id, resolver)
      |> maybe_put_strict(host, opts, resolver)
    )
  end

  defp conn_attrs(conn, opts) do
    %{}
    |> maybe_put(:actor, resolve_opt(conn, opts, :actor, &source_value/3))
    |> maybe_put(:targeting_key, resolve_targeting_key(conn, opts, &source_value/3))
    |> maybe_put(:tenant_key, resolve_opt(conn, opts, :tenant_key, &source_value/3))
    |> maybe_put(:environment, resolve_opt(conn, opts, :environment, &source_value/3))
    |> maybe_put(:attributes, resolve_opt(conn, opts, :attributes, &source_value/3))
    |> maybe_put(:request_id, resolve_opt(conn, opts, :request_id, &source_value/3))
    |> maybe_put(:session_id, resolve_opt(conn, opts, :session_id, &source_value/3))
    |> maybe_put_strict(conn, opts, &source_value/3)
  end

  defp base_context(host, opts) do
    assign_key = Keyword.get(opts, :context_assign, @default_context_assign)

    case host |> Map.get(:assigns, %{}) |> Map.get(assign_key) do
      %Context{} = context -> context
      _other -> Context.new(%{})
    end
  end

  defp merge_context(%Context{} = base, attrs) when is_map(attrs) do
    base
    |> Map.from_struct()
    |> Map.merge(attrs)
    |> Context.new()
  end

  defp resolve_targeting_key(host, opts, resolver) do
    opts
    |> Keyword.get(:targeting_key_sources, @default_targeting_key_sources)
    |> Enum.find_value(fn source -> resolver.(host, source, opts) end)
  end

  defp resolve_opt(host, opts, key, resolver) do
    case Keyword.fetch(opts, key) do
      {:ok, source} -> resolver.(host, source, opts)
      :error -> nil
    end
  end

  defp maybe_put(map, key, host, opts, opt_key, resolver) do
    maybe_put(map, key, resolve_opt(host, opts, opt_key, resolver))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_strict(map, host, opts, resolver) do
    if Keyword.has_key?(opts, :strict?) do
      Map.put(map, :strict?, resolver.(host, Keyword.fetch!(opts, :strict?), opts))
    else
      map
    end
  end

  defp session_data(host, opts) do
    cond do
      Keyword.has_key?(opts, :session) and is_map(opts[:session]) ->
        opts[:session]

      is_map(Map.get(host, :private)) ->
        Map.get(host.private, :plug_session) || Map.get(host.private, "plug_session") || %{}

      true ->
        %{}
    end
  end

  defp fetch_key(map, key, _opts) when is_map(map) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end
end
