defmodule RulesteadDemo.Repo do
  use Ecto.Repo,
    otp_app: :rulestead_demo,
    adapter: Ecto.Adapters.Postgres
end
