# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Form do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.LifecycleDefaults
  alias RulesteadAdmin.Components.Shell

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
            |> assign(:current_path, "/admin/flags/new?env=#{env}")
            |> assign_form_state(Map.put(default_form_data(), "environment_keys", [env]))

          :edit ->
            load_edit(socket, params["key"], env)
        end

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"flag" => attrs}, socket) do
    form_data =
      socket.assigns.form_data
      |> merge_form_data(attrs)
      |> apply_picker_defaults(socket.assigns.owner_picker_options)

    errors = validate(form_data, socket.assigns.mode)

    if map_size(errors) > 0 do
      {:noreply, socket |> assign(:errors, errors) |> assign_form_state(form_data)}
    else
      case persist(socket.assigns.mode, socket.assigns.flag_key, form_data) do
        {:ok, payload} ->
          {:noreply,
           socket
           |> assign(:errors, %{})
           |> assign_form_state(to_form_data(payload.flag))
           |> push_navigate(
             to: "/admin/flags/#{payload.flag.key}?env=#{socket.assigns.current_environment.key}"
           )}

        {:error, error} ->
          {:noreply,
           socket
           |> assign(:errors, %{"base" => error.message})
           |> assign_form_state(form_data)}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if @mode == :new, do: "Create flag", else: "Edit flag"}
      page_kicker="Flag metadata"
      page_summary="Create or update owner, lifecycle metadata, description, tags, type, and default value."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={%{}}
    >
      <form aria-label="Flag metadata form" phx-submit="save">
        <p :if={@errors["base"]} role="alert"><%= @errors["base"] %></p>

        <label>
          <span>Key</span>
          <input type="text" name="flag[key]" value={@form_data["key"]} disabled={@mode == :edit} />
          <p class="rs-form-help" style="font-size: 0.85em; color: var(--rs-color-text-muted, #666);">Unique identifier used in code, e.g. <code>new_checkout_flow</code></p>
        </label>
        <p :if={@errors["key"]} role="alert"><%= @errors["key"] %></p>

        <label>
          <span>Description</span>
          <textarea name="flag[description]"><%= @form_data["description"] %></textarea>
        </label>

        <label :if={@owner_picker_options != []}>
          <span>Host owner picker</span>
          <select name="flag[owner_picker_ref]">
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

        <label>
          <span>Owner reference</span>
          <input type="text" name="flag[owner_ref]" value={@form_data["owner_ref"]} />
        </label>
        <p :if={@errors["owner_ref"]} role="alert"><%= @errors["owner_ref"] %></p>

        <label>
          <span>Owner kind</span>
          <select name="flag[owner_kind]">
            <option value="">Choose owner kind</option>
            <option
              :for={{label, value} <- @owner_kind_options}
              value={value}
              selected={@form_data["owner_kind"] == value}
            >
              <%= label %>
            </option>
          </select>
        </label>
        <p :if={@errors["owner_kind"]} role="alert"><%= @errors["owner_kind"] %></p>

        <label>
          <span>Owner display</span>
          <input type="text" name="flag[owner_display]" value={@form_data["owner_display"]} />
        </label>

        <fieldset class="rs-radio-group" style="margin-bottom: 1rem; border: none; padding: 0;">
          <legend style="font-weight: 600; margin-bottom: 0.5rem;">Flag type</legend>
          <div :for={{label, value} <- @flag_type_options} style="margin-bottom: 0.5rem;">
            <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: normal;">
              <input 
                type="radio" 
                name="flag[flag_type]" 
                value={value} 
                checked={@form_data["flag_type"] == value} 
                disabled={@mode == :edit} 
              />
              <%= label %>
            </label>
          </div>
        </fieldset>

        <label>
          <span>Value type</span>
          <select name="flag[value_type]" disabled={@mode == :edit}>
            <option
              :for={{label, value} <- @value_type_options}
              value={value}
              selected={@form_data["value_type"] == value}
            >
              <%= label %>
            </option>
          </select>
        </label>

        <fieldset class="rs-radio-group" style="margin-bottom: 1rem; border: none; padding: 0;" :if={@form_data["value_type"] == "boolean"}>
          <legend style="font-weight: 600; margin-bottom: 0.5rem;">Default value</legend>
          <div style="display: flex; gap: 1rem;">
            <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: normal;">
              <input type="radio" name="flag[default_value]" value="true" checked={@form_data["default_value"] in ["true", true]} disabled={@mode == :edit} /> True
            </label>
            <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: normal;">
              <input type="radio" name="flag[default_value]" value="false" checked={@form_data["default_value"] in ["false", false]} disabled={@mode == :edit} /> False
            </label>
          </div>
        </fieldset>

        <label :if={@form_data["value_type"] != "boolean"}>
          <span>Default value</span>
          <input
            type={if @form_data["value_type"] == "integer", do: "number", else: "text"}
            name="flag[default_value]"
            value={@form_data["default_value"]}
            disabled={@mode == :edit}
          />
        </label>

        <section aria-label="Lifecycle suggestion">
          <strong>Suggested lifecycle</strong>
          <p><%= humanize(@lifecycle_suggestion.mode || "explicit choice required") %></p>
          <p><%= @lifecycle_suggestion.rationale %></p>
          <p :if={@lifecycle_suggestion.default_overridden}>Operator override recorded.</p>
        </section>

        <fieldset class="rs-radio-group" style="margin-bottom: 1rem; border: none; padding: 0;">
          <legend style="font-weight: 600; margin-bottom: 0.5rem;">Lifecycle posture</legend>
          <div style="display: flex; gap: 1rem;">
            <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: normal;">
              <input type="radio" name="flag[lifecycle_mode]" value="expiring" checked={@form_data["lifecycle_mode"] == "expiring"} /> Expiring
            </label>
            <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: normal;">
              <input type="radio" name="flag[lifecycle_mode]" value="permanent" checked={@form_data["lifecycle_mode"] == "permanent"} /> Permanent
            </label>
          </div>
        </fieldset>
        <p :if={@errors["lifecycle_mode"]} role="alert"><%= @errors["lifecycle_mode"] %></p>

        <label>
          <span>Review by date</span>
          <input type="date" name="flag[review_by]" value={@form_data["review_by"]} />
          <p class="rs-form-help" style="font-size: 0.85em; color: var(--rs-color-text-muted, #666);">Required for expiring flags. Sets the expected lifetime.</p>
        </label>
        <p :if={@errors["review_by"]} role="alert"><%= @errors["review_by"] %></p>

        <label>
          <span>Tags</span>
          <input type="text" name="flag[tags]" value={@form_data["tags"]} />
        </label>

        <button type="submit">{if @mode == :new, do: "Create flag", else: "Save metadata"}</button>
      </form>
    </Shell.page>
    """
  end

  defp load_edit(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        socket
        |> assign(:mode, :edit)
        |> assign(:flag_key, key)
        |> assign(:errors, %{})
        |> assign(:current_path, "/admin/flags/#{key}/edit?env=#{env}")
        |> assign_form_state(to_form_data(detail.flag))

      {:error, error} ->
        socket
        |> assign(:mode, :edit)
        |> assign(:flag_key, key)
        |> assign(:errors, %{"base" => error.message})
        |> assign(:current_path, "/admin/flags/#{key}/edit?env=#{env}")
    end
  end

  defp persist(:new, _flag_key, form_data) do
    ownership = ownership_payload(form_data)
    lifecycle = lifecycle_payload(form_data)

    Rulestead.create_flag(%{
      key: form_data["key"],
      description: blank_to_nil(form_data["description"]),
      flag_type: String.to_atom(form_data["flag_type"]),
      value_type: String.to_atom(form_data["value_type"]),
      default_value: %{value: parse_default(form_data["value_type"], form_data["default_value"])},
      ownership: ownership,
      lifecycle: lifecycle,
      environment_keys: form_data["environment_keys"],
      tags: parse_tags(form_data["tags"])
    })
  end

  defp persist(:edit, flag_key, form_data) do
    ownership = ownership_payload(form_data)
    lifecycle = lifecycle_payload(form_data)

    Rulestead.update_flag(flag_key, %{
      description: blank_to_nil(form_data["description"]),
      ownership: ownership,
      lifecycle: lifecycle,
      tags: parse_tags(form_data["tags"])
    })
  end

  defp validate(form_data, mode) do
    ownership = normalized_ownership(form_data)
    lifecycle = lifecycle_payload(form_data)

    %{}
    |> maybe_put_error(
      "key",
      if(mode == :new and blank?(form_data["key"]), do: "Key is required", else: nil)
    )
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
    |> maybe_put_error(
      "review_by",
      if(lifecycle[:mode] == :expiring and is_nil(lifecycle[:review_by]),
        do: "Review by is required for expiring flags",
        else: nil
      )
    )
  end

  defp assign_form_state(socket, form_data) do
    assign(socket, :form_data, form_data)
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
      "default_value" => default_value_to_string(flag.default_value && flag.default_value.value),
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
  defp parse_date(value), do: Date.from_iso8601!(value)

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
