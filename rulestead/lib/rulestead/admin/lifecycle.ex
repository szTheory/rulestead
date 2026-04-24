defmodule Rulestead.Admin.Lifecycle do
  @moduledoc """
  Derives persisted admin lifecycle state from authored flag data.
  """

  @default_stale_after_seconds 30 * 24 * 60 * 60

  @type state :: :active | :potentially_stale | :stale | :archived

  @spec classify(map() | struct(), map() | struct(), keyword()) :: %{
          state: state(),
          mode: :permanent | :expiring,
          owner: term(),
          expected_expiration: Date.t() | nil,
          permanent: boolean(),
          last_evaluated_at: DateTime.t() | nil
        }
  def classify(flag, flag_environment, opts \\ []) do
    flag = Map.new(flag)
    flag_environment = Map.new(flag_environment)

    permanent = truthy?(flag[:permanent])
    expected_expiration = flag[:expected_expiration]
    last_evaluated_at = flag_environment[:last_evaluated_at]

    %{
      state: state(flag, flag_environment, last_evaluated_at, opts),
      mode: if(permanent, do: :permanent, else: :expiring),
      owner: flag[:owner],
      expected_expiration: expected_expiration,
      permanent: permanent,
      last_evaluated_at: last_evaluated_at
    }
  end

  defp state(flag, flag_environment, _last_evaluated_at, opts) do
    if not is_nil(flag[:archived_at]) or flag_environment[:status] == :archived do
      :archived
    else
      state_from_freshness(flag_environment[:last_evaluated_at], opts)
    end
  end

  defp state_from_freshness(nil, _opts), do: :potentially_stale

  defp state_from_freshness(%DateTime{} = last_evaluated_at, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    stale_after_seconds = Keyword.get(opts, :stale_after_seconds, @default_stale_after_seconds)
    warning_after_seconds = Keyword.get(opts, :warning_after_seconds, div(stale_after_seconds, 2))
    age_seconds = DateTime.diff(now, last_evaluated_at, :second)

    cond do
      age_seconds >= stale_after_seconds -> :stale
      age_seconds >= warning_after_seconds -> :potentially_stale
      true -> :active
    end
  end

  defp truthy?(value), do: value in [true, "true", 1, "1"]
end
