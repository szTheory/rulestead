# Phase 22: Environment Compare & Conflict Model - Research

**Researched:** 2026-05-18
**Domain:** Authored-state environment compare, dependency closure, stale-preview tokens, and mounted admin compare UX for environment promotion. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
**Confidence:** MEDIUM-HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Compare Surface and Route Model
- **D-01:** Phase 22 starts with a **hybrid compare surface**: a lightweight environment-to-environment summary page that lists only differing or problematic flags, plus a per-flag compare drill-in where the real authored-state reasoning happens.
- **D-02:** Do **not** start with a standalone compare console that behaves like a release-orchestration product. Do **not** hide full compare only inside the existing flag detail page.
- **D-03:** The summary route stays read-only and shallow in Phase 22. It exists for discovery, scanability, and navigation into the per-flag compare screen, not for mutation.
- **D-04:** The compare entry should preserve the mounted admin’s existing URL/state discipline. Environment selection remains explicit and URL-backed; do not fork the current admin model into hidden session-only compare state.
- **D-05:** Phase 22 compare is whole-flag compare. Partial-rule or cherry-pick promotion remains deferred with `PROM-05`.

### Authored-State Boundary
- **D-06:** The canonical authored compare set is:
  - global flag metadata (`key`, description, flag/value type, default value, owner, lifecycle fields, tags, archive state)
  - the source and target environment’s **published** ruleset and active pointer
  - the dependency closure required to realize that published authored state, especially referenced audiences and similar prerequisite authored objects
- **D-07:** Draft rulesets are authored work, but they are **not** part of the default promotable compare basis. Surface them as explicit unpublished work so operators see that source has newer saved intent without accidentally promoting drafts.
- **D-08:** Kill-switch overrides, runtime snapshots, evaluation freshness counters, telemetry-derived stats, audit history, approval state, and similar operational/process artifacts are **not** part of authored compare. Surface them separately as warnings or banners when relevant.
- **D-09:** The compare model must preserve the project’s existing split: authored publication changes the desired config, and runtime snapshots/operational overlays remain separate consequences or overlays of that authored state.

### Dependency and Conflict Taxonomy
- **D-10:** Compare findings use a typed three-severity model:
  - `blocker` — not safe to apply because the proposed target state is invalid, unreproducible, or stale
  - `warning` — applyable, but operator intent may be misunderstood or runtime behavior may still differ due to non-authored state
  - `info` — observational drift or non-blocking asymmetry
- **D-11:** Severity is derived from **apply safety**, not from how visually different two environments are.
- **D-12:** Findings should also carry a typed class such as `missing_dependency`, `lifecycle_conflict`, `staleness_conflict`, `operational_override`, `soft_mismatch`, or `drift_info`, so later CLI and manifest workflows can preserve meaning without scraping prose.
- **D-13:** Recommended default classifications:
  - missing prerequisite/dependency required to realize source authored state -> `blocker`
  - source changed since preview -> `blocker`
  - target changed since preview -> `blocker`
  - stale preview bundle / compare token -> `blocker`
  - archived/retired target state that would require an explicit revive path -> `blocker`
  - active kill-switch or similar operational override difference -> `warning` by default
  - missing target `flag_environment` row that apply can legitimately create -> `warning`
  - protected target environment requiring governed apply -> `warning`
  - target-only unrelated extra state outside the selected authored scope -> `info`
- **D-14:** Do not silently treat operational overrides as authored diffs. Surface them explicitly and separately.

### Stale-Preview Contract
- **D-15:** Every compare result must carry a `compare_token` built from:
  - source environment
  - target environment
  - compared flag keys
  - dependency-closure keys
  - compare schema/algorithm version
  - source and target authored-state heads or fingerprints for that exact set
- **D-16:** A preview becomes **hard-stale** if apply-relevant authored state changes on either side for the compared set or its dependency closure.
- **D-17:** Unrelated mutations elsewhere in the source or target environment must **not** invalidate the compare token.
- **D-18:** Add a warning-only age badge after a short window, but do **not** hard-expire compare purely on elapsed time.
- **D-19:** Phase 23 governed apply and Phase 24 CLI/manifest flows should treat this token as a real workflow contract, not a cosmetic UI hint.

### Result Shape and Information Hierarchy
- **D-20:** The compare result should use a layered hybrid presentation:
  - context bar first
  - overall status and counts next
  - findings buckets next
  - per-flag rows next
  - expandable structured diffs after that
  - raw/machine payload hidden behind progressive disclosure
- **D-21:** Raw document diff is the wrong default for Rulestead. Summary and go/no-go clarity come first; exact detail is available on demand.
- **D-22:** The UI and future CLI should render the same canonical compare payload instead of inventing separate summary logic per surface.
- **D-23:** Each flag compare entry should conceptually carry:
  - `flag_key`
  - status / severity summary
  - changed fields
  - dependency findings
  - drift findings
  - conflict findings
  - source state
  - current target state
  - proposed target state after apply
- **D-24:** Use explicit directionality in copy and structure: `source`, `current target`, and `proposed target after apply`. Never collapse these into a vague “before/after.”

### Recommendation-Heavy Planning Posture
- **D-25:** For this repo and milestone, shift recommendations left in downstream GSD work by default. Research and planning should come back with a coherent recommended path unless a choice is truly high-impact, product-defining, or dangerous to lock without user confirmation.
- **D-26:** “High-impact” here means a choice that would materially change product scope, public contract, security posture, or release shape. Normal implementation tradeoffs should default to recommendation-first rather than question-first.

### Claude's Discretion
- Exact module and payload struct names for compare projections, provided the authored-state boundary and finding taxonomy stay intact
- Exact route names and LiveView/module split for the summary and drill-in surfaces, provided the hybrid IA stays intact
- Exact fingerprint/head implementation strategy, provided it is stable and scoped to apply-relevant authored state rather than whole-environment churn
- Exact warning copy, badge labels, and progressive-disclosure mechanics, provided the calm operator posture and explicit directionality remain intact

### Deferred Ideas (OUT OF SCOPE)
- Bulk environment promotion console or release-pipeline UX
- Automated stage engines or multi-step promotion workflows
- Destructive prune semantics for target-only extra state
- Git-first reconciler as the primary authoring model
- Partial-rule or cherry-pick promotion as a primary UX
- Broader environment-management product surface beyond compare and promotion
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROM-01 | Operator can compare authored flag configuration between a source and target environment before making changes. [VERIFIED: `.planning/REQUIREMENTS.md`] | Build one canonical compare payload over `Flag` + `FlagEnvironment` + published `Ruleset` + referenced `Audience` closure, then expose it through a read-only core facade and mounted admin summary/drill-in routes. [VERIFIED: `rulestead/lib/rulestead/flag.ex`][VERIFIED: `rulestead/lib/rulestead/flag_environment.ex`][VERIFIED: `rulestead/lib/rulestead/ruleset.ex`][VERIFIED: `rulestead/lib/rulestead/audience.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`] |
| PROM-02 | Promotion preview reports dependency gaps, target drift, and conflict conditions before any target mutation occurs. [VERIFIED: `.planning/REQUIREMENTS.md`] | Classify findings by apply safety, include dependency closure and compare-token fingerprints in the payload, and preserve operational overrides and draft presence as separate warnings instead of flattening them into authored diff. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/governance/change_request.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
</phase_requirements>

## Summary

Phase 22 should be planned as a new read-only promotion substrate inside `rulestead`, not as UI-only diff code and not as early Phase 23 apply logic. The repo already has the authored-state primitives needed for compare: one canonical flag identity, per-environment authored overlays via `flag_environments`, immutable published rulesets, reusable audiences, and route-backed admin surfaces that keep environment scope explicit in `?env=`. [VERIFIED: `rulestead/lib/rulestead/flag.ex`][VERIFIED: `rulestead/lib/rulestead/flag_environment.ex`][VERIFIED: `rulestead/lib/rulestead/ruleset.ex`][VERIFIED: `rulestead/lib/rulestead/audience.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`]

The main planning risk is scope bleed. The phase description, roadmap, and locked context all say compare now, apply later. That means the plan should build a canonical compare result, a stable compare token scoped to apply-relevant authored state, dependency closure analysis, and two mounted read surfaces. It should not perform target mutation, schedule orchestration, prune extra target-only state, or turn `rulestead_admin` into a release console. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/REQUIREMENTS.md`][VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `AGENTS.md`][VERIFIED: `CLAUDE.md`]

The most pragmatic implementation path is to add a compare projection seam beside the existing store/facade model, reuse current authored payload serialization patterns, and keep one machine-readable payload for core, UI, and later CLI/manifests. The admin should only render that payload. This matches the repo’s established boundaries: core computes domain truth, LiveView handles route/state/rendering, and governance/change-request/scheduled-execution remain separate workflow objects until Phase 23. [VERIFIED: `rulestead/lib/rulestead/store.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead/lib/rulestead.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`]

**Primary recommendation:** Plan Phase 22 around one core compare service and payload in `rulestead`, one new public read facade, one fake+ecto parity contract suite, and two mounted LiveViews in `rulestead_admin` that consume the same payload without adding apply behavior. [VERIFIED: `rulestead/lib/rulestead/store.ex`][VERIFIED: `rulestead/lib/rulestead/fake.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Authored-state compare projection | API / Backend | Database / Storage | Source-of-truth data already lives in store-backed `Flag`, `FlagEnvironment`, `Ruleset`, and `Audience` structures, so diff semantics belong in `rulestead`, not LiveView templates. [VERIFIED: `rulestead/lib/rulestead/flag.ex`][VERIFIED: `rulestead/lib/rulestead/flag_environment.ex`][VERIFIED: `rulestead/lib/rulestead/ruleset.ex`][VERIFIED: `rulestead/lib/rulestead/audience.ex`] |
| Dependency closure and conflict classification | API / Backend | Database / Storage | Missing audiences, archived state, and stale compare heads are apply-safety facts derived from authored records and should be normalized once in the backend. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| Compare-token fingerprinting and stale-preview checks | API / Backend | — | Phase 23 and Phase 24 will consume the token as a real contract, so generation must be backend-owned and deterministic. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`] |
| Environment selection and compare navigation | Frontend Server (SSR) | Browser / Client | The admin already resolves canonical environment state through `handle_params/3`, `?env=`, and route-backed links. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Compare summary rendering and drill-in disclosure | Frontend Server (SSR) | Browser / Client | The mounted admin already owns summary grids, trace panels, readable diff cards, and policy banners. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: `CLAUDE.md`]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: `CLAUDE.md`]
- Preserve the sibling-package layout; do not collapse work into a single package shape. [VERIFIED: `CLAUDE.md`]
- Do not create Phase 8-only docs early. [VERIFIED: `CLAUDE.md`]
- `rulestead_admin` remains a guarded sibling package; do not add early publish flows that bypass the linked release design. [VERIFIED: `CLAUDE.md`]
- Prefer narrow, auditable changes and keep root docs honest about the current phase. [VERIFIED: `CLAUDE.md`]
- Use scripts-first CI surfaces where workflow logic becomes non-trivial. [VERIFIED: `CLAUDE.md`]
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: `AGENTS.md`]
- Do not widen scope into apply, release orchestration, or publishing `rulestead_admin`. [VERIFIED: `AGENTS.md`][VERIFIED: `.planning/ROADMAP.md`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing `rulestead` store/facade contract | local code [VERIFIED: `rulestead/lib/rulestead/store.ex`][VERIFIED: `rulestead/lib/rulestead.ex`] | Core compare entrypoint, compare payload structs, compare-token generation | The repo already centralizes authoring reads and writes through command/facade seams; compare should extend that pattern instead of inventing a side service. [VERIFIED: `rulestead/lib/rulestead/store.ex`][VERIFIED: `rulestead/lib/rulestead.ex`] |
| `Ecto.Multi` via `ecto_sql` | `3.13.5` [VERIFIED: `rulestead/mix.lock`] | Shared pattern for any compare-head snapshot persistence or audit-linked preview metadata if Phase 22 stores any helper rows | Current store code already uses `Ecto.Multi` for publish/governance paths, and official docs define it as the standard transaction composition API. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `Phoenix.LiveView` | `1.1.28` [VERIFIED: `rulestead_admin/mix.lock`] | Mounted compare summary and flag drill-in pages with URL-backed environment state | Existing admin routes use LiveView `handle_params/3`, and official docs confirm route-backed state and connected-only async loading. [VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing serialized authored payload helpers | local code [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] | Reuse `flag_summary`, `flag_environment_summary`, `serialize_ruleset`, and readable diff conventions as compare building blocks | Use for source/target/proposed projections so compare shape stays close to existing admin payloads. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| `Rulestead.Fake` parity seam | local code [VERIFIED: `rulestead/lib/rulestead/fake.ex`] | Deterministic compare contract coverage without DB coupling | Use for adapter parity and admin tests, matching the repo’s existing fake-backed workflow. [VERIFIED: `rulestead/lib/rulestead/fake.ex`][VERIFIED: `rulestead/test/support/store_contract_case.ex`] |
| Existing admin components | local code [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`] | Findings buckets, status lists, trace panels, and readable diff cards | Use to keep compare summary-first and consistent with prior admin surfaces. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Core-generated canonical compare payload | Build diff logic directly in LiveViews | That would duplicate semantics across UI and later CLI/manifest work and violate the repo’s backend-owned domain-truth pattern. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`] |
| Compare over published authored state only | Include draft rulesets in default compare basis | Locked scope says drafts must be surfaced as unpublished work, not folded into promotable authored state. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`] |
| Typed findings + compare token | Raw JSON diff only | Raw diff fails the repo’s summary-first operator posture and is not a stable contract for Phase 23/24 consumers. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`] |

**Installation:** No new dependency is warranted for Phase 22. Use the existing `rulestead` + `rulestead_admin` stack. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`]

**Version verification:** Locked project versions relevant to Phase 22 are `elixir 1.19.5`, `ecto_sql 3.13.5`, `phoenix 1.8.5`, and `phoenix_live_view 1.1.28`. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead/mix.lock`][VERIFIED: `rulestead_admin/mix.lock`][VERIFIED: local command `elixir -e 'IO.puts(System.version())'`]

## Architecture Patterns

### System Architecture Diagram

```text
Operator selects source env + target env + scope
  -> mounted compare summary LiveView (`?env=` + explicit source/target params)
  -> core compare facade in `rulestead`
     -> fetch source authored state
     -> fetch target authored state
     -> derive dependency closure (audiences and related authored refs)
     -> compute source fingerprint + target fingerprint for scoped set
     -> build findings:
        -> dependency gaps
        -> lifecycle conflicts
        -> staleness conflicts
        -> operational override warnings
        -> informational drift
     -> emit canonical compare payload + compare_token
  -> summary page renders counts + findings buckets + differing/problem flags
  -> operator opens per-flag drill-in
     -> same canonical payload, narrowed to one flag
     -> source / current target / proposed target sections
  -> Phase 23 later consumes compare_token to revalidate before apply
```

### Recommended Project Structure

```text
rulestead/
├── lib/rulestead/promotion/compare.ex              # canonical compare service/facade
├── lib/rulestead/promotion/compare_token.ex        # scoped fingerprint + token helpers
├── lib/rulestead/promotion/compare_result.ex       # payload structs / serializers
├── lib/rulestead/store/command.ex                  # CompareEnvironments / CompareFlag commands
├── lib/rulestead/store/ecto.ex                     # compare query/projection implementation
├── lib/rulestead/fake.ex                           # parity implementation
└── test/rulestead/                                 # compare contract + staleness tests

rulestead_admin/
├── lib/rulestead_admin/live/environment_compare_live/index.ex  # summary route
├── lib/rulestead_admin/live/environment_compare_live/show.ex   # per-flag drill-in
├── lib/rulestead_admin/components/                 # reuse operator/audit components
└── test/rulestead_admin/live/                      # compare UX/accessibility tests
```

### Pattern 1: Compare as a Core Projection

**What:** Compute compare results in `rulestead` using authored-state projections, then render them unchanged in admin and later CLI/manifests. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**When to use:** Every environment-to-environment preview, whether initiated from admin now or automation later. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`]

**Example:**

```elixir
# Source: project pattern adapted from rulestead/lib/rulestead.ex and store command usage
def compare_environments(source_env, target_env, opts \\ []) do
  source_env
  |> Rulestead.Store.Command.CompareEnvironments.new(target_env, opts)
  |> run_store(:compare_environments)
end
```

### Pattern 2: Route-backed Compare Screens

**What:** Keep source/target/scope state in the URL and drive reloading through `handle_params/3` or explicit param-building helpers. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`]

**When to use:** Summary and drill-in compare pages in the mounted admin. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**Example:**

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
def handle_params(params, _uri, socket) do
  source = params["source_env"]
  target = params["target_env"]
  {:noreply, assign(socket, :compare, load_compare(source, target))}
end
```

### Pattern 3: Connected-only Async Loading for Summary Pages

**What:** For the summary page only, defer compare loading until the socket is connected if the projection becomes expensive. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**When to use:** Environment summary pages that may compare many flags. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex`]

**Example:**

```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex
defp maybe_load_compare(socket) do
  if connected?(socket), do: load_compare(socket), else: socket
end
```

### Anti-Patterns to Avoid

- **Compare built from runtime snapshots:** Locked scope requires authored-state compare, and runtime snapshots include operational consequences rather than desired config. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
- **Whole-environment invalidation on unrelated writes:** The compare token must only depend on the scoped flags and dependency closure. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
- **Operational overrides treated as authored deltas:** Kill switch state must be surfaced separately as warning context. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/flag_environment.ex`]
- **Workflow logic embedded in compare pages:** Existing governance screens keep preview/review/action explicit and separate; Phase 22 should stay read-only. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`][VERIFIED: `.planning/ROADMAP.md`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transaction/composition boundary | Ad hoc nested Repo calls if any compare metadata becomes persisted later | `Ecto.Multi` | The store already uses it for publish/governance consistency, and it preserves auditable composition. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Admin diff primitives | New bespoke compare UI language | `OperatorComponents.summary_grid`, `status_list`, `trace_panel`, `AuditComponents.diff_card` | The admin already has calm summary-first rendering blocks. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`] |
| Compare-state navigation | Hidden session-only compare state | Existing `Session.current_path/3` and URL-backed params | Current admin pages already preserve environment scope and shareable URLs this way. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`] |
| Diff semantics for later consumers | Separate CLI and UI compare schemas | One canonical compare payload with typed findings | Locked scope explicitly requires UI and later CLI/manifests to render the same result. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`] |

**Key insight:** The repo already has the hard prerequisites for compare semantics. Phase 22 should add a contract over those primitives, not invent new domain storage or a new workflow engine. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`]

## Common Pitfalls

### Pitfall 1: Comparing Draft Intent Instead of Published Authored State

**What goes wrong:** The preview shows source draft edits as if they were promotable, which makes Phase 23 apply semantics ambiguous. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**Why it happens:** `fetch_flag` already exposes both `active_ruleset` and `draft_rulesets`, so it is easy to grab the wrong one. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`]

**How to avoid:** Base compare on `active_ruleset` only and attach a separate `unpublished_source_work?` warning when source drafts exist. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**Warning signs:** Proposed payload fields treat `draft_rulesets` as part of `proposed_target_state`. [VERIFIED: codebase grep]

### Pitfall 2: Missing Dependency Closure

**What goes wrong:** Source and target rulesets appear equivalent, but target cannot realize the promoted rules because referenced audiences or future tenant-sensitive authored objects are absent. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`]

**Why it happens:** Rules currently reference audiences by stable keys/IDs inside embedded rule documents, so the closure is not automatically obvious from top-level flag metadata. [VERIFIED: `rulestead/lib/rulestead/ruleset/rule.ex`][VERIFIED: `rulestead/lib/rulestead/audience.ex`]

**How to avoid:** Parse every published rule for dependency refs and carry a normalized dependency list into the compare result and token scope. [VERIFIED: `rulestead/lib/rulestead/ruleset/rule.ex`]

**Warning signs:** A compare plan talks only about `Flag` and `Ruleset` diffing and never mentions `Audience` closure. [VERIFIED: codebase grep]

### Pitfall 3: Coarse Staleness Checks

**What goes wrong:** Unrelated edits elsewhere in an environment invalidate a compare preview, producing noisy stale results and bad UX. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**Why it happens:** It is simpler to fingerprint “latest environment update” than the exact authored subset. [ASSUMED]

**How to avoid:** Fingerprint only the compared flag set plus referenced dependency closure, and include compare schema version in the token. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**Warning signs:** Token design depends on one environment-wide timestamp or snapshot version only. [VERIFIED: codebase grep]

### Pitfall 4: Compare Pages Becoming Early Apply Consoles

**What goes wrong:** The summary page starts to accrete action buttons, bulk mutation affordances, or schedule hooks, collapsing the compare/apply boundary. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

**Why it happens:** The compare payload will look close to a “plan,” and the existing governance screens already have explicit action flows. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex`]

**How to avoid:** Keep Phase 22 routes read-only and move all apply intent to Phase 23 plans. [VERIFIED: `.planning/ROADMAP.md`]

**Warning signs:** The plan includes `Approve`, `Execute`, `Schedule`, or mutation forms on Phase 22 routes. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and current project code:

### Existing Route-backed Environment State

```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/session.ex
def current_path(socket_or_assigns, base_path, params \\ %{}) do
  env_key =
    socket_or_assigns
    |> fetch_assign(:current_environment, %{})
    |> Map.get(:key, "dev")

  params
  |> Map.put("env", env_key)
  |> encode_params()
  |> then(&"#{base_path}?#{&1}")
end
```

### Existing Connected-only Async Pattern

```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex
defp load_health(socket) do
  environment_key = socket.assigns.page.current_environment.key

  assign_async(socket, :health_snapshot, fn ->
    {:ok, %{health_snapshot: build_health_view(environment_key)}}
  end)
end
```

### Existing Readable Before/After Audit Projection

```elixir
# Source: rulestead/lib/rulestead/store/ecto.ex
metadata:
  AuditEvent.metadata(%{
    before: Map.get(opts, :before, %{}),
    after: Map.get(opts, :after, %{}),
    diff: diff_map(Map.get(opts, :before, %{}), Map.get(opts, :after, %{}))
  })
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-environment duplicated flag identity | Unified flag identity with environment overlays | Locked in Phase 2 design and reaffirmed for `v0.6.0`. [VERIFIED: `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md`][VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`] | Compare can reason about one flag across environments instead of reconciling cloned identities. [VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`] |
| Raw or workflow-heavy promotion surface | Summary-first compare/apply model with explicit preview and separate apply phase | Locked for Phase 22 on 2026-05-18. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`] | Keeps the first multi-environment milestone calm and compatible with later governed apply and manifest flows. [VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`] |

**Deprecated/outdated:**
- Raw document diff as the default operator view: replaced here by typed findings plus progressive disclosure because the admin IA is explicitly summary-first. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The simplest coarse implementation path would tempt developers to use one environment-wide timestamp for staleness rather than a scoped fingerprint. [ASSUMED] | Common Pitfalls | Medium — planning may under-specify compare-token scope and create noisy invalidation behavior. |

## Open Questions

1. **Should Phase 22 expose one multi-flag compare facade, one per-flag compare facade, or both?**
   - What we know: The roadmap plans a summary surface plus per-flag drill-in, and the existing public facade already prefers explicit verbs and command structs. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `rulestead/lib/rulestead.ex`]
   - What's unclear: Whether the public core API should expose a list-level and drill-in-level command separately or one command with optional scope narrowing.
   - Recommendation: Plan one list-level compare command with optional `flag_keys` filtering; let the per-flag UI consume the same payload narrowed by scope. [VERIFIED: `rulestead/lib/rulestead/store/command.ex`][VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]

2. **Should compare-token fingerprints be derived from serialized compare input or from authored record heads?**
   - What we know: The token must include schema/algorithm version, source/target environments, compared keys, dependency-closure keys, and authored-state heads/fingerprints. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
   - What's unclear: The exact lowest-risk implementation in this codebase.
   - Recommendation: Plan for deterministic hashing of normalized authored projections per scope, because existing store payload serializers already provide stable, explicit maps and avoid dependence on whole-environment churn. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core compare implementation and tests | ✓ | `1.19.5` [VERIFIED: local command `elixir -e 'IO.puts(System.version())'`] | — |
| Mix | Test and verification commands | ✓ | present [VERIFIED: local command `mix --version`] | — |
| PostgreSQL client | Ecto-backed verification if Phase 22 includes adapter integration tests | ✓ | `14.17` [VERIFIED: local command `psql --version`] | Fake-backed contract tests still run without it, but Ecto parity coverage would be reduced. [VERIFIED: `rulestead/test/support/store_contract_case.ex`] |
| Docker | Optional local service orchestration | ✓ | `29.4.1` [VERIFIED: local command `docker --version`] | Not required if local Postgres is already available. [VERIFIED: `docker-compose.yml`] |
| Node/npm | Existing admin asset/toolchain context | ✓ | `v22.14.0` / `11.1.0` [VERIFIED: local command `node --version`][VERIFIED: local command `npm --version`] | Likely unnecessary for pure LiveView changes in this phase. [VERIFIED: `rulestead_admin/mix.exs`] |

**Missing dependencies with no fallback:** None identified. [VERIFIED: local command availability checks]

**Missing dependencies with fallback:** None identified. [VERIFIED: local command availability checks]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with fake-backed contract tests and LiveView integration tests. [VERIFIED: `rulestead/test/test_helper.exs`][VERIFIED: `rulestead_admin/test/test_helper.exs`] |
| Config file | `rulestead/config/test.exs` for core; package-local Mix projects for both packages. [VERIFIED: `rulestead/config/test.exs`][VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`] |
| Quick run command | `cd rulestead && mix test test/support/store_contract_case.ex test/rulestead/store_ecto_admin_test.exs test/rulestead/admin_governance_policy_test.exs` plus `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/change_request_live/show_test.exs`. [VERIFIED: `rulestead/test/support/store_contract_case.ex`][VERIFIED: `rulestead/test/rulestead/store_ecto_admin_test.exs`][VERIFIED: `rulestead/test/rulestead/admin_governance_policy_test.exs`][VERIFIED: `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`][VERIFIED: `rulestead_admin/test/rulestead_admin/live/change_request_live/show_test.exs`] |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test`. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROM-01 | Compare authored source vs target state using published rulesets and flag metadata only | unit + adapter contract | `cd rulestead && mix test test/rulestead/environment_compare_contract_test.exs` | ❌ Wave 0 |
| PROM-02 | Report dependency gaps, drift, operational warnings, and stale compare-token conflicts before any mutation | unit + integration | `cd rulestead && mix test test/rulestead/environment_compare_conflict_test.exs` | ❌ Wave 0 |
| PROM-01, PROM-02 | Mounted admin summary and drill-in render canonical compare payload with URL-backed scope and no apply actions | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the new focused compare tests in `rulestead` and `rulestead_admin`. [VERIFIED: existing targeted-package test pattern in `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`]
- **Per wave merge:** Run both package-local targeted suites plus any shared contract tests. [VERIFIED: `rulestead/test/support/store_contract_case.ex`]
- **Phase gate:** Full suite green in both packages before `/gsd-verify-work`. [VERIFIED: `.planning/config.json`]

### Wave 0 Gaps

- [ ] `rulestead/test/rulestead/environment_compare_contract_test.exs` — compare payload shape, authored-only scope, dependency closure, and fake/ecto parity. [VERIFIED: `rulestead/test/support/store_contract_case.ex`]
- [ ] `rulestead/test/rulestead/environment_compare_conflict_test.exs` — blocker/warning/info classification and compare-token staleness. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
- [ ] `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` — summary screen counts, findings buckets, and URL-backed source/target state. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`]
- [ ] `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs` — per-flag drill-in directionality and no-mutation posture. [VERIFIED: `.planning/ROADMAP.md`]
- [ ] Optional accessibility test pair for compare pages if new disclosure-heavy UI lands. [VERIFIED: `rulestead_admin/test/rulestead_admin/live/change_request_live/accessibility_test.exs`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host-owned auth/session remains the trust boundary for mounted admin routes. [VERIFIED: `prompts/rulestead-security-privacy-and-threat-model.md`][VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`] |
| V3 Session Management | yes | Mounted LiveViews inherit host `live_session` and `on_mount` policy resolution instead of creating a second session model. [VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| V4 Access Control | yes | Compare screens should authorize through the existing admin policy seam with environment-aware scope; Phase 23 apply remains separately governed. [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`][VERIFIED: `rulestead/test/rulestead/admin_governance_policy_test.exs`] |
| V5 Input Validation | yes | Normalize and validate source/target environment keys, optional flag scopes, and compare-token inputs through command structs and typed payloads. [VERIFIED: `rulestead/lib/rulestead/store/command.ex`] |
| V6 Cryptography | yes | Use standard hashing from the BEAM/runtime for compare-token fingerprints; never hand-roll token security semantics. [ASSUMED] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale preview replay after source/target authored state changes | Tampering | Scope compare tokens to exact authored heads and reject mismatches as `blocker` findings. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`] |
| Unauthorized visibility into protected environment compare data | Information Disclosure | Reuse mounted admin policy checks and environment-explicit routing before loading compare payloads. [VERIFIED: `rulestead/lib/rulestead/admin/policy.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`] |
| Operational override confusion (kill switch shown as authored diff) | Tampering | Surface operational overrides as separate warnings, not authored deltas. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/flag_environment.ex`] |
| Draft leakage into promotion preview | Integrity | Keep compare basis on published rulesets only and render draft presence as non-promotable context. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md` - locked Phase 22 scope, compare taxonomy, and stale-preview contract. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - milestone scope and PROM-01/PROM-02 contract. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/REQUIREMENTS.md`]
- `rulestead/lib/rulestead/store.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`, `rulestead/lib/rulestead.ex` - current store/facade/payload patterns. [VERIFIED: `rulestead/lib/rulestead/store.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead/lib/rulestead/fake.ex`][VERIFIED: `rulestead/lib/rulestead.ex`]
- `rulestead_admin/lib/rulestead_admin/live/session.ex`, `rulestead_admin/lib/rulestead_admin/router.ex`, `rulestead_admin/lib/rulestead_admin/components/*.ex` - mounted admin route/state/rendering patterns. [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - `handle_params/3` and `assign_async/3` route/async semantics. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transaction composition semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Secondary (MEDIUM confidence)

- `.planning/research/V0_6_PRODUCT_SHAPE.md` - milestone-level product recommendation for unified flag + environment overlay + compare/apply. [VERIFIED: `.planning/research/V0_6_PRODUCT_SHAPE.md`]
- `prompts/rulestead-admin-ux-and-operator-ia.md`, `prompts/rulestead-security-privacy-and-threat-model.md`, `prompts/rulestead-domain-language-field-guide.md` - operator IA, security boundary, and vocabulary guidance. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`][VERIFIED: `prompts/rulestead-security-privacy-and-threat-model.md`][VERIFIED: `prompts/rulestead-domain-language-field-guide.md`]

### Tertiary (LOW confidence)

- None beyond the single explicit assumption in the Assumptions Log. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 22 can stay inside the existing repo stack with strong local-code evidence and a small number of official framework docs. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Architecture: MEDIUM-HIGH - The repo and locked context strongly constrain the shape, but exact compare-token implementation remains a design choice. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`]
- Pitfalls: MEDIUM - Most pitfalls are directly implied by locked scope and current code, with one explicit assumption about likely coarse-token shortcuts. [VERIFIED: `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`]

**Research date:** 2026-05-18
**Valid until:** 2026-06-17 for repo-local structure; 2026-05-25 for external framework/doc currency.
