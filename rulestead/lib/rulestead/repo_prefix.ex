defmodule Rulestead.RepoPrefix do
  @moduledoc false

  @default_prefix "rulestead"

  @spec default_prefix() :: String.t()
  def default_prefix, do: @default_prefix

  @spec configured_prefix() :: String.t()
  def configured_prefix do
    :rulestead
    |> Application.get_env(Rulestead.Repo, [])
    |> Keyword.get(:prefix, @default_prefix)
    |> normalize!()
  end

  @spec repo_opts(keyword()) :: keyword()
  def repo_opts(opts \\ []) do
    Keyword.put_new(opts, :prefix, configured_prefix())
  end

  @spec normalize!(term()) :: String.t()
  def normalize!(prefix) when is_binary(prefix) do
    prefix = String.trim(prefix)

    cond do
      prefix == "" ->
        raise ArgumentError, "Rulestead repo prefix must be a non-empty string"

      Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*$/, prefix) ->
        prefix

      true ->
        raise ArgumentError,
              "Rulestead repo prefix must be a valid unquoted PostgreSQL identifier"
    end
  end

  def normalize!(_prefix) do
    raise ArgumentError,
          "Rulestead repo prefix must be a string; use \"public\" for the public schema"
  end

  @spec quoted_identifier(String.t()) :: String.t()
  def quoted_identifier(prefix) when is_binary(prefix) do
    ~s("#{normalize!(prefix)}")
  end

  @spec qualified(String.t(), String.t()) :: String.t()
  def qualified(prefix, identifier) when is_binary(prefix) and is_binary(identifier) do
    quoted_identifier(prefix) <> "." <> quoted_identifier(identifier)
  end
end
