# credo:disable-for-this-file
defmodule Rulestead.Install.FileInjector do
  @moduledoc false

  alias Rulestead.ConfigError

  @spec inject_after(Path.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, Rulestead.Error.t()}
  def inject_after(path, anchor, snippet, label) do
    mutate(path, label, fn contents ->
      cond do
        String.contains?(contents, snippet) ->
          {:skip, contents}

        true ->
          case String.split(contents, anchor, parts: 2) do
            [prefix, suffix] ->
              {:write, prefix <> anchor <> snippet <> suffix}

            [_only] ->
              {:error, conflict(path, label, anchor)}
          end
      end
    end)
  end

  @spec inject_before_last(Path.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, Rulestead.Error.t()}
  def inject_before_last(path, anchor, snippet, label) do
    mutate(path, label, fn contents ->
      cond do
        String.contains?(contents, snippet) ->
          {:skip, contents}

        true ->
          case :binary.matches(contents, anchor) do
            [] ->
              {:error, conflict(path, label, anchor)}

            matches ->
              {index, _length} = List.last(matches)
              prefix = binary_part(contents, 0, index)
              suffix = binary_part(contents, index, byte_size(contents) - index)
              {:write, prefix <> snippet <> suffix}
          end
      end
    end)
  end

  defp mutate(path, label, fun) do
    with {:ok, contents} <- File.read(path) do
      case fun.(contents) do
        {:skip, _contents} ->
          {:ok, "skip #{Path.relative_to_cwd(path)} #{label} already present"}

        {:write, updated} ->
          File.write!(path, updated)
          {:ok, "write #{Path.relative_to_cwd(path)} #{label}"}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, :enoent} ->
        {:error,
         ConfigError.new(
           :invalid_command,
           "unable to inject #{label}; #{Path.relative_to_cwd(path)} does not exist",
           metadata: %{path: Path.relative_to_cwd(path)}
         )}

      {:error, reason} ->
        {:error,
         ConfigError.new(
           :invalid_command,
           "unable to read #{Path.relative_to_cwd(path)} for #{label}: #{inspect(reason)}",
           metadata: %{path: Path.relative_to_cwd(path)}
         )}
    end
  end

  defp conflict(path, label, anchor) do
    ConfigError.new(
      :invalid_command,
      "unable to inject #{label} into #{Path.relative_to_cwd(path)}",
      metadata: %{path: Path.relative_to_cwd(path), anchor: anchor}
    )
  end
end
