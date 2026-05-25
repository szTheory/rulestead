defmodule Rulestead.Runtime.HealthPeerProvider do
  @moduledoc false

  @callback peer_nodes() :: [map()]
end
