unless Code.ensure_loaded?(Plug.Conn) do
  defmodule Plug.Conn do
    defstruct assigns: %{},
              private: %{},
              req_headers: [],
              cookies: %{},
              params: %{}
  end
end

defmodule Rulestead.PlugTest do
  use ExUnit.Case, async: true

  alias Rulestead.{Context, Phoenix}
  alias Rulestead.Plug, as: RulesteadPlug

  test "context_from_conn/2 normalizes configured conn fields into a rulestead context" do
    conn = %Plug.Conn{
      assigns: %{
        current_actor: %{id: " actor-1 "},
        tenant: " tenant-1 ",
        current_environment: "  prod  ",
        rulestead_attributes: %{"plan" => "beta"}
      },
      private: %{
        plug_session: %{
          "targeting_key" => "  session-user  ",
          "session_id" => "  session-123  "
        }
      },
      req_headers: [{"x-request-id", " req-123 "}, {"x-rulestead-tenant", "tenant-from-header"}],
      cookies: %{"anon_id" => "cookie-user"}
    }

    context =
      Phoenix.context_from_conn(
        conn,
        actor: {:assign, :current_actor},
        environment: {:assign, :current_environment},
        tenant_key: {:assign, :tenant},
        request_id: {:header, "x-request-id"},
        session_id: {:session, "session_id"},
        attributes: {:assign, :rulestead_attributes},
        targeting_key_sources: [
          {:session, "targeting_key"},
          {:cookie, "anon_id"},
          {:header, "x-rulestead-targeting-key"}
        ],
        strict?: true
      )

    assert %Context{} = context
    assert context.actor == %{id: " actor-1 "}
    assert context.targeting_key == "session-user"
    assert context.environment == "prod"
    assert context.tenant_key == "tenant-1"
    assert context.request_id == "req-123"
    assert context.session_id == "session-123"
    assert context.attributes == %{"plan" => "beta"}
    assert context.strict? == true
  end

  test "plug stores the built context only in conn.assigns[:rulestead_context]" do
    conn = %Plug.Conn{
      assigns: %{current_actor: %{id: "user-1"}},
      private: %{plug_session: %{"targeting_key" => "user-1"}},
      req_headers: [{"x-request-id", "req-456"}],
      cookies: %{"anon_id" => "cookie-user"}
    }

    updated_conn =
      RulesteadPlug.call(
        conn,
        actor: {:assign, :current_actor},
        targeting_key_sources: [{:session, "targeting_key"}, {:cookie, "anon_id"}],
        request_id: {:header, "x-request-id"},
        environment: "test"
      )

    assert %Context{} = updated_conn.assigns[:rulestead_context]
    assert updated_conn.assigns[:rulestead_context].targeting_key == "user-1"
    assert updated_conn.assigns[:rulestead_context].environment == "test"
    assert updated_conn.assigns[:current_actor] == %{id: "user-1"}
    assert updated_conn.private == conn.private
    refute Map.has_key?(updated_conn.private, :rulestead_context)
  end
end
