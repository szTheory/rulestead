defmodule RulesteadDemoWeb.LocalProxyTest do
  use ExUnit.Case, async: true

  alias RulesteadDemoWeb.LocalProxy

  test "matches localhost and rulestead localhost demo hosts" do
    for host <- [
          "localhost",
          "127.0.0.1",
          "backend",
          "rulestead.localhost",
          "fleetdesk.rulestead.localhost",
          "rulestead-feature-x.localhost"
        ] do
      assert LocalProxy.localhost_demo?(%Plug.Conn{host: host})
    end
  end

  test "rejects unrelated hosts" do
    refute LocalProxy.localhost_demo?(%Plug.Conn{host: "example.com"})
    refute LocalProxy.localhost_demo?(%Plug.Conn{host: "rulestead.local"})
  end
end
