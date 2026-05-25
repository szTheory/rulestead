defmodule RulesteadDemoWeb.PageController do
  use RulesteadDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
