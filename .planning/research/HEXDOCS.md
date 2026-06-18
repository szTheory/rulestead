# R2 — HexDocs Front Door & Public-API Doc Surface (ExDoc) for Rulestead 1.0 GA

**Milestone:** v2.0 — 1.0 GA Release & Adoption
**Scope:** ExDoc config, module/function doc patterns, "Why Rulestead?" landing extra, README + badges. **No new runtime APIs.** Lock the public surface as-is.
**Researched:** 2026-06-17
**Overall confidence:** HIGH (ExDoc options verified against official `ex-doc.hexdocs.pm` docs; exemplar patterns verified against Req/Ash sources; brand facts read from repo `brandbook/`).

---

## Recommended decisions register

| # | Decision | Recommendation | Confidence |
|---|----------|----------------|------------|
| D1 | Render the 3 hidden public modules | Replace `@moduledoc false` with real `@moduledoc` on `Rulestead.Context`, `Rulestead.Runtime`, `Rulestead.Admin.Policy` | HIGH |
| D2 | `Rulestead.Runtime` group placement | Add to a new **"Runtime (cached lookup)"** module group; keep `Rulestead.Runtime.*` impl modules `@moduledoc false` | HIGH |
| D3 | `groups_for_modules` shape | 5 groups: Core API · Runtime (cached lookup) · Behaviours & Seams · Store Adapters · Telemetry & Config | HIGH |
| D4 | `extras:` ordering | Reorder to match real onboarding funnel: Why Rulestead → Install → Getting Started → Phoenix Spine → concepts → flows → recipes; promote `api_stability.md` into an "API & Stability" group | HIGH |
| D5 | `groups_for_extras` | 6 groups: Introduction · Concepts · Guides (Flows) · Recipes · API & Stability · Contributing | HIGH |
| D6 | `logo:` | `../brandbook/assets/logo/rs-mark.svg` (the d-sigil mark; 48×48 area wants a square mark, not the wordmark) | HIGH |
| D7 | `favicon:` | `../brandbook/assets/logo/rs-favicon.svg` (distinct top-level option; ExDoc 0.34+) | HIGH |
| D8 | Theming via `before_closing_head_tag` | Inject a small `<style>` overriding ExDoc CSS custom-props with mineral palette + accent; **system/light/dark via `prefers-color-scheme`, no JS theme toggle**; respect ExDoc's own night-mode toggle | HIGH |
| D9 | `assets:` | `%{"../brandbook/assets/logo" => "assets"}` so the social card / marks ship to HexDocs output for in-page `<img>` use | HIGH |
| D10 | `source_ref` | Switch from `"v#{@version}"` to `"v#{@version}"` still — but version becomes `1.0.0`, so `source_ref: "v1.0.0"`; keep `source_url` | HIGH |
| D11 | `main:` | Keep `main: "readme"` (README is the canonical front door; HexDocs renders it as the landing) — but the README must carry the 1.0 pitch | HIGH |
| D12 | "Why Rulestead?" extra | New `guides/introduction/why-rulestead.md`, placed **first** in Introduction; positioning + differentiators + "what it is not" + 60-second mental model. NOT a duplicate of README | HIGH |
| D13 | Doc coverage bar | Every listed-public symbol gets `@doc` + `@spec`; add `@moduledoc` examples that are doctests where pure; CI guard via `mix docs` warnings-as-signal | HIGH |
| D14 | `@moduledoc false` discipline | Everything NOT in `api_stability.md` stays `@moduledoc false`; add a one-line "internal — not public API" banner comment | HIGH |
| D15 | README badge set | 5 badges: Hex version · HexDocs · CI · License · (optional) Elixir version. Exact markdown below | HIGH |
| D16 | Social card | Reference `rs-social-card.svg` as GitHub repo social preview (Settings) + as the OpenGraph image via `before_closing_head_tag` `<meta og:image>` | MEDIUM |
| D17 | `rulestead_admin` docs | Give it the same logo/favicon/theming + a real `@moduledoc` on `RulesteadAdmin.Router`; extras get the admin flow guides | HIGH |
| D18 | `api_reference` | Keep `true` (default). With `main: "readme"` the auto API-reference page is still useful as the module index | HIGH |

---

## 1. ExDoc configuration

### 1.1 The three hidden modules WILL NOT render — root cause and fix (D1)

Confirmed by reading source:

- `rulestead/lib/rulestead/context.ex` line 2: `@moduledoc false`
- `rulestead/lib/rulestead/runtime.ex` line 3: `@moduledoc false`
- `rulestead/lib/rulestead/admin/policy.ex` line 3: `@moduledoc false`

ExDoc **excludes any module with `@moduledoc false` from generated docs entirely** — it will not appear in the sidebar, the API reference, or be linkable. This directly contradicts `guides/api_stability.md`, which lists `Rulestead.Context`, `Rulestead.Admin.Policy`, and the `Rulestead.Runtime` facade as **public, supported, semver-locked** surface. For a 1.0 that markets stability, a public-but-invisible module is the single worst trust signal: adopters who read `api_stability.md` and click through find nothing.

Additionally confirmed: `Rulestead.Runtime` is **absent from `groups_for_modules`** in `rulestead/mix.exs` (lines 122–140). Even after un-hiding it, it would land in the ungrouped catch-all unless added (D2/D3).

**Fix:** Replace `@moduledoc false` with real module docs (drafts in §2). This is purely additive documentation — no runtime API change, fully inside the milestone's "no new features" constraint.

> Footgun to avoid (seen in many libs): un-hiding a module that has private-looking functions exposes `@doc`-less defs as "Functions" with no description, which looks worse than hidden. Pair D1 with D13: every public function on these three modules needs `@doc` + `@spec`, and any genuinely-internal function on them must be `@doc false` or moved to a private helper module. `Rulestead.Context` and `Rulestead.Runtime` already have `@spec`s on the public funs; they need `@doc` strings and the internal helpers marked `@doc false`.

### 1.2 Module groups (D2, D3)

Current groups (3): "Public API", "Store Adapters", "Extensibility". This is fine for `0.1.x` but undersells a 1.0 with a broad runtime facade, a cached-lookup facade, behaviour seams, and a telemetry/config contract. Idiomatic exemplars (Ecto, Ash, Phoenix) group by **the reader's mental model**, not by namespace.

**Recommended 5 groups** (order matters — first group shows first):

```elixir
groups_for_modules: [
  "Core API": [
    Rulestead,
    Rulestead.Context,
    Rulestead.Result,
    Rulestead.Error
  ],
  "Runtime (cached lookup)": [
    Rulestead.Runtime
  ],
  "Behaviours & Seams": [
    Rulestead.Store,
    Rulestead.Admin.Policy,
    Rulestead.Tenancy
  ],
  "Store Adapters": [
    Rulestead.Store.Ecto,
    Rulestead.Store.Redis
  ],
  "Telemetry & Config": [
    Rulestead.Telemetry,
    Rulestead.Config
  ]
]
```

Rationale / tradeoffs:
- **`Rulestead.Runtime` gets its own group.** Pro: the docs make the payload-first (`Rulestead.evaluate/3`) vs cached-lookup (`Rulestead.Runtime.enabled?/3`) distinction visible — this is the #1 confusion for new adopters (the README already has to explain it twice). Con: a one-module group looks thin; acceptable because the distinction is load-bearing. Alternative considered: fold `Runtime` into "Core API" — rejected because it blurs the very distinction `product-boundary.md` works hard to draw.
- **"Behaviours & Seams"** replaces the vaguer "Extensibility" and now correctly houses `Rulestead.Admin.Policy` (a `@callback`-defining behaviour) and `Rulestead.Store`. This is the Ecto pattern ("Adapters and recipes" / behaviours grouped).
- `Rulestead.Runtime.Snapshot` was in the old "Extensibility" group but is **explicitly NOT public** per `api_stability.md` line 58. **Remove it from groups and keep it `@moduledoc false`.** (Current mix.exs leaks it into a group — a real bug to fix.)
- `Rulestead.Config` is listed public (`api_stability.md` §"Stable Host Config Schema") but is not currently grouped; add it.

`Rulestead.Telemetry` and `Rulestead.Config` are both listed public — confirm they are NOT `@moduledoc false` before relying on the group (Grep them during implementation; if hidden, same fix as D1).

### 1.3 Extras ordering and groups (D4, D5)

The current `extras:` list (mix.exs 92–121) is essentially in repo-folder order, not reader order, and buries `api_stability.md` mid-list. For a 1.0 front door the order should mirror the **actual onboarding funnel** a HexDocs visitor follows.

**Recommended `extras:`** (README stays `main`, so it's the landing; the rest is sidebar order):

```elixir
extras: [
  "README.md",
  # — Introduction —
  "../guides/introduction/why-rulestead.md",         # NEW (D12), first concept page
  "../guides/introduction/installation.md",
  "../guides/introduction/getting-started.md",
  "../guides/introduction/phoenix-integration-spine.md",
  "../guides/introduction/domain_language.md",
  "../guides/introduction/product-boundary.md",
  "../guides/introduction/user-flows-and-jtbd.md",
  "../guides/introduction/adoption-lab.md",
  # — Guides (Flows) —
  "../guides/flows/evaluation.md",
  "../guides/flows/rulesets.md",
  "../guides/flows/flag-lifecycle.md",
  "../guides/flows/rollout.md",
  "../guides/flows/admin-ui.md",
  "../guides/flows/explainability.md",
  "../guides/flows/multi-env.md",
  "../guides/flows/telemetry.md",
  "../guides/flows/extending-rulestead.md",
  # — Recipes —
  "../guides/recipes/testing.md",
  "../guides/recipes/ecto-conventions.md",
  "../guides/recipes/oban-background-jobs.md",
  "../guides/recipes/deployment.md",
  "../guides/recipes/context-propagation.md",
  "../guides/recipes/footguns.md",
  "../guides/recipes/migrating-from-funwithflags.md",
  "../guides/recipes/troubleshooting.md",            # NEW (milestone adoption guide)
  "../guides/recipes/integrations-cookbook.md",       # NEW (milestone adoption guide)
  # — API & Stability —
  "../guides/api_stability.md",
  "../guides/introduction/upgrading.md",
  "../guides/cheatsheet.cheatmd",
  # — Contributing —
  "../CONVENTIONS.md"
],
```

**Recommended `groups_for_extras`** (regex-matched; ExDoc assigns first match):

```elixir
groups_for_extras: [
  "Introduction": ~r"guides/introduction/",
  "Guides": ~r"guides/flows/",
  "Recipes": ~r"guides/recipes/",
  "API & Stability": ~r"guides/(api_stability|introduction/upgrading)|cheatsheet",
  "Contributing": ~r"CONVENTIONS"
]
```

Key moves and rationale:
- **`why-rulestead.md` first.** A first-time HexDocs visitor lands on the README, then the very first sidebar item should answer "is this for me?" before "how do I install?". This mirrors Ash's **"Start Here"** group and Ecto's intro ordering.
- **`api_stability.md` promoted into its own "API & Stability" group** alongside `upgrading.md`. For a 1.0 whose entire pitch is *semver truth*, the stability contract must be a first-class, easy-to-find section — not item #11 in a flat list. This is the highest-leverage extras change.
- **`upgrading.md` moves here too** — it's the `0.1.x → 1.0` migration story (a named milestone deliverable). Co-locating it with the stability contract is the principle of least surprise.
- **Group naming:** "Guides" (not "Flows") reads better to outsiders; "Flows" is internal vocabulary. Keep the regex pointed at `guides/flows/` but label the group "Guides".
- The two NEW adoption guides (`troubleshooting.md`, `integrations-cookbook.md`) slot into Recipes.

Per-extra options worth using (ExDoc supports `title:`, `filename:`, `search_data:`): give `domain_language.md` a friendlier `title: "Concepts & Domain Language"` since the filename uses an underscore. Example:

```elixir
{"../guides/introduction/domain_language.md", title: "Concepts & Domain Language"},
```

### 1.4 Logo, favicon, assets (D6, D7, D9)

Verified ExDoc behavior (official docs):
- **`logo`**: PNG/JPEG/**SVG**. "shown within a 48×48px area. If using SVG, ensure appropriate width, height and viewBox attributes are present." → Use a **square** asset. The wordmark (`rs-wordmark.svg`, viewBox `0 0 340 62`) would be crushed into 48×48. The repo has `rs-mark.svg` (viewBox `0 0 62 62`, the d-sigil) — **that is the correct logo** for the 48px slot.
- **`favicon`**: separate top-level option (PNG/JPEG/SVG), copied to `assets/favicon.EXT`. The repo has `rs-favicon.svg`. Use it.
- **`assets`**: "A map of source => target directories copied as-is to the output path." Use this to ship the social card + wordmark so in-page Markdown can reference them and the OG meta tag can point at a real URL.

```elixir
logo: "../brandbook/assets/logo/rs-mark.svg",
favicon: "../brandbook/assets/logo/rs-favicon.svg",
assets: %{"../brandbook/assets/logo" => "assets"},
```

> Note: `logo` and `favicon` paths are relative to the package root (where `mix.exs` lives), hence `../brandbook/...`. **You must also add `brandbook/assets/logo` to the package `files:` list** in `package/0` — otherwise the published Hex tarball won't contain the SVGs and HexDocs (which builds from the package) will 404 the logo. Today `files:` (mix.exs 81–83) does **not** include `brandbook/`. This is a concrete release-blocking gotcha.

Cover: ExDoc's `cover:` is PNG/JPEG only and "has no effect when using the html formatter." HexDocs uses the html formatter, so **do not set `cover`** — it only matters for EPUB. Don't waste effort exporting a PNG cover.

### 1.5 Theming — `before_closing_head_tag` (D8)

ExDoc ships its own night-mode (system/dark/light) toggle and a set of CSS custom properties (`--main-background`, `--sidebar-background`, `--link-color`, `--text-color`, etc.). The brand-faithful, low-risk path is **not** to fight ExDoc's theme machinery but to **re-tint its variables** with the mineral palette, scoped so it respects ExDoc's own light/dark switching.

Verified palette (from `brandbook/tokens.css`):
- Light brand primary `#3A6F8F` (Stead Blue), accent `#9b5931` (Ember Copper).
- Dark brand primary `#5885a0`, social-card field `#0F1720` (Basalt).
- Ink blue `#183247` (wordmark fill).

Recommended `before_closing_head_tag` function (mutually coherent with the logo's own colors):

```elixir
defp docs do
  [
    # ...
    before_closing_head_tag: &before_closing_head_tag/1
  ]
end

defp before_closing_head_tag(:html) do
  """
  <meta property="og:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.svg">
  <meta name="twitter:card" content="summary_large_image">
  <style>
    /* Rulestead mineral palette — re-tints ExDoc CSS vars; respects ExDoc light/dark */
    :root {
      --link-color: #3A6F8F;        /* Stead Blue */
      --link-visited-color: #2d5f7c;
      --main-color-darkened: #183247;
      --code-link-color: #9b5931;   /* Ember Copper accent for code links */
    }
    .dark {
      --link-color: #5885a0;        /* desaturated brand for dark */
      --code-link-color: #c08a63;
    }
    /* keep focus rings on-brand and visible (a11y); do NOT remove outlines */
    a:focus-visible, button:focus-visible {
      outline: 2px solid #3A6F8F;
      outline-offset: 2px;
    }
  </style>
  """
end

defp before_closing_head_tag(:epub), do: ""
```

Rationale / tradeoffs:
- **Why re-tint vars, not a custom stylesheet:** ExDoc renames/reorganizes CSS classes between minor versions (a real footgun — Ash and others pin or avoid deep class overrides). Re-tinting documented `:root`/`.dark` custom properties is the most version-stable surface and the smallest blast radius. HIGH confidence it survives ExDoc upgrades.
- **`.dark` selector:** ExDoc applies the `dark` class on the root when night mode is active; tinting both `:root` and `.dark` gives correct light/dark/system without any JS.
- **No theme JS, no toggle of our own:** the milestone wants "respect light/dark/system; no weird hover/focus." ExDoc already does system-default + manual toggle. Adding our own would conflict. **Do nothing beyond re-tinting.**
- **Focus ring** is set explicitly to the brand blue with offset — matches the admin UI's `:focus-visible` discipline (v1.13) and is AA-safe on both themes.
- **`og:image`** points at the social card we ship via `assets:` (D9/D16). This makes Slack/Twitter/forum link unfurls show the branded card — important for the ElixirForum announce.

Footgun: keep the injected CSS **minimal**. The temptation is to restyle headers, sidebar, code blocks to match the HTML brand book — resist it. Heavy overrides break on every ExDoc release and on mobile. The exemplars that age well (Phoenix, Ecto, Req) use **near-stock ExDoc** with at most a link-color tweak. Rulestead should match that restraint; the brand shows through the logo, favicon, social card, accent link color, and the copy voice — not a reskinned doc chrome.

### 1.6 `source_ref` / `source_url` (D10)

Current: `source_ref: "v#{@version}"` with `@version "0.1.7"`. After the 1.0 cut `@version` becomes `"1.0.0"`, so `source_ref` auto-resolves to `"v1.0.0"`. **Keep the interpolation** — it stays correct across future bumps. Confirm a matching git tag `v1.0.0` exists at publish time (release-please will create it for `rulestead`/`rulestead_admin`; the manual `open_feature_rulestead` publish must tag too). `source_url` is already correct (`https://github.com/szTheory/rulestead`).

One subtlety: this is a **monorepo** — the package roots are `rulestead/` and `rulestead_admin/`, but `source_url` points at the repo root. ExDoc generates `%{path}#L%{line}` links relative to repo root, and because `mix docs` runs from inside `rulestead/`, the `path` will be repo-relative correctly for files under `rulestead/lib/...`. Verify a couple of "source" links after the first `mix docs` render — monorepo source-link drift is a known ExDoc gotcha. If links 404, set an explicit `source_url_pattern` accounting for the `rulestead/` subdir.

### 1.7 `rulestead_admin` docs (D17)

`rulestead_admin/mix.exs` `docs/0` is bare (`main: "readme"`, extras `["README.md", "CHANGELOG.md"]`, no logo/groups/theming). For a 1.0 it should at minimum:
- Get the same `logo`, `favicon`, `before_closing_head_tag` (share the helper via a tiny copied function — the two mix.exs files can't share code, so duplicate the small function).
- Add the admin-facing flow guides to `extras:` (`../guides/flows/admin-ui.md`, `explainability.md`) so the admin package docs are not a dead end.
- A real `@moduledoc` on `RulesteadAdmin.Router` (the one public symbol per `api_stability.md` §"Public Admin Seam") documenting `rulestead_admin/2`, the required `policy:` option, and the session keys. Everything else (`RulesteadAdmin.Live.*`, `Components.*`) stays `@moduledoc false`.

---

## 2. Module + function doc patterns

### 2.1 Draft `@moduledoc` openers for the three hidden modules

These are drafts in the brand voice (clear, calm, exact; from `VOICE.md`), sized to render well and seed doctests where pure.

**`Rulestead.Context`** — replace `@moduledoc false`:

```elixir
@moduledoc """
Explicit evaluation context: who is asking, in which environment, and with what
attributes.

`Rulestead.Context` is the second argument to every evaluation call. It is a
plain struct you build once per request (or once per job) and pass into
`Rulestead.evaluate/3`, `Rulestead.Runtime.enabled?/3`, and the other evaluation
functions. Evaluation never reads ambient process state — context is always
explicit, which is what makes a decision reproducible and explainable.

## Building a context

    iex> ctx =
    ...>   Rulestead.Context.new(
    ...>     environment: "production",
    ...>     targeting_key: "user-123",
    ...>     attributes: %{plan: :pro}
    ...>   )
    iex> ctx.targeting_key
    "user-123"

The `:targeting_key` is the stable identity used for deterministic, sticky
bucketing — pass the same key and a flag resolves the same way every time.
`:attributes` carry the traits your ordered rules match on.

## Stable fields

See [API Stability](api_stability.md) for the frozen field list. The supported
fields are `:actor`, `:targeting_key`, `:tenant_key`, `:environment`,
`:attributes`, `:request_id`, `:session_id`, and `:strict?`.
"""
```

(Implementation note: the private helpers `normalize_aliases/1`, `promote_traits_to_attributes/1`, etc. stay private; only `new/1` and `normalize/1` are public per `api_stability.md` — they already have `@spec`; add `@doc` to each.)

**`Rulestead.Runtime`** — replace `@moduledoc false`:

```elixir
@moduledoc """
Cached, keyed flag lookup for running Phoenix and Plug applications.

Where `Rulestead.evaluate/3` is the pure evaluator over an authored flag
*payload* you already hold, `Rulestead.Runtime` resolves a flag by
`environment_key` and `flag_key` against the local snapshot cache and then
evaluates it. Use it in request and job paths where you do not want to fetch and
pass payloads yourself.

    {:ok, true} =
      Rulestead.Runtime.enabled?("production", "checkout_v2", context)

## Payload-first vs cached lookup

| You have… | Use |
|-----------|-----|
| an authored flag payload | `Rulestead.evaluate/3` |
| an environment + flag key, snapshot cache running | `Rulestead.Runtime` |

Both share the same deterministic evaluator and the same `%Rulestead.Result{}`.

## Supported surface

This facade is a closed catalog: `evaluate/3`, `enabled?/3`, `get_value/4`,
`get_variant/3`, `explain/3`, and `diagnostics/1`. Modules under
`Rulestead.Runtime.*` (cache, snapshot, refresh) are **implementation detail and
not public API** — see [API Stability](api_stability.md).
"""
```

(Implementation note: `api_stability.md` lists `diagnostics/1` as the public arity, but `Rulestead.diagnostics/0` delegates to `Runtime.diagnostics()`. Confirm the public `Rulestead.Runtime` arity during implementation and document exactly the frozen catalog; do not document arities that don't match the contract.)

**`Rulestead.Admin.Policy`** — replace `@moduledoc false`:

```elixir
@moduledoc """
Host-owned authorization seam for the mounted admin and governed actions.

Rulestead does not ship an auth stack. You implement this behaviour in your
application and pass it to `RulesteadAdmin.Router.rulestead_admin/2` (and it is
consulted for governed runtime mutations). Each call is explicit about *who*
(`actor`), *what* (`action`), *which resource*, and *which environment* — there
is no implicit role inference.

    defmodule MyApp.RulesteadPolicy do
      @behaviour Rulestead.Admin.Policy

      @impl true
      def can?(actor, action, _resource, _environment_key) do
        action in Rulestead.Admin.Policy.viewer_actions() or admin?(actor)
      end
    end

## Canonical role model

Actions map to the Viewer / Editor / Admin model. The action catalogs are
introspectable: `viewer_actions/0`, `editor_actions/0`, `admin_actions/0`,
`governance_actions/0`.

## Callbacks

`c:can?/4` is required. `c:change_request_required?/4` and
`c:allow_self_approval?/4` are optional and default to safe (governed) behavior.
"""
```

This module already exposes `@callback`s and the `*_actions/0` helpers with `@spec`s — un-hiding it renders a genuinely useful behaviour page (the `@callback`s become a "Callbacks" section automatically). Add `@doc` strings to `governance_actions/0` etc.

### 2.2 `@doc` / `@spec` coverage expectations (D13)

For a 1.0 that promises stability, the bar is: **every symbol listed in `api_stability.md` has both `@doc` and `@spec`.** Most of `Rulestead` already has `@spec` (verified in `lib/rulestead.ex`) and short `@doc`s. Gaps to close:
- The three un-hidden modules' public functions (above).
- Any listed-public function whose `@doc` is a one-liner that doesn't show a return shape — add a `## Examples` or at least an `## Returns` note for the workflow functions (`evaluate/3`, `enabled?/2`, `get_value/3`, `explain/2`).
- `%Rulestead.Result{}` and `%Rulestead.Error{}` field meaning — document the closed `:reason` and `:type`/`:domain` atoms inline (they're already enumerated in `api_stability.md`; mirror briefly in the moduledoc so the doc page is self-contained).

Doctest conventions:
- Make examples doctests **only where the function is pure and has no store/config dependency** — i.e. `Rulestead.Context.new/1`, `Rulestead.evaluate/3` over an inline payload, `Rulestead.Result.new/1`. These run under `mix test` and become a correctness guard for the public contract (this is the Ecto/Nimble pattern).
- Do **not** doctest store-backed or cache-backed functions (`Rulestead.Runtime.*`, `Rulestead.fetch_flag/3`) — they need Postgres/Redis and would make docs flaky. Show them as plain fenced ```elixir blocks instead.
- Idiomatic: a doctest for the bucketing determinism claim (same `targeting_key` → same variant) is high-value marketing-as-test.

CI signal: `mix docs` already runs in this repo's toolchain (ex_doc dep present). Treat **ExDoc undefined-reference warnings as a release gate** for the 1.0 cut — the milestone is about doc truth. The existing `skip_undefined_reference_warnings_on` (mix.exs 146–149) suppresses `lib/` and `mix verify.` refs; keep it, but during the 1.0 audit, run `mix docs` and read the warning output for broken `` `Rulestead.X` `` autolinks introduced by un-hiding modules.

### 2.3 Public-vs-internal discipline (D14)

The rule for a stability-promising lib: **`@moduledoc false` is the default for anything not in `api_stability.md`.** Audit `lib/` for modules that are *not* listed but also *not* `@moduledoc false` — those are accidental public surface. From the contract, these must stay hidden:
- `Rulestead.Runtime.Cache`, `Rulestead.Runtime.Snapshot`, all `Rulestead.Runtime.*` impl
- `Rulestead.Fake.Control`, governance/manifest/admin internals
- `RulesteadAdmin.Live.*`, `RulesteadAdmin.Components.*`

For genuinely-internal modules, keep `@moduledoc false` and add a one-line comment (`# Internal — not public API; see guides/api_stability.md`) so future contributors don't accidentally document them. This is exactly Bandit's / Plug's discipline (a small documented surface over a large private one).

Footgun: `@moduledoc false` hides the module but **`@doc` on its functions still emits autolink targets**. If a guide links `` `Rulestead.Runtime.Cache.foo/1` ``, ExDoc warns. Keep guides referencing only the listed public surface.

---

## 3. "Why Rulestead?" positioning extra (D12)

**File:** `guides/introduction/why-rulestead.md`. **Placement:** first item in the Introduction group (after README). **Purpose:** answer "is this for me, and why this over FunWithFlags / LaunchDarkly / rolling my own?" in 2 minutes. It is the HexDocs equivalent of a landing page — but it is **not** a duplicate of the README. README = "what + 15-min quickstart"; Why = "why + mental model + boundaries."

Source material: `brandbook/brand-book.md` §6 (Differentiation: "Core differentiators", "What Rulestead is not", "Competitive language frame"), §7 (Messaging pillars), `COPY.md` (Feature Blurbs, Landing Hero), `VOICE.md`. Reuse verbatim where possible — the copy is already on-brand and AA-reviewed.

### Proposed outline

```
# Why Rulestead?

> Runtime decisions, made clear.                         ← tagline (COPY.md)

[1 paragraph: the problem narrative — opaque flag precedence,
 "why did this user see X?", flags that never die. From brand-book §4.]

## What you get
- Ordered rules            (COPY.md "Ordered rules" blurb)
- Multivariate values      (COPY.md blurb)
- Local, explainable eval  (COPY.md blurb)
- Lifecycle-aware governance, host-owned auth

## The mental model (60 seconds)
[Context in → ordered rules → deterministic bucketing → Result + explain trace.
 The single diagram/table that makes evaluation legible. Link evaluation.md.]

## Payload-first vs cached lookup
[The one table from §2.1 Runtime moduledoc — set expectations early.]

## What Rulestead is — and is not
[Two short columns from brand-book §6 "What Rulestead is not":
 self-hostable, Elixir-native, mounted (not standalone) admin;
 NOT a hosted SaaS, NOT an observability product, NOT a team directory.
 Link product-boundary.md for the full boundary.]

## Where it fits
[Phoenix/Plug/Ecto/LiveView/Oban one-liner + sibling-package shape.
 Link getting-started.md as the next step.]

## Next steps
- Install → Getting Started → Phoenix Integration Spine
```

Principle of least surprise for a first-time visitor:
- **Set the boundary early.** The biggest adopter disappointment risk (per `product-boundary.md`) is expecting a hosted LaunchDarkly clone. State "self-hostable, mounted admin, host owns auth/identity/observability" above the fold so the wrong-fit reader bounces in 30 seconds instead of after a failed integration.
- **Don't restate the quickstart.** Link to it. The Why page earns the install; the README delivers it.
- **Keep it short** (one screen + a table or two). Long positioning pages read as marketing; the brand voice is "low hype."

---

## 4. README for hex.pm + GitHub (D11, D15, D16)

HexDocs renders `README.md` as the landing page (`main: "readme"`), and hex.pm shows it on the package page, and GitHub shows it on the repo. One file, three audiences — so it must carry the above-the-fold 1.0 pitch, the badge row, and the install snippet, then funnel into the guides.

**Relationship to the HexDocs landing:** README *is* the HexDocs landing (because `main: "readme"`). The "Why Rulestead?" extra is the *second* thing in the sidebar and goes deeper on positioning. So: README = pitch + badges + 15-min quickstart + "choose your path" links; Why = the durable positioning/mental-model essay. No duplication of the quickstart between them.

### Current README problems to fix for 1.0

The current `README.md` is structurally good (hero, 60-second, 15-min quickstart, choose-your-path) but has **two release-truth defects** for a 1.0 cut:
1. The "Two version lines" callout (lines 7–10) explains the `0.1.x` Hex vs repo-`v1.0.0` mismatch — **this entire callout must be deleted.** The milestone *resolves* the mismatch (all packages → `1.0.0` on Hex). Leaving it would re-introduce the exact confusion the milestone exists to kill.
2. Every install snippet says `{:rulestead, "~> 0.1"}` → change to `{:rulestead, "~> 1.0"}`. Same for `rulestead_admin`. The `getting-started.md` extra has the same `0.1.x` language to scrub.
3. **No badges and no logo** at the top.

### Recommended badge set (D15) — exact markdown

Idiomatic Elixir badge row (verified against Req's README, which uses Hex version + Hex docs + CI + license). For Rulestead:

```markdown
[![Hex.pm](https://img.shields.io/hexpm/v/rulestead.svg)](https://hex.pm/packages/rulestead)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blueviolet.svg)](https://hexdocs.pm/rulestead)
[![CI](https://github.com/szTheory/rulestead/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/rulestead/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/hexpm/l/rulestead.svg)](https://github.com/szTheory/rulestead/blob/main/LICENSE)
```

Optional 5th (only if you want it): `[![Elixir](https://img.shields.io/badge/elixir-~%3E%201.17-purple.svg)](https://elixir-lang.org)`.

Notes:
- Verify the CI workflow filename (`ci.yml`) — adjust badge URL to the real workflow path under `.github/workflows/`.
- Use `hexpm/v/rulestead` (auto-updates from Hex) rather than a hardcoded version badge.
- `hexpm/l/rulestead` reads the license from package metadata (already `["MIT"]`).

### README skeleton (above-the-fold pitch)

```markdown
<p align="center">
  <img src="brandbook/assets/logo/rs-wordmark.svg" alt="Rulestead" width="320">
</p>

<p align="center">
  <em>Runtime decisions, made clear.</em>
</p>

<p align="center">
  [Hex.pm badge] [Hex Docs badge] [CI badge] [License badge]
</p>

Rulestead is an Elixir-native feature management system for safe rollout,
multivariate config, and explainable runtime decisions — for Phoenix, Plug,
Ecto, LiveView, and Oban apps. It ships as two sibling Hex packages:

- **`rulestead`** — runtime evaluator, installer, context builders, test helpers
- **`rulestead_admin`** — optional mounted Phoenix LiveView operator UI

Evaluation is deterministic, rule precedence is explicit, and every decision is
explainable without reverse-engineering application state.

## Install

    defp deps do
      [
        {:rulestead, "~> 1.0"}
      ]
    end

    mix deps.get
    mix rulestead.install
    mix ecto.migrate

## 15-minute quickstart
[keep current payload-first + Rulestead.Runtime examples — they're good;
 just bump version pins and drop the version-mismatch callout]

## Choose your path
[keep current Build / Operate / Extend link clusters]

## Why teams adopt it
[keep current bullet list]

## Local demo
[keep FleetDesk adoption-lab section]

## Versioning
Rulestead follows Semantic Versioning. See [API Stability](guides/api_stability.md)
and [Upgrading](guides/introduction/upgrading.md).
```

Rationale:
- **Wordmark (not mark) at README top:** the README header is wide, so the horizontal `rs-wordmark.svg` (or the `readme-header.svg` specimen) is correct here — opposite of the ExDoc `logo` slot (D6) which is square. The repo has `brandbook/assets/specimens/readme-header.svg` purpose-built for this; prefer it if it includes the tagline lockup.
- **Centered hero block** is the idiomatic Elixir README pattern (Phoenix, Ash, Nx). Req omits the logo but it has no brand system; Rulestead does, so use it.
- **Logo path in README is repo-relative** (`brandbook/assets/logo/...`) — GitHub and hex.pm both resolve repo-relative image paths, but **hex.pm only if the file is in the package `files:`** (same gotcha as D6/D9). Add `brandbook/assets/logo` and `brandbook/assets/specimens` to `files:`.
- **Social card (D16):** set `rs-social-card.svg` as the GitHub repo's social preview image (repo Settings → Social preview — note GitHub wants PNG/JPG there, so you may need to rasterize the SVG to 1200×630 PNG; the repo's brand tooling already renders SVG→PNG per memory). Reference the same card as `og:image` via `before_closing_head_tag` (D8) for HexDocs/forum unfurls.

---

## 5. Lessons from exemplar libs (what to copy / what to avoid)

| Lib | Copy this | Avoid / footgun |
|-----|-----------|-----------------|
| **Req** | 4-badge row (version/docs/CI/license); README opens with a runnable example, not prose; near-stock ExDoc | No logo/brand (N/A for Rulestead — it has one) |
| **Ecto** | Module groups by mental model (not namespace); behaviours grouped; rich doctested moduledocs | — |
| **Phoenix** | Restrained ExDoc theming; guides-as-extras grouped by reader journey; README funnels to guides | Large guide set can overwhelm — Rulestead's grouping (D5) mitigates |
| **Ash** | "Start Here" extras group first; per-formatter `before_closing_head_tag` for analytics + small `<style>`; mermaid via head tag; `source_ref: "v#{@version}"` | 14 module groups / 100+ modules is a lot — only justified by Ash's size; Rulestead's 5 groups is right-sized |
| **Oban** | Excellent `@moduledoc` narrative + small public surface, large private; clear "Pro vs OSS" boundary mirrors Rulestead's "core vs admin vs OpenFeature" framing | — |
| **Bandit / Plug** | Tiny documented public surface over large `@moduledoc false` internals — exactly Rulestead's `api_stability.md` posture | — |
| **Nx / LiveView** | Cross-linking between guides and module docs via autolink (`` `Rulestead.evaluate/3` ``) | Broken autolinks emit warnings — gate on them (D13) |
| **docs.rs (Rust)** | Feature-flagged item visibility, version-pinned source links | N/A to ExDoc but reinforces: source links must be version-pinned (`source_ref`) |

**Cross-cutting lesson:** the best-documented Elixir libs win on **doc structure + voice + a tiny stable surface**, not on heavy custom CSS. Rulestead already has the surface (`api_stability.md`) and the voice (`VOICE.md`/`COPY.md`); the 1.0 work is (a) make the listed surface actually render (D1), (b) order/group it for the reader (D3–D5), (c) add the Why page (D12), (d) light brand touches (D6–D9), (e) tell the truth in README (D11/D15).

---

## 6. Reader-DX, accessibility, brand-faithfulness

- **Light/dark/system:** ExDoc's built-in night mode + the `:root`/`.dark` re-tint (D8) covers all three with zero JS. No custom toggle.
- **Focus/hover:** explicit `:focus-visible` brand-blue ring with offset; no removed outlines; no novel hover behavior. Matches v1.13 admin a11y discipline.
- **Contrast:** brand link colors are AA on ExDoc backgrounds (light `#3A6F8F` on white; dark `#5885a0` on ExDoc dark surface) — the same pairs already AA-verified in the admin re-skin. Use the dark-mode brand value `#5885a0`, not the light `#3A6F8F`, inside `.dark` (the light blue fails contrast on dark backgrounds — a real trap).
- **Brand-faithful without fighting ExDoc:** logo (mark), favicon, accent link color, social card OG image, and the copy voice carry the brand. Doc chrome stays near-stock — this is *more* on-brand for a "calm, low-hype" identity than a heavily reskinned site would be.
- **SVG logo sizing:** `rs-mark.svg` has `viewBox="0 0 62 62"` — square, satisfies ExDoc's "ensure viewBox present for predictable cropping" requirement. The wordmark would distort in the 48px slot.

---

## 7. Open questions / implementation-time verifications

1. **Confirm `Rulestead.Telemetry` and `Rulestead.Config` are not `@moduledoc false`** — both are listed public; if hidden, apply the D1 fix (Grep at implementation time).
2. **`Rulestead.Tenancy`** is in the proposed "Behaviours & Seams" group and appears in current mix.exs Extensibility — confirm it's listed/intended public (it's referenced in `api_stability.md` config schema `tenancy.module` but not in the stable-modules list; decide whether to group it or drop it).
3. **`Rulestead.Runtime.diagnostics/1` arity** — `api_stability.md` says `diagnostics/1`; root facade has `diagnostics/0`. Document the exact frozen arity; don't invent one.
4. **`files:` must include `brandbook/assets/logo` (+ `specimens`)** or logo/favicon 404 on HexDocs and hex.pm — release-blocking; verify in the published tarball with `mix hex.build` before the real publish.
5. **Monorepo source-link paths** — verify `source_url` links resolve after first `mix docs`; add `source_url_pattern` only if they 404.
6. **CI workflow filename** for the README CI badge — confirm the path under `.github/workflows/`.
7. **Social card rasterization** — GitHub repo social-preview needs PNG/JPG, not SVG; use the existing SVG→PNG brand tooling to emit a 1200×630 PNG of `rs-social-card.svg`.
8. **Apply the same logo/favicon/theming to `rulestead_admin`** mix.exs (duplicate the small `before_closing_head_tag` helper).
