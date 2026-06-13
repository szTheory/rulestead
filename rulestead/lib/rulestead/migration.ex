defmodule Rulestead.Migration do
  @moduledoc false

  defmacro __using__(opts) do
    prefix = Keyword.fetch!(opts, :prefix)
    create_schema? = Keyword.get(opts, :create_schema, prefix != "public")
    normalized_prefix = Rulestead.RepoPrefix.normalize!(prefix)
    quoted_prefix = Rulestead.RepoPrefix.quoted_identifier(normalized_prefix)

    quote bind_quoted: [
            prefix: normalized_prefix,
            create_schema?: create_schema?,
            quoted_prefix: quoted_prefix
          ] do
      use Ecto.Migration

      @rulestead_prefix prefix
      @rulestead_create_schema create_schema?
      @rulestead_quoted_prefix quoted_prefix

      import Rulestead.Migration

      defp rulestead_prefix, do: @rulestead_prefix
      defp rulestead_create_schema?, do: @rulestead_create_schema

      if create_schema? and prefix != "public" do
        defp create_rulestead_schema do
          execute("CREATE SCHEMA IF NOT EXISTS #{@rulestead_quoted_prefix}")
        end

        defp drop_rulestead_schema do
          execute("DROP SCHEMA IF EXISTS #{@rulestead_quoted_prefix}")
        end
      else
        defp create_rulestead_schema, do: :ok
        defp drop_rulestead_schema, do: :ok
      end
    end
  end

  defmacro rulestead_table(name, opts \\ []) do
    quote do
      table(unquote(name), Keyword.put_new(unquote(opts), :prefix, rulestead_prefix()))
    end
  end

  defmacro rulestead_index(table, columns, opts \\ []) do
    quote do
      index(
        unquote(table),
        unquote(columns),
        Keyword.put_new(unquote(opts), :prefix, rulestead_prefix())
      )
    end
  end

  defmacro rulestead_unique_index(table, columns, opts \\ []) do
    quote do
      unique_index(
        unquote(table),
        unquote(columns),
        Keyword.put_new(unquote(opts), :prefix, rulestead_prefix())
      )
    end
  end

  defmacro rulestead_constraint(table, name, opts) do
    quote do
      constraint(
        unquote(table),
        unquote(name),
        Keyword.put_new(unquote(opts), :prefix, rulestead_prefix())
      )
    end
  end

  defmacro rulestead_references(table, opts \\ []) do
    quote do
      references(unquote(table), Keyword.put_new(unquote(opts), :prefix, rulestead_prefix()))
    end
  end

  defmacro rulestead_qualified(identifier) do
    quote do
      Rulestead.RepoPrefix.qualified(rulestead_prefix(), unquote(identifier))
    end
  end
end
