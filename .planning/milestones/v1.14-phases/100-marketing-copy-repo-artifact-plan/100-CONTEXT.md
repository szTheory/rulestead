# Phase 100: Marketing Copy + Repo Artifact Plan - Context

**Gathered:** 2026-06-05 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Fifth and final **non-capstone** phase on the strict spine **95 → 96 → 98 → 99 → 100**
(milestone v1.14, Brand System Realization). Palette (95), tokens (96), logos (97),
admin re-skin (98), and SVG specimens (99) are all complete. Phase 100 **assembles
ready-to-paste copy and final repo artifacts** from the already-locked brand system,
then proves a full green CI end-to-end run.

**In scope:**
- COPY-01 — `brandbook/VOICE.md` (8–12 say-this/not-this pairs for error/empty/success,
  grounded in brand-book §9/§19) + `brandbook/RELEASE-TEMPLATE.md` (release-announcement
  scaffold, grounded in §19/§21).
- COPY-02 — ready-to-paste copy blocks file in `brandbook/` (GitHub repo description,
  Hex.pm `:description` for both packages, 140-char blurb, README intro/hero, landing
  hero/sub + primary/secondary CTAs, three feature blurbs) + szTheory suite
  brand-architecture note (shared-vs-unique across Rulestead, Parapet, Scoria, Cairnloop);
  both `mix.exs` `:description` values updated.
- REPO-01 — final `brandbook/README.md` directory index (cross-links `rulestead_admin.css`
  + `brandbook/brand-book.md`); `brandbook/docs/brand-usage.md` brought to final state;
  `prompts/` pointer confirmed.
- REPO-02 — repo-size guard: `brandbook/BUDGET.md` (per-file-type limits matching the
  live lint), root `.gitattributes` binary-bloat guard, SVG size-budget lint confirmed
  passing.
- Full CI end-to-end: `check_synced_pair.py` + `check_brand_tokens.py` + SVG size-budget
  loop all exit 0 in one `scripts/ci/lint.sh` run.

**Out of scope (Phase 101 capstone):** `brandbook/index.html` HTML brand book + its
generator + its drift-check; **marking `.planning/PROJECT.md` / `STATE.md` as v1.14
shipped happens in Phase 101, NOT here**. No new copy *voice* is invented — all copy is
extracted/reformatted from the canonical brand book. No hex/token/CSS/SVG-asset changes
(those are LOCKED in 95–99). No new SVG assets. No CI logic redesign — the SVG budget
loop already exists and is active.
</domain>

<decisions>
## Implementation Decisions

### Voice & Copy Grounding (COPY-01, COPY-02)
- **D-01:** **All copy is extracted-and-reformatted from `brandbook/brand-book.md`, never
  invented.** VOICE.md's say-this/not-this pairs draw verbatim from §9 Do/Don't word lists
  (`brand-book.md:311–325`), §9 Good/Bad voice examples (`:327–338`), and §19 worked
  empty/error/warning/success microcopy (`:784–806`). RELEASE-TEMPLATE.md follows the §19
  error structure ("what happened / what did not / what next") and §21 maintainer tone
  (`:854–859`). README/landing/feature copy reuses §7 pitches (`:219–242`) and the §8
  **locked default tagline** "Runtime decisions, made clear." (`:259`), which the root
  `README.md:3` hero already uses. The phase assembles a copy kit; it does not author new voice.
- **D-02:** VOICE.md delivers **8–12 say-this/not-this pairs spanning error, empty, AND
  success states** (the three SC-1 categories), each pair traceable to a brand-book §9/§19
  source line. RELEASE-TEMPLATE.md is a fill-in scaffold (e.g. headline, what shipped,
  operator impact, upgrade notes, links) in the §21 "operator-impact-first" changelog tone.

### Published Brand Surfaces (COPY-02 — maintainer-confirmed: proceed)
- **D-03:** `rulestead/mix.exs:72` `:description` changes from the **tagline**
  `"Runtime decisions, made clear."` → a **functional one-liner** derived from brand-book
  §7's one-line description (`:220`), e.g. *"Elixir-native feature flags, experimentation,
  and remote config with deterministic, explainable evaluation."* (taglines belong in §8,
  functional descriptions in §7 / the Hex `:description` slot).
- **D-04:** `rulestead_admin/mix.exs:58` `:description` changes from
  `"Mountable admin UI package for Rulestead."` → a **parallel** description naming it the
  **optional mounted Phoenix LiveView operator companion** to Rulestead. Both descriptions
  are drafted in the plan and **surfaced for maintainer review before merge** — they
  auto-publish to hex.pm on merge to `main` (see [[release-pipeline-auto-publishes]]).
- **D-05:** The GitHub repo description + 140-char blurb are drawn from the same §7/§8
  corpus and kept consistent with the Hex `:description`. The szTheory suite
  brand-architecture note is **grounded in `.planning/research/ECOSYSTEM_SYNERGY.md`**
  (the only repo source characterizing all four suite members): **shared** layer =
  BEAM-native, DDD boundaries, `:telemetry` seams, clean protocol delegation, no tight
  coupling; **unique** = Rulestead (flags/experiments/config), Parapet (SRE/reliability),
  Scoria (AI governance), Cairnloop (support OS). Note frames suite identity vs. each
  library's distinct domain.

### Repo Artifacts & Size Guard (REPO-01, REPO-02)
- **D-06:** **The SVG size-budget lint already exists and is active** at
  `scripts/ci/lint.sh:32–48` (logo ≤20480 B, specimens ≤51200 B; prints "SVG SIZE BUDGET
  OK"). Phase 100 **does not build or redesign it** — it confirms it passes and documents
  it. All current assets pass with wide margin (largest specimen `palette.svg` ~10 KB,
  largest logo `rs-social-card.svg` ~6.4 KB).
- **D-07:** `brandbook/BUDGET.md` **codifies the existing live limits verbatim** (20 KB
  per logo SVG, 50 KB per specimen SVG) — it must not invent different numbers, or the
  doc and CI contradict each other. It documents per-file-type limits and the approval/
  review path for adding new brand assets.
- **D-08:** **A root `.gitattributes` is added** as the concrete REPO-02 binary-bloat
  guard (none exists today). This satisfies REPO-02's "size budget + CI check +
  `.gitattributes`" three-part requirement alongside the existing lint loop.
- **D-09:** `brandbook/README.md` is **rewritten** from its current placeholder
  (which self-identifies at `:12–19` as "to be replaced in Phase 100") into a
  self-contained directory index: all files (brand-book, tokens.json/css, VOICE,
  RELEASE-TEMPLATE, BUDGET, docs/, assets/logo/, assets/specimens/) with status, plus the
  cross-links to `../rulestead_admin/priv/static/css/rulestead_admin.css` and
  `brand-book.md` already present in placeholder form.
- **D-10:** `brandbook/docs/brand-usage.md` is brought to **final state** — its **stale
  tense** is corrected: the "intentional Phase 96 failure / Expected Phase 98 exit 0"
  language (`:24–38`) describes a now-resolved state and must be updated to reflect that
  the re-skin is **done** and the token check **exits 0**, so it no longer tells
  contributors the check "should exit 1." Adds the new-contributor re-skin path.
- **D-11:** The `prompts/` pointer requirement is satisfied by **confirming the pointer
  left behind in Phase 96** at `prompts/rulestead-brand-book.md` → `brandbook/brand-book.md`
  (verify it exists and points correctly; do not relocate again).

### CI End-to-End (SC-5)
- **D-12:** The phase's terminal proof is a **single `scripts/ci/lint.sh` run** in which
  `python3 scripts/check_synced_pair.py` + `python3 scripts/check_brand_tokens.py` + the
  SVG size-budget loop **all exit 0**. This is verification of the assembled repo state,
  not new CI logic. **PROJECT.md / STATE.md are NOT marked v1.14 shipped here** — that is
  the Phase 101 capstone's job.

### Claude's Discretion
- Exact final wording of all copy blocks (drafted from the §7/§8/§9/§19 corpus; the two
  published `:description` strings are surfaced for maintainer review before merge).
- VOICE.md and RELEASE-TEMPLATE.md document structure/headings.
- `.gitattributes` rule set (binary/text classification + any LFS-style guard for brand
  asset paths) consistent with the repo's existing asset types.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `brandbook/brand-book.md` — §7 (pitches/pillars), §8 (taglines, default locked),
  §9 (voice Do/Don't + Good/Bad), §19 (UI-writing worked microcopy), §21 (maintainer/
  changelog tone). The copy source of truth.
- `.planning/research/ECOSYSTEM_SYNERGY.md` — sole source for the szTheory suite
  shared-vs-unique brand-architecture note (Rulestead, Parapet, Scoria, Cairnloop).
- `scripts/ci/lint.sh` (`:32–48`) — the live SVG size-budget loop (20 KB logo / 50 KB
  specimen) that BUDGET.md must match and SC-5 must show green.
- `scripts/check_synced_pair.py`, `scripts/check_brand_tokens.py` — the other two CI
  checks that must exit 0 in the SC-5 end-to-end run.
- `rulestead/mix.exs:72`, `rulestead_admin/mix.exs:58` — current `:description` values to
  replace.
- `brandbook/README.md`, `brandbook/docs/brand-usage.md` — placeholder/near-final
  artifacts to finalize.
- `.planning/REQUIREMENTS.md` — COPY-01, COPY-02, REPO-01, REPO-02 exact text.
- `prompts/rulestead-brand-book.md` — pointer left from Phase 96 (confirm, don't relocate).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Brand book copy corpus** (`brandbook/brand-book.md`): pitches (§7), taglines (§8),
  voice Do/Don't + Good/Bad (§9), worked microcopy for empty/error/warning/success (§19),
  maintainer tone (§21). Phase 100 is assembly over this, not authorship.
- **Live SVG budget loop** (`scripts/ci/lint.sh:32–48`): already active, prints
  "SVG SIZE BUDGET OK", enforces 20 KB logo / 50 KB specimen. No build needed.
- **`brandbook/README.md`** placeholder already lists the §100 deliverables and carries
  the cross-link skeleton — the rewrite fills it in.
- **`brandbook/docs/brand-usage.md`** is structurally complete (check-script usage,
  synced-pair rule) — needs tense correction to "re-skin done, check exits 0."
- **Root `README.md:3`** already uses the §8 locked tagline — proves the "quote the book"
  pattern.

### Established Patterns
- CI surfaces are **scripts-first** under `scripts/ci/` + `scripts/*.py` (stdlib `python3`).
- Brand artifacts are **self-contained under `brandbook/`** with markdown indexes.
- Drift/guard checks are additive to `scripts/ci/lint.sh`, each exiting non-zero on failure.

### Integration Points
- `mix.exs` `:description` edits in **both** sibling packages (auto-publish to hex.pm on
  merge to `main` — surface for review).
- New root `.gitattributes` (REPO-02 binary-bloat guard) — none exists today.
- `scripts/ci/lint.sh` is the single end-to-end gate that must show all three checks green.
</code_context>

<specifics>
## Specific Ideas

- Hex `:description` should be a **functional** summary (§7), not the §8 tagline currently
  sitting in `rulestead/mix.exs:72`.
- BUDGET.md must mirror the **exact** 20 KB / 50 KB limits already in `lint.sh` — no new
  numbers.
- `brand-usage.md` "intentional failure / expected exit 1" language is now stale and must
  flip to "re-skin done, exits 0."
</specifics>

<deferred>
## Deferred Ideas

- `brandbook/index.html` HTML brand book + generator + drift-check → **Phase 101** (capstone).
- Marking `.planning/PROJECT.md` / `STATE.md` as **v1.14 shipped** → **Phase 101**.

### Reviewed Todos (not folded)
None — `todo.match-phase 100` returned 0 matches.
</deferred>
