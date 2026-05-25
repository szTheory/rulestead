defmodule Rulestead.Runtime.Notifier do
  @moduledoc false

  @type notice :: %{
          required(:environment_key) => String.t(),
          required(:snapshot_version) => pos_integer()
        }

  @callback broadcast(notice(), keyword()) :: :ok | {:error, term()}
  @callback subscribe(keyword()) :: :ok | {:error, term()}

  @spec broadcast(module() | nil, map(), keyword()) :: :ok | {:error, term()}
  def broadcast(nil, _notice, _opts), do: :ok

  def broadcast(notifier, notice, opts) when is_atom(notifier) and is_map(notice) do
    notifier.broadcast(normalize_notice!(notice), opts)
  end

  @spec subscribe(module() | nil, keyword()) :: :ok | {:error, term()}
  def subscribe(nil, _opts), do: :ok

  def subscribe(notifier, opts) when is_atom(notifier) do
    notifier.subscribe(opts)
  end

  @spec normalize_notice!(map()) :: notice()
  def normalize_notice!(notice) when is_map(notice) do
    environment_key = notice[:environment_key] || notice["environment_key"]
    snapshot_version = notice[:snapshot_version] || notice["snapshot_version"]

    %{
      environment_key: to_string(environment_key),
      snapshot_version: normalize_version!(snapshot_version)
    }
  end

  defp normalize_version!(snapshot_version)
       when is_integer(snapshot_version) and snapshot_version > 0,
       do: snapshot_version

  defp normalize_version!(snapshot_version) when is_binary(snapshot_version) do
    case Integer.parse(snapshot_version) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> raise ArgumentError, "snapshot_version must be a positive integer"
    end
  end

  defp normalize_version!(_snapshot_version) do
    raise ArgumentError, "snapshot_version must be a positive integer"
  end
end
