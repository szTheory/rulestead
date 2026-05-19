defmodule Rulestead.Runtime.Snapshot do

  alias Rulestead.EvaluationError

  @enforce_keys [:environment_key, :version, :published_at, :generated_at, :flags]
  defstruct [:environment_key, :version, :published_at, :generated_at, :flags, metadata: %{}, flag_keys: []]

  @type flag_entry :: %{
          required(:flag_key) => String.t(),
          required(:flag_payload) => map()
        }

  @type t :: %__MODULE__{
          environment_key: String.t(),
          version: pos_integer(),
          published_at: DateTime.t(),
          generated_at: DateTime.t() | nil,
          flags: %{required(String.t()) => flag_entry()},
          metadata: map(),
          flag_keys: [String.t()]
        }

  @spec compile(map()) :: {:ok, t()} | {:error, Rulestead.Error.t()}
  def compile(snapshot) when is_map(snapshot) do
    with {:ok, environment_key} <- fetch_string(snapshot, :environment_key),
         {:ok, version} <- fetch_integer(snapshot, :version),
         {:ok, published_at} <- fetch_datetime(snapshot, :published_at),
         {:ok, payload} <- fetch_binary(snapshot, :payload),
         {:ok, decoded_payload} <- decode_payload(payload),
         {:ok, flags, generated_at} <- compile_payload(decoded_payload, environment_key) do
      flag_keys = flags |> Map.keys() |> Enum.sort()

      {:ok,
       %__MODULE__{
         environment_key: environment_key,
         version: version,
         published_at: published_at,
         generated_at: generated_at,
         flags: flags,
         metadata: Map.get(snapshot, :metadata, %{}),
         flag_keys: flag_keys
       }}
    end
  end

  def compile(_snapshot), do: {:error, EvaluationError.malformed_runtime_data()}

  defp decode_payload(payload) do
    try do
      case :erlang.binary_to_term(payload, [:safe]) do
        decoded when is_map(decoded) -> {:ok, decoded}
        _other -> {:error, EvaluationError.malformed_runtime_data()}
      end
    rescue
      ArgumentError -> {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp compile_payload(payload, environment_key) do
    with {:ok, payload_environment_key} <- fetch_string(payload, :environment_key),
         true <- payload_environment_key == environment_key,
         flags when is_map(flags) <- fetch(payload, :flags) do
      compiled_flags =
        flags
        |> Enum.map(fn {flag_key, flag_payload} ->
          normalized_flag_key = normalize_string(flag_key)
          {normalized_flag_key, %{flag_key: normalized_flag_key, flag_payload: flag_payload}}
        end)
        |> Map.new()

      {:ok, compiled_flags, fetch(payload, :generated_at)}
    else
      false -> {:error, EvaluationError.malformed_runtime_data()}
      _other -> {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp fetch_string(map, key) do
    case normalize_string(fetch(map, key)) do
      nil -> {:error, EvaluationError.malformed_runtime_data()}
      value -> {:ok, value}
    end
  end

  defp fetch_integer(map, key) do
    case fetch(map, key) do
      value when is_integer(value) and value > 0 -> {:ok, value}
      _other -> {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp fetch_binary(map, key) do
    case fetch(map, key) do
      value when is_binary(value) -> {:ok, value}
      _other -> {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp fetch_datetime(map, key) do
    case fetch(map, key) do
      %DateTime{} = value -> {:ok, value}
      _other -> {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp fetch(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(_value), do: nil
end
