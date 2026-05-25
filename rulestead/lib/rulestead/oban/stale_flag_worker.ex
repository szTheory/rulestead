defmodule Rulestead.Oban.StaleFlagWorker do
  @moduledoc false
  # Worker to periodically flush the ETS telemetry cache to the database.

  use Rulestead.Oban.Worker,
    queue: :telemetry,
    max_attempts: 3

  alias Rulestead.Repo
  alias Rulestead.Telemetry.Cache
  alias Rulestead.FlagEnvironment

  import Ecto.Query

  def perform(_job) do
    snapshot = Cache.snapshot()
    Cache.clear()

    if snapshot != %{} do
      flush_to_db(snapshot)
    end

    {:ok, :flushed}
  end

  defp flush_to_db(snapshot) do
    Enum.each(snapshot, fn {{flag_key, env_key}, data} ->
      update_flag_environment(flag_key, env_key, data)
    end)
  end

  defp update_flag_environment(flag_key, env_key, data) do
    query =
      from(fe in FlagEnvironment,
        join: f in assoc(fe, :flag),
        join: e in assoc(fe, :environment),
        where: f.key == ^flag_key and e.key == ^env_key,
        select: fe
      )

    case Repo.one(query) do
      nil ->
        :ok

      fe ->
        existing_variants = fe.variants_served || %{}
        new_variants = data[:variants_served] || %{}

        merged_variants =
          Enum.reduce(new_variants, existing_variants, fn {v, count}, acc ->
            Map.update(acc, v, count, &(&1 + count))
          end)

        last_eval = fe.last_evaluated_at
        new_eval = data[:last_evaluated_at]

        updated_last_eval =
          if last_eval && new_eval do
            if DateTime.compare(new_eval, last_eval) == :gt do
              new_eval
            else
              last_eval
            end
          else
            new_eval || last_eval
          end

        fe
        |> Ecto.Changeset.change(%{
          variants_served: merged_variants,
          last_evaluated_at: updated_last_eval
        })
        |> Repo.update!()
    end
  end
end
