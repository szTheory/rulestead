defmodule Rulestead.Plug do
  @moduledoc false
  # Plug-facing seam that assigns a normalized `%Rulestead.Context{}` onto
  # `conn.assigns[:rulestead_context]`.


  alias Rulestead.Phoenix

  @default_assign :rulestead_context

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(map(), keyword()) :: map()
  def call(conn, opts \\ []) when is_map(conn) and is_list(opts) do
    assign_key = Keyword.get(opts, :context_assign, @default_assign)
    context = Phoenix.context_from_conn(conn, opts)
    assigns = conn |> Map.get(:assigns, %{}) |> Map.put(assign_key, context)

    Map.put(conn, :assigns, assigns)
  end
end
