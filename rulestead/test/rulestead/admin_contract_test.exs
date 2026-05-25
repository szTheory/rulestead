# credo:disable-for-this-file
defmodule Rulestead.AdminContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.Store
  alias Rulestead.Store.Command

  test "admin policy exposes authorization and governance callbacks" do
    assert Enum.sort(Rulestead.Admin.Policy.behaviour_info(:callbacks)) == [
             allow_self_approval?: 4,
             can?: 4,
             change_request_required?: 4
           ]
  end

  test "the root facade exposes the phase 6 admin verbs" do
    exports = Rulestead.module_info(:exports)

    assert {:list_flags, 0} in exports
    assert function_exported?(Rulestead, :list_flags, 1)
    assert function_exported?(Rulestead, :fetch_flag, 1)
    assert function_exported?(Rulestead, :fetch_flag, 3)
    assert function_exported?(Rulestead, :create_flag, 1)
    assert function_exported?(Rulestead, :create_flag, 2)
    assert function_exported?(Rulestead, :update_flag, 1)
    assert function_exported?(Rulestead, :update_flag, 3)
    assert function_exported?(Rulestead, :list_environments, 0)
    assert function_exported?(Rulestead, :list_environments, 1)
    assert function_exported?(Rulestead, :record_evaluation, 1)
    assert function_exported?(Rulestead, :record_evaluation, 3)
  end

  test "the store and typed commands carry phase 6 pagination and lifecycle contracts" do
    callbacks = Store.behaviour_info(:callbacks)

    for cb <- [
          :archive_flag,
          :create_flag,
          :fetch_flag,
          :fetch_snapshot,
          :list_environments,
          :list_flags,
          :publish_ruleset,
          :record_evaluation,
          :save_draft_ruleset,
          :update_flag
        ] do
      assert Keyword.has_key?(callbacks, cb)
      assert callbacks[cb] == 1
    end

    page = %Command.Page{
      entries: [%{flag: %{key: "checkout-redesign"}}],
      limit: 25,
      next_cursor: "cursor:next",
      prev_cursor: nil,
      has_next_page?: true,
      has_previous_page?: false
    }

    assert %Command.ListFlags{
             environment_key: "production",
             owner: "growth",
             tags: ["checkout"],
             lifecycle: :active,
             stale: :stale,
             limit: 25,
             after: "cursor:next",
             before: nil,
             page: ^page
           } =
             Command.ListFlags.new(
               environment_key: "production",
               owner: "growth",
               tags: ["checkout"],
               lifecycle: :active,
               stale: :stale,
               limit: 25,
               after: "cursor:next",
               page: page
             )

    assert %Command.CreateFlag{
             key: "checkout-redesign",
             owner: "growth",
             lifecycle: %{
               mode: :expiring,
               review_by: ~D[2026-05-01],
               default_source: :flag_type,
               default_overridden: false
             },
             permanent: false,
             environment_keys: ["test", "production"]
           } =
             Command.CreateFlag.new(%{
               key: "checkout-redesign",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               owner: "growth",
               lifecycle: %{
                 mode: :expiring,
                 review_by: ~D[2026-05-01],
                 default_source: :flag_type,
                 default_overridden: false
               },
               permanent: false,
               environment_keys: ["test", "production"]
             })

    assert %Command.UpdateFlag{
             flag_key: "checkout-redesign",
             owner: "growth",
             lifecycle: %{
               mode: :permanent,
               review_by: nil,
               default_source: :operator_required,
               default_overridden: false
             }
           } =
             Command.UpdateFlag.new("checkout-redesign", %{
               owner: "growth",
               permanent: true
             })

    assert %Command.ListEnvironments{query: "prod", limit: 10} =
             Command.ListEnvironments.new(query: "prod", limit: 10)

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    assert %Command.RecordEvaluation{
             flag_key: "checkout-redesign",
             environment_key: "production",
             last_evaluated_at: ^now
           } = Command.RecordEvaluation.new("checkout-redesign", "production", now)
  end
end
