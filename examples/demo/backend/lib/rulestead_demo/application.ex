defmodule RulesteadDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Rulestead.Runtime.Supervisor, as: RuntimeSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      RulesteadDemoWeb.Telemetry,
      RulesteadDemo.Repo,
      Rulestead.Repo,
      {DNSCluster, query: Application.get_env(:rulestead_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RulesteadDemo.PubSub},
      {RuntimeSupervisor,
       name: nil,
       environment_keys: ["staging", "production"],
       refresh_name: %{
         "staging" => RulesteadDemo.RuntimeRefresh.Staging,
         "production" => RulesteadDemo.RuntimeRefresh.Production
       }},
      # Start a worker by calling: RulesteadDemo.Worker.start_link(arg)
      # {RulesteadDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      RulesteadDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RulesteadDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RulesteadDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
