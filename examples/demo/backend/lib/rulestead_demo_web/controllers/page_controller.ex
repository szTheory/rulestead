defmodule RulesteadDemoWeb.PageController do
  use RulesteadDemoWeb, :controller

  alias RulesteadDemo.DemoUrls

  def home(conn, _params) do
    render(conn, :home, fleetdesk_frontend_url: DemoUrls.fleetdesk_frontend_url())
  end
end
