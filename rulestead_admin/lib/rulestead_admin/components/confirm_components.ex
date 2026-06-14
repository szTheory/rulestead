defmodule RulesteadAdmin.Components.ConfirmComponents do
  @moduledoc """
  The shared mutation-confirm contract.

  Every governed mutation in the admin (audience edit/archive/delete, flag
  cleanup, kill switch, rollout advance/hold/rollback, change-request execution)
  follows one preview → confirm → audit shape. `mutation_confirm/1` is the
  confirm step's canonical affordance: an optional scope line, slots for
  evidence (blast radius, diffs) and extra fields, optional first-class typed
  confirmation, a required reason, and a primary-or-danger submit paired with a
  back link.

  Standardizing this one component is the highest-leverage consistency win —
  every confirm screen reads and behaves identically instead of hand-rolling its
  own form markup.
  """

  use Phoenix.Component

  @doc """
  Renders the canonical confirm form: scope → evidence → typed confirmation →
  extra fields → reason → actions.

  Drop governance evidence (blast radius, callouts) into the `:evidence` slot and
  any custom pre-reason inputs into the `:extra_fields` slot. Prefer the typed
  confirmation assigns for production key checks so destructive confirmations
  render before the reason field consistently. The reason textarea and the
  submit/back actions are always rendered so confirm screens stay visually and
  behaviourally uniform.
  """
  attr(:submit_event, :string, required: true, doc: "phx-submit event name")
  attr(:submit_label, :string, required: true)
  attr(:reason_value, :string, default: "")
  attr(:reason_label, :string, default: "Reason (required)")
  attr(:reason_required, :boolean, default: true)
  attr(:back_href, :string, default: nil)
  attr(:back_label, :string, default: "Back")
  attr(:danger?, :boolean, default: false)
  attr(:aria_label, :string, default: "Confirm action")
  attr(:disabled?, :boolean, default: false)
  attr(:disabled_reason, :string, default: nil)
  attr(:unavailable_reason, :string, default: nil)
  attr(:read_only?, :boolean, default: false)
  attr(:read_only_reason, :string, default: nil)
  attr(:typed_confirmation_label, :string, default: nil)
  attr(:typed_confirmation_name, :string, default: "confirmation")
  attr(:typed_confirmation_value, :string, default: "")
  attr(:typed_confirmation_required, :boolean, default: false)
  attr(:typed_confirmation_help, :string, default: nil)

  attr(:scope, :map,
    default: nil,
    doc: "optional %{environment:, tenant:, fingerprint:} context line"
  )

  slot(:evidence, doc: "blast radius / diff / callouts shown above the reason")
  slot(:extra_fields, doc: "inputs shown above the reason, e.g. typed confirmation")

  def mutation_confirm(assigns) do
    blocked_state = mutation_confirm_blocked_state(assigns)

    assigns =
      assigns
      |> assign(:blocked_state, blocked_state)
      |> assign(:action_disabled?, not is_nil(blocked_state))

    ~H"""
    <form
      phx-submit={@submit_event}
      aria-label={@aria_label}
      class="rs-mutation-confirm"
      data-danger={to_string(@danger?)}
      data-state={if @blocked_state, do: @blocked_state.state, else: "actionable"}
    >
      <dl :if={@scope} class="rs-mutation-confirm__scope">
        <div :if={@scope[:fingerprint]}>
          <dt>Fingerprint</dt>
          <dd><code>{@scope.fingerprint}</code></dd>
        </div>
        <div>
          <dt>Scope</dt>
          <dd><code>{@scope.environment}</code></dd>
        </div>
        <div :if={@scope[:tenant]}>
          <dt>Tenant</dt>
          <dd><code>{@scope.tenant}</code></dd>
        </div>
      </dl>

      <div :if={@evidence != []} class="rs-mutation-confirm__evidence">
        {render_slot(@evidence)}
      </div>

      <section
        :if={@blocked_state}
        class="rs-mutation-confirm__state"
        data-tone={@blocked_state.tone}
        role="status"
      >
        <strong>{@blocked_state.title}</strong>
        <p>{@blocked_state.reason}</p>
      </section>

      <label :if={@typed_confirmation_label} class="rs-form-field rs-mutation-confirm__typed">
        <span>{@typed_confirmation_label}</span>
        <input
          type="text"
          name={@typed_confirmation_name}
          value={@typed_confirmation_value}
          required={@typed_confirmation_required and not @action_disabled?}
          disabled={@action_disabled?}
        />
        <p :if={@typed_confirmation_help} class="rs-field-help">
          {@typed_confirmation_help}
        </p>
      </label>

      {render_slot(@extra_fields)}

      <label class="rs-form-field rs-mutation-confirm__reason">
        <span>{@reason_label}</span>
        <textarea
          name="reason"
          rows="3"
          required={@reason_required and not @action_disabled?}
          disabled={@action_disabled?}
        ><%= @reason_value %></textarea>
      </label>

      <div class="rs-mutation-confirm__actions">
        <a :if={@back_href} href={@back_href} class="rs-button rs-button--text">{@back_label}</a>
        <button
          type="submit"
          class={["rs-button", (@danger? && "rs-button--danger") || "rs-button--primary"]}
          disabled={@action_disabled?}
        >
          {@submit_label}
        </button>
      </div>
    </form>
    """
  end

  defp mutation_confirm_blocked_state(assigns) do
    cond do
      Map.get(assigns, :read_only?) ->
        %{
          state: "read-only",
          title: "Read-only action",
          reason:
            first_present(
              Map.get(assigns, :read_only_reason),
              Map.get(assigns, :disabled_reason),
              "Current policy or state only allows review."
            ),
          tone: "warning"
        }

      present?(Map.get(assigns, :unavailable_reason)) ->
        %{
          state: "unavailable",
          title: "Action unavailable",
          reason: String.trim(Map.get(assigns, :unavailable_reason)),
          tone: "warning"
        }

      Map.get(assigns, :disabled?) ->
        %{
          state: "disabled",
          title: "Action disabled",
          reason:
            first_present(
              Map.get(assigns, :disabled_reason),
              "This action is disabled until the required evidence is available."
            ),
          tone: "warning"
        }

      true ->
        nil
    end
  end

  defp first_present(values) when is_list(values) do
    Enum.find_value(values, fn
      value when is_binary(value) ->
        value = String.trim(value)
        if value == "", do: nil, else: value

      _ ->
        nil
    end)
  end

  defp first_present(value, fallback), do: first_present([value, fallback])

  defp first_present(value, fallback, final_fallback),
    do: first_present([value, fallback, final_fallback])

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false
end
