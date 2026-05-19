defmodule Rulestead.StoreError do
  @moduledoc false
  # Constructors for store-domain `Rulestead.Error` values.


  alias Rulestead.Error

  @spec new(Error.type(), String.t(), keyword()) :: Error.t()
  def new(type, message, opts \\ []) do
    Error.new(
      Keyword.merge(
        [
          domain: :store,
          type: type,
          message: message
        ],
        opts
      )
    )
  end

  @spec flag_not_found(String.t() | atom, String.t() | atom, keyword()) :: Error.t()
  def flag_not_found(flag_key, environment_key, opts \\ []) do
    new(
      :flag_not_found,
      "flag was not found for the requested environment",
      Keyword.merge(
        [
          metadata: %{
            flag_key: to_string(flag_key),
            environment_key: to_string(environment_key)
          }
        ],
        opts
      )
    )
  end

  @spec environment_not_found(String.t() | atom, keyword()) :: Error.t()
  def environment_not_found(environment_key, opts \\ []) do
    new(
      :environment_not_found,
      "environment was not found",
      Keyword.merge([metadata: %{environment_key: to_string(environment_key)}], opts)
    )
  end

  @spec snapshot_not_found(String.t() | atom, keyword()) :: Error.t()
  def snapshot_not_found(environment_key, opts \\ []) do
    new(
      :snapshot_not_found,
      "runtime snapshot was not found for the requested environment",
      Keyword.merge([metadata: %{environment_key: to_string(environment_key)}], opts)
    )
  end

  @spec invalid_command(String.t(), keyword()) :: Error.t()
  def invalid_command(message \\ "store command is invalid", opts \\ []) do
    new(:invalid_command, message, opts)
  end

  @spec unavailable(keyword()) :: Error.t()
  def unavailable(opts \\ []) do
    new(:store_unavailable, "store is unavailable", opts)
  end

  @spec archived(String.t() | atom, keyword()) :: Error.t()
  def archived(flag_key, opts \\ []) do
    new(
      :flag_archived,
      "flag is archived and cannot be changed",
      Keyword.merge([metadata: %{flag_key: to_string(flag_key)}], opts)
    )
  end
end
