# credo:disable-for-this-file
defmodule Rulestead.Runtime.Backup do
  @moduledoc false

  alias Rulestead.Runtime.{Backup.FileStore, Cache, Snapshot}

  @type backup_status ::
          :disabled
          | :loaded
          | :persisted
          | :missing
          | :quarantined
          | :restore_failed
          | :persist_failed

  @spec restore(String.t() | atom(), keyword()) :: :ok
  def restore(environment_key, opts \\ []) do
    environment_key = to_string(environment_key)

    case backup_config(opts) do
      %{enabled?: false} ->
        Cache.put_backup_status(environment_key, :disabled)

      %{path: path} ->
        case FileStore.load(path, environment_key) do
          {:ok, %Snapshot{} = snapshot} ->
            case Cache.apply(snapshot, source: :disk) do
              {:ok, %{applied?: true}} ->
                Cache.put_backup_status(environment_key, :loaded)

              {:ok, %{applied?: false}} ->
                Cache.put_backup_status(environment_key, :loaded)
            end

          {:error, :not_found} ->
            Cache.put_backup_status(environment_key, :missing)

          {:error, {:quarantined, _reason}} ->
            Cache.put_backup_status(environment_key, :quarantined)

          {:error, _reason} ->
            Cache.put_backup_status(environment_key, :restore_failed)
        end
    end

    :ok
  end

  @spec persist(Snapshot.t(), keyword()) :: :ok
  def persist(%Snapshot{} = snapshot, opts \\ []) do
    case backup_config(opts) do
      %{enabled?: false} ->
        Cache.put_backup_status(snapshot.environment_key, :disabled)

      %{path: path} ->
        case FileStore.persist(path, snapshot) do
          {:ok, _paths} -> Cache.put_backup_status(snapshot.environment_key, :persisted)
          {:error, _reason} -> Cache.put_backup_status(snapshot.environment_key, :persist_failed)
        end
    end

    :ok
  end

  @spec enabled?(keyword()) :: boolean()
  def enabled?(opts \\ []) do
    backup_config(opts).enabled?
  end

  defp backup_config(opts) do
    snapshot_config = Rulestead.Runtime.Config.snapshot(opts)
    configured = Keyword.get(snapshot_config, :backup, []) |> normalize_keyword()

    enabled? = Keyword.get(configured, :enabled, false)
    path = Keyword.get(configured, :path, default_path())

    %{enabled?: enabled?, path: path}
  end

  defp normalize_keyword(value) when is_list(value), do: value
  defp normalize_keyword(value) when is_map(value), do: Map.to_list(value)
  defp normalize_keyword(_value), do: []

  defp default_path do
    Path.join(System.tmp_dir!(), "rulestead-runtime-backups")
  end
end
