default_excludes =
  []
  |> then(fn ex ->
    if System.get_env("RULESTEAD_RUN_INSTALL_INTEGRATION") == "1",
      do: ex,
      else: [{:install_integration, true} | ex]
  end)
  |> then(fn ex ->
    if System.get_env("RULESTEAD_RUN_PUBLISHED_HEX_SMOKE") == "1",
      do: ex,
      else: [{:published_hex_smoke, true} | ex]
  end)

ExUnit.start(exclude: default_excludes)

{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Rulestead.Repo.start_link()
Application.put_env(:rulestead, :store, Rulestead.Fake)
Application.put_env(:rulestead, :admin_policy, Rulestead.AllowPolicy)
Rulestead.Fake.Control.ensure_started()
Rulestead.Fake.Control.reset!()

try do
  Supervisor.terminate_child(Rulestead.Application.Supervisor, Rulestead.Analytics.Batcher)
catch
  :exit, _ -> :ok
end

Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, :manual)
