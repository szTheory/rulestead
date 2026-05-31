defmodule RulesteadAdmin.Components.AuditComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:active?, :boolean, required: true)
  attr(:flag_key, :string, required: true)
  attr(:environment_name, :string, required: true)
  attr(:reason, :string, default: nil)
  attr(:kill_path, :string, required: true)
  attr(:timeline_path, :string, required: true)
  attr(:show_release_button, :boolean, default: false)

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

  attr(:mode, :atom, required: true)
  attr(:flag_key, :string, required: true)
  attr(:production?, :boolean, required: true)
  attr(:confirmation_value, :string, default: "")
  attr(:reason_value, :string, default: "")
  attr(:error, :string, default: nil)

  def kill_switch_form(assigns) do
    assigns =
      assign(assigns,
        title: if(assigns.mode == :engage, do: "Engage kill switch", else: "Release kill switch"),
        event: if(assigns.mode == :engage, do: "engage", else: "release"),
        submit_label:
          if(assigns.mode == :engage, do: "Confirm kill switch", else: "Confirm release")
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

  attr(:entry, :map, required: true)
  attr(:show_flag, :boolean, default: false)
  attr(:show_rollback, :boolean, default: false)

  def timeline_item(assigns) do
    assigns =
      assigns
      |> assign(:event_id, "audit-event-#{assigns.entry.id}")
      |> assign(:automatic?, Map.get(assigns.entry, :automatic?, false))
      |> assign(:rollout_event?, rollout_event?(assigns.entry))

    ~H"""
    <li class="rs-event-timeline__item" data-result={@entry.result} data-automatic={@automatic?}>
      <div class="rs-event-timeline__time">
        <time datetime={Map.get(@entry, :occurred_at_iso)}>
          {Map.get(@entry, :occurred_at_label) || "Unknown time"}
        </time>
        <span>{Map.get(@entry, :environment_key) || "Unknown env"}</span>
      </div>

      <div class="rs-event-timeline__marker" aria-hidden="true"></div>

      <article class="rs-event-panel" aria-labelledby={@event_id}>
        <header class="rs-event-panel__header">
          <div>
            <h3 id={@event_id}>{@entry.title}</h3>
            <p>{@entry.summary}</p>
          </div>
          <span class="rs-event-panel__result" data-result={@entry.result}>
            {result_label(@entry.result)}
          </span>
        </header>

        <div class="rs-event-panel__meta" aria-label={"Audit metadata for #{@entry.title}"}>
          <span>{Map.get(@entry, :actor_label) || "Unknown actor"}</span>
          <span :if={@automatic?}>
            Automatic<span :if={Map.get(@entry, :source_label)}> source {@entry.source_label}</span>
          </span>
          <span :if={!@automatic? and @rollout_event?}>Manual rollout action</span>
          <span :if={Map.get(@entry, :resource_key)}>Flag <code>{@entry.resource_key}</code></span>
        </div>

        <p :if={@entry.reason} class="rs-event-panel__reason">
          <strong>Reason</strong>
          <span>{@entry.reason}</span>
        </p>

        <p :if={@entry.rollback_of_event_id} class="rs-event-panel__link">
          Rollback of audit event <code>{@entry.rollback_of_event_id}</code>
        </p>

        <div class="rs-event-panel__actions">
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

        <.readable_diff
          :if={Map.get(@entry, :show_diff?, false)}
          entry={@entry}
          structured_label="Review before / after"
        />

        <.raw_detail entry={@entry} />
      </article>
    </li>
    """
  end

  def timeline_row(assigns) do
    assigns =
      assigns
      |> assign_new(:show_flag, fn -> false end)
      |> assign_new(:show_rollback, fn -> false end)

    ~H"""
    <article class="rs-card rs-audit-row" data-result={@entry.result}>
      <header>
        <h3>{@entry.title}</h3>
        <p>{@entry.meta}</p>
      </header>

      <p :if={Map.get(@entry, :automatic?, false)} class="rs-audit-row__source">
        Automatic<span :if={Map.get(@entry, :source_label)}> source {@entry.source_label}</span>
      </p>
      <p
        :if={
          !Map.get(@entry, :automatic?, false) and
            String.starts_with?(to_string(@entry.raw.event.event_type), "rollout.")
        }
        class="rs-audit-row__source"
      >
        Manual rollout action
      </p>
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

      <.raw_detail entry={@entry} />
    </article>
    """
  end

  attr(:entry, :map, required: true)

  def raw_detail(assigns) do
    assigns = assign(assigns, :tokens, json_tokens(assigns.entry.raw))

    ~H"""
    <details class="rs-raw-detail" aria-label={"Raw detail for #{@entry.title}"}>
      <summary>Show raw detail</summary>
      <pre><code class="rs-json" aria-label={"JSON raw detail for #{@entry.title}"}><span
        :for={token <- @tokens}
        class={"rs-json-token rs-json-token--#{token.type}"}
      >{token.value}</span></code></pre>
    </details>
    """
  end

  attr(:entry, :map, required: true)
  attr(:source_label, :string, default: "Before")
  attr(:current_target_label, :string, default: nil)
  attr(:proposed_target_label, :string, default: "After")
  attr(:structured_label, :string, default: "Readable diff")

  def diff_card(assigns) do
    ~H"""
    <details class="rs-readable-diff" aria-label={@structured_label}>
      <summary>{@structured_label}</summary>
      <section class="rs-diff-card" aria-label={"Diff for #{@entry.title}"}>
        <.diff_values
          entry={@entry}
          source_label={@source_label}
          current_target_label={@current_target_label}
          proposed_target_label={@proposed_target_label}
        />
      </section>
    </details>
    """
  end

  attr(:entry, :map, required: true)
  attr(:source_label, :string, default: "Before")
  attr(:current_target_label, :string, default: nil)
  attr(:proposed_target_label, :string, default: "After")
  attr(:structured_label, :string, default: "Readable diff")

  def readable_diff(assigns) do
    ~H"""
    <details class="rs-readable-diff" aria-label={@structured_label}>
      <summary>{@structured_label}</summary>
      <section class="rs-diff-card rs-diff-card--inline" aria-label={"Diff for #{@entry.title}"}>
        <.diff_values
          entry={@entry}
          source_label={@source_label}
          current_target_label={@current_target_label}
          proposed_target_label={@proposed_target_label}
        />
      </section>
    </details>
    """
  end

  attr(:entry, :map, required: true)
  attr(:source_label, :string, required: true)
  attr(:current_target_label, :string, default: nil)
  attr(:proposed_target_label, :string, required: true)

  defp diff_values(assigns) do
    ~H"""
    <div class="rs-diff-card__values">
      <div class="rs-diff-card__value">
        <p>{@source_label}</p>
        <code>{Map.get(@entry, :source_summary) || Map.get(@entry, :before_summary) || "No recorded state"}</code>
      </div>
      <div :if={@current_target_label} class="rs-diff-card__value">
        <p>{@current_target_label}</p>
        <code>{Map.get(@entry, :current_target_summary) || "Not available"}</code>
      </div>
      <div :if={!@current_target_label} class="rs-diff-card__transition" aria-hidden="true">&rarr;</div>
      <div class="rs-diff-card__value">
        <p>{@proposed_target_label}</p>
        <code>{Map.get(@entry, :proposed_target_summary) || Map.get(@entry, :after_summary) || "No recorded state"}</code>
      </div>
    </div>
    <ul :if={Map.get(@entry, :diff_lines, []) != []} class="rs-diff-card__positions">
      <li :for={line <- Map.get(@entry, :diff_lines, [])}>{line}</li>
    </ul>
    """
  end

  defp rollout_event?(entry) do
    entry
    |> get_in([:raw, :event, :event_type])
    |> to_string()
    |> String.starts_with?("rollout.")
  end

  defp result_label(:ok), do: "OK"
  defp result_label("ok"), do: "OK"
  defp result_label(:denied), do: "Denied"
  defp result_label("denied"), do: "Denied"
  defp result_label(result), do: result |> to_string() |> String.upcase()

  defp json_tokens(value) do
    value
    |> normalize_json_value()
    |> Jason.encode!(pretty: true)
    |> tokenize_json([])
  end

  defp normalize_json_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp normalize_json_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp normalize_json_value(%Date{} = value), do: Date.to_iso8601(value)
  defp normalize_json_value(%Time{} = value), do: Time.to_iso8601(value)

  defp normalize_json_value(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested_value} ->
      {to_string(key), normalize_json_value(nested_value)}
    end)
    |> Map.new()
  end

  defp normalize_json_value(value) when is_list(value),
    do: Enum.map(value, &normalize_json_value/1)

  defp normalize_json_value(value) when is_atom(value) and value in [true, false, nil], do: value
  defp normalize_json_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_json_value(value), do: value

  defp tokenize_json("", tokens), do: Enum.reverse(tokens)

  defp tokenize_json(<<"\"", _rest::binary>> = json, tokens) do
    {value, rest} = take_json_string(json)
    type = if json_key?(rest), do: "key", else: "string"
    tokenize_json(rest, [%{type: type, value: value} | tokens])
  end

  defp tokenize_json(<<char::utf8, _rest::binary>> = json, tokens)
       when char in [?\s, ?\n, ?\r, ?\t] do
    {value, rest} = take_while(json, &(&1 in [?\s, ?\n, ?\r, ?\t]))
    tokenize_json(rest, [%{type: "space", value: value} | tokens])
  end

  defp tokenize_json(<<"true", rest::binary>>, tokens),
    do: tokenize_json(rest, [%{type: "boolean", value: "true"} | tokens])

  defp tokenize_json(<<"false", rest::binary>>, tokens),
    do: tokenize_json(rest, [%{type: "boolean", value: "false"} | tokens])

  defp tokenize_json(<<"null", rest::binary>>, tokens),
    do: tokenize_json(rest, [%{type: "null", value: "null"} | tokens])

  defp tokenize_json(<<char::utf8, _rest::binary>> = json, tokens)
       when char in [?-, ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9] do
    {value, rest} =
      take_while(json, &(&1 in [?-, ?+, ?., ?e, ?E, ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9]))

    tokenize_json(rest, [%{type: "number", value: value} | tokens])
  end

  defp tokenize_json(<<char::utf8, rest::binary>>, tokens) do
    tokenize_json(rest, [%{type: "punctuation", value: <<char::utf8>>} | tokens])
  end

  defp take_json_string(<<"\"", rest::binary>>), do: take_json_string(rest, ["\""])

  defp take_json_string(<<"\\", char::utf8, rest::binary>>, acc),
    do: take_json_string(rest, [<<"\\", char::utf8>> | acc])

  defp take_json_string(<<"\"", rest::binary>>, acc),
    do: {acc |> Enum.reverse() |> IO.iodata_to_binary() |> Kernel.<>("\""), rest}

  defp take_json_string(<<char::utf8, rest::binary>>, acc),
    do: take_json_string(rest, [<<char::utf8>> | acc])

  defp json_key?(rest), do: rest |> String.trim_leading() |> String.starts_with?(":")

  defp take_while(binary, predicate), do: take_while(binary, predicate, [])

  defp take_while(<<char::utf8, rest::binary>>, predicate, acc) do
    if predicate.(char) do
      take_while(rest, predicate, [<<char::utf8>> | acc])
    else
      {acc |> Enum.reverse() |> IO.iodata_to_binary(), <<char::utf8, rest::binary>>}
    end
  end

  defp take_while("", _predicate, acc), do: {acc |> Enum.reverse() |> IO.iodata_to_binary(), ""}
end
