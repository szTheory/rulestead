defmodule Rulestead.Store.Redis do
  @moduledoc false
  alias Rulestead.{Redis, Store, StoreError}
  alias Rulestead.Store.Command

  @behaviour Store

  @read_only_message "Redis adapter is read-only"

  @impl Store
  def fetch_snapshot(%Command.FetchSnapshot{} = command) do
    case Redis.client().command(Redis.name(), ["GET", Redis.snapshot_key(command.environment_key)]) do
      {:ok, nil} ->
        {:error, snapshot_not_found(command)}

      {:ok, payload} when is_binary(payload) ->
        decode_snapshot(payload, command)

      {:error, reason} ->
        {:error,
         StoreError.unavailable(
           metadata: %{environment_key: to_string(command.environment_key)},
           cause: reason
         )}
    end
  end

  for callback <- [
        :compare_environments,
        :apply_promotion,
        :preview_manifest_import,
        :apply_manifest_import,
        :fetch_flag,
        :create_flag,
        :update_flag,
        :save_draft_ruleset,
        :publish_ruleset,
        :archive_flag,
        :list_flags,
        :list_environments,
        :list_audiences,
        :list_audience_dependencies,
        :preview_audience_impact,
        :apply_audience_mutation,
        :record_evaluation,
        :advance_rollout,
        :evaluate_guarded_rollout,
        :fetch_guardrail_status,
        :engage_kill_switch,
        :release_kill_switch,
        :list_audit_events,
        :rollback_audit_event,
        :submit_change_request,
        :approve_change_request,
        :reject_change_request,
        :cancel_change_request,
        :execute_change_request,
        :fetch_change_request,
        :list_change_requests,
        :schedule_change_request,
        :schedule_governed_action,
        :cancel_scheduled_execution,
        :requeue_scheduled_execution,
        :execute_scheduled_execution,
        :fetch_scheduled_execution,
        :list_scheduled_executions,
        :receive_inbound_webhook,
        :fetch_webhook_record,
        :list_webhook_records,
        :create_webhook_destination,
        :update_webhook_destination,
        :fetch_webhook_destination,
        :list_webhook_destinations,
        :list_webhook_deliveries,
        :retry_webhook_delivery
      ] do
    @impl Store
    def unquote(callback)(_command), do: {:error, StoreError.invalid_command(@read_only_message)}
  end

  defp decode_snapshot(payload, command) do
    snapshot = :erlang.binary_to_term(payload, [:safe])

    cond do
      not is_map(snapshot) ->
        {:error, invalid_snapshot(command, snapshot)}

      not is_nil(command.version) and Map.get(snapshot, :version) != command.version ->
        {:error, snapshot_not_found(command)}

      true ->
        {:ok, snapshot}
    end
  rescue
    error in [ArgumentError] ->
      {:error,
       StoreError.unavailable(
         metadata: %{environment_key: to_string(command.environment_key)},
         cause: error
       )}
  end

  defp invalid_snapshot(command, snapshot) do
    StoreError.unavailable(
      metadata: %{environment_key: to_string(command.environment_key)},
      details: [%{message: "redis snapshot payload was invalid"}],
      cause: snapshot
    )
  end

  defp snapshot_not_found(%Command.FetchSnapshot{} = command) do
    metadata =
      %{environment_key: to_string(command.environment_key)}
      |> maybe_put(:version, command.version)

    StoreError.snapshot_not_found(command.environment_key, metadata: metadata)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
