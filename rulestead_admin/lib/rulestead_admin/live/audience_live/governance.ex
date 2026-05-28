# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.Governance do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias Phoenix.LiveView.Socket
  alias Rulestead.Admin.Authorizer
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Promotion.Compare
  alias RulesteadAdmin.Live.AudienceLive.Shared

  @type governance_mode :: :unrestricted | :direct_apply | :change_request | :blocked
  @type visibility_tier :: :full | :partial | :denied

  @spec load_governance_context(Socket.t(), map(), keyword()) :: Socket.t()
  def load_governance_context(socket, preview, opts) when is_map(preview) and is_list(opts) do
    operation = Keyword.fetch!(opts, :operation)
    environment_key = socket.assigns.current_environment.key
    audience_key = preview_audience_key(preview, socket)

    deps_result =
      Rulestead.list_audience_dependencies(Shared.dependency_command(socket, audience_key))

    inventory = normalize_dependency_inventory(deps_result)
    hidden_count = hidden_reference_count(deps_result)
    tier = visibility_tier(inventory)

    assess_attrs =
      build_assess_attrs(preview, operation, environment_key, hidden_count)

    {assessment, blocked_reason} =
      case Rulestead.assess_audience_blast_radius(assess_attrs) do
        {:ok, assessment} ->
          {assessment, top_breach_remediation(assessment)}

        {:error, _error} ->
          {nil, "Blast radius cannot be evaluated safely. Re-run preview after resolving inputs."}
      end

    mode = governance_mode(environment_key, assessment, tier)

    socket
    |> assign(:governance_mode, mode)
    |> assign(:visibility_tier, tier)
    |> assign(:blast_radius_assessment, assessment)
    |> assign(:dependency_inventory, inventory)
    |> assign(:governance_blocked_reason, blocked_reason)
  end

  @spec governance_mode(term(), map() | nil, visibility_tier()) :: governance_mode()
  def governance_mode(environment_key, assessment, visibility_tier) do
    cond do
      not Compare.protected_target?(normalize_environment_key(environment_key)) ->
        :unrestricted

      visibility_tier in [:partial, :denied] ->
        :blocked

      is_nil(assessment) ->
        :blocked

      assessment_verdict(assessment) == :below_threshold ->
        :direct_apply

      assessment_verdict(assessment) == :above_threshold ->
        :change_request

      true ->
        :blocked
    end
  end

  @spec visibility_tier(map()) :: visibility_tier()
  def visibility_tier(%{denied?: true}), do: :denied

  def visibility_tier(%{hidden_count: hidden}) when is_integer(hidden) and hidden > 0,
    do: :partial

  def visibility_tier(%{hidden_reference_count: hidden}) when is_integer(hidden) and hidden > 0,
    do: :partial

  def visibility_tier(_inventory), do: :full

  @spec merge_approval_expectations(Socket.t(), String.t()) :: Socket.t()
  def merge_approval_expectations(socket, audience_key) when is_binary(audience_key) do
    approval_expectation_assigns(socket, audience_key)
    |> Enum.reduce(socket, fn {key, value}, acc -> assign(acc, key, value) end)
  end

  @spec build_approval_requirement(Socket.t(), atom(), String.t()) :: ApprovalRequirement.t()
  def build_approval_requirement(socket, action, audience_key)
      when is_binary(audience_key) and is_atom(action) do
    Authorizer.approval_requirement(
      socket.assigns.current_actor,
      action,
      %{resource_type: "audience", resource_key: audience_key},
      socket.assigns.current_environment.key
    )
  end

  @spec audience_mutation_command_map(Socket.t(), map(), map() | nil, :update | :archive) :: map()
  def audience_mutation_command_map(socket, preview, audience, operation)
      when is_map(preview) and operation in [:update, :archive] do
    base = %{
      "audience_key" => socket.assigns.audience_key,
      "environment_key" => socket.assigns.current_environment.key,
      "tenant_key" => tenant_key(socket),
      "operation" => normalize_operation(operation),
      "preview_schema_version" => fetch(preview, :preview_schema_version),
      "preview_fingerprint" => fetch(preview, :preview_fingerprint),
      "preview_basis" => fetch(preview, :preview_basis),
      "affected_reference_keys" => affected_reference_keys(preview)
    }

    case operation do
      :update when is_map(audience) ->
        Map.put(base, "after_definition", fetch(audience, :definition))

      _ ->
        base
    end
  end

  @spec ensure_governance_mode(Socket.t(), governance_mode()) :: :ok | {:error, String.t()}
  def ensure_governance_mode(%{assigns: %{governance_mode: mode}}, expected)
      when mode == expected,
      do: :ok

  def ensure_governance_mode(_socket, _expected),
    do: {:error, "This action is not available for the current governance state."}

  @spec approval_expectation_assigns(Socket.t(), String.t()) :: map()
  def approval_expectation_assigns(socket, audience_key) when is_binary(audience_key) do
    actor = socket.assigns.current_actor
    env_key = socket.assigns.current_environment.key
    resource = %{resource_type: "audience", resource_key: audience_key}

    requirement =
      Authorizer.approval_requirement(actor, :submit_change_request, resource, env_key)

    can_submit? = Authorizer.authorize(actor, :submit_change_request, resource, env_key) == :ok

    %{
      required_approvals: requirement.required_approvals,
      self_approval_allowed?: requirement.self_approval_allowed?,
      can_submit?: can_submit?
    }
  end

  defp build_assess_attrs(preview, operation, environment_key, hidden_count) do
    %{
      environment_key: environment_key,
      operation: normalize_operation(operation),
      preview_fingerprint: fetch(preview, :preview_fingerprint),
      preview_schema_version: fetch(preview, :preview_schema_version),
      affected_references: List.wrap(fetch(preview, :affected_references)),
      affected_reference_keys: affected_reference_keys(preview),
      dependency_entries: [],
      hidden_reference_count: hidden_count,
      tenant_key: tenant_key_from_preview(preview)
    }
  end

  defp normalize_dependency_inventory({:ok, result}) do
    %{
      summary: Shared.dependency_summary(result),
      entries: Map.get(result, :entries, []),
      redacted_entries: Map.get(result, :redacted_entries, []),
      hidden_count: Map.get(result, :hidden_reference_count, 0),
      denied?: false
    }
  end

  defp normalize_dependency_inventory({:error, error}) do
    if auth_error?(error) do
      %{
        summary: "Dependency list unavailable",
        entries: [],
        redacted_entries: [],
        hidden_count: 0,
        denied?: true
      }
    else
      %{
        summary: "Dependency list unavailable",
        entries: [],
        redacted_entries: [],
        hidden_count: 0,
        denied?: false
      }
    end
  end

  defp hidden_reference_count({:ok, result}), do: Map.get(result, :hidden_reference_count, 0)
  defp hidden_reference_count(_), do: 0

  defp auth_error?(%{domain: :auth}), do: true
  defp auth_error?(%{domain: "auth"}), do: true
  defp auth_error?(_), do: false

  defp assessment_verdict(assessment) do
    verdict = fetch(assessment, :verdict)

    case verdict do
      v when v in [:above_threshold, :below_threshold, :indeterminate] -> v
      "above_threshold" -> :above_threshold
      "below_threshold" -> :below_threshold
      "indeterminate" -> :indeterminate
      _ -> :indeterminate
    end
  end

  defp top_breach_remediation(%{breach_reasons: [first | _]}) when is_map(first) do
    Map.get(first, :remediation) || Map.get(first, "remediation")
  end

  defp top_breach_remediation(_), do: nil

  defp affected_reference_keys(preview) do
    preview
    |> fetch(:affected_references)
    |> List.wrap()
    |> Enum.map(fn ref ->
      fetch(ref, :reference_key)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  defp preview_audience_key(preview, socket) do
    fetch(preview, :audience_key) || socket.assigns[:audience_key]
  end

  defp tenant_key(socket) do
    socket.assigns.current_tenant && socket.assigns.current_tenant.key
  end

  defp tenant_key_from_preview(preview) do
    scope = fetch(preview, :tenant_scope)

    case scope do
      %{tenant_key: key} -> key
      %{"tenant_key" => key} -> key
      _ -> nil
    end
  end

  defp normalize_operation(:update), do: "update"
  defp normalize_operation(:archive), do: "archive"
  defp normalize_operation(operation) when is_binary(operation), do: operation
  defp normalize_operation(operation) when is_atom(operation), do: Atom.to_string(operation)

  defp normalize_environment_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_environment_key(key), do: key

  defp fetch(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
