defmodule Rulestead.Oban.Worker do
  @moduledoc false
  # Worker-side seam that restores the serialized `%Rulestead.Context{}` from an
  # Oban job without repeating helper boilerplate in each worker module.

  defmacro __using__(_opts) do
    quote do
      @doc """
      Restores the explicit `%Rulestead.Context{}` carried by this job.
      """
      def rulestead_context(job), do: Rulestead.Oban.context_from_job(job)

      @doc """
      Alias for `rulestead_context/1`.
      """
      def context_from_job(job), do: Rulestead.Oban.context_from_job(job)
    end
  end
end
