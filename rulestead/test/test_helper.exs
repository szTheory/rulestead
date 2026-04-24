ExUnit.start()

Code.require_file("support/oban_job_stub.ex", __DIR__)

{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Rulestead.Repo.start_link()
Application.put_env(:rulestead, :store, Rulestead.Fake)
Rulestead.Fake.Control.ensure_started()
Rulestead.Fake.Control.reset!()

Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, :manual)
