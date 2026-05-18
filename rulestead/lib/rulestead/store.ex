defmodule Rulestead.Store do
  @moduledoc """
  Key-first authoring store behavior for the Rulestead public API.

  The contract is semantic and domain-oriented rather than CRUD-oriented.
  Implementations must normalize misses into `{:error, %Rulestead.Error{}}`
  and may not return `nil` for not-found cases.
  """

  alias Rulestead.Error
  alias Rulestead.Store.Command

  @type result(value) :: {:ok, value} | {:error, Error.t()}

  @callback fetch_flag(Command.FetchFlag.t()) :: result(map())
  @callback compare_environments(Command.CompareEnvironments.t()) :: result(map())
  @callback fetch_snapshot(Command.FetchSnapshot.t()) :: result(map())
  @callback create_flag(Command.CreateFlag.t()) :: result(map())
  @callback update_flag(Command.UpdateFlag.t()) :: result(map())
  @callback save_draft_ruleset(Command.SaveDraftRuleset.t()) :: result(map())
  @callback publish_ruleset(Command.PublishRuleset.t()) :: result(map())
  @callback archive_flag(Command.ArchiveFlag.t()) :: result(map())
  @callback list_flags(Command.ListFlags.t()) :: result(Command.Page.t(map()))
  @callback list_environments(Command.ListEnvironments.t()) :: result([map()])
  @callback list_audiences(Command.ListAudiences.t()) :: result([map()])
  @callback record_evaluation(Command.RecordEvaluation.t()) :: result(map())
  @callback engage_kill_switch(Command.EngageKillSwitch.t()) :: result(map())
  @callback release_kill_switch(Command.ReleaseKillSwitch.t()) :: result(map())
  @callback list_audit_events(Command.ListAuditEvents.t()) :: result(Command.Page.t(map()))
  @callback rollback_audit_event(Command.RollbackAuditEvent.t()) :: result(map())
  @callback submit_change_request(Command.SubmitChangeRequest.t()) :: result(map())
  @callback approve_change_request(Command.ApproveChangeRequest.t()) :: result(map())
  @callback reject_change_request(Command.RejectChangeRequest.t()) :: result(map())
  @callback cancel_change_request(Command.CancelChangeRequest.t()) :: result(map())
  @callback execute_change_request(Command.ExecuteChangeRequest.t()) :: result(map())
  @callback fetch_change_request(Command.FetchChangeRequest.t()) :: result(map())
  @callback list_change_requests(Command.ListChangeRequests.t()) :: result(Command.Page.t(map()))
  @callback schedule_change_request(Command.ScheduleChangeRequest.t()) :: result(map())
  @callback schedule_governed_action(Command.ScheduleGovernedAction.t()) :: result(map())
  @callback cancel_scheduled_execution(Command.CancelScheduledExecution.t()) :: result(map())
  @callback requeue_scheduled_execution(Command.RequeueScheduledExecution.t()) :: result(map())
  @callback execute_scheduled_execution(Command.ExecuteScheduledExecution.t()) :: result(map())
  @callback fetch_scheduled_execution(Command.FetchScheduledExecution.t()) :: result(map())
  @callback list_scheduled_executions(Command.ListScheduledExecutions.t()) ::
              result(Command.Page.t(map()))

  @callback receive_inbound_webhook(Command.ReceiveInboundWebhook.t()) :: result(map())
  @callback fetch_webhook_record(Command.FetchWebhookRecord.t()) :: result(map())
  @callback list_webhook_records(Command.ListWebhookRecords.t()) :: result(Command.Page.t(map()))

  @callback create_webhook_destination(Command.CreateWebhookDestination.t()) :: result(map())
  @callback update_webhook_destination(Command.UpdateWebhookDestination.t()) :: result(map())
  @callback fetch_webhook_destination(Command.FetchWebhookDestination.t()) :: result(map())
  @callback list_webhook_destinations(Command.ListWebhookDestinations.t()) ::
              result(Command.Page.t(map()))

  @callback list_webhook_deliveries(Command.ListWebhookDeliveries.t()) ::
              result(Command.Page.t(map()))

  @callback retry_webhook_delivery(Command.RetryWebhookDelivery.t()) :: result(map())
end
