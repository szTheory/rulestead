defmodule Rulestead.Install.MigrationWriter do
  @moduledoc false

  @source_dir Application.app_dir(:rulestead, "priv/repo/migrations")

  @spec copy_migrations(module(), keyword()) ::
          {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
  def copy_migrations(repo, opts \\ []) do
    target_dir = Keyword.get(opts, :migrations_path) || target_path_for_repo(repo)

    prefix =
      opts |> Keyword.get(:prefix, Rulestead.RepoPrefix.default_prefix()) |> normalize_prefix()

    create_schema? = Keyword.get(opts, :create_schema, prefix != "public")
    File.mkdir_p!(target_dir)

    messages =
      @source_dir
      |> File.ls!()
      |> Enum.sort()
      |> Enum.map(fn filename ->
        source = Path.join(@source_dir, filename)
        target = Path.join(target_dir, filename)

        case File.exists?(target) do
          true ->
            "skip #{Path.relative_to_cwd(target)} already present"

          false ->
            source
            |> File.read!()
            |> render_migration(prefix, create_schema?)
            |> then(&File.write!(target, &1))

            "copy #{Path.relative_to_cwd(target)}"
        end
      end)

    {:ok, messages}
  end

  defp target_path_for_repo(repo) do
    _repo = repo
    Path.join(File.cwd!(), "priv/repo/migrations")
  end

  defp normalize_prefix(prefix), do: Rulestead.RepoPrefix.normalize!(prefix)

  defp render_migration(contents, prefix, create_schema?) do
    contents
    |> String.replace(
      ~r/use Rulestead\.Migration, prefix: "rulestead", create_schema: (true|false)/,
      ~s(use Rulestead.Migration, prefix: #{inspect(prefix)}, create_schema: #{inspect(create_schema?)})
    )
  end
end
