defmodule Rulestead.Runtime.Diagnostics do
  @moduledoc false

  alias Rulestead.Runtime.Cache
  alias Rulestead.Runtime.Health

  @spec current() :: map()
  def current do
    %{
      node: node(),
      environments: Cache.diagnostics(),
      infrastructure_health: Health.current()
    }
  end
end
