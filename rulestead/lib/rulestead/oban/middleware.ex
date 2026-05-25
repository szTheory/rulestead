defmodule Rulestead.Oban.Middleware do
  @moduledoc false
  # Explicit enqueue seam for attaching a serialized rulestead context to jobs.

  alias Rulestead.Oban

  @doc """
  Attaches the caller-provided context to a job-like map.
  """
  @spec attach(map(), keyword()) :: map()
  def attach(job, opts) when is_map(job) and is_list(opts) do
    context =
      case Keyword.fetch(opts, :context) do
        {:ok, context} -> context
        :error -> raise ArgumentError, "attach/2 requires :context"
      end

    Oban.put_context(job, context, opts)
  end
end
