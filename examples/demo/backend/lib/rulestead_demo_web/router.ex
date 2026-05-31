defmodule RulesteadDemoWeb.Router do
  use RulesteadDemoWeb, :router

  use RulesteadAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RulesteadDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug RulesteadDemoWeb.Plugs.DemoCors
    plug :accepts, ["json"]
  end

  scope "/", RulesteadDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/demo/sign-in", DemoSessionController, :create
  end

  scope "/api", RulesteadDemoWeb do
    pipe_through :api

    get "/demo/personas", DemoContextController, :personas

    options "/flags", FlagController, :preflight
    get "/flags", FlagController, :show
    options "/flags/stream", FlagStreamController, :preflight
    get "/flags/stream", FlagStreamController, :show
    options "/flags/explain", ExplainController, :preflight
    get "/flags/explain", ExplainController, :show
  end

  scope "/admin" do
    pipe_through :browser
    rulestead_admin("/flags", policy: RulesteadDemo.AdminPolicy, mount_path: "/admin/flags")
  end
end
