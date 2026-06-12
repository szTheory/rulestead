defmodule RulesteadDemo.DemoUrls do
  @moduledoc false

  @fallback_fleetdesk_frontend_url "http://localhost:3000"

  def fleetdesk_frontend_url do
    Application.get_env(
      :rulestead_demo,
      :fleetdesk_frontend_url,
      @fallback_fleetdesk_frontend_url
    )
  end
end
