defmodule Rulestead.Runtime.Diagnostics do
  @moduledoc false

  alias Rulestead.Runtime.Cache

  @spec current() :: map()
  def current do
    %{
      node: node(),
      environments: Cache.diagnostics()
    }
  end
end
