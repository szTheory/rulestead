defmodule Rulestead.ContextTest do
  use ExUnit.Case, async: true

  alias Rulestead.Context

  test "normalizes map and keyword input into the canonical context struct" do
    assert %Context{
             actor: %{key: "user-123", id: 9},
             targeting_key: "user-123",
             tenant_key: "acme",
             environment: "staging",
             attributes: %{plan: "enterprise"},
             request_id: "req-1",
             session_id: "sess-1",
             strict?: true
           } =
             Context.new(
               actor: %{key: "user-123", id: 9},
               tenant_key: "acme",
               environment: "staging",
               attributes: %{plan: "enterprise"},
               request_id: "req-1",
               session_id: "sess-1",
               strict?: true
             )
  end

  test "normalizes subject input to actor without exposing a subject field" do
    context = Context.new(subject: %{key: "subject-1", role: "admin"})

    assert context.actor == %{key: "subject-1", role: "admin"}
    assert context.targeting_key == "subject-1"
    refute Map.has_key?(Map.from_struct(context), :subject)
  end

  test "defaults targeting_key from actor.key when not explicitly provided" do
    context = Context.new(%{actor: %{key: "actor-key", name: "Priya"}})

    assert context.targeting_key == "actor-key"
  end
end
