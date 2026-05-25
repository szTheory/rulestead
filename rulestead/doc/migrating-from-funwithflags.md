# Migrating from FunWithFlags

Welcome to Rulestead! If you are transitioning from `FunWithFlags` (or similar feature flag libraries in the Elixir ecosystem), you'll find that Rulestead covers similar ground but introduces a more robust, auditable, and structured approach to feature toggles.

This guide will help you map the concepts you know from FunWithFlags to the Rulestead terminology and patterns.

## Conceptual Shifts

Rulestead moves away from the concept of "Gates" and "Priority", and instead utilizes "Rules" and "Ordered Evaluation". Furthermore, Rulestead places a strong emphasis on auditability, requiring explicit contexts and utilizing a Change Request process for mutations.

| FunWithFlags Concept | Rulestead Concept | Description |
| :--- | :--- | :--- |
| **Flag** | **Flag** | The core feature toggle. In Rulestead, flags belong to an environment. |
| **Gate** | **Rule** | The condition that determines if a flag is enabled. |
| **Priority** | **Ordered Evaluation** | Rulestead evaluates rules strictly in the order they are defined within a Ruleset, rather than relying on implicit gate priority. |
| **Boolean Gate** | **Rule without conditions** | A rule that simply returns `true` or `false` without checking any attributes. |
| **Actor Gate** | **Condition checking an ID** | A rule condition that checks an identifier in the context (e.g., `{"user_id", :in, ["123"]}`). |
| **Group Gate** | **Condition checking a role** | A rule condition that explicitly checks a role or group attribute passed in the context. |
| **Percentage Gate** | **Rollout Rule** | A rule that uses deterministic bucketing based on an attribute to evaluate to `true` for a percentage of traffic. |

## Evaluating Flags

In FunWithFlags, you might evaluate a flag globally or for a specific actor:

```elixir
# FunWithFlags
FunWithFlags.enabled?(:my_feature)
FunWithFlags.enabled?(:my_feature, for: user)
```

In Rulestead, evaluation **always requires a context**. This ensures deterministic behavior and makes it explicit what data is being used to evaluate the rules.

```elixir
# Rulestead
Rulestead.enabled?(:my_feature, %{"user_id" => "123", "role" => "admin"})
```

If you have a flag that is strictly a global boolean and requires no context, you must still pass an empty context (or an explicit context map to be safe for future rule additions):

```elixir
# Rulestead
Rulestead.enabled?(:global_feature, %{})
```

## Mutating Flags

FunWithFlags allows you to mutate flags directly via its API:

```elixir
# FunWithFlags
FunWithFlags.enable(:my_feature)
FunWithFlags.enable(:my_feature, for: user)
FunWithFlags.enable(:my_feature, for_group: :admins)
```

Rulestead prioritizes governance and auditability. You do not mutate flags directly; instead, you submit a **Change Request** or publish a **Ruleset**.

```elixir
# Rulestead
alias Rulestead.Store.Command.PublishRuleset

# Equivalent to enabling a flag globally
Rulestead.publish_ruleset(%PublishRuleset{
  environment_key: "production",
  flag_key: "my_feature",
  rules: [
    %{
      id: "rule-1",
      action: "return_true",
      conditions: []
    }
  ],
  actor: %{"user" => "admin@example.com"},
  reason: "Enabling feature globally"
})
```

For more complex scenarios, such as requiring approvals, you would use the `SubmitChangeRequest` command.

## Summary

Migrating to Rulestead means moving from an imperative, mutation-heavy API to a declarative, state-based, and auditable API. By explicitly passing context and using rulesets, your feature flags become more predictable, easier to test, and safer to operate at scale.
