ExUnit.start()

{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Rulestead.Repo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, :manual)
