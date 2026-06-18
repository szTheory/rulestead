---
phase: 126-hexdocs-front-door
verified: 2026-06-18T10:00:00Z
status: human_needed
score: 12/12
behavior_unverified: 0
overrides_applied: 0
re_verification: null
human_verification:
  - test: "Run `RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors` from `rulestead_admin/` once the package is published on Hex (i.e. after rulestead@1.0.0 is live on hex.pm)"
    expected: "Exits 0 — no undefined-reference warnings from the full Hex-mode dep graph"
    why_human: "Locally the flag triggers a Hex dep fetch that fails because rulestead is not yet published. Dev-mode (`mix docs --warnings-as-errors` without the flag) exits 0 and was verified. The Hex-release gate itself can only be proven post-publish."
  - test: "Open `rulestead/doc/index.html` in a browser and toggle light/dark mode"
    expected: "Logo (`rs-mark.svg`) loads (no 404), favicon resolves, sidebar/links/focus ring are tinted Stead Blue (#3A6F8F family), dark mode applies via `body.dark` selector"
    why_human: "CSS variable cascade and runtime font/asset resolution require a browser render — `mix docs --warnings-as-errors` passing does not exercise visual rendering"
  - test: "Open `rulestead_admin/doc/index.html` in a browser and toggle light/dark mode"
    expected: "Same as core — logo/favicon resolve, Stead Blue tint, dark mode; og:image points to rulestead_admin host"
    why_human: "Admin HTML doc output requires visual inspection for theming parity"
  - test: "Paste a HexDocs page URL or a GitHub link containing the README into a social-card unfurler (e.g. https://cards-dev.twitter.com/validator or opengraph.xyz)"
    expected: "`og:image` resolves to the `rs-social-card.png` 1200x630 image and renders — not an empty/broken unfurl"
    why_human: "OG meta correctness requires a network unfurl — grep on the `<meta>` tag proves the URL is present, not that the CDN resolves it"
resolved_during_verification:
  - item: "check_version_truth.py false-positive in why-rulestead.md:148"
    resolution: "Rephrased narrative '`0.1.x`' to 'pre-1.0 Hex version line' (commit on branch). Guard re-run: VERSION TRUTH OK (34 files clean, exit 0). No script exemption needed; guard kept strict."
---

# Phase 126: HexDocs Front Door — Verification Report

**Phase Goal:** The published HexDocs for both packages present a 1.0-grade, branded, onboarding-funnel experience — with the logo resolving (no 404s), the five module groups, six extras groups, mineral-palette theming, and `rulestead_admin` docs at parity.

**Verified:** 2026-06-18T10:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

All 12 must-have truths are VERIFIED by codebase evidence. Human verification items (browser rendering, post-publish Hex-release gate, OG unfurl, and one script false-positive) are flagged below but do not indicate missing implementation.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Each package has a committed `brandbook` symlink resolving to `../brandbook` | VERIFIED | `test -L rulestead/brandbook` and `test -L rulestead_admin/brandbook` both pass; `git ls-files` confirms both tracked; `rs-mark.svg` resolves through both symlinks |
| 2 | `rs-social-card.png` exists at 1200x630 (PNG bytes, not SVG) | VERIFIED | `file brandbook/assets/logo/rs-social-card.png` reports `PNG image data, 1200 x 630, 8-bit/color RGBA, non-interlaced` |
| 3 | CI fails the build if the logo SVG is missing/dangling in the tarball | VERIFIED | `check_logo_bytes.sh` exists, is executable, passes `bash -n`, is invoked from `contributor.sh`, and passed live run: "logo SVG bytes verified in tarball" |
| 4 | `why-rulestead.md` positioning page exists, sourced from brandbook narrative, not a README duplicate, links `product-boundary.md` | VERIFIED | File exists at 159 lines; `grep -q 'product-boundary.md'` passes; `diff` with README is non-identical; no named competitor vendors found |
| 5 | README opens with centered brand hero using wordmark+tagline asset | VERIFIED | `brandbook/assets/logo/rs-wordmark-tagline.svg` at line 2; wrapped in `<div align="center">` |
| 6 | Exactly 5 clickable badges present (Hex version, HexDocs, CI, License, Elixir) | VERIFIED | 5 `<a href>` links confirmed in hero block: `hexpm/v/rulestead`, `hex-docs-3A6F8F`, `ci.yml/badge.svg`, `hexpm/l/rulestead`, `badge/elixir` |
| 7 | Version badge is shields.io-driven, never a hardcoded version string; `~> 1.0` install snippet kept; no `~> 0.1` regression | VERIFIED | `img.shields.io/hexpm/v/rulestead` present; `~> 1.0` confirmed; no `~> 0\.1` found |
| 8 | Core `mix.exs` has exactly 6 module groups, dangling `Rulestead.Rule` removed, `groups_for_extras` has "API & Stability" first with explicit file list, `why-rulestead.md` is first Introduction extra | VERIFIED | `grep -cE '"(Core API|Runtime...|Testing|Behaviours...|Store Adapters|Telemetry...)":' mix.exs` returns `6`; no `Rulestead.Rule,`; "API & Stability" at line 155 first in `groups_for_extras`; `why-rulestead.md` at line 99 (first intro extra after README) |
| 9 | `before_closing_head_tag` re-tints `--main*` at `:root` + `body.dark`, sets PNG og:image, no `<script>`, no `a:focus-visible` | VERIFIED | All grep checks pass: `before_closing_head_tag`, `defp before_closing_head_tag(:html)`, `--main:`, `body.dark`, `og:image.*rs-social-card.png`, `:epub` clause; no `<script>`, no `a:focus-visible` |
| 10 | `mix docs --warnings-as-errors` green for core | VERIFIED | Live run exits 0: "View html docs at doc/index.html" — no warnings |
| 11 | Admin docs reach parity: logo/favicon/assets, duplicated `--main*` head-tag (admin og:image host), "Operator Guides", "Public Admin Seam", no Live modules in groups | VERIFIED | All admin mix.exs greps pass; `groups_for_modules` is `"Public Admin Seam": [RulesteadAdmin.Router]` only; `RulesteadAdmin.Live.` in `skip_code_autolink_to` only (correct use) |
| 12 | `RulesteadAdmin.Router` has real `@moduledoc` with host-owns-auth contract + 3 contracted session keys; `__using__/1` and `live_session/3` are `@doc false` | VERIFIED | `head -4 router.ex` shows `@moduledoc """` at line 2; `current_actor` and `rulestead_admin_last_env` confirmed; `@doc false` count = 2 |

**Score:** 12/12 truths verified (0 present-behavior-unverified)

---

### ROADMAP Success Criteria Cross-Reference

| SC | Criterion | Status | Notes |
|----|-----------|--------|-------|
| SC-1 | `mix hex.build` tarball contains `brandbook/assets/logo/` SVGs and specimens | VERIFIED | Tarball contains 9 logo SVGs + specimens/readme-header.svg; `check_logo_bytes.sh` green |
| SC-2 | `rulestead/mix.exs` configured with "5 module groups" and "6 extras groups" in funnel order | VERIFIED (with correction) | 6 module groups (D-02 user-confirmed — Testing group added); 5 extras groups (ROADMAP/REQ wording says "6" but D-06 CONTEXT defines 5; implementation matches D-06 precisely) |
| SC-3 | Logo/favicon wired; `before_closing_head_tag` re-tints mineral palette + OG meta; no custom theme JS | VERIFIED | All confirmed in codebase; `mix docs --warnings-as-errors` green |
| SC-4 | "Why Rulestead?" exists as first Introduction extra, brandbook-sourced, not README duplicate | VERIFIED | 159-line file confirmed; position 2 in `extras:` list; no vendor names |
| SC-5 | README centered brand hero + 5 badges + `~> 1.0`; social card rasterized | VERIFIED | Hero block confirmed at top of README; 1200x630 PNG present |
| SC-6 | `rulestead_admin` docs parity — logo/favicon/theming + real Router `@moduledoc` + admin flow guides | VERIFIED | All parity checks pass; dev-mode `mix docs --warnings-as-errors` exits 0 |

**Note on SC-2 module group count:** The ROADMAP and DOC-01 requirement text say "5 module groups" but D-02 is a user-confirmed correction adding the "Testing" group for `Rulestead.TestHelpers` (the contracted adopter facade). The plan explicitly instructs: "Treat criterion-2 as satisfied-with-correction — do NOT flag the count." The CONTEXT.md D-06 definition clearly specifies 5 extras groups, not 6; "6 extras groups" in the ROADMAP/requirements text is a stale count. The implementation matches D-06 exactly.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `rulestead/brandbook` | Symlink to `../brandbook` | VERIFIED | `test -L` passes; git-tracked as mode 120000 |
| `rulestead_admin/brandbook` | Symlink to `../brandbook` | VERIFIED | `test -L` passes; git-tracked as mode 120000 |
| `brandbook/assets/logo/rs-social-card.png` | PNG 1200x630 | VERIFIED | `file` reports PNG image data, 1200 x 630, 8-bit/color RGBA |
| `scripts/ci/check_logo_bytes.sh` | D-10 tarball assertion | VERIFIED | Executable, `bash -n` clean, invoked from `contributor.sh`, live run passes |
| `guides/introduction/why-rulestead.md` | Brandbook positioning page, ≥40 lines | VERIFIED | 159 lines; links `product-boundary.md`; not README duplicate |
| `README.md` | Brand hero + 5 badges + `~> 1.0` | VERIFIED | Hero at line 1-11; all 5 badge URLs present; `~> 1.0` kept; no `~> 0.1` |
| `rulestead/mix.exs` | 6 module groups, funnel extras, asset wiring, theming | VERIFIED | All must-have patterns confirmed; `mix docs --warnings-as-errors` green |
| `rulestead_admin/mix.exs` | Admin parity: logo/favicon/theming/extras/groups | VERIFIED | All parity greps pass |
| `rulestead_admin/lib/rulestead_admin/router.ex` | Real `@moduledoc` (host-owns-auth) | VERIFIED | `@moduledoc """` at line 2; 3 contracted session keys present; 2 `@doc false` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `rulestead/brandbook` (symlink) | `../brandbook` directory | Git-tracked symlink (mode 120000) | WIRED | `test -L` + `git ls-files` pass; `rs-mark.svg` resolves |
| `rulestead_admin/brandbook` (symlink) | `../brandbook` directory | Git-tracked symlink (mode 120000) | WIRED | `test -L` + `git ls-files` pass |
| `scripts/ci/check_logo_bytes.sh` | `scripts/ci/contributor.sh` | `grep -q 'check_logo_bytes.sh' contributor.sh` | WIRED | Confirmed in contributor.sh |
| `rulestead/mix.exs files:` glob | `rulestead/brandbook` symlink | `brandbook/assets/logo/*.svg` plain-relative glob | WIRED | Tarball contains 9 logo SVGs + specimens; `check_logo_bytes.sh` green |
| `rulestead/mix.exs before_closing_head_tag` | ExDoc 0.40.3 `--main*` CSS vars | Inline `<style>` at `:root` + `body.dark` | WIRED | `--main:`, `body.dark` confirmed; `mix docs` green |
| `rulestead_admin/mix.exs files:` glob | `rulestead_admin/brandbook` symlink | `brandbook/assets/logo/*.svg` plain-relative glob | WIRED | `check_package_whitelist.sh` passed: "package whitelist checks passed" |
| `rulestead_admin/lib/rulestead_admin/router.ex @moduledoc` | `guides/api_stability.md` session keys | Verbatim `current_actor`, `rulestead_admin_environments`, `rulestead_admin_last_env` | WIRED | All 3 session keys confirmed in router.ex |
| `why-rulestead.md` | `guides/introduction/product-boundary.md` | Above-the-fold `product-boundary.md` link | WIRED | `grep -q 'product-boundary.md'` passes |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix docs --warnings-as-errors` exits 0 (core) | `cd rulestead && mix docs --warnings-as-errors` | "View html docs at doc/index.html" | PASS |
| `mix docs --warnings-as-errors` exits 0 (admin, dev mode) | `cd rulestead_admin && mix docs --warnings-as-errors` | "View html docs at doc/index.html" | PASS |
| D-10 logo-bytes assertion green | `bash scripts/ci/check_logo_bytes.sh` | "logo SVG bytes verified in tarball" | PASS |
| Package whitelist check passes | `bash scripts/ci/check_package_whitelist.sh` | "package whitelist checks passed" | PASS |
| 6 module groups in core mix.exs | `grep -cE '"(Core API|...)"' rulestead/mix.exs` | Returns `6` | PASS |
| Tarball contains brandbook SVGs | `tar xOf rulestead-0.1.7.tar contents.tar.gz \| tar tzf - \| grep brandbook` | 9 logo SVGs + specimens | PASS |

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| DOC-01 | Plan 05 | `rulestead/mix.exs` module groups + extras groups + funnel order | SATISFIED | 6 module groups (D-02 corrected from 5), 5 extras groups per D-06, funnel order confirmed |
| DOC-02 | Plan 01 | Brand logo/favicon/assets wired; `brandbook/` in `files:`; no launch-day 404 | SATISFIED | Tarball contains all SVGs; `check_logo_bytes.sh` green; symlinks committed |
| DOC-03 | Plan 05 | `before_closing_head_tag` mineral-palette re-tint + OG meta; no theme JS | SATISFIED | All CSS vars + OG meta confirmed; no `<script>` in mix.exs |
| DOC-04 | Plan 02 | "Why Rulestead?" first Introduction extra; brandbook-sourced; not README duplicate | SATISFIED | `why-rulestead.md` at 159 lines; position 2 in extras; no vendors |
| DOC-05 | Plan 03 | README brand hero (5 badges, `~> 1.0`); social card rasterized | SATISFIED | All 5 badges + hero confirmed; 1200x630 PNG present |
| DOC-06 | Plan 06 | `rulestead_admin` docs parity; real Router `@moduledoc`; admin flow guides | SATISFIED | All parity items confirmed; dev-mode docs green |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `guides/introduction/why-rulestead.md` | 148 | `0.1.x` in narrative prose | INFO | `check_version_truth.py` false-positive on narrative sentence; not an install snippet; deferred per plan 03 SUMMARY |

No TBD/FIXME/XXX markers found in any phase-modified file. No stub implementations. No hardcoded empty values.

---

### Human Verification Required

#### 1. Admin `RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs` Gate

**Test:** After publishing `rulestead@1.0.0` to Hex, run `RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors` from `rulestead_admin/`
**Expected:** Exits 0 — the full Hex-mode dep graph resolves and the autolink gate is clean
**Why human:** Locally the `RULESTEAD_ADMIN_HEX_RELEASE=1` flag triggers a `{:rulestead, "~> 1.0"}` Hex dep fetch that fails because the package is not yet published. Dev-mode (`mix docs --warnings-as-errors` without the flag) exits 0 and was verified in this report. This gate can only be confirmed post-publish.

#### 2. Visual Browser Render — Core Docs

**Test:** Build docs with `cd rulestead && mix docs`, then open `doc/index.html` in a browser and toggle between light and dark mode
**Expected:** Logo `rs-mark.svg` loads (no 404 in network tab), favicon resolves, sidebar/links are tinted Stead Blue (#3A6F8F), dark mode applies via `body.dark` selector producing the dark mineral palette
**Why human:** CSS variable cascade and runtime asset resolution require a browser render — `mix docs --warnings-as-errors` passing does not exercise visual output

#### 3. Visual Browser Render — Admin Docs

**Test:** Build docs with `cd rulestead_admin && mix docs`, then open `doc/index.html` in a browser and toggle light/dark mode
**Expected:** Same as core — logo/favicon resolve, Stead Blue tint, dark mode; `og:image` meta should point to `rulestead_admin` host
**Why human:** Admin theming parity requires visual inspection; duplicate `before_closing_head_tag` implementation cannot be compared against core at runtime without rendering

#### 4. OG / Social Card Unfurl

**Test:** After the package is published, paste a HexDocs page URL into a social card unfurler (e.g. opengraph.xyz or Twitter Card Validator)
**Expected:** `og:image` resolves to `rs-social-card.png` 1200x630 and renders correctly in the unfurl preview — not an empty or broken card
**Why human:** OG meta correctness requires a live network fetch from the CDN — the `<meta>` tag presence was verified by grep but CDN resolution requires post-publish validation

#### 5. `check_version_truth.py` False-Positive Resolution

**Test:** Review `why-rulestead.md:148`: `version line ('0.1.x') had stopped telling the truth about that maturity.`
**Expected:** Decision: either (a) update `check_version_truth.py` to exempt narrative-context `0.1.x` references (add an exemption pattern for lines containing the phrase "had stopped telling the truth" or similar), or (b) rephrase the sentence to avoid the trigger
**Why human:** Policy call — the line is intentional prose explaining the 1.0 promotion story; the script is a Phase 125 guard that may need tuning for narrative use

---

### Gaps Summary

No gaps found. All 12 must-have truths are VERIFIED against the codebase. The 5 human verification items above are standard post-implementation checks (browser rendering, post-publish gate, OG unfurl) that cannot be resolved by static analysis.

---

_Verified: 2026-06-18T10:00:00Z_
_Verifier: Claude (gsd-verifier)_
