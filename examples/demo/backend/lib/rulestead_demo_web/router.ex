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

  # Fixture-only UI matrix evidence route. Dev/test by default so it never ships
  # in a real production deployment. The adoption-lab Docker image opts in via
  # RULESTEAD_DEMO_DEV_ROUTES=1 (set in examples/demo/backend/Dockerfile before
  # `mix compile`) so the integration Playwright suite can drive it against the
  # prod-built backend. Evaluated at compile time — matches the build env.
  if Mix.env() in [:dev, :test] or System.get_env("RULESTEAD_DEMO_DEV_ROUTES") == "1" do
    scope "/dev/rulestead-admin", RulesteadDemoWeb do
      pipe_through :browser

      live "/ui-matrix", UiMatrixLive, :index
    end
  end
end
