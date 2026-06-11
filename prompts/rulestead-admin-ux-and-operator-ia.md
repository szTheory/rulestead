# Rulestead Admin UX & Operator Information Architecture

> **Purpose:** Specify the mountable LiveView admin UI — screens, interactions, information hierarchy, progressive disclosure, and keyboard-first operator ergonomics. Applies sigra's mountable-LiveView DNA and lockspire's operator-IA principles to the feature-flag domain, with UX patterns distilled from GrowthBook, Unleash, and LaunchDarkly.
>
> **Read alongside:** `rulestead-engineering-dna-from-prior-libs.md` §2.2, `rulestead-domain-language-field-guide.md` (nouns/verbs), `rulestead-telemetry-observability-and-audit.md` (where impressions/audit feed timelines).

---

## 1. North-star principles

1. **Ships mounted, not embedded.** `rulestead_admin "/admin/flags"` in the host router. Host owns auth/layout/CSP. We render inside their chrome.
2. **Read-path must be fast + scannable.** Flag lists, audit timelines, evaluation explainers are the 80% surface. Every list loads under 300ms on 10k-row tenants (streams + keyset pagination).
3. **Every mutation has three stages: preview → confirm → audit.** No flag, ruleset, rollout, or kill-switch change happens without a diff preview and an audit row.
4. **Simulate before publish.** Every ruleset edit surfaces a "simulate against last-hour sample" button. You cannot publish without simulating.
5. **Explain a decision in one click.** `(flag, actor)` → full trace (snapshot version + matched rule + bucket + variant + timing) on a single page.
6. **Keyboard-first.** Command palette (`⌘K`), list navigation (`j`/`k`), row-level actions (`e`/`d`/`s` for edit/duplicate/simulate).
7. **Multi-tenant-aware by default.** Tenant picker always visible. URL encodes tenant. No global "all tenants" footgun — requires explicit opt-in.
8. **Progressive disclosure.** Beginner mode shows boolean flags only. Advanced mode surfaces variants, audiences, percentage rollouts, kill switches, scheduled changes.
9. **AI-assist is suggestive, not autopilot.** Change-request drafts, naming hints, and rule suggestions land in a review pane — never auto-applied.
10. **No visual novelty for its own sake.** Clarity > cleverness. Operators wake up at 3am to use this.
11. **Affordance honesty.** Controls must look interactive, current location labels must not, and read-only evidence must not borrow input styling. Breadcrumb terminal items render as current-page text, internal admin navigation uses LiveView navigation, same-view state changes use patches, and narrative change notes use list/prose styling instead of field-like boxes. Reuse these patterns before inventing a new surface.

---

## 2. Information architecture

### 2.1 Top-level navigation (mounted under `/admin/flags` by convention)

```
/admin/flags                   Flag list (primary)
/admin/flags/:key              Flag detail
/admin/flags/:key/rules        Ruleset editor (scoped to flag)
/admin/flags/:key/simulate     Simulation playground
/admin/flags/:key/explain      Decision explainer
/admin/flags/:key/timeline     Per-flag audit timeline
/admin/flags/:key/rollouts     Rollout state + controls
/admin/flags/:key/kill         Kill switch toggle (protected)

/admin/audiences               Audience list
/admin/audiences/:key          Audience detail (criteria + member preview)

/admin/rulesets                Ruleset versions (draft / active / archived)
/admin/rulesets/:id/compare    Side-by-side diff (current vs draft)

/admin/rollouts                All active rollouts across flags
/admin/schedule                Scheduled changes (calendar view)

/admin/audit                   Cross-flag audit timeline
/admin/audit/:event_id         Event detail (immutable)

/admin/diagnostics             Fallthrough, stale snapshots, fail-closed events
/admin/settings                Environments, policies, hooks registry, change-request settings
```

No `/admin/flags/index` — conventional `:index` action, `~p"/admin/flags"`.

### 2.2 Left-rail vs top-bar

- **Top bar:** brand + tenant picker + environment picker + command palette trigger + user menu.
- **Left rail:** Flags, Audiences, Rulesets, Rollouts, Schedule, Audit, Diagnostics, Settings.
- **Context breadcrumb:** always `Tenant › Env › Flag › View`.

### 2.3 Env/tenant in URL

Tenant + env are query params (`?tenant=acme&env=prod`), not path segments. Rationale: sharing URLs cross-environment is common; encoding in path makes bookmarking environment-specific which is wrong.

---

## 3. Primary screens

### 3.1 Flag list (`/admin/flags`)

Layout:
- **Header:** title "Flags", button "New flag", env/tenant context chips, quick-filter tabs (All / Active / Archived / Has kill switch / Rolling out now / Stale).
- **Filter bar:** text search (key, description, owner), status multi-select, env selector, "has scheduled change" toggle, "owned by me" toggle.
- **Table / stream:** sortable columns — key · type · current value (pilled per variant) · status · last modified · owner · audience count · rollout state.
- **Row click:** → flag detail.
- **Row hover actions:** edit, duplicate, simulate, kill (with confirm).
- **Empty state:** primary CTA "Create your first flag" + secondary link "Import from JSON".
- **10k+ rows:** keyset pagination + `Phoenix.LiveView.stream/3`.

Filter state lives in `params` (via `handle_params`) so URLs are shareable and back-button works.

Column priorities (mobile):
1. key (always visible)
2. status + current value (single merged column on mobile)
3. last modified
4. kebab menu (everything else)

### 3.2 Flag detail (`/admin/flags/:key`)

Layout (two-column on desktop, stacked on mobile):

**Left column (summary):**
- Key (monospace, copyable)
- Description (markdown-rendered, editable inline)
- Status pill (active / archived / pending-cleanup)
- Type (boolean / string / number / json)
- Variants list (name + weight + value chip)
- Owner + team
- Created / last modified
- Tags
- "Scheduled changes" card (if any) — linked to `/admin/schedule`.
- "Open change requests" card (if any).

**Right column (live state):**
- Current active ruleset name + version + published-at.
- Rollout state (if any) — progress bar + "advance / hold / rollback" buttons.
- Kill switch state — big red toggle (with confirmation modal + reason-required textarea).
- Impression volume last 24h (spark line).
- Last 10 audit events (linked to timeline).

**Tabs (below the two columns):**
- `Rules` — inline ruleset editor (§3.3)
- `Simulate` — playground (§3.4)
- `Explain` — decision lookup (§3.5)
- `Timeline` — audit (§3.6)
- `Rollouts` — state + controls (§3.7)

### 3.3 Ruleset editor (`/admin/flags/:key/rules`)

Core interaction model: **ordered rule list**, drag-to-reorder, inline-edit, no page reload.

- **Rule row:** conditions summary · strategy · variant/value · enabled toggle · reorder handle · delete.
- **Condition builder:** expanded state shows attribute + operator + value(s). Attributes picker lists known context attributes + tenant + env. Operators depend on attribute type.
- **Strategy dropdown:** static value · bucketed percentage · A/B/C multivariate · forced variant (for a specific audience).
- **Add-rule button:** opens a popover with strategy presets + blank condition row.
- **Simulate before save:** inline banner — "X% of last-hour traffic would shift if published" + link to full simulate view.
- **Save as draft:** always allowed.
- **Publish:** disabled until `Simulate` has been run on the current diff. Confirm modal shows:
  - who/when
  - diff (side-by-side)
  - delta over last-hour sample (`N evaluations would change variant`)
  - audit reason (required textarea)
- **Revert:** in the version history panel, any historical ruleset has a "Revert to this" button that opens publish flow with reversal as the proposed change.

### 3.4 Simulation playground (`/admin/flags/:key/simulate`)

- **Input mode A — Sample:** "Last hour" / "Last 24h" / "Last 7 days" / "Custom JSON sample" selector. Runs the draft ruleset against the sample.
- **Input mode B — Single actor:** paste a JSON context or pick from recent evaluations. Shows the full decision trace.
- **Output:**
  - **Aggregate mode:** histogram of variant distribution before/after, delta count, "N flipped to X, M flipped to Y".
  - **Single-actor mode:** matched rule · bucket value · variant · reason · timing.
- **Export:** CSV of (actor_id, before, after) for deeper analysis.

Server-side implementation: `assign_async` + `Phoenix.LiveView.stream_async` for large sample results. Cancel button wired to `cancel_async`.

### 3.5 Explain a decision (`/admin/flags/:key/explain`)

The single most-used page at 3am.

- **Input:** `(flag_key, actor_id, env, timestamp?)` — prefilled from URL query params so support teams can share explain-links.
- **Optional snapshot_version:** replay evaluation against a historical snapshot to answer "what would this have returned at 2:14am?"
- **Output:**
  - Final variant + value.
  - Matched rule (with full condition tree expanded).
  - Bucket value (0–9999) with variant-threshold visualization.
  - Reason chain: `ruleset v27 → rule 3 matched (env=prod, country=US) → bucketed at 4721 → variant=treatment`.
  - Snapshot version + published-at.
  - Applicable audiences (chip list).
  - Was any kill switch engaged at the time?
  - Evaluation time (p50/p99 for this flag in last hour).

Every line is copy-linkable (anchor) for paste-into-Slack support flows.

### 3.6 Per-flag audit timeline (`/admin/flags/:key/timeline`)

- Reverse-chronological event stream; streams + keyset pagination.
- Event row: icon · actor · verb · summary · timestamp · expand.
- Expand shows full event payload (JSONB) as diff-rendered fields.
- Filter: event type multi-select, actor, date range.
- Export: JSON / CSV.

Every event is immutable. No "edit" or "delete" affordance.

### 3.7 Rollouts (`/admin/flags/:key/rollouts`)

- **State machine visualization:** draft → scheduled → rolling → held → completed → rolled-back.
- **Stages table:** stage % · advanced-at · advanced-by · health-check status · next-stage ETA.
- **Controls:**
  - `Advance` — confirm + audit reason.
  - `Hold` — confirm + audit reason.
  - `Rollback` — confirm + reason + shows what variant will revert to.
- **Health signals sidebar:** p99 evaluation latency, impression error rate, anomaly detector (if `:rulestead_insights` installed).
- **Scheduled advance preview:** "If you hit Advance now, 12,400 more actors will be moved to `treatment`."

### 3.8 Kill switch (`/admin/flags/:key/kill`)

Separate screen (not buried in a menu).
- Big red state indicator.
- `Engage` button → confirm modal (reason required, expiration optional).
- `Release` button → same modal.
- Last 10 engage/release events inline.
- If engaged: shows the forced variant + an impression count for "how much traffic this is catching."

### 3.9 Audiences (`/admin/audiences`)

- Simple list: key · description · member-count estimate · rules referencing · last modified.
- Detail: criteria builder (same as rule condition builder) + live member-count preview + sample matching actors (opt-in).
- Member preview respects privacy: redacts PII attributes per `Rulestead.ContextRedactor`.

### 3.10 Cross-flag audit (`/admin/audit`)

- Global timeline across all flags/rulesets/rollouts/kill-switches.
- Filter: flag, actor, event type, date range.
- Export: JSON / CSV with signed bundle (threadline pattern).
- "Recent high-impact events" pinned at top: kill switches engaged, rollouts rolled back, bulk archives.

### 3.11 Scheduled changes (`/admin/schedule`)

Calendar view + list view toggle. Upcoming changes (rulesets to publish, rollouts to advance, kill-switches to release). Each row links back to the flag. Supports cancel + reschedule.

### 3.12 Diagnostics (`/admin/diagnostics`)

- **Fallthroughs panel:** flags where >X% of evaluations hit `default_value` (possible misconfig).
- **Stale snapshots panel:** nodes serving snapshots older than N minutes (cache-invalidation lag).
- **Fail-closed events panel:** evaluator errors in last 24h grouped by reason.
- **Hook health panel:** before_eval / after_eval / before_mutation hook latencies + errors.

### 3.13 Settings (`/admin/settings`)

Tabs:
- **Environments** — list + create/rename/archive.
- **Policies** — change-request approval rules (who can self-approve vs needs peer).
- **Hooks** — registered hooks with health pills (inline enable/disable).
- **Context attributes** — declared actor attributes for autocomplete in rule builder.
- **Redaction rules** — which attributes get scrubbed in audit/logs.
- **Integrations** — webhook destinations, OTel endpoint, audit-export bucket.

---

## 4. Interaction patterns

### 4.1 Mutation lifecycle

Every mutation uses the same modal shape:

```
┌─────────────────────────────────────────┐
│ Confirm: Advance rollout                │
├─────────────────────────────────────────┤
│ Flag:     checkout_v2                   │
│ From:     25%                           │
│ To:       50%                           │
│ Affects:  ~24,800 more actors           │
│                                         │
│ Reason (required):                      │
│ [ textarea ...                       ]  │
│                                         │
│ Schedule: [Now ▾] (or: 2026-11-20 09:00)│
│                                         │
│ [Cancel]                  [Advance] (⏎) │
└─────────────────────────────────────────┘
```

Keyboard: `⏎` confirms, `Esc` cancels.

### 4.2 Command palette (`⌘K` / `Ctrl+K`)

Opens anywhere. Top results categorized:
- Flags (keyword match on key + description)
- Audiences
- Rulesets
- Scheduled changes
- Recent audit events
- Actions ("Create flag", "Kill switch for…", "Explain decision for…")

Result navigation: arrow keys + `⏎`.

### 4.3 Keyboard-first lists

- `j` / `k` — next / previous row
- `⏎` — open row
- `e` — edit
- `d` — duplicate
- `s` — simulate
- `.` — toggle enabled (if applicable)
- `?` — keyboard help overlay

### 4.4 Diff rendering

Side-by-side. Old value on left (red tint on removed lines), new on right (green tint on added lines). Inline intra-line diff highlighting. Whitespace-mode toggle. Used in ruleset diff, audit event expand, simulate delta.

### 4.5 Live updates

- LiveView subscribes to `PubSub` topics like `"rulestead:flag:#{key}"`, `"rulestead:audit"`.
- When another operator mutates a flag you're viewing, a "This flag was updated by @alice. [Refresh]" banner appears (don't auto-refresh in the middle of an edit).
- Impression counts on flag-detail update in real time (stream updates).

### 4.6 Optimistic updates

Minor state toggles (description edit, tag changes, enabled-toggle on draft rules) are optimistic — the UI updates immediately, rolls back with a toast if the server rejects.

Destructive actions (publish, kill, advance, rollback) are NEVER optimistic. They wait for server confirmation before reflecting.

### 4.7 Empty + loading + error states

- Every list has: empty state, loading skeleton, error state with retry button.
- LiveView uses `assign_async` with `.async_result` components so skeletons render instantly.
- Errors show a sanitized message + "Show technical details" collapse.

### 4.8 Affordance catalog

- **Shell header:** The app shell header is global chrome only: Rulestead wordmark, command search, and a single baseline-aligned control bar for access, environment, tenant, and theme. Environment and tenant scope use compact field-shaped selector controls that show the current scope in one trigger and list alternatives in a menu; do not render adjacent environment pills or visible "Viewing" copy. Access is low-emphasis metadata, not a button-shaped badge. Do not render visible page titles, section kickers, summaries, stacked context labels, helper prose, or page-specific actions in the header because they create route-to-route height shifts and crowd the global controls.
- **Pills vs. selectors:** Reserve rounded pills for true status badges, filter tokens, and small inline tags. Dropdown triggers, static scope values, and shell metadata use the rectangular selector/control language (`--rs-radius-md`, left-aligned value, right-pinned affordance when interactive) so the UI does not collapse into one repeated pill shape.
- **Brand lockup:** The top-left shell identity is the complete Rulestead wordmark SVG, linked to the mounted admin overview while preserving the current environment. Do not rebuild the logo from arbitrary text spans; the mark-to-typemark spacing, glyph outlines, and optical alignment belong to the canonical wordmark artwork. The favicon square is for browser chrome, not the in-app shell lockup.
- **Page context:** Page-specific orientation belongs at the top of `main`, not in the shell header. Render breadcrumbs first, then the short page summary as an unframed content intro. Keep `page_title` available as a screen-reader-only H1 for semantic page naming, but do not add a second visible title above the main job-to-be-done.
- **Breadcrumbs:** Always reserve the breadcrumb row. Top-level pages render a single current crumb such as `Flags`; detail pages render ancestors as LiveView links and the terminal crumb as non-link text with `aria-current="page"`.
- **Page actions:** Commands belong near the content they affect: refresh and diagnostics actions in banners or section headers, filtered return links in main-content action bars, and mutation commands inside governed cards/forms. Do not put action buttons inside breadcrumbs; breadcrumbs stay navigation-only.
- **Theme:** Theme selection is a compact global appearance menu in the shell, not a filter-like segmented control. The trigger shows the current mode with a familiar system/light/dark icon and opens three explicit choices. Keep the `system | light | dark` persistence contract, but avoid exposing all three options as equal-weight header pills.
- **Navigation:** Internal admin page changes use LiveView navigation; same-page state such as filters, sort, search tokens, and cursor pagination uses patches. Sort and pagination must not reset theme or document identity; sort should preserve scroll position.
- **Pagination:** Render pagination only when a previous or next page exists. Do not show filler meta like "Showing 1 flag" when the result heading already communicates count.
- **Action icons:** Use icons only in action clusters where scanability improves: create, edit, rules, simulate, explain, preview, save, publish, archive, diagnostics, compare, back, schedule, execute, reject, timeline, and kill-switch routes. Do not add icons to breadcrumbs, pagination, filter tabs, row titles, badges, tags, or dense table links.
- **Read-only evidence:** Narrative audit notes and change summaries use prose/list styling. Field-like borders, input backgrounds, and form spacing are reserved for editable controls or structured before/after values.

---

## 5. Progressive disclosure

### 5.1 Modes

- **Simple mode (default for new installs):** boolean flags only. No variants, no percentage rollouts, no audiences. Ruleset editor shows "if env=prod → on / else off"-style builder.
- **Advanced mode:** all surfaces enabled.

Mode is per-user preference, stored server-side.

### 5.2 Feature gating via optional deps

- Rollout controls hidden unless `Rulestead.RolloutController` is registered.
- Kill switch hidden unless `:rulestead_kill_switch` applied (or always on by default — TBD during GSD v0 phase).
- Insights panel hidden unless `:rulestead_insights` installed.
- Scheduled changes hidden unless `Oban` detected.

`Rulestead.Optional` detects and the nav items + admin routes are conditionally registered.

---

## 6. Multi-tenancy in UX

1. **Tenant picker always visible** (top bar, after brand).
2. **No "all tenants" default.** Requires explicit opt-in for cross-tenant views (for operators with global scope).
3. **Tenant encoded in URL.** Changing tenant reloads the view with new scope.
4. **Visual signal in non-prod envs.** Yellow stripe header when `env != prod`, red stripe when viewing prod.
5. **Tenant isolation in queries.** All admin queries scoped by `tenant_id` in `Ecto.Query`. Cross-tenant operator roles must be explicitly granted by `Rulestead.Admin.Policy`.

---

## 7. AI-assist surfaces (v0.7+)

**Never autopilot. Always suggest.**

- **Change-request drafting:** operator types "gradually roll out checkout_v2 to premium tier users over 2 weeks"; AI drafts the ruleset + rollout schedule; operator reviews diff, edits, submits through normal change-request flow.
- **Naming hints:** on flag create, suggest well-formed keys (`snake_case.domain.feature`) based on description.
- **Drift detection:** flag list surfaces "possibly stale" badges on flags with no evaluations in 30d.
- **Explain summaries:** on the explain page, AI writes a 1-sentence human-readable summary of the decision ("Served treatment because user is in the US premium audience and bucketed into 47% which exceeds the 25% rollout threshold.").

All AI output is labeled `AI suggestion — review before applying`, renders in a sidebar, and never auto-submits.

---

## 8. Accessibility

- WCAG 2.1 AA minimum.
- All interactive controls keyboard-reachable.
- Focus outlines: never suppress.
- Color + icon + text for every status (never color-only).
- All icons paired with text labels (or `aria-label`).
- LiveView `phx-click` elements use `<button>` or `<a>` — never `<div>`.
- Confirm modals trap focus, restore on close.
- Live regions (`role="status"`) for toast notifications.
- Tables use `<thead>`, `<th scope="col">`, `<tbody>`.
- Forms use `<label>` + `for=`; errors use `aria-describedby`.
- Dark mode honored + high-contrast mode tested.

---

## 9. Design tokens + theming

- Exposes a minimal set of CSS custom properties: `--rulestead-accent`, `--rulestead-bg`, `--rulestead-border`, `--rulestead-danger`, etc.
- Host can override via their own stylesheet without forking component templates.
- Default theme: neutral gray/slate with a single accent (brand color from `rulestead-brand-book.md`).
- Dark mode by `prefers-color-scheme` + optional `data-theme="dark"` attr for host-app override.
- Typography inherits from host. No font-face declarations.
- No CSS reset; scope styles with `[data-rulestead]` attribute + carefully-written selectors to avoid bleeding into host styles.

Shipped as plain CSS (compiled from a tiny Sass or PostCSS build, or hand-authored). No runtime CSS-in-JS. No Tailwind-as-a-dep (host can use it if they want; we don't).

---

## 10. Assets + build

- Admin assets live under `priv/static/admin/`.
- Built with `esbuild` + a small CSS preprocess step, checked in as artifacts (sigra pattern).
- No runtime asset build required for the host (install is `mix.install + migrate + route`, no `npm install`).
- Host can opt-in to a "proxy through LiveView" asset mount, or serve directly via `Plug.Static` (default).

---

## 11. Error + empty state patterns

Inventory — every one of these must have an illustration + helpful CTA:

| State | Primary CTA | Tone |
|---|---|---|
| No flags | "Create your first flag" | Encouraging |
| No rulesets | "Start with boolean defaults" | Guiding |
| No audit events | "Changes will appear here as they happen" | Reassuring |
| Ruleset publish failed | "Revert draft" + error details | Honest |
| Snapshot stale | "Last-known-good is still serving" + diagnostics link | Calm |
| Store unreachable | "We're serving the cached snapshot" | Calm |
| Permission denied | "You don't have access to this flag" + who to contact | Honest, not scary |

---

## 12. Instrumentation — what the UI measures

Every admin UI interaction emits telemetry so we can improve the UX:

- `[:rulestead, :admin, :ui, :page_view]` — route, tenant, env, duration.
- `[:rulestead, :admin, :ui, :action_started]` — action name, target (flag key, etc.).
- `[:rulestead, :admin, :ui, :action_completed]` — action name, success/failure, duration.
- `[:rulestead, :admin, :ui, :search]` — query length, result count.

These feed the diagnostics panel + product analytics (opt-in).

---

## 13. Mobile considerations

Admin UI is **responsive but not mobile-first.** Expected usage is desktop ops/SRE work. Phone-sized viewports collapse:
- List: cards, primary cols only, kebab menu for rest.
- Flag detail: single-column stacked.
- Ruleset editor: read-only on mobile (editing is desktop-only by design).
- Kill switch: fully functional on mobile (3am use case).

---

## 14. Screens by persona — quick map

| Persona | Primary screen | Secondary |
|---|---|---|
| App dev | Flag list + flag detail | Explain |
| Tech lead | Rulesets + rollouts | Audit |
| PM | Rollouts + schedule | Audit (read-only) |
| Support | Explain a decision | Timeline |
| SRE / on-call | Kill switch + diagnostics | Audit |
| OSS contributor | Settings (hooks, integrations) | Diagnostics |

See `rulestead-personas-jtbd-and-onboarding.md` for full persona definitions + JTBD → screen mapping.

---

## 15. Do / Don't quick list

**Do:**
- Scope everything by tenant + env, always in URL.
- Require a reason on every mutation.
- Show diff before publish.
- Run simulate before publish (blocking).
- Emit audit event on every mutation (`Ecto.Multi`).
- Use LiveView streams for any list >100 rows.
- Cancel outstanding `assign_async` when params change.
- Use `~p"/admin/flags"` verified routes only.
- Respect host's layout + CSP.

**Don't:**
- Don't page-refresh — use PubSub + streams.
- Don't surface global kill-switches without confirmation + reason.
- Don't auto-apply AI suggestions.
- Don't color-code status alone (add icon + text).
- Don't show PII in audit without redaction.
- Don't bury destructive actions in kebab menus.
- Don't let optimistic updates lie — reconcile on server response.
- Don't ship a fork-required CSS setup — CSS custom properties only.

---

## 16. TL;DR — the admin UX thesis

> The rulestead admin is a **mounted LiveView** that treats the operator as a skilled professional with keyboard shortcuts and sub-second feedback, prioritizes **explain** and **simulate** as first-class surfaces, enforces **preview → confirm → audit** on every mutation, and scales from 10 flags to 10,000 via streams + keyset pagination. Progressive disclosure hides complexity until operators need it; multi-tenancy is enforced in every query; AI-assist is always suggestive, never autopilot.
