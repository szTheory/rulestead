defmodule Rulestead.Runtime.Backup.FileStore do
  @moduledoc false

  alias Rulestead.Runtime.Snapshot

  @magic "RSTBKP"
  @format_version 1
  @current_file "snapshot.current"
  @previous_file "snapshot.previous"

  @type load_result ::
          {:ok, Snapshot.t()}
          | {:error, :not_found}
          | {:error, {:quarantined, atom()}}
          | {:error, atom()}

  @spec load(String.t(), String.t()) :: load_result()
  def load(root_path, environment_key) do
    environment_dir = environment_dir(root_path, environment_key)
    current_path = current_path(root_path, environment_key)

    case File.read(current_path) do
      {:ok, contents} ->
        case decode_snapshot(contents, environment_key) do
          {:ok, %Snapshot{} = snapshot} ->
            {:ok, snapshot}

          {:error, reason} ->
            quarantine(current_path, environment_dir, reason)
            {:error, {:quarantined, reason}}
        end

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, normalize_file_error(reason)}
    end
  end

  @spec persist(String.t(), Snapshot.t()) ::
          {:ok, %{current_path: String.t(), previous_path: String.t()}}
          | {:error, atom()}
  def persist(root_path, %Snapshot{} = snapshot) do
    environment_dir = environment_dir(root_path, snapshot.environment_key)
    current_path = current_path(root_path, snapshot.environment_key)
    previous_path = previous_path(root_path, snapshot.environment_key)
    temp_path = Path.join(environment_dir, "snapshot.tmp-#{System.unique_integer([:positive])}")

    with :ok <- File.mkdir_p(environment_dir),
         :ok <- File.write(temp_path, encode_snapshot(snapshot), [:binary]),
         :ok <- sync_file(temp_path),
         :ok <- rotate_previous(current_path, previous_path),
         :ok <- File.rename(temp_path, current_path),
         :ok <- sync_directory(environment_dir) do
      {:ok, %{current_path: current_path, previous_path: previous_path}}
    else
      {:error, reason} ->
        File.rm(temp_path)
        {:error, normalize_file_error(reason)}
    end
  end

  @spec current_path(String.t(), String.t() | atom()) :: String.t()
  def current_path(root_path, environment_key) do
    Path.join([environment_dir(root_path, environment_key), @current_file])
  end

  defp previous_path(root_path, environment_key) do
    Path.join([environment_dir(root_path, environment_key), @previous_file])
  end

  defp environment_dir(root_path, environment_key) do
    Path.join(root_path, to_string(environment_key))
  end

  defp encode_snapshot(%Snapshot{} = snapshot) do
    payload =
      :erlang.term_to_binary(%{
        environment_key: snapshot.environment_key,
        version: snapshot.version,
        published_at: snapshot.published_at,
        generated_at: snapshot.generated_at,
        metadata: snapshot.metadata,
        flags:
          Map.new(snapshot.flags, fn {flag_key, %{flag_payload: flag_payload}} ->
            {flag_key, flag_payload}
          end)
      })

    checksum = :crypto.hash(:sha256, payload)

    IO.iodata_to_binary([@magic, <<@format_version::unsigned-32>>, <<byte_size(payload)::unsigned-32>>, payload, checksum])
  end

  defp decode_snapshot(
         <<@magic, format_version::unsigned-32, payload_size::unsigned-32,
           payload::binary-size(payload_size), checksum::binary-size(32)>>,
         environment_key
       ) do
    with :ok <- validate_format(format_version),
         :ok <- validate_checksum(payload, checksum),
         {:ok, decoded_payload} <- safe_decode(payload),
         {:ok, snapshot} <- inflate_snapshot(decoded_payload),
         :ok <- validate_environment(snapshot.environment_key, environment_key) do
      {:ok, snapshot}
    end
  end

  defp decode_snapshot(_contents, _environment_key), do: {:error, :invalid_envelope}

  defp validate_format(@format_version), do: :ok
  defp validate_format(_other), do: {:error, :unsupported_format}

  defp validate_checksum(payload, checksum) do
    if checksum == :crypto.hash(:sha256, payload), do: :ok, else: {:error, :checksum_mismatch}
  end

  defp safe_decode(payload) do
    try do
      case :erlang.binary_to_term(payload, [:safe]) do
        decoded when is_map(decoded) -> {:ok, decoded}
        _other -> {:error, :invalid_payload}
      end
    rescue
      ArgumentError -> {:error, :invalid_payload}
    end
  end

  defp validate_environment(snapshot_environment_key, expected_environment_key) do
    if snapshot_environment_key == to_string(expected_environment_key) do
      :ok
    else
      {:error, :environment_mismatch}
    end
  end

  defp inflate_snapshot(payload) when is_map(payload) do
    with {:ok, environment_key} <- fetch_string(payload, :environment_key),
         {:ok, version} <- fetch_integer(payload, :version),
         {:ok, published_at} <- fetch_datetime(payload, :published_at),
         {:ok, flags} <- inflate_flags(Map.get(payload, :flags) || Map.get(payload, "flags")),
         {:ok, generated_at} <- fetch_optional_datetime(payload, :generated_at),
         {:ok, metadata} <- fetch_map(payload, :metadata) do
      {:ok,
       %Snapshot{
         environment_key: environment_key,
         version: version,
         published_at: published_at,
         generated_at: generated_at,
         flags: flags,
         metadata: metadata,
         flag_keys: Map.keys(flags) |> Enum.sort()
       }}
    else
      _other -> {:error, :invalid_payload}
    end
  end

  defp inflate_snapshot(_payload), do: {:error, :invalid_payload}

  defp inflate_flags(flags) when is_map(flags) do
    {:ok,
     Map.new(flags, fn {flag_key, flag_payload} ->
       normalized_flag_key = to_string(flag_key)
       {normalized_flag_key, %{flag_key: normalized_flag_key, flag_payload: flag_payload}}
     end)}
  end

  defp inflate_flags(_flags), do: {:error, :invalid_payload}

  defp rotate_previous(current_path, previous_path) do
    File.rm(previous_path)

    case File.rename(current_path, previous_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp quarantine(source_path, environment_dir, reason) do
    quarantine_dir = Path.join(environment_dir, "quarantine")
    File.mkdir_p(quarantine_dir)

    quarantine_path =
      Path.join(
        quarantine_dir,
        "#{Path.basename(source_path)}.#{reason}.#{System.unique_integer([:positive])}"
      )

    case File.rename(source_path, quarantine_path) do
      :ok -> :ok
      {:error, _reason} -> File.cp(source_path, quarantine_path)
    end
  end

  defp sync_file(path) do
    case :file.open(String.to_charlist(path), [:read, :binary]) do
      {:ok, device} ->
        result =
          case :file.datasync(device) do
            :ok -> :ok
            {:error, :enotsup} -> :file.sync(device)
            other -> other
          end

        :file.close(device)
        normalize_sync_result(result)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp sync_directory(path) do
    case :file.open(String.to_charlist(path), [:read]) do
      {:ok, device} ->
        result =
          case :file.sync(device) do
            :ok -> :ok
            {:error, :einval} -> :ok
            other -> other
          end

        :file.close(device)
        normalize_sync_result(result)

      {:error, :eisdir} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_sync_result(:ok), do: :ok
  defp normalize_sync_result({:error, reason}), do: {:error, reason}

  defp fetch_string(map, key) do
    case Map.get(map, key) || Map.get(map, Atom.to_string(key)) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      value when is_atom(value) -> {:ok, Atom.to_string(value)}
      _other -> {:error, :invalid_payload}
    end
  end

  defp fetch_integer(map, key) do
    case Map.get(map, key) || Map.get(map, Atom.to_string(key)) do
      value when is_integer(value) and value > 0 -> {:ok, value}
      _other -> {:error, :invalid_payload}
    end
  end

  defp fetch_datetime(map, key) do
    case Map.get(map, key) || Map.get(map, Atom.to_string(key)) do
      %DateTime{} = value -> {:ok, value}
      _other -> {:error, :invalid_payload}
    end
  end

  defp fetch_optional_datetime(map, key) do
    case Map.get(map, key) || Map.get(map, Atom.to_string(key)) do
      nil -> {:ok, nil}
      %DateTime{} = value -> {:ok, value}
      _other -> {:error, :invalid_payload}
    end
  end

  defp fetch_map(map, key) do
    case Map.get(map, key) || Map.get(map, Atom.to_string(key)) do
      nil -> {:ok, %{}}
      value when is_map(value) -> {:ok, value}
      _other -> {:error, :invalid_payload}
    end
  end

  defp normalize_file_error(reason) when reason in [:enoent, :enotdir], do: :not_found
  defp normalize_file_error(reason) when is_atom(reason), do: reason
  defp normalize_file_error(_reason), do: :backup_io_failed
end
