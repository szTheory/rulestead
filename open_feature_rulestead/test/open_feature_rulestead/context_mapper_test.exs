defmodule OpenFeatureRulestead.ContextMapperTest do
  use ExUnit.Case, async: true

  alias OpenFeatureRulestead.ContextMapper
  alias Rulestead.Context

  test "Given a string-key map with targetingKey, tenantKey, environment, sessionId, requestId, actor, returns a valid Rulestead.Context struct" do
    of_context = %{
      "targetingKey" => "user-123",
      "tenantKey" => "acme",
      "environment" => "production",
      "sessionId" => "sess-1",
      "requestId" => "req-1",
      "actor" => %{"id" => "user-123", "role" => "admin"}
    }

    result = ContextMapper.translate(of_context)

    assert %Context{} = result
    assert result.targeting_key == "user-123"
    assert result.tenant_key == "acme"
    assert result.environment == "production"
    assert result.session_id == "sess-1"
    assert result.request_id == "req-1"
    assert result.actor == %{"id" => "user-123", "role" => "admin"}
    assert result.attributes == %{}
  end

  test "Unrecognized keys in the OpenFeature map are moved into the attributes map in the Rulestead.Context" do
    of_context = %{
      "targetingKey" => "user-456",
      "customProperty" => "value",
      "nested" => %{"key" => "val"}
    }

    result = ContextMapper.translate(of_context)

    assert result.targeting_key == "user-456"

    assert result.attributes == %{
             "customProperty" => "value",
             "nested" => %{"key" => "val"}
           }
  end

  test "Handles missing optional keys gracefully" do
    of_context = %{}

    result = ContextMapper.translate(of_context)

    assert %Context{} = result
    assert result.targeting_key == nil
    assert result.tenant_key == nil
    assert result.attributes == %{}
  end
end
