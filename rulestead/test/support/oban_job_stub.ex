unless Code.ensure_loaded?(Oban.Job) do
  defmodule Oban.Job do
    @moduledoc false
    defstruct id: nil, args: %{}, meta: %{}, worker: nil, scheduled_at: nil
  end
end
