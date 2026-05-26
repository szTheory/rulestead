defmodule Rulestead.Redis do
  @moduledoc false

  alias Rulestead.Store.Ecto

  @default_name :rulestead_redis
  @default_url "redis://localhost:6379"
  @reserved_keys [:client, :enabled, :name, :publisher_store, :url]

  @spec enabled?(keyword()) :: boolean()
  def enabled?(overrides \\ []) do
    overrides
    |> config()
    |> Keyword.get(:enabled, true)
  end

  @spec client(keyword()) :: module()
  def client(overrides \\ []) do
    overrides
    |> config()
    |> Keyword.get(:client, Redix)
  end

  @spec publisher_store(keyword()) :: module()
  def publisher_store(overrides \\ []) do
    cfg = config(overrides)

    Keyword.get_lazy(cfg, :publisher_store, fn ->
      Application.get_env(:rulestead, :store, Ecto)
    end)
  end

  @spec name(keyword()) :: GenServer.name()
  def name(overrides \\ []) do
    overrides
    |> config()
    |> Keyword.get(:name, @default_name)
  end

  @spec url(keyword()) :: String.t()
  def url(overrides \\ []) do
    overrides
    |> config()
    |> Keyword.get(:url, @default_url)
  end

  @spec snapshot_key(String.t() | atom()) :: String.t()
  def snapshot_key(environment_key) do
    "rulestead:snapshot:#{to_string(environment_key)}"
  end

  @spec connection_spec(keyword()) :: {String.t(), keyword()}
  def connection_spec(overrides \\ []) do
    cfg = config(overrides)

    options =
      cfg
      |> Keyword.drop(@reserved_keys)
      |> Keyword.put_new(:name, name(cfg))
      |> Keyword.put_new(:sync_connect, false)
      |> Keyword.put_new(:exit_on_disconnection, false)

    {url(cfg), options}
  end

  @spec child_specs(keyword()) :: [Supervisor.child_spec() | module()]
  def child_specs(overrides \\ []) do
    if enabled?(overrides) do
      [
        Supervisor.child_spec({client(overrides), connection_spec(overrides)},
          id: name(overrides)
        ),
        Rulestead.Redis.Publisher
      ]
    else
      []
    end
  end

  @spec config(keyword()) :: keyword()
  def config(overrides \\ []) do
    :rulestead
    |> Application.get_env(:redis, [])
    |> normalize_keyword()
    |> Keyword.merge(normalize_keyword(overrides))
  end

  defp normalize_keyword(value) when is_list(value), do: value
  defp normalize_keyword(value) when is_map(value), do: Map.to_list(value)
  defp normalize_keyword(_value), do: []
end
