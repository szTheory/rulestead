defmodule RulesteadAdmin.Components.Shell do
  @moduledoc false

  use Phoenix.Component

  attr(:page_title, :string, required: true)
  attr(:page_kicker, :string, required: true)
  attr(:page_summary, :string, required: true)
  attr(:current_environment, :map, required: true)
  attr(:environments, :list, default: [])
  attr(:env_links, :map, default: %{})
  attr(:navigation_links, :list, default: [])
  slot(:header_actions)
  slot(:inner_block, required: true)

  def page(assigns) do
    assigns = assign(assigns, :env_tone, env_tone(assigns.current_environment))

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
        <section class="rs-shell__env" aria-label="Environment">
          <p class="rs-shell__env-label">Environment</p>
          <div class="rs-shell__env-picker" role="list">
            <%= for environment <- @environments do %>
              <a
                href={Map.get(@env_links, environment.key, "#")}
                class="rs-shell__env-link"
                data-current={to_string(environment.key == @current_environment.key)}
                data-env-tone={env_tone(environment)}
              >
                <span><%= environment.name %></span>
                <span :if={environment.key == @current_environment.key}>Current</span>
              </a>
            <% end %>
          </div>
        </section>
      </header>

      <nav :if={@navigation_links != []} class="rs-shell__nav" aria-label="Governance navigation">
        <a
          :for={link <- @navigation_links}
          href={link.path}
          class="rs-shell__nav-link"
          aria-current={if(link.current?, do: "page", else: nil)}
        >
          <%= link.label %>
        </a>
      </nav>

      <main class="rs-shell__body">
        <%= render_slot(@inner_block) %>
      </main>
    </div>
    """
  end

  defp env_tone(%{key: "prod"}), do: "production"
  defp env_tone(%{key: "production"}), do: "production"
  defp env_tone(_environment), do: "standard"
end
