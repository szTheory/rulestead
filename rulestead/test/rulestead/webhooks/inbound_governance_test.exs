# credo:disable-for-this-file
defmodule Rulestead.Webhooks.InboundGovernanceTest do
  use Rulestead.RepoCase, async: false

  setup do
    Rulestead.Fake.reset()
    :ok
  end

  alias Rulestead.Webhooks.InboundEvent
  alias Rulestead.Store.Command

  test "verified inbound event requiring approvals becomes a local change request" do
    # 1. Setup a flag
    {:ok, flag} =
      Rulestead.create_flag(
        %{
          key: "webhook-feature",
          flag_type: :release,
          value_type: :boolean,
          default_value: %{value: false},
          ownership: %{owner_ref: "admin", owner_kind: :team},
          lifecycle: %{mode: :permanent, default_source: :flag_type, default_overridden: false},
          environment_keys: ["production"]
        },
        actor: %{id: "admin", roles: [:admin]}
      )

    # 2. Setup a verified inbound event for a change request
    now = DateTime.utc_now()

    event =
      InboundEvent.new(%{
        provider: "github",
        endpoint_key: "default",
        delivery_id: "del_123",
        received_at: now,
        payload: %{
          "action" => "submit_change_request",
          "flag_key" => flag.flag.key,
          "environment_key" => "production",
          "command_operation" => "publish_ruleset",
          "command_attrs" => %{"version" => 1},
          "reason" => "Inbound from GitHub"
        },
        metadata: %{"user" => "github_user"},
        correlation_id: "corr_123"
      })

    receipt = %{id: Ecto.UUID.generate()}

    # 3. Execute through facade
    # Since production usually requires change requests for publish, this should result in a CR
    {:ok, result} = Rulestead.execute_inbound_event(event, receipt)

    assert result.change_request.resource_key == "webhook-feature"
    assert result.change_request.state in [:submitted, "submitted"]
    submitted_by = result.change_request.submitted_by
    assert (submitted_by["id"] || submitted_by[:id]) == "system:webhook:default"
    assert result.change_request.metadata["webhook_delivery_id"] == "del_123"
  end

  test "verified inbound event allowed directly executes immediately" do
    # 1. Setup a flag
    seed_environment!("development")

    {:ok, flag} =
      Rulestead.create_flag(
        %{
          key: "direct-feature",
          flag_type: :release,
          value_type: :boolean,
          default_value: %{value: false},
          ownership: %{owner_ref: "admin", owner_kind: :team},
          lifecycle: %{mode: :permanent, default_source: :flag_type, default_overridden: false},
          environment_keys: ["development"]
        },
        actor: %{id: "admin", roles: [:admin]}
      )

    {:ok, _} =
      Rulestead.save_draft_ruleset(
        Command.SaveDraftRuleset.new(flag.flag.key, "development", %{rules: []},
          actor: %{id: "admin", roles: [:admin]}
        )
      )

    # 2. Setup a verified inbound event for a direct kill-switch action
    now = DateTime.utc_now()

    event =
      InboundEvent.new(%{
        provider: "github",
        endpoint_key: "dev-webhook",
        delivery_id: "del_456",
        received_at: now,
        payload: %{
          "action" => "engage_kill_switch",
          "flag_key" => flag.flag.key,
          "environment_key" => "development",
          "reason" => "Inbound from GitHub"
        },
        metadata: %{},
        correlation_id: "corr_456"
      })

    receipt = %{id: Ecto.UUID.generate()}

    # 3. Execute through facade
    {:ok, result} = Rulestead.execute_inbound_event(event, receipt)

    # In development, it should execute the bounded direct action immediately
    assert result.flag_environment.status == :killswitched
    assert result.flag_environment.environment_key == "development"
  end

  defp seed_environment!(key) do
    attrs = %{
      key: key,
      name: String.upcase(key)
    }

    changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)

    case Rulestead.Repo.insert(changeset) do
      {:ok, _env} -> :ok
      {:error, %Ecto.Changeset{errors: [key: {"has already been taken", _}]}} -> :ok
    end
  end
end
