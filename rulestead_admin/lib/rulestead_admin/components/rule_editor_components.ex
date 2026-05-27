defmodule RulesteadAdmin.Components.RuleEditorComponents do
  @moduledoc false

  use Phoenix.Component

  attr :detail, :map, required: true
  attr :editable?, :boolean, required: true
  attr :status_message, :string, default: nil

  def lifecycle_banner(assigns) do
    ~H"""
    <section class="rs-rule-banner" aria-label="Rules workspace status">
      <p :if={@detail.has_draft_ruleset? and @editable?}>
        <strong>Draft ruleset ready</strong>
        <span> Version <%= List.first(@detail.draft_rulesets).version %> is saved but not live yet.</span>
      </p>
      <p :if={!@detail.has_draft_ruleset? and @editable?}>
        <strong>No draft ruleset yet.</strong>
        <span> Save draft to keep editing separate from publish.</span>
      </p>
      <p :if={!@editable?}>
        <strong>This flag is archived.</strong>
        <span> Rules are read-only and excluded from runtime evaluation.</span>
      </p>
      <p :if={@status_message} role="status"><%= @status_message %></p>
    </section>
    """
  end

  attr :error_messages, :list, default: []
  attr :editable?, :boolean, required: true

  def validation_notices(assigns) do
    ~H"""
    <section :if={@error_messages != []} class="rs-rule-errors" aria-label="Rules validation">
      <p :for={message <- @error_messages} role="alert"><%= message %></p>
    </section>
    """
  end

  attr :detail, :map, required: true
  attr :editable?, :boolean, required: true
  attr :error_messages, :list, default: []

  def action_bar(assigns) do
    ~H"""
    <section class="rs-rule-actions" aria-label="Draft and publish actions">
      <h3>Draft and publish</h3>
      <p>Save draft and publish remain separate actions so operators can stage work safely.</p>
      <button :if={@editable?} type="button" phx-click="save_draft">Save draft</button>
      <button :if={@editable?} type="button" phx-click="publish">Publish</button>
      <button :if={@editable?} type="button" phx-click="archive_flag">Archive flag</button>
      <p>Active ruleset: <%= active_version(@detail) %></p>
      <p>Draft ruleset: <%= draft_version(@detail) %></p>
    </section>
    """
  end

  attr :audiences, :list, default: []
  attr :mount_path, :string, default: nil

  def audience_library(assigns) do
    ~H"""
    <section class="rs-audience-library" aria-label="Audience library">
      <h3>Audience library</h3>
      <p>Audience targeting references shared definitions instead of repeating inline conditions.</p>
      <ul>
        <li :for={audience <- @audiences}>
          <strong><%= audience.key %></strong>
          <span :if={Map.get(audience, :description)}> <%= Map.get(audience, :description) %></span>
          <span :if={Map.get(audience, :archived_at)}> (archived)</span>
          <a :if={@mount_path} href={"#{@mount_path}/audiences/#{audience.key}"}>View audience <%= audience.key %></a>
        </li>
        <li :if={@audiences == []}>No reusable audiences available.</li>
      </ul>
    </section>
    """
  end

  attr :index, :integer, required: true
  attr :rule, :map, required: true
  attr :audiences, :list, default: []
  attr :mount_path, :string, default: nil
  attr :editable?, :boolean, required: true

  def rule_card(assigns) do
    ~H"""
    <article class="rs-rule-card" data-role="rule-card" data-rule-key={@rule["key"]}>
      <header class="rs-rule-card__header">
        <div>
          <h4><%= @rule["name"] |> blank_to_fallback(@rule["key"]) %></h4>
          <p>Strategy: <%= humanize(@rule["strategy"]) %></p>
          <p :if={@rule["strategy"] == "segment_match"}>
            Audience:
            <code><%= @rule["audience_key"] || "not selected" %></code>
            <span :if={missing_audience?(@rule, @audiences)} role="alert">
              — Audience not found in snapshot — pick another audience or remove the reference before publish.
            </span>
            <a :if={@mount_path && @rule["audience_key"]} href={"#{@mount_path}/audiences/#{@rule["audience_key"]}"}>
              View audience <%= @rule["audience_key"] %>
            </a>
          </p>
        </div>
        <div class="rs-rule-card__moves">
          <button
            :if={@editable?}
            type="button"
            phx-click="move_rule"
            phx-value-key={@rule["key"]}
            phx-value-direction="up"
          >
            Move up
          </button>
          <button
            :if={@editable?}
            type="button"
            phx-click="move_rule"
            phx-value-key={@rule["key"]}
            phx-value-direction="down"
          >
            Move down
          </button>
        </div>
      </header>

      <div class="rs-rule-card__fields">
        <label>
          <span>Rule key</span>
          <input type="text" name={"ruleset[rules][#{@index}][key]"} value={@rule["key"]} readonly={!@editable?} />
        </label>

        <label>
          <span>Rule name</span>
          <input type="text" name={"ruleset[rules][#{@index}][name]"} value={@rule["name"]} readonly={!@editable?} />
        </label>

        <label>
          <span>Strategy</span>
          <select name={"ruleset[rules][#{@index}][strategy]"} disabled={!@editable?}>
            <option :for={strategy <- ["forced_value", "segment_match", "variant_split"]} value={strategy} selected={@rule["strategy"] == strategy}>
              <%= humanize(strategy) %>
            </option>
          </select>
        </label>

        <label>
          <span>Resolved value</span>
          <select name={"ruleset[rules][#{@index}][value]"} disabled={!@editable?}>
            <option value="true" selected={@rule["value"] == "true"}>true</option>
            <option value="false" selected={@rule["value"] == "false"}>false</option>
          </select>
        </label>
      </div>

      <.audience_picker index={@index} rule={@rule} audiences={@audiences} editable?={@editable?} />
      <.condition_builder rule={@rule} />
      <.variant_editor index={@index} rule={@rule} editable?={@editable?} />
    </article>
    """
  end

  attr :index, :integer, required: true
  attr :rule, :map, required: true
  attr :audiences, :list, default: []
  attr :editable?, :boolean, required: true

  def audience_picker(assigns) do
    ~H"""
    <section class="rs-rule-audience">
      <label>
        <span>Reusable audience</span>
        <select
          aria-label="Reusable audience"
          name={"ruleset[rules][#{@index}][audience_key]"}
          disabled={!@editable?}
        >
          <option value="">Choose audience</option>
          <option :for={audience <- @audiences} value={audience.key} selected={@rule["audience_key"] == audience.key}>
            <%= audience.key %>
          </option>
        </select>
      </label>
    </section>
    """
  end

  attr :rule, :map, required: true

  def condition_builder(assigns) do
    ~H"""
    <section class="rs-rule-conditions" aria-label="Condition builder">
      <h5>Condition builder</h5>
      <p :if={@rule["conditions"] == []}>No inline conditions configured. Use reusable audience targeting when possible.</p>
      <ul :if={@rule["conditions"] != []}>
        <li :for={condition <- @rule["conditions"]}>
          <%= condition[:attribute] || condition["attribute"] %> <%= condition[:operator] || condition["operator"] %>
        </li>
      </ul>
    </section>
    """
  end

  attr :index, :integer, required: true
  attr :rule, :map, required: true
  attr :editable?, :boolean, required: true

  def variant_editor(assigns) do
    ~H"""
    <section class="rs-rule-variants" aria-label="Variant editor">
      <h5>Variant editor</h5>
      <p :if={@rule["strategy"] != "variant_split"}>Variant weights are only used for variant split rules.</p>
      <div :if={@rule["strategy"] == "variant_split"}>
        <div :for={{variant, variant_index} <- Enum.with_index(@rule["variants"])} class="rs-rule-variants__row">
          <label>
            <span>Variant key</span>
            <input type="text" name={"ruleset[rules][#{@index}][variants][#{variant_index}][key]"} value={variant["key"]} readonly={!@editable?} />
          </label>
          <label>
            <span>Variant value</span>
            <select name={"ruleset[rules][#{@index}][variants][#{variant_index}][value]"} disabled={!@editable?}>
              <option value="true" selected={variant["value"] == "true"}>true</option>
              <option value="false" selected={variant["value"] == "false"}>false</option>
            </select>
          </label>
          <label>
            <span>Weight</span>
            <input type="number" name={"ruleset[rules][#{@index}][variants][#{variant_index}][weight]"} value={variant["weight"]} readonly={!@editable?} />
          </label>
        </div>
      </div>
    </section>
    """
  end

  defp draft_version(detail) do
    case detail.draft_rulesets do
      [draft | _rest] -> "Version #{draft.version}"
      [] -> "No draft"
    end
  end

  defp active_version(detail) do
    case detail.active_ruleset do
      nil -> "No active ruleset"
      ruleset -> "Version #{ruleset.version}"
    end
  end

  defp humanize(value) when is_atom(value), do: humanize(Atom.to_string(value))
  defp humanize(value) when is_binary(value), do: value |> String.replace("_", " ") |> String.capitalize()
  defp humanize(value), do: to_string(value)

  defp blank_to_fallback(nil, fallback), do: fallback

  defp blank_to_fallback(value, fallback) when is_binary(value) do
    if String.trim(value) == "", do: fallback, else: value
  end

  defp blank_to_fallback(value, _fallback), do: value

  defp missing_audience?(%{"strategy" => "segment_match", "audience_key" => key}, audiences)
       when is_binary(key) do
    not Enum.any?(audiences, fn audience ->
      audience.key == key and is_nil(Map.get(audience, :archived_at))
    end)
  end

  defp missing_audience?(_rule, _audiences), do: false
end
