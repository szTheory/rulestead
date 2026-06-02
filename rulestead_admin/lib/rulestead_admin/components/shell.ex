defmodule RulesteadAdmin.Components.Shell do
  @moduledoc false

  use Phoenix.Component

  alias RulesteadAdmin.Navigation

  attr(:page_title, :string, required: true)
  attr(:page_kicker, :string, required: true)
  attr(:page_summary, :string, required: true)
  attr(:breadcrumbs, :list, default: [])
  attr(:current_environment, :map, required: true)
  attr(:environments, :list, default: [])
  attr(:env_links, :map, default: %{})
  attr(:env_options, :list, default: nil)
  attr(:env_context_label, :string, default: "Viewing environment")
  attr(:env_context_help, :string, default: "Switches the admin view scope.")
  attr(:current_tenant, :map, default: nil)
  attr(:tenants, :list, default: [])
  attr(:tenant_links, :map, default: %{})
  attr(:base_path, :string, default: nil)
  attr(:current_section, :atom, default: nil)
  # Deprecated: section nav is now derived from base_path + current_section via
  # RulesteadAdmin.Navigation. Kept declared so legacy callers don't raise.
  attr(:navigation_links, :list, default: [])
  attr(:policy_state, :map, default: nil)
  attr(:flash, :map, default: %{})
  slot(:header_actions)
  slot(:inner_block, required: true)

  def page(assigns) do
    assigns =
      assigns
      |> assign(:env_tone, env_tone(assigns.current_environment))
      |> assign(:resolved_env_options, env_options(assigns))
      |> assign(:flash_entries, flash_entries(assigns.flash))
      |> assign(:nav_groups, nav_groups(assigns))
      |> assign(:nav_overview, nav_overview(assigns))

    ~H"""
    <div class="rs-shell" data-env-tone={@env_tone}>
      <header class="rs-shell__header">
        <div>
          <p class="rs-shell__kicker"><%= @page_kicker %></p>
          <h1 class="rs-shell__title"><%= @page_title %></h1>
          <p class="rs-shell__summary"><%= @page_summary %></p>
          <div :if={@header_actions != []} class="rs-shell__header-actions">
            <%= render_slot(@header_actions) %>
          </div>
        </div>
        <section :if={@policy_state} class="rs-shell__context" aria-label="Access">
          <p class="rs-shell__context-label">Access</p>
          <div
            class="rs-shell__context-item"
            title={"You have #{highest_capability(Map.get(@policy_state, :capabilities))} access in this environment. " <> capability_summary(Map.get(@policy_state, :capabilities))}
          >
            <span><%= highest_capability(Map.get(@policy_state, :capabilities)) %></span>
          </div>
        </section>
        <section :if={@resolved_env_options != []} class="rs-shell__context" aria-label={@env_context_label}>
          <p class="rs-shell__context-label"><%= @env_context_label %></p>
          <div class="rs-shell__env-picker" role="list">
            <%= for option <- @resolved_env_options do %>
              <a
                :if={option.available?}
                href={option.href}
                class="rs-shell__env-link"
                role="listitem"
                data-current={to_string(option.current?)}
                data-env-tone={option.tone}
                title={option.title}
              >
                <span><%= option.name %></span>
                <span :if={option.current?}>Viewing</span>
              </a>
              <span
                :if={!option.available?}
                class="rs-shell__env-link"
                data-current={to_string(option.current?)}
                data-env-tone={option.tone}
                data-available="false"
                aria-disabled="true"
                role="listitem"
                title={option.title}
              >
                <span><%= option.name %></span>
                <span>Not configured</span>
              </span>
            <% end %>
          </div>
          <p :if={@env_context_help} class="rs-shell__context-help"><%= @env_context_help %></p>
        </section>
        <section :if={show_tenant_scope?(assigns)} class="rs-shell__context" aria-label="Tenant scope">
          <p class="rs-shell__context-label">Tenant</p>
          <div :if={length(@tenants) > 1} class="rs-shell__env-picker" role="list">
            <%= for tenant <- @tenants do %>
              <a
                href={Map.get(@tenant_links, tenant.key, "#")}
                class="rs-shell__env-link"
                role="listitem"
                data-current={to_string(current_tenant?(assigns, tenant))}
              >
                <span><%= tenant.name %></span>
                <span :if={current_tenant?(assigns, tenant)}>Current</span>
              </a>
            <% end %>
          </div>
          <p :if={length(@tenants) <= 1 and @current_tenant} class="rs-shell__summary">
            Scoped to <strong><%= @current_tenant.name %></strong>
          </p>
        </section>
      </header>

      <div class="rs-shell__layout">
        <nav :if={@nav_groups != []} class="rs-shell__rail" aria-label="Primary navigation">
          <div :if={@nav_overview} class="rs-shell__rail-group">
            <a
              href={@nav_overview.path}
              class="rs-shell__rail-link rs-shell__rail-link--overview"
              aria-current={if(@nav_overview.current?, do: "page", else: nil)}
            >
              <%= @nav_overview.label %>
            </a>
          </div>
          <div :for={group <- @nav_groups} class="rs-shell__rail-group">
            <p class="rs-shell__rail-group-title"><%= group.title %></p>
            <a
              :for={item <- group.items}
              href={item.path}
              class="rs-shell__rail-link"
              aria-current={if(item.current?, do: "page", else: nil)}
            >
              <%= item.label %>
            </a>
          </div>
        </nav>

        <main class="rs-shell__main">
          <nav :if={@breadcrumbs != []} aria-label="Breadcrumb" class="rs-shell__breadcrumbs">
            <ol>
              <li :for={{crumb, index} <- Enum.with_index(@breadcrumbs)}>
                <a href={crumb.path} class="rs-shell__breadcrumb-link"><%= crumb.label %></a>
                <span :if={index < length(@breadcrumbs) - 1} class="rs-shell__breadcrumb-separator" aria-hidden="true">/</span>
              </li>
            </ol>
          </nav>

          <div class="rs-shell__body">
            <section :if={@flash_entries != []} class="rs-flash-stack" aria-label="Page messages">
              <div
                :for={entry <- @flash_entries}
                class="rs-flash"
                data-kind={entry.kind}
                role={flash_role(entry.kind)}
                aria-live={flash_live(entry.kind)}
              >
                <strong><%= flash_title(entry.kind) %></strong>
                <p><%= entry.message %></p>
              </div>
            </section>

            <%= render_slot(@inner_block) %>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp nav_groups(%{base_path: base_path} = assigns) when is_binary(base_path) do
    env_key = Map.get(assigns.current_environment || %{}, :key)
    Navigation.groups(base_path, env_key, assigns.current_section)
  end

  defp nav_groups(_assigns), do: []

  defp nav_overview(%{base_path: base_path} = assigns) when is_binary(base_path) do
    env_key = Map.get(assigns.current_environment || %{}, :key)
    Navigation.overview(base_path, env_key, assigns.current_section)
  end

  defp nav_overview(_assigns), do: nil

  defp env_tone(%{key: "prod"}), do: "production"
  defp env_tone(%{key: "production"}), do: "production"
  defp env_tone(_environment), do: "standard"

  defp env_options(%{env_options: options}) when is_list(options) do
    Enum.map(options, fn option ->
      environment = Map.fetch!(option, :environment)

      %{
        key: environment.key,
        name: environment.name,
        href: Map.get(option, :href, "#"),
        current?: Map.get(option, :current?, false),
        available?: Map.get(option, :available?, true),
        tone: Map.get(option, :tone, env_tone(environment)),
        title: Map.get(option, :title)
      }
    end)
  end

  defp env_options(assigns) do
    Enum.map(assigns.environments, fn environment ->
      %{
        key: environment.key,
        name: environment.name,
        href: Map.get(assigns.env_links, environment.key, "#"),
        current?: environment.key == assigns.current_environment.key,
        available?: true,
        tone: env_tone(environment),
        title: "View #{environment.name}"
      }
    end)
  end

  defp highest_capability(%{admin?: true}), do: "Admin"
  defp highest_capability(%{execute?: true}), do: "Execute"
  defp highest_capability(%{propose?: true}), do: "Propose"
  defp highest_capability(%{read?: true}), do: "Read-only"
  defp highest_capability(_capabilities), do: "No access"

  defp capability_summary(nil), do: "No capabilities defined"

  defp capability_summary(caps) do
    "Permissions - Read: #{caps.read?}, Execute: #{caps.execute?}, Propose: #{caps.propose?}, Admin: #{caps.admin?}"
  end

  defp current_tenant?(%{current_tenant: %{key: current_key}}, %{key: tenant_key}),
    do: current_key == tenant_key

  defp current_tenant?(_assigns, _tenant), do: false

  defp show_tenant_scope?(%{current_tenant: tenant, tenants: tenants}),
    do: is_map(tenant) or tenants != []

  defp flash_entries(flash) when is_map(flash) do
    [:info, :success, :error]
    |> Enum.flat_map(fn kind ->
      case Map.get(flash, kind) || Map.get(flash, to_string(kind)) do
        message when is_binary(message) and message != "" ->
          [%{kind: to_string(kind), message: message}]

        _other ->
          []
      end
    end)
  end

  defp flash_entries(_flash), do: []

  defp flash_role("error"), do: "alert"
  defp flash_role(_kind), do: "status"

  defp flash_live("error"), do: "assertive"
  defp flash_live(_kind), do: "polite"

  defp flash_title("error"), do: "Needs attention"
  defp flash_title(_kind), do: "Done"
end
