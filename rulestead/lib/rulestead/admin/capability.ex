defmodule Rulestead.Admin.Capability do
  @moduledoc false
  # Reusable capability projection to prevent UI/backend drift.

  alias Rulestead.Admin.Authorizer

  @type t :: %__MODULE__{
          read_allowed?: boolean(),
          execute_allowed?: boolean(),
          proposal_only?: boolean(),
          admin_only?: boolean(),
          reason: atom() | nil
        }

  defstruct [
    :read_allowed?,
    :execute_allowed?,
    :proposal_only?,
    :admin_only?,
    :reason
  ]

  @spec project(term(), atom(), term(), String.t() | atom() | nil) :: t()
  def project(actor, action, resource, environment_key) do
    read_allowed? = authorize?(actor, :read_flags, resource, environment_key)

    case Authorizer.authorize_governed_action(actor, action, resource, environment_key) do
      {:ok, requirement} ->
        %__MODULE__{
          read_allowed?: read_allowed?,
          execute_allowed?: true,
          proposal_only?: requirement.change_request_required?,
          admin_only?: false,
          reason: nil
        }

      {:error, _error, audit} ->
        reason = audit[:reason] || :unauthorized

        # Determine if it's admin_only by checking if an admin could do it
        admin_actor = %{id: "probe-admin", roles: [:admin]}

        admin_only? =
          case Authorizer.authorize_governed_action(
                 admin_actor,
                 action,
                 resource,
                 environment_key
               ) do
            {:ok, _} -> true
            _ -> false
          end

        %__MODULE__{
          read_allowed?: read_allowed?,
          execute_allowed?: false,
          proposal_only?: false,
          admin_only?: admin_only?,
          reason: reason
        }
    end
  end

  defp authorize?(actor, action, resource, environment_key) do
    case Authorizer.authorize(actor, action, resource, environment_key) do
      :ok -> true
      _ -> false
    end
  end
end
