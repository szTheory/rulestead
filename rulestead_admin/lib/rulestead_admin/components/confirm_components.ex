defmodule RulesteadAdmin.Components.ConfirmComponents do
  @moduledoc """
  The shared mutation-confirm contract.

  Every governed mutation in the admin (audience edit/archive/delete, flag
  cleanup, kill switch, rollout advance/hold/rollback, change-request execution)
  follows one preview → confirm → audit shape. `mutation_confirm/1` is the
  confirm step's canonical affordance: an optional scope line, slots for
  evidence (blast radius, diffs) and extra fields (typed confirmation), a
  required reason, and a primary-or-danger submit paired with a back link.

  Standardizing this one component is the highest-leverage consistency win —
  every confirm screen reads and behaves identically instead of hand-rolling its
  own form markup.
  """

  use Phoenix.Component

  @doc """
  Renders the canonical confirm form: scope → evidence → extra fields → reason →
  actions.

  Drop governance evidence (blast radius, callouts) into the `:evidence` slot and
  any pre-reason inputs (e.g. a production typed-key confirmation) into the
  `:extra_fields` slot. The reason textarea and the submit/back actions are
  always rendered so confirm screens stay visually and behaviourally uniform.
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

  attr(:scope, :map,
    default: nil,
    doc: "optional %{environment:, tenant:, fingerprint:} context line"
  )

  slot(:evidence, doc: "blast radius / diff / callouts shown above the reason")
  slot(:extra_fields, doc: "inputs shown above the reason, e.g. typed confirmation")

  def mutation_confirm(assigns) do
    ~H"""
    <form
      phx-submit={@submit_event}
      aria-label={@aria_label}
      class="rs-mutation-confirm"
      data-danger={to_string(@danger?)}
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

      {render_slot(@extra_fields)}

      <label class="rs-form-field rs-mutation-confirm__reason">
        <span>{@reason_label}</span>
        <textarea name="reason" rows="3" required={@reason_required}><%= @reason_value %></textarea>
      </label>

      <div class="rs-mutation-confirm__actions">
        <a :if={@back_href} href={@back_href} class="rs-button rs-button--text">{@back_label}</a>
        <button
          type="submit"
          class={["rs-button", (@danger? && "rs-button--danger") || "rs-button--primary"]}
        >
          {@submit_label}
        </button>
      </div>
    </form>
    """
  end
end
