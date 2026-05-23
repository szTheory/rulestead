# Phase 36: Archive-Readiness Signals & Cleanup Analysis - Research

**Researched:** 2026-05-23
**Domain:** Lifecycle guidance, archive-readiness projection, mounted-admin reporting, and read-only Mix reporting for Rulestead flags. [VERIFIED: codebase grep] [VERIFIED: repo docs]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 36 remains advisory and read-only. It must improve operator judgment, not automate cleanup.
- **D-02:** Recommendation-heavy output is preferred. Planning should assume one coherent path unless a choice would materially change public contract, security/governance posture, release shape, or package boundaries.
- **D-03:** The system must continue to honor the Phase 35 rule: operators author facts, admin computes guidance.

### Lifecycle facts vs archive-readiness guidance
- **D-04:** Keep authored lifecycle facts and derived archive-readiness guidance as separate axes.
- **D-05:** `archived_at` remains the only hard terminal lifecycle fact. Lifecycle-authored fields such as mode, review horizon, and override provenance remain canonical truth.
- **D-06:** Derived archive-readiness must not replace lifecycle posture and must not be persisted as canonical database truth.
- **D-07:** The current overloading of `lifecycle.state` with freshness semantics should be refactored toward a split model:
  - lifecycle/authored posture
  - freshness/evaluation evidence
  - archive-readiness advisory
- **D-08:** `stale` becomes one evidence signal inside archive-readiness, not the product’s entire cleanup model.

### Advisory model and evidence composition
- **D-09:** Use a bounded **rule-ladder plus evidence-matrix** model, exposed as categories and evidence quality, not a numeric score.
- **D-10:** User-visible numeric readiness scores are disallowed. They create false precision and undermine operator trust.
- **D-11:** Recommended derived guidance shape should include at least:
  - `readiness`
  - `evidence_quality`
  - `reasons`
  - `unknowns`
  - `blockers`
  - `recommended_next_action`
  - bounded secondary actions
- **D-12:** Recommended readiness categories are:
  - `keep_active`
  - `needs_review`
  - `archive_candidate`
- **D-13:** Recommended evidence-quality categories are:
  - `strong`
  - `partial`
  - `weak`
- **D-14:** If internal ordering is needed for sorting, use a hidden ordinal tuple or comparable bounded ranking. Do not expose that rank as a product score.
- **D-15:** Archive-readiness must stay explainable in plain language from the returned reasons and unknowns. Operators should be able to see what signal drove the recommendation without reverse-engineering weights.

### Signal semantics and uncertainty handling
- **D-16:** Distinguish positive evidence, negative evidence, and missing evidence explicitly. Missing data must never quietly count as archive-positive evidence.
- **D-17:** `no code references found from a fresh scan` is positive evidence; `no scan` or `stale scan` is uncertainty.
- **D-18:** Distinguish at least:
  - `recently evaluated`
  - `not evaluated recently`
  - `never evaluated`
  - `evaluation evidence unavailable`
- **D-19:** Evaluation evidence gaps must degrade evidence quality rather than silently helping an archive recommendation.
- **D-20:** Permanent authored posture should strongly resist archive recommendations unless later phases introduce an explicit retirement flow.
- **D-21:** Expiring authored posture lowers the archive-readiness threshold, but it must not override contradictory evidence such as fresh code references or recent evaluations.
- **D-22:** `remote_config` remains the important exception. Its readiness posture must follow authored intent more than type default, and it should require stronger evidence before becoming an archive candidate.
- **D-23:** `kill_switch`, `operational`, and `permission` flags should default toward `keep_active` unless explicit authored lifecycle posture and evidence clearly say otherwise.
- **D-24:** The archive-readiness model must be honest about uncertainty. Recommended UI/CLI language should say “guidance limited by missing evidence” rather than implying certainty.

### Recommendation UX and operator guidance
- **D-25:** Show one **primary recommended next action** plus at most two bounded secondary actions.
- **D-26:** When evidence is conflicting or weak, withhold the primary recommendation and surface a review-oriented message instead of pretending the system knows.
- **D-27:** Recommended next-action vocabulary should stay concrete and advisory, for example:
  - `keep_active`
  - `review_manually`
  - `refresh_code_refs`
  - `collect_eval_evidence`
  - `remove_code_refs`
  - `mark_permanent`
  - `archive_ready`
- **D-28:** Checklists are appropriate only after an action path is chosen. They should support Phase 37 preview/confirm flows, not replace Phase 36 recommendations.
- **D-29:** Mounted-admin copy should preserve the calm “read surface first, explicit action later” posture already used in the detail and cleanup views.

### CLI and reporting surface
- **D-30:** Phase 36 should add a **read-only** lifecycle/cleanup report command. No CLI mutation path ships in this phase.
- **D-31:** The preferred task shape is `mix rulestead.lifecycle`, with default human-readable text output and stable `--format json` output for scripts.
- **D-32:** CLI filter names should mirror mounted-admin vocabulary and URL state as closely as possible, including environment, owner, lifecycle, stale/freshness, and archived inclusion semantics.
- **D-33:** JSON output is the canonical machine contract; text output is a renderer over the same data, not a separate schema.
- **D-34:** The CLI should include a format/schema version field so downstream automation can remain stable as reporting evolves.
- **D-35:** This phase should not introduce `plan/apply` or `cleanup` mutation commands. Those belong in Phase 37 when explicit preview/confirm/audit flows land.

### Architecture and implementation guardrails
- **D-36:** Extend the existing projector seam in `Rulestead.Admin.Lifecycle` or an equivalent adjacent derived-guidance seam. Keep the computation pure and read-model focused.
- **D-37:** Avoid background recompute jobs, trigger-based projection persistence, generated columns, or SQL-heavy rule duplication for archive-readiness in this phase.
- **D-38:** Use bounded enums/atoms and stable reason identifiers so mounted-admin, CLI, and tests can share one coherent vocabulary.
- **D-39:** New public/admin payloads should carry enough explanation for LiveView badges, filters, cleanup screens, and CLI reports without requiring separate recomputation in each surface.

### Ecosystem lessons to incorporate
- **D-40:** Learn from LaunchDarkly’s separation of lifecycle intent, code-removal guidance, and archival checks; do not collapse them into one blunt stale bit.
- **D-41:** Learn from Unleash and Statsig that authored permanence vs temporary posture matters, but do not import their richer SaaS-only stage models wholesale into Rulestead’s bounded library/product shape.
- **D-42:** Avoid the ConfigCat/GrowthBook footgun of over-trusting weak or modified-time-only staleness heuristics.

### the agent's Discretion
- Exact field names for archive-readiness, evidence-quality, reason, and unknown sets
- Exact render shape for admin badges/cards, provided the authored-facts vs derived-guidance split remains explicit
- Exact CLI text layout, provided JSON remains the stable machine contract
- Exact internal sort tuple/rank shape, provided no user-visible score is introduced

### Deferred Ideas (OUT OF SCOPE)
- Explicit archive/cleanup preview, confirmation, reason capture, and audit continuity flows — Phase 37
- Lifecycle workbench ranking, bulk actions, and mutation orchestration beyond read-only review — Phase 37
- Any automatic archival, automatic code removal, or hidden state mutation based on heuristics
- Persisted readiness scores, background recompute pipelines, or SQL-native advisory materialization
- Rich SaaS-style lifecycle stage systems that exceed Rulestead’s mounted sibling-package scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-02 | Rulestead classifies lifecycle state and archive readiness from bounded signals such as flag type, expected lifetime, last evaluation evidence, and code-reference coverage instead of a single blunt stale heuristic. | Use one pure projector payload that separates authored lifecycle posture, freshness evidence, and archive-readiness advisory; derive it once in core/store code and reuse it in LiveView and the new read-only Mix task. [VERIFIED: repo docs] [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: CLAUDE.md]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout; do not collapse work into a single package shape. [VERIFIED: CLAUDE.md]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, `guides/flows/extending-rulestead.md`. [VERIFIED: CLAUDE.md]
- `rulestead_admin` is intentionally a guarded stub until later phases; do not introduce early publish flows that bypass that rule. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes and keep root docs honest about the current phase. [VERIFIED: CLAUDE.md]
- Use scripts-first CI surfaces where workflow logic gets non-trivial. [VERIFIED: CLAUDE.md]

## Summary

Phase 36 should not add a second lifecycle engine. It should replace the current overloaded `lifecycle.state` projection with one richer derived payload that keeps authored posture (`mode`, `review_by`, `archived_at`) separate from freshness evidence (`last_evaluated_at`, recency bucket, code-reference evidence, uncertainty) and archive-readiness advice (`readiness`, `evidence_quality`, `reasons`, `unknowns`, `blockers`, `recommended_next_action`). The existing code already centralizes lifecycle decoration in `Rulestead.Admin.Lifecycle` and decorates list/detail payloads in both the Ecto and Fake adapters, so the standard implementation path is to deepen that seam rather than spread heuristics into LiveViews or a background subsystem. [VERIFIED: codebase grep] [VERIFIED: repo docs]

The main planning risk is not algorithm complexity but signal honesty. Today, the projector still collapses freshness into a single `state`, the store filters equate lifecycle filtering with that same freshness state, and the cleanup view directly archives flags while loading raw code references itself. Meanwhile, code-reference ingestion currently deletes and replaces the entire `code_references` table on every webhook call, and the schema does not store a scan batch or explicit freshness marker. That means Phase 36 can support advisory code-reference evidence, but it must model “no recent scan” as uncertainty instead of inferring “no references.” [VERIFIED: codebase grep]

**Primary recommendation:** Build one shared `archive_readiness` projection in core/store code, keep it read-only, and have mounted-admin plus `mix rulestead.lifecycle` render the same canonical JSON-backed payload. [VERIFIED: repo docs] [VERIFIED: codebase grep] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Archive-readiness classification | API / Backend | Database / Storage | The classifier should remain a pure server-side read-model seam in `Rulestead.Admin.Lifecycle`, fed from authored flag data plus stored evidence, not recomputed in LiveView templates. [VERIFIED: codebase grep] |
| Freshness evidence interpretation | API / Backend | Database / Storage | `last_evaluated_at` and `variants_served` are already persisted on `flag_environments`, so classification logic belongs where those records are assembled. [VERIFIED: codebase grep] |
| Code-reference evidence interpretation | API / Backend | Database / Storage | Code references are persisted in the `code_references` table and uploaded via webhook/CI, so advisory interpretation belongs in the shared server payload. [VERIFIED: codebase grep] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] |
| Mounted-admin filters and badges | Frontend Server (SSR) | API / Backend | LiveViews should consume the shared payload and keep URL state canonical with `handle_params/3` and `push_patch/2`, rather than owning the heuristics. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Read-only lifecycle report CLI | API / Backend | Browser / Client | Mix tasks are the repo-standard operator surface for scripted reporting; they should call the same public/store projection and render text or JSON without adding mutation paths. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] |

## Standard Stack

### Core
| Library / Seam | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Rulestead.Admin.Lifecycle` | current repo seam | Shared derived lifecycle/readiness projector. [VERIFIED: codebase grep] | It is already the single classification seam used by Ecto and Fake payload decoration, so Phase 36 should extend it instead of introducing a second engine. [VERIFIED: codebase grep] |
| `ecto` / `ecto_sql` | locked `3.13.5`; latest `3.14.0` released 2026-05-19. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] | Compose read-model payloads from `flags`, `flag_environments`, and `code_references`. [VERIFIED: codebase grep] | The Ecto store already owns `list_flags/1`, `fetch_flag/1`, and lifecycle decoration, which is the correct place to assemble archive-readiness inputs. [VERIFIED: codebase grep] |
| `phoenix_live_view` | locked `1.1.28`; latest stable `1.1.30` released 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] | Preserve shareable mounted-admin filters and drill-ins through `handle_params/3` and `push_patch/2`. [VERIFIED: codebase grep] | The current admin inventory already uses URL-driven filters, which matches the repo’s operator UX rules and the official LiveView navigation model. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| `Mix.Task` + `OptionParser` | Elixir `1.19.5`. [VERIFIED: exec_command] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] [CITED: https://hexdocs.pm/elixir/OptionParser.html] | Implement `mix rulestead.lifecycle` with text-by-default and canonical JSON output. [VERIFIED: repo docs] | Existing repo tasks already follow the “compute + render + exit code” pattern and `OptionParser.parse/2` conventions, so the new report should reuse that house style. [VERIFIED: codebase grep] |

### Supporting
| Library / Seam | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `telemetry` | locked `1.4.1`; latest `1.4.2` released 2026-05-11. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] | Source of evaluation-stop events that feed freshness persistence. [VERIFIED: codebase grep] | Use it only indirectly through the already-existing tracker/cache path; do not invent new runtime dependencies for Phase 36. [VERIFIED: codebase grep] |
| `Rulestead.Admin.StaleTracker` + `Rulestead.Telemetry.Cache` | current repo seams. [VERIFIED: codebase grep] | Existing bounded evaluation-evidence ingestion. [VERIFIED: codebase grep] | Reuse for recency interpretation; Phase 36 should not change runtime semantics. [VERIFIED: repo docs] |
| `Rulestead.Webhooks.CodeRefsPlug` + `Rulestead.CodeRefs.Scanner` | current repo seams. [VERIFIED: codebase grep] | Existing passive host-side code-reference ingestion. [VERIFIED: codebase grep] | Reuse as advisory evidence only; account for its freshness and coverage limits explicitly. [VERIFIED: codebase grep] |
| `phoenix` / `phoenix_html` | locked `1.8.5` / `4.3.0`; latest `1.8.7` / `4.3.0`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] | Mounted-admin rendering primitives. [VERIFIED: mix.lock] | Only use for consuming the shared payload and rendering calm read surfaces; keep archive-readiness logic out of templates. [VERIFIED: repo docs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared projector payload | LiveView-specific computation | Rejected because it would duplicate rules across list/detail/cleanup and break the repo’s “operators author facts, admin computes guidance” boundary. [VERIFIED: repo docs] [VERIFIED: codebase grep] |
| Read-time projection | Persisted readiness columns / generated scores | Rejected because Phase 36 explicitly disallows persisted computed readiness truth and user-visible scoring. [VERIFIED: repo docs] |
| Rule ladder + evidence matrix | Numeric score | Rejected because the phase locks explainability and bounded categories over false precision. [VERIFIED: repo docs] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] |
| Read-only Mix report | Mutation-capable cleanup task | Rejected because CLI mutation paths are deferred to Phase 37. [VERIFIED: repo docs] |

**Installation:**
```bash
cd rulestead && mix deps.get
cd ../rulestead_admin && mix deps.get
```

**Version verification:** Repo-pinned versions were verified from `mix.lock`, and current registry releases were verified with `mix hex.info` on 2026-05-23. [VERIFIED: mix.lock] [VERIFIED: mix hex.info]

## Architecture Patterns

### System Architecture Diagram

```text
Host CI / local scan
  -> mix rulestead.code_refs
  -> /api/webhooks/rulestead/code_refs
  -> code_references table

Runtime evaluations
  -> [:rulestead, :eval, :decide, :stop]
  -> Rulestead.Admin.StaleTracker
  -> record_evaluation/3
  -> flag_environments.last_evaluated_at + variants_served

Authored flag metadata
  -> flags.lifecycle / flags.ownership / archived_at

flags + flag_environments + code_references
  -> Rulestead.Admin.Lifecycle.classify(...)
  -> archive_readiness projection
     -> readiness
     -> evidence_quality
     -> reasons / unknowns / blockers
     -> recommended_next_action

archive_readiness projection
  -> Rulestead.list_flags/1 + fetch_flag/2 payloads
  -> mounted-admin badges, filters, cleanup read surface
  -> mix rulestead.lifecycle text renderer
  -> mix rulestead.lifecycle --format json
```

This matches the existing project architecture: evidence is stored as authored state plus bounded passive signals, classification is pure server-side projection, and UI/CLI are read-only renderers over that projection. [VERIFIED: codebase grep] [VERIFIED: repo docs]

### Recommended Project Structure
```text
rulestead/lib/
├── rulestead/admin/           # shared lifecycle + archive-readiness projection seam
├── rulestead/store/           # Ecto/Fake payload decoration and filtering
└── mix/tasks/                 # read-only lifecycle report task + renderer

rulestead_admin/lib/
├── rulestead_admin/live/flag_live/   # URL-driven list/detail/cleanup read surfaces
└── rulestead_admin/components/       # badges/cards consuming shared projection vocab
```

### Pattern 1: Split Authored Posture From Derived Readiness
**What:** Keep authored lifecycle facts (`mode`, `review_by`, `archived_at`) separate from freshness evidence and from archive-readiness advice. [VERIFIED: repo docs]
**When to use:** Everywhere a flag is listed or shown in detail, and especially in filters, badges, CLI JSON, and cleanup review screens. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: rulestead/lib/rulestead/admin/lifecycle.ex + Phase 36 context
%{
  lifecycle: %{
    authored_mode: :expiring,
    review_by: ~D[2026-06-01],
    archived?: false
  },
  freshness: %{
    state: :not_evaluated_recently,
    last_evaluated_at: ~U[2026-05-01 12:00:00Z]
  },
  archive_readiness: %{
    readiness: :needs_review,
    evidence_quality: :partial,
    reasons: [:review_horizon_elapsed],
    unknowns: [:code_refs_scan_stale],
    blockers: [],
    recommended_next_action: :refresh_code_refs
  }
}
```

### Pattern 2: Compute Once, Render Everywhere
**What:** Assemble archive-readiness in the shared payload decorator so Ecto, Fake, LiveView, and the new Mix task all consume the same vocabulary. [VERIFIED: codebase grep]
**When to use:** For list filtering, detail cards, cleanup advisory copy, CLI rows, and JSON output. [VERIFIED: repo docs]
**Example:**
```elixir
# Source: rulestead/lib/rulestead/store/ecto.ex
payload
|> Map.put(:lifecycle, lifecycle(flag, flag_environment))
|> Map.put(:archive_readiness, archive_readiness(flag, flag_environment, code_refs))
```

### Pattern 3: Canonical URL / CLI Filter Vocabulary
**What:** Keep mounted-admin query params and CLI switches aligned so operators can move between UI and shell without learning two taxonomies. [VERIFIED: repo docs]
**When to use:** `env`, `owner`, `lifecycle`, `stale`, `include_archived`, and any new `readiness` or `evidence_quality` filters. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
def handle_params(params, uri, socket) do
  filters = normalize_filters(Map.merge(query_params(uri), params), current_env)
  {:noreply, push_patch(socket, to: build_index_path(base_path, filters))}
end
```

### Anti-Patterns to Avoid
- **Overloading `lifecycle.state` again:** The current classifier returns `:active | :potentially_stale | :stale | :archived`, which mixes posture and freshness; Phase 36 should split that instead of renaming the same coupling. [VERIFIED: codebase grep]
- **Treating “no refs found” as “fresh scan found no refs”:** The current schema stores per-reference rows only, with no scan batch or explicit freshness record. [VERIFIED: codebase grep]
- **Computing readiness in LiveViews:** The list/detail pages already consume decorated payloads; duplicating rules there would create Ecto/Fake/UI drift. [VERIFIED: codebase grep]
- **Sneaking in cleanup mutation UX:** The context locks this phase to advisory/read-only output, while the current cleanup view already archives flags directly. Planning must not widen that surface further. [VERIFIED: repo docs] [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Readiness ranking | Numeric weighted scoring engine | Bounded rule ladder + evidence matrix | The phase explicitly bans user-visible scores and requires explainable reasons. [VERIFIED: repo docs] |
| Per-surface heuristics | Separate readiness logic in list/detail/CLI | Shared core/store projector payload | Duplication would create filter drift and inconsistent operator advice. [VERIFIED: codebase grep] |
| Background recompute system | Oban/DB-trigger readiness materializer | Read-time pure projection | The context explicitly rejects background recompute and persisted derived truth. [VERIFIED: repo docs] |
| Custom CLI contract | One-off text parsing format | Canonical JSON envelope plus text renderer | Existing Mix tasks already compute a result envelope, render text/json, and use stable exit codes. [VERIFIED: codebase grep] |
| Freshness certainty from weak inputs | “No refs == safe” heuristic | Explicit uncertainty buckets | LaunchDarkly separates staleness from archive/code-removal checks, and the local code-ref model lacks scan freshness truth. [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] [VERIFIED: codebase grep] |

**Key insight:** The difficult part in this domain is not calculating a recommendation; it is preserving operator trust when evidence is partial, stale, or contradictory. The winning implementation path is bounded vocabulary plus explicit uncertainty, not more automation. [VERIFIED: repo docs] [CITED: https://docs.statsig.com/feature-flags/permanent-and-stale-gates] [CITED: https://docs.getunleash.io/concepts/feature-flags]

## Common Pitfalls

### Pitfall 1: Ambiguous “No Code References”
**What goes wrong:** The product says a flag is ready for archive because the table has no rows, even though no recent scan has run. [VERIFIED: codebase grep]
**Why it happens:** `code_references` stores rows only, and the webhook does a global delete-and-replace with no explicit scan ledger. [VERIFIED: codebase grep]
**How to avoid:** Model code-reference evidence as at least `fresh_refs_present`, `fresh_refs_absent`, or `scan_unknown_or_stale`; degrade evidence quality when freshness cannot be proven. [VERIFIED: repo docs] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references]
**Warning signs:** Empty reference list plus no accompanying scan timestamp or freshness reason in the payload. [VERIFIED: codebase grep]

### Pitfall 2: Lifecycle and Freshness Filter Drift
**What goes wrong:** Admin filters still treat lifecycle and stale state as the same dimension, so “Lifecycle: active” silently means “not stale yet.” [VERIFIED: codebase grep]
**Why it happens:** `maybe_filter_lifecycle/2` and `maybe_filter_stale/2` both currently dispatch off `entry.lifecycle.state`. [VERIFIED: codebase grep]
**How to avoid:** Add distinct payload fields and distinct filter handling for authored lifecycle posture, freshness, and archive readiness. [VERIFIED: repo docs]
**Warning signs:** The same atom list drives both lifecycle badges and stale filters. [VERIFIED: codebase grep]

### Pitfall 3: Permanent Flags Accidentally Nudge Toward Archive
**What goes wrong:** Kill switches, permission flags, operational toggles, or remote config settings get cleanup recommendations because they look old or quiet. [VERIFIED: repo docs]
**Why it happens:** Pure recency heuristics ignore authored permanence or product intent. [CITED: https://docs.statsig.com/feature-flags/permanent-and-stale-gates] [CITED: https://docs.getunleash.io/concepts/feature-flags]
**How to avoid:** Let permanent posture strongly resist archive readiness, and require stronger evidence for `remote_config` than for short-lived release/experiment flags. [VERIFIED: repo docs]
**Warning signs:** A recommendation appears without citing posture, flag type, or contradictory evidence. [VERIFIED: repo docs]

### Pitfall 4: Mutation Creep on the Cleanup Screen
**What goes wrong:** Phase 36 turns the cleanup page into a more opinionated archive executor instead of a read surface. [VERIFIED: codebase grep]
**Why it happens:** The existing cleanup LiveView already loads code refs and directly calls `Rulestead.archive_flag/1`. [VERIFIED: codebase grep]
**How to avoid:** Keep Phase 36 focused on richer read payloads, copy, and filters; defer new archive/confirm flows to Phase 37. [VERIFIED: repo docs]
**Warning signs:** New buttons, bulk actions, or CLI `apply` flags appear in a Phase 36 plan. [VERIFIED: repo docs]

### Pitfall 5: Over-trusting Limited Code Scanning
**What goes wrong:** Indirect flag usage is missed, and readiness advice is overconfident. [VERIFIED: codebase grep]
**Why it happens:** The current scanner only matches direct `Rulestead.evaluate(...)` calls with literal binary flag keys. [VERIFIED: codebase grep]
**How to avoid:** Surface scanner limits as `unknowns`, and keep “remove_code_refs” advisory rather than authoritative. [VERIFIED: codebase grep] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references]
**Warning signs:** Flags referenced through wrappers, aliases, or variables never appear in `code_references`. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and current repo seams:

### URL-Driven Filter State in Mounted Admin
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
def handle_params(params, uri, socket) do
  merged = Map.merge(query_params(uri), params)
  filters = normalize_filters(merged, current_environment)

  {:noreply, push_patch(socket, to: build_index_path(base_path, filters))}
end
```

### Read-Only Mix Task Skeleton
```elixir
# Source: https://hexdocs.pm/mix/main/Mix.Task.html
# Source: https://hexdocs.pm/elixir/OptionParser.html
defmodule Mix.Tasks.Rulestead.Lifecycle do
  use Mix.Task

  @switches [environment: :string, owner: :string, format: :string, include_archived: :boolean]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate_args!(opts, argv, invalid)
    result = compute(opts)
    emit(result, Keyword.get(opts, :format, "text"))
  end
end
```

### Shared Projection Decoration
```elixir
# Source: rulestead/lib/rulestead/store/ecto.ex
payload
|> Map.put(:lifecycle, lifecycle(flag, flag_environment))
|> Map.put(:archive_readiness, archive_readiness(flag, flag_environment, code_ref_evidence))
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single stale bit as the cleanup model | Separate lifecycle intent, stale/freshness, and code-removal/archive checks | Current LaunchDarkly docs and current Phase 36 context. [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] [VERIFIED: repo docs] | Rulestead should expose bounded evidence and recommendations, not rename the existing `stale` atom. [VERIFIED: repo docs] |
| Type-driven default lifetime only | Type-informed lifecycle plus usage/lifecycle stages and archive suggestions | Current Unleash docs (updated May 19, 2026). [CITED: https://docs.getunleash.io/concepts/feature-flags] | Strong fit for Rulestead’s authored posture plus derived guidance split, but only the bounded parts should be imported. [VERIFIED: repo docs] |
| Temporary vs permanent only | Permanent posture plus stale cleanup nudges and caution before archive | Current Statsig docs. [CITED: https://docs.statsig.com/feature-flags/permanent-and-stale-gates] | Supports the Phase 36 requirement that permanent/operational flags resist archive advice. [VERIFIED: repo docs] |
| Manual stale reports | Email/API-backed stale or zombie reports | ConfigCat 2025 article. [CITED: https://configcat.com/blog/identify-and-remove-zombie-flags-in-configcat/] | Validates adding a read-only report surface and stable machine-readable output. [VERIFIED: repo docs] |

**Deprecated/outdated:**
- Treating `lifecycle.state` as both authored lifecycle and freshness status is now the outdated local approach; it already conflicts with the locked Phase 36 split model. [VERIFIED: repo docs] [VERIFIED: codebase grep]
- Treating code-reference absence as a complete signal is outdated for mature flag tooling; LaunchDarkly explicitly separates staleness from archive/code-removal checks. [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references]

## Assumptions Log

All material claims in this research were verified against the codebase, repo docs, runtime environment, or current official docs. No `[ASSUMED]` claims remain. [VERIFIED: codebase grep]

## Open Questions

1. **How should Phase 36 prove code-reference scan freshness?**
   - What we know: the current webhook deletes and replaces all code-reference rows, and the schema stores no explicit scan batch or scan status row. [VERIFIED: codebase grep]
   - What's unclear: whether Phase 36 should infer freshness from row timestamps alone, add a lightweight scan metadata record, or withhold “fresh scan found no refs” until a later phase. [VERIFIED: codebase grep]
   - Recommendation: plan a bounded freshness marker in the read model or persistence layer if needed for honesty, but do not invent a crawler or background subsystem. [VERIFIED: repo docs]

2. **Should the current cleanup LiveView be softened into a read surface in Phase 36 or only supplemented?**
   - What we know: the existing page directly archives flags today, which exceeds the new phase’s advisory-only posture. [VERIFIED: codebase grep]
   - What's unclear: whether the plan should temporarily narrow that surface in Phase 36 or simply avoid touching its mutation path until Phase 37. [VERIFIED: codebase grep]
   - Recommendation: keep Phase 36 scoped to projection/reporting improvements and avoid adding any new mutation behavior; only narrow the page if needed to keep the public/admin contract honest. [VERIFIED: repo docs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix task implementation and tests | ✓ | `1.19.5` | — |
| Mix | `mix rulestead.lifecycle` and ExUnit | ✓ | `1.19.5` | — |
| PostgreSQL | Ecto adapter path and code-reference persistence/tests | ✓ | `psql 14.17`, `pg_isready` OK | Fake store for non-DB unit tests |
| Redis | Not required for this phase’s read-model implementation | ✓ | `redis-cli PONG` | Phase can proceed without Redis-specific work |

**Missing dependencies with no fallback:**
- None. [VERIFIED: exec_command]

**Missing dependencies with fallback:**
- None. [VERIFIED: exec_command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit in both sibling packages. [VERIFIED: codebase grep] |
| Config file | `rulestead/test/test_helper.exs`; `rulestead_admin/test/test_helper.exs`; `rulestead/config/test.exs`; admin package uses test helper setup without a separate `config/test.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/webhooks/code_refs_plug_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIF-02 | Classify archive-readiness from authored posture, evaluation evidence, code-reference evidence, and uncertainty without a blunt stale-only heuristic. | unit + integration + LiveView + Mix task | `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/webhooks/code_refs_plug_test.exs` and `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs` | ✅ existing surfaces, but readiness-specific cases are missing |

### Sampling Rate
- **Per task commit:** run the quick targeted suite above. [VERIFIED: codebase grep]
- **Per wave merge:** run `cd rulestead && mix test && cd ../rulestead_admin && mix test`. [VERIFIED: codebase grep]
- **Phase gate:** full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps
- [ ] `rulestead/test/rulestead/admin_lifecycle_test.exs` needs new coverage for split freshness buckets, evidence quality, blockers, and recommendation withholding. [VERIFIED: codebase grep]
- [ ] `rulestead/test/rulestead/store_ecto_admin_test.exs` needs list/detail assertions for distinct lifecycle vs stale vs readiness filters and payload fields. [VERIFIED: codebase grep]
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` needs assertions for new readiness/evidence badges and URL state. [VERIFIED: codebase grep]
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` needs assertions for reasons, unknowns, blockers, and next-action copy. [VERIFIED: codebase grep]
- [ ] `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` does not exist and should be created for text/json contract coverage and exit-code semantics. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host application owns authentication; Rulestead consumes session/context only. [VERIFIED: repo docs] |
| V3 Session Management | no | Host application owns sessions; mounted admin must stay inside host session policy. [VERIFIED: repo docs] |
| V4 Access Control | yes | Preserve `Rulestead.Admin.Policy` as the authorization seam and keep Phase 36 read-only. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
| V5 Input Validation | yes | Keep CLI input parsing bounded through `OptionParser` and webhook/code-ref payload validation bounded through existing changeset/plug checks. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| V6 Cryptography | no | This phase does not add new cryptographic requirements; existing webhook auth token handling remains unchanged. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overconfident cleanup guidance causes unsafe archival decisions | Tampering / DoS | Expose uncertainty explicitly, withhold recommendations on weak/conflicting evidence, and keep archive actions out of Phase 36. [VERIFIED: repo docs] |
| Unauthorized lifecycle/archive visibility expansion | Information Disclosure | Continue mounted-admin policy gating and avoid new direct DB reads from UI-specific code when a shared payload can enforce policy boundaries. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
| Malformed CLI or webhook inputs create misleading evidence | Tampering | Use strict `OptionParser` switches and existing webhook shape validation; reject invalid inputs rather than defaulting silently. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/elixir/OptionParser.html] |

## Sources

### Primary (HIGH confidence)
- Local codebase seams:
  - `rulestead/lib/rulestead/admin/lifecycle.ex` - current lifecycle classifier shape and freshness coupling. [VERIFIED: codebase grep]
  - `rulestead/lib/rulestead/store/ecto.ex` and `rulestead/lib/rulestead/fake.ex` - payload decoration, list/detail filtering, and adapter parity seams. [VERIFIED: codebase grep]
  - `rulestead/lib/rulestead/webhooks/code_refs_plug.ex`, `rulestead/lib/rulestead/code_refs/scanner.ex`, `rulestead/priv/repo/migrations/20260516193701_create_rulestead_code_references.exs` - code-reference ingestion model and its limits. [VERIFIED: codebase grep]
  - `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`, `show.ex`, `cleanup.ex` - current mounted-admin consumers and mutation boundary. [VERIFIED: codebase grep]
- Project planning/docs:
  - `.planning/phases/36-archive-readiness-signals-cleanup-analysis/36-CONTEXT.md` - locked scope and decision set. [VERIFIED: repo docs]
  - `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - requirement mapping and milestone constraints. [VERIFIED: repo docs]
  - `prompts/rulestead-*.md` security/admin/integration/telemetry anchors - product posture and operator UX rules. [VERIFIED: repo docs]
- Official docs:
  - https://launchdarkly.com/docs/eu-docs/home/flags/code-references - code references, archive checks, and separation from stale detection. [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references]
  - https://docs.getunleash.io/concepts/feature-flags - expected lifetimes, stale states, lifecycle stages, and archive suggestions. [CITED: https://docs.getunleash.io/concepts/feature-flags]
  - https://docs.statsig.com/feature-flags/permanent-and-stale-gates - permanent vs stale gate semantics. [CITED: https://docs.statsig.com/feature-flags/permanent-and-stale-gates]
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html - `handle_params/3` and `push_patch/2`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
  - https://hexdocs.pm/mix/main/Mix.Task.html - Mix task behavior conventions. [CITED: https://hexdocs.pm/mix/main/Mix.Task.html]
  - https://hexdocs.pm/elixir/OptionParser.html - strict option parsing rules. [CITED: https://hexdocs.pm/elixir/OptionParser.html]

### Secondary (MEDIUM confidence)
- https://configcat.com/blog/identify-and-remove-zombie-flags-in-configcat/ - current read-only stale/zombie reporting patterns. [CITED: https://configcat.com/blog/identify-and-remove-zombie-flags-in-configcat/]

### Tertiary (LOW confidence)
- https://www.growthbook.io/blog/stale-feature-flag-detection - ecosystem corroboration for stale-detection/reporting as a first-class operator workflow; useful for direction, not for locked contract details. [CITED: https://www.growthbook.io/blog/stale-feature-flag-detection]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase can stay inside existing repo seams, and dependency/runtime facts were verified locally. [VERIFIED: codebase grep] [VERIFIED: mix.lock] [VERIFIED: mix hex.info] [VERIFIED: exec_command]
- Architecture: HIGH - the Phase 36 context is unusually specific, and the current code already reveals the exact seams to extend. [VERIFIED: repo docs] [VERIFIED: codebase grep]
- Pitfalls: HIGH - the main risks are directly visible in current code and corroborated by official ecosystem docs. [VERIFIED: codebase grep] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] [CITED: https://docs.getunleash.io/concepts/feature-flags] [CITED: https://docs.statsig.com/feature-flags/permanent-and-stale-gates]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 for repo-specific seams; re-check official product docs sooner if the phase slips, because feature-flag vendor guidance changes faster than the local codebase. [VERIFIED: repo docs] [CITED: https://launchdarkly.com/docs/eu-docs/home/flags/code-references] [CITED: https://docs.getunleash.io/concepts/feature-flags]
