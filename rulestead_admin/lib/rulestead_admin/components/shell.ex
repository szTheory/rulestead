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
  attr(:theme_default, :string, default: "system")
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
      |> assign(:palette_groups, palette_groups(assigns))

    ~H"""
    <div class="rs-shell" data-env-tone={@env_tone} data-theme-pending>
      <header class="rs-shell__header">
        <div>
          <p class="rs-shell__kicker"><%= @page_kicker %></p>
          <h1 class="rs-shell__title"><%= @page_title %></h1>
          <p class="rs-shell__summary"><%= @page_summary %></p>
          <div :if={@header_actions != []} class="rs-shell__header-actions">
            <%= render_slot(@header_actions) %>
          </div>
          <button
            :if={@palette_groups != []}
            type="button"
            class="rs-shell__search"
            data-rs-cmdk-open
            aria-haspopup="dialog"
            aria-keyshortcuts="Meta+K Control+K"
          >
            <span class="rs-shell__search-glyph" aria-hidden="true">⌕</span>
            <span class="rs-shell__search-label">Search commands and pages…</span>
            <kbd class="rs-shell__search-kbd" aria-hidden="true">⌘K</kbd>
          </button>
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
        <section class="rs-shell__context" aria-label="Theme">
          <p class="rs-shell__context-label" id="rs-theme-label">Theme</p>
          <div
            id="rs-theme-control"
            role="radiogroup"
            aria-labelledby="rs-theme-label"
            phx-hook=".ThemeControl"
            data-theme-default={@theme_default}
            class="rs-theme-control__group"
          >
            <button type="button" role="radio" aria-checked="true"  tabindex="0"  data-value="system" class="rs-theme-control__opt">System</button>
            <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="light"  class="rs-theme-control__opt">Light</button>
            <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="dark"   class="rs-theme-control__opt">Dark</button>
          </div>
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

      <div :if={@palette_groups != []} id="rs-cmdk" class="rs-cmdk" phx-hook=".CmdK" hidden>
        <div class="rs-cmdk__backdrop" data-rs-cmdk-backdrop aria-hidden="true"></div>
        <div class="rs-cmdk__panel" role="dialog" aria-modal="true" aria-label="Command palette">
          <div class="rs-cmdk__search">
            <span class="rs-cmdk__search-glyph" aria-hidden="true">⌕</span>
            <input
              id="rs-cmdk-input"
              data-rs-cmdk-input
              class="rs-cmdk__input"
              type="text"
              role="combobox"
              aria-expanded="true"
              aria-controls="rs-cmdk-list"
              aria-label="Search commands and pages"
              placeholder="Search commands and pages…"
              autocomplete="off"
              spellcheck="false"
            />
          </div>
          <ul id="rs-cmdk-list" data-rs-cmdk-list class="rs-cmdk__list" role="listbox" aria-label="Results">
            <li
              :for={{title, items} <- @palette_groups}
              data-rs-cmdk-group
              role="group"
              aria-label={title}
              class="rs-cmdk__group"
            >
              <p class="rs-cmdk__group-title" aria-hidden="true"><%= title %></p>
              <a
                :for={item <- items}
                id={"rs-cmdk-opt-" <> item.id}
                role="option"
                aria-selected="false"
                href={item.href}
                data-keywords={item.keywords}
                class="rs-cmdk__option"
              >
                <span class="rs-cmdk__option-label"><%= item.label %></span>
                <span :if={item.hint} class="rs-cmdk__option-hint"><%= item.hint %></span>
              </a>
            </li>
          </ul>
          <p data-rs-cmdk-empty class="rs-cmdk__empty" hidden>
            No matches. Try a page or action name.
          </p>
          <div class="rs-cmdk__footer" aria-hidden="true">
            <span><kbd>↑</kbd><kbd>↓</kbd> navigate</span>
            <span><kbd>⮐</kbd> open</span>
            <span><kbd>esc</kbd> close</span>
          </div>
        </div>
        <script :type={Phoenix.LiveView.ColocatedHook} name=".CmdK" runtime>
          {
            mounted() {
              const root = this.el
              const input = root.querySelector("[data-rs-cmdk-input]")
              const list = root.querySelector("[data-rs-cmdk-list]")
              const empty = root.querySelector("[data-rs-cmdk-empty]")
              const visible = () => Array.from(list.querySelectorAll("[role=option]")).filter(o => !o.hidden)
              let index = 0
              let lastFocus = null

              const select = (i) => {
                root.querySelectorAll("[role=option]").forEach(o => o.setAttribute("aria-selected", "false"))
                const vis = visible()
                if (vis.length === 0) { input.removeAttribute("aria-activedescendant"); index = 0; return }
                index = ((i % vis.length) + vis.length) % vis.length
                const sel = vis[index]
                sel.setAttribute("aria-selected", "true")
                sel.scrollIntoView({ block: "nearest" })
                input.setAttribute("aria-activedescendant", sel.id)
              }

              const filter = (q) => {
                q = (q || "").trim().toLowerCase()
                const terms = q.length ? q.split(/\s+/) : []
                root.querySelectorAll("[role=option]").forEach(o => {
                  const kw = (o.dataset.keywords || o.textContent || "").toLowerCase()
                  o.hidden = terms.length > 0 && !terms.every(t => kw.indexOf(t) !== -1)
                })
                root.querySelectorAll("[data-rs-cmdk-group]").forEach(g => {
                  g.hidden = !g.querySelector("[role=option]:not([hidden])")
                })
                if (empty) empty.hidden = visible().length > 0
                select(0)
              }

              const open = () => {
                lastFocus = document.activeElement
                root.hidden = false
                document.documentElement.style.overflow = "hidden"
                input.value = ""
                filter("")
                requestAnimationFrame(() => input.focus())
              }
              const close = () => {
                root.hidden = true
                document.documentElement.style.overflow = ""
                if (lastFocus && lastFocus.focus) lastFocus.focus()
              }

              this._onKey = (e) => {
                if ((e.metaKey || e.ctrlKey) && !e.altKey && (e.key === "k" || e.key === "K")) {
                  e.preventDefault()
                  root.hidden ? open() : close()
                }
              }
              window.addEventListener("keydown", this._onKey)

              this._onOpenClick = (e) => {
                const t = e.target.closest("[data-rs-cmdk-open]")
                if (t) { e.preventDefault(); open() }
              }
              document.addEventListener("click", this._onOpenClick)

              root.querySelector("[data-rs-cmdk-backdrop]").addEventListener("click", close)
              input.addEventListener("input", (e) => filter(e.target.value))

              root.addEventListener("keydown", (e) => {
                if (e.key === "Escape") { e.preventDefault(); close() }
                else if (e.key === "ArrowDown") { e.preventDefault(); select(index + 1) }
                else if (e.key === "ArrowUp") { e.preventDefault(); select(index - 1) }
                else if (e.key === "Enter") {
                  e.preventDefault()
                  const sel = visible()[index]
                  if (sel) window.location.assign(sel.getAttribute("href"))
                }
                else if (e.key === "Tab") { e.preventDefault(); input.focus() }
              })

              list.addEventListener("mousemove", (e) => {
                const o = e.target.closest("[role=option]")
                if (o && !o.hidden) {
                  const i = visible().indexOf(o)
                  if (i >= 0 && i !== index) select(i)
                }
              })

              filter("")
            },
            destroyed() {
              window.removeEventListener("keydown", this._onKey)
              document.removeEventListener("click", this._onOpenClick)
              document.documentElement.style.overflow = ""
            }
          }
        </script>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeControl" runtime>
        {
          mounted() {
            const ctrl = this.el
            const shell = ctrl.closest(".rs-shell")
            const opts  = Array.from(ctrl.querySelectorAll("[role=radio]"))
            const VALID = ["system", "light", "dark"]

            const readTheme = () => {
              try {
                const v = localStorage.getItem("rulestead_admin.theme")
                return VALID.includes(v) ? v : (ctrl.dataset.themeDefault || "system")
              } catch (_) { return ctrl.dataset.themeDefault || "system" }
            }

            const writeTheme = (val) => {
              try { localStorage.setItem("rulestead_admin.theme", val) } catch (_) {}
            }

            const applyTheme = (val) => {
              shell.setAttribute("data-theme-switching", "")
              this._mode = val
              if (val === "dark")       shell.setAttribute("data-theme", "dark")
              else if (val === "light") shell.setAttribute("data-theme", "light")
              else                      shell.removeAttribute("data-theme")
              requestAnimationFrame(() => shell.removeAttribute("data-theme-switching"))
            }

            this._syncAria = () => {
              const current = this._mode || "system"
              opts.forEach((opt) => {
                const isActive = opt.dataset.value === current
                opt.setAttribute("aria-checked", String(isActive))
                opt.tabIndex = isActive ? 0 : -1
              })
            }

            applyTheme(readTheme())
            shell.removeAttribute("data-theme-pending")
            this._syncAria()

            this._mq = window.matchMedia("(prefers-color-scheme: dark)")
            this._mqListener = (_e) => {
              if (this._mode !== "system") return
              this._syncAria()
            }
            this._mq.addEventListener("change", this._mqListener)

            this._onClick = (e) => {
              const opt = e.target.closest("[role=radio]")
              if (!opt) return
              const val = opt.dataset.value
              writeTheme(val)
              applyTheme(val)
              this._syncAria()
              opt.focus()
            }
            ctrl.addEventListener("click", this._onClick)

            this._onKeydown = (e) => {
              const current = opts.findIndex(o => o.tabIndex === 0)
              let next = -1
              if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                e.preventDefault(); next = (current + 1) % opts.length
              } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                e.preventDefault(); next = (current - 1 + opts.length) % opts.length
              } else if (e.key === "Home") {
                e.preventDefault(); next = 0
              } else if (e.key === "End") {
                e.preventDefault(); next = opts.length - 1
              }
              if (next >= 0) {
                const val = opts[next].dataset.value
                writeTheme(val)
                applyTheme(val)
                this._syncAria()
                opts[next].focus()
              }
            }
            ctrl.addEventListener("keydown", this._onKeydown)
          },

          updated() {
            this._syncAria()
          },

          destroyed() {
            this._mq.removeEventListener("change", this._mqListener)
          }
        }
      </script>
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

  # Builds the command-palette result groups from the same Navigation source the
  # rail uses, so the palette and the rail teach the same mental model.
  defp palette_groups(%{base_path: base_path} = assigns) when is_binary(base_path) do
    env_key = Map.get(assigns.current_environment || %{}, :key)
    env_q = if env_key && env_key != "", do: "?env=#{env_key}", else: ""
    caps = Map.get(assigns.policy_state || %{}, :capabilities) || %{}
    can_create? = Map.get(caps, :edit?, false) or Map.get(caps, :admin?, false)

    nav = nav_groups(assigns)

    goto =
      [%{label: "Overview", href: base_path <> env_q, hint: "Home"}] ++
        for(group <- nav, item <- group.items, do: %{label: item.label, href: item.path, hint: group.title})

    actions =
      if can_create?,
        do: [%{label: "Create a flag", href: base_path <> "/new" <> env_q, hint: "New"}],
        else: []

    [{"Actions", actions}, {"Go to", goto}]
    |> Enum.reject(fn {_title, items} -> items == [] end)
    |> Enum.map(fn {title, items} ->
      finalized =
        items
        |> Enum.with_index()
        |> Enum.map(fn {item, index} ->
          item
          |> Map.put(:id, "#{palette_slug(title)}-#{index}")
          |> Map.put(:keywords, String.downcase("#{item.label} #{Map.get(item, :hint, "")} #{title}"))
        end)

      {title, finalized}
    end)
  end

  defp palette_groups(_assigns), do: []

  defp palette_slug(value),
    do: value |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")

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
