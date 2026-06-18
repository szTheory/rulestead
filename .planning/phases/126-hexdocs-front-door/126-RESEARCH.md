# Phase 126: HexDocs Front Door - Research

**Researched:** 2026-06-18
**Domain:** ExDoc 0.40 packaging + theming, Hex tarball asset shipping, brand wiring for two sibling Hex packages
**Confidence:** HIGH

## Summary

Phase 126 is **mechanical wiring, not design** — it lands the already-frozen v1.15 brand assets and the
already-frozen 1.x API contract into the published HexDocs of both `rulestead` and `rulestead_admin`.
The hard research was done in `126-CONTEXT.md` (23 locked decisions D-01..D-23, with a 4-agent gray-area
pass that produced **three empirically-proven corrections** to the older `.planning/research/HEXDOCS.md`
baseline). This RESEARCH.md **consolidates those decisions into an implementation-ready map** and
**verifies the five build-time-check items** the decisions flagged. **No decision was re-opened.** All five
verifications came back confirming the decisions; one *refinement* (dark-mode selector specificity) and one
*simplification* (social-card rasterization) are flagged below for the planner.

**Primary recommendation:** Execute D-01..D-23 verbatim. The only adjustments are (a) use the
`body.dark` selector (not `.dark`) for the dark-mode `--main*` override to match ExDoc 0.40.3's exact
specificity, and (b) rasterize the social card with `npx @resvg/resvg-js` (the card SVG is already pure
`<path>`, so no HTML wrapper or text-flatten step is needed; headless-Chrome is the documented fallback).

**This is a no-new-API milestone.** Every `@moduledoc false` flip (D-02/D-03/D-22) renders an
**already-frozen** `api_stability.md` contract symbol more truthfully (Phase 124 precedent). None widens
the public surface.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Module grouping / extras IA | Build config (`mix.exs docs/0`) | — | ExDoc reads `docs:` at `mix docs` time |
| Asset shipping (logo/favicon in tarball) | Package manifest (`mix.exs package files:`) + committed symlink | CI gate (`check_package_whitelist.sh`) | `mix hex.build` tarball is the launch-day source of truth |
| HexDocs theming | Doc chrome (ExDoc `before_closing_head_tag/1`) | `brandbook/tokens.css` (value source only) | CSS-var re-tint cascades through ExDoc's own rules |
| Positioning narrative | Content (`guides/introduction/why-rulestead.md`) | `brandbook/brand-book.md` (source) | Extra page, not code |
| README hero + badges | Repo docs (`README.md` files) | shields.io / GitHub Actions (live badge targets) | hex.pm package page + GitHub render this |
| Social card raster | Build artifact (`brandbook/assets/logo/rs-social-card.png`) | OG meta in head-tag | Unfurlers need PNG; GitHub social-preview slot |
| Admin Router contract doc | Code (`router.ex @moduledoc`) | `api_stability.md` (session keys) | Renders the frozen host-owns-auth seam |

## User Constraints (from CONTEXT.md)

### Locked Decisions
The 23 decisions D-01..D-23 in `126-CONTEXT.md` are **locked** and must be implemented verbatim. The
high-leverage ones, condensed:

- **D-01/D-02:** Exactly **6** module groups (Core API · Runtime (cached lookup) · Testing ·
  Behaviours & Seams · Store Adapters · Telemetry & Config). The 6th "Testing" group renders
  `Rulestead.TestHelpers` (a contracted adopter facade currently hidden). **ROADMAP criterion-2 says "5"
  — treat as satisfied-with-correction (6 not 5); do NOT flag the count.**
- **D-03:** Flip `Rulestead.Telemetry` + `Rulestead.Config` `@moduledoc false` → real `@moduledoc` (both in
  `api_stability.md`), else "Telemetry & Config" renders empty.
- **D-04:** Delete the dangling `Rulestead.Rule` from `mix.exs` (module does not exist); drop
  `Rulestead.Ruleset` + `Rulestead.Flag` from groups (not in frozen stable list).
- **D-05:** Keep `Rulestead.Tenancy` out of all groups (only the config *key* is public).
- **D-06:** Use an **explicit ordered file list** for "API & Stability" group placed **first** in
  `groups_for_extras` (defuses the first-match regex footgun where Introduction would swallow `upgrading.md`).
- **D-07:** `extras:` in onboarding-funnel order; promote `api_stability.md` to its own first-class group.
- **D-09 (CORRECTS-HEXDOCS):** Do **NOT** use `../` tokens in `files:` (leaks an absolute tarball path →
  logo 404). Use a **committed symlink** per package + plain-relative narrow `*.svg` globs.
- **D-10:** MANDATORY CI tarball-content assertion (real SVG bytes, not a dangling symlink) before any publish.
- **D-13 (CORRECTS-HEXDOCS):** Re-tint the ExDoc 0.40 `--main*` HSL family (NOT the dead 0.38
  `--main-color-darkened`/`--code-link-color`/`--main-background` names).
- **D-15 (CORRECTS-HEXDOCS):** OG image must be **PNG**, not SVG.
- **D-17/D-18:** New `guides/introduction/why-rulestead.md`, sourced from brandbook narrative, NOT a README
  duplicate; never name vendors / no comparison matrix.
- **D-19:** Rasterize `rs-social-card.png` (1200×630).
- **D-20:** README centered hero + 5-badge clickable row; never hardcode the version badge.
- **D-21/D-22/D-23:** `rulestead_admin` docs parity; real `RulesteadAdmin.Router` `@moduledoc` leading with
  host-owns-auth; `@doc false` on `__using__/1` + `live_session/3`; backtick only public symbols.

### Claude's Discretion
- Exact full `extras:` ordering within each group (follow HEXDOCS.md §1.3 + IA report).
- D-08 telemetry-recipe call (recommend **leave out** `guides/recipes/telemetry.md` — avoid duplicate surface).
- Precise prose of `why-rulestead.md` and the Router `@moduledoc` (skeletons in research reports are the template).
- Exact badge label casing.

### Deferred Ideas (OUT OF SCOPE)
- Amend ROADMAP criterion-2 "5 → 6 module groups" (small doc-hygiene edit; not blocking).
- Move `upgrading.md` → `guides/upgrading/` (Oban model) — right long-term, wrong phase (touches every link).
- Adding `guides/recipes/telemetry.md` to extras (D-08; recommend leave out).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | `docs:` 6 module groups + 6 extras groups + funnel order | D-01..D-08; verified module/group state below |
| DOC-02 | Logo/favicon/assets wired + `brandbook/assets/logo` in `files:`, no 404 | D-09..D-12; symlink + tarball gate verified |
| DOC-03 | `before_closing_head_tag` re-tints CSS vars + OG meta, no JS | D-13..D-16; `--main*` var names verified in installed CSS |
| DOC-04 | "Why Rulestead?" first Introduction extra, brandbook-sourced | D-17/D-18; absence of file verified |
| DOC-05 | README hero + 5 badges + `~> 1.0` snippet + rasterized social card | D-19/D-20; asset viewBoxes + `ci.yml` filename verified |
| DOC-06 | `rulestead_admin` parity + real Router `@moduledoc` + admin flow guides | D-21..D-23; admin extras + session keys verified |

---

## Build-Time Verification Results (the value-add)

All five flagged items were re-checked against the live codebase on 2026-06-18.

### V1 — ExDoc version + CSS var names — D-13 CONFIRMED [VERIFIED: rulestead/mix.lock + deps CSS grep]

- Installed ex_doc is **0.40.3** (`mix.lock` pins `0.40.3`; `deps/ex_doc/hex_metadata.config` →
  `{<<"version">>,<<"0.40.3">>}`). `mix.exs` `~> 0.38` resolves up to 0.40.3 in both packages.
- The authoritative CSS is `rulestead/deps/ex_doc/formatters/html/dist/html-elixir-NHQLCD6Y.css`
  (hashed filename — **do not hardcode this hash anywhere; re-glob `html-elixir-*.css`**).
- **`--main*` family confirmed present** (defined once, at `:root`):
  ```
  --main:        hsl(250, 68%, 69%)
  --mainDark:    hsl(250, 68%, 59%)
  --mainDarkest: hsl(250, 68%, 49%)
  --mainLight:   hsl(250, 68%, 74%)
  --mainLightest:hsl(250, 68%, 79%)
  --searchBarFocusColor: #8E7CE6
  --searchBarBorderColor: rgba(142, 124, 230, .25)
  ```
  → D-13's re-tint targets all exist. The brand values in D-13 are correct.
- **HEXDOCS.md's dead vars confirmed absent:** grep for `--main-color-darkened`, `--code-link-color`,
  `--main-background` returned **zero hits**. D-13's CORRECTS-HEXDOCS claim is empirically true; those
  would silently no-op.
- **Cascade confirmed:** `--link-color: var(--mainDark)` (light) and `--link-color: var(--mainLightest)`
  (dark). So re-tinting `--main*` cascades to links, visited links, sidebar accent, and search **for free**.
- **D-14 confirmed:** ExDoc 0.40.3 ships `outline:2px solid var(--main)` (two occurrences). Re-tinting
  `--main` gives the on-brand AA focus ring automatically; the manual `a:focus-visible{...}` block must be
  dropped (would fight ExDoc's rule).
- ⚠️ **REFINEMENT for the planner (selector specificity — NOT a decision change):** ExDoc 0.40.3 uses
  **`body.dark{...}`** (specificity 0,1,1), not `.dark{...}` (0,1,0). ExDoc does **not** redefine `--main*`
  under `body.dark` (it derives dark link colors via `var(--mainLightest)`), so a user `.dark{--main:...}`
  override still applies with no competing same-property rule — but to be robust and match ExDoc exactly,
  **write the dark override as `body.dark { --main: ...; }`** (or `:root, body.dark { ... }`). D-13's intent
  is correct; this is a one-token hardening of the snippet. Authoritative var list to target: `--main`,
  `--mainDark`, `--mainDarkest`, `--mainLight`, `--mainLightest`, `--searchBarFocusColor`,
  `--searchBarBorderColor`.

### V2 — `../` in `files:` is broken; symlink ships real bytes — D-09/D-10/D-11 CONFIRMED [VERIFIED: script inspection]

- D-09's claim that `../brandbook/...` leaks an absolute tarball path is consistent with Hex's
  `Path.relative_to/2` behavior for out-of-root files (the 4-agent pass proved it with a real
  `mix hex.build`). **Do not use `../` tokens in `files:`.**
- **CI whitelist script is safe as-is for `brandbook/` paths [VERIFIED: `scripts/ci/check_package_whitelist.sh`]:**
  its only cross-package guards are `grep -q "^rulestead_admin/"` (in the core tarball) and
  `grep -q "^rulestead/"` (in the admin tarball). `brandbook/...` paths start with neither prefix → no trip.
  D-10's "safe as-is" is confirmed. The script already does `mix hex.build` + `tar tzf` inspection, so the
  D-10 content assertion extends an existing pattern cleanly.
- **Symlink target state [VERIFIED]:** `rulestead/brandbook` and `rulestead_admin/brandbook` do **not** exist
  yet (to be created via `ln -sfn ../brandbook ...` + `git add`). `git check-ignore` confirms `brandbook/` is
  **not gitignored** — symlinks will commit and store as symlinks.
- **D-11 fallback note (CI runner `core.symlinks=false`):** keep the `aliases` copy-on-build fallback in the
  planner's back pocket. GitHub-hosted Linux runners materialize committed symlinks by default, but document
  the fallback so a future runner change can't silently 404 production. Symlink is preferred (narrower).
- **D-10 assertion target:** after `mix hex.build`, extract `brandbook/assets/logo/rs-mark.svg` from the
  tarball and assert it contains `viewBox="0 0 62 62"` (real SVG bytes, not a 0-byte dangling-symlink entry).

### V3 — Guide-file inventory — D-07/D-17/D-21 CONFIRMED [VERIFIED: `ls guides/`]

- `guides/introduction/` (8 files): `adoption-lab.md`, `domain_language.md`, `getting-started.md`,
  `installation.md`, `phoenix-integration-spine.md`, `product-boundary.md`, `upgrading.md`,
  `user-flows-and-jtbd.md`. **`why-rulestead.md` is ABSENT** (confirmed — to be created, D-17).
- `guides/flows/` (9 files): `admin-ui.md` ✓, `evaluation.md`, `explainability.md` ✓, `extending-rulestead.md`,
  `flag-lifecycle.md`, `multi-env.md`, `rollout.md`, `rulesets.md`, `telemetry.md`. Both admin extras
  (`admin-ui.md`, `explainability.md`) **EXIST** (confirmed for D-21).
- `guides/recipes/` (8 files): `context-propagation.md`, `deployment.md`, `ecto-conventions.md`, `footguns.md`,
  `migrating-from-funwithflags.md`, `oban-background-jobs.md`, **`telemetry.md` (present but NOT in `extras:`)**,
  `testing.md`. D-08: recommend **leave `recipes/telemetry.md` out** (only `flows/telemetry.md` is in extras).
- `guides/` root: `api_stability.md`, `cheatsheet.cheatmd`.
- **Landmine for D-06:** `upgrading.md` physically lives at `guides/introduction/upgrading.md` — a broad
  `~r"guides/introduction/"` Introduction regex would swallow it before "API & Stability". The explicit
  ordered list (D-06) for "API & Stability", placed first, is the fix.
- **Sidebar render-order caveat:** ExDoc orders extras groups by **first appearance in `extras:`**, not by
  `groups_for_extras` keyword order. Verify the rendered sidebar after the first `mix docs` (D-08).

### V4 — `@moduledoc false` state + module existence — D-02/D-03/D-04/D-22 CONFIRMED [VERIFIED: grep]

| Symbol | File:Line | Current state | Action |
|--------|-----------|---------------|--------|
| `Rulestead.TestHelpers` | `rulestead/lib/rulestead/test_helpers.ex:2` | `@moduledoc false` | Flip → real `@moduledoc` (D-02) |
| `Rulestead.Telemetry` | `rulestead/lib/rulestead/telemetry.ex:3` | `@moduledoc false` | Flip → real `@moduledoc` (D-03) |
| `Rulestead.Config` | `rulestead/lib/rulestead/config.ex:2` | `@moduledoc false` | Flip → real `@moduledoc` (D-03) |
| `RulesteadAdmin.Router` | `rulestead_admin/lib/rulestead_admin/router.ex:2` | `@moduledoc false` | Replace → real `@moduledoc` (D-22) |
| `Rulestead.Rule` | referenced `rulestead/mix.exs:126` | **module does NOT exist** | Delete reference (D-04 latent-bug fix) |
| `Rulestead.Ruleset.Rule` | `rulestead/lib/rulestead/ruleset/rule.ex` | exists (the real module) | not grouped |
| `Rulestead.Ruleset` | `rulestead/lib/rulestead/ruleset.ex` | exists | drop from group (not in stable list, D-04) |
| `Rulestead.Flag` | `rulestead/lib/rulestead/flag.ex` | exists | drop from group (not in stable list, D-04) |

- **Nuance for D-04:** `Rulestead.Rule` is genuinely dangling (no such module — the real one is
  `Rulestead.Ruleset.Rule`). `Rulestead.Ruleset` and `Rulestead.Flag` **do** exist as modules but are
  excluded from groups because they are not in the frozen stable list. Both removals are correct, for
  different reasons.

### V5 — Social-card rasterization — D-19 CONFIRMED + SIMPLIFIED [VERIFIED: SVG grep + MEMORY]

- `brandbook/assets/logo/rs-social-card.svg` has `viewBox="0 0 1200 630"` (correct GitHub/OG spec).
- **It contains 0 `<text>` elements** and uses `<path>` — **the wordmark is already flattened to paths.**
  So D-19's precautionary `gen_wordmark_paths.py` text-flatten step is **NOT needed** for the card; any
  rasterizer will be font-exact.
- `rs-social-card.png` is **ABSENT** (confirmed — to be generated, D-19).
- **No turnkey SVG→PNG helper exists.** `scripts/gen_brandbook_html.py` (2881 lines) is an *HTML generator*,
  not a rasterizer — it produces HTML that the documented headless-Chrome flow renders to PNG/PDF.
- ⚠️ **SIMPLIFICATION for the planner (not a decision change):** the repo's own MEMORY
  `brandbook-visual-rendering` says *"do NOT use ImageMagick for SVG→PNG … prefer `npx @resvg/resvg-js`."*
  Because the card is already pure-`<path>` SVG, the cleanest rasterization is:
  `npx @resvg/resvg-js rs-social-card.svg --width 1200 --height 630 -o rs-social-card.png` (or the JS API) —
  **no HTML wrapper, no Chrome, no font-fetch, no text-flatten.** The headless-Chrome HTML→PNG path
  (`--headless=new --screenshot --window-size=1200,630`, fonts via `curl` not urllib) remains the documented
  fallback if resvg is unavailable on the build host. D-19's *intent* (1200×630 PNG via an established repo
  path) is satisfied either way.
- PNG → `brandbook/assets/logo/`, shipped via `assets:` (D-09), referenced in OG meta (D-15), set as the
  GitHub repo Social-preview.

---

## Standard Stack

### Core (already installed — no new deps)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ex_doc` | **0.40.3** (pinned `~> 0.38`, resolved) [VERIFIED: mix.lock] | HexDocs generation, theming, autolink gate | The Elixir-ecosystem doc standard |

### Supporting (build-time tooling, not Hex deps)
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `@resvg/resvg-js` (npx) | SVG→PNG rasterization of the social card | D-19 (preferred — card is pure-path) |
| Headless Chrome (`--headless=new`) | HTML→PNG fallback rasterizer | D-19 fallback only; per MEMORY `brandbook-visual-rendering` |
| `shields.io` | live README badges (Hex version, license, etc.) | D-20 |
| `mix hex.build` + `tar` | tarball content assertion | D-10 CI gate |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| committed symlink (`files:`) | `aliases` copy-on-build | D-11 fallback; only if runner `core.symlinks=false`. Symlink is narrower, no build machinery |
| `@resvg/resvg-js` | headless-Chrome HTML→PNG | Chrome is heavier + needs fonts via curl; only needed if resvg absent |
| inline `<style>` re-tint | custom stylesheet file | D-16: restraint — inline `<style>` + meta only, matches Oban/Ash/Phoenix envelope |

**Installation:** No new Hex deps. `brandbook/` symlinks + `mix.exs` config edits only.
```bash
ln -sfn ../brandbook rulestead/brandbook
ln -sfn ../brandbook rulestead_admin/brandbook
git add rulestead/brandbook rulestead_admin/brandbook   # stores as symlinks
```

## Package Legitimacy Audit

> No external Hex packages are added in this phase. `ex_doc` is already a locked dev dependency
> (`0.40.3`, verified in `mix.lock`, 8+ years on Hex, the canonical Elixir doc tool — OK). The only
> non-Hex tool is `@resvg/resvg-js` invoked via `npx` at build time (not a project dependency, not
> shipped in either tarball). No `npm install` is added to the package manifests.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| `ex_doc` | Hex (already locked, 0.40.3) | OK | Approved — pre-existing dev dep |
| `@resvg/resvg-js` (npx, build-time only) | npm | [ASSUMED — established rasterizer, recommended by repo MEMORY] | Build tool, not a shipped/declared dep; fallback to headless-Chrome exists |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
   brandbook/  (single    │  brandbook/assets/logo/*.svg  (source of     │
   source of truth) ──────│  truth: rs-mark, rs-favicon, rs-wordmark-    │
                          │  tagline, rs-social-card.svg)                │
                          └───────────────┬──────────────────┬──────────┘
                          committed symlink│                  │ npx @resvg/resvg-js
                          ../brandbook      │                  ▼
              ┌───────────────────┐  ┌──────────────┐   rs-social-card.png (1200×630)
              │ rulestead/        │  │rulestead_admin│        │
              │  brandbook ───────┘  │  brandbook ───┘        │ shipped via assets:
              └─────────┬─────────┘  └──────┬────────┘        ▼
                        │                   │            OG meta (head-tag) + GitHub
        ┌───────────────┼───────────────────┼──────────────┐  social-preview slot
        ▼               ▼                   ▼              ▼
   mix.exs docs:   mix.exs files:    before_closing    extras: (funnel order)
   groups_for_*    brandbook/*.svg   _head_tag/1       README → why-rulestead →
   (6 modules,     (plain-relative,  (--main* re-tint  install → ... → api_stability
    6 extras)       NO ../)           + OG meta)        → CONVENTIONS
        │               │                   │              │
        ▼               ▼                   ▼              ▼
   mix docs ────►  mix hex.build ────► HexDocs HTML ──► hexdocs.pm/{rulestead,
   (--warnings-     (tarball, gated     (themed,         rulestead_admin}
    as-errors       by D-10 content     branded)         (docs built locally +
    autolink gate)  assertion + CI                        uploaded, NOT rebuilt
                    whitelist)                            from tarball — D-12)
```

Key data-flow facts (both proven in CONTEXT.md / verified here):
- **HexDocs extras render off-disk** (docs built locally + uploaded via `mix hex.publish docs`), so root
  `../guides/...` extras work without being in the tarball (D-12). Only the README header SVG + logo SVGs
  must be **in the tarball** (for the hex.pm package page) — D-09 covers that.
- The two `mix.exs` files **cannot share code** — `before_closing_head_tag/1` is duplicated verbatim, with
  only the `og:image`/`twitter:image` URLs differing (`/rulestead/` vs `/rulestead_admin/`) (D-21).

### Pattern 1: ExDoc CSS-var re-tint (no custom stylesheet) — D-13/D-16
**What:** Inline `<style>` in `before_closing_head_tag(:html)` overriding the `--main*` family at `:root`
(light) and `body.dark` (dark). Cascades to links, sidebar accent, search, focus ring.
**When to use:** Brand-tint HexDocs without forking ExDoc's theme or shipping a stylesheet file.
**Example (var names + selectors verified against installed 0.40.3 CSS; values from `brandbook/tokens.css`):**
```elixir
# Source: rulestead/deps/ex_doc/formatters/html/dist/html-elixir-*.css (verified 2026-06-18)
defp before_closing_head_tag(:html) do
  """
  <meta property="og:title" content="Rulestead — Runtime decisions, made clear.">
  <meta property="og:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.png">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:image" content="https://hexdocs.pm/rulestead/assets/rs-social-card.png">
  <style>
    :root {
      --main:        hsl(203, 42%, 39%);  /* #3A6F8F Stead Blue */
      --mainDark:    hsl(202, 47%, 33%);  /* #2d5f7c (→ --link-color light) */
      --mainDarkest: hsl(207, 49%, 19%);  /* #183247 ink */
      --mainLight:   hsl(202, 29%, 49%);  /* #5885a0 */
      --mainLightest:hsl(202, 29%, 60%);
      --searchBarFocusColor: #3A6F8F;
      --searchBarBorderColor: rgba(58, 111, 143, .25);
    }
    body.dark {                            /* ⚠️ body.dark, NOT .dark — matches ExDoc 0.40.3 specificity */
      --main:        hsl(202, 29%, 49%);  /* #5885a0 */
      --mainDark:    hsl(203, 36%, 45%);
      --mainDarkest: hsl(203, 42%, 39%);  /* #3A6F8F */
      --mainLight:   hsl(203, 36%, 60%);
      --mainLightest:hsl(202, 29%, 72%);  /* AA on dark surface (→ --link-color dark) */
    }
  </style>
  """
end
defp before_closing_head_tag(:epub), do: ""
```
**Note:** Ember Copper `#9b5931` is NOT wired into doc-chrome (0.40 has no code-link var) — copper stays the
asset/logo color (D-16). `og:image` must be the **PNG** (D-15).

### Pattern 2: Asset shipping via committed symlink (no `../` in files:) — D-09
**What:** A committed `brandbook` symlink per package + plain-relative globs in `files:`/`docs:`.
**Example:**
```elixir
# package files: — plain-relative, no ../, *.svg glob excludes .DS_Store/svgo.config.mjs/concepts/
files: ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs
          README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md
          brandbook/assets/logo/*.svg brandbook/assets/specimens/readme-header.svg)

# docs: — plain-relative
logo: "brandbook/assets/logo/rs-mark.svg",      # square viewBox 0 0 62 62 (verified) — correct for 48px slot
favicon: "brandbook/assets/logo/rs-favicon.svg", # viewBox 0 0 62 62 (verified)
assets: %{"brandbook/assets/logo" => "assets"}
```

### Anti-Patterns to Avoid
- **`"../brandbook/..."` in `files:`** — leaks an absolute tarball path → logo 404 on launch day (D-09).
- **Targeting `--main-color-darkened` / `--code-link-color` / `--main-background`** — dead vars in 0.40,
  silently no-op (D-13; verified absent).
- **Manual `a:focus-visible{outline:...}` block** — fights ExDoc's `outline:2px solid var(--main)`, risks
  double outlines (D-14; verified).
- **`.dark{--main:...}`** — lower specificity than ExDoc's `body.dark`; use `body.dark` (V1 refinement).
- **SVG `og:image`** — Slack/Twitter/Facebook unfurlers don't render SVG → blank unfurl (D-15).
- **Backticking `RulesteadAdmin.Live.*` / `.Components.*` / `live_session/3`** — hidden symbols →
  undefined-reference warning → fails the `--warnings-as-errors` gate (D-23).
- **README duplicate as why-rulestead.md** — must be brandbook-sourced positioning, not a quickstart (D-17/D-18).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Brand-tinting HexDocs | A custom stylesheet / forked theme | Re-tint `--main*` via `before_closing_head_tag` | ExDoc's own cascade does the work; restraint matches exemplars (D-16) |
| Focus-ring theming | Manual `:focus-visible` CSS | Re-tint `--main` | ExDoc already ships `outline:2px solid var(--main)` (D-14, verified) |
| SVG→PNG | ImageMagick / a hand-rolled rasterizer | `npx @resvg/resvg-js` | MEMORY: ImageMagick has no rsvg/cairo delegate here; card is pure-path (V5) |
| Shipping cross-package assets | `../` path tokens | committed symlink + relative glob | `../` leaks absolute tarball paths (D-09, verified) |
| Version badge | hardcoded version string | `img.shields.io/hexpm/v/rulestead` | self-heals from Hex metadata (D-20) |

**Key insight:** The entire phase leans on ExDoc's existing cascade and Hex's existing tarball pipeline. The
only "build" is a ~12-line inline `<style>`, a symlink, a glob, and one PNG. Every place a custom artifact was
tempting (theme JS, stylesheet, focus CSS, ImageMagick rasterizer) the decision is *don't* — restraint is on-brand.

## Common Pitfalls

### Pitfall 1: The autolink `--warnings-as-errors` release gate (D-23)
**What goes wrong:** Backticking a hidden symbol (`RulesteadAdmin.Live.*`, `live_session/3`) emits an
undefined-reference warning; Phase 124 established `mix docs --warnings-as-errors` as a release gate, so this
**fails CI**.
**How to avoid:** Backtick only public symbols (`` `Rulestead.Admin.Policy` `` resolves cross-package — safe).
Add `@doc false` to BOTH `__using__/1` and `live_session/3` in `router.ex`. Add a `skip_code_autolink_to`
guard for stray `RulesteadAdmin.Live.` mentions (belt-and-suspenders).
**Warning signs:** any `mix docs` output line containing "undefined reference".

### Pitfall 2: Merge-to-main auto-publishes to hex.pm with NO human gate
**What goes wrong:** A broken/missing symlink or `../` path 404s the logo **in production** the moment the PR
merges (MEMORY `release-pipeline-auto-publishes`).
**How to avoid:** The D-10 CI tarball-content assertion MUST gate the build — assert real SVG bytes
(`viewBox="0 0 62 62"`) extracted from the `mix hex.build` tarball, so a broken symlink fails the build, not
launch day. (Note: the actual `1.0.0` publish is Phase 128; this phase only lands the config + gate.)

### Pitfall 3: Extras first-match group assignment (D-06)
**What goes wrong:** A broad `~r"guides/introduction/"` Introduction regex swallows
`guides/introduction/upgrading.md` before "API & Stability" can claim it (ExDoc assigns each extra to the
**first** matching `groups_for_extras` entry).
**How to avoid:** Explicit ordered file list for "API & Stability", placed **first** in `groups_for_extras`.
**Warning signs:** `upgrading.md` rendering under Introduction in the sidebar.

### Pitfall 4: CI runner can't materialize committed symlinks (D-11)
**What goes wrong:** `core.symlinks=false` on a runner turns the committed symlink into a plain text file
containing `../brandbook` → tarball ships a 13-byte text "SVG" → 404.
**How to avoid:** The D-10 content assertion catches this (asserts real `<svg>` bytes). Keep the D-11
`aliases` copy-on-build fallback documented.

### Pitfall 5: README badge workflow filename drift (D-20)
**What goes wrong:** Hardcoding a wrong CI workflow filename in the badge URL → broken CI badge.
**How to avoid:** Verified the workflow file is **`ci.yml`** (`.github/workflows/ci.yml` exists) → badge URL
`actions/workflows/ci.yml/badge.svg` is correct. Never hardcode the **version** badge (use `hexpm/v/...`).

## Runtime State Inventory

> This phase is config/content wiring with no datastore/service/OS state migration. Brief inventory for
> completeness (it touches committed symlinks + a new build artifact, not runtime state):

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB/keys/collections touched | none |
| Live service config | hex.pm / HexDocs are written by the publish pipeline (Phase 128), not this phase | none here |
| OS-registered state | None | none |
| Secrets/env vars | None (no new secrets; `RULESTEAD_ADMIN_HEX_RELEASE` already exists, unchanged) | none |
| Build artifacts | NEW: `brandbook/assets/logo/rs-social-card.png` (generated); NEW committed symlinks `rulestead/brandbook`, `rulestead_admin/brandbook` | generate PNG; create + `git add` symlinks |

**The canonical question — what runtime systems still have stale state after files change?** None — the only
new "state" is the committed symlinks and the generated PNG, both produced by this phase. The published
HexDocs/hex.pm artifacts are (re)written by Phase 128's publish, not cached from a prior shape.

## Code Examples

### Admin Router @moduledoc — host-owns-auth lead (D-22, the differentiator)
```elixir
# Source: api_stability.md §"Required Host Session Keys" (L464-468, verified) + router.ex Map.take (L88-95)
# The three CONTRACTED session keys (verbatim) — tenant keys documented as OPTIONAL:
#   "current_actor", "rulestead_admin_environments", "rulestead_admin_last_env"
# (router.ex Map.take ALSO reads "rulestead_admin_tenants" / "_last_tenant" / "_default_tenant"
#  — these are NOT in the frozen contract; document them as optional, per D-22.)
@moduledoc """
Mount the Rulestead admin LiveView under a host-owned, authenticated scope.

    scope "/admin", MyAppWeb do
      pipe_through [:browser, :require_admin]   # host owns auth + session + CSRF
      rulestead_admin "/flags", policy: MyApp.RulesteadPolicy
    end

## What you must provide
- a `:browser` pipeline with session + CSRF
- your own auth in FRONT of the scope (Rulestead does not authenticate)
- a required `policy:` implementing `Rulestead.Admin.Policy`
- session keys: `"current_actor"`, `"rulestead_admin_environments"`, `"rulestead_admin_last_env"`
...
"""
```

### CI tarball content assertion (D-10) — extend check_package_whitelist.sh
```bash
# Source: pattern from scripts/ci/check_package_whitelist.sh (verified safe for brandbook/ paths)
# After `mix hex.build`, assert real SVG bytes (not a dangling symlink):
tar xOf "${core_tarball}" contents.tar.gz | tar xzO brandbook/assets/logo/rs-mark.svg \
  | grep -q 'viewBox="0 0 62 62"' \
  || { echo "logo SVG missing/empty in tarball — broken symlink?" >&2; exit 1; }
```

## State of the Art

| Old Approach (HEXDOCS.md baseline) | Current Approach (CONTEXT.md, verified) | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `--main-color-darkened`/`--code-link-color`/`--main-background` | `--main*` HSL family | ex_doc 0.40 (installed 0.40.3) | Old vars silently no-op; verified absent |
| Manual `a:focus-visible{outline}` | re-tint `--main` (ExDoc ships the outline) | ex_doc 0.40 | D-14; verified `outline:2px solid var(--main)` present |
| `../brandbook/...` in `files:` | committed symlink + relative glob | proven by real `mix hex.build` | D-09; avoids logo 404 |
| SVG `og:image` | PNG `og:image` | always (unfurler limitation) | D-15; avoids blank unfurl |

**Deprecated/outdated:** `.planning/research/HEXDOCS.md` §1.5 (0.38 var names), its D6/D7/D9 `../` `files:`
forms, and its SVG OG image — all superseded by CONTEXT.md D-13/D-09/D-15 and re-confirmed here.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `npx @resvg/resvg-js` is available/usable on the build host for D-19 | V5 / Stack | LOW — headless-Chrome HTML→PNG fallback is documented (MEMORY); D-19 intent met either way |
| A2 | GitHub-hosted runners materialize committed symlinks (`core.symlinks` default) | V2 / Pitfall 4 | LOW — D-11 `aliases` copy fallback + D-10 content assertion both catch a non-materialized symlink |
| A3 | D-13's specific dark-mode HSL values hit AA contrast on ExDoc's dark surface | Pattern 1 | LOW — values from `brandbook/tokens.css`; verify visually after first `mix docs` (UI hint: yes) |

**Note:** All *structural* claims (var names, file existence, moduledoc states, tarball-script safety, viewBox
values, workflow filename) were tool-verified this session and are NOT assumptions. Only the three operational
items above carry residual risk, all with documented fallbacks.

## Open Questions (RESOLVED)

1. **D-08: include `guides/recipes/telemetry.md` in extras?**
   - What we know: it exists on disk; only `flows/telemetry.md` is currently in `extras:`.
   - Recommendation: **leave it out** (avoid a duplicate telemetry surface). Executor's call; verify sidebar
     render order after first `mix docs`.
   - **RESOLVED:** leave out, per D-08 / plan-05 (Task 1 action explicitly LEAVES `guides/recipes/telemetry.md`
     OUT; only `flows/telemetry.md` ships).
2. **Exact dark-mode HSL fine-tuning for AA contrast (A3).**
   - What we know: D-13 provides values; ExDoc derives dark link colors from `--mainLightest`/`--mainLight`.
   - Recommendation: render `mix docs`, toggle dark mode, eyeball link/accent contrast; nudge `--mainLightest`
     lighter if needed (UI hint on this phase is **yes**).
   - **RESOLVED:** deferred to the manual UI pass per VALIDATION.md (Manual-Only Verifications: "Visual brand
     pass … link/sidebar tint in light AND dark"); D-13 values ship as-is, eyeball nudge happens in that pass.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `ex_doc` | all of DOC-01..03/06 | ✓ | 0.40.3 (locked) | — |
| `mix hex.build` | D-10 tarball gate | ✓ | (mix/hex) | — |
| committed symlink support | D-09 | ✓ (local; not gitignored) | — | D-11 `aliases` copy-on-build |
| `npx @resvg/resvg-js` | D-19 (preferred) | ✗ (verify on host) | — | headless-Chrome HTML→PNG (MEMORY) |
| headless Chrome | D-19 fallback | ✓ (macOS dev box per MEMORY) | Chrome `--headless=new` | — |
| shields.io | D-20 badges | ✓ (public CDN) | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `@resvg/resvg-js` (→ headless Chrome); symlink materialization (→ aliases copy).

## Validation Architecture

> nyquist_validation treated as enabled (no `.planning/config.json` opt-out found). This section maps each
> success criterion to a concrete proof command for VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExDoc build + shell assertions (this phase has no ExUnit deltas; existing `release_contract_test.exs` must stay green) |
| Config file | `rulestead/mix.exs` `docs/0`, `rulestead_admin/mix.exs` `docs/0` |
| Quick run command | `cd rulestead && mix docs --warnings-as-errors` |
| Full suite command | `bash scripts/ci/contributor.sh` (core) + `scripts/ci/check_package_whitelist.sh` (both tarballs) |

### Success Criterion → Proof Map
| Crit / Req | Behavior to prove | Proof command | Type |
|-----------|-------------------|---------------|------|
| Crit-1 / DOC-02 | Tarball contains real logo SVG bytes (no 404) | `cd rulestead && mix hex.build` → extract `brandbook/assets/logo/rs-mark.svg` → `grep -q 'viewBox="0 0 62 62"'` | tarball content assert (D-10) |
| Crit-1 / DOC-02 | `brandbook/assets/logo` present in `files:`; CI whitelist not tripped | `bash scripts/ci/check_package_whitelist.sh` (must print "package whitelist checks passed") | CI gate |
| Crit-2 / DOC-01 | 6 module groups + 6 extras groups + funnel order present | `mix docs` then grep generated `dist`/sidebar JSON for the 6 group labels + assert `why-rulestead` is first Introduction extra; AST/grep `mix.exs` for the 6 `groups_for_modules` + 6 `groups_for_extras` keys | grep/AST + render |
| Crit-2 / DOC-01 | No dangling module ref | `mix docs --warnings-as-errors` (zero undefined-reference) + assert `Rulestead.Rule` absent from `mix.exs` | autolink gate |
| Crit-3 / DOC-03 | Head-tag re-tints `--main*` + sets OG meta, no JS | grep `mix.exs` `before_closing_head_tag` for `--main:`, `body.dark`, `og:image .*\.png`; assert no `<script>` and no custom stylesheet file | grep |
| Crit-4 / DOC-04 | `why-rulestead.md` exists, renders, is NOT a README copy | `test -f guides/introduction/why-rulestead.md` + assert it is not byte-identical to README + appears as first Introduction extra in rendered sidebar | file + diff + render |
| Crit-5 / DOC-05 | README hero + 5 clickable badges + `~> 1.0` snippet | grep `README.md` for `rs-wordmark-tagline.svg`, the 5 badge `<a href>`s (hexpm/v, hex-docs, ci.yml, hexpm/l, elixir), and `~> 1.0`; assert no `~> 0.1` (Phase 125 guard) | grep |
| Crit-5 / DOC-05 | Social card rasterized to PNG | `test -f brandbook/assets/logo/rs-social-card.png` + assert 1200×630 dimensions | file + dimension |
| Crit-6 / DOC-06 | Admin parity: same logo/favicon/theming, real Router `@moduledoc`, admin flow guides | grep `rulestead_admin/mix.exs` for `logo`/`favicon`/`before_closing_head_tag`/`admin-ui.md`/`explainability.md`/`Public Admin Seam`; assert `router.ex:2` is NOT `@moduledoc false`; `cd rulestead_admin && RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors` | grep + autolink gate |
| Regression | Frozen contract unchanged | `release_contract_test.exs` green (both packages) | ExUnit |

### Sampling Rate
- **Per task commit:** `mix docs --warnings-as-errors` (the autolink gate — catches the D-23 footguns fast).
- **Per wave merge:** `mix hex.build` + tarball content assertion (D-10) on the touched package.
- **Phase gate:** both packages `mix docs --warnings-as-errors` green + `check_package_whitelist.sh` green +
  D-10 logo-bytes assertion green + `release_contract_test.exs` green, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `scripts/ci/` — D-10 logo-bytes tarball assertion (extend `check_package_whitelist.sh` or sibling script)
- [ ] No ExUnit additions needed; no framework install needed (ExDoc + existing CI present).

*(UI hint on this phase is **yes** → reserve a manual visual pass: render `mix docs`, confirm logo resolves,
favicon shows, mineral tint in light+dark, focus ring on-brand, social-card unfurl. This is the one
human-eyeball gate the automated checks can't fully cover, per A3.)*

## Security Domain

> `security_enforcement` treated as enabled (no `false` in config). This phase ships **no runtime code paths
> and no new inputs** — it is doc config + static assets + `@moduledoc` text. The security-relevant surface is
> narrow and mostly about not *mis-documenting* the auth contract.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | no | No user input introduced (build-time config + static SVG/MD only) |
| V6 Cryptography | no | None |
| V14 Configuration | yes (lightly) | `files:` glob must not leak unintended files; D-09 `*.svg` glob already excludes `.DS_Store`/`svgo.config.mjs`/`concepts/`. CI whitelist (`check_package_whitelist.sh`) guards cross-package leakage |
| V1 Architecture (doc accuracy) | yes | The Router `@moduledoc` (D-22) must state **host-owns-auth** correctly — under-documenting it is the trust risk the exemplars (Oban Web, LiveDashboard) fall into; mis-stating required session keys could mislead an operator's auth setup |

### Known Threat Patterns for {ExDoc/Hex packaging}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tarball ships unintended files (e.g. dotfiles, configs) | Information Disclosure | Narrow `*.svg` glob (D-09) + `check_package_whitelist.sh` tarball inspection (verified) |
| Mis-documented auth contract in Router `@moduledoc` | Spoofing / Elevation (downstream) | Lead with host-owns-auth + "What you must provide" checklist; use the 3 contracted session keys verbatim from `api_stability.md` (D-22) |
| OG/asset URLs pointing off-brand or to wrong package | Tampering (low) | Per-package `og:image` URL (`/rulestead/` vs `/rulestead_admin/`) reviewed in the duplicated head-tag (D-21) |

## Sources

### Primary (HIGH confidence)
- `126-CONTEXT.md` — 23 locked decisions D-01..D-23 (the authoritative spec for this phase)
- `rulestead/deps/ex_doc/formatters/html/dist/html-elixir-NHQLCD6Y.css` — `--main*` var names, dark
  selector form, `outline:2px solid var(--main)`, dead-var absence (grepped 2026-06-18)
- `rulestead/mix.lock` + `deps/ex_doc/hex_metadata.config` — ex_doc 0.40.3
- `scripts/ci/check_package_whitelist.sh` — cross-package grep prefixes (`brandbook/` safe)
- `guides/api_stability.md` L462-468 — contracted host session keys; stable module list
- `rulestead/lib/**` + `rulestead_admin/lib/rulestead_admin/router.ex` — `@moduledoc false` states, module existence
- `brandbook/assets/logo/*.svg` viewBoxes; `brandbook/tokens.css` mineral hexes; `.github/workflows/ci.yml`

### Secondary (MEDIUM confidence)
- `.planning/research/HEXDOCS.md` — baseline (READ WITH 3 corrections applied; superseded where noted)
- MEMORY `brandbook-visual-rendering` (resvg/headless-Chrome guidance), `release-pipeline-auto-publishes`

### Tertiary (LOW confidence)
- None — all structural claims tool-verified this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — ex_doc 0.40.3 verified in lockfile; no new deps.
- Architecture / config: HIGH — every var name, file path, moduledoc state, viewBox, and script behavior
  tool-verified against the live tree on 2026-06-18.
- Pitfalls: HIGH — each landmine corresponds to a verified fact (autolink gate, auto-publish, first-match
  regex, symlink materialization, workflow filename).
- Residual risk: LOW — confined to 3 operational items (A1-A3), all with documented fallbacks.

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 (stable; re-grep `deps/ex_doc/.../html-elixir-*.css` var names if ex_doc minor bumps).
