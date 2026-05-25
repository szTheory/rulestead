defmodule Rulestead.Runtime.BackupTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Backup, Backup.FileStore, Cache, Snapshot, Supervisor}

  setup do
    Control.reset!()

    runtime_config = Application.get_env(:rulestead, :runtime, [])
    store_config = Application.get_env(:rulestead, :store)
    snapshot_config = Application.get_env(:rulestead, :snapshot, [])

    backup_root =
      System.tmp_dir!()
      |> Path.join("rulestead-backup-test-#{System.unique_integer([:positive])}")

    File.rm_rf!(backup_root)
    File.mkdir_p!(backup_root)

    on_exit(fn ->
      Application.put_env(:rulestead, :runtime, runtime_config)

      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end

      Application.put_env(:rulestead, :snapshot, snapshot_config)
      File.rm_rf!(backup_root)
    end)

    %{backup_root: backup_root}
  end

  test "enabled backup restores the last-known-good snapshot before the first refresh", %{
    backup_root: backup_root
  } do
    environment_key = unique_environment_key("backup-restore")
    seed_snapshot(environment_key, true)

    supervisor = start_runtime(environment_key, backup_root, Rulestead.Fake)
    assert Process.alive?(supervisor)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    shutdown_supervisor(supervisor)
    Cache.reset(environment_key)
    Control.disconnect!()

    restored_supervisor = start_runtime(environment_key, backup_root, Rulestead.Fake)
    assert Process.alive?(restored_supervisor)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())
  end

  test "corrupt backups are quarantined and skipped without crashing startup", %{
    backup_root: backup_root
  } do
    environment_key = unique_environment_key("backup-corrupt")
    File.mkdir_p!(Path.join(backup_root, environment_key))
    File.write!(Path.join([backup_root, environment_key, "snapshot.current"]), "corrupt-backup")

    supervisor = start_runtime(environment_key, backup_root, Rulestead.MissingStore)
    assert Process.alive?(supervisor)
    assert {:ok, false} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    quarantine_dir = Path.join([backup_root, environment_key, "quarantine"])
    assert [quarantined_file] = File.ls!(quarantine_dir)
    assert String.contains?(quarantined_file, "snapshot.current")
  end

  test "backup disabled leaves startup as a no-op for disk restore", %{backup_root: backup_root} do
    environment_key = unique_environment_key("backup-disabled")
    seed_snapshot(environment_key, true)

    supervisor = start_runtime(environment_key, backup_root, Rulestead.Fake)
    assert Process.alive?(supervisor)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    shutdown_supervisor(supervisor)
    Cache.reset(environment_key)
    Cache.register_environment(environment_key)

    assert :ok =
             Backup.restore(environment_key,
               snapshot: [backup: [enabled: false, path: backup_root]]
             )

    assert {:ok, environment} = Cache.environment(environment_key)
    assert environment.source == :none
    assert environment.disk_backup_status == :disabled
    assert {:ok, false} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())
  end

  test "persist rotates the previous generation while keeping the latest snapshot current", %{
    backup_root: backup_root
  } do
    environment_key = unique_environment_key("backup-rotate")
    first_snapshot = compiled_snapshot(environment_key, 1, true)
    second_snapshot = compiled_snapshot(environment_key, 2, false)

    assert {:ok, _paths} = FileStore.persist(backup_root, first_snapshot)
    assert {:ok, _paths} = FileStore.persist(backup_root, second_snapshot)

    current_path = FileStore.current_path(backup_root, environment_key)
    previous_path = Path.join([backup_root, environment_key, "snapshot.previous"])

    assert File.exists?(current_path)
    assert File.exists?(previous_path)
    assert {:ok, %Snapshot{version: 2}} = FileStore.load(backup_root, environment_key)

    assert {:ok, previous_binary} = File.read(previous_path)
    assert {:ok, %Snapshot{version: 1}} = decode_snapshot(previous_binary, environment_key)
  end

  defp start_runtime(environment_key, backup_root, store, opts \\ []) do
    Application.put_env(
      :rulestead,
      :snapshot,
      backup: [enabled: Keyword.get(opts, :backup_enabled?, true), path: backup_root]
    )

    Application.put_env(:rulestead, :store, store)

    start_supervised!(%{
      id: {:runtime_supervisor, environment_key, System.unique_integer([:positive])},
      start:
        {Supervisor, :start_link,
         [[name: nil, environment_keys: [environment_key], store: store]]},
      type: :supervisor
    })
  end

  defp seed_snapshot(environment_key, forced_value) do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Control.put_environment!(%{key: environment_key, name: "Backup #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "ops", owner_kind: :team},
      lifecycle: %{
        mode: :expiring,
        review_by: Date.utc_today(),
        default_source: :flag_type,
        default_overridden: false
      },
      environment_keys: [environment_key]
    })

    {:ok, _draft} =
      Rulestead.save_draft_ruleset(
        Rulestead.Store.Command.SaveDraftRuleset.new("checkout-redesign", environment_key, %{
          salt: "checkout:#{System.unique_integer([:positive])}",
          rules: [
            %{
              key: "beta-rollout",
              strategy: :forced_value,
              value: %{value: forced_value},
              conditions: [
                %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
              ]
            }
          ]
        })
      )

    {:ok, _published} =
      Rulestead.publish_ruleset(
        Rulestead.Store.Command.PublishRuleset.new("checkout-redesign", environment_key)
      )
  end

  defp actor_context, do: Context.new(actor: %{key: "user-1"})

  defp compiled_snapshot(environment_key, version, forced_value) do
    now = DateTime.utc_now()

    %Snapshot{
      environment_key: environment_key,
      version: version,
      published_at: now,
      generated_at: now,
      flags: %{
        "checkout-redesign" => %{
          flag_key: "checkout-redesign",
          flag_payload: %{
            key: "checkout-redesign",
            flag_type: :release,
            value_type: :boolean,
            enabled: true,
            default_value: false,
            rules: [
              %{
                key: "beta-rollout",
                conditions: [
                  %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
                ],
                strategy: :forced_value,
                value: forced_value
              }
            ]
          }
        }
      },
      metadata: %{},
      flag_keys: ["checkout-redesign"]
    }
  end

  defp decode_snapshot(binary, environment_key) do
    root =
      System.tmp_dir!()
      |> Path.join("rulestead-backup-decode-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(root, environment_key))
    File.write!(Path.join([root, environment_key, "snapshot.current"]), binary)

    result =
      case FileStore.load(root, environment_key) do
        {:ok, snapshot} -> {:ok, snapshot}
        {:error, reason} -> {:error, reason}
      end

    File.rm_rf!(root)
    result
  end

  defp shutdown_supervisor(supervisor) do
    :ok = Elixir.Supervisor.stop(supervisor, :shutdown, 1_000)
  end

  defp unique_environment_key(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end
end
