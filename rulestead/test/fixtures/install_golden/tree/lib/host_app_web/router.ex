defmodule HostAppWeb.Router do
  use HostAppWeb, :router

  use RulesteadAdmin.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {HostAppWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", HostAppWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  # Other scopes may use custom stacks.
  # scope "/api", HostAppWeb do
  #   pipe_through :api
  # end
  scope "/admin", HostAppWeb do
    pipe_through(:browser)
    rulestead_admin("/flags", policy: HostApp.AdminPolicy)
  end
end
