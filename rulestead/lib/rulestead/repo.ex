defmodule Rulestead.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :rulestead,
    adapter: Ecto.Adapters.Postgres
end
