# Phase 30: Mounted Admin Tenant Scope Closure - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead_admin/lib/rulestead_admin/live/session.ex` | hook | request-response | `rulestead_admin/lib/rulestead_admin/live/session.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/shell.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/components/shell.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` | exact |
| `rulestead_admin/test/rulestead_admin/live/session_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/session_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs` | exact |
| `rulestead/lib/rulestead/store/command.ex` | model | request-response | `rulestead/lib/rulestead/store/command.ex` | exact |
| `rulestead/lib/rulestead/promotion/compare.ex` | service | request-response | `rulestead/lib/rulestead/promotion/compare.ex` | exact |
| `rulestead/test/rulestead/promotion/compare_test.exs` | test | request-response | `rulestead/test/rulestead/promotion/compare_test.exs` | exact |
| `rulestead/test/rulestead/store/compare_contract_test.exs` | test | request-response | `rulestead/test/rulestead/store/compare_contract_test.exs` | exact |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/live/session.ex` (hook, request-response)

**Use as the primary Phase 30 seam.** This is already the mounted-admin resolver and route helper surface.

**Resolution pattern**
- Copy the existing `resolve/3` precedence structure from `rulestead_admin/lib/rulestead_admin/live/session.ex:41-72`.
- Current environment inputs already come from:
  - URL param
  - remembered session value (`"rulestead_admin_last_env"`)
  - allowed host-provided environments
  - fail-closed error when nothing valid exists
- Phase 30 should add tenant resolution alongside that flow, not beside it in ad hoc page code.

**Mount assign pattern**
- Reuse the `on_mount/4` assign shape in `rulestead_admin/lib/rulestead_admin/live/session.ex:19-38`.
- Keep tenant data in the same shared mounted-admin session assign family as environment data.
- Add tenant-specific assigns here so downstream LiveViews read from one resolved source.

**Route helper pattern**
- Preserve the current helper ownership split in:
  - `current_path/3` at `rulestead_admin/lib/rulestead_admin/live/session.ex:74-86`
  - `env_links/3` at `rulestead_admin/lib/rulestead_admin/live/session.ex:88-95`
- Phase 30 should extend these helpers to preserve `tenant` and `env` together.
- Do not rebuild compare URLs manually in individual LiveViews.

**Placeholder/page-state pattern**
- Reuse `placeholder_assigns/2` in `rulestead_admin/lib/rulestead_admin/live/session.ex:140-155`.
- This is the established way to hand shell-visible scope state into mounted pages.

### `rulestead_admin/lib/rulestead_admin/components/shell.ex` (component, request-response)

**Use as the shell chrome insertion point for tenant visibility.**

**Existing reusable asset**
- `attr(:env_links, :map, default: %{})` at `rulestead_admin/lib/rulestead_admin/components/shell.ex:11`
- Environment navigation link rendering at `rulestead_admin/lib/rulestead_admin/components/shell.ex:35`

**Pattern to copy**
- Keep scope chrome centralized in `Shell.page`, not duplicated inside compare pages.
- Add tenant display next to, but distinct from, environment scope. Phase 29 locked these as separate axes.
- Follow the current shell pattern of passing fully prepared assigns in from `Session.placeholder_assigns/2` or `build_page/…` rather than having the component resolve session state on its own.

**Closest visibility analog**
- `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex:67-72` shows the repo’s current pattern for rendering explicit scope banners without implying broader discovery.

### `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` (component, request-response)

**Use as the main compare carry-through analog.**

**Mounted page-state pattern**
- The page already builds route-backed compare state and shell props in:
  - `Session.env_links(socket, admin_base_path(socket, "/compare"), params)` at `.../index.ex:139`
  - `Session.current_path(socket, admin_base_path(socket, "/compare"), params)` at `.../index.ex:144`
- Extend the `params` map here so `tenant` travels with `source_env` and `target_env`.

**Shared compare call pattern**
- The compare invocation already happens through the public seam:
  - `Rulestead.compare_environments(...)` at `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:153`
- Phase 30 should keep that seam and add `tenant_key:` in the options passed to it.
- Do not reach into store adapters directly from LiveView code.

**Policy/scope rendering pattern**
- `OperatorComponents.policy_state` is rendered at `.../index.ex:60`.
- Keep tenant scope visible in shell/page assigns; do not overload policy state to carry tenant selection.

### `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` (component, request-response)

**Use as the drill-in route analog.** Phase 30’s route preservation decision applies here too, even though the context names `index.ex` first.

**Param carry-through pattern**
- `build_page/5` composes the page params map at `.../show.ex:115-132`.
- It already preserves `source_env`, `target_env`, and optional `compare_token`.
- Add `tenant` to this params map so drill-in links and env-switch links do not drop tenant scope.

**Compare invocation pattern**
- `load_compare/1` builds options and calls `Rulestead.compare_environments/3` at `.../show.ex:135-156`.
- Extend the options keyword list with `tenant_key:` from resolved mounted session state.

**Trace panel pattern**
- `trace_rows/2` at `.../show.ex:171-178` is the established place to surface compare scope metadata.
- Add tenant there instead of hiding it only in raw params.

### `rulestead_admin/test/rulestead_admin/live/session_test.exs` (test, request-response)

**Use as the resolver precedence test anchor.**

**What to extend**
- Existing coverage already exercises remembered environment and policy-state behavior; see hits around:
  - `rulestead_admin/test/rulestead_admin/live/session_test.exs:22`
  - `rulestead_admin/test/rulestead_admin/live/session_test.exs:39`
  - `rulestead_admin/test/rulestead_admin/live/session_test.exs:54`
  - `rulestead_admin/test/rulestead_admin/live/session_test.exs:85`

**Pattern to copy**
- Stay in small direct `Session.resolve/3` unit tests.
- Add tenant precedence cases parallel to environment cases:
  - URL tenant wins when allowed
  - remembered tenant wins when URL missing
  - default or first allowed tenant fills the gap
  - invalid tenant never broadens scope

### `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` (test, request-response)

**Use as the summary-route verification pattern.**

**Session fixture pattern**
- Mounted session setup lives at `.../index_test.exs:15-25`.
- Copy this shape when adding allowed-tenant and default-tenant host session keys.

**URL-backed assertion pattern**
- Existing request-response assertions at `.../index_test.exs:30-43` already verify compare state is visible in HTML via query params.
- Extend these assertions to require `tenant=...` carry-through alongside `source_env` and `target_env`.

**Mounted compare posture**
- The test at `.../index_test.exs:64-74` confirms drill-in navigation stays mounted and read-only.
- Add tenant-preservation assertions to that same route family rather than creating a broad new UI test.

### `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs` (test, request-response)

**Use as the drill-in route verification pattern.**

**Existing route fixture**
- Mounted route setup at `.../show_test.exs:30-35` already exercises explicit compare params on the detail page.

**Pattern to copy**
- Add tenant in the route under test and assert it survives:
  - page render
  - compare token refresh/stale flows
  - read-only drill-in presentation

**Best assertion slot**
- The compare token and flag metadata assertions at `.../show_test.exs:43-55` are the cleanest place to add tenant-scope visibility checks.

### `rulestead/lib/rulestead/store/command.ex` (model, request-response)

**Use as the canonical compare command contract.**

**Reusable asset**
- `Command.CompareEnvironments` already includes `tenant_key` in its struct and constructor:
  - struct/default at `rulestead/lib/rulestead/store/command.ex:184`
  - type at `.../command.ex:192`
  - normalization in `new/3` at `.../command.ex:202`

**Integration rule**
- Mounted-admin code should pass `tenant_key` into this existing seam.
- Do not invent a mounted-admin-only compare option shape.

### `rulestead/lib/rulestead/promotion/compare.ex` (service, request-response)

**Use as the compare payload and token contract anchor.**

**Reusable asset**
- Tenant propagation already exists in the compare service:
  - option normalization at `rulestead/lib/rulestead/promotion/compare.ex:37-38`
  - result payload field at `.../compare.ex:89`
  - compare-token basis at `.../compare.ex:191-192`

**Integration rule**
- Phase 30 should only ensure mounted-admin callers pass the tenant.
- Do not change compare token semantics in this phase unless mounted-admin exposure proves they are missing, because the contract tests already assume tenant participates in the token.

### `rulestead/test/rulestead/promotion/compare_test.exs` (test, request-response)

**Use as the narrow public-facade regression anchor.**

**Existing reusable asset**
- The file already proves compare command normalization and public facade delegation.

**Pattern to copy**
- Add tenant-aware assertions beside the existing command/facade tests, not in a new broad integration harness.
- Reuse the current compare-token stability structure to prove tenant changes produce distinct tokens when authored scope is otherwise identical.
- Keep the test focused on the public seam that mounted-admin callers use.

### `rulestead/test/rulestead/store/compare_contract_test.exs` (test, request-response)

**Use as the adapter-parity regression anchor.**

**Existing reusable asset**
- The file already verifies fake/ecto parity and staleness behavior for compare results.

**Pattern to copy**
- Extend parity assertions to keep tenant-aware compare scope explicit.
- Prefer additive assertions around tenant-scoped payload and token behavior instead of broad fixture rewrites.
- Keep mounted-admin concerns out of this file; it should continue to prove the shared compare seam only.

## Shared Patterns

### Mounted scope resolution
**Source:** `rulestead_admin/lib/rulestead_admin/live/session.ex:19-38`, `:41-72`

Apply to all mounted-admin pages that need tenant awareness.

- Resolve once in the shared session seam.
- Assign normalized scope to socket assigns.
- Reuse helper-generated URLs instead of page-local query assembly.

### Route-backed scope carry-through
**Source:** `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:139-144`, `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex:115-132`

Apply to compare summary and drill-in routes.

- Build one params map.
- Hand that map to both `Session.env_links/3` and `Session.current_path/3`.
- Preserve `tenant`, `env`, `source_env`, `target_env`, and `compare_token` together where applicable.

### Compare seam discipline
**Source:** `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:153`, `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex:140-144`, `rulestead/lib/rulestead/store/command.ex:184-202`, `rulestead/lib/rulestead/promotion/compare.ex:37-38`

Apply to all mounted compare invocations.

- Call `Rulestead.compare_environments/3`.
- Pass `tenant_key` explicitly.
- Let core compare logic own token generation and findings.

### Targeted verification posture
**Source:** `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs:30-74`, `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs:30-68`, `rulestead/test/rulestead/promotion/compare_test.exs:77-126`, `rulestead/test/rulestead/store/compare_contract_test.exs:236-268`

Apply to new or modified tests.

- Prefer small mounted-route tests over broad end-to-end expansion.
- Assert visible scope and compare invocation semantics.
- Reuse the core compare tests as proof that `tenant_key` already affects command normalization and token stability.

## Reusable Assets And Integration Points

- `rulestead_admin/lib/rulestead_admin/live/session.ex`: single source of truth for mounted-admin scope resolution.
- `rulestead_admin/lib/rulestead_admin/components/shell.ex`: single shell chrome location for visible tenant scope.
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`: summary route that must keep tenant in query-backed page state.
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex`: drill-in route that must keep tenant during compare-token carry-through.
- `rulestead/lib/rulestead/store/command.ex` and `rulestead/lib/rulestead/promotion/compare.ex`: already-correct tenant-aware compare seam; Phase 30 should plug into it, not redesign it.
- `rulestead/test/rulestead/promotion/compare_test.exs`: narrow public compare regression surface for explicit `tenant_key` carry-through.
- `rulestead/test/rulestead/store/compare_contract_test.exs`: adapter parity proof that tenant-aware compare tokens and payloads stay stable across fake and ecto.
- `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs`: local simulation already demonstrates explicit tenant input; use it as a behavioral reminder, not as the mounted-route implementation pattern.

## Anti-Patterns For This Phase

- Do not derive allowed tenants from authored storage, compare payloads, or flag data. Host session remains authoritative.
- Do not treat invalid `tenant` params as permission to drop back to implicit all-tenant scope.
- Do not hide tenant inside `env`, policy state, or compare-token-only metadata. Tenant and environment stay separate visible axes.
- Do not hand-build compare URLs in individual pages when `Session.current_path/3` and `Session.env_links/3` should own route preservation.
- Do not bypass `Rulestead.compare_environments/3` with direct store calls from LiveViews.
- Do not widen Phase 30 into write-path provenance automation. That remains Phase 31 work per `30-CONTEXT.md`.

## No Exact Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Tenant scope chrome inside `Shell.page` | component | request-response | Shell currently renders environment scope only, so Phase 30 must add a second explicit scope indicator rather than copy an existing tenant-aware header verbatim. |

## Metadata

**Analog search scope:** `rulestead_admin/lib/rulestead_admin/live`, `rulestead_admin/lib/rulestead_admin/components`, `rulestead_admin/test/rulestead_admin/live`, `rulestead/lib/rulestead`, `rulestead/test/rulestead`

**Pattern extraction date:** 2026-05-22
