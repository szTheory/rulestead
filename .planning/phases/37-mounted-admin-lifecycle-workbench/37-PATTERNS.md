# Phase 37: Mounted Admin Lifecycle Workbench - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 12 proposed Phase 37 surfaces
**Analogs found:** 10 / 12 direct or partial matches

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | LiveView | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | LiveView | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` | LiveView | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_preview.ex` | LiveView | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` + `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex` | hybrid |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_confirm.ex` | LiveView | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` | role-match |
| `rulestead_admin/lib/rulestead_admin/router.ex` | router | request-response | `rulestead_admin/lib/rulestead_admin/router.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/session.ex` | utility | request-response | `rulestead_admin/lib/rulestead_admin/live/session.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` / `cleanup_confirm_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/kill_test.exs` + `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | hybrid |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`

**Use for:** URL-backed filter normalization, canonical `push_patch` flows, lifecycle preset links, and queue-state preservation.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`

**Copy this**

- `handle_params/3` canonicalization loop from lines `34-51`.
  - Merge decoded query params with route params.
  - Normalize once.
  - Compare `current_path` to canonical path.
  - `push_patch` only when the URL is not canonical.
- `filters_changed` event from lines `55-62`.
  - Merge incoming filters into current filters.
  - Reset cursors (`after`/`before`) before patching.
- Filter vocabulary and whitelist normalization from lines `9-12`, `290-305`.
  - Phase 37 should extend the same one-truth query contract instead of inventing a second lifecycle dialect.
- `list_opts/1` from lines `227-239`.
  - Keep UI filters mapped directly into `Rulestead.list_flags/1` options.
- `environment_links/3` and `pagination_params/1` from lines `242-260`.
  - Keep queue links shareable and environment-switch-safe.

**Concrete excerpt to copy**

```elixir
def handle_params(params, uri, socket) do
  merged_params = Map.merge(query_params(uri), stringify_keys(params))
  filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
  current_path = path_with_query(uri)
  canonical_path = build_index_path(socket.assigns.base_path, filters)

  if canonical_path != current_path do
    {:noreply, push_patch(socket, to: canonical_path)}
  else
    ...
  end
end
```

```elixir
def handle_event("filters_changed", %{"filters" => filters}, socket) do
  merged_filters =
    socket.assigns.filters
    |> Map.merge(filters)
    |> Map.put("after", nil)
    |> Map.put("before", nil)

  {:noreply, push_patch(socket, to: build_index_path(...))}
end
```

**Avoid this**

- Do not keep lifecycle preset state in assigns-only memory.
- Do not add a second route with a different filter schema for lifecycle workbench presets.
- Do not reuse the current `flag_path/3` and `cleanup_path/3` helpers for Phase 37 action-entry links if they only preserve `env`; those helpers at lines `412-413` drop queue filters and are too weak for `return_to`.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

**Use for:** Calm read surface, lifecycle guidance projection, and cross-LiveView deep links out to dedicated workflows.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

**Copy this**

- `handle_params/3` plus `Session.current_path/2` and `Session.env_links/2` wiring from lines `23-35`.
- Link-out posture from lines `56-59`, `117`, `204-232`.
  - Detail stays readable.
  - Dedicated routes do the real work.
- Section-card composition for lifecycle and evidence from lines `101-163`.
  - Preview/confirm routes should project the same lifecycle payload instead of recomputing a local view model.

**Concrete excerpt to copy**

```elixir
socket
|> assign(:flag_key, key)
|> assign(:current_path, Session.current_path(socket, base_path))
|> assign(:env_links, Session.env_links(socket, base_path))
|> load_detail(key, env)
```

```elixir
<FlagComponents.section_card title="Archive readiness guidance">
  <p>
    <FlagComponents.readiness_badge readiness={archive_readiness(@detail).readiness} />
    <FlagComponents.evidence_quality_badge quality={archive_readiness(@detail).evidence_quality} />
  </p>
  <p>
    <strong>Primary recommendation:</strong> <%= primary_action_label(archive_readiness(@detail)) %>
  </p>
</FlagComponents.section_card>
```

**Avoid this**

- Do not turn detail into the mutation hub.
- Do not place archive confirm UI directly on this page.
- Do not add a second copy of cleanup evidence here; link into cleanup/preview instead.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`

**Use for:** Canonical pre-mutation review surface and lifecycle evidence summary.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`

**Copy this**

- Capability gate and mounted redirect from lines `23-29`.
- `Session.current_path/2` and `Session.env_links/2` setup from lines `30-38`.
- Summary-grid plus section-card layout from lines `63-124`.
- Evidence wording helpers such as `guidance_limited?/1` and `scan_label/1` from lines `204-251`.

**Concrete excerpt to copy**

```elixir
if not capabilities.edit? and not capabilities.execute? and not capabilities.admin? do
  {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
else
  ...
end
```

```elixir
<div class="rs-summary-grid" aria-label="Cleanup summary">
  <FlagComponents.stat title="Archive readiness" ... />
  <FlagComponents.stat title="Evidence quality" ... />
  <FlagComponents.stat title="Code references" ... />
  <FlagComponents.stat title="Evaluation evidence" ... />
</div>
```

**Avoid this**

- Do not keep the Phase 36 copy that says mutation comes later; replace that with explicit links to preview/confirm.
- Do not mutate directly from `cleanup.ex` if the route contract now says `cleanup -> preview -> confirm`.
- Do not downgrade capability checks to cosmetic hiding only.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_preview.ex`

**Use for:** Route-backed preview screen with shareable URL, evidence summary, mutation impact summary, and entry into confirmation.

**Closest analogs**

- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex`
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`

**Copy this**

- From `cleanup.ex` lines `63-124`: summary grid and evidence cards.
- From `kill.ex` lines `25-39`, `73-103`: dedicated governed route, back-link, summary block, explicit action panel.
- From `change_request_live/show.ex` lines `167-178`: explicit confirm step and “Back to preview” posture, but only as route semantics, not a same-page toggle.
- From `show.ex` lines `139-163`: archive readiness guidance, reasons, blockers, unknowns.

**What this means for Phase 37**

- The preview page should remain read-dominant like `cleanup.ex`.
- The CTA should navigate to `/cleanup/confirm`, not mutate inline.
- Reason entry can begin on preview if desired, but final apply should stay on confirm.

**Avoid this**

- Avoid copying `pending_action` state from `change_request_live/show.ex` as an in-page confirmation mode.
  - Phase 37 explicitly wants route-backed preview and confirm.
- Avoid using `push_patch` between preview and confirm if they are separate LiveViews.
  - Use `navigate`/`href` between routes.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_confirm.ex`

**Use for:** Governed destructive confirmation, required reason, typed-key confirmation in production, and revalidation-before-apply.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex`

**Copy this**

- Dedicated action route and summary grid from lines `25-39`, `73-103`.
- Reason validation from lines `122-123`, `152-153`, `211-212`.
- Environment-sensitive typed confirmation from lines `203-219`.
- Success notice pattern from lines `136`, `166`.

**Concrete excerpt to copy**

```elixir
with :ok <- validate_reason(reason),
     :ok <- validate_confirmation(socket.assigns.flag_key, socket.assigns.current_environment.key, confirmation),
     {:ok, _payload} <- ... do
  {:noreply, socket |> assign(:notice, "...") |> load_detail(...)}
else
  {:error, error} -> ...
  {:validation, message} -> ...
end
```

```elixir
defp validate_confirmation(flag_key, environment_key, confirmation) do
  if production_env?(environment_key) and confirmation != flag_key do
    {:validation, "Type the exact flag key to confirm this production action."}
  else
    :ok
  end
end
```

**Phase 37 additions beyond the analog**

- Revalidate current lifecycle/readiness state immediately before archive apply.
- If revalidation fails, block apply and navigate or re-render back to preview/confirm with a clear drift message.
- Success should return to canonical `return_to`, not stay on the confirm route.

**Avoid this**

- Do not mutate without a reason.
- Do not skip typed confirmation in production.
- Do not leave the operator stranded on confirm after success.

### `rulestead_admin/lib/rulestead_admin/router.ex`

**Use for:** New cleanup preview/confirm route shape under the existing mounted seam.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/router.ex`

**Copy this**

- Mounted `live_session` seam from lines `16-18`.
- Sibling route shape from lines `22-43`.

**Phase 37 route pattern**

- Add sibling routes under the existing flag branch:
  - `live("/:key/cleanup/preview", ...)`
  - `live("/:key/cleanup/confirm", ...)`
- Keep everything under the same mount path and same `live_session`.

**Avoid this**

- Do not create a second lifecycle router subtree.
- Do not create a separate `/admin/lifecycle` product surface.

### `rulestead_admin/lib/rulestead_admin/live/session.ex`

**Use for:** Mounted-admin session/path helpers, canonical env/tenant propagation, and reusable `return_to` building.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/live/session.ex`

**Copy this**

- `current_path/3` from lines `105-124`.
- `env_links/3` from lines `126-146`.
- `placeholder_assigns/2` from lines `210-229`.

**Concrete excerpt to copy**

```elixir
params
|> Map.put("env", env_key)
|> maybe_put_scope_param("tenant", tenant_key)
|> encode_params()
|> then(&"#{base_path}?#{&1}")
```

**Phase 37 helper guidance**

- Add any `return_to` helper here, not ad hoc inside individual LiveViews.
- Canonicalize `return_to` through the same env/tenant-aware path discipline used elsewhere.

**Avoid this**

- Avoid string-building return paths manually in each LiveView.
- Avoid preserving only `env` when the originating queue needs `owner`, `lifecycle`, `readiness`, `include_archived`, and similar params.

### `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`

**Use for:** Badge/card/stat reuse across lifecycle workbench, preview, confirm, and audit-adjacent outcome surfaces.

**Primary analog:** `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`

**Copy this**

- Badge primitives from lines `8-91`.
- `stat/1` from lines `138-146`.
- `section_card/1` from lines `150-157`.
- Existing tone mapping for lifecycle, readiness, and evidence.

**Concrete excerpt to copy**

```elixir
<span class="rs-badge rs-badge--readiness" data-tone={@tone}>
  <%= @label %>
</span>
```

```elixir
<article class="rs-stat" data-tone={@tone}>
  <p class="rs-stat__title"><%= @title %></p>
  <p class="rs-stat__value"><%= @value %></p>
</article>
```

**Avoid this**

- Do not invent a parallel lifecycle badge component set unless the new surface truly needs a new semantic type.
- Do not collapse lifecycle, stale status, readiness, and evidence quality into one badge.

### `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`

**Use for:** LiveView param round-tripping, canonical patch assertions, and queue filter persistence tests.

**Primary analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`

**Copy this**

- `assert_patch/1` flow from lines `128-166`, `204-206`.
- Selected-option assertions and URL-backed filter round-trip from lines `179-209`.
- Table-row assertions keyed by `data-flag-key`.

**Phase 37 tests to add based on this**

- lifecycle preset links normalize into canonical query params
- owner exact filter survives patches
- `return_to` generated from current queue contains canonical filters
- post-action return injects or preserves `include_archived=true`

**Avoid this**

- Do not test only rendered text when the key behavior is URL canonicalization.

### `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`

**Use for:** Calm-detail posture tests and deep-link entrypoint tests.

**Primary analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`

**Copy this**

- Route-link assertions from lines `153-157`.
- Archive-readiness rendering assertions from lines `204-224`.
- “detail is not the workflow hub” posture from the change-request/schedule preview card test around lines `191-201`.

**Avoid this**

- Do not add tests that require direct archive submission from detail.

### `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`

**Use for:** Cleanup pre-mutation review assertions and weak-evidence rendering tests.

**Primary analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`

**Copy this**

- Existing evidence assertions from lines `88-104`.
- Keep tests focused on reasons, blockers, unknowns, and next-step links.

**Phase 37 adaptation**

- Replace the Phase 36 “advisory only” assertion with:
  - preview CTA present
  - confirm route not present until preview/confirm step
  - `return_to` hidden field or link param present when originating from queue

**Avoid this**

- Do not leave the old “no archive submission controls” expectation once preview/confirm ships.

### `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` / `cleanup_confirm_test.exs`

**Use for:** Route-backed destructive-flow tests, confirmation rules, redirect behavior, and revalidation failures.

**Closest analogs**

- `rulestead_admin/test/rulestead_admin/live/flag_live/kill_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`

**Copy this**

- From `kill_test.exs` lines `74-123`: non-prod vs prod confirmation expectations.
- From `kill_test.exs` lines `154-174`: success changes underlying state and preserves route behavior.
- From `index_test.exs` lines `179-206`: assert URL params, not just copy.

**Phase 37 tests to add**

- preview loads with `return_to` and renders canonical lifecycle evidence
- confirm rejects blank reason
- confirm requires exact typed key in production
- confirm revalidation failure blocks archive and explains drift
- success redirects to canonical `return_to`
- success preserves or injects `include_archived=true`
- returned queue shows outcome banner and keeps archived flag visible

**Avoid this**

- Do not rely only on flash copy without asserting redirect target.

## Shared Patterns

### URL-backed normalization and patching

**Sources**

- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` lines `34-62`, `263-305`
- `rulestead_admin/lib/rulestead_admin/live/schedule_live/index.ex` lines `20-25`, `208-230`
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/index.ex` lines `22-47`

**Apply to**

- `FlagLive.Index`
- lifecycle preset shortcuts
- any queue-return banner/highlight state that must survive refresh

**Rule**

- Normalize in `handle_params/3`.
- Patch only to canonical URL.
- Reset cursors when changing filters.
- Encode filter state in query params, never only in assigns.

### Cross-LiveView navigation with canonical paths

**Sources**

- `rulestead_admin/lib/rulestead_admin/live/session.ex` lines `105-146`, `210-229`
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex` lines `183-244`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` lines `56-59`, `365`

**Apply to**

- `show -> cleanup`
- `cleanup -> preview`
- `preview -> confirm`
- `confirm -> return_to queue`

**Rule**

- Build links with `Session.current_path/3`.
- Preserve env and tenant automatically.
- For queue return, preserve full canonical queue params, not only `env`.

### Governed destructive confirmation

**Sources**

- `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` lines `122-166`, `203-219`
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex` lines `55-76`, `167-178`

**Apply to**

- archive confirmation
- any later destructive lifecycle action added to the cleanup spine

**Rule**

- reason required
- production typed-key confirmation
- capability gate before action UI
- explicit success/error notice handling
- revalidate before apply

### Mounted-admin policy and redirect posture

**Sources**

- `rulestead_admin/lib/rulestead_admin/live/session.ex` lines `27-44`, `231-233`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` lines `23-29`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` lines `25-29`

**Apply to**

- preview
- confirm
- any new lifecycle mutation route

**Rule**

- unauthorized users should be redirected at route entry, not merely shown disabled buttons.

### Badge/card/stat reuse

**Sources**

- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` lines `8-91`, `138-157`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` lines `72-99`, `139-163`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` lines `63-124`

**Apply to**

- workbench lifecycle row affordances
- cleanup preview summary
- confirm summary
- post-action banner support content

**Rule**

- Keep the existing semantic split:
  - lifecycle badge
  - stale badge
  - readiness badge
  - evidence-quality badge

## What To Copy Vs What To Avoid

### Copy

- Canonical query normalization from `FlagLive.Index`.
- Env/tenant-aware path building from `Session`.
- Calm detail + dedicated workflow links from `FlagLive.Show`.
- Summary-grid + evidence rendering from `FlagLive.Cleanup`.
- Typed destructive confirmation from `FlagLive.Kill`.
- Related-route linking posture from `ChangeRequestLive.Show` and `ScheduleLive.Show`.
- `assert_patch/1` and selected-param assertions from `index_test.exs`.

### Avoid

- Manual `?env=` string concatenation for any new link that should preserve queue context.
- Inline modal-only destructive confirmations.
- Same-page `pending_action` confirmation mode for preview/confirm if the route must stay shareable.
- Direct archive action on detail.
- A second lifecycle list route or a second filter dialect.
- Conflating owner search with stable owner identity.

## No Direct Analog Found

| Surface | Role | Data Flow | Gap |
|---|---|---|---|
| `return_to` canonical full-path param | utility | request-response | Existing code preserves env/tenant and sometimes queue filters, but no current helper stores the entire origin queue path as a first-class param. |
| Outcome banner + one-time archived row highlight on queue return | component / LiveView | request-response | No existing mounted-admin pattern currently echoes mutation result back into the originating flag inventory queue. |

**Planner guidance for these gaps**

- Build `return_to` on top of `Session.current_path/3`; do not invent a second path canonicalizer.
- For queue-return outcome UI, reuse `FlagComponents.section_card` / badge tones and keep the state URL-backed so refreshes remain honest.

## Metadata

**Analog search scope:** `rulestead_admin/lib/rulestead_admin/live`, `rulestead_admin/lib/rulestead_admin/components`, `rulestead_admin/test/rulestead_admin/live/flag_live`

**Key files scanned:** `router.ex`, `session.ex`, `flag_live/index.ex`, `flag_live/show.ex`, `flag_live/cleanup.ex`, `flag_live/kill.ex`, `change_request_live/index.ex`, `change_request_live/show.ex`, `schedule_live/index.ex`, `schedule_live/show.ex`, `flag_components.ex`, flag LiveView tests

**Planner-ready summary**

- Phase 37 should extend the existing `FlagLive.Index` URL contract, not introduce a second lifecycle console.
- Use `cleanup.ex` as the evidence-review spine, then add route-backed `preview` and `confirm` LiveViews modeled on `kill.ex` confirmation discipline.
- Build `return_to` and cross-LiveView links on `Session.current_path/3`; avoid the current flag-local helpers that only preserve `env`.
- Reuse `FlagComponents` badges/cards/stats so lifecycle, freshness, readiness, and evidence quality remain visibly separate.
- Test URL params, redirects, and confirmation rules explicitly. Do not settle for text-only assertions.

Pattern mapping complete. This document is ready for the planner.
