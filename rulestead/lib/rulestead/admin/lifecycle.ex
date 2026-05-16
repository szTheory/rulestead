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
      flag_type = to_string(flag[:flag_type])
      if flag_type in ["kill_switch", "operational"] do
        :active
      else
        state_from_freshness(flag_environment, opts)
      end
    end
  end

  defp state_from_freshness(%{last_evaluated_at: nil}, _opts), do: :potentially_stale

  defp state_from_freshness(%{last_evaluated_at: %DateTime{} = last_evaluated_at} = flag_environment, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    stale_after_seconds = Keyword.get(opts, :stale_after_seconds, @default_stale_after_seconds)
    warning_after_seconds = Keyword.get(opts, :warning_after_seconds, div(stale_after_seconds, 2))
    
    last_published_at = flag_environment[:last_published_at] || last_evaluated_at
    variants_served = flag_environment[:variants_served] || %{}

    eval_age_seconds = DateTime.diff(now, last_evaluated_at, :second)
    pub_age_seconds = DateTime.diff(now, last_published_at, :second)
    served_one_variant? = map_size(variants_served) <= 1

    terminal_stale? = pub_age_seconds >= stale_after_seconds and served_one_variant?
    terminal_warning? = pub_age_seconds >= warning_after_seconds and served_one_variant?

    cond do
      eval_age_seconds >= stale_after_seconds -> :stale
      terminal_stale? -> :stale
      eval_age_seconds >= warning_after_seconds -> :potentially_stale
      terminal_warning? -> :potentially_stale
      true -> :active
    end
  end

  defp truthy?(value), do: value in [true, "true", 1, "1"]
end
