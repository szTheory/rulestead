defmodule Rulestead.Store.FakeContractTest do
  use Rulestead.StoreContractCase,
    store: Rulestead.Fake,
    control: Rulestead.Fake.Control

  alias Rulestead.Store.Command

  setup do
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    on_exit(fn ->
      Application.delete_env(:rulestead, :admin_lifecycle)
    end)

    :ok
  end

  store_contract_tests()

  test "fake adapter mirrors archive readiness payloads and advisory filters" do
    @store_control.put_flag!(
      valid_flag_attrs(%{
        key: "ops-cleanup",
        ownership: %{owner_ref: "ops", owner_kind: :team},
      lifecycle: %{mode: :expiring, default_source: :flag_type, default_overridden: false},
        expected_expiration: ~D[2026-04-20],
        code_reference_count: 0,
        code_refs_scan: %{received_at: ~U[2026-04-23 15:50:00Z], reference_count: 0}
      })
    )

    @store_control.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        ownership: %{owner_ref: "growth", owner_kind: :team},
      lifecycle: %{mode: :permanent, default_source: :flag_type, default_overridden: false},
        code_reference_count: 2,
        code_refs_scan: %{received_at: ~U[2026-04-23 15:50:00Z], reference_count: 2}
      })
    )

    assert {:ok, _} =
             @store_module.record_evaluation(
               Command.RecordEvaluation.new(
                 "ops-cleanup",
                 "test",
                 ~U[2026-04-23 14:00:00Z]
               )
             )

    assert {:ok, _} =
             @store_module.record_evaluation(
               Command.RecordEvaluation.new(
                 "checkout-redesign",
                 "test",
                 ~U[2026-04-23 15:55:00Z]
               )
             )

    assert {:ok, %Command.Page{entries: [entry]}} =
             @store_module.list_flags(
               Command.ListFlags.new(
                 environment_key: "test",
                 readiness: :archive_candidate,
                 evidence_quality: :strong
               )
             )

    assert entry.flag.key == "ops-cleanup"
    assert entry.lifecycle.archive_readiness.readiness == :archive_candidate
    assert entry.lifecycle.freshness.code_references == :fresh_refs_absent

    assert {:ok, detail} = @store_module.fetch_flag(fetch_flag_command("checkout-redesign", "test"))
    assert detail.lifecycle.archive_readiness.readiness == :keep_active
    assert detail.lifecycle.freshness.code_references == :refs_present
  end
end
