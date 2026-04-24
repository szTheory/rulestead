defmodule RulesteadAdmin.Live.FlagLive.Form do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:mode, :new)
     |> assign(:flag_key, nil)
     |> assign(:form_data, default_form_data())
     |> assign(:errors, %{})
     |> assign(:current_path, "/admin/flags/new")
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    env = query_params(uri)["env"] || socket.assigns.current_environment.key

    socket =
      case socket.assigns.live_action do
        :new ->
          socket
          |> assign(:mode, :new)
          |> assign(:flag_key, nil)
          |> assign(:form_data, Map.put(default_form_data(), "environment_keys", [env]))
          |> assign(:errors, %{})
          |> assign(:current_path, "/admin/flags/new?env=#{env}")

        :edit ->
          load_edit(socket, params["key"], env)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"flag" => attrs}, socket) do
    form_data = merge_form_data(socket.assigns.form_data, attrs)
    errors = validate(form_data, socket.assigns.mode)

    if map_size(errors) > 0 do
      {:noreply, assign(socket, :form_data, form_data) |> assign(:errors, errors)}
    else
      case persist(socket.assigns.mode, socket.assigns.flag_key, form_data) do
        {:ok, payload} ->
          {:noreply,
           socket
           |> assign(:form_data, to_form_data(payload.flag))
           |> assign(:errors, %{})
           |> push_navigate(to: "/admin/flags/#{payload.flag.key}?env=#{socket.assigns.current_environment.key}")}

        {:error, error} ->
          {:noreply, assign(socket, :errors, %{"base" => error.message}) |> assign(:form_data, form_data)}
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
        </label>

        <label>
          <span>Description</span>
          <textarea name="flag[description]"><%= @form_data["description"] %></textarea>
        </label>

        <label>
          <span>Owner</span>
          <input type="text" name="flag[owner]" value={@form_data["owner"]} />
        </label>
        <p :if={@errors["owner"]} role="alert"><%= @errors["owner"] %></p>

        <label>
          <span>Flag type</span>
          <select name="flag[flag_type]" disabled={@mode == :edit}>
            <option :for={type <- ~w(release experiment ops permission)} value={type} selected={@form_data["flag_type"] == type}>
              <%= humanize(type) %>
            </option>
          </select>
        </label>

        <label>
          <span>Value type</span>
          <select name="flag[value_type]" disabled={@mode == :edit}>
            <option :for={type <- ~w(boolean string integer float json)} value={type} selected={@form_data["value_type"] == type}>
              <%= humanize(type) %>
            </option>
          </select>
        </label>

        <label>
          <span>Default value</span>
          <input type="text" name="flag[default_value]" value={@form_data["default_value"]} disabled={@mode == :edit} />
        </label>

        <label>
          <span>Expected expiration</span>
          <input type="date" name="flag[expected_expiration]" value={@form_data["expected_expiration"]} />
        </label>

        <label>
          <input type="hidden" name="flag[permanent]" value="false" />
          <input type="checkbox" name="flag[permanent]" value="true" checked={@form_data["permanent"] == "true"} />
          <span>Permanent</span>
        </label>
        <p :if={@errors["lifecycle"]} role="alert"><%= @errors["lifecycle"] %></p>

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
        |> assign(:form_data, to_form_data(detail.flag))
        |> assign(:errors, %{})
        |> assign(:current_path, "/admin/flags/#{key}/edit?env=#{env}")

      {:error, error} ->
        socket
        |> assign(:mode, :edit)
        |> assign(:flag_key, key)
        |> assign(:errors, %{"base" => error.message})
        |> assign(:current_path, "/admin/flags/#{key}/edit?env=#{env}")
    end
  end

  defp persist(:new, _flag_key, form_data) do
    Rulestead.create_flag(%{
      key: form_data["key"],
      description: blank_to_nil(form_data["description"]),
      flag_type: String.to_atom(form_data["flag_type"]),
      value_type: String.to_atom(form_data["value_type"]),
      default_value: %{value: parse_default(form_data["value_type"], form_data["default_value"])},
      owner: String.trim(form_data["owner"]),
      expected_expiration: parse_date(form_data["expected_expiration"]),
      permanent: form_data["permanent"] == "true",
      environment_keys: form_data["environment_keys"],
      tags: parse_tags(form_data["tags"])
    })
  end

  defp persist(:edit, flag_key, form_data) do
    Rulestead.update_flag(flag_key, %{
      description: blank_to_nil(form_data["description"]),
      owner: String.trim(form_data["owner"]),
      expected_expiration: parse_date(form_data["expected_expiration"]),
      permanent: form_data["permanent"] == "true",
      tags: parse_tags(form_data["tags"])
    })
  end

  defp validate(form_data, mode) do
    %{}
    |> maybe_put_error("owner", owner_error(form_data["owner"]))
    |> maybe_put_error("lifecycle", lifecycle_error(form_data))
    |> maybe_put_error("key", if(mode == :new and blank?(form_data["key"]), do: "Key is required", else: nil))
  end

  defp owner_error(owner), do: if(blank?(owner), do: "Owner is required", else: nil)

  defp lifecycle_error(form_data) do
    if blank?(form_data["expected_expiration"]) and form_data["permanent"] != "true" do
      "Choose an expected expiration or mark the flag permanent"
    end
  end

  defp maybe_put_error(errors, _field, nil), do: errors
  defp maybe_put_error(errors, field, message), do: Map.put(errors, field, message)

  defp default_form_data do
    %{
      "key" => "",
      "description" => "",
      "flag_type" => "release",
      "value_type" => "boolean",
      "default_value" => "false",
      "owner" => "",
      "expected_expiration" => "",
      "permanent" => "false",
      "tags" => "",
      "environment_keys" => []
    }
  end

  defp merge_form_data(existing, attrs) do
    attrs = Map.new(attrs)

    existing
    |> Map.merge(attrs)
    |> Map.update("permanent", "false", &normalize_permanent/1)
  end

  defp to_form_data(flag) do
    %{
      "key" => flag.key,
      "description" => flag.description || "",
      "flag_type" => to_string(flag.flag_type),
      "value_type" => to_string(flag.value_type),
      "default_value" => default_value_to_string(flag.default_value && flag.default_value.value),
      "owner" => flag.owner || "",
      "expected_expiration" => if(flag.expected_expiration, do: Date.to_iso8601(flag.expected_expiration), else: ""),
      "permanent" => if(flag.permanent, do: "true", else: "false"),
      "tags" => Enum.join(flag.tags || [], ", "),
      "environment_keys" => Enum.map(Map.get(flag, :environment_keys, []), &to_string/1)
    }
  end

  defp normalize_permanent(value) when value in [true, "true", "on"], do: "true"
  defp normalize_permanent(_value), do: "false"

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
  defp humanize(value), do: value |> to_string() |> String.replace("_", " ") |> String.capitalize()
end
