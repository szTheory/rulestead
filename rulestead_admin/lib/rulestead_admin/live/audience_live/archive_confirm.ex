# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.ArchiveConfirm do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Store.Command

  alias RulesteadAdmin.Components.{
    ConfirmComponents,
    FlagComponents,
    GovernanceComponents,
    OperatorComponents,
    Shell
  }

  alias RulesteadAdmin.Live.{AudienceLive.Governance, AudienceLive.Shared, Session}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:audience_key, nil)
     |> assign(:preview, nil)
     |> assign(:error_message, nil)
     |> assign(:reason_value, "")
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})
     |> assign(:governance_mode, nil)
     |> assign(:visibility_tier, nil)
     |> assign(:blast_radius_assessment, nil)
     |> assign(:dependency_inventory, nil)
     |> assign(:governance_blocked_reason, nil)
     |> assign(:required_approvals, 0)
     |> assign(:self_approval_allowed?, true)
     |> assign(:can_submit?, false)}
  end

  @impl true
  def handle_params(%{"audience_key" => audience_key}, uri, socket) do
    query = Shared.query_params(uri)
    base_path = "#{Shared.audience_base(socket, audience_key)}/archive/confirm"

    socket =
      socket
      |> assign(:audience_key, audience_key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_preview(audience_key, query)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@audience_key, do: "#{@audience_key} archive confirm", else: "Archive confirm")}
      page_kicker="Archive confirm"
      page_summary="Archive only after preview evidence and an operator reason are recorded."
      base_path={@rulestead_admin_mount_path}
      current_section={:audiences}
      breadcrumbs={Shared.breadcrumbs(assigns, "Archive confirm")}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <FlagComponents.section_card :if={@preview} title="Confirm archive">
        <p><strong>Fingerprint:</strong> <code><%= @preview.preview_fingerprint %></code></p>
        <p><strong>Scope:</strong> <code><%= @current_environment.key %></code>
          <span :if={@current_tenant}> · tenant <code><%= @current_tenant.key %></code></span>
        </p>

        <GovernanceComponents.blast_radius_panel
          :if={@blast_radius_assessment && @governance_mode == :change_request}
          assessment={@blast_radius_assessment}
          variant={:operator}
          visibility={visibility_attr(@visibility_tier)}
          environment_label={@current_environment.name}
        />

        <FlagComponents.callout
          :if={@governance_mode == :blocked}
          title="Cannot evaluate safely"
          tone="critical"
        >
          <p>{@governance_blocked_reason || "Blast radius cannot be evaluated safely."}</p>
          <p :if={@dependency_inventory}>{@dependency_inventory.summary}</p>
        </FlagComponents.callout>

        <p :if={@governance_mode == :change_request && @required_approvals > 0}>
          <strong>Required approvals:</strong> <%= @required_approvals %>
        </p>
        <p :if={@governance_mode == :change_request}>
          <strong>Self-approval:</strong>
          <%= if @self_approval_allowed?, do: "You may approve your own request.", else: "You cannot approve your own request." %>
        </p>

        <OperatorComponents.capability_explanation
          :if={@governance_mode == :change_request && !@can_submit?}
          title="Change request required"
          reason="You do not have permission to submit a change request for this audience."
        />

        <ConfirmComponents.mutation_confirm
          :if={@governance_mode == :change_request && @can_submit?}
          submit_event="submit_change_request"
          submit_label="Submit change request"
          reason_value={@reason_value}
          back_href={Shared.path(assigns, "/audiences/#{@audience_key}/archive/preview")}
          back_label="Back to preview"
          aria_label="Submit audience archive change request"
        />

        <ConfirmComponents.mutation_confirm
          :if={show_apply_form?(@governance_mode)}
          submit_event="apply"
          submit_label="Apply archive"
          reason_value={@reason_value}
          danger?={true}
          back_href={Shared.path(assigns, "/audiences/#{@audience_key}/archive/preview")}
          back_label="Back to preview"
          aria_label="Confirm audience archive"
        />

        <p :if={no_confirm_form?(@governance_mode, @can_submit?)}>
          <.link navigate={Shared.path(assigns, "/audiences/#{@audience_key}/archive/preview")}>
            Back to preview
          </.link>
        </p>
      </FlagComponents.section_card>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("apply", %{"reason" => reason}, socket) do
    reason = String.trim(reason)

    with :ok <- validate_reason(reason),
         {:ok, preview} <- ensure_preview(socket),
         :ok <- ensure_apply_allowed(socket),
         {:ok, _result} <- Rulestead.apply_audience_mutation(apply_attrs(socket, preview, reason)) do
      {:noreply,
       socket
       |> put_flash(:info, "Audience archived.")
       |> push_navigate(to: Shared.path(socket, "/audiences/#{socket.assigns.audience_key}"))}
    else
      {:error, :missing_reason} ->
        {:noreply, assign(socket, :error_message, "Reason is required.")}

      {:error, :missing_preview} ->
        {:noreply, assign(socket, :error_message, "Run impact preview before confirming.")}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, :error_message, message)}

      {:error, error} ->
        if Shared.stale_preview_error?(error) do
          {:noreply,
           push_navigate(socket,
             to:
               Shared.path(
                 socket,
                 "/audiences/#{socket.assigns.audience_key}/archive/preview?drifted=true"
               )
           )}
        else
          {:noreply, assign(socket, :error_message, error.message)}
        end
    end
  end

  @impl true
  def handle_event("submit_change_request", %{"reason" => reason}, socket) do
    reason = String.trim(reason)
    audience_key = socket.assigns.audience_key

    with :ok <- validate_reason(reason),
         {:ok, preview} <- ensure_preview(socket),
         :ok <- Governance.ensure_governance_mode(socket, :change_request),
         approval_requirement <-
           Governance.build_approval_requirement(socket, :apply_audience_mutation, audience_key),
         command_map <- Governance.audience_mutation_command_map(socket, preview, nil, :archive),
         {:ok, %{change_request: change_request}} <-
           Rulestead.submit_change_request(
             Command.SubmitChangeRequest.new(
               %{
                 action: :apply_audience_mutation,
                 environment_key: socket.assigns.current_environment.key,
                 resource_type: "audience",
                 resource_key: audience_key,
                 command: command_map,
                 approval_requirement: approval_requirement
               },
               actor: socket.assigns.current_actor,
               reason: reason
             )
           ) do
      {:noreply,
       socket
       |> put_flash(
         :info,
         "Change request submitted. Audience archive is unchanged until this request is approved and executed."
       )
       |> push_navigate(
         to:
           Session.current_path(
             socket,
             "#{Shared.mount_path(socket)}/change-requests/#{change_request.id}"
           )
       )}
    else
      {:error, :missing_preview} ->
        {:noreply, assign(socket, :error_message, "Run impact preview before confirming.")}

      {:error, :missing_reason} ->
        {:noreply, assign(socket, :error_message, "Reason is required.")}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, :error_message, message)}

      {:error, error} ->
        {:noreply, assign(socket, :error_message, error.message)}
    end
  end

  defp load_preview(socket, audience_key, query) do
    fingerprint = blank_to_nil(query["preview_fingerprint"])
    schema_version = blank_to_nil(query["preview_schema_version"])

    cond do
      is_nil(fingerprint) or is_nil(schema_version) ->
        assign(socket, preview: nil, error_message: "Run impact preview before confirming.")

      true ->
        opts =
          Shared.scope_opts(socket)
          |> Keyword.merge(
            preview_fingerprint: fingerprint,
            preview_schema_version: schema_version,
            reason: "Mounted archive confirm"
          )

        case Rulestead.preview_audience_impact(audience_key, :archive, opts) do
          {:ok, preview} ->
            socket
            |> assign(:preview, preview)
            |> assign(:error_message, nil)
            |> Governance.load_governance_context(preview, operation: :archive)
            |> Governance.merge_approval_expectations(audience_key)

          {:error, error} ->
            assign(socket, preview: nil, error_message: error.message)
        end
    end
  end

  defp apply_attrs(socket, preview, reason) do
    %{
      environment_key: socket.assigns.current_environment.key,
      tenant_key: socket.assigns.current_tenant && socket.assigns.current_tenant.key,
      audience_key: socket.assigns.audience_key,
      operation: :archive,
      preview_schema_version: preview.preview_schema_version,
      preview_fingerprint: preview.preview_fingerprint,
      preview_basis: preview.preview_basis,
      affected_reference_keys:
        Enum.map(List.wrap(preview.affected_references), fn ref ->
          ref[:reference_key] || ref["reference_key"]
        end),
      actor: socket.assigns.current_actor,
      reason: reason
    }
  end

  defp ensure_preview(%{assigns: %{preview: %{} = preview}}), do: {:ok, preview}
  defp ensure_preview(_socket), do: {:error, :missing_preview}

  defp validate_reason(""), do: {:error, :missing_reason}
  defp validate_reason(_), do: :ok

  defp ensure_apply_allowed(%{assigns: %{governance_mode: mode}})
       when mode in [:unrestricted, :direct_apply],
       do: :ok

  defp ensure_apply_allowed(_socket),
    do: {:error, "Direct apply is not available for the current governance state."}

  defp show_apply_form?(mode) when mode in [:unrestricted, :direct_apply], do: true
  defp show_apply_form?(_), do: false

  defp no_confirm_form?(:change_request, can_submit?), do: not can_submit?
  defp no_confirm_form?(mode, _can_submit?), do: not show_apply_form?(mode)

  defp visibility_attr(:full), do: :full
  defp visibility_attr(_), do: :redacted

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
