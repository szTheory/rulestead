# Phase 126: HexDocs Front Door - Context

**Gathered:** 2026-06-18 (assumptions mode + 4-agent gray-area research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the **already-shipped** v1.15 "Identity Tournament" brand assets into the published
HexDocs of **both** sibling packages so they present a 1.0-grade, branded, onboarding-funnel
experience — logo/favicon resolving (no 404s), module groups, extras funnel, mineral-palette
theming, README hero+badges, and `rulestead_admin` docs at parity.

**This is mechanical WIRING, not design.** The brand (logo, palette, voice) is frozen. Do NOT
re-open visual brand design. Do NOT add runtime APIs — every "un-hide" below renders an
**already-frozen** contract surface (per `api_stability.md`) more truthfully; none widens the
public contract. Requirements: DOC-01..DOC-06.
</domain>

<decisions>
## Implementation Decisions

> **Provenance:** Baseline = `.planning/research/HEXDOCS.md`. Four research agents pressure-tested
> it against the live codebase + top Elixir libs (Ash, Oban, Phoenix, LiveDashboard, Oban Web) and
> found **three empirically-proven corrections to HEXDOCS.md** (marked ⚠️CORRECTS-HEXDOCS). Those
> corrections supersede HEXDOCS.md where they conflict.

### A. Module groups — `groups_for_modules` (DOC-01) — 6 groups (LOCKED)
- **D-01:** Ship exactly these **6** groups (membership reconciled against the `api_stability.md`
  frozen stable module list, NOT the current stale `mix.exs`):
  ```elixir
  groups_for_modules: [
    "Core API": [Rulestead, Rulestead.Context, Rulestead.Result, Rulestead.Error],
    "Runtime (cached lookup)": [Rulestead.Runtime],
    "Testing": [Rulestead.TestHelpers],
    "Behaviours & Seams": [Rulestead.Store, Rulestead.Admin.Policy],
    "Store Adapters": [Rulestead.Store.Ecto, Rulestead.Store.Redis],
    "Telemetry & Config": [Rulestead.Telemetry, Rulestead.Config]
  ]
  ```
- **D-02 (USER-CONFIRMED, deviates from ROADMAP criterion-2's literal "5"):** Render
  `Rulestead.TestHelpers` as a 6th **"Testing"** group. It is a contracted "Supported adopter
  facade" (`api_stability.md:97-99`) but is currently `@moduledoc false` → invisible. Leaving it
  hidden recreates the exact "public-but-invisible" defect this milestone exists to kill. Flip its
  `@moduledoc false` → real `@moduledoc`. **Treat criterion-2 as satisfied-with-correction (6 not
  5); the planner/verifier should not flag the count.** Consider amending ROADMAP criterion-2 text
  to "6 module groups" (see Deferred).
- **D-03 (prerequisite un-hides, additive):** Flip `Rulestead.Telemetry` (`telemetry.ex:3`) and
  `Rulestead.Config` (`config.ex:2`) from `@moduledoc false` → real `@moduledoc`. Without this the
  "Telemetry & Config" group renders empty. Same "render the already-frozen surface" rule Phase 124
  used for Context/Runtime/Admin.Policy (already un-hidden). Confirm both are in `api_stability.md`
  before flipping (they are, L77+).
- **D-04 (latent-bug fix — do regardless):** Delete `Rulestead.Rule` from `mix.exs:126`. **That
  module does not exist** (the module is `Rulestead.Ruleset.Rule`); it is a dangling
  reference. Also drop `Rulestead.Ruleset` and `Rulestead.Flag` from the group — none are in the
  frozen stable module list.
- **D-05 (do NOT group):** `Rulestead.Tenancy` is **NOT** in the stable module list (only the
  `tenancy.module` *config key* is public, `api_stability.md:441`). Keep it OUT of "Behaviours &
  Seams" and out of all groups — grouping it would overstate the 1.0 contract.

### B. Extras groups + funnel order — `groups_for_extras` / `extras:` (DOC-01) (LOCKED)
- **D-06 (⚠️ first-match footgun — use EXPLICIT LIST, Ash idiom):** ExDoc assigns each extra to the
  **first matching `groups_for_extras` entry**. `upgrading.md` physically lives at
  `guides/introduction/upgrading.md`, so a broad `~r"guides/introduction/"` Introduction regex
  swallows it before "API & Stability" can. Defuse by construction with an **explicit ordered file
  list** for "API & Stability", placed **first** in the keyword list:
  ```elixir
  groups_for_extras: [
    "API & Stability": ["../guides/api_stability.md",
                        "../guides/introduction/upgrading.md",
                        "../guides/cheatsheet.cheatmd"],
    "Introduction": ~r"guides/introduction/",
    "Concepts & Guides": ~r"guides/flows/",   # label, not internal "Flows" vocab
    "Recipes": ~r"guides/recipes/",
    "Contributing": ~r"CONVENTIONS"
  ]
  ```
- **D-07:** `extras:` in onboarding-funnel order: README → **why-rulestead.md (NEW, first concept)**
  → installation → getting-started → phoenix-integration-spine → domain_language → product-boundary
  → (other introduction) → flows/* → recipes/* (cookbook early, troubleshooting last per GUIDES.md)
  → api_stability → upgrading → cheatsheet → CONVENTIONS. (Full ordered list in HEXDOCS.md §1.3 +
  the IA-research report; promoting `api_stability.md` into its own first-class group is the
  highest-leverage change — SemVer truth IS the 1.0 pitch.)
- **D-08 (executor check):** `guides/recipes/telemetry.md` exists on disk but is NOT in `extras:`
  (only `flows/telemetry.md` is). Planner decides: add it, or leave it (recommend leave — avoid a
  duplicate telemetry surface). Verify sidebar **render** order after first `mix docs` (ExDoc orders
  groups by first appearance, not keyword order).

### C. Asset wiring + `files:` manifest (DOC-02) — SYMLINK approach (LOCKED, empirically proven)
- **D-09 (⚠️CORRECTS-HEXDOCS D6/D7/D9 — `../` in `files:` is BROKEN):** A real `mix hex.build`
  proved that `"../brandbook/..."` in `files:` leaks an **absolute** path into the tarball
  (`Path.relative_to/2` returns the abs path unchanged for files outside the package root) → the
  logo 404s. **Do NOT use `../` tokens in `files:`.** Instead:
  1. Commit a symlink per package: `ln -sfn ../brandbook rulestead/brandbook` and
     `ln -sfn ../brandbook rulestead_admin/brandbook` (`git add` stores them as symlinks; verified
     not gitignored). Keeps `brandbook/` the single source of truth.
  2. Add **plain-relative, no-`../`** narrow globs to each `files:`:
     `brandbook/assets/logo/*.svg brandbook/assets/specimens/readme-header.svg`
     (the `*.svg` glob cleanly excludes `.DS_Store`, `svgo.config.mjs`, `concepts/`).
  3. `docs:` uses **plain-relative** paths (no `../`):
     ```elixir
     logo: "brandbook/assets/logo/rs-mark.svg",        # rs-mark is square (viewBox 0 0 62 62) — correct for 48px slot
     favicon: "brandbook/assets/logo/rs-favicon.svg",
     assets: %{"brandbook/assets/logo" => "assets"},
     ```
- **D-10 (verification gate — MANDATORY before any publish):** Add a tarball-content assertion to
  CI (extend/mirror `scripts/ci/check_package_whitelist.sh`, which already does `tar` inspection and
  is **safe as-is** — `brandbook/` paths trip neither cross-package grep). Assert the tarball
  contains **real SVG bytes** (not a dangling symlink): `mix hex.build` → extract
  `brandbook/assets/logo/rs-mark.svg` → confirm `<svg ... viewBox="0 0 62 62">`. Gate this in CI so
  a missing/broken symlink fails the build, not production (recall: merge-to-main auto-publishes to
  hex.pm with NO human gate).
- **D-11 (fallback):** If a CI runner can't materialize committed symlinks (`core.symlinks=false`),
  fall back to a `mix.exs` `aliases` copy-on-build step staging `brandbook/assets/logo/*.svg` into a
  package-local dir before `hex.build`. Symlink is preferred (narrower, no build machinery).
- **D-12 (no `../guides` in `files:`):** Do NOT add `../guides` to `files:`. Root guides render on
  hexdocs.pm because docs are **built locally and uploaded** (`mix hex.publish docs`), not rebuilt
  from the tarball — so `extras: "../guides/..."` works off-disk without being in the tarball
  (already proven for the core package today). Only the **README header SVG** must be in the tarball
  (for the hex.pm package page), which D-09 covers.

### D. Theming — `before_closing_head_tag` (DOC-03) — ExDoc 0.40 `--main*` re-tint (LOCKED)
- **D-13 (⚠️CORRECTS-HEXDOCS §1.5 — installed ex_doc is 0.40.3, NOT 0.38):** HEXDOCS.md's snippet
  targets `--main-color-darkened` / `--code-link-color` / `--main-background` — **these do not exist
  in ex_doc 0.40.x** and silently no-op. The correct, version-stable override (grepped from
  `deps/ex_doc/formatters/html/dist/html-elixir-*.css`) re-tints the **`--main*` HSL family**, which
  cascades to links, sidebar accent, search, AND focus rings:
  ```elixir
  defp before_closing_head_tag(:html) do
    """
    <meta property="og:title" content="Rulestead — Runtime decisions, made clear.">
    <meta property="og:description" content="Elixir-native feature flags, experimentation, and remote config — deterministic, explainable runtime decisions for Phoenix.">
    <meta property="og:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.png">
    <meta property="og:type" content="website">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.png">
    <style>
      :root {
        --main:        hsl(203, 42%, 39%);  /* #3A6F8F Stead Blue */
        --mainDark:    hsl(202, 47%, 33%);  /* #2d5f7c */
        --mainDarkest: hsl(207, 49%, 19%);  /* #183247 ink */
        --mainLight:   hsl(202, 29%, 49%);  /* #5885a0 */
        --mainLightest:hsl(202, 29%, 60%);
        --searchBarFocusColor: #3A6F8F;
        --searchBarBorderColor: rgba(58, 111, 143, .25);
      }
      .dark {
        --main:        hsl(202, 29%, 49%);  /* #5885a0 */
        --mainDark:    hsl(203, 36%, 45%);  /* #4a7d9c */
        --mainDarkest: hsl(203, 42%, 39%);  /* #3A6F8F */
        --mainLight:   hsl(203, 36%, 60%);
        --mainLightest:hsl(202, 29%, 72%);  /* AA on dark surface */
      }
    </style>
    """
  end
  defp before_closing_head_tag(:epub), do: ""
  ```
  Source values from `brandbook/tokens.css`. Implementation-time check: re-grep the actual installed
  `deps/ex_doc` CSS for the `--main*` var names (they can drift between minors) before locking.
- **D-14 (⚠️CORRECTS-HEXDOCS):** **Drop** HEXDOCS.md's manual
  `a:focus-visible{outline:2px solid #3A6F8F}` block — ExDoc 0.40 already ships
  `outline: 2px solid var(--main)`, so re-tinting `--main` (D-13) gives an on-brand AA focus ring
  for free, with broader control coverage. A manual block would fight ExDoc's rule and risk double
  outlines.
- **D-15 (⚠️CORRECTS-HEXDOCS — OG image must be PNG):** `og:image`/`twitter:image` point at
  `rs-social-card.png` (rasterized), NOT the `.svg`. Slack/Twitter/Facebook unfurlers do not render
  SVG OG images → blank unfurl. (Rasterization in D-19.)
- **D-16 (restraint, on-brand):** No theme JS, no custom stylesheet file (inline `<style>` + meta
  only), `:epub` → `""`. Ember Copper (`#9b5931`) is NOT wired into doc-chrome links (0.40 has no
  code-link var; copper stays the asset/logo color). Verified: Oban/Ash/Phoenix don't re-tint vars
  at all — this `--main*` re-tint is *more* branded than the exemplars while staying in their
  restraint envelope.

### E. why-rulestead.md (DOC-04) (LOCKED)
- **D-17:** NEW `guides/introduction/why-rulestead.md` (confirmed absent), first Introduction extra,
  sourced from `brandbook/brand-book.md` §4 (problem narrative), §6 (differentiation + "What
  Rulestead is not"), §7 (messaging pillars) + POSITIONING.md — **NOT** a README quickstart
  duplicate. Structure (one screen, ≤2 small tables): tagline → problem → "why the usual answers
  fall short" → what-you-get → 60-sec mental model → **payload-first vs cached-lookup table** →
  **"What Rulestead is — and is not" (boundary above the fold, link product-boundary.md)** →
  "will this be maintained?" (SemVer/deprecation/runbook) → next steps.
- **D-18 (brand guardrail):** Frame competition as *the in-house build* and *outgrowing booleans* —
  **NEVER** named vendors, NO comparison matrix (brand-book §6/§24, POSITIONING.md D11). Voice:
  calm, low-hype. Make this the single canonical positioning source (reused condensed in the future
  ElixirForum tl;dr).

### F. README hero + badges + social card (DOC-05) (LOCKED)
- **D-19 (social-card rasterization):** Generate `rs-social-card.png` (1200×630, GitHub/OG spec —
  `rs-social-card.svg` already has `viewBox="0 0 1200 630"`) via the repo's established
  **headless-Chrome HTML→PNG** path (`scripts/gen_brandbook_html.py` pattern; MEMORY
  `brandbook-visual-rendering` — fetch fonts with `curl`, NOT urllib which hangs on gstatic). Best
  practice: if the card SVG embeds the wordmark as live `<text>`, flatten to `<path>` first (repo
  has `gen_wordmark_paths.py`) so ANY rasterizer is font-exact. PNG → `brandbook/assets/logo/`,
  shipped via `assets:`, set as GitHub repo Social-preview, referenced in OG meta (D-15).
- **D-20:** Root README centered hero using `rs-wordmark-tagline.svg` (viewBox 0 0 340 96 —
  wordmark+tagline in one asset) + a centered **5-badge** row, each wrapped in `<a>` (clickable):
  Hex version (`img.shields.io/hexpm/v/rulestead`) · HexDocs (`badge/hex-docs`, tint `3A6F8F`) · CI
  (`actions/workflows/ci.yml/badge.svg` — **verify the workflow filename** under `.github/workflows`
  before committing the URL) · License (`hexpm/l/rulestead`, self-healing from metadata) · Elixir
  version (`badge/elixir-~%3E%201.17`, tint `9b5931`). Never hardcode the version badge. Keep the
  `~> 1.0` install snippet (Phase 125 already bumped); the "two version lines" callout is already
  deleted (Phase 125).

### G. rulestead_admin parity (DOC-06) (LOCKED)
- **D-21 (docs config parity):** Expand `rulestead_admin/mix.exs` `docs:` (currently bare) to mirror
  core: same `logo`/`favicon`/`assets` (via its own committed symlink + plain-relative paths, D-09),
  a **duplicated** `before_closing_head_tag/1` (the two mix.exs can't share code — copy the EXACT
  0.40 `--main*` snippet from D-13; only `og:image`/`twitter:image` change to
  `hexdocs.pm/rulestead_admin/assets/rs-social-card.png`). Add `brandbook/assets/logo/*.svg` to admin
  `files:`. `extras:` += `../guides/flows/admin-ui.md`, `../guides/flows/explainability.md` (both
  confirmed to exist) grouped as **"Operator Guides"** (`~r"guides/flows/"`). `groups_for_modules:
  ["Public Admin Seam": [RulesteadAdmin.Router]]`. Do NOT pull rollout/telemetry guides (those are
  core's, avoid a drift-prone duplicate surface).
  > ⚠️ Reconciliation: Agent D's draft admin snippet used the OLD `--link-color`/`--code-link-color`
  > vars and `../` `files:` — both superseded by D-13 (use `--main*`) and D-09 (symlink, no `../`).
- **D-22 (`RulesteadAdmin.Router` @moduledoc):** Replace `@moduledoc false` (`router.ex:2`) with a
  real `@moduledoc` that teaches mounting and — the differentiator the exemplars (Oban Web,
  LiveDashboard) both UNDER-document — leads with **host-owns-auth**. Structure: 1-line intro →
  copy-paste `scope`/`pipe_through`/`rulestead_admin "/flags", policy: ...` snippet → **"What you
  must provide" checklist** (browser pipeline w/ session+CSRF, required `policy:`, auth in front of
  the scope, session keys) → **Options** (`:policy` required, `:mount_path`) → **Session keys read
  from host** (use the three CONTRACTED names verbatim from `api_stability.md:464-468`:
  `"current_actor"`, `"rulestead_admin_environments"`, `"rulestead_admin_last_env"`; tenant keys
  documented as *optional*) → **Boundary** (internal Live/Components/DOM/CSS not in the 1.x promise).
  Add a concise `@doc` on the `rulestead_admin/2` macro (not a moduledoc duplicate).
- **D-23 (autolink footguns for `--warnings-as-errors` gate):** Backtick only public symbols
  (`` `Rulestead.Admin.Policy` `` resolves cross-package — safe). **Never** backtick
  `RulesteadAdmin.Live.*`, `RulesteadAdmin.Components.*`, or `live_session/3` (all hidden →
  undefined-reference warning fails the gate). Add `@doc false` to BOTH `__using__/1` and
  `live_session/3` in `router.ex` so they neither render nor autolink. Add a
  `skip_code_autolink_to` guard for stray `RulesteadAdmin.Live.` mentions as belt-and-suspenders.

### Claude's Discretion
- Exact full `extras:` ordering within each group (follow HEXDOCS.md §1.3 + IA report); D-08
  telemetry-recipe call; precise prose of why-rulestead.md and the Router @moduledoc (skeletons in
  research reports are the template); exact badge label casing.

### Folded Todos
None — `todo.match-phase 126` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/HEXDOCS.md` — baseline config (module groups, extras, theming, README) —
  **READ WITH 3 CORRECTIONS APPLIED:** §1.5 var names wrong for ex_doc 0.40 (use D-13 `--main*`);
  D6/D7/D9 `../` `files:` forms broken (use D-09 symlink); OG image must be PNG (D-15).
- `guides/api_stability.md` — the **frozen 1.x contract**; stable module list (~L64-105) is the
  source of truth for module-group membership; Required Host Session Keys (~L464-468) for D-22.
- `.planning/research/POSITIONING.md`, `.planning/research/GUIDES.md` — positioning + guide ordering.
- `brandbook/tokens.css` — **authoritative mineral palette** (hex → HSL values in D-13).
- `brandbook/brand-book.md` — Why-Rulestead narrative source (§4/§6/§7) + voice guardrails.
- `prompts/rulestead-brand-book.md` — older brand reference; **`brandbook/` supersedes on conflict**.
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — funnel/persona basis for extras order + Why.
- `prompts/rulestead-admin-ux-and-operator-ia.md`, `prompts/rulestead-host-app-integration-seam.md`
  — operator persona + host-owns-auth framing for the Router @moduledoc (D-22).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/assets/logo/` — `rs-mark.svg` (square 62×62 → `logo:`), `rs-favicon.svg` (→ `favicon:`),
  `rs-wordmark-tagline.svg` (340×96 → README hero), `rs-social-card.svg` (1200×630 → rasterize to
  PNG), plus dark/mono variants + `concepts/` (excluded by the `*.svg` glob being non-recursive).
- `brandbook/assets/specimens/readme-header.svg` — alt README header.
- `scripts/gen_brandbook_html.py` — headless-Chrome HTML→PNG pattern for D-19 rasterization;
  `gen_wordmark_paths.py`/`gen_glyph_paths.py` — flatten text→path for font-exact rasterizing.
- `deps/ex_doc/formatters/html/dist/html-elixir-*.css` — authoritative ex_doc **0.40.3** CSS var
  source (re-grep at implementation time to confirm `--main*` names).

### Established Patterns
- `scripts/ci/check_package_whitelist.sh` — existing tarball-inspection + cross-package whitelist
  guard; **safe as-is** (brandbook/ root paths trip neither grep); extend it for the D-10 content
  assertion. Matches CLAUDE.md "scripts-first CI" posture.
- Phase 124 precedent: render contracted-but-hidden modules (Context/Runtime/Admin.Policy already
  un-hidden); "documenting an existing contract symbol ≠ new API". D-02/D-03 extend the same rule.
- Phase 125: version-truth swept, README "two version lines" callout already deleted, `~> 1.0`
  install snippets already in place.
- Both packages pin `ex_doc ~> 0.38` in mix.exs but resolve to **0.40.3** — theming must target 0.40.

### Integration Points
- `rulestead/mix.exs` — `docs/0` (groups L122-147, extras L92-121), `package` `files:` (~L81-82).
- `rulestead_admin/mix.exs` — bare `docs:` (~L70-78), `files:` (~L66).
- `rulestead_admin/lib/rulestead_admin/router.ex` — `@moduledoc false` (L2), `rulestead_admin/2`
  macro, `__using__/1` + `live_session/3` (need `@doc false`), `Map.take` session keys (~L88-95).
- `guides/flows/admin-ui.md`, `guides/flows/explainability.md` — admin extras (confirmed exist).
- New file: `guides/introduction/why-rulestead.md`. New artifact: `brandbook/assets/logo/rs-social-card.png`.
- New committed symlinks: `rulestead/brandbook`, `rulestead_admin/brandbook` → `../brandbook`.
</code_context>

<specifics>
## Specific Ideas

- **6 module groups, not 5** (D-02, user-confirmed) — render the contracted `TestHelpers` facade.
- **Symlink-based asset shipping** (D-09) is empirically proven against a real `mix hex.build`;
  `../` in `files:` is the 404 trap — do not use it.
- **ExDoc 0.40 `--main*` re-tint** (D-13) supersedes HEXDOCS.md's 0.38 snippet; OG image = PNG.
- Router @moduledoc's distinguishing move (D-22): the **"What you must provide" + host-owns-auth**
  section that Oban Web and LiveDashboard both omit — the operator-trust differentiator.
</specifics>

<deferred>
## Deferred Ideas

- **Amend ROADMAP criterion-2 wording "5 → 6 module groups"** to match D-02 (or note the
  satisfied-with-correction). Small doc edit; planner or a STATE/roadmap-hygiene pass can apply it.
- **Move `upgrading.md` → `guides/upgrading/`** (Oban model) to make the extras regex trivial —
  right long-term, wrong phase (touches every inbound link). Deferred; D-06 explicit-list defuses
  the footgun for now.
- **`guides/recipes/telemetry.md` in extras** (D-08) — executor decision; recommend leave out.

### Reviewed Todos (not folded)
None — no todo matches for this phase.
</deferred>
</content>
</invoke>
