defmodule Rulestead.Install.ConfigWriter do
  @moduledoc false

  @template_path Application.app_dir(
                   :rulestead,
                   "priv/templates/rulestead.install/config/rulestead.exs"
                 )
  @import_line ~s(import_config "rulestead.exs")

  @spec write(module(), keyword()) :: {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
  def write(repo, opts \\ []) do
    config_dir = Keyword.get(opts, :config_path) || Path.join(File.cwd!(), "config")
    rulestead_path = Path.join(config_dir, "rulestead.exs")
    config_path = Path.join(config_dir, "config.exs")

    File.mkdir_p!(config_dir)

    rendered = render_template(repo)

    messages =
      []
      |> maybe_write_rulestead_config(rulestead_path, rendered)
      |> maybe_inject_import(config_path)

    {:ok, Enum.reverse(messages)}
  end

  defp render_template(repo) do
    @template_path
    |> File.read!()
    |> String.replace("__REPO_MODULE__", inspect(repo))
  end

  defp maybe_write_rulestead_config(messages, path, rendered) do
    case File.read(path) do
      {:ok, ^rendered} ->
        ["skip #{Path.relative_to_cwd(path)} already present" | messages]

      {:ok, _existing} ->
        File.write!(path, rendered)
        ["write #{Path.relative_to_cwd(path)}" | messages]

      {:error, :enoent} ->
        File.write!(path, rendered)
        ["write #{Path.relative_to_cwd(path)}" | messages]
    end
  end

  defp maybe_inject_import(messages, config_path) do
    contents =
      case File.read(config_path) do
        {:ok, existing} -> existing
        {:error, :enoent} -> "import Config\n"
      end

    cond do
      String.contains?(contents, @import_line) ->
        ["skip #{Path.relative_to_cwd(config_path)} import already present" | messages]

      true ->
        updated = inject_import(contents)
        File.write!(config_path, updated)
        ["write #{Path.relative_to_cwd(config_path)} import" | messages]
    end
  end

  defp inject_import(contents) do
    trimmed = String.trim_trailing(contents)
    trimmed <> "\n\n" <> @import_line <> "\n"
  end
end
