defmodule Rulestead.StoreContractCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Rulestead.Error

  using opts do
    quote bind_quoted: [opts: opts] do
      use ExUnit.Case, async: false

      alias Rulestead.{RulesetError, StoreError}

      import Rulestead.StoreContractCase
      import Rulestead.StoreFixtures

      @store_module Keyword.fetch!(opts, :store)
      @store_control Keyword.fetch!(opts, :control)

      setup do
        previous_store = Application.get_env(:rulestead, :store)
        @store_control.ensure_started()
        @store_control.reset!()
        Application.put_env(:rulestead, :store, @store_module)

        on_exit(fn ->
          @store_control.reset!()

          case previous_store do
            nil -> Application.delete_env(:rulestead, :store)
            value -> Application.put_env(:rulestead, :store, value)
          end
        end)

        :ok
      end
    end
  end

  defmacro store_contract_tests do
    quote do
      test "round-trips authored state through draft save, publish, and fetch" do
        @store_control.put_flag!(valid_flag_attrs())

        assert {:ok, %{version: 1, ruleset: %{status: :draft}}} =
                 @store_module.save_draft_ruleset(save_draft_command())

        assert {:ok, %{active_ruleset: %{version: 1, status: :published}}} =
                 @store_module.publish_ruleset(publish_ruleset_command())

        assert {:ok, payload} = @store_module.fetch_flag(fetch_flag_command())
        assert payload.flag.key == "checkout-redesign"
        assert payload.environment.key == "test"
        assert payload.flag_environment.status == :active
        assert payload.active_ruleset.version == 1
        assert payload.active_ruleset.status == :published

        assert payload.active_ruleset.rules |> List.first() |> Map.fetch!(:strategy) ==
                 :forced_value

        assert payload.draft_rulesets == []

        assert {:ok, public_payload} = Rulestead.fetch_flag("checkout-redesign", "test")
        assert public_payload.active_ruleset.version == 1
      end

      test "rejects invalid rulesets using the shared schema semantics" do
        @store_control.put_flag!(valid_flag_attrs())

        assert {:error, %Error{domain: :ruleset, type: :invalid_ruleset} = error} =
                 @store_module.save_draft_ruleset(
                   save_draft_command("checkout-redesign", "test", invalid_ruleset_attrs())
                 )

        assert Enum.any?(
                 error.details,
                 &(&1[:message] == "must be present for forced_value rules")
               )
      end

      test "returns a typed variant-weight error when rule weights do not sum to 100" do
        @store_control.put_flag!(valid_flag_attrs())

        assert {:error, %Error{domain: :ruleset, type: :variant_weights_invalid} = error} =
                 @store_module.save_draft_ruleset(
                   save_draft_command(
                     "checkout-redesign",
                     "test",
                     invalid_variant_weight_ruleset_attrs()
                   )
                 )

        assert Enum.any?(error.details, &(&1[:message] == "weights must sum to 100"))
      end

      test "normalizes not-found behavior for environments, flags, and rulesets" do
        @store_control.put_flag!(valid_flag_attrs())

        assert {:error, %Error{domain: :store, type: :environment_not_found}} =
                 @store_module.fetch_flag(fetch_flag_command("checkout-redesign", "missing"))

        assert {:error, %Error{domain: :store, type: :flag_not_found}} =
                 @store_module.fetch_flag(fetch_flag_command("missing", "test"))

        assert {:error, %Error{domain: :ruleset, type: :ruleset_not_found}} =
                 @store_module.publish_ruleset(
                   publish_ruleset_command("checkout-redesign", "test")
                 )
      end

      test "enforces publish version boundaries instead of republishing an active ruleset" do
        @store_control.put_flag!(valid_flag_attrs())

        assert {:ok, %{version: 1}} = @store_module.save_draft_ruleset(save_draft_command())

        assert {:ok, %{active_ruleset: %{version: 1}}} =
                 @store_module.publish_ruleset(publish_ruleset_command())

        assert {:error, %Error{domain: :store, type: :invalid_command} = error} =
                 @store_module.publish_ruleset(
                   publish_ruleset_command("checkout-redesign", "test", version: 1)
                 )

        assert error.metadata.requested_version == 1
        assert error.metadata.active_version == 1
      end

      test "treats archived flags as read-only while keeping them discoverable when requested" do
        @store_control.put_flag!(valid_flag_attrs())
        assert {:ok, %{archived?: true}} = @store_module.archive_flag(archive_flag_command())

        assert {:error, %Error{domain: :store, type: :flag_archived}} =
                 @store_module.save_draft_ruleset(save_draft_command())

        assert {:ok, []} = @store_module.list_flags(list_flags_command())

        assert {:ok, [archived_entry]} =
                 @store_module.list_flags(list_flags_command(include_archived?: true))

        assert archived_entry.flag.archived_at
        assert archived_entry.flag_environment.status == :archived
      end

      test "rejects duplicate flag keys through the control surface used for shared adapter setup" do
        assert {:ok, _flag} = @store_control.put_flag(valid_flag_attrs())

        assert {:error, %Error{domain: :store, type: :invalid_command} = error} =
                 @store_control.put_flag(valid_flag_attrs())

        assert error.metadata.flag_key == "checkout-redesign"
      end

      test "lists only matching flag rows for an environment filter and query" do
        @store_control.put_flag!(valid_flag_attrs())

        @store_control.put_flag!(
          valid_flag_attrs(%{key: "pricing-page", environment_keys: ["staging"]})
        )

        assert {:ok, [entry]} =
                 @store_module.list_flags(
                   list_flags_command(environment_key: "staging", query: "pricing")
                 )

        assert entry.flag.key == "pricing-page"
        assert entry.environment.key == "staging"
      end
    end
  end
end
