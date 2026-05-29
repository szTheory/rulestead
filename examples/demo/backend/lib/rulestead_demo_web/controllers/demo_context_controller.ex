defmodule RulesteadDemoWeb.DemoContextController do
  @moduledoc false

  use RulesteadDemoWeb, :controller

  alias RulesteadDemoWeb.DemoContextJSON

  def personas(conn, _params) do
    json(conn, DemoContextJSON.personas())
  end
end
