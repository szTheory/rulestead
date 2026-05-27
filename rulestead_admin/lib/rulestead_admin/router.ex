defmodule RulesteadAdmin.Router do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import RulesteadAdmin.Router, only: [rulestead_admin: 1, rulestead_admin: 2]
    end
  end

  defmacro rulestead_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      policy = Keyword.fetch!(opts, :policy)
      live_session_name = Module.concat(policy, AdminSession)

      scope path, as: :rulestead_admin do
        live_session live_session_name,
          session: {RulesteadAdmin.Router, :live_session, [path, policy]},
          on_mount: [{RulesteadAdmin.Live.Session, :default}] do
          live("/", RulesteadAdmin.Live.FlagLive.Index, :index)
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
          live("/:key", RulesteadAdmin.Live.FlagLive.Show, :show)
          live("/:key/edit", RulesteadAdmin.Live.FlagLive.Form, :edit)
          live("/:key/rules", RulesteadAdmin.Live.FlagLive.Rules, :index)
          live("/:key/simulate", RulesteadAdmin.Live.FlagLive.Simulate, :show)
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
