defmodule Rulestead.Analytics.Query do
  @moduledoc """
  Ecto aggregation queries for experiment metrics.
  """

  import Ecto.Query

  alias Rulestead.Analytics.Event
  alias Rulestead.Repo

  @doc """
  Fetches experiment metrics (exposures and conversions) grouped by variation.

  Returns a list of maps, e.g.,
  `[%{variation: "red", exposures: 100, conversions: 20}]`
  """
  def experiment_metrics(flag_key, target_event, env) do
    exposures_query =
      from e in Event,
        where: e.kind == "exposure" and e.env == ^env,
        where: fragment("?->>'flag_key' = ?", e.metadata, ^flag_key),
        select: %{
          actor_id: e.actor_id,
          variation: fragment("?->>'value'", e.metadata)
        }

    conversions_query =
      from c in Event,
        where: c.kind == "custom" and c.event_name == ^target_event and c.env == ^env,
        select: %{
          actor_id: c.actor_id
        }

    from(e in subquery(exposures_query),
      left_join: c in subquery(conversions_query),
      on: e.actor_id == c.actor_id,
      group_by: e.variation,
      select: %{
        variation: e.variation,
        exposures: count(e.actor_id, :distinct),
        conversions: count(c.actor_id, :distinct)
      }
    )
    |> Repo.all()
  end
end
