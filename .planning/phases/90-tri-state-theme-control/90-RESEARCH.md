# Phase 90: Tri-State Theme Control + Persistence + FOUC — Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView ColocatedHook (runtime), localStorage persistence, FOUC suppression, ARIA radiogroup, Playwright fixture testing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- localStorage key `rulestead_admin.theme`, values `system|light|dark`. Per-device, client-only. No cookies, no host session, no server round-trip.
- Colocated `ColocatedHook` runtime hook (mirror `.CmdK`) named `.ThemeControl`, attached to the segmented control element via `phx-hook=".ThemeControl"`.
- Segmented control: `role="radiogroup"`, three `role="radio"`/button options, roving tabindex + arrow-key nav, `aria-checked` on the active option, accessible label "Theme". Reuse `.rs-flag-subnav__tab`/segmented visual pattern.
- On select: write localStorage → set/remove `data-theme` on `.rs-shell` (remove for `system`) → update `aria-checked`. On `system`: remove `data-theme` and let `matchMedia` drive; add a matchMedia listener that no-ops unless current mode is `system`.
- FOUC: System = flash-free via CSS `@media`. Pinned = `data-theme-pending` + transition-suppression → instant snap in `mounted()`. Hook removes `data-theme-pending` after applying.
- Optional `attr :theme_default, :string, default: "system"` on `Shell.page/1`.
- Document optional copy-paste host `<head>` snippet — NOT required.
- CSS for segmented control + `[data-theme-pending] * { transition: none }` suppression using existing tokens.

### Claude's Discretion
- Exact hook name, element ids/data-attrs, and the precise markup of the segmented control (match shell.ex conventions).
- Whether `data-theme-pending` is set in HEEx (server render) and cleared by the hook, vs set/cleared entirely client-side — pick whatever gives the cleanest no-flash for pinned users given the hook runs post-mount.

### Deferred Ideas (OUT OF SCOPE)
- Per-host theme branding palette → Future (THM-07).
- Motion choreography of the theme switch beyond the no-flash snap → Phase 94 (must not conflict with `[data-theme-pending]` suppression).
- Design-system documentation of the control → Phase 91.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THM-02 | Operator can choose System / Light / Dark from a control in the admin shell, and the choice persists across reloads on that device. | localStorage + `.ThemeControl` hook + segmented control markup |
| THM-04 | First paint shows the correct theme with no visible flash for System users; a pinned-theme correction is an instant snap, never an animated wipe. | `data-theme-pending` + `[data-theme-pending] * { transition: none }` + synchronous `mounted()` set |
</phase_requirements>

---

## Summary

Phase 90 adds the operator-facing tri-state theme control to the `rulestead_admin` shell header. The technical work has three parts: (1) a colocated runtime LiveView JS hook (`.ThemeControl`) that reads/writes `localStorage` and sets/removes `data-theme` on `.rs-shell`; (2) a `role="radiogroup"` segmented control with roving tabindex and `aria-checked` for a11y; and (3) FOUC suppression via a `data-theme-pending` attribute and a CSS transition-suppression rule so pinned users get an instant snap rather than an animated wipe.

The most novel/risky aspects are all definitively resolvable: the `.`-prefixed `runtime` colocated hook mechanism is well-understood from the existing `.CmdK` implementation and the LiveView source confirms it auto-registers at runtime with zero host LiveSocket wiring. The `mounted()` lifecycle fires after LiveView DOM patching is complete (post-server-join), meaning pinned users who mismatch the CSS default WILL see a brief flash if transitions are not suppressed — the `data-theme-pending` approach directly fixes this. The `.rs-shell` element is the LiveView root container; JS-set `data-theme` on it is NOT clobbered during LiveView patches (only `id`/`phx-session`/`phx-static`/`phx-main`/`phx-root-id` are touched on the root). The child segmented control IS patchable by LiveView morphdom, meaning `aria-checked` set by the hook can be clobbered — the hook must implement `updated()` to re-sync.

Testing can be done entirely via the existing `file://` Playwright fixture pattern (zero Phoenix, zero DB) by extending `theme-harness.html` with the control markup and an inlined copy of the hook logic. This is the preferred path; the demo DB-conflict gotcha makes the live demo unreliable for CI.

**Primary recommendation:** Mirror `.CmdK` exactly for the hook shape. Set `data-theme-pending` in HEEx server-render; clear it synchronously in `mounted()` before rAF. Place the segmented control as a new `<section>` in the header context cluster after the env picker. Add `updated()` to re-sync `aria-checked` from localStorage against LiveView patches.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Theme persistence (localStorage read/write) | Browser / Client | — | Pure client preference; no server state needed |
| FOUC suppression (`data-theme-pending` snap) | Browser / Client | Frontend Server (SSR) for `data-theme-pending` attr | Hook fires client-side; server sets the pending marker |
| `data-theme` on `.rs-shell` | Browser / Client | — | JS hook owns runtime DOM attribute; CSS cascade owns rendering |
| Segmented control markup + ARIA | Frontend Server (SSR) | — | HEEx component renders the structure; hook wires behavior |
| matchMedia / OS-change listener | Browser / Client | — | `window.matchMedia` is browser-only |
| CSS cascade + token theming | CDN / Static | — | Static CSS already live from Phase 87–88 |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Phoenix.LiveView.ColocatedHook` (runtime) | Bundled with phoenix_live_view | Ship self-contained JS hook from mounted package | Zero host build step; `.`-prefix + `runtime` = auto-registration at runtime |
| `localStorage` (Web API) | Native browser | Persist theme choice per device | No server round-trip; survives tab close; scoped by origin |
| `window.matchMedia` (Web API) | Native browser | Detect + live-track OS color scheme | Standard API; modern `addEventListener('change')` pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Playwright (existing) | Used by `examples/demo/frontend` | Fixture-based tests for persistence + a11y | File:// harness, no Phoenix needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `localStorage` | Cookies | Cookies require server read + set; violates mounted-package discipline (THM-05) |
| Runtime colocated hook | Normal colocated hook (bundled) | Bundled hooks require host build step; runtime hooks auto-register from the mounted package |
| `data-theme-pending` + transition suppression | Host `<head>` script (layer 3) | Layer 3 is optional + documented; layer 2 is the no-host-cooperation baseline |

**Installation:** No new packages. All capabilities are native browser APIs or already-present LiveView features.

---

## Package Legitimacy Audit

No external packages are introduced in this phase. All JS is native browser APIs + the already-vendored LiveView runtime. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser first paint (HTML + CSS arrive)
  │
  ├─→ .rs-shell has data-theme-pending (HEEx server-render)
  │     └─→ CSS: [data-theme-pending] * { transition: none } → transitions frozen
  │
  ├─→ @media (prefers-color-scheme: dark)
  │     └─→ .rs-shell:not([data-theme]) gets dark tokens (system users: correct at first paint)
  │
LiveView mounts (WebSocket connects, DOM patched)
  │
  ├─→ execNewMounted() → maybeAddNewHook() → .ThemeControl hook.__mounted()
  │     ├─→ Read localStorage["rulestead_admin.theme"]   (synchronous)
  │     ├─→ Apply: set/remove data-theme on .rs-shell    (synchronous, before rAF)
  │     ├─→ Sync aria-checked on radio buttons           (synchronous)
  │     ├─→ Remove data-theme-pending from .rs-shell     (synchronous)
  │     │     └─→ transitions un-frozen → no animated wipe (snap was already done)
  │     └─→ Register matchMedia listener (active only while mode === "system")
  │
User clicks System / Light / Dark
  │
  ├─→ Hook click handler
  │     ├─→ Write localStorage["rulestead_admin.theme"]
  │     ├─→ Set/remove data-theme on .rs-shell
  │     ├─→ Update aria-checked + roving tabindex
  │     └─→ If "system": attach matchMedia listener; else detach
  │
LiveView re-renders (any server push)
  │
  └─→ morphdom patches .rs-theme-control children
        └─→ hook.updated() → re-read localStorage → re-sync aria-checked
            (data-theme on .rs-shell is NOT touched — it is the LV root container)
```

### Recommended Project Structure

The control and hook are colocated in `shell.ex`. No new files needed beyond CSS rules added to `rulestead_admin.css`.

```
rulestead_admin/
├── lib/rulestead_admin/components/
│   └── shell.ex                 ← segmented control markup + .ThemeControl ColocatedHook
└── priv/static/css/
    └── rulestead_admin.css      ← .rs-theme-control rules + [data-theme-pending] suppression
```

### Pattern 1: Runtime ColocatedHook Registration

**What:** The `<script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeControl" runtime>` tag is transformed at compile time by `Phoenix.LiveView.ColocatedHook.transform/2` into:

```javascript
// [VERIFIED: /rulestead_admin/deps/phoenix_live_view/lib/phoenix_live_view/colocated_hook.ex:171]
window["phx_hook_RulesteadAdmin.Components.Shell.ThemeControl"] = function() {
  return {
    mounted() { ... },
    updated() { ... },
    destroyed() { ... }
  }
}
```

The `<script>` tag is left in the DOM with attribute `data-phx-runtime-hook="RulesteadAdmin.Components.Shell.ThemeControl"`. When LiveView mounts an element with `phx-hook=".ThemeControl"`, it calls `maybeRuntimeHook(name)` which:

```javascript
// [VERIFIED: /rulestead_admin/deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js:6155]
const runtimeHook = document.querySelector(
  `script[data-phx-runtime-hook="${CSS.escape(name)}"]`
);
let callbacks = window[`phx_hook_${name}`];
// callbacks() returns the hook object
```

**Key insight:** The `.`-prefix causes the full module name prefix — `name=".ThemeControl"` becomes `"RulesteadAdmin.Components.Shell.ThemeControl"` in the global key. The element using the hook must also use the `.`-prefixed name: `phx-hook=".ThemeControl"`. No host LiveSocket hook registration needed. [VERIFIED: colocated_hook.ex source]

**When to use:** Any time you ship JS behavior from a mounted package that must not require host build-step wiring.

**Example — hook skeleton following .CmdK pattern:**
```javascript
// Source: shell.ex:231 (existing .CmdK pattern, read directly)
<script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeControl" runtime>
  {
    mounted() {
      const shell = this.el.closest(".rs-shell")
      // ... read localStorage, set data-theme, sync aria-checked, remove data-theme-pending
      this._mq = window.matchMedia("(prefers-color-scheme: dark)")
      this._mqListener = (e) => { if (this._mode === "system") this._applySystem(e.matches) }
      this._mq.addEventListener("change", this._mqListener)
    },
    updated() {
      // Re-sync aria-checked after LiveView morphdom patches the control's children
      this._syncAria()
    },
    destroyed() {
      this._mq.removeEventListener("change", this._mqListener)
    }
  }
</script>
```

### Pattern 2: `data-theme-pending` FOUC Snap

**What:** The server-rendered HEEx sets `data-theme-pending` on `.rs-shell`. Under this attribute, a CSS rule freezes all transitions. The hook clears it synchronously in `mounted()` after applying the correct `data-theme`. This ensures the theme correction (the "snap") has no animated wipe.

**Set in HEEx (server render) — this is the correct choice:**

Setting `data-theme-pending` in HEEx is correct because:
- The attribute is present at first paint (before any JS runs)
- Transitions are frozen from the moment the HTML arrives
- The hook clears it only after `data-theme` is already set
- If JS never runs (JS disabled, slow network), the `data-theme-pending` attr stays but only causes frozen transitions — not a broken theme (CSS `@media` still works)

```html
<!-- shell.ex: .rs-shell root -->
<div class="rs-shell" data-env-tone={@env_tone} data-theme-pending>
```

**CSS transition suppression:**
```css
/* rulestead_admin.css — add near the theme layer */
[data-theme-pending],
[data-theme-pending] * {
  transition: none !important;
}
```

**Hook clears it synchronously before rAF:**
```javascript
mounted() {
  const shell = this.el.closest(".rs-shell")
  const stored = localStorage.getItem("rulestead_admin.theme") || "system"
  this._mode = stored
  if (stored === "dark")  shell.setAttribute("data-theme", "dark")
  else if (stored === "light") shell.setAttribute("data-theme", "light")
  else shell.removeAttribute("data-theme")
  shell.removeAttribute("data-theme-pending")   // ← synchronous; transitions un-frozen here
  this._syncAria()
  // matchMedia wiring follows...
}
```

**Why synchronous before rAF matters:** [VERIFIED: phoenix_live_view.esm.js:4009, 4591] `mounted()` is called synchronously inside `maybeAddNewHook()` which is called inside `execNewMounted()` which is called inside `applyJoinPatch()`. The browser has already rendered the server HTML before this point (it's post-DOM-patch), but `mounted()` itself runs synchronously within the JS microtask queue — there is no forced frame between "DOM patched" and "mounted() runs". Setting `data-theme` and removing `data-theme-pending` both happen before the next paint frame, making the correction invisible.

### Pattern 3: matchMedia System Mode Listener

**What:** The modern `addEventListener('change')` pattern on `MediaQueryList`. The listener no-ops unless the current mode is `system` (guarded by `this._mode === "system"` check).

```javascript
// [ASSUMED: standard Web API pattern, confirmed by MDN docs behavior]
this._mq = window.matchMedia("(prefers-color-scheme: dark)")

this._mqListener = (e) => {
  if (this._mode !== "system") return   // pinned users: ignore OS changes
  this._applySystem(e.matches)
}

this._mq.addEventListener("change", this._mqListener)

// In _applySystem:
_applySystem(isDark) {
  // system mode: no data-theme attr; CSS @media handles it
  // But aria-checked on the System button must stay correct
  this._syncAria()
}
```

**Why remove `data-theme` for system rather than set it:** The CSS already has `.rs-shell:not([data-theme])` + `@media (prefers-color-scheme: dark)` for system dark. Setting `data-theme="system"` would break this — the `[data-theme]` attribute selector in the CSS only handles `"dark"` and `"light"`. System = absence of `data-theme`. [VERIFIED: rulestead_admin.css:211]

**Note on legacy `addListener`:** The `MediaQueryList.addListener()` API is deprecated. Use `addEventListener('change', handler)` — supported in all modern browsers. [ASSUMED: standard Web API deprecation, training knowledge]

### Pattern 4: Segmented Radiogroup A11Y

**What:** ARIA `role="radiogroup"` + `role="radio"` with roving tabindex (one tab stop in the group; arrow keys move selection).

**Structure:**
```html
<section class="rs-shell__context rs-theme-control" aria-label="Theme">
  <p class="rs-shell__context-label" id="rs-theme-label">Theme</p>
  <div
    id="rs-theme-control"
    role="radiogroup"
    aria-labelledby="rs-theme-label"
    phx-hook=".ThemeControl"
    class="rs-theme-control__group"
  >
    <button type="button" role="radio" aria-checked="true"  tabindex="0"  data-value="system" class="rs-theme-control__opt">System</button>
    <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="light"  class="rs-theme-control__opt">Light</button>
    <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="dark"   class="rs-theme-control__opt">Dark</button>
  </div>
</section>
```

**Roving tabindex pattern:**
- Only the currently-selected option has `tabindex="0"`; others have `tabindex="-1"`
- `ArrowRight` / `ArrowDown`: move to next option (wrap), set `aria-checked="true"`, update tabindex, focus the new option, write localStorage + `data-theme`
- `ArrowLeft` / `ArrowUp`: move to previous option (wrap)
- `Home` / `End`: jump to first/last option (optional but recommended)
- `Enter` / `Space`: select focused option (should already be selected via arrow nav in a radiogroup — include for robustness)
- `Tab`: leaves the radiogroup entirely (normal tab flow)

**Reuse `.rs-flag-subnav__tab` for visual styling:** The existing tab CSS (lines 1836–1864) provides the correct visual — bottom-border underline for active, muted color for inactive, focus-visible ring. The theme control needs a compact pill variant. Consider `.rs-theme-control__opt` styled after `.rs-segmented-links a` (lines 1896–1914) — pill shape with border, surface background, text-muted inactive, primary fill active. [VERIFIED: rulestead_admin.css read]

**`aria-checked` vs `aria-selected`:** For `role="radio"`, use `aria-checked` (not `aria-selected`). `aria-selected` is for `role="option"` in listboxes. [ASSUMED: ARIA spec, training knowledge]

### Anti-Patterns to Avoid

- **Setting `data-theme="system"` instead of removing `data-theme`:** The CSS cascade uses `:not([data-theme])` for system. Any value in the attribute (including `"system"`) will prevent the `@media` block from applying. [VERIFIED: rulestead_admin.css:211]
- **Calling `removeAttribute("data-theme-pending")` after rAF:** Using `requestAnimationFrame(() => shell.removeAttribute("data-theme-pending"))` defers the snap by one frame. The transition suppression must be lifted AFTER `data-theme` is set but the removal must happen synchronously within the same JS task, before the browser has a chance to paint the intermediate state. Remove pending BEFORE rAF.
- **Storing the matchMedia listener as an anonymous function:** You cannot call `removeEventListener` with a different function reference. Store as `this._mqListener`.
- **Wiring the `phx-hook` to a container that is a LiveView child (not root):** If the hook element is inside the LV root, LiveView morphdom CAN patch its attributes. If `aria-checked` is set by the hook on radio buttons, those children will be patched back to the server-rendered state on every LV update. Always implement `updated()` to re-sync.
- **Traversing to `.rs-shell` via `this.el.parentElement.parentElement...`:** Use `this.el.closest(".rs-shell")` — robust to DOM structure changes.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auto-registering JS hook in mounted package | Host LiveSocket `hooks:` config | `runtime` attribute on ColocatedHook | Runtime hooks register themselves via `window["phx_hook_..."]`; no host wiring needed |
| Persisting client preference | Cookie / server session | `localStorage` | localStorage is synchronous, origin-scoped, survives tab close, no server round-trip, no THM-05 violation |
| Live OS-change tracking | Polling `window.matchMedia(...).matches` on an interval | `addEventListener('change')` on `MediaQueryList` | Passive event; zero polling overhead |

**Key insight:** The runtime colocated hook pattern exists precisely for this use-case (mounting a JS hook from a library's own package without requiring the host to configure LiveSocket). The `.CmdK` hook at `shell.ex:231` is the proof it works.

---

## Runtime State Inventory

Step 2.5 SKIPPED — this is a greenfield feature addition, not a rename/refactor/migration phase. No existing runtime state stores the string being changed.

---

## Common Pitfalls

### Pitfall 1: `data-theme` clobbered by LiveView patch — FALSE ALARM for `.rs-shell`

**What goes wrong (the fear):** Every LiveView push re-renders and morphdom patches the DOM. Will `data-theme` set by JS get removed?

**Why it does NOT happen for `.rs-shell`:** `.rs-shell` is the LiveView root container element (each live view's `render/1` function starts with `<Shell.page ...>` which renders `<div class="rs-shell">`). LiveView's `replaceRootContainer` only updates `id`, `phx-session`, `phx-static`, `phx-main`, `phx-root-id` on the root element. JS-set `data-theme` and `data-theme-pending` on `.rs-shell` are preserved across all LiveView patches. [VERIFIED: phoenix_live_view.esm.js:844]

**Why it DOES happen for children:** The radio button children inside the control (`.rs-theme-control__opt`) are ordinary LiveView children. `mergeAttrs` during morphdom patching will sync their attributes back to what the server rendered — including `aria-checked` and `tabindex`. Mitigation: implement `updated()` on the hook to re-sync `aria-checked` and `tabindex` from localStorage.

**Warning signs:** `aria-checked` flips back to `"false"` on all buttons after a navigation push. Fix: add `updated() { this._syncAria() }` to the hook.

### Pitfall 2: `data-theme-pending` stays forever if JS fails

**What goes wrong:** If the LiveView connection fails before `mounted()` fires, `data-theme-pending` stays on `.rs-shell` forever. All transitions are frozen for that session.

**Why it happens:** The attribute is set at server-render time and only cleared by client JS.

**How to avoid:** This is an acceptable degradation — system users are still correctly themed by CSS `@media`; pinned users see the correct theme (they're on light OS + pinned dark → they get light, not dark, but no animated wipe). The only negative is frozen transitions, which is preferable to a flash. If desired, add a `setTimeout` fallback (e.g., 5000ms) to remove `data-theme-pending` unconditionally. [ASSUMED: fallback timing choice]

**Warning signs:** All CSS transitions permanently disabled. Check `data-theme-pending` attribute on `.rs-shell` in devtools.

### Pitfall 3: New Elixir module needs dev-server restart

**What goes wrong:** Adding `attr :theme_default` to `shell.ex` or adding the hook `<script>` tag compiles fine, but the hot-reload path for `.ex` files requires a code reload. The colocated hook `<script>` tag is compiled at Elixir compile time. If `mix compile` doesn't run between adding the hook and testing, the `window["phx_hook_..."]` global won't exist.

**How to avoid:** After modifying `shell.ex`, always `mix compile` (or let the code reloader do it) before testing. The dev server's code_reloader handles this automatically for `.ex` edits. [VERIFIED: admin-ui-dev-loop memory note]

### Pitfall 4: `.rs-shell` not found via `this.el.closest()` if hook is on `.rs-shell` itself

**What goes wrong:** If `phx-hook=".ThemeControl"` is on the `.rs-shell` element directly, `this.el.closest(".rs-shell")` returns `this.el` itself (correct). But if the hook element is a child, `closest` traverses up correctly. Either way, `closest` is the right call — not hardcoded parentElement chains.

**How to avoid:** Use `this.el.closest(".rs-shell")` regardless of whether the hook is on `.rs-shell` or a descendant. Following the `.CmdK` pattern: `.CmdK` is on `#rs-cmdk` which is inside `.rs-shell`, and the hook accesses root vars via `const root = this.el` (which IS the hook element). For `.ThemeControl`, the hook element is the radiogroup container — `this.el.closest(".rs-shell")` correctly walks up to the scope root.

### Pitfall 5: `localStorage` access throws in third-party iframes

**What goes wrong:** In some iframe-embedded contexts or with certain browser security settings, `localStorage.getItem()` throws a `SecurityError`.

**How to avoid:** Wrap localStorage access in a try/catch. Fall through to `"system"` default:
```javascript
function readTheme() {
  try { return localStorage.getItem("rulestead_admin.theme") || "system" }
  catch (_) { return "system" }
}
```
[ASSUMED: standard browser security edge case, training knowledge]

---

## Code Examples

### Complete hook skeleton (template from .CmdK, adapted for .ThemeControl)

```javascript
// Source: shell.ex:231 — .CmdK hook structure (verified from codebase read)
// Adaptation for .ThemeControl:
<script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeControl" runtime>
  {
    mounted() {
      const ctrl = this.el          // the radiogroup div
      const shell = ctrl.closest(".rs-shell")
      const opts  = Array.from(ctrl.querySelectorAll("[role=radio]"))

      const readTheme = () => {
        try { return localStorage.getItem("rulestead_admin.theme") || "system" }
        catch (_) { return "system" }
      }

      const writeTheme = (val) => {
        try { localStorage.setItem("rulestead_admin.theme", val) } catch (_) {}
      }

      const applyTheme = (val) => {
        this._mode = val
        if (val === "dark")       shell.setAttribute("data-theme", "dark")
        else if (val === "light") shell.setAttribute("data-theme", "light")
        else                      shell.removeAttribute("data-theme")
      }

      this._syncAria = () => {
        const current = this._mode || "system"
        opts.forEach((opt) => {
          const isActive = opt.dataset.value === current
          opt.setAttribute("aria-checked", String(isActive))
          opt.tabIndex = isActive ? 0 : -1
        })
      }

      // Initial apply — synchronous, before rAF
      applyTheme(readTheme())
      shell.removeAttribute("data-theme-pending")   // un-freeze transitions
      this._syncAria()

      // matchMedia listener — active only in system mode
      this._mq = window.matchMedia("(prefers-color-scheme: dark)")
      this._mqListener = (_e) => {
        if (this._mode !== "system") return
        this._syncAria()   // aria-checked for System button stays correct
      }
      this._mq.addEventListener("change", this._mqListener)

      // Click handler
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

      // Roving tabindex keyboard nav
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
      // LiveView morphdom may have patched aria-checked/tabindex back to server state
      this._syncAria()
    },

    destroyed() {
      this._mq.removeEventListener("change", this._mqListener)
    }
  }
</script>
```

### HEEx control markup

```heex
<%!-- Place after the env-picker section in the shell header context cluster --%>
<section class="rs-shell__context" aria-label="Theme">
  <p class="rs-shell__context-label" id="rs-theme-label">Theme</p>
  <div
    id="rs-theme-control"
    role="radiogroup"
    aria-labelledby="rs-theme-label"
    phx-hook=".ThemeControl"
    class="rs-theme-control__group"
  >
    <button type="button" role="radio" aria-checked="true"  tabindex="0"  data-value="system" class="rs-theme-control__opt">System</button>
    <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="light"  class="rs-theme-control__opt">Light</button>
    <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="dark"   class="rs-theme-control__opt">Dark</button>
  </div>
</section>
```

Note: the server-rendered `aria-checked="true"` on System is the default fallback. The hook will re-sync immediately on mount. The server does not know the persisted value — that's purely client state.

### `.rs-shell` root with `data-theme-pending`

```heex
<div class="rs-shell" data-env-tone={@env_tone} data-theme-pending>
```

Add `data-theme-pending` as a static attribute. It is removed by the hook synchronously on mount.

### CSS transition suppression

```css
/* Add after the theme layer blocks in rulestead_admin.css */

/* FOUC snap: freeze all transitions while pinned-theme correction is in flight.
   The .ThemeControl hook removes data-theme-pending synchronously in mounted()
   after applying data-theme — so this only suppresses transitions for the brief
   window between first paint and hook mount. */
[data-theme-pending],
[data-theme-pending] * {
  transition: none !important;
}
```

**Interaction with Phase 94:** Phase 94 adds real micro-animations. The `[data-theme-pending] * { transition: none }` rule only applies while the attribute exists — which is only during the mount window. Once removed by the hook, all transitions work normally. Phase 94 animations are not affected.

### Optional host `<head>` fast-path snippet (layer 3 — documented, not required)

```html
<!-- Optional: include in host app's <head> to eliminate pinned-mismatch flash
     even before LiveView connects. Copy-paste only — do not require. -->
<script>
  (function() {
    try {
      var t = localStorage.getItem("rulestead_admin.theme");
      if (t === "dark" || t === "light") {
        var shell = document.querySelector(".rs-shell");
        if (shell) shell.setAttribute("data-theme", t);
      }
    } catch (_) {}
  })();
</script>
```

Document this in `prompts/rulestead-host-app-integration-seam.md` or a new integration guide, clearly marked optional.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `MediaQueryList.addListener()` | `MediaQueryList.addEventListener('change', ...)` | Chrome 79 / Firefox 55 (2019–2020) | `addListener` is deprecated; use `addEventListener` |
| Bundled colocated hooks (need host build step) | Runtime colocated hooks (`runtime` attribute) | Phoenix LiveView ~0.20+ (colocated hooks feature) | Mounted packages can ship self-registering hooks with no host config |
| `role="tab"` for toggle buttons | `role="radio"` + `role="radiogroup"` for mutually exclusive choices | ARIA 1.1 (2017) clarification | Tabs imply panel content association; radiogroup is correct for theme choices |

**Deprecated / outdated:**
- `MediaQueryList.addListener`: Removed from some browser implementations. Use `addEventListener('change', ...)`.
- Setting `color-scheme` on `:root` in a mounted package: Violates THM-05 scope discipline. Already resolved in Phase 87.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `MediaQueryList.addListener()` is deprecated; modern pattern is `addEventListener('change')` | Code Examples, State of the Art | Low risk — both work in all modern browsers; `addEventListener` is strictly safer |
| A2 | `role="radio"` with `aria-checked` is the correct ARIA for a 3-option exclusive choice (not `role="tab"`) | Architecture Patterns §4 | Low risk — ARIA spec is unambiguous on this; `role="tab"` would require panel association |
| A3 | `localStorage` throws `SecurityError` in some iframe/sandboxed contexts | Common Pitfalls §5 | Low risk — defensive try/catch pattern has no downside |
| A4 | A `setTimeout` fallback (5000ms) to unconditionally remove `data-theme-pending` is a viable safety net | Common Pitfalls §2 | Low risk — exact timeout value is a judgment call; 3000–5000ms range is reasonable |
| A5 | `[data-theme-pending] * { transition: none !important }` does not interfere with Phase 94 micro-animations | Code Examples §3 | Low risk — attribute is removed synchronously on hook mount; Phase 94 animations are registered after mount |

**All other claims in this document are VERIFIED from codebase source reads.**

---

## Open Questions

1. **`theme_default` attr plumbing**
   - What we know: The CONTEXT.md calls for `attr :theme_default, :string, default: "system"` on `Shell.page/1`.
   - What's unclear: Whether the hook should read this as a fallback when localStorage is empty (so the host can set a corporate default), vs. whether it's only for the optional layer-3 bridge rule.
   - Recommendation: Read `theme_default` from `data-theme-default` on the control element (set by HEEx). In `mounted()`: `const stored = readTheme(); const val = stored !== "system" ? stored : (ctrl.dataset.themeDefault || "system")`. This lets the host seed the default without requiring the layer-3 head script.

2. **Where exactly in the header context cluster does the control go?**
   - What we know: The header is a CSS grid at 900px+ with columns `minmax(0, 1fr) repeat(3, auto)`. Currently: col 1 = title block, col 2 = Access section (if policy_state), col 3 = env picker section (if env_options), col 4 = tenant section (if tenants). Adding a 4th auto column for the theme control pushes the grid to 5 auto columns at 900px+.
   - What's unclear: Whether the header has enough horizontal space for a 5th context section on typical screen widths, or whether the theme control should share a column or be positioned differently.
   - Recommendation: Add it as the final `<section>` in the header (after tenant section). The CSS grid `repeat(3, auto)` may need to become `repeat(4, auto)` at 900px+. Keep it narrow: the control is just 3 small pill buttons. Claude's discretion per CONTEXT.md.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js / npm | Playwright tests | ✓ | (existing `examples/demo/frontend` setup) | — |
| Playwright | Theme control fixture tests | ✓ | Used by existing `theme-cascade.spec.ts` | — |
| Phoenix LiveView | ColocatedHook runtime | ✓ | Bundled in `rulestead_admin/deps/` | — |
| `localStorage` (browser) | Theme persistence | ✓ (Playwright + all target browsers) | Web API | Fall through to `"system"` default |

**Missing dependencies:** None blocking.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Playwright (existing) |
| Config file | `examples/demo/frontend/playwright.config.ts` |
| Quick run command | `cd examples/demo/frontend && npx playwright test tests/theme-control.spec.ts` |
| Full suite command | `cd examples/demo/frontend && npx playwright test` |

### Test Path: File:// Fixture (STRONGLY PREFERRED)

Do NOT boot the demo server for Phase 90 tests. The rationale:
1. The demo has a known DB-conflict gotcha (`rulestead_demo_dev` migration lock — see admin-ui-dev-loop memory).
2. Theme persistence, the control, and FOUC are pure client-side concerns — no server data is needed.
3. The existing `theme-cascade.spec.ts` and `theme-scope.spec.ts` already prove the `file://` harness pattern works perfectly for this test domain.

**Approach:** Create `theme-control-harness.html` alongside `theme-harness.html` in `rulestead_admin/priv/static/`. The harness includes:
- The full CSS (`rulestead_admin.css`)
- The control markup (radiogroup with 3 buttons)
- An inlined copy of the hook's JS logic (not the full ColocatedHook infrastructure — just the JS object body as a `<script>` block that runs on DOMContentLoaded)
- A `<div class="rs-shell" data-theme-pending>` scope root

The Playwright spec (`theme-control.spec.ts`) runs against `file://` and tests all behaviors without Phoenix.

**Why inlining hook logic is valid for testing:** The hook logic is pure DOM + localStorage. The `mounted()` / `updated()` / `destroyed()` calls from LiveView are the only integration point. The fixture calls `mounted()` directly on page load. The behavior being tested is identical.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| THM-02 | Select Dark → `data-theme="dark"` on `.rs-shell` | unit | `npx playwright test tests/theme-control.spec.ts -g "select dark"` | ❌ Wave 0 |
| THM-02 | Select Dark → `localStorage["rulestead_admin.theme"] === "dark"` | unit | `npx playwright test tests/theme-control.spec.ts -g "persists dark"` | ❌ Wave 0 |
| THM-02 | Reload page → dark theme still active (localStorage read) | unit | `npx playwright test tests/theme-control.spec.ts -g "persists across reload"` | ❌ Wave 0 |
| THM-02 | Select System → removes `data-theme` from `.rs-shell` | unit | `npx playwright test tests/theme-control.spec.ts -g "system removes attr"` | ❌ Wave 0 |
| THM-02 | Select System → `matchMedia` dark OS change is live-applied | unit | `npx playwright test tests/theme-control.spec.ts -g "system follows OS"` | ❌ Wave 0 |
| THM-02 | Select Dark when in System mode → OS change is ignored | unit | `npx playwright test tests/theme-control.spec.ts -g "pinned ignores OS"` | ❌ Wave 0 |
| THM-02 | Arrow keys navigate radiogroup | unit | `npx playwright test tests/theme-control.spec.ts -g "keyboard nav"` | ❌ Wave 0 |
| THM-02 | `aria-checked` tracks active option | unit | `npx playwright test tests/theme-control.spec.ts -g "aria-checked"` | ❌ Wave 0 |
| THM-04 | Pinned mismatch: no `transition` fires during snap | unit | `npx playwright test tests/theme-control.spec.ts -g "no animated wipe"` | ❌ Wave 0 |
| THM-04 | `data-theme-pending` absent after hook mount | unit | `npx playwright test tests/theme-control.spec.ts -g "pending cleared"` | ❌ Wave 0 |
| THM-04 | System user (no localStorage): zero `data-theme` attr at first paint | unit | existing `theme-cascade.spec.ts` cases 1 + 2 | ✅ exists |

### Sampling Rate

- **Per task commit:** `npx playwright test tests/theme-control.spec.ts`
- **Per wave merge:** `npx playwright test` (full suite)
- **Phase gate:** Full suite green + both-theme visual screenshot check before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `examples/demo/frontend/tests/theme-control.spec.ts` — new spec covering all THM-02 + THM-04 behaviors above
- [ ] `rulestead_admin/priv/static/theme-control-harness.html` — fixture with control markup + inlined hook JS

*(Existing `theme-cascade.spec.ts` and `theme-scope.spec.ts` cover the CSS cascade and scoping regressions — no changes needed there.)*

---

## Security Domain

`security_enforcement` is not explicitly set to false in `.planning/config.json`. Applying standard review.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | Theme is not session state |
| V4 Access Control | no | Theme choice has no permission model |
| V5 Input Validation | yes (low) | localStorage value is constrained to `system|light|dark`; any other value falls back to `system` in hook logic |
| V6 Cryptography | no | — |

### Known Threat Patterns for localStorage + Client JS

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| localStorage value injection (malicious extension sets `rulestead_admin.theme`) | Tampering | Whitelist check: `["system","light","dark"].includes(stored) ? stored : "system"` |
| CSP blocking the runtime hook `<script>` tag | Denial of Service | Document CSP nonce requirement: `nonce={@script_csp_nonce}` on the `<script>` tag (see colocated_hook.ex:128) |
| XSS via `data-theme` attribute reflection | Tampering | `data-theme` is set via `setAttribute` — no innerHTML injection; attribute values are CSS selector inputs only (sanitized by browser) |

**CSP note:** If the host app has a strict `script-src` CSP without `unsafe-inline`, the runtime hook `<script>` tag needs a nonce. The `nonce` attribute is supported by `ColocatedHook` — pass `@script_csp_nonce` from the live session assign if needed. Document this in the integration guide. [VERIFIED: colocated_hook.ex:128]

---

## Sources

### Primary (HIGH confidence)

- `/rulestead_admin/deps/phoenix_live_view/lib/phoenix_live_view/colocated_hook.ex` — ColocatedHook transform logic, runtime hook code generation, hook naming (`module.name`), nonce support
- `/rulestead_admin/deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js` lines 6155–6180, 4009, 4588–4591, 4468–4560, 744–780, 844–870 — runtime hook lookup, `__mounted()` call sequence, `mergeAttrs` behavior, `replaceRootContainer` preserved attributes
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` lines 42, 180–326 — `.rs-shell` root element, `.CmdK` hook structure (the exact template for `.ThemeControl`), header context cluster layout
- `rulestead_admin/priv/static/css/rulestead_admin.css` lines 121–371, 1201–1300, 1821–1915 — theme cascade blocks (`:not([data-theme])` system behavior, `[data-theme="dark"]` pinned behavior), header grid, subnav tab + segmented-links visual patterns
- `rulestead_admin/priv/static/theme-harness.html` — existing `file://` test fixture pattern; `window.setTheme` / `window.clearTheme` helpers as precedent for hook API
- `examples/demo/frontend/tests/theme-cascade.spec.ts` — existing Playwright `file://` pattern (colorScheme context, `shellVar` helper, browser.newContext)
- `examples/demo/frontend/playwright.config.ts` — test runner config

### Secondary (MEDIUM confidence)

- `session-recap-inherited-micali.md` — Approach 2 decisions: localStorage + colocated hook + segmented control + FOUC layers 1–2 + optional layer 3
- `admin-ui-dev-loop.md` (memory) — demo DB-conflict gotcha, CSS hot-reload symlink, PORT=4010

### Tertiary (LOW confidence / ASSUMED)

- ARIA radiogroup / roving tabindex keyboard pattern — based on training knowledge (ARIA Authoring Practices Guide pattern); not re-verified via live docs fetch this session
- `MediaQueryList.addListener()` deprecation in favor of `addEventListener('change')` — training knowledge; verify at MDN if needed

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — ColocatedHook mechanism verified from source; localStorage and matchMedia are native APIs
- Architecture: HIGH — `mounted()` timing and DOM patching behavior verified from LiveView esm.js source; `.rs-shell` root-container behavior verified
- Pitfalls: HIGH for LV root/clobber behavior; MEDIUM for ARIA keyboard pattern (training knowledge, authoritative but unverified this session)

**Research date:** 2026-06-04
**Valid until:** 2026-08-04 (stable LiveView internals; native browser APIs don't change)
