defmodule RulesteadAdmin.Router do
  @moduledoc """
  Mounts the Rulestead admin UI into your Phoenix router.

  ## Quick start

  Add the admin UI to your Phoenix router:

      scope "/admin", MyAppWeb do
        pipe_through [:browser, :require_admin]

        rulestead_admin "/flags", policy: MyApp.AdminPolicy
      end

  Your host app is responsible for authentication. The admin UI does **not**
  authenticate requests — it reads an already-authenticated session.

  ## What you must provide

  1. **A `:browser` pipeline** that includes session parsing and CSRF protection.
  2. **Authentication in front of the scope** — use a plug or a `pipe_through`
     with your auth pipeline. Rulestead never authenticates users.
  3. **A `policy:` option** pointing at a module that implements `Rulestead.Admin.Policy`.
  4. **The required session keys** listed below.

  ## Options

  - `:policy` — **required** — a module implementing `Rulestead.Admin.Policy`.
    Controls which actions each actor may perform.
  - `:mount_path` — optional — overrides the base path used inside the live
    session (defaults to the first argument, `path`).

  ## Session keys read from the host

  The admin UI reads the following keys from the Plug session on each request.
  They must be placed there by your authentication layer before the scope is entered.

  ### Required (frozen 1.x contract)

  - `"current_actor"` — the authenticated actor map (passed to every policy call).
  - `"rulestead_admin_environments"` — list of environment maps to populate the env switcher.
  - `"rulestead_admin_last_env"` — string key of the environment the actor last selected.

  ### Optional (not part of the frozen 1.x contract)

  The following tenant-related keys are read when present; omit them in single-tenant setups:

  - `"rulestead_admin_tenants"` — list of tenant maps.
  - `"rulestead_admin_last_tenant"` — string key of the last-selected tenant.
  - `"rulestead_admin_default_tenant"` — string key of the default tenant.

  ## Boundary

  Internal implementation details — `RulesteadAdmin.Live.*`, `RulesteadAdmin.Components.*`,
  DOM structure, and CSS class names — are **not** part of the 1.x promise and may change
  between minor releases. Depend only on the public mount seam (`rulestead_admin/2`) and the
  session-key contract documented above.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import RulesteadAdmin.Router, only: [rulestead_admin: 1, rulestead_admin: 2]
    end
  end

  @doc """
  Mounts all Rulestead admin LiveView routes under `path`.

  Accepts an optional `policy:` keyword argument specifying a module that
  implements `Rulestead.Admin.Policy`. The `:policy` option is required.

  ## Example

      rulestead_admin "/flags", policy: MyApp.AdminPolicy

  """
  defmacro rulestead_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      policy = Keyword.fetch!(opts, :policy)
      mount_path = Keyword.get(opts, :mount_path, path)
      live_session_name = Module.concat(policy, AdminSession)

      scope path, as: :rulestead_admin do
        live_session live_session_name,
          session: {RulesteadAdmin.Router, :live_session, [mount_path, policy]},
          on_mount: [{RulesteadAdmin.Live.Session, :default}] do
          live("/", RulesteadAdmin.Live.HomeLive.Index, :index)
          live("/flags", RulesteadAdmin.Live.FlagLive.Index, :index)
          live("/new", RulesteadAdmin.Live.FlagLive.Form, :new)
          live("/audit", RulesteadAdmin.Live.AuditLive.Index, :index)
          live("/change-requests", RulesteadAdmin.Live.ChangeRequestLive.Index, :index)
          live("/change-requests/:id", RulesteadAdmin.Live.ChangeRequestLive.Show, :show)
          live("/schedule", RulesteadAdmin.Live.ScheduleLive.Index, :index)
          live("/schedule/:scheduled_execution_id", RulesteadAdmin.Live.ScheduleLive.Show, :show)
          live("/webhooks", RulesteadAdmin.Live.WebhookLive.Index, :index)
          live("/webhooks/:id", RulesteadAdmin.Live.WebhookLive.Show, :show)
          live("/experiments", RulesteadAdmin.Live.ExperimentLive.Index, :index)
          live("/experiments/:key", RulesteadAdmin.Live.ExperimentLive.Show, :show)
          live("/diagnostics", RulesteadAdmin.Live.DiagnosticsLive.Index, :index)
          live("/compare", RulesteadAdmin.Live.EnvironmentCompareLive.Index, :index)
          live("/compare/:key", RulesteadAdmin.Live.EnvironmentCompareLive.Show, :show)
          live("/audiences", RulesteadAdmin.Live.AudienceLive.Index, :index)
          live("/audiences/:audience_key", RulesteadAdmin.Live.AudienceLive.Show, :show)

          live(
            "/audiences/:audience_key/edit/preview",
            RulesteadAdmin.Live.AudienceLive.EditPreview,
            :show
          )

          live(
            "/audiences/:audience_key/edit/confirm",
            RulesteadAdmin.Live.AudienceLive.EditConfirm,
            :show
          )

          live(
            "/audiences/:audience_key/archive/preview",
            RulesteadAdmin.Live.AudienceLive.ArchivePreview,
            :show
          )

          live(
            "/audiences/:audience_key/archive/confirm",
            RulesteadAdmin.Live.AudienceLive.ArchiveConfirm,
            :show
          )

          live(
            "/audiences/:audience_key/delete/preview",
            RulesteadAdmin.Live.AudienceLive.DeletePreview,
            :show
          )

          live("/:key", RulesteadAdmin.Live.FlagLive.Show, :show)
          live("/:key/edit", RulesteadAdmin.Live.FlagLive.Form, :edit)
          live("/:key/rules", RulesteadAdmin.Live.FlagLive.Rules, :index)
          live("/:key/simulate", RulesteadAdmin.Live.FlagLive.Simulate, :show)
          live("/:key/explain", RulesteadAdmin.Live.FlagLive.Explain, :show)
          live("/:key/rollouts", RulesteadAdmin.Live.FlagLive.Rollouts, :show)
          live("/:key/kill", RulesteadAdmin.Live.FlagLive.Kill, :show)
          live("/:key/cleanup", RulesteadAdmin.Live.FlagLive.Cleanup, :show)
          live("/:key/cleanup/preview", RulesteadAdmin.Live.FlagLive.CleanupPreview, :show)
          live("/:key/cleanup/confirm", RulesteadAdmin.Live.FlagLive.CleanupConfirm, :show)
          live("/:key/timeline", RulesteadAdmin.Live.FlagLive.Timeline, :show)
        end
      end
    end
  end

  @doc false
  def live_session(conn, path, policy) do
    session = Plug.Conn.get_session(conn)

    session
    |> Map.take([
      "current_actor",
      "rulestead_admin_environments",
      "rulestead_admin_last_env",
      "rulestead_admin_tenants",
      "rulestead_admin_last_tenant",
      "rulestead_admin_default_tenant"
    ])
    |> Map.merge(%{
      "policy" => policy,
      "mount_path" => path
    })
  end
end
