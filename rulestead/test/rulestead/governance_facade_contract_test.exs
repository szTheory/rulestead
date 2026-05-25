defmodule Rulestead.GovernanceFacadeContractTest do
  use ExUnit.Case, async: false

  alias Rulestead.{
    Error,
    Governance.ApprovalRequirement,
    Governance.ChangeRequest,
    Governance.ScheduledExecution,
    Store.Command,
    Telemetry
  }

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Rulestead.Fake.Control.reset!()

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end

      Rulestead.Fake.Control.reset!()
    end)

    :ok
  end

  test "root facade exports governance verbs in command-first forms" do
    assert Code.ensure_loaded?(Rulestead)
    assert function_exported?(Rulestead, :submit_change_request, 1)
    assert function_exported?(Rulestead, :approve_change_request, 1)
    assert function_exported?(Rulestead, :reject_change_request, 1)
    assert function_exported?(Rulestead, :cancel_change_request, 1)
    assert function_exported?(Rulestead, :execute_change_request, 1)
    assert function_exported?(Rulestead, :fetch_change_request, 1)
    assert function_exported?(Rulestead, :list_change_requests, 1)

    approval_requirement =
      ApprovalRequirement.new(
        action: :publish_ruleset,
        environment_key: "production",
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: false
      )

    assert %Command.SubmitChangeRequest{
             action: :publish_ruleset,
             environment_key: "production",
             resource_type: "flag",
             resource_key: "checkout-redesign",
             actor: %{"id" => "operator-1"},
             approval_requirement: %{"required_approvals" => 1}
           } =
             Command.SubmitChangeRequest.new(
               %{
                 action: :publish_ruleset,
                 environment_key: "production",
                 resource_type: "flag",
                 resource_key: "checkout-redesign",
                 command: %{"version" => 2},
                 approval_requirement: approval_requirement
               },
               actor: %{id: "operator-1"}
             )

    assert %Command.ApproveChangeRequest{change_request_id: "cr-123"} =
             Command.ApproveChangeRequest.new("cr-123")

    assert %Command.RejectChangeRequest{change_request_id: "cr-123"} =
             Command.RejectChangeRequest.new("cr-123")

    assert %Command.CancelChangeRequest{change_request_id: "cr-123"} =
             Command.CancelChangeRequest.new("cr-123")

    assert %Command.ExecuteChangeRequest{change_request_id: "cr-123"} =
             Command.ExecuteChangeRequest.new("cr-123")

    assert %Command.FetchChangeRequest{change_request_id: "cr-123"} =
             Command.FetchChangeRequest.new("cr-123")

    assert %Command.ListChangeRequests{
             environment_key: "production",
             status: :submitted,
             resource_key: "checkout-redesign"
           } =
             Command.ListChangeRequests.new(
               environment_key: "production",
               status: :submitted,
               resource_key: "checkout-redesign"
             )
  end

  test "promotion is accepted as a first-class governed action across contract surfaces" do
    assert :promote_environment in ChangeRequest.governed_actions()
    assert :promote_environment in ScheduledExecution.governed_actions()
    assert :promote_environment in Rulestead.Admin.Policy.governance_actions()

    approval_requirement =
      ApprovalRequirement.new(
        action: :promote_environment,
        environment_key: "production",
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: false
      )

    assert %Command.SubmitChangeRequest{
             action: :promote_environment,
             environment_key: "production",
             resource_type: "environment",
             resource_key: "production",
             command: %{
               "compare_token" => "cmp_123",
               "flag_keys" => ["checkout-redesign"],
               "source_environment_key" => "staging",
               "target_environment_key" => "production"
             },
             approval_requirement: %{
               "action" => "promote_environment",
               "change_request_required?" => true,
               "environment_key" => "production",
               "required_approvals" => 1,
               "self_approval_allowed?" => false
             }
           } =
             Command.SubmitChangeRequest.new(%{
               action: :promote_environment,
               environment_key: "production",
               resource_type: "environment",
               resource_key: "production",
               command: %{
                 compare_token: "cmp_123",
                 flag_keys: ["checkout-redesign"],
                 source_environment_key: "staging",
                 target_environment_key: "production"
               },
               approval_requirement: approval_requirement
             })
  end

  test "facade exposes change-request fetch and list reads through the public seam" do
    approval_requirement =
      ApprovalRequirement.new(
        action: :publish_ruleset,
        environment_key: "production",
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: false
      )

    assert {:ok, %{change_request: submitted}} =
             Rulestead.Fake.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: :publish_ruleset,
                   environment_key: "production",
                   resource_type: "flag",
                   resource_key: "checkout-redesign",
                   command: %{"version" => 2, "diff" => %{"title" => "Publish v2"}},
                   approval_requirement: approval_requirement
                 },
                 actor: %{id: "operator-1", display: "Priya"}
               )
             )

    assert {:ok, %{change_request: fetched, approvals: [], audit_events: audit_events}} =
             Rulestead.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

    assert fetched.id == submitted.id
    assert fetched.resource_key == "checkout-redesign"
    assert is_list(audit_events)

    assert {:ok, page} =
             Rulestead.list_change_requests(
               Command.ListChangeRequests.new(
                 environment_key: "production",
                 status: :submitted,
                 resource_key: "checkout-redesign"
               )
             )

    assert Enum.map(page.entries, & &1.id) == [submitted.id]
  end

  test "facade exposes governance authorization entrypoints with typed errors" do
    Application.put_env(:rulestead, :admin_policy, __MODULE__.GovernancePolicy)

    actor = %{id: "prod-operator-1", roles: [:prod_operator], display: "Prod Operator"}
    resource = %{resource_type: :flag, resource_key: "checkout-redesign"}

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
             Rulestead.authorize_governed_action(actor, :publish_ruleset, resource, "production")

    assert error.metadata == %{
             action: "publish_ruleset",
             environment_key: "production",
             reason: "change_request_required"
           }

    assert denied_audit.reason == :change_request_required

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
             Rulestead.authorize_change_request_approval(
               actor,
               actor,
               :publish_ruleset,
               resource,
               "production"
             )

    assert error.metadata == %{
             action: "approve_change_request",
             environment_key: "production",
             reason: "self_approval_forbidden"
           }

    assert denied_audit.reason == :self_approval_forbidden
  end

  test "governance telemetry metadata keeps the canonical correlated fields" do
    metadata =
      %Command.ExecuteChangeRequest{
        change_request_id: "cr-123",
        metadata: %{request_id: "req-123"}
      }
      |> Telemetry.governance_metadata(%{
        event: :merged,
        action: :publish_ruleset,
        environment_key: "production",
        resource_key: "checkout-redesign",
        change_request_id: "cr-123",
        correlation_id: "corr-123",
        audit_event_id: "evt-123"
      })
      |> Telemetry.metadata()

    assert metadata == %{
             operation: "execute_change_request",
             environment: "production",
             audit_action: "publish_ruleset",
             reason: :merged,
             change_request_id: "cr-123",
             correlation_id: "corr-123",
             audit_event_id: "evt-123",
             resource_key: "checkout-redesign"
           }
  end

  defmodule GovernancePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, action, _resource, "production")
        when action in [:publish_ruleset, :promote_environment],
        do: true

    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def allow_self_approval?(_actor, _action, _resource, "production"), do: false

    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end
end
