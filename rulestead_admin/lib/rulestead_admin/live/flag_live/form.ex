# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Form do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.LifecycleDefaults
  alias RulesteadAdmin.Components.{FlagComponents, Shell}

  @owner_kind_options [
    {"Person", "person"},
    {"Team", "team"},
    {"Service", "service"}
  ]

  @flag_type_options [
    {"Release", "release"},
    {"Experiment", "experiment"},
    {"Kill switch", "kill_switch"},
    {"Permission", "permission"},
    {"Remote config", "remote_config"},
    {"Operational", "operational"},
    {"Migration", "migration"}
  ]

  @value_type_options [
    {"Boolean", "boolean"},
    {"String", "string"},
    {"Integer", "integer"},
    {"Float", "float"},
    {"JSON", "json"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:mode, :new)
     |> assign(:flag_key, nil)
     |> assign(:errors, %{})
     |> assign(:submitted?, false)
     |> assign(:touched_fields, MapSet.new())
     |> assign(:current_path, "/admin/flags/new")
     |> assign(:env_links, %{})
     |> assign(:owner_kind_options, @owner_kind_options)
     |> assign(:flag_type_options, @flag_type_options)
     |> assign(:value_type_options, @value_type_options)
     |> assign(:owner_picker_options, owner_picker_options())
     |> assign_form_state(default_form_data())}
  end

  @impl true
  def handle_params(params, uri, socket) do
    if not socket.assigns.rulestead_admin_policy_state.capabilities.edit? do
      {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
    else
      env = query_params(uri)["env"] || socket.assigns.current_environment.key

      socket =
        case socket.assigns.live_action do
          :new ->
            socket
            |> assign(:mode, :new)
            |> assign(:flag_key, nil)
            |> assign(:errors, %{})
            |> assign(:submitted?, false)
            |> assign(:touched_fields, MapSet.new())
            |> assign(:current_path, "/admin/flags/new?env=#{env}")
            |> assign_form_state(Map.put(default_form_data(), "environment_keys", [env]))

          :edit ->
            load_edit(socket, params["key"], env)
        end

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"flag" => attrs}, socket) do
    form_data =
      socket.assigns.form_data
      |> merge_form_data(attrs)
      |> apply_picker_defaults(socket.assigns.owner_picker_options)

    errors =
      form_data
      |> validate(socket.assigns.mode)
      |> visible_errors(socket.assigns.submitted?, socket.assigns.touched_fields)

    {:noreply, socket |> assign(:errors, errors) |> assign_form_state(form_data)}
  end

  @impl true
  def handle_event("touch_field", %{"field" => field}, socket) do
    touched_fields = MapSet.put(socket.assigns.touched_fields, field)

    errors =
      socket.assigns.form_data
      |> validate(socket.assigns.mode)
      |> visible_errors(socket.assigns.submitted?, touched_fields)

    {:noreply, socket |> assign(:touched_fields, touched_fields) |> assign(:errors, errors)}
  end

  @impl true
  def handle_event("save", %{"flag" => attrs}, socket) do
    form_data =
      socket.assigns.form_data
      |> merge_form_data(attrs)
      |> apply_picker_defaults(socket.assigns.owner_picker_options)

    errors = validate(form_data, socket.assigns.mode)

    if map_size(errors) > 0 do
      {:noreply,
       socket
       |> assign(:submitted?, true)
       |> assign(:errors, errors)
       |> assign_form_state(form_data)}
    else
      case persist(
             socket.assigns.mode,
             socket.assigns.flag_key,
             form_data,
             socket.assigns.current_actor
           ) do
        {:ok, payload} ->
          {:noreply,
           socket
           |> assign(:errors, %{})
           |> assign(:submitted?, false)
           |> assign_form_state(to_form_data(payload.flag))
           |> put_flash(:info, success_flash(socket.assigns.mode, payload.flag.key))
           |> redirect(
             to: "/admin/flags/#{payload.flag.key}?env=#{socket.assigns.current_environment.key}"
           )}

        {:error, error} ->
          {:noreply,
           socket
           |> assign(:submitted?, true)
           |> assign(:errors, %{"base" => error.message})
           |> assign_form_state(form_data)}
      end
    end
  end

  @impl true
  def handle_event("set_review_by", %{"days" => days}, socket) do
    form_data =
      socket.assigns.form_data
      |> Map.put("review_by", review_date_in(days))

    {:noreply,
     socket
     |> assign(:touched_fields, MapSet.put(socket.assigns.touched_fields, "review_by"))
     |> assign(:errors, Map.delete(socket.assigns.errors, "review_by"))
     |> assign_form_state(form_data)}
  end

  @impl true
  def handle_event("clear_review_by", _params, socket) do
    form_data = Map.put(socket.assigns.form_data, "review_by", "")

    {:noreply,
     socket
     |> assign(:touched_fields, MapSet.put(socket.assigns.touched_fields, "review_by"))
     |> assign(:errors, Map.delete(socket.assigns.errors, "review_by"))
     |> assign_form_state(form_data)}
  end

  @impl true
  def handle_event("pick_review_by", %{"date" => date}, socket) do
    form_data = Map.put(socket.assigns.form_data, "review_by", date)

    {:noreply,
     socket
     |> assign(:touched_fields, MapSet.put(socket.assigns.touched_fields, "review_by"))
     |> assign(:errors, Map.delete(socket.assigns.errors, "review_by"))
     |> assign(:review_calendar_month, calendar_month(date))
     |> assign_form_state(form_data)}
  end

  @impl true
  def handle_event("shift_review_month", %{"months" => months}, socket) do
    month =
      socket.assigns.review_calendar_month
      |> Date.add(String.to_integer(months) * 32)
      |> beginning_of_month()

    {:noreply, assign(socket, :review_calendar_month, month)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if @mode == :new, do: "Create flag", else: "Edit flag"}
      page_kicker="Flag metadata"
      page_summary={if @mode == :new, do: "Create a new runtime decision point.", else: "Update flag metadata."}
      base_path={@rulestead_admin_mount_path}
      current_section={:flags}
      breadcrumbs={breadcrumbs(assigns)}
      current_environment={@current_environment}
      environments={[]}
      env_links={%{}}
      policy_state={@rulestead_admin_policy_state}
    >
      <form aria-label="Flag metadata form" phx-change="validate" phx-submit="save" class="rs-flag-form">
        <div :if={(@submitted? or not is_nil(@errors["base"])) and @errors != %{}} class="rs-form-summary" role="alert" aria-live="polite">
          <strong><%= if @mode == :new, do: "Flag was not created", else: "Flag was not saved" %></strong>
          <p>Fix the highlighted fields and submit again.</p>
          <p :if={@errors["base"]}><%= @errors["base"] %></p>
        </div>

        <div phx-feedback-for="flag_key" class="rs-form-field">
          <label>
            <span>Key</span>
            <input type="text" id="flag_key" name="flag[key]" value={@form_data["key"]} disabled={@mode == :edit} phx-blur="touch_field" phx-value-field="key" />
            <p class="rs-form-help">Unique identifier used in code. For example, <code>checkout-one-click-buy</code>.</p>
          </label>
          <p :if={@errors["key"]} class="rs-form-error" role="alert"><%= @errors["key"] %></p>
        </div>

        <div phx-feedback-for="flag_description" class="rs-form-field">
          <label>
            <span>Description</span>
            <textarea id="flag_description" name="flag[description]"><%= @form_data["description"] %></textarea>
            <p class="rs-form-help">
              Shown in inventory, review, and audit surfaces so operators understand why the flag exists.
              For example, "Enables one-click checkout for returning customers while the team monitors conversion and support tickets."
            </p>
          </label>
        </div>

        <fieldset class="rs-fieldset">
          <legend>Owner details</legend>

          <div phx-feedback-for="flag_owner_picker_ref" class="rs-form-field">
            <label :if={@owner_picker_options != []}>
              <span>Host owner picker</span>
              <select id="flag_owner_picker_ref" name="flag[owner_picker_ref]">
                <option value="">Manual entry</option>
                <option
                  :for={option <- @owner_picker_options}
                  value={option.owner_ref}
                  selected={@form_data["owner_picker_ref"] == option.owner_ref}
                >
                  <%= option.owner_display || option.owner_ref %>
                </option>
              </select>
            </label>
          </div>

          <div phx-feedback-for="flag_owner_kind" class="rs-form-field">
            <fieldset class="rs-radio-card-group rs-radio-card-group--compact">
              <legend>Owner type</legend>
              <div class="rs-radio-card-grid rs-radio-card-grid--three">
                <label :for={{label, value} <- @owner_kind_options} class="rs-radio-card">
                  <input type="radio" id={"flag_owner_kind_#{value}"} name="flag[owner_kind]" value={value} checked={@form_data["owner_kind"] == value} phx-blur="touch_field" phx-value-field="owner_kind" />
                  <span class="rs-radio-card__body">
                    <.owner_kind_icon kind={value} />
                    <span class="rs-radio-card__text">
                      <strong><%= label %></strong>
                      <span><%= owner_kind_hint(value) %></span>
                    </span>
                  </span>
                </label>
              </div>
            </fieldset>
            <p :if={@errors["owner_kind"]} class="rs-form-error" role="alert"><%= @errors["owner_kind"] %></p>
          </div>

          <div phx-feedback-for="flag_owner_display" class="rs-form-field">
            <label>
              <span>Display name</span>
              <input type="text" id="flag_owner_display" name="flag[owner_display]" value={@form_data["owner_display"]} />
              <p class="rs-form-help">Human-readable name shown in the UI. For example, "Checkout Team".</p>
            </label>
          </div>

          <div phx-feedback-for="flag_owner_ref" class="rs-form-field" style="margin-bottom: 0;">
            <label>
              <span>Owner ID</span>
              <input type="text" id="flag_owner_ref" name="flag[owner_ref]" value={@form_data["owner_ref"]} phx-blur="touch_field" phx-value-field="owner_ref" />
              <p class="rs-form-help">Stable system identifier. For example, <code>team:checkout</code>.</p>
            </label>
            <p :if={@errors["owner_ref"]} class="rs-form-error" role="alert"><%= @errors["owner_ref"] %></p>
          </div>
        </fieldset>

        <div phx-feedback-for="flag_type" class="rs-form-field">
          <fieldset class="rs-radio-card-group">
            <legend>Flag type</legend>
            <p class="rs-form-help">Choose the reason this flag exists. This drives lifecycle guidance and cleanup expectations.</p>
            <div class="rs-radio-card-stack">
              <label :for={{label, value} <- @flag_type_options} class="rs-radio-card rs-radio-card--choice">
                <input 
                  type="radio" 
                  id={"flag_type_#{value}"}
                  name="flag[flag_type]" 
                  value={value} 
                  checked={@form_data["flag_type"] == value} 
                  disabled={@mode == :edit} 
                />
                <span class="rs-radio-card__body">
                  <span class="rs-radio-card__text">
                    <strong><%= flag_type_label(label, value) %></strong>
                    <span><%= flag_type_hint(value) %></span>
                  </span>
                </span>
              </label>
            </div>
          </fieldset>
        </div>

        <div phx-feedback-for="flag_lifecycle_mode" class="rs-form-field">
          <fieldset class="rs-radio-card-group rs-radio-card-group--compact">
            <legend>Flag lifespan</legend>
            <p class="rs-form-help">
              Suggestion: <strong><%= humanize(@lifecycle_suggestion.mode || "explicit choice required") %></strong>.
              <%= @lifecycle_suggestion.rationale %>
              <span :if={@lifecycle_suggestion.default_overridden}>(Operator override recorded).</span>
            </p>
            <div class="rs-radio-card-grid rs-radio-card-grid--two">
              <label class="rs-radio-card">
                <input type="radio" id="flag_lifecycle_mode_expiring" name="flag[lifecycle_mode]" value="expiring" checked={@form_data["lifecycle_mode"] == "expiring"} phx-blur="touch_field" phx-value-field="lifecycle_mode" />
                <span class="rs-radio-card__body">
                  <span class="rs-radio-card__text">
                    <strong>Expiring</strong>
                    <span>Needs an explicit review date and cleanup decision.</span>
                  </span>
                </span>
              </label>
              <label class="rs-radio-card">
                <input type="radio" id="flag_lifecycle_mode_permanent" name="flag[lifecycle_mode]" value="permanent" checked={@form_data["lifecycle_mode"] == "permanent"} phx-blur="touch_field" phx-value-field="lifecycle_mode" />
                <span class="rs-radio-card__body">
                  <span class="rs-radio-card__text">
                    <strong>Permanent</strong>
                    <span>Expected to remain as ongoing product or operations behavior.</span>
                  </span>
                </span>
              </label>
            </div>
          </fieldset>
          <p :if={@errors["lifecycle_mode"]} class="rs-form-error" role="alert"><%= @errors["lifecycle_mode"] %></p>
        </div>

        <div phx-feedback-for="flag_review_by" class="rs-form-field" :if={@form_data["lifecycle_mode"] == "expiring"}>
          <div class="rs-date-picker">
            <label for="flag_review_by">Review by date</label>
            <div class="rs-date-picker__entry">
              <input type="text" inputmode="numeric" id="flag_review_by" name="flag[review_by]" value={@form_data["review_by"]} placeholder="YYYY-MM-DD" aria-describedby="flag_review_by_help" phx-blur="touch_field" phx-value-field="review_by" />
              <div class="rs-date-picker__calendar" aria-label="Review date calendar">
                <div class="rs-date-calendar">
                  <div class="rs-date-calendar__header">
                    <button type="button" phx-click="shift_review_month" phx-value-months="-1" aria-label="Previous month">&lt;</button>
                    <strong><%= calendar_month_label(@review_calendar_month) %></strong>
                    <button type="button" phx-click="shift_review_month" phx-value-months="1" aria-label="Next month">&gt;</button>
                  </div>
                  <div class="rs-date-calendar__weekdays" aria-hidden="true">
                    <span :for={day <- ~w(S M T W T F S)}><%= day %></span>
                  </div>
                  <div class="rs-date-calendar__grid">
                    <button
                      :for={day <- calendar_days(@review_calendar_month)}
                      type="button"
                      phx-click="pick_review_by"
                      phx-value-date={Date.to_iso8601(day.date)}
                      class={["rs-date-calendar__day", day.current_month? && "is-current-month", @form_data["review_by"] == Date.to_iso8601(day.date) && "is-selected"]}
                    >
                      <%= day.date.day %>
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <div class="rs-date-picker__presets" aria-label="Review date shortcuts">
              <button type="button" phx-click="set_review_by" phx-value-days="30">30 days</button>
              <button type="button" phx-click="set_review_by" phx-value-days="60">60 days</button>
              <button type="button" phx-click="set_review_by" phx-value-days="90">90 days</button>
              <button type="button" phx-click="clear_review_by">Clear date</button>
            </div>
            <p id="flag_review_by_help" class="rs-form-help">Required for expiring flags. Use <code>YYYY-MM-DD</code>, or pick a review horizon.</p>
          </div>
          <p :if={@errors["review_by"]} class="rs-form-error" role="alert"><%= @errors["review_by"] %></p>
        </div>

        <div phx-feedback-for="flag_value_type" class="rs-form-field">
          <fieldset class="rs-radio-card-group">
            <legend>Data type</legend>
            <p class="rs-form-help">Choose what your application receives when it evaluates the flag.</p>
            <div class="rs-radio-card-grid rs-radio-card-grid--value-types">
              <label :for={{label, value} <- @value_type_options} class="rs-radio-card rs-radio-card--choice">
                <input
                  type="radio"
                  id={"flag_value_type_#{value}"}
                  name="flag[value_type]"
                  value={value}
                  checked={@form_data["value_type"] == value}
                  disabled={@mode == :edit}
                  phx-blur="touch_field"
                  phx-value-field="value_type"
                />
                <span class="rs-radio-card__body">
                  <span class="rs-radio-card__text">
                    <strong><%= value_type_label(label, value) %></strong>
                    <span><%= value_type_hint(value) %></span>
                  </span>
                </span>
              </label>
            </div>
          </fieldset>
        </div>

        <div phx-feedback-for="flag_default_value" class="rs-form-field">
          <fieldset class="rs-radio-card-group rs-radio-card-group--compact" :if={@form_data["value_type"] == "boolean"}>
            <legend>Default value</legend>
            <div class="rs-radio-card-grid rs-radio-card-grid--two">
              <label class="rs-radio-card">
                <input type="radio" id="flag_default_value_true" name="flag[default_value]" value="true" checked={@form_data["default_value"] in ["true", true]} disabled={@mode == :edit} phx-blur="touch_field" phx-value-field="default_value" />
                <span class="rs-radio-card__body">
                  <span class="rs-radio-card__text">
                    <strong>True</strong>
                    <span>On unless a rule says otherwise.</span>
                  </span>
                </span>
              </label>
              <label class="rs-radio-card">
                <input type="radio" id="flag_default_value_false" name="flag[default_value]" value="false" checked={@form_data["default_value"] in ["false", false]} disabled={@mode == :edit} phx-blur="touch_field" phx-value-field="default_value" />
                <span class="rs-radio-card__body">
                  <span class="rs-radio-card__text">
                    <strong>False</strong>
                    <span>Off unless a rule says otherwise.</span>
                  </span>
                </span>
              </label>
            </div>
          </fieldset>

          <label :if={@form_data["value_type"] not in ["boolean", "json"]}>
            <span>Default value</span>
            <input
              type={if @form_data["value_type"] == "integer", do: "number", else: "text"}
              id="flag_default_value_input"
              name="flag[default_value]"
              value={@form_data["default_value"]}
              disabled={@mode == :edit}
              phx-blur="touch_field"
              phx-value-field="default_value"
            />
          </label>

          <label :if={@form_data["value_type"] == "json"}>
            <span>Default value</span>
            <textarea
              id="flag_default_value_textarea"
              name="flag[default_value]"
              disabled={@mode == :edit}
              phx-blur="touch_field"
              phx-value-field="default_value"
              style="font-family: var(--rs-font-mono); min-height: 80px;"
            ><%= @form_data["default_value"] %></textarea>
          </label>
          <p :if={@errors["default_value"]} class="rs-form-error" role="alert"><%= @errors["default_value"] %></p>
        </div>

        <div phx-feedback-for="flag_tags" class="rs-form-field">
          <label>
            <span>Tags</span>
            <input type="text" id="flag_tags" name="flag[tags]" value={@form_data["tags"]} />
            <div class="rs-form-preview" :if={@form_data["tags"] != "" and @form_data["tags"] != nil}>
              <FlagComponents.tag_list tags={parse_tags(@form_data["tags"])} />
            </div>
            <p class="rs-form-help">Comma-separated labels for filtering. For example, <code>checkout, release, revenue</code>.</p>
          </label>
        </div>

        <button type="submit" class="rs-button rs-button--primary"><%= if @mode == :new, do: "Create flag", else: "Save metadata" %></button>
      </form>
    </Shell.page>
    """
  end

  defp breadcrumbs(%{mode: :edit} = assigns) do
    mount = assigns.rulestead_admin_mount_path
    env = assigns.current_environment.key
    key = assigns.flag_key

    [
      %{label: "Flags", path: mount <> "/flags?env=" <> env},
      %{label: key, path: mount <> "/" <> key <> "?env=" <> env},
      %{label: "Edit", path: mount <> "/" <> key <> "/edit?env=" <> env}
    ]
  end

  defp breadcrumbs(assigns) do
    mount = assigns.rulestead_admin_mount_path
    env = assigns.current_environment.key

    [
      %{label: "Flags", path: mount <> "/flags?env=" <> env},
      %{label: "New flag", path: mount <> "/new?env=" <> env}
    ]
  end

  attr(:kind, :string, required: true)

  defp owner_kind_icon(assigns) do
    ~H"""
    <span class="rs-owner-kind-icon" aria-hidden="true">
      <svg :if={@kind == "person"} viewBox="0 0 20 20" fill="none">
        <path d="M10 10.15a3.25 3.25 0 1 0 0-6.5 3.25 3.25 0 0 0 0 6.5Z" stroke="currentColor" stroke-width="1.6" />
        <path d="M4.5 16.35c.75-2.25 2.75-3.55 5.5-3.55s4.75 1.3 5.5 3.55" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
      </svg>
      <svg :if={@kind == "team"} viewBox="0 0 20 20" fill="none">
        <path d="M7.75 9.25a2.65 2.65 0 1 0 0-5.3 2.65 2.65 0 0 0 0 5.3Z" stroke="currentColor" stroke-width="1.55" />
        <path d="M13.8 9.4a2.25 2.25 0 1 0 0-4.5" stroke="currentColor" stroke-width="1.55" stroke-linecap="round" />
        <path d="M3.25 16.1c.7-2.25 2.3-3.45 4.5-3.45s3.8 1.2 4.5 3.45" stroke="currentColor" stroke-width="1.55" stroke-linecap="round" />
        <path d="M13.1 12.85c1.75.25 2.95 1.35 3.65 3.25" stroke="currentColor" stroke-width="1.55" stroke-linecap="round" />
      </svg>
      <svg :if={@kind == "service"} viewBox="0 0 20 20" fill="none">
        <rect x="3.5" y="4.5" width="13" height="4.5" rx="1.4" stroke="currentColor" stroke-width="1.55" />
        <rect x="3.5" y="11" width="13" height="4.5" rx="1.4" stroke="currentColor" stroke-width="1.55" />
        <path d="M6.5 6.75h.01M6.5 13.25h.01M9.25 6.75h4.25M9.25 13.25h4.25" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
      </svg>
    </span>
    """
  end

  defp owner_kind_hint("person"), do: "An individual accountable for follow-up."
  defp owner_kind_hint("team"), do: "A shared operating or product team."
  defp owner_kind_hint("service"), do: "A system or service owner."

  defp flag_type_label("Release", "release"), do: "Release (most common)"
  defp flag_type_label(label, _value), do: label

  defp flag_type_hint("release"),
    do: "Temporary toggle for shipping a new behavior safely, then removing it."

  defp flag_type_hint("experiment"),
    do: "Measures outcomes across variants and should end after the decision."

  defp flag_type_hint("kill_switch"),
    do: "Emergency control for disabling broken behavior quickly."

  defp flag_type_hint("permission"),
    do: "Grants capability, entitlement, or tier access."

  defp flag_type_hint("remote_config"),
    do: "Changes small runtime settings without redeploying."

  defp flag_type_hint("operational"),
    do: "Controls ongoing infrastructure or operator behavior."

  defp flag_type_hint("migration"),
    do: "Moves traffic between old and new systems incrementally."

  defp value_type_label("Boolean", "boolean"), do: "Boolean (most common)"
  defp value_type_label(label, _value), do: label

  defp value_type_hint("boolean"),
    do: "Use for on/off releases, permissions, and safety switches."

  defp value_type_hint("string"), do: "Use for named variants, copy choices, or small mode names."
  defp value_type_hint("integer"), do: "Use for whole-number limits, thresholds, and counts."
  defp value_type_hint("float"), do: "Use only when fractional tuning is required."
  defp value_type_hint("json"), do: "Use for small structured config; avoid large payloads."

  defp calendar_month_label(%Date{} = date), do: Calendar.strftime(date, "%B %Y")

  defp calendar_days(%Date{} = month) do
    first = beginning_of_month(month)
    start_date = Date.add(first, -(Date.day_of_week(first, :sunday) - 1))

    Enum.map(0..41, fn offset ->
      date = Date.add(start_date, offset)

      %{
        date: date,
        current_month?: date.month == first.month and date.year == first.year
      }
    end)
  end

  defp load_edit(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        socket
        |> assign(:mode, :edit)
        |> assign(:flag_key, key)
        |> assign(:errors, %{})
        |> assign(:submitted?, false)
        |> assign(:touched_fields, MapSet.new())
        |> assign(:current_path, "/admin/flags/#{key}/edit?env=#{env}")
        |> assign_form_state(to_form_data(detail.flag))

      {:error, error} ->
        socket
        |> assign(:mode, :edit)
        |> assign(:flag_key, key)
        |> assign(:errors, %{"base" => error.message})
        |> assign(:submitted?, false)
        |> assign(:touched_fields, MapSet.new())
        |> assign(:current_path, "/admin/flags/#{key}/edit?env=#{env}")
    end
  end

  defp persist(:new, _flag_key, form_data, actor) do
    ownership = ownership_payload(form_data)
    lifecycle = lifecycle_payload(form_data)

    Rulestead.create_flag(
      %{
        key: form_data["key"],
        description: blank_to_nil(form_data["description"]),
        flag_type: String.to_atom(form_data["flag_type"]),
        value_type: String.to_atom(form_data["value_type"]),
        default_value: %{
          value: parse_default(form_data["value_type"], form_data["default_value"])
        },
        ownership: ownership,
        lifecycle: lifecycle,
        environment_keys: form_data["environment_keys"],
        tags: parse_tags(form_data["tags"])
      },
      actor: actor
    )
  end

  defp persist(:edit, flag_key, form_data, actor) do
    ownership = ownership_payload(form_data)
    lifecycle = lifecycle_payload(form_data)

    Rulestead.update_flag(
      flag_key,
      %{
        description: blank_to_nil(form_data["description"]),
        ownership: ownership,
        lifecycle: lifecycle,
        tags: parse_tags(form_data["tags"])
      },
      actor: actor
    )
  end

  defp success_flash(:new, flag_key), do: "Flag #{flag_key} was created."
  defp success_flash(:edit, flag_key), do: "Metadata saved for #{flag_key}."

  defp validate(form_data, mode) do
    ownership = normalized_ownership(form_data)
    lifecycle = lifecycle_payload(form_data)
    key_error = key_validation_error(form_data["key"], mode)
    review_date_error = review_date_validation_error(form_data["review_by"])

    default_value_error =
      default_value_validation_error(form_data["value_type"], form_data["default_value"])

    %{}
    |> maybe_put_error("key", key_error)
    |> maybe_put_error(
      "owner_ref",
      if(blank?(ownership["owner_ref"]), do: "Owner reference is required", else: nil)
    )
    |> maybe_put_error(
      "owner_kind",
      if(ownership["owner_kind"] in ["person", "team", "service"],
        do: nil,
        else: "Choose a valid owner kind"
      )
    )
    |> maybe_put_error("owner_ref", owner_validation_error(ownership))
    |> maybe_put_error(
      "lifecycle_mode",
      if(blank?(form_data["lifecycle_mode"]), do: "Choose a lifecycle posture", else: nil)
    )
    |> maybe_put_error("review_by", review_date_error)
    |> maybe_put_error("review_by", review_by_required_error(lifecycle, review_date_error))
    |> maybe_put_error("default_value", default_value_error)
  end

  defp visible_errors(errors, true, _touched_fields), do: errors

  defp visible_errors(errors, false, touched_fields) do
    errors
    |> Enum.filter(fn {field, message} ->
      MapSet.member?(touched_fields, field) and early_visible_error?(field, message)
    end)
    |> Map.new()
  end

  defp early_visible_error?("review_by", "Use a real review date in YYYY-MM-DD format"), do: true
  defp early_visible_error?("default_value", "Invalid JSON format"), do: true
  defp early_visible_error?("key", message) when message != "Key is required", do: true
  defp early_visible_error?(_field, _message), do: false

  defp assign_form_state(socket, form_data) do
    assign(socket, :form_data, form_data)
    |> assign(:review_calendar_month, calendar_month(form_data["review_by"]))
    |> assign(
      :lifecycle_suggestion,
      LifecycleDefaults.suggest(
        form_data["flag_type"],
        authored_mode: mode_from_form(form_data["lifecycle_mode"]),
        authored_review_by: parse_date(form_data["review_by"])
      )
    )
  end

  defp default_form_data do
    suggestion = LifecycleDefaults.suggest("release")

    %{
      "key" => "",
      "description" => "",
      "flag_type" => "release",
      "value_type" => "boolean",
      "default_value" => "false",
      "owner_picker_ref" => "",
      "owner_ref" => "",
      "owner_kind" => "team",
      "owner_display" => "",
      "lifecycle_mode" => to_string(suggestion.mode),
      "review_by" => "",
      "tags" => "",
      "environment_keys" => []
    }
  end

  defp merge_form_data(existing, attrs) do
    existing
    |> Map.merge(Map.new(attrs))
  end

  defp apply_picker_defaults(form_data, options) do
    case Enum.find(options, &(&1.owner_ref == form_data["owner_picker_ref"])) do
      nil ->
        form_data

      option ->
        form_data
        |> put_blank_default("owner_ref", option.owner_ref)
        |> put_blank_default("owner_kind", option.owner_kind)
        |> put_blank_default("owner_display", option.owner_display)
    end
  end

  defp to_form_data(flag) do
    ownership = Map.get(flag, :ownership) || %{}
    lifecycle = Map.get(flag, :lifecycle) || %{}

    %{
      "key" => flag.key,
      "description" => flag.description || "",
      "flag_type" => to_string(flag.flag_type),
      "value_type" => to_string(flag.value_type),
      "default_value" => default_value_to_string(default_value_value(flag.default_value)),
      "owner_picker_ref" => "",
      "owner_ref" => get_value(ownership, :owner_ref) || "",
      "owner_kind" => to_string(get_value(ownership, :owner_kind) || "team"),
      "owner_display" => get_value(ownership, :owner_display) || "",
      "lifecycle_mode" => to_string(get_value(lifecycle, :mode)),
      "review_by" => review_by_value(lifecycle),
      "tags" => Enum.join(flag.tags || [], ", "),
      "environment_keys" => Enum.map(Map.get(flag, :environment_keys, []), &to_string/1)
    }
  end

  defp review_by_value(lifecycle) do
    case get_value(lifecycle, :review_by) do
      %Date{} = value -> Date.to_iso8601(value)
      _other -> ""
    end
  end

  defp default_value_value(nil), do: nil
  defp default_value_value(value) when is_map(value), do: get_value(value, :value)
  defp default_value_value(value), do: value

  defp normalized_ownership(form_data) do
    %{
      "owner_ref" => blank_to_nil(form_data["owner_ref"]),
      "owner_kind" => blank_to_nil(form_data["owner_kind"]),
      "owner_display" => blank_to_nil(form_data["owner_display"])
    }
  end

  defp ownership_payload(form_data) do
    ownership = normalized_ownership(form_data)

    %{
      owner_ref: ownership["owner_ref"],
      owner_kind: String.to_atom(ownership["owner_kind"]),
      owner_display: ownership["owner_display"]
    }
  end

  defp lifecycle_payload(form_data) do
    suggestion =
      LifecycleDefaults.suggest(form_data["flag_type"],
        authored_mode: mode_from_form(form_data["lifecycle_mode"]),
        authored_review_by: parse_date(form_data["review_by"])
      )

    mode = mode_from_form(form_data["lifecycle_mode"])
    overridden = Map.get(suggestion, :default_overridden, false)

    %{
      mode: mode,
      review_by: parse_date(form_data["review_by"]),
      default_source:
        if(overridden and suggestion.default_source != :operator_required,
          do: :operator_override,
          else: suggestion.default_source
        ),
      default_overridden: overridden
    }
  end

  defp owner_picker_options do
    Application.get_env(:rulestead, :admin_owner, [])
    |> Keyword.get(:picker_options, [])
    |> Enum.map(fn option ->
      %{
        owner_ref: get_value(option, :owner_ref),
        owner_kind: to_string(get_value(option, :owner_kind) || "team"),
        owner_display: get_value(option, :owner_display)
      }
    end)
    |> Enum.reject(&blank?(&1.owner_ref))
  end

  defp owner_validation_error(ownership) do
    validator =
      Application.get_env(:rulestead, :admin_owner, [])
      |> Keyword.get(:validate)

    case apply_owner_validator(validator, ownership) do
      :ok -> nil
      {:ok, _ownership} -> nil
      {:error, message} -> message
      _other -> nil
    end
  end

  defp apply_owner_validator(nil, _ownership), do: :ok

  defp apply_owner_validator(validator, ownership) when is_function(validator, 1),
    do: validator.(ownership)

  defp apply_owner_validator({module, function, extra_args}, ownership),
    do: apply(module, function, [ownership | List.wrap(extra_args)])

  defp apply_owner_validator(_validator, _ownership), do: :ok

  defp get_value(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp put_blank_default(form_data, key, value) do
    if blank?(Map.get(form_data, key)) do
      Map.put(form_data, key, to_string(value || ""))
    else
      form_data
    end
  end

  defp maybe_put_error(errors, _field, nil), do: errors
  defp maybe_put_error(errors, field, message), do: Map.put_new(errors, field, message)

  defp mode_from_form("expiring"), do: :expiring
  defp mode_from_form("permanent"), do: :permanent
  defp mode_from_form(mode) when mode in [:expiring, :permanent], do: mode
  defp mode_from_form(_mode), do: nil

  defp parse_tags(tags) do
    tags
    |> to_string()
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_date(""), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(value) do
    case Date.from_iso8601(to_string(value)) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  defp key_validation_error(_value, mode) when mode != :new, do: nil

  defp key_validation_error(value, :new) do
    key = String.trim(to_string(value || ""))

    cond do
      key == "" ->
        "Key is required"

      String.length(key) < 2 ->
        "Key must be at least 2 characters"

      String.length(key) > 128 ->
        "Key must be 128 characters or fewer"

      not Regex.match?(~r/^[a-z0-9][a-z0-9:_-]*$/, key) ->
        "Use lowercase letters, numbers, colon, underscore, or hyphen. Start with a letter or number."

      true ->
        nil
    end
  end

  defp review_date_validation_error(value) when value in ["", nil], do: nil

  defp review_date_validation_error(value) do
    case Date.from_iso8601(to_string(value)) do
      {:ok, _date} -> nil
      {:error, _reason} -> "Use a real review date in YYYY-MM-DD format"
    end
  end

  defp review_by_required_error(%{mode: :expiring, review_by: nil}, nil),
    do: "Review by is required for expiring flags"

  defp review_by_required_error(_lifecycle, _review_date_error), do: nil

  defp default_value_validation_error("json", value) when value not in ["", nil] do
    case Jason.decode(to_string(value)) do
      {:ok, _decoded} -> nil
      {:error, _reason} -> "Invalid JSON format"
    end
  end

  defp default_value_validation_error(_value_type, _value), do: nil

  defp review_date_in(days) do
    days = String.to_integer(to_string(days))

    admin_today()
    |> Date.add(days)
    |> Date.to_iso8601()
  end

  defp calendar_month(value) do
    value
    |> parse_date()
    |> case do
      %Date{} = date -> beginning_of_month(date)
      nil -> beginning_of_month(admin_today())
    end
  end

  defp admin_today do
    :rulestead
    |> Application.get_env(:admin_lifecycle, [])
    |> Keyword.get(:now)
    |> case do
      %DateTime{} = now -> DateTime.to_date(now)
      %NaiveDateTime{} = now -> NaiveDateTime.to_date(now)
      %Date{} = date -> date
      _other -> Date.utc_today()
    end
  end

  defp beginning_of_month(%Date{} = date), do: %{date | day: 1}

  defp parse_default("boolean", value), do: value in ["true", true]
  defp parse_default(_type, value), do: value

  defp default_value_to_string(value) when is_boolean(value), do: to_string(value)
  defp default_value_to_string(value) when is_nil(value), do: ""
  defp default_value_to_string(value), do: to_string(value)

  defp query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end

  defp blank?(value), do: String.trim(to_string(value || "")) == ""
  defp blank_to_nil(value), do: if(blank?(value), do: nil, else: value)

  defp humanize(value),
    do: value |> to_string() |> String.replace("_", " ") |> String.capitalize()
end
