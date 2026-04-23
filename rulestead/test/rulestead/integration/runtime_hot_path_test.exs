defmodule Rulestead.Integration.RuntimeHotPathTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.{Context, Environment, Flag, FlagEnvironment, Repo, Runtime}
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Store.Command

  @moduletag :telemetry

  setup do
    Repo.delete_all(Rulestead.AuditEvent)
    Repo.delete_all(Rulestead.RuntimeSnapshot)
    Repo.delete_all(Rulestead.Ruleset)
    Repo.delete_all(FlagEnvironment)
    Repo.delete_all(Flag)
    Repo.delete_all(Environment)

    environment =
      %Environment{}
      |> Environment.changeset(%{key: "test", name: "Test", description: "Telemetry integration"})
      |> Repo.insert!()

    flag =
      %Flag{}
      |> Flag.changeset(%{
        key: "checkout-redesign",
        description: "Hot path proof",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: "ops",
        expected_expiration: Date.utc_today()
      })
      |> Repo.insert!()

    %FlagEnvironment{}
    |> FlagEnvironment.changeset(%{flag_id: flag.id, environment_id: environment.id, status: :draft})
    |> Repo.insert!()

    store_config = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, Rulestead.Store.Ecto)

    on_exit(fn ->
      Cache.reset("test")

      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end
    end)

    :ok
  end

  test "warm-cache keyed runtime evaluation performs zero repo queries" do
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "test", %{
                 salt: "checkout-hot-path",
                 rules: [
                   %{
                     key: "beta-rollout",
                     strategy: :forced_value,
                     value: %{value: true},
                     conditions: [
                       %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
                     ]
                   }
                 ]
               })
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "test"))

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: "test",
         store: Rulestead.Store.Ecto,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)
    assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    handler_id = "repo-query-count-#{System.unique_integer([:positive])}"
    parent = self()

    :telemetry.attach(
      handler_id,
      [:rulestead, :repo, :query],
      fn _event, _measurements, metadata, test_pid ->
        send(test_pid, {:repo_query, metadata.query})
      end,
      parent
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
    refute_receive {:repo_query, _query}, 200
  end
end
