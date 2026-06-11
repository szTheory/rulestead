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
  slot(:inner_block, required: true)

  def page(assigns) do
    theme_default = normalize_theme_default(assigns.theme_default)
    resolved_env_options = env_options(assigns)

    assigns =
      assigns
      |> assign(:theme_default, theme_default)
      |> assign(:initial_theme_attr, explicit_theme_attr(theme_default))
      |> assign(:env_tone, env_tone(assigns.current_environment))
      |> assign(:resolved_env_options, resolved_env_options)
      |> assign(
        :current_env_option,
        current_env_option(resolved_env_options, assigns.current_environment)
      )
      |> assign(:flash_entries, flash_entries(assigns.flash))
      |> assign(:nav_groups, nav_groups(assigns))
      |> assign(:nav_overview, nav_overview(assigns))
      |> assign(:palette_groups, palette_groups(assigns))
      |> assign(:resolved_breadcrumbs, resolved_breadcrumbs(assigns))
      |> assign(:brand_href, brand_href(assigns))

    ~H"""
    <div
      class="rs-shell"
      data-env-tone={@env_tone}
      data-theme-default={@theme_default}
      data-theme={@initial_theme_attr}
      data-theme-pending
    >
      <script>
        (() => {
          const STORAGE_KEY = "rulestead_admin.theme"
          const VALID = ["system", "light", "dark"]

          const normalizeTheme = (value) => VALID.includes(value) ? value : "system"

          const readTheme = (fallback = "system") => {
            try {
              const stored = localStorage.getItem(STORAGE_KEY)
              return VALID.includes(stored) ? stored : normalizeTheme(fallback)
            } catch (_) {
              return normalizeTheme(fallback)
            }
          }

          const writeTheme = (value) => {
            try { localStorage.setItem(STORAGE_KEY, normalizeTheme(value)) } catch (_) {}
          }

          const applyTheme = (shell, value) => {
            if (!shell) return false
            const mode = normalizeTheme(value)
            const current = shell.getAttribute("data-theme")
            if (mode === "dark" || mode === "light") {
              if (current === mode) return false
              shell.setAttribute("data-theme", mode)
              return true
            }
            if (!shell.hasAttribute("data-theme")) return false
            shell.removeAttribute("data-theme")
            return true
          }

          const syncControl = (shell, value) => {
            const control = shell && shell.querySelector("#rs-theme-control")
            if (!control) return false
            const mode = normalizeTheme(value)
            const label = mode.charAt(0).toUpperCase() + mode.slice(1)
            const trigger = control.querySelector("[data-rs-theme-trigger]")
            const triggerLabel = control.querySelector("[data-rs-theme-trigger-label]")
            const triggerIcons = control.querySelectorAll("[data-rs-theme-trigger-icon]")
            if (trigger) trigger.setAttribute("aria-label", `Theme: ${label}`)
            if (triggerLabel) triggerLabel.textContent = label
            triggerIcons.forEach((icon) => { icon.hidden = icon.dataset.rsThemeTriggerIcon !== mode })
            control.querySelectorAll("[role=menuitemradio]").forEach((option) => {
              const active = option.dataset.value === mode
              option.setAttribute("aria-checked", String(active))
              option.tabIndex = active ? 0 : -1
            })
            return true
          }

          const primeShell = (shell) => {
            if (!shell) return "system"
            const mode = readTheme(shell.dataset.themeDefault || "system")
            applyTheme(shell, mode)
            if (syncControl(shell, mode)) shell.removeAttribute("data-theme-pending")
            return mode
          }

          const primeNode = (node) => {
            if (!(node instanceof Element)) return
            if (node.matches(".rs-shell")) primeShell(node)
            node.querySelectorAll && node.querySelectorAll(".rs-shell").forEach(primeShell)
          }

          const installObserver = () => {
            const existing = window.RulesteadAdminTheme
            if (existing && existing.observer) return existing.observer

            const observer = new MutationObserver((mutations) => {
              mutations.forEach((mutation) => {
                if (mutation.type === "attributes") {
                  const target = mutation.target
                  if (target instanceof Element && target.matches(".rs-shell")) primeShell(target)
                  return
                }
                mutation.addedNodes.forEach(primeNode)
              })
            })

            observer.observe(document.documentElement, {
              childList: true,
              subtree: true,
              attributes: true,
              attributeFilter: ["data-theme", "data-theme-pending"]
            })

            return observer
          }

          const api = {
            normalizeTheme,
            readTheme,
            writeTheme,
            applyTheme,
            syncControl,
            primeShell,
            observer: installObserver()
          }

          window.RulesteadAdminTheme = Object.assign(window.RulesteadAdminTheme || {}, api)
          primeShell(document.currentScript && document.currentScript.closest(".rs-shell"))
        })()
      </script>
      <header class="rs-shell__header">
        <div class="rs-shell__intro">
          <div class="rs-shell__brand-row">
            <.brand_lockup href={@brand_href} />
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
        <div class="rs-shell__controls" role="group" aria-label="Global controls">
          <section :if={@policy_state} class="rs-shell__access" aria-label="Access">
            <p
              class="rs-shell__access-readout"
              aria-label={access_title(Map.get(@policy_state, :capabilities))}
              title={access_title(Map.get(@policy_state, :capabilities))}
              data-capability={capability_attr(Map.get(@policy_state, :capabilities))}
            >
              <span class="rs-shell__access-label">Access</span>
              <span class="rs-shell__access-value">
                <%= highest_capability(Map.get(@policy_state, :capabilities)) %>
              </span>
            </p>
          </section>
          <section
            :if={@resolved_env_options != []}
            class="rs-shell__context rs-shell__context--environment"
            aria-labelledby="rs-env-context-label"
            aria-describedby={if(@env_context_help, do: "rs-env-context-help", else: nil)}
          >
            <p class="sr-only" id="rs-env-context-label"><%= @env_context_label %></p>
            <div
              :if={length(@resolved_env_options) == 1}
              class="rs-shell__scope-static rs-shell__env-static"
              data-env-tone={@current_env_option.tone}
              title={@current_env_option.title || @current_env_option.name}
            >
              <span class="rs-env-switcher__tone" aria-hidden="true"></span>
              <span class="rs-env-switcher__trigger-label"><%= @current_env_option.name %></span>
            </div>
            <div
              :if={length(@resolved_env_options) > 1}
              id="rs-env-switcher"
              class="rs-env-switcher"
              phx-hook=".EnvSwitcher"
              data-current-env={@current_env_option.key}
            >
              <button
                id="rs-env-trigger"
                type="button"
                class="rs-env-switcher__trigger"
                aria-haspopup="menu"
                aria-expanded="false"
                aria-controls="rs-env-menu"
                aria-label={env_trigger_label(@current_env_option)}
                data-rs-env-trigger
                data-env-tone={@current_env_option.tone}
              >
                <span class="rs-env-switcher__tone" aria-hidden="true"></span>
                <span class="rs-env-switcher__trigger-label">
                  <%= @current_env_option.name %>
                </span>
                <span class="rs-env-switcher__chevron" aria-hidden="true">
                  <svg viewBox="0 0 20 20" fill="none" focusable="false">
                    <path d="m6.5 8 3.5 3.5L13.5 8" />
                  </svg>
                </span>
              </button>
              <div
                id="rs-env-menu"
                role="menu"
                aria-labelledby="rs-env-context-label"
                class="rs-env-switcher__menu"
                hidden
                data-rs-env-menu
              >
              <%= for option <- @resolved_env_options do %>
                <.link
                  :if={option.available? and not option.current?}
                  href={plain_href(option.href)}
                  navigate={live_navigate(option.href)}
                  class="rs-env-switcher__option"
                  role="menuitemradio"
                  aria-checked="false"
                  aria-label={env_option_aria_label(option)}
                  tabindex="-1"
                  data-current={to_string(option.current?)}
                  data-available={to_string(option.available?)}
                  data-env-tone={option.tone}
                  data-rs-env-option
                  title={option.title}
                >
                  <span class="rs-env-switcher__option-tone" aria-hidden="true"></span>
                  <span class="rs-env-switcher__option-copy">
                    <span><%= option.name %></span>
                  </span>
                  <span class="rs-env-switcher__check" aria-hidden="true">
                    <svg viewBox="0 0 20 20" fill="none" focusable="false">
                      <path d="m5 10.5 3.25 3.25L15 6.5" />
                    </svg>
                  </span>
                </.link>
                <span
                  :if={!option.available? or option.current?}
                  class="rs-env-switcher__option"
                  role="menuitemradio"
                  aria-checked={to_string(option.current?)}
                  aria-disabled={if(option.available?, do: nil, else: "true")}
                  aria-label={env_option_aria_label(option)}
                  tabindex={env_option_tabindex(option)}
                  data-current={to_string(option.current?)}
                  data-available={to_string(option.available?)}
                  data-env-tone={option.tone}
                  data-rs-env-option
                  title={option.title}
                >
                  <span class="rs-env-switcher__option-tone" aria-hidden="true"></span>
                  <span class="rs-env-switcher__option-copy">
                    <span><%= option.name %></span>
                    <span :if={option.current?}>Current</span>
                    <span :if={!option.available?}>Not configured</span>
                  </span>
                  <span class="rs-env-switcher__check" aria-hidden="true">
                    <svg viewBox="0 0 20 20" fill="none" focusable="false">
                      <path d="m5 10.5 3.25 3.25L15 6.5" />
                    </svg>
                  </span>
                </span>
              <% end %>
              </div>
            </div>
            <p :if={@env_context_help} class="sr-only" id="rs-env-context-help"><%= @env_context_help %></p>
          </section>
          <script :type={Phoenix.LiveView.ColocatedHook} name=".EnvSwitcher" runtime>
            {
              mounted() {
                const ctrl = this.el
                const trigger = ctrl.querySelector("[data-rs-env-trigger]")
                const menu = ctrl.querySelector("[data-rs-env-menu]")
                const options = () => Array.from(ctrl.querySelectorAll("[data-rs-env-option]"))
                const currentIndex = () => {
                  const index = options().findIndex((option) => option.dataset.current === "true")
                  return index >= 0 ? index : 0
                }
                const focusOption = (index) => {
                  const currentOptions = options()
                  if (currentOptions.length === 0) return
                  const next = ((index % currentOptions.length) + currentOptions.length) % currentOptions.length
                  currentOptions.forEach((option, optionIndex) => {
                    option.tabIndex = optionIndex === next ? 0 : -1
                  })
                  currentOptions[next].focus()
                }
                const sync = () => {
                  options().forEach((option) => {
                    option.tabIndex = option.dataset.current === "true" ? 0 : -1
                  })
                }
                const setOpen = (open, focusTarget = "trigger") => {
                  if (!trigger || !menu) return
                  menu.hidden = !open
                  ctrl.dataset.open = String(open)
                  trigger.setAttribute("aria-expanded", String(open))
                  if (open && focusTarget === "selected") requestAnimationFrame(() => focusOption(currentIndex()))
                  if (open && focusTarget === "first") requestAnimationFrame(() => focusOption(0))
                  if (open && focusTarget === "last") requestAnimationFrame(() => focusOption(options().length - 1))
                  if (!open && focusTarget === "trigger") trigger.focus()
                }
                const activateOption = (option) => {
                  if (!option) return
                  if (
                    option.matches("a") &&
                    option.dataset.available !== "false" &&
                    option.dataset.current !== "true"
                  ) {
                    setOpen(false, "none")
                    option.click()
                  } else {
                    setOpen(false, "trigger")
                  }
                }

                this._sync = sync
                this._setOpen = setOpen
                sync()

                this._onClick = (e) => {
                  const triggerEl = e.target.closest("[data-rs-env-trigger]")
                  if (triggerEl) {
                    e.preventDefault()
                    setOpen(menu.hidden, menu.hidden ? "selected" : "trigger")
                    return
                  }

                  const option = e.target.closest("[data-rs-env-option]")
                  if (!option) return
                  if (option.dataset.current === "true" || option.dataset.available === "false") {
                    e.preventDefault()
                    setOpen(false, "trigger")
                  } else {
                    setOpen(false, "none")
                  }
                }
                ctrl.addEventListener("click", this._onClick)

                this._onKeydown = (e) => {
                  const currentOptions = options()
                  const current = Math.max(0, currentOptions.indexOf(document.activeElement))
                  let next = -1

                  if (e.target.closest("[data-rs-env-trigger]")) {
                    if (e.key === "Escape") {
                      e.preventDefault(); setOpen(false, "trigger")
                    } else if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
                      e.preventDefault(); setOpen(true, "selected")
                    } else if (e.key === "ArrowUp") {
                      e.preventDefault(); setOpen(true, "last")
                    }
                    return
                  }

                  if (e.key === "Escape") {
                    e.preventDefault(); setOpen(false, "trigger")
                    return
                  }

                  if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                    e.preventDefault(); next = current + 1
                  } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                    e.preventDefault(); next = current - 1
                  } else if (e.key === "Home") {
                    e.preventDefault(); next = 0
                  } else if (e.key === "End") {
                    e.preventDefault(); next = currentOptions.length - 1
                  } else if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault(); activateOption(e.target.closest("[data-rs-env-option]"))
                    return
                  } else if (e.key === "Tab") {
                    setOpen(false, "none")
                  }

                  if (next >= 0) focusOption(next)
                }
                ctrl.addEventListener("keydown", this._onKeydown)

                this._onDocumentClick = (e) => {
                  if (!ctrl.contains(e.target)) setOpen(false, "none")
                }
                document.addEventListener("click", this._onDocumentClick)
              },

              updated() {
                if (this._sync) this._sync()
                if (this._setOpen) this._setOpen(false, "none")
              },

              destroyed() {
                if (this._onDocumentClick) document.removeEventListener("click", this._onDocumentClick)
              }
            }
          </script>
          <section
            :if={show_tenant_scope?(assigns)}
            class="rs-shell__context"
            aria-labelledby="rs-tenant-scope-label"
            aria-describedby={if(@current_tenant, do: "rs-tenant-scope-help", else: nil)}
          >
            <p class="sr-only" id="rs-tenant-scope-label">Tenant scope</p>
            <div :if={length(@tenants) > 1} class="rs-shell__scope-picker" role="list">
              <%= for tenant <- @tenants do %>
                <.link
                  href={plain_href(Map.get(@tenant_links, tenant.key, "#"))}
                  navigate={live_navigate(Map.get(@tenant_links, tenant.key, "#"))}
                  class="rs-shell__scope-link"
                  role="listitem"
                  data-current={to_string(current_tenant?(assigns, tenant))}
                >
                  <span class="rs-shell__scope-name"><%= tenant.name %></span>
                  <span :if={current_tenant?(assigns, tenant)} class="rs-shell__scope-current">
                    Current
                  </span>
                </.link>
              <% end %>
            </div>
            <p
              :if={length(@tenants) <= 1 and @current_tenant}
              class="rs-shell__scope-static rs-shell__tenant-static"
              title={"Scoped to #{@current_tenant.name}"}
            >
              <span class="rs-shell__scope-name"><%= @current_tenant.name %></span>
            </p>
            <p :if={@current_tenant} class="sr-only" id="rs-tenant-scope-help">
              Scoped to <%= @current_tenant.name %>.
            </p>
          </section>
          <section class="rs-shell__context rs-shell__context--theme" aria-label="Theme">
            <p class="sr-only" id="rs-theme-label">Theme</p>
            <div
              id="rs-theme-control"
              phx-hook=".ThemeControl"
              data-theme-default={@theme_default}
              class="rs-theme-control"
            >
              <button
                id="rs-theme-trigger"
                type="button"
                class="rs-theme-control__trigger"
                aria-haspopup="menu"
                aria-expanded="false"
                aria-controls="rs-theme-menu"
                aria-label={"Theme: " <> theme_label(@theme_default)}
                data-rs-theme-trigger
              >
                <span class="rs-theme-control__trigger-icon" aria-hidden="true">
                  <span
                    :for={option <- theme_options()}
                    data-rs-theme-trigger-icon={option.value}
                    hidden={@theme_default != option.value}
                  >
                    <.theme_icon name={option.value} />
                  </span>
                </span>
                <span class="rs-theme-control__trigger-copy">
                  <span class="rs-theme-control__trigger-prefix">Theme</span>
                  <span data-rs-theme-trigger-label><%= theme_label(@theme_default) %></span>
                </span>
                <span class="rs-theme-control__chevron" aria-hidden="true">
                  <svg viewBox="0 0 20 20" fill="none" focusable="false">
                    <path d="m6.5 8 3.5 3.5L13.5 8" />
                  </svg>
                </span>
              </button>
              <div
                id="rs-theme-menu"
                role="menu"
                aria-labelledby="rs-theme-label"
                class="rs-theme-control__menu"
                hidden
                data-rs-theme-menu
              >
                <button
                  :for={option <- theme_options()}
                  type="button"
                  role="menuitemradio"
                  aria-checked={theme_checked?(@theme_default, option.value)}
                  tabindex={theme_tabindex(@theme_default, option.value)}
                  data-value={option.value}
                  class="rs-theme-control__option"
                >
                  <span class="rs-theme-control__option-icon" aria-hidden="true">
                    <.theme_icon name={option.value} />
                  </span>
                  <span class="rs-theme-control__option-copy">
                    <span><%= option.label %></span>
                    <span><%= option.description %></span>
                  </span>
                  <span class="rs-theme-control__check" aria-hidden="true">
                    <svg viewBox="0 0 20 20" fill="none" focusable="false">
                      <path d="m5 10.5 3.25 3.25L15 6.5" />
                    </svg>
                  </span>
                </button>
              </div>
            </div>
            <script>
              (() => {
                const shell = document.currentScript && document.currentScript.closest(".rs-shell")
                if (window.RulesteadAdminTheme && shell) window.RulesteadAdminTheme.primeShell(shell)
              })()
            </script>
          </section>
        </div>
      </header>

      <div class="rs-shell__layout">
        <nav :if={@nav_groups != []} class="rs-shell__rail" aria-label="Primary navigation">
          <div :if={@nav_overview} class="rs-shell__rail-group">
            <.link
              href={plain_href(@nav_overview.path)}
              navigate={live_navigate(@nav_overview.path)}
              class="rs-shell__rail-link rs-shell__rail-link--overview"
              aria-current={if(@nav_overview.current?, do: "page", else: nil)}
            >
              <%= @nav_overview.label %>
            </.link>
          </div>
          <div :for={group <- @nav_groups} class="rs-shell__rail-group">
            <p class="rs-shell__rail-group-title"><%= group.title %></p>
            <.link
              :for={item <- group.items}
              href={plain_href(item.path)}
              navigate={live_navigate(item.path)}
              class="rs-shell__rail-link"
              aria-current={if(item.current?, do: "page", else: nil)}
            >
              <%= item.label %>
            </.link>
          </div>
        </nav>

        <main class="rs-shell__main">
          <section class="rs-shell__page-intro" aria-labelledby="rs-shell-page-title">
            <nav :if={@resolved_breadcrumbs != []} aria-label="Breadcrumb" class="rs-shell__breadcrumbs">
              <ol>
                <li :for={{crumb, index} <- Enum.with_index(@resolved_breadcrumbs)}>
                  <.link
                    :if={!last_breadcrumb?(@resolved_breadcrumbs, index) and breadcrumb_path(crumb)}
                    href={plain_href(breadcrumb_path(crumb))}
                    navigate={live_navigate(breadcrumb_path(crumb))}
                    class="rs-shell__breadcrumb-link"
                  >
                    <%= breadcrumb_label(crumb) %>
                  </.link>
                  <span
                    :if={last_breadcrumb?(@resolved_breadcrumbs, index) or is_nil(breadcrumb_path(crumb))}
                    class="rs-shell__breadcrumb-current"
                    aria-current={if(last_breadcrumb?(@resolved_breadcrumbs, index), do: "page", else: nil)}
                  >
                    <%= breadcrumb_label(crumb) %>
                  </span>
                  <span :if={index < length(@resolved_breadcrumbs) - 1} class="rs-shell__breadcrumb-separator" aria-hidden="true">/</span>
                </li>
              </ol>
            </nav>

            <h1 id="rs-shell-page-title" class="sr-only"><%= @page_title %></h1>
            <p class="rs-shell__page-summary"><%= @page_summary %></p>
          </section>

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
              <.link
                :for={item <- items}
                id={"rs-cmdk-opt-" <> item.id}
                role="option"
                aria-selected="false"
                href={plain_href(item.href)}
                navigate={live_navigate(item.href)}
                data-keywords={item.keywords}
                class="rs-cmdk__option"
              >
                <span class="rs-cmdk__option-label"><%= item.label %></span>
                <span :if={item.hint} class="rs-cmdk__option-hint"><%= item.hint %></span>
              </.link>
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
                  if (sel) sel.click()
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
            const VALID = ["system", "light", "dark"]
            const trigger = ctrl.querySelector("[data-rs-theme-trigger]")
            const menu = ctrl.querySelector("[data-rs-theme-menu]")
            const themeApi = window.RulesteadAdminTheme || {}
            const normalize = (value) => {
              if (themeApi.normalizeTheme) return themeApi.normalizeTheme(value)
              return VALID.includes(value) ? value : "system"
            }
            const labelFor = (value) => {
              const mode = normalize(value)
              return mode.charAt(0).toUpperCase() + mode.slice(1)
            }
            const opts = () => Array.from(ctrl.querySelectorAll("[role=menuitemradio]"))
            const currentIndex = () => {
              const current = normalize(this._mode || "system")
              const index = opts().findIndex(o => normalize(o.dataset.value) === current)
              return index >= 0 ? index : 0
            }
            const focusOption = (index) => {
              const currentOpts = opts()
              if (currentOpts.length === 0) return
              const next = ((index % currentOpts.length) + currentOpts.length) % currentOpts.length
              currentOpts[next].focus()
            }
            const setOpen = (open, focusTarget = "trigger") => {
              if (!trigger || !menu) return
              menu.hidden = !open
              ctrl.dataset.open = String(open)
              trigger.setAttribute("aria-expanded", String(open))
              if (open && focusTarget === "selected") requestAnimationFrame(() => focusOption(currentIndex()))
              if (open && focusTarget === "first") requestAnimationFrame(() => focusOption(0))
              if (open && focusTarget === "last") requestAnimationFrame(() => focusOption(opts().length - 1))
              if (!open && focusTarget === "trigger") trigger.focus()
            }
            const selectOption = (opt, restoreFocus = true) => {
              if (!opt) return
              const val = normalize(opt.dataset.value)
              writeTheme(val)
              applyTheme(val)
              this._syncAria()
              setOpen(false, restoreFocus ? "trigger" : "none")
            }

            const readTheme = () => {
              const fallback = normalize(ctrl.dataset.themeDefault || "system")
              if (themeApi.readTheme) return themeApi.readTheme(fallback)
              try {
                const v = localStorage.getItem("rulestead_admin.theme")
                return VALID.includes(v) ? v : fallback
              } catch (_) { return fallback }
            }

            const writeTheme = (val) => {
              if (themeApi.writeTheme) themeApi.writeTheme(val)
              else {
                try { localStorage.setItem("rulestead_admin.theme", normalize(val)) } catch (_) {}
              }
            }

            const applyTheme = (val) => {
              const mode = normalize(val)
              const before = shell.getAttribute("data-theme")
              this._mode = mode

              if (themeApi.applyTheme) themeApi.applyTheme(shell, mode)
              else if (mode === "dark") shell.setAttribute("data-theme", "dark")
              else if (mode === "light") shell.setAttribute("data-theme", "light")
              else shell.removeAttribute("data-theme")

              const after = shell.getAttribute("data-theme")
              if (before !== after) {
                shell.setAttribute("data-theme-switching", "")
                requestAnimationFrame(() => shell.removeAttribute("data-theme-switching"))
              }
            }

            this._syncAria = () => {
              const current = normalize(this._mode || "system")
              const label = labelFor(current)
              if (trigger) trigger.setAttribute("aria-label", `Theme: ${label}`)
              const triggerLabel = ctrl.querySelector("[data-rs-theme-trigger-label]")
              if (triggerLabel) triggerLabel.textContent = label
              ctrl.querySelectorAll("[data-rs-theme-trigger-icon]").forEach((icon) => {
                icon.hidden = icon.dataset.rsThemeTriggerIcon !== current
              })
              opts().forEach((opt) => {
                const isActive = normalize(opt.dataset.value) === current
                opt.setAttribute("aria-checked", String(isActive))
                opt.tabIndex = isActive ? 0 : -1
              })
            }

            this._applyTheme = applyTheme
            this._readTheme = readTheme

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
              const triggerEl = e.target.closest("[data-rs-theme-trigger]")
              if (triggerEl) {
                e.preventDefault()
                setOpen(menu.hidden, menu.hidden ? "selected" : "trigger")
                return
              }

              const opt = e.target.closest("[role=menuitemradio]")
              if (opt) {
                e.preventDefault()
                selectOption(opt)
              }
            }
            ctrl.addEventListener("click", this._onClick)

            this._onKeydown = (e) => {
              const currentOpts = opts()
              const current = Math.max(0, currentOpts.indexOf(document.activeElement))
              let next = -1

              if (e.target.closest("[data-rs-theme-trigger]")) {
                if (e.key === "Escape") {
                  e.preventDefault(); setOpen(false, "trigger")
                } else if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
                  e.preventDefault(); setOpen(true, "selected")
                } else if (e.key === "ArrowUp") {
                  e.preventDefault(); setOpen(true, "last")
                }
                return
              }

              if (e.key === "Escape") {
                e.preventDefault(); setOpen(false, "trigger")
                return
              }

              if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                e.preventDefault(); next = current + 1
              } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                e.preventDefault(); next = current - 1
              } else if (e.key === "Home") {
                e.preventDefault(); next = 0
              } else if (e.key === "End") {
                e.preventDefault(); next = currentOpts.length - 1
              } else if (e.key === "Enter" || e.key === " ") {
                e.preventDefault(); selectOption(e.target.closest("[role=menuitemradio]"))
                return
              } else if (e.key === "Tab") {
                setOpen(false, "none")
              }
              if (next >= 0) {
                focusOption(next)
              }
            }
            ctrl.addEventListener("keydown", this._onKeydown)

            this._onDocumentClick = (e) => {
              if (!ctrl.contains(e.target)) setOpen(false, "none")
            }
            document.addEventListener("click", this._onDocumentClick)
          },

          updated() {
            if (this._applyTheme) this._applyTheme(this._mode || this._readTheme())
            this._syncAria()
          },

          destroyed() {
            if (this._mq && this._mqListener) this._mq.removeEventListener("change", this._mqListener)
            if (this._onDocumentClick) document.removeEventListener("click", this._onDocumentClick)
            // Defensive: if torn down in the same tick as a toggle (before the rAF
            // clears it), don't leave transitions permanently suppressed.
            const shell = this.el.closest(".rs-shell")
            if (shell) shell.removeAttribute("data-theme-switching")
          }
        }
      </script>
    </div>
    """
  end

  defp brand_lockup(assigns) do
    ~H"""
    <.link
      :if={@href}
      href={plain_href(@href)}
      navigate={live_navigate(@href)}
      class="rs-shell__brand"
      aria-label="Rulestead overview"
    >
      <.brand_wordmark />
    </.link>
    <span :if={is_nil(@href)} class="rs-shell__brand">
      <.brand_wordmark />
    </span>
    """
  end

  defp brand_wordmark(assigns) do
    ~H"""
    <svg
      class="rs-shell__wordmark"
      viewBox="0 0 372 64"
      aria-hidden="true"
      focusable="false"
      preserveAspectRatio="xMinYMid meet"
    >
      <g>
        <rect class="rs-shell__wordmark-line" width="7.5" height="39.5" x="30" y="13" rx="1" />
        <rect class="rs-shell__wordmark-line" width="20" height="7.5" x="12" y="28.25" rx="1" />
        <circle class="rs-shell__wordmark-line" cx="12" cy="32" r="6.5" />
        <rect class="rs-shell__wordmark-active" width="14" height="7.5" x="32" y="12.25" rx="1" />
        <circle class="rs-shell__wordmark-active" cx="50" cy="16" r="6.5" />
        <rect class="rs-shell__wordmark-line" width="14" height="7.5" x="32" y="28.25" rx="1" />
        <circle class="rs-shell__wordmark-muted" cx="50" cy="32" r="6.5" />
        <rect class="rs-shell__wordmark-line" width="14" height="7.5" x="32" y="44.25" rx="1" />
        <circle class="rs-shell__wordmark-muted" cx="50" cy="48" r="6.5" />
        <path
          class="rs-shell__wordmark-type"
          d="M78.493 52V11.675h8.985V52Zm24.272 0L91.04 34.796h9.862L113.175 52ZM85.068 39.18v-7.07h9.862q1.972 0 3.424-.794 1.452-.795 2.247-2.247t.794-3.37q0-1.917-.794-3.369-.795-1.452-2.247-2.246-1.452-.795-3.424-.795h-9.862v-7.615h9.15q4.985 0 8.656 1.506t5.644 4.466 1.972 7.451v.877q0 4.438-2 7.369t-5.643 4.383-8.63 1.452Zm43.068 13.751q-5.205 0-8-3.37t-2.794-10.163V21.975h8.767v17.862q0 2.41 1.37 3.835t3.67 1.424q2.356 0 3.836-1.479t1.479-4V21.975h8.766V52h-6.958V39.344h.603q0 4.547-1.178 7.588-1.178 3.04-3.48 4.52-2.3 1.48-5.698 1.48ZM153.723 52V12.003h8.821V52Zm-3.561-33.531v-6.466h12.382v6.466Zm34.19 34.572q-3.835 0-6.767-1.315-2.93-1.315-4.876-3.534-1.945-2.219-2.959-4.986-1.013-2.767-1.013-5.67V36.44q0-3.014 1.013-5.78 1.014-2.768 2.932-4.96 1.917-2.19 4.794-3.478t6.547-1.288q4.822 0 8.137 2.164 3.314 2.164 5.068 5.644t1.753 7.588v2.959h-26.573v-4.986h21.258l-2.849 2.301q0-2.685-.767-4.602t-2.274-2.932-3.753-1.013q-2.301 0-3.89 1.04-1.589 1.042-2.41 3.042t-.822 4.903q0 2.685.767 4.685t2.41 3.096q1.644 1.095 4.274 1.095 2.41 0 3.945-.931 1.534-.932 2.082-2.301h8.054q-.657 3.013-2.575 5.37-1.918 2.355-4.822 3.67t-6.684 1.315m31.834-.11q-6.41 0-10.027-2.63t-3.835-7.396h7.78q.22 1.424 1.726 2.548 1.507 1.123 4.52 1.123 2.302 0 3.808-.795 1.507-.794 1.507-2.273 0-1.315-1.15-2.11-1.151-.794-4.11-1.123l-2.356-.22q-5.424-.547-8.136-3.013t-2.712-6.3q0-3.178 1.589-5.315t4.41-3.233 6.438-1.096q5.808 0 9.37 2.548 3.56 2.548 3.725 7.37h-7.78q-.22-1.48-1.534-2.494-1.315-1.013-3.89-1.013-2.028 0-3.233.767t-1.205 2.082q0 1.26 1.04 1.918 1.042.657 3.398.931l2.355.22q5.534.602 8.603 3.067t3.068 6.63q0 3.013-1.644 5.232t-4.657 3.397-7.068 1.178m32.716-.547q-4.547 0-7.341-1.124-2.795-1.123-4.082-3.78-1.288-2.657-1.288-7.205V13.866h8.164v26.738q0 2.136 1.123 3.26t3.205 1.123h4.438v7.397Zm-17.258-23.998v-6.41h21.477v6.41Zm41.148 24.655q-3.835 0-6.767-1.315-2.93-1.315-4.876-3.534-1.945-2.219-2.959-4.986-1.013-2.767-1.013-5.67V36.44q0-3.014 1.013-5.78 1.014-2.768 2.932-4.96 1.917-2.19 4.794-3.478t6.547-1.288q4.822 0 8.137 2.164 3.314 2.164 5.068 5.644t1.753 7.588v2.959h-26.573v-4.986h21.258l-2.849 2.301q0-2.685-.767-4.602t-2.274-2.932-3.753-1.013q-2.301 0-3.89 1.04-1.589 1.042-2.41 3.042t-.822 4.903q0 2.685.767 4.685t2.41 3.096 4.274 1.095q2.41 0 3.945-.931 1.534-.932 2.082-2.301h8.054q-.657 3.013-2.575 5.37-1.918 2.355-4.822 3.67t-6.684 1.315M311.365 52v-8.876h-1.48v-9.643q0-2.301-1.095-3.452-1.096-1.15-3.507-1.15-1.205 0-3.177.054-1.973.055-4.055.165t-3.78.219V21.92q1.26-.11 2.958-.219 1.699-.11 3.507-.164t3.397-.055q4.602 0 7.753 1.315t4.794 3.972 1.643 6.822V52Zm-9.588.767q-3.233 0-5.67-1.15-2.439-1.151-3.809-3.315-1.37-2.165-1.37-5.178 0-3.287 1.699-5.397 1.698-2.11 4.767-3.123 3.068-1.013 7.068-1.013h6.41v4.876h-6.465q-2.301 0-3.534 1.123t-1.233 3.04q0 1.809 1.233 2.932t3.534 1.123q1.48 0 2.657-.52t1.945-1.78.877-3.507l2.082 2.191q-.274 3.123-1.507 5.26t-3.397 3.287-5.287 1.151m36.385.219q-3.178 0-5.78-1.15-2.603-1.151-4.52-3.206-1.918-2.054-2.932-4.849-1.013-2.794-1.013-6.026v-1.26q0-3.233.959-6.027.958-2.795 2.794-4.904 1.835-2.11 4.41-3.288t5.753-1.178q3.617 0 6.247 1.562 2.63 1.561 4.109 4.602t1.643 7.48l-2.3-2.138v-20.6h8.82V52h-6.958V39.563h1.206q-.165 4.273-1.781 7.287-1.616 3.013-4.356 4.575-2.74 1.561-6.3 1.561m2.192-7.342q2.027 0 3.698-.904t2.685-2.657 1.013-4.219v-2.027q0-2.41-1.04-4.055-1.042-1.643-2.74-2.52-1.699-.876-3.671-.876-2.192 0-3.917 1.123-1.726 1.123-2.713 3.068-.986 1.945-.986 4.52 0 2.63.986 4.548.987 1.917 2.74 2.958t3.945 1.041"
        />
      </g>
    </svg>
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
        for(
          group <- nav,
          item <- group.items,
          do: %{label: item.label, href: item.path, hint: group.title}
        )

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
          |> Map.put(
            :keywords,
            String.downcase("#{item.label} #{Map.get(item, :hint, "")} #{title}")
          )
        end)

      {title, finalized}
    end)
  end

  defp palette_groups(_assigns), do: []

  defp palette_slug(value),
    do: value |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")

  defp theme_options do
    [
      %{value: "system", label: "System", description: "Follow device"},
      %{value: "light", label: "Light", description: "Light interface"},
      %{value: "dark", label: "Dark", description: "Dark interface"}
    ]
  end

  defp theme_label(value) do
    value
    |> normalize_theme_default()
    |> String.capitalize()
  end

  attr(:name, :string, required: true)

  defp theme_icon(assigns) do
    ~H"""
    <svg :if={@name == "system"} viewBox="0 0 20 20" fill="none" focusable="false">
      <rect width="12.5" height="8.5" x="3.75" y="4.25" rx="1.5" />
      <path d="M7.5 15.75h5M10 12.75v3" />
    </svg>
    <svg :if={@name == "light"} viewBox="0 0 20 20" fill="none" focusable="false">
      <circle cx="10" cy="10" r="3.25" />
      <path d="M10 2.75v2M10 15.25v2M4.88 4.88 6.3 6.3M13.7 13.7l1.42 1.42M2.75 10h2M15.25 10h2M4.88 15.12 6.3 13.7M13.7 6.3l1.42-1.42" />
    </svg>
    <svg :if={@name == "dark"} viewBox="0 0 20 20" fill="none" focusable="false">
      <path d="M14.9 12.96A6.1 6.1 0 0 1 7.04 5.1 6.85 6.85 0 1 0 14.9 12.96Z" />
    </svg>
    """
  end

  defp normalize_theme_default(value) when value in ["light", "dark"], do: value
  defp normalize_theme_default(_value), do: "system"

  defp explicit_theme_attr("light"), do: "light"
  defp explicit_theme_attr("dark"), do: "dark"
  defp explicit_theme_attr(_value), do: nil

  defp theme_checked?(current, value), do: to_string(current == value)
  defp theme_tabindex(current, value) when current == value, do: "0"
  defp theme_tabindex(_current, _value), do: "-1"

  defp resolved_breadcrumbs(%{breadcrumbs: [_ | _] = breadcrumbs}), do: breadcrumbs

  defp resolved_breadcrumbs(assigns) do
    label = current_section_label(assigns) || assigns.page_title

    if is_binary(label) and label != "" do
      [%{label: label}]
    else
      []
    end
  end

  defp current_section_label(%{current_section: :home}), do: "Overview"

  defp current_section_label(%{base_path: base_path, current_section: current_section} = assigns)
       when is_binary(base_path) and not is_nil(current_section) do
    env_key = Map.get(assigns.current_environment || %{}, :key)

    base_path
    |> Navigation.items(env_key, current_section)
    |> Enum.find_value(fn
      %{key: ^current_section, label: label} -> label
      _item -> nil
    end)
  end

  defp current_section_label(_assigns), do: nil

  defp brand_href(%{base_path: base_path, current_environment: environment})
       when is_binary(base_path) and base_path != "" do
    env_key = Map.get(environment || %{}, :key)

    base_path
    |> Navigation.overview(env_key)
    |> Map.fetch!(:path)
  end

  defp brand_href(_assigns), do: nil

  defp last_breadcrumb?(breadcrumbs, index), do: index == length(breadcrumbs) - 1

  defp breadcrumb_label(crumb), do: Map.get(crumb, :label) || Map.get(crumb, "label")
  defp breadcrumb_path(crumb), do: Map.get(crumb, :path) || Map.get(crumb, "path")

  defp live_navigate(path) when is_binary(path) do
    if String.starts_with?(path, "/") and not String.starts_with?(path, "//"), do: path
  end

  defp live_navigate(_path), do: nil

  defp plain_href(path) when is_binary(path) do
    if live_navigate(path), do: nil, else: path
  end

  defp plain_href(_path), do: "#"

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

  defp current_env_option(options, current_environment) do
    current_key = Map.get(current_environment || %{}, :key)

    Enum.find(options, & &1.current?) ||
      Enum.find(options, &(Map.get(&1, :key) == current_key)) ||
      List.first(options)
  end

  defp env_trigger_label(nil), do: "Environment"
  defp env_trigger_label(option), do: "Environment: #{option.name}"

  defp env_option_aria_label(%{current?: true, available?: false} = option),
    do: "#{option.name}, current environment, not configured"

  defp env_option_aria_label(%{current?: true} = option),
    do: "#{option.name}, current environment"

  defp env_option_aria_label(%{available?: false} = option),
    do: "#{option.name}, not configured"

  defp env_option_aria_label(option), do: "Switch to #{option.name}"

  defp env_option_tabindex(%{current?: true}), do: "0"
  defp env_option_tabindex(_option), do: "-1"

  defp highest_capability(%{admin?: true}), do: "Admin"
  defp highest_capability(%{execute?: true}), do: "Execute"
  defp highest_capability(%{edit?: true}), do: "Edit"
  defp highest_capability(%{propose?: true}), do: "Propose"
  defp highest_capability(%{read?: true}), do: "Read-only"
  defp highest_capability(_capabilities), do: "No access"

  defp access_title(caps) do
    "You have #{highest_capability(caps)} access in this environment. " <>
      capability_summary(caps)
  end

  defp capability_attr(caps) do
    caps
    |> highest_capability()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp capability_summary(nil), do: "No capabilities defined"

  defp capability_summary(caps) do
    "Permissions - Read: #{Map.get(caps, :read?, false)}, Edit: #{Map.get(caps, :edit?, false)}, Execute: #{Map.get(caps, :execute?, false)}, Propose: #{Map.get(caps, :propose?, false)}, Admin: #{Map.get(caps, :admin?, false)}"
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
