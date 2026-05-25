alias Rulestead.Store.Command
alias Rulestead.Runtime.Refresh

demo_actor = %{
  id: "demo-operator",
  email: "demo-operator@rulestead.local",
  display: "Demo Operator",
  roles: ["admin"]
}

flag_key = "enable-new-dashboard"
environment_keys = ["staging", "production"]

case Rulestead.fetch_flag(flag_key, "staging", include_ruleset?: false) do
  {:ok, _flag} ->
    :ok

  {:error, _error} ->
    {:ok, _flag} =
      Rulestead.create_flag(
        %{
          key: flag_key,
          description: "Turns the demo frontend's new dashboard experience on.",
          flag_type: :release,
          value_type: :boolean,
          default_value: %{value: false},
          owner: "demo-platform",
          permanent: true,
          tags: ["demo", "ga"],
          environment_keys: environment_keys
        },
        actor: demo_actor,
        metadata: %{seed: "phase-28"}
      )
end

ruleset = %{
  salt: "enable-new-dashboard:demo:v1",
  metadata: %{seed: "phase-28"},
  rules: [
    %{
      key: "always-on-demo-dashboard",
      name: "Always on in the demo app",
      strategy: :forced_value,
      value: %{value: true},
      conditions: []
    }
  ]
}

Enum.each(environment_keys, fn environment_key ->
  {:ok, _draft} =
    Rulestead.save_draft_ruleset(
      Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
        actor: demo_actor,
        metadata: %{seed: "phase-28"}
      )
    )

  {:ok, _published} =
    Rulestead.publish_ruleset(
      Command.PublishRuleset.new(flag_key, environment_key,
        actor: demo_actor,
        metadata: %{seed: "phase-28"}
      )
    )
end)

Enum.each(
  [
    RulesteadDemo.RuntimeRefresh.Staging,
    RulesteadDemo.RuntimeRefresh.Production
  ],
  fn refresh_name ->
    if Process.whereis(refresh_name) do
      :ok = Refresh.refresh_now(refresh_name)
    end
  end
)

IO.puts("Seeded demo environments, enable-new-dashboard flag, and published demo rulesets.")
