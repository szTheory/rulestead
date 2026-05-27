# credo:disable-for-this-file
defmodule Rulestead.Store.AudienceImpactContractTest do
  use ExUnit.Case, async: false

  alias Rulestead.Error
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.ImpactPreview

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_pid = Application.get_env(:rulestead, :policy_test_pid)

    Application.put_env(:rulestead, :store, __MODULE__.CaptureStore)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.CapturePolicy)
    Application.put_env(:rulestead, :policy_test_pid, self())

    on_exit(fn ->
      restore_env(:store, previous_store)
      restore_env(:admin_policy, previous_policy)
      restore_env(:policy_test_pid, previous_pid)
    end)

    :ok
  end

  test "preview_audience_impact builds a command and routes through admin read authorization" do
    actor = %{id: "reader-1", roles: [:viewer]}

    assert {:ok, %{command: %Command.PreviewAudienceImpact{} = command}} =
             Rulestead.preview_audience_impact("vip-users", :update,
               environment_key: "production",
               tenant_key: "tenant-a",
               after_definition: %{rules: [%{attribute: "plan", operator: "eq", value: "pro"}]},
               actor: actor,
               reason: "check references",
               metadata: %{request_id: "req-preview"}
             )

    assert command.audience_key == "vip-users"
    assert command.operation == "update"
    assert command.environment_key == "production"
    assert command.tenant_key == "tenant-a"

    assert_received {:authorized, :preview_audience_impact,
                     %{resource_type: :audience, resource_key: "vip-users"}, "production",
                     authorized_actor}

    assert authorized_actor.id == "reader-1"
    assert authorized_actor.roles == [:viewer]

    assert_received {:store_preview, ^command}
  end

  test "apply_audience_mutation rejects missing fingerprint before store mutation" do
    assert {:error, %Error{domain: :store, type: :invalid_command} = error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: ImpactPreview.schema_version(),
               preview_fingerprint: "",
               reason: "ship update",
               actor: %{id: "editor-1", roles: [:admin]},
               after_definition: %{rules: []}
             })

    assert error.message =~ "preview_fingerprint"
    refute_received {:store_apply, _command}
  end

  test "apply_audience_mutation routes confirmed mutations through admin write authorization" do
    actor = %{id: "editor-1", roles: [:admin]}

    attrs = %{
      environment_key: "production",
      tenant_key: "tenant-a",
      audience_key: "vip-users",
      operation: :archive,
      preview_schema_version: ImpactPreview.schema_version(),
      preview_fingerprint: "audprev_fresh",
      preview_basis: %{basis: "authored_state"},
      affected_reference_keys: ["flag:checkout"],
      reason: "retire stale audience",
      actor: actor,
      metadata: %{request_id: "req-apply"}
    }

    assert {:ok, %{command: %Command.ApplyAudienceMutation{} = command}} =
             Rulestead.apply_audience_mutation(attrs)

    assert command.operation == "archive"
    assert command.preview_fingerprint == "audprev_fresh"

    assert_received {:authorized, :apply_audience_mutation,
                     %{resource_type: :audience, resource_key: "vip-users"}, "production",
                     authorized_actor}

    assert authorized_actor.id == "editor-1"
    assert authorized_actor.roles == [:admin]

    assert_received {:store_apply, ^command}
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)

  defmodule CapturePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(actor, action, resource, environment_key) do
      send(Application.fetch_env!(:rulestead, :policy_test_pid), {
        :authorized,
        action,
        resource,
        environment_key,
        actor
      })

      true
    end
  end

  defmodule CaptureStore do
    def preview_audience_impact(%Command.PreviewAudienceImpact{} = command) do
      send(Application.fetch_env!(:rulestead, :policy_test_pid), {:store_preview, command})
      {:ok, %{command: command}}
    end

    def apply_audience_mutation(%Command.ApplyAudienceMutation{} = command) do
      send(Application.fetch_env!(:rulestead, :policy_test_pid), {:store_apply, command})
      {:ok, %{command: command}}
    end
  end
end
