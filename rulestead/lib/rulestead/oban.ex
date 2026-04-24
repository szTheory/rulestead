defmodule Rulestead.Oban do
  @moduledoc """
  Explicit Oban-facing helpers for serializing and restoring
  `%Rulestead.Context{}` values across job boundaries.
  """

  alias Rulestead.Context
  alias Rulestead.Governance.ScheduledExecution

  @default_key "rulestead_context"
  @bounded_fields ~w(actor targeting_key tenant_key environment attributes request_id session_id strict?)a
  @scheduled_execution_queue "rulestead_scheduled_execution"
  @scheduled_execution_worker "Elixir.Rulestead.Oban.ScheduledExecutionWorker"
  @scheduled_execution_max_attempts 3

  @doc """
  Restores a normalized context from a job-like map.
  """
  @spec context_from_job(map(), keyword()) :: Context.t()
  def context_from_job(job, opts \\ []) when is_map(job) and is_list(opts) do
    key = Keyword.get(opts, :context_key, @default_key)

    job
    |> serialized_context(key)
    |> case do
      nil -> Context.new(%{})
      attrs -> attrs |> atomize_bounded_keys() |> Context.normalize()
    end
  end

  @doc """
  Attaches a serialized context payload to a job-like map.
  """
  @spec put_context(map(), Context.t() | keyword() | map(), keyword()) :: map()
  def put_context(job, context, opts \\ []) when is_map(job) and is_list(opts) do
    key = Keyword.get(opts, :context_key, @default_key)
    serialized = serialize_context(context)
    args = job |> Map.get(:args, %{}) |> Map.put(key, serialized)

    Map.put(job, :args, args)
  end

  @doc """
  Produces the bounded, serializable context payload used by Oban seams.
  """
  @spec serialize_context(Context.t() | keyword() | map()) :: map()
  def serialize_context(context) do
    context
    |> Context.normalize()
    |> Map.from_struct()
    |> Map.take(@bounded_fields)
    |> Map.update(:actor, nil, &normalize_actor/1)
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, Atom.to_string(key), value) end)
  end

  @doc """
  Builds the durable Oban payload for a scheduled execution delivery.
  """
  @spec scheduled_execution_job(ScheduledExecution.t() | map(), Context.t() | map() | keyword()) :: map()
  def scheduled_execution_job(scheduled_execution, context \\ %{}) do
    scheduled_execution = ScheduledExecution.new(scheduled_execution)
    inserted_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    %{
      state: "scheduled",
      queue: @scheduled_execution_queue,
      worker: @scheduled_execution_worker,
      args: %{
        "scheduled_execution_id" => scheduled_execution.id,
        "correlation_id" => scheduled_execution.correlation_id,
        "governed_action" => scheduled_execution.action |> Atom.to_string(),
        "environment_key" => scheduled_execution.environment_key,
        @default_key => serialize_context(context)
      },
      meta: %{},
      tags: ["rulestead", "scheduled_execution"],
      errors: [],
      attempt: 0,
      max_attempts: @scheduled_execution_max_attempts,
      priority: 0,
      inserted_at: inserted_at,
      scheduled_at: scheduled_execution.scheduled_for
    }
  end

  @spec scheduled_execution_worker() :: String.t()
  def scheduled_execution_worker, do: @scheduled_execution_worker

  @spec scheduled_execution_max_attempts() :: pos_integer()
  def scheduled_execution_max_attempts, do: @scheduled_execution_max_attempts

  defp serialized_context(job, key) do
    fetch_key(Map.get(job, :args, %{}), key) || fetch_key(Map.get(job, :meta, %{}), key)
  end

  defp normalize_actor(nil), do: nil
  defp normalize_actor(%_{} = actor), do: actor |> Map.from_struct() |> normalize_actor()
  defp normalize_actor(actor) when is_map(actor), do: Enum.into(actor, %{})
  defp normalize_actor(actor), do: %{"key" => to_string(actor)}

  defp fetch_key(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))

  defp atomize_bounded_keys(attrs) when is_map(attrs) do
    Enum.reduce(@bounded_fields, %{}, fn key, acc ->
      case Map.fetch(attrs, Atom.to_string(key)) do
        {:ok, value} -> Map.put(acc, key, value)
        :error -> acc
      end
    end)
  end
end
