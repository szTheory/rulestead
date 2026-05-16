defmodule Rulestead.Oban.StaleFlagWorkerTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Oban.StaleFlagWorker
  alias Rulestead.Telemetry.Cache
  alias Rulestead.FlagEnvironment
  alias Rulestead.Repo

  setup do
    {:ok, _pid} = Cache.start_link([])
    Cache.clear()

    # Create a flag, environment, and flag_environment
    env = insert_environment()
    flag = insert_flag(key: "test_flag")
    fe = insert_flag_environment(flag, env)

    %{env: env, flag: flag, fe: fe}
  end

  test "fetches snapshot from ETS cache, updates database, and clears cache", %{flag: flag, env: env, fe: fe} do
    timestamp = DateTime.utc_now()
    
    # Record evaluation
    Cache.record_evaluation(flag.key, env.key, "on", timestamp)
    Cache.record_evaluation(flag.key, env.key, "on", timestamp)
    Cache.record_evaluation(flag.key, env.key, "off", timestamp)

    # Cache should have values
    assert Cache.snapshot() != %{}

    # Run the worker
    assert {:ok, :flushed} = StaleFlagWorker.perform(%Oban.Job{})

    # Cache should be cleared
    assert Cache.snapshot() == %{}

    # DB should be updated
    updated_fe = Repo.get!(FlagEnvironment, fe.id)
    assert DateTime.compare(updated_fe.last_evaluated_at, timestamp) == :eq
    assert updated_fe.variants_served == %{"on" => 2, "off" => 1}
  end

  # Helpers to insert data (since Rulestead uses a custom store, we can use Store commands or insert directly)
  defp insert_environment do
    %Rulestead.Environment{key: "test_env", name: "Test"}
    |> Repo.insert!()
  end

  defp insert_flag(attrs) do
    %Rulestead.Flag{
      key: attrs[:key],
      flag_type: :release,
      value_type: :boolean,
      default_value: %{"value" => false},
      permanent: true,
      owner: "tester"
    }
    |> Repo.insert!()
  end

  defp insert_flag_environment(flag, env) do
    %Rulestead.FlagEnvironment{
      flag_id: flag.id,
      environment_id: env.id,
      status: :active
    }
    |> Repo.insert!()
  end
end
