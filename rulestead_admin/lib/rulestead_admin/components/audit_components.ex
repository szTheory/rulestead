defmodule RulesteadAdmin.Components.AuditComponents do
  @moduledoc false

  use Phoenix.Component

  attr :active?, :boolean, required: true
  attr :flag_key, :string, required: true
  attr :environment_name, :string, required: true
  attr :reason, :string, default: nil
  attr :kill_path, :string, required: true
  attr :timeline_path, :string, required: true
  attr :show_release_button, :boolean, default: false

  def kill_switch_banner(assigns) do
    ~H"""
    <section
      class="rs-banner rs-banner--kill-switch"
      data-tone={if(@active?, do: "critical", else: "neutral")}
      aria-label="Kill switch state"
    >
      <h2>{if(@active?, do: "Kill switch active", else: "Kill switch inactive")}</h2>
      <p :if={@active?}>
        <code>{@flag_key}</code> is forcing authored evaluation back to the default value in
        {@environment_name}.
      </p>
      <p :if={!@active?}>
        No environment override is active for <code>{@flag_key}</code> in {@environment_name}.
      </p>
      <p :if={@reason} class="rs-banner__meta">Latest reason: {@reason}</p>
      <div class="rs-banner__actions">
        <a href={@kill_path}>{if(@active?, do: "Open kill switch", else: "Engage kill switch")}</a>
        <a href={@timeline_path}>Open audit timeline</a>
        <button :if={@show_release_button} type="button" phx-click="release_kill_switch">
          Release kill switch
        </button>
      </div>
    </section>
    """
  end

  attr :mode, :atom, required: true
  attr :flag_key, :string, required: true
  attr :production?, :boolean, required: true
  attr :confirmation_value, :string, default: ""
  attr :reason_value, :string, default: ""
  attr :error, :string, default: nil

  def kill_switch_form(assigns) do
    assigns =
      assign(assigns,
        title: if(assigns.mode == :engage, do: "Engage kill switch", else: "Release kill switch"),
        event: if(assigns.mode == :engage, do: "engage", else: "release"),
        submit_label: if(assigns.mode == :engage, do: "Confirm kill switch", else: "Confirm release")
      )

    ~H"""
    <form phx-submit={@event} aria-label={"Kill switch #{@event} form"}>
      <label>
        Reason
        <textarea name="reason" aria-label="Reason" rows="3"><%= @reason_value %></textarea>
      </label>

      <label :if={@production?}>
        Type the flag key to confirm production action
        <input
          type="text"
          name="confirmation"
          value={@confirmation_value}
          aria-label="Type the flag key to confirm production action"
        />
      </label>

      <p class="rs-confirmation-hint">
        <%= if @production? do %>
          Production requires an exact typed-key confirmation for <code>{@flag_key}</code>.
        <% else %>
          Non-production still requires an operator reason, but not typed-key confirmation.
        <% end %>
      </p>

      <p :if={@error} role="alert">{@error}</p>

      <button type="submit">{@submit_label}</button>
    </form>
    """
  end

  attr :entry, :map, required: true
  attr :show_flag, :boolean, default: false
  attr :show_rollback, :boolean, default: false

  def timeline_row(assigns) do
    ~H"""
    <article class="rs-card rs-audit-row" data-result={@entry.result}>
      <header>
        <h3>{@entry.title}</h3>
        <p>{@entry.meta}</p>
      </header>

      <p>{@entry.summary}</p>
      <p :if={@show_flag} class="rs-audit-row__flag">Flag: <code>{@entry.resource_key}</code></p>
      <p :if={@entry.reason} class="rs-audit-row__reason">Reason: {@entry.reason}</p>
      <p :if={@entry.rollback_of_event_id} class="rs-audit-row__link">
        Rollback of audit event <code>{@entry.rollback_of_event_id}</code>
      </p>

      <div class="rs-audit-row__actions">
        <button
          :if={@show_rollback}
          type="button"
          phx-click="rollback"
          phx-value-id={@entry.id}
          aria-label={"Rollback #{@entry.title}"}
        >
          Roll back with inverse write
        </button>
      </div>

      <details aria-label={"Raw detail for #{@entry.title}"}>
        <summary>Show raw detail</summary>
        <pre>{inspect(@entry.raw, pretty: true)}</pre>
      </details>
    </article>
    """
  end

  attr :entry, :map, required: true

  def diff_card(assigns) do
    ~H"""
    <section class="rs-diff-card" aria-label={"Diff for #{@entry.title}"}>
      <h4>Readable diff</h4>
      <div class="rs-diff-card__values">
        <div>
          <p>Before</p>
          <code>{@entry.before_summary}</code>
        </div>
        <div>
          <p>After</p>
          <code>{@entry.after_summary}</code>
        </div>
      </div>
      <ul :if={Map.get(@entry, :diff_lines, []) != []} class="rs-diff-card__positions">
        <li :for={line <- @entry.diff_lines}>{line}</li>
      </ul>
    </section>
    """
  end
end
