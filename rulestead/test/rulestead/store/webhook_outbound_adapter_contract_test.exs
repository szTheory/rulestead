defmodule Rulestead.WebhookOutboundAdapterContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    ensure_phase9_schema!()
    ensure_phase12_schema!()
    ensure_oban_jobs!()
    :ok
  end

  test "governance events enqueue outbound deliveries transactionally across fake and ecto adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_governed_publish!(adapter)

      submitter = %{id: "submitter-1", type: "operator", display: "Submitter"}

      # Create a destination that subscribes to change_request.submitted
      {:ok, dest} = adapter.create_webhook_destination(Command.CreateWebhookDestination.new(%{
        name: "Test Slack",
        url: "https://hooks.slack.com/...",
        environment_key: "test",
        subscriptions: ["change_request.submitted"]
      }))

      submit_command =
        Command.SubmitChangeRequest.new(
          %{
            action: :publish_ruleset,
            environment_key: "test",
            resource_type: "flag",
            resource_key: "checkout-redesign",
            command: %{"version" => 2},
            approval_requirement:
              ApprovalRequirement.new(
                action: :publish_ruleset,
                environment_key: "test",
                required_approvals: 1,
                change_request_required?: true,
                self_approval_allowed?: false
              )
          },
          actor: submitter,
          reason: "Ship version 2",
          metadata: %{request_id: "corr-123", source: :review_queue}
        )

      assert {:ok, %{change_request: submitted}} = adapter.submit_change_request(submit_command)
      assert submitted.state == :submitted

      {:ok, deliveries_page} = adapter.list_webhook_deliveries(Command.ListWebhookDeliveries.new(destination_id: dest.id))
      assert [%{state: :pending} = delivery] = deliveries_page.entries

      # Enqueue should have created an Oban job
      if adapter == StoreEcto do
        result = Rulestead.Repo.query!("SELECT queue, args FROM oban_jobs")
        assert [[queue, args]] = result.rows
        assert queue == "rulestead_webhook_delivery"
        assert args["delivery_id"] == delivery.id
      end
    end)
  end

  defp seed_governed_publish!(adapter) do
    ensure_environment!("test")

    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(StoreFixtures.valid_flag_attrs(%{permanent: true}))
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "test",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test")
             )
  end

  defp reset_adapter!(Rulestead.Fake) do
    Rulestead.Fake.Control.reset!()
  end

  defp reset_adapter!(StoreEcto) do
    :ok
  end

  defp ensure_environment!(key) do
    case Rulestead.Repo.get_by(Rulestead.Environment, key: key) do
      nil ->
        attrs = StoreFixtures.valid_environment_attrs(%{key: key, name: String.upcase(key)})
        changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)
        assert {:ok, _env} = Rulestead.Repo.insert(changeset)

      _env ->
        :ok
    end
  end

  defp ensure_phase9_schema! do
    # Re-use schema from GovernanceAdapterContractTest
    Rulestead.Repo.query!("ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false")
    Rulestead.Repo.query!("ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone")

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS change_requests (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      status text NOT NULL DEFAULT 'submitted',
      governed_action text NOT NULL,
      environment_key text NOT NULL,
      resource_type text NOT NULL,
      resource_key text NOT NULL,
      submitter_id text NOT NULL,
      submitter_type text NOT NULL,
      submitter_display text,
      reason text,
      approval_requirement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      command_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      submitted_at timestamp(6) with time zone NOT NULL,
      resolved_at timestamp(6) with time zone,
      executed_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")
  end

  defp ensure_phase12_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS webhook_destinations (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name text NOT NULL,
      description text,
      url text NOT NULL,
      secret_id text,
      environment_key text NOT NULL,
      subscriptions text[] NOT NULL DEFAULT '{}',
      enabled boolean NOT NULL DEFAULT true,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")
    
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS webhook_outbound_events (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      event_type text NOT NULL,
      payload jsonb NOT NULL DEFAULT '{}'::jsonb,
      resource_type text,
      resource_key text,
      environment_key text,
      correlation_id text NOT NULL,
      inserted_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS webhook_deliveries (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      webhook_destination_id uuid NOT NULL REFERENCES webhook_destinations(id) ON DELETE CASCADE,
      webhook_outbound_event_id uuid NOT NULL REFERENCES webhook_outbound_events(id) ON DELETE CASCADE,
      state text NOT NULL DEFAULT 'pending',
      attempt_count integer NOT NULL DEFAULT 0,
      last_attempt_at timestamp(6) with time zone,
      next_attempt_at timestamp(6) with time zone,
      terminal_failure_reason text,
      last_response_code integer,
      last_response_body text,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")
  end

  defp ensure_oban_jobs! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS oban_jobs (
      id bigserial PRIMARY KEY,
      state text NOT NULL DEFAULT 'scheduled',
      queue text NOT NULL DEFAULT 'default',
      worker text NOT NULL,
      args jsonb NOT NULL DEFAULT '{}'::jsonb,
      meta jsonb NOT NULL DEFAULT '{}'::jsonb,
      tags text[] NOT NULL DEFAULT '{}',
      errors jsonb[] NOT NULL DEFAULT '{}',
      attempt integer NOT NULL DEFAULT 0,
      max_attempts integer NOT NULL DEFAULT 3,
      priority integer NOT NULL DEFAULT 0,
      attempted_by text[],
      attempted_at timestamp(6) with time zone,
      cancelled_at timestamp(6) with time zone,
      completed_at timestamp(6) with time zone,
      discarded_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      scheduled_at timestamp(6) with time zone NOT NULL
    )")
  end
end
