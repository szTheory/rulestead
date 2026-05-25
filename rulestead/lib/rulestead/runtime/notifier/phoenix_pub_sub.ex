defmodule Rulestead.Runtime.Notifier.PhoenixPubSub do
  @moduledoc false

  @behaviour Rulestead.Runtime.Notifier

  @event :rulestead_runtime_refresh

  @impl true
  def broadcast(notice, opts) do
    case Keyword.get(opts, :pubsub) do
      nil ->
        :ok

      pubsub ->
        if Code.ensure_loaded?(Phoenix.PubSub) do
          Phoenix.PubSub.broadcast(pubsub, Keyword.fetch!(opts, :pubsub_topic), {@event, notice})
          :ok
        else
          :ok
        end
    end
  end

  @impl true
  def subscribe(opts) do
    case Keyword.get(opts, :pubsub) do
      nil ->
        :ok

      pubsub ->
        if Code.ensure_loaded?(Phoenix.PubSub) do
          Phoenix.PubSub.subscribe(pubsub, Keyword.fetch!(opts, :pubsub_topic))
        else
          :ok
        end
    end
  end
end
