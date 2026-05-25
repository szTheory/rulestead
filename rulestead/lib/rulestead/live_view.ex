defmodule Rulestead.LiveView do
  @moduledoc false
  # Explicit LiveView helpers for carrying `%Rulestead.Context{}` and eagerly
  # assigning runtime-backed flag values onto a socket.

  alias Rulestead.{Context, Runtime}

  @default_context_assign :rulestead_context

  @type flag_projection ::
          String.t()
          | atom()
          | {:enabled, String.t() | atom()}
          | {:variant, String.t() | atom()}
          | {:value, String.t() | atom(), term()}
          | {:evaluate, String.t() | atom()}
          | %{
              required(:flag_key) => String.t() | atom(),
              optional(:mode) => atom(),
              optional(:default) => term()
            }

  @doc """
  Builds a normalized context from a socket-like map and explicit session data.
  """
  @spec context_from_socket(map(), keyword()) :: Context.t()
  def context_from_socket(socket, opts \\ []) when is_map(socket) and is_list(opts) do
    socket
    |> base_context(opts)
    |> merge_context(socket_attrs(socket, opts))
  end

  @doc """
  Resolves a set of runtime-backed flag projections and writes them into socket
  assigns in one pass.
  """
  @spec assign_flags(map(), map() | keyword() | [flag_projection()], keyword()) :: map()
  def assign_flags(socket, flag_specs, opts \\ []) when is_map(socket) and is_list(opts) do
    context = resolve_context(socket, opts)

    environment_key =
      Keyword.get(opts, :environment, context.environment) ||
        raise ArgumentError, "assign_flags/3 requires an environment"

    assignments =
      flag_specs
      |> normalize_flag_specs()
      |> Enum.reduce(%{}, fn {assign_key, spec}, acc ->
        Map.put(acc, assign_key, resolve_projection(environment_key, context, spec))
      end)

    put_assigns(socket, assignments)
  end

  defp base_context(socket, opts) do
    assign_key = Keyword.get(opts, :context_assign, @default_context_assign)

    case socket |> Map.get(:assigns, %{}) |> Map.get(assign_key) do
      %Context{} = context -> context
      _other -> Context.new(%{})
    end
  end

  defp socket_attrs(socket, opts) do
    %{}
    |> maybe_put(:actor, resolve_opt(socket, opts, :actor))
    |> maybe_put(:targeting_key, resolve_targeting_key(socket, opts))
    |> maybe_put(:tenant_key, resolve_tenant_key(socket, opts))
    |> maybe_put(:environment, resolve_opt(socket, opts, :environment))
    |> maybe_put(:attributes, resolve_opt(socket, opts, :attributes))
    |> maybe_put(:request_id, resolve_opt(socket, opts, :request_id))
    |> maybe_put(:session_id, resolve_opt(socket, opts, :session_id))
    |> maybe_put_strict(socket, opts)
  end

  defp resolve_context(socket, opts) do
    case Keyword.get(opts, :context) do
      %Context{} = context -> Context.normalize(context)
      nil -> context_from_socket(socket, opts)
      context -> Context.normalize(context)
    end
  end

  defp resolve_projection(environment_key, context, {:enabled, flag_key}) do
    unwrap_runtime!(:enabled?, Runtime.enabled?(environment_key, flag_key, context), flag_key)
  end

  defp resolve_projection(environment_key, context, {:variant, flag_key}) do
    unwrap_runtime!(
      :get_variant,
      Runtime.get_variant(environment_key, flag_key, context),
      flag_key
    )
  end

  defp resolve_projection(environment_key, context, {:value, flag_key, default}) do
    unwrap_runtime!(
      :get_value,
      Runtime.get_value(environment_key, flag_key, context, default),
      flag_key
    )
  end

  defp resolve_projection(environment_key, context, {:evaluate, flag_key}) do
    unwrap_runtime!(:evaluate, Runtime.evaluate(environment_key, flag_key, context), flag_key)
  end

  defp resolve_projection(environment_key, context, %{flag_key: flag_key} = spec) do
    case Map.get(spec, :mode, :enabled) do
      :enabled ->
        resolve_projection(environment_key, context, {:enabled, flag_key})

      :variant ->
        resolve_projection(environment_key, context, {:variant, flag_key})

      :value ->
        resolve_projection(environment_key, context, {:value, flag_key, Map.get(spec, :default)})

      :evaluate ->
        resolve_projection(environment_key, context, {:evaluate, flag_key})
    end
  end

  defp resolve_projection(environment_key, context, flag_key) do
    resolve_projection(environment_key, context, {:enabled, flag_key})
  end

  defp unwrap_runtime!(_operation, {:ok, value}, _flag_key), do: value

  defp unwrap_runtime!(operation, {:error, error}, flag_key) do
    raise ArgumentError, "runtime #{operation} failed for #{inspect(flag_key)}: #{inspect(error)}"
  end

  defp normalize_flag_specs(specs) when is_list(specs) do
    if Keyword.keyword?(specs) do
      Enum.into(specs, [])
    else
      Enum.map(specs, fn spec -> {default_assign_key(spec), spec} end)
    end
  end

  defp normalize_flag_specs(specs) when is_map(specs), do: Enum.into(specs, [])

  defp default_assign_key(%{flag_key: flag_key}), do: default_assign_key(flag_key)
  defp default_assign_key({_, flag_key}), do: default_assign_key(flag_key)
  defp default_assign_key(flag_key), do: flag_key

  defp put_assigns(socket, attrs) do
    assigns = socket |> Map.get(:assigns, %{}) |> Map.merge(attrs)
    Map.put(socket, :assigns, assigns)
  end

  defp merge_context(%Context{} = base, attrs) do
    base
    |> Map.from_struct()
    |> Map.merge(attrs)
    |> Context.new()
  end

  defp resolve_targeting_key(socket, opts) do
    opts
    |> Keyword.get(:targeting_key_sources, [
      {:session, "targeting_key"},
      {:assign, :targeting_key}
    ])
    |> Enum.find_value(fn source -> socket_source(socket, source, opts) end)
  end

  defp resolve_tenant_key(socket, opts) do
    explicit = resolve_opt(socket, opts, :tenant_key)

    if explicit do
      explicit
    else
      Rulestead.Tenancy.resolve_tenant(socket)
    end
  end

  defp resolve_opt(socket, opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, source} -> socket_source(socket, source, opts)
      :error -> nil
    end
  end

  defp socket_source(socket, {:assign, key}, _opts) do
    socket |> Map.get(:assigns, %{}) |> fetch_key(key)
  end

  defp socket_source(_socket, {:session, key}, opts) do
    opts |> Keyword.get(:session, %{}) |> fetch_key(key)
  end

  defp socket_source(socket, {:private, key}, _opts) do
    socket |> Map.get(:private, %{}) |> fetch_key(key)
  end

  defp socket_source(socket, {:param, key}, _opts) do
    socket |> Map.get(:params, %{}) |> fetch_key(key)
  end

  defp socket_source(socket, resolver, _opts) when is_function(resolver, 1), do: resolver.(socket)
  defp socket_source(_socket, literal, _opts), do: literal

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_strict(map, socket, opts) do
    if Keyword.has_key?(opts, :strict?) do
      Map.put(map, :strict?, socket_source(socket, Keyword.fetch!(opts, :strict?), opts))
    else
      map
    end
  end

  defp fetch_key(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
