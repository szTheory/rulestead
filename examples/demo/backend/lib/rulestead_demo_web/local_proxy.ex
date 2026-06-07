defmodule RulesteadDemoWeb.LocalProxy do
  @moduledoc false

  def localhost_demo?(%Plug.Conn{host: host}) when is_binary(host) do
    host in ["localhost", "127.0.0.1", "backend", "rulestead.localhost"] or
      String.ends_with?(host, ".localhost")
  end

  def localhost_demo?(_conn), do: false
end
