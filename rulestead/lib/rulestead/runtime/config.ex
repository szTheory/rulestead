defmodule Rulestead.Runtime.Config do
  @moduledoc false

  @default_snapshot [
    refresh_interval_ms: 15_000,
    min_refresh_interval_ms: 5_000,
    max_refresh_interval_ms: 60_000,
    refresh_jitter_ms: 1_000,
    backoff_ms: [1_000, 2_000, 4_000, 8_000, 16_000, 30_000],
    pubsub_topic: "rulestead:runtime_snapshot"
  ]

  @spec runtime_options(keyword()) :: keyword()
  def runtime_options(overrides \\ []) do
    host_runtime =
      Rulestead.Config.load()
      |> Keyword.get(:runtime, [])
      |> normalize_keyword()

    runtime =
      :rulestead
      |> Application.get_env(:runtime, [])
      |> normalize_keyword()

    host_runtime
    |> Keyword.merge(runtime)
    |> Keyword.merge(overrides)
  end

  @spec environment_keys(keyword()) :: [String.t()]
  def environment_keys(opts \\ []) do
    opts
    |> runtime_options()
    |> Keyword.get(:environment_keys, [])
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
  end

  @spec store(keyword()) :: module() | nil
  def store(opts \\ []) do
    opts
    |> runtime_options()
    |> Keyword.get(:store, Application.get_env(:rulestead, :store))
  end

  @spec notifier(keyword()) :: module() | nil
  def notifier(opts \\ []) do
    opts
    |> runtime_options()
    |> Keyword.get(:notifier)
  end

  @spec health_peer_provider(keyword()) :: module() | nil
  def health_peer_provider(opts \\ []) do
    opts
    |> runtime_options()
    |> Keyword.get(:health_peer_provider)
  end

  @spec pubsub(keyword()) :: module() | atom() | nil
  def pubsub(opts \\ []) do
    opts
    |> runtime_options()
    |> Keyword.get(:pubsub)
  end

  @spec pubsub_topic(keyword()) :: String.t()
  def pubsub_topic(opts \\ []) do
    opts
    |> runtime_options()
    |> Keyword.get(:pubsub_topic, snapshot(opts)[:pubsub_topic])
    |> to_string()
  end

  @spec snapshot(keyword()) :: keyword()
  def snapshot(opts \\ []) do
    configured =
      :rulestead
      |> Application.get_env(:snapshot, [])
      |> normalize_keyword()

    Keyword.merge(@default_snapshot, configured)
    |> Keyword.merge(
      opts
      |> runtime_options()
      |> Keyword.get(:snapshot, [])
      |> normalize_keyword()
    )
  end

  defp normalize_keyword(value) when is_list(value), do: value
  defp normalize_keyword(value) when is_map(value), do: Map.to_list(value)
  defp normalize_keyword(_value), do: []
end
