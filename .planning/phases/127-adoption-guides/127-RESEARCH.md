# Phase 127: Adoption Guides - Research

**Researched:** 2026-06-18
**Domain:** Adopter documentation authoring (ExDoc extras) for an Elixir/Phoenix feature-flag library — NO runtime code
**Confidence:** HIGH (all seams verified against current-branch source; CI guards read line-by-line)

## Summary

Phase 127 authors two new adopter docs — `guides/recipes/troubleshooting.md` (GUIDE-01: 7 symptom-indexed patterns) and `guides/recipes/integrations-cookbook.md` (GUIDE-02: 4 persona/JTBD recipes) — and wires both into the EXISTING "Recipes" extras group in `rulestead/mix.exs` (GUIDE-03). This is pure documentation: no module, function, mix task, telemetry event, or config key may be invented. Every reference must resolve to a symbol that exists on the current branch AND is in the locked 1.x public surface (`guides/api_stability.md`).

The single highest-risk dimension is **seam legitimacy**: several "obvious" APIs a recipe author would reach for are NOT in the locked catalog even though they exist in source. Specifically — the change-request functions (`submit_change_request/1`, `approve_change_request/1`, …) carry `@doc`+`@spec` and will render/autolink, but are **absent from the `api_stability.md` Rulestead function catalog**; `Rulestead.Store.Redis` is `@moduledoc false` and not a stable module; `mix rulestead.promote` and `mix rulestead.redis.sync` are `@moduledoc false`. The recipes that touch promotion, Redis-staleness, and change-request blocks must therefore route through PUBLIC seams (telemetry events, the root facade's catalog functions, `mix rulestead.lifecycle`, governance behaviour callbacks) rather than naming the non-public internals.

The second-highest risk is the **version-truth CI guard** (`scripts/check_version_truth.py`, run by `scripts/ci/lint.sh`). It recursively scans `guides/**/*.md`, so BOTH new files are in scope. It hard-fails on `0.1.x`, `0.1.7`, `future…1.0`, `1.0 API freeze`, `Two version lines`, and a bare `~> 0.1`. Existing recipes still say `v0.1.0` in body prose; the new files must use `1.x` / `~> 1.0` to be both truthful and guard-safe. `mix docs --warnings-as-errors` is also in the lint lane — undefined-reference and broken-autolink warnings are release-blocking.

**Primary recommendation:** Author both files using ONLY the symbols enumerated in the "Verified Public Seams" table below; cross-link `footguns.md` for the "why" (do not restate it); match the existing recipes' Title-Case `##` headings, ` ```elixir ` fences, and relative-link style; wire the two extras in `mix.exs` with cookbook EARLY and troubleshooting LAST in the recipes block of the `extras:` list; then run `cd rulestead && mix docs --warnings-as-errors` and `python3 scripts/check_version_truth.py` as the green-light gate.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Troubleshooting reference (7 patterns) | Docs / ExDoc extra | — | Markdown under `guides/recipes/`; auto-joins Recipes group via regex |
| Integrations cookbook (4 recipes) | Docs / ExDoc extra | — | Same; new fixed template, existing conventions |
| Extras wiring + ordering | Build config (`rulestead/mix.exs`) | — | `extras:` list order = sidebar order; `groups_for_extras` regex = group membership |
| Seam-truth enforcement | CI guards (`scripts/ci/lint.sh`) | `api_stability.md` | `mix docs --warnings-as-errors` + `check_version_truth.py` gate the docs |

## Standard Stack

This is a docs phase — there is no package to install. The "stack" is the toolchain that VALIDATES the docs.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| ExDoc | (already a dep of `rulestead`) | Renders `extras:` + autolinks module/function refs | The HexDocs front door; `mix docs --warnings-as-errors` is the gate `[VERIFIED: scripts/ci/lint.sh:36]` |
| `mix docs --warnings-as-errors` | mix | Fails on undefined-reference / broken autolink | Release gate per API-02 `[VERIFIED: scripts/ci/lint.sh:36]` |
| `scripts/check_version_truth.py` | python3 | Bans stale pre-1.0 version language in `guides/**` | Run by lint.sh `[VERIFIED: scripts/ci/lint.sh:71]` |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `mix format --check-formatted` | Formats `.exs` snippets only — markdown is NOT formatted by mix | N/A for `.md`, but code fences should be valid Elixir |
| `mix credo --strict` | Lints `lib/` — does not touch guides | Won't affect docs |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New extras group for recipes | Reuse existing "Recipes" group | GUIDE-03 mandates NO new group — reuse only |
| Absolute `file://`-style links with `:line` | Relative `.md` links + backtick autolinks | Existing recipes mix both; prefer relative links + backtick autolinks for portability (see Conventions) |

**Installation:** None — documentation phase, no dependency changes.

## Package Legitimacy Audit

> Not applicable. This phase installs zero external packages. The analogous gate here is **seam legitimacy** (below) — verifying that every module/function/task/event referenced in the docs exists AND is public. That gate is satisfied in the "Verified Public Seams" and "Non-Public / Landmine Seams" sections.

## Verified Public Seams (the load-bearing reference table)

Every symbol below was confirmed in current-branch source AND checked against `guides/api_stability.md`. Recipes may use these freely.

| Seam | Kind | Verified at | Public in api_stability.md? |
|------|------|-------------|------------------------------|
| `Rulestead.Runtime.enabled?/3` | fn | `rulestead/lib/rulestead/runtime.ex:108` | YES (Runtime catalog) |
| `Rulestead.Runtime.evaluate/3` | fn | `runtime.ex:60` | YES |
| `Rulestead.Runtime.get_value/4` | fn | `runtime.ex:131` | YES |
| `Rulestead.Runtime.get_variant/3` | fn | `runtime.ex:153` | YES |
| `Rulestead.Runtime.explain/3` | fn | `runtime.ex:173` | YES |
| `Rulestead.Runtime.diagnostics/1` | fn | `runtime.ex:192` | YES — returns `%{node, environments, infrastructure_health}` `[VERIFIED: runtime/diagnostics.ex:8]` |
| `Rulestead.evaluate/3`, `evaluate/2` | fn | `lib/rulestead.ex` | YES (root catalog) |
| `%Rulestead.Context{}` + `Context.new/1`, `normalize/1` | struct/fn | api_stability.md:198-212 | YES |
| `%Rulestead.Result{}` (`:reason` atoms incl. `:targeting_key_missing`, `:flag_off`) | struct | api_stability.md:214-237 | YES |
| `%Rulestead.Error{}` (`:type` incl. `:unauthorized`, `:kill_switch_active`, `:missing_targeting_key`) | struct | api_stability.md:269-289 | YES |
| `Rulestead.Plug` | module | `lib/rulestead/plug.ex` | seam shown in context-propagation.md; config-driven |
| `Rulestead.Phoenix.context_from_conn/2` | fn | `phoenix.ex:42` | shown in existing recipe |
| `Rulestead.LiveView.assign_flags/3`, `context_from_socket/2` | fn | `live_view.ex:38,27` | shown in existing recipe |
| `Rulestead.Oban.Middleware.attach/2` | fn | `lib/rulestead/oban/middleware.ex` | shown in oban recipe |
| `Rulestead.Oban.Worker` (`use` + `rulestead_context/1`) | macro | `lib/rulestead/oban/worker.ex` | shown in oban recipe |
| `Rulestead.Telemetry.attach_many/4` + helpers | fn | api_stability.md:176-186 | YES |
| Telemetry events `[:rulestead, :eval, :decide, :stop]`, `[:rulestead, :runtime, :cache, :stale_used]`, `…:miss`, `…:refresh`, `[:rulestead, :store, :write, :stop]`, `[:rulestead, :admin, :mutation, :stop]` | events | api_stability.md:371-387 | YES (full catalog) |
| Telemetry metadata keys (`:flag_key`, `:environment`, `:reason`, `:has_targeting_key?`, `:cache_age_ms`, …) | keys | api_stability.md:391-406 | YES |
| `Rulestead.Admin.Policy` `c:can?/4`, `c:change_request_required?/4`, `c:allow_self_approval?/4` | callbacks | `lib/rulestead/admin/policy.ex:205,221,238` | YES (api_stability.md:319-339) |
| `Rulestead.Admin.Policy.governance_actions/0` + role catalogs | fn | policy.ex | YES |
| `mix rulestead.install` (`--repo`, `--yes`, `--prefix`, `--create_schema`) | task | `lib/mix/tasks/rulestead.install.ex` — `@moduledoc` present | YES (installer is in-scope per product-boundary.md:18) |
| `mix ecto.migrate` | task | host-owned Ecto | standard Ecto |
| `mix rulestead.lifecycle` (text + JSON) | task | `lib/mix/tasks/rulestead.lifecycle.ex` | YES — named public lifecycle seam (api_stability.md:347) |
| `Rulestead.Store` behaviour + `Rulestead.Store.Ecto` | module | `lib/rulestead/store/ecto.ex` (`@moduledoc` present) | Store behaviour YES; Ecto adapter in groups_for_modules |
| `Rulestead.TestHelpers` (`with_flag/3`, `put_flag/3`, `seed_bucket/3`, …) | fn | api_stability.md:97-108 | YES |
| `config :rulestead, :host` keys (`:oban`, `:plug`, `:live_view`, `:runtime`, `:environment_key`, `:tenancy`) | config | api_stability.md:412-451 | YES (closed schema) |

## Non-Public / Landmine Seams (DO NOT name these as public API in recipes)

These exist in source and may even render in HexDocs, but they are NOT in the locked 1.x catalog. Using them as the recipe's headline seam would violate "uses only shipped public seams."

| Seam | Status | Verified at | Recipe consequence |
|------|--------|-------------|--------------------|
| `Rulestead.submit_change_request/1`, `approve_change_request/1`, `reject_change_request/1`, `cancel_change_request/1` | `@doc`+`@spec` present, RENDERS, but **NOT in api_stability.md root catalog** | `lib/rulestead.ex:380-410`; catalog at api_stability.md:110-170 has no CR entry | The "change-request block" troubleshooting pattern and "staging→prod CR promotion" recipe must frame CR behaviour through the **governance flow** (`Rulestead.Admin.Policy.change_request_required?/4` callback + the `[:rulestead, :admin, :mutation, :stop]` telemetry event + `%Rulestead.Error{type: :unauthorized}`), and may MENTION these functions as the host-app entry points — but must not present them as semver-stable. **Flag for planner: confirm with maintainer whether CR functions are intentionally public-but-uncataloged or should be treated as advisory.** `[ASSUMED]` they are usable-but-uncataloged. |
| `Rulestead.Store.Redis` | `@moduledoc false`; NOT in api_stability stable module list | `lib/rulestead/store/redis.ex:2` | The "OpenFeature/Redis stale" pattern must NOT name `Rulestead.Store.Redis` as a public module. Use the PUBLIC `[:rulestead, :runtime, :cache, :stale_used]` / `:miss` / `:refresh` telemetry events and `mix rulestead.redis.sync` as the observable surface. (`Store.Redis` IS in mix.exs `groups_for_modules` "Store Adapters", so it renders — but the stability promise is the `Rulestead.Store` BEHAVIOUR, not the adapter internals.) |
| `mix rulestead.redis.sync` | `@moduledoc false`, `@shortdoc` present ("Seeds Redis with the latest runtime snapshots from Ecto") | `lib/mix/tasks/rulestead.redis.sync.ex:3,12` | May be referenced as an OPERATIONAL task (it has a `@shortdoc`), but note it is not `@moduledoc`-documented. Prefer describing the OUTCOME (snapshot freshness) over deep task internals. |
| `mix rulestead.promote` | `@moduledoc false`, `@shortdoc` "Previews or applies environment promotion through a saved plan artifact" | `lib/mix/tasks/rulestead.promote.ex:3,9` | The "staging→prod CR promotion" recipe may reference `mix rulestead.promote` as the promotion entry point (in-scope per product-boundary.md:15 "Promotion / GitOps") but should lean on the promote→CR→audit FLOW, not internal task flags. |
| `Rulestead.Store.Command.*` (e.g. `ApplyAudienceMutation`, `SubmitChangeRequest`) | structs exist; **zero mentions in api_stability.md** | `rulestead/lib/rulestead/store/command.ex` | Recipes must build mutations via the root facade's **map/keyword form** (e.g. `Rulestead.apply_audience_mutation(attrs, opts)` accepts a map — `lib/rulestead.ex:964`), NOT by naming `Rulestead.Store.Command.ApplyAudienceMutation`. |
| `Rulestead.Runtime.Cache/Snapshot/*`, `Rulestead.Runtime.Diagnostics` internal | explicitly NOT public (api_stability.md:94, :502) | `runtime/diagnostics.ex:2` is `@moduledoc false` | "Snapshot boot race" pattern uses `Rulestead.Runtime.diagnostics/1` (public) + supervision/refresh prose from `deployment.md` — never the internal cache modules. |
| `Rulestead.Telemetry.dispatch/4` | visible but explicitly non-public (api_stability.md:521) | — | Do not reference. |

## The 7 Troubleshooting Patterns → Seam Map (GUIDE-01)

Each in **Symptom → Cause → Fix → Verify** form. "Verify" should reference a PUBLIC observable (a telemetry event, a `Rulestead.Runtime.diagnostics/1` field, a `Result.reason`, or a mix task output).

| # | Topic | Public seams to use | footguns.md overlap → cross-link, don't duplicate |
|---|-------|---------------------|----------------------------------------------------|
| 1 | install / migration | `mix rulestead.install`, `mix ecto.migrate`; `%Rulestead.Error{type: :repo_not_configured \| :store_not_configured}` | none — net-new content |
| 2 | payload-vs-keyed runtime | `Rulestead.evaluate/3` (payload) vs `Rulestead.Runtime.enabled?/3` (keyed) | **strong overlap** — footguns.md:21-30 "Payload-first vs keyed runtime confusion" (incl. the `Rulestead.enabled?("flag_key", conn)` anti-call). Cross-link `[footguns](footguns.md#payload-first-vs-keyed-runtime-confusion)`; troubleshooting gives the symptom-first FIX path, footguns gives the WHY |
| 3 | snapshot boot race | `Rulestead.Runtime.diagnostics/1` (`infrastructure_health`, `environments`); supervision/refresh prose; `%Rulestead.Error{type: :snapshot_not_found}` | **overlap** — footguns.md:53-56 "Snapshot cache before readiness". Cross-link; reference `deployment.md` "Start with degraded-mode expectations" |
| 4 | context propagation | `Rulestead.Plug`, `Rulestead.Phoenix.context_from_conn/2`, `Rulestead.LiveView.assign_flags/3`, `Rulestead.Oban.Middleware.attach/2`; `%Rulestead.Context{targeting_key:}`; `Result.reason == :targeting_key_missing` | **overlap** — footguns.md:5-11 "Missing or unstable targeting_key". Cross-link; point to existing `context-propagation.md` recipe |
| 5 | RBAC 403 | `Rulestead.Admin.Policy.can?/4`, role catalogs (`viewer_actions/0`…); `%Rulestead.Error{domain: :auth, type: :unauthorized, plug_status:}` | none direct — host owns auth (product-boundary.md:38) |
| 6 | change-request block | `Rulestead.Admin.Policy.change_request_required?/4` callback; `[:rulestead, :admin, :mutation, :stop]` event; CR-required outcome surfaces as a blocked mutation | none — but see Landmine note: do NOT present `submit_change_request/1` as a stable catalog symbol |
| 7 | OpenFeature / Redis stale | `[:rulestead, :runtime, :cache, :stale_used]` / `:miss` / `:refresh` events; `mix rulestead.redis.sync` (snapshot freshness); `Result.cache_age_ms`; OpenFeature provider `open_feature_rulestead` resolve_* funcs | partial overlap — footguns.md:53-56 readiness; cross-link. Do NOT name `Rulestead.Store.Redis` as public |

**Cross-link discipline (GUIDE-01 acceptance):** troubleshooting.md gives Symptom→Cause→Fix→Verify; footguns.md gives the conceptual "why." Link to footguns once per overlapping pattern via `[footguns](footguns.md#<anchor>)`; never restate footguns prose. Anchors are GitHub/ExDoc auto-slugs of the `##` headings (lowercase, spaces→hyphens, punctuation dropped).

## The 4 Cookbook Recipes → Seam Map (GUIDE-02)

Fixed template per recipe: **Goal → For → Prerequisites → Steps → Verification → Gotchas → Related**. Each needs an honest **boundary line** (what the host owns / what Rulestead does NOT do).

| Recipe | Persona (user-flows-and-jtbd.md) | Public seams | Honest boundary line (source) |
|--------|----------------------------------|--------------|-------------------------------|
| Stripe-tier audience | Tech Lead (jtbd §2) / "premium accounts" (Flow 2, line 158-160) | `Rulestead.apply_audience_mutation(attrs, opts)` (map form, `rulestead.ex:964`), `Rulestead.preview_audience_impact/3`, `%Rulestead.Context{attributes:}` for tier | Host owns the Stripe webhook + population truth; previews "declare basis and uncertainty" — no authoritative affected-user count (product-boundary.md:40-41; footguns.md:38-42) |
| eval-telemetry → Segment | Support/SRE (jtbd §4-5) | `Rulestead.Telemetry.attach_many/4`; `[:rulestead, :eval, :decide, :stop]` + metadata keys; redaction guarantee | Telemetry is redacted by default — raw actor payloads/attrs are NOT in the contract; the host owns the Segment client (api_stability.md:408-410) |
| staging→prod CR promotion | Operator/Tech Lead (jtbd §2-3; Flow 3 "reviewable change", line 166-176) | `mix rulestead.promote` (promotion entry); `Rulestead.Admin.Policy.change_request_required?/4`; `[:rulestead, :admin, :mutation, :stop]`; audit via `Rulestead.list_audit_events/1` | Rulestead is "Promotion / GitOps" + governed apply, NOT a hosted control plane; protected-env gating is host-policy-driven (product-boundary.md:15,49). Do NOT headline the uncataloged `submit_change_request/1` |
| Oban-gated job | App Developer (jtbd §1; Flow 1) | `Rulestead.Oban.Middleware.attach/2`, `use Rulestead.Oban.Worker` + `rulestead_context/1`, `Rulestead.Runtime.enabled?/3`; `config :rulestead, :host, oban:` | Oban seam carries bounded context only — "not a promise of hosted rollout orchestration, governance queues, or hidden admin mutation pipelines" (oban-background-jobs.md tail; product-boundary boundary) |

**Persona grounding source:** `guides/introduction/user-flows-and-jtbd.md` defines the six personas (App Developer, Tech Lead, Operator, Support Engineer, SRE/On-call, Maintainer) and six flows (Ship Behind A Flag → Target Audience → Preview → Roll Out → Explain → Survive 3am). Anchor each recipe's "For" line to a named persona + flow. `guides/introduction/adoption-lab.md` adds concrete persona names (Alex = app dev) if a recipe wants a named actor.

## Architecture Patterns

### Existing Recipe Conventions (match these EXACTLY — verified)

- **Filename:** `guides/recipes/<kebab-case>.md` `[VERIFIED: ls guides/recipes/]`
- **H1:** single `# Title Case Title` (e.g. `# Oban Background Jobs`, `# Telemetry`, `# Footguns`)
- **Sections:** `## Sentence-case-ish Title Case` headings (e.g. `## Attach context when enqueueing`, `## Prefer the safe wrapper`). Existing files use sentence-style capitalization for `##`; footguns uses Title Case. Pick sentence-style for prose recipes; the cookbook's fixed template (`## Goal`, `## For`, …) uses single-word Title Case.
- **Code fences:** ` ```elixir ` for Elixir, ` ```bash ` / plain for shell. `[VERIFIED: oban-background-jobs.md, telemetry.md]`
- **Module/function refs:** inline backticks `` `Rulestead.Runtime.enabled?/3` `` — ExDoc autolinks these. `[VERIFIED: footguns.md:28,30; telemetry.md]`
- **Cross-links to other guides:** relative markdown `[context propagation](context-propagation.md)`, `[migrating from FunWithFlags](migrating-from-funwithflags.md)`, `[Adoption Lab](../introduction/adoption-lab.md)`. `[VERIFIED: footguns.md:30,66; testing.md:184,187]`
- **Avoid:** the absolute `file://`-style `:line` links (`[`Rulestead.Store`](/Users/jon/.../store.ex:1)`) seen in ecto-conventions.md:59 / telemetry.md:5 / testing.md:138 — these are editor artifacts and are NOT portable to HexDocs. Use backtick autolinks for code and relative `.md` links for guides. (They currently pass only because `skip_undefined_reference_warnings_on` whitelists `lib/`-prefixed refs — `[VERIFIED: mix.exs:165-168]`. Do not rely on that; prefer clean refs.)

### The mix.exs Edit (GUIDE-03) — exact

`groups_for_extras` already maps `"Recipes": ~r"guides/recipes/"` `[VERIFIED: rulestead/mix.exs:162]`, so **any new `guides/recipes/*.md` auto-joins the Recipes group — no `groups_for_extras` change needed.** GUIDE-03's "no new group" is satisfied by doing nothing there.

What DOES change is the `extras:` LIST (mix.exs:97-127), whose order drives sidebar order WITHIN the group. Current recipes block (lines 116-122):

```
"../guides/recipes/testing.md",
"../guides/recipes/ecto-conventions.md",
"../guides/recipes/oban-background-jobs.md",
"../guides/recipes/deployment.md",
"../guides/recipes/context-propagation.md",
"../guides/recipes/footguns.md",
"../guides/recipes/migrating-from-funwithflags.md",
```

Target edit: insert `integrations-cookbook.md` **early** (top of the recipes block, before `testing.md`) and `troubleshooting.md` **last** (after `migrating-from-funwithflags.md`, before `../guides/api_stability.md` on line 123):

```
"../guides/recipes/integrations-cookbook.md",   # early
"../guides/recipes/testing.md",
...
"../guides/recipes/migrating-from-funwithflags.md",
"../guides/recipes/troubleshooting.md",         # last
"../guides/api_stability.md",                   # unchanged — stays in "API & Stability" group
```

- The 15-minute golden path is `guides/introduction/getting-started.md` (extras line 101) — **leave untouched** `[VERIFIED: mix.exs:101]`.
- `skip_undefined_reference_warnings_on` (mix.exs:165) whitelists refs starting `lib/` or `mix verify.`; `skip_code_autolink_to` (mix.exs:169) skips autolinking `Rulestead.`, `mix rulestead.`, `mix verify.` text. **Net effect:** writing `mix rulestead.install` or `Rulestead.Runtime` in prose is safe (won't be force-autolinked or warned). Backtick `` `Rulestead.Runtime.enabled?/3` `` DOES autolink and must resolve — it will, since those are real public functions.

### Anti-Patterns to Avoid
- **Naming non-public internals as stable API** (`Rulestead.Store.Redis`, `Rulestead.Store.Command.*`, `Rulestead.Runtime.Cache`) — violates GUIDE-02's "shipped public seams" bar.
- **Duplicating footguns.md prose** in troubleshooting.md — GUIDE-01 says cross-link the "why," don't restate.
- **Re-introducing pre-1.0 language** (`0.1.x`, `~> 0.1`, "future 1.0") — fails `check_version_truth.py`.
- **Adding a new extras group** — GUIDE-03 forbids it.
- **Touching getting-started.md** — explicitly out of scope.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recipe group membership | A new `groups_for_extras` entry | The existing `~r"guides/recipes/"` regex | Auto-membership; GUIDE-03 forbids new group |
| "Why" explanations in troubleshooting | Restated conceptual prose | `[footguns](footguns.md#anchor)` cross-link | Single source of truth; GUIDE-01 mandate |
| Persona descriptions | New persona definitions | Reference `user-flows-and-jtbd.md` personas/flows | Already canonical |
| Version strings | Hand-picking `0.1.x`/version text | `1.x` / `~> 1.0` (matches getting-started.md, installation.md) | Version-truth guard + GA reality |

## Runtime State Inventory

> Not a rename/refactor/migration phase — greenfield documentation. The closest analogue (the version-truth guard scanning `guides/**`) is captured under Common Pitfalls and Validation Architecture. Section omitted intentionally.

## Common Pitfalls

### Pitfall 1: Version-truth guard hard-fail on new docs
**What goes wrong:** `python3 scripts/check_version_truth.py` exits 1 if either new file contains `0.1.x`, `0.1.7`, `future…1.0`, `1.0 API freeze`, `Two version lines`, or bare `~> 0.1`. `[VERIFIED: scripts/check_version_truth.py:45-52]`
**Why it happens:** It recursively globs `guides/**/*.md` (line 61) — both new recipes are in scope.
**How to avoid:** Use `1.x` and `~> 1.0` exclusively; the existing recipes' `v0.1.0` prose is grandfathered but `0.1.0` is NOT in the ban list — still, write `1.x` for truth.
**Warning signs:** Any literal `0.1` in version context.

### Pitfall 2: Broken autolink fails the docs gate
**What goes wrong:** `mix docs --warnings-as-errors` (lint.sh:36) fails on an undefined reference — e.g. backtick `` `Rulestead.foo/1` `` where `foo/1` doesn't exist, or a relative link to a missing `.md`.
**Why it happens:** Autoref to a function the author assumed exists (e.g. a stable `submit_change_request/3` arity that isn't real).
**How to avoid:** Only backtick-reference symbols in the "Verified Public Seams" table with their exact arity. Verify each `[text](file.md)` target exists in `guides/recipes/` or `guides/introduction/`.
**Warning signs:** New module/function names not in the verified table.

### Pitfall 3: Referencing a non-public seam as if stable
**What goes wrong:** A recipe headlines `Rulestead.Store.Redis` or `Rulestead.submit_change_request/1` as a stable public API; GUIDE-02 acceptance ("only shipped public seams") fails review even though `mix docs` is green.
**Why it happens:** The symbol renders/autolinks (it has `@doc` or is in `groups_for_modules`) so it looks public.
**How to avoid:** Cross-check EVERY headline seam against `api_stability.md`. Use the "Non-Public / Landmine Seams" table.
**Warning signs:** Symbol renders in HexDocs but is absent from `api_stability.md`.

### Pitfall 4: Product-boundary violation
**What goes wrong:** A recipe promises hosted analytics, a stats engine, authoritative user counts, or percentage-of-time rollouts.
**Why it happens:** Natural to over-promise in an integration guide.
**How to avoid:** Each recipe's boundary line must align with product-boundary.md "Out of scope" (lines 43-52) and "Host always owns" (37-41).
**Warning signs:** Claims of dashboards, warehouses, or affected-user census.

## Code Examples

Verified patterns the recipes can lean on (all from existing shipped recipes / public seams):

### Keyed runtime eval (payload-vs-keyed pattern 2; Oban recipe)
```elixir
# Source: guides/recipes/context-propagation.md (verified shipped)
{:ok, enabled?} =
  Rulestead.Runtime.enabled?(context.environment, "sync-enabled", context)
```

### Safe telemetry attach (Segment recipe)
```elixir
# Source: guides/recipes/telemetry.md (verified shipped)
Rulestead.Telemetry.attach_many(
  "my-app-rulestead",
  [[:rulestead, :eval, :decide, :stop]],
  &MyApp.RulesteadTelemetry.handle_event/4,
  nil
)
```

### Oban context attach + restore (Oban-gated job recipe)
```elixir
# Source: guides/recipes/oban-background-jobs.md (verified shipped)
job =
  %Oban.Job{args: %{"task" => "sync"}}
  |> Rulestead.Oban.Middleware.attach(
    context: %{targeting_key: "user-123", environment: "prod"}
  )

defmodule MyApp.SyncWorker do
  use Rulestead.Oban.Worker
  def perform(%Oban.Job{} = job) do
    context = rulestead_context(job)
    Rulestead.Runtime.enabled?(context.environment, "sync-enabled", context)
  end
end
```

### Install + migrate (troubleshooting pattern 1)
```bash
# Source: guides/introduction/getting-started.md:28-29 (golden path; do not modify that file)
mix rulestead.install
mix ecto.migrate
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `v0.1.0` / `~> 0.1.0` version language | `1.x` / `~> 1.0` | v2.0 milestone (Phase 125 version-truth sweep) | New docs MUST use 1.x; guard enforces |
| Free-form recipe structure | Cookbook on FIXED template (Goal→For→Prereq→Steps→Verification→Gotchas→Related) | This phase (GUIDE-02) | New convention for integrations-cookbook only; existing recipes unchanged |

**Deprecated/outdated:**
- Pre-1.0 framing in any `guides/**` file: removed by the version-truth guard.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The change-request functions (`submit_change_request/1` etc.) are usable-but-deliberately-uncataloged (documented, not semver-locked), so recipes may reference them as host entry points but not as stable API | Non-Public/Landmine; Recipe map | If they are actually private, the CR-promotion recipe and pattern 6 must route ENTIRELY through `Admin.Policy.change_request_required?/4` + telemetry, naming no `Rulestead.*_change_request` function. **Planner should confirm with maintainer.** |
| A2 | `mix rulestead.promote` and `mix rulestead.redis.sync` (both `@moduledoc false` but with `@shortdoc`) are acceptable to reference as operational tasks since they are in-scope surfaces (Promotion/GitOps; Redis adapter) | Recipe map; pattern 7 | If maintainer wants only `@moduledoc`-documented tasks referenced, recipes must describe outcomes (snapshot freshness, governed promotion) without naming the tasks |
| A3 | The cookbook's fixed template headings (`## Goal`, `## For`, …) render cleanly under ExDoc without a `groups_for_extras` change | mix.exs edit | Low — regex membership is structural, heading text is irrelevant to grouping |

## Open Questions

1. **Are the `*_change_request/1` root functions intended as public 1.x API?**
   - What we know: they have `@doc`+`@spec` and render; absent from `api_stability.md` catalog.
   - What's unclear: whether omission is deliberate (governance flow is the public seam) or an oversight.
   - Recommendation: planner adds a `checkpoint:human-verify` or routes the CR recipe/pattern through `Admin.Policy.change_request_required?/4` + `[:rulestead, :admin, :mutation, :stop]` to be safe regardless.

2. **OpenFeature provider surface for pattern 7.**
   - What we know: `open_feature_rulestead/lib/open_feature_rulestead/provider.ex` exposes `resolve_boolean_value/4`, `resolve_string_value/4`, `resolve_number_value/4`, `resolve_map_value/4`, `initialize/3`, `shutdown/1` `[VERIFIED: provider.ex:12-40]`.
   - What's unclear: whether the OF provider has its own published stability doc analogous to api_stability.md.
   - Recommendation: keep pattern 7 focused on the Rulestead-side stale-cache telemetry (`stale_used`/`miss`/`refresh`) and `mix rulestead.redis.sync`; mention OF provider resolve_* funcs as the consumer boundary only.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/mix | `mix docs --warnings-as-errors` validation | ✓ (CI lane, lint.sh) | per lint.sh | — |
| python3 | `check_version_truth.py` | ✓ (lint.sh runs it) | system | — |
| ExDoc | doc render | ✓ (rulestead dep) | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none — pure docs + existing CI toolchain.

## Validation Architecture

> nyquist_validation is enabled (config.json). For a docs phase the "tests" are the CI guards.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | mix docs + python guard (no ExUnit needed for the docs themselves) |
| Config file | `rulestead/mix.exs` (`docs:` block), `scripts/ci/lint.sh` |
| Quick run command | `cd rulestead && mix docs --warnings-as-errors` |
| Full suite command | `bash scripts/ci/lint.sh` (includes `mix docs --warnings-as-errors` + `check_version_truth.py`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GUIDE-01 | troubleshooting.md renders, 7 patterns, no broken refs | docs render | `cd rulestead && mix docs --warnings-as-errors` | ❌ new file |
| GUIDE-01 | no pre-1.0 drift | guard | `python3 scripts/check_version_truth.py` | ✅ guard exists |
| GUIDE-02 | cookbook renders, 4 recipes, no broken refs | docs render | `cd rulestead && mix docs --warnings-as-errors` | ❌ new file |
| GUIDE-03 | both files in Recipes group, correct order, golden path untouched | manual/visual + render | `cd rulestead && mix docs` then inspect sidebar order; `git diff` shows getting-started.md unchanged | ✅ mix.exs |

### Sampling Rate
- **Per task commit:** `cd rulestead && mix docs --warnings-as-errors` + `python3 scripts/check_version_truth.py`
- **Per wave merge:** `bash scripts/ci/lint.sh`
- **Phase gate:** full `lint.sh` green; sidebar order visually confirmed (cookbook early, troubleshooting last); `git diff guides/introduction/getting-started.md` empty.

### Wave 0 Gaps
- [ ] `guides/recipes/integrations-cookbook.md` — covers GUIDE-02 (does not exist yet)
- [ ] `guides/recipes/troubleshooting.md` — covers GUIDE-01 (does not exist yet)
- [ ] `rulestead/mix.exs` `extras:` edit — covers GUIDE-03

*(No new ExUnit test infra needed — the existing `mix docs --warnings-as-errors` lane and `check_version_truth.py` guard fully cover this docs phase. An optional addition: a tiny guard asserting both filenames appear in the `extras:` list and getting-started.md is unchanged, if the planner wants belt-and-suspenders.)*

## Security Domain

> `security_enforcement` is not a docs-relevant concern here — Phase 127 ships no code, no inputs, no auth surface. The one security-adjacent content rule: the RBAC-403 pattern and CR-promotion recipe must reinforce that **the host owns authorization** (`Rulestead.Admin.Policy`, no bundled auth stack — product-boundary.md:38) and must not imply Rulestead authenticates actors. No ASVS category applies to markdown authoring. Section otherwise omitted.

## Sources

### Primary (HIGH confidence)
- `guides/api_stability.md` — the locked 1.x public surface (catalog of modules, functions, telemetry events, config keys)
- `rulestead/mix.exs:90-175` — `docs:` block: `extras:`, `groups_for_extras`, `groups_for_modules`, skip rules
- `scripts/check_version_truth.py` + `scripts/ci/lint.sh` — CI guards (read line-by-line)
- `rulestead/lib/rulestead.ex`, `runtime.ex`, `plug.ex`, `phoenix.ex`, `live_view.ex`, `oban/*`, `admin/policy.ex`, `store/*`, `mix/tasks/rulestead.*` — seam existence + public/non-public status
- `guides/recipes/*.md` (oban, telemetry, context-propagation, footguns, deployment, testing) — conventions
- `guides/introduction/user-flows-and-jtbd.md`, `product-boundary.md`, `getting-started.md`, `installation.md` — personas, boundaries, golden path, version truth

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` (GUIDE-01/02/03 acceptance bars), `.planning/ROADMAP.md` (Phase 127 line)

### Tertiary (LOW confidence)
- None — all claims grounded in current-branch source.

## Metadata

**Confidence breakdown:**
- Standard stack (toolchain/guards): HIGH — read `lint.sh` and `check_version_truth.py` directly.
- Seam verification: HIGH — every referenced symbol grepped in source AND cross-checked against api_stability.md; landmines (CR funcs, Store.Redis, Command.*, promote/redis.sync tasks) explicitly flagged.
- Conventions: HIGH — sampled 6 existing recipes.
- Persona grounding: HIGH — user-flows-and-jtbd.md is canonical.
- One MEDIUM dependency: whether the uncataloged CR functions are intended-public (A1) — flagged for maintainer confirmation.

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 (stable; API surface is frozen for v2.0 — public surface locked as-is per REQUIREMENTS.md)
