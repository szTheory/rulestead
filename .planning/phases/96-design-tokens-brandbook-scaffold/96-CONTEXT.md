# Phase 96: Design Tokens (`brandbook/` scaffold) - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Second phase of milestone v1.14 (Brand System Realization), on the strict spine
**95 → 96 → 98 → 99 → 100**. Scaffold the `brandbook/` directory tree and the
token-drift guard mechanism. Concretely: commit machine-readable `tokens.json`
(DTCG 2025.10), a hand-authored `tokens.css` mirror, the `check_brand_tokens.py`
drift-check script, additive CI lint extensions, the relocated+reconciled
`brandbook/brand-book.md`, and `brandbook/docs/brand-usage.md` — and prove the
drift check FAILS on the still-generic admin CSS before Phase 98 touches the cascade.

**In scope:** TOK-01 (tokens.json raw→semantic→state, light+dark), TOK-02
(tokens.css `--rs-*` mirror), TOK-03 (semantic+state roles + spacing/radius/border/
shadow/focus-ring/code-block/callout primitives), TOK-04 (optional Tailwind excerpt);
the `check_brand_tokens.py` guard; additive `lint.sh` extension (token check +
no-op-safe SVG budget loop); brand-book relocation + §12 hex reconciliation +
`brandbook/docs/brand-usage.md`.

**Out of scope (later phases):** logo/mark SVGs (97), admin CSS re-skin — Phase 98
is what makes the drift check go green (98), specimens (99), copy/voice/release-template/
budget docs + final README (100). No hex values are computed here — all are LOCKED
in Phase 95. No `--rs-*` value in `rulestead_admin.css` is changed in this phase
(the check is *supposed* to fail against it).
</domain>

<decisions>
## Implementation Decisions

### DTCG Token Structure (tokens.json)
- **D-01:** `tokens.json` is DTCG 2025.10 (`$value`/`$type`/`$description` leaves) with a
  three-tier model: **`primitive`** (mineral named colors — `stead-blue`, `ember-copper`,
  `ink-blue`, `slate-stead`, `basalt`, `signal-gold`, plus the neutral ramp slots) →
  **`semantic`** (role aliases referencing primitives via DTCG `{primitive.stead-blue}`
  alias syntax; roles: default/hover/active/focus/disabled/selected/success/warning/
  error/info/subtle/muted) → **`state`** (interaction states). Scalar groups (spacing,
  radius, border, shadow, focus-ring structural, code-block, callout) live in one shared
  **invariant** group — they do not vary by theme.
- **D-02:** Light vs dark color values are expressed by a **top-level `light` / `dark`
  group split** for the color-carrying groups — NOT `$extensions` modes. Rationale: this
  mirrors the shipped CSS invariant-vs-variant split (`rulestead_admin.css:127–163`) and
  stays human-diffable against the four cascade blocks. Nothing consumes the JSON
  programmatically (no Style Dictionary), so structure optimizes for audit, not tooling.
- **D-03:** `tokens.json` includes a top-level **`admin_css_mapping`** dict with `light`
  and `dark` sub-objects, each mapping every **variant** `--rs-*` token name → its resolved
  value. **Invariant `:root` tokens are excluded** (they never change per theme, so
  including them only adds false-drift surface). This mapping is the comparison target for
  `check_brand_tokens.py`.
- **D-04:** All token *values* come verbatim from the LOCKED Phase 95 record
  (`95-PALETTE-RECONCILIATION.md` §4 canonical one-hex-per-role + §5 dark ramp slot
  mapping). Gap-2 per-surface canonicals (Success `#2d7753`, Danger `#b04848` on Stone
  Mist) are encoded as per-surface token values per D-11 sign-off. Phase 96 **encodes,
  never recomputes**. Known mismatch: `info`, `subtle`, `muted`, `selected` are
  token-design semantics with no 1:1 shipped `--rs-*` counterpart — `admin_css_mapping`
  maps only the `--rs-*` names that actually exist; tokens.json defines the fuller role set.

### tokens.css Authoring Shape
- **D-05:** `tokens.css` is a **canonical reference mirror**, not the deployed cascade:
  a **simplified two-block light/dark pair** (`.rs-shell, [data-rulestead]` for light;
  `.rs-shell[data-theme="dark"], [data-rulestead][data-theme="dark"]` for dark) + the
  shared `:root` invariant block. It does NOT reproduce all four cascade blocks (the
  `@media` system-dark and explicit-light precedence blocks are a live-app concern, not a
  reference-file concern; a comment documents that they're handled in `rulestead_admin.css`).
  Scope stays `.rs-shell` / `[data-rulestead]` only — never `:root`/`<html>` for color.
- **D-06:** The TOK-04 Tailwind token excerpt is embedded as a trailing **commented-out
  CSS block** (`/* ... */`) so `tokens.css` remains valid, side-effect-free CSS and never
  pollutes the `--rs-*` namespace or leaks tokens outside the mounted scope.

### check_brand_tokens.py Semantics
- **D-07:** `scripts/check_brand_tokens.py` reads `brandbook/tokens.json`, extracts
  `admin_css_mapping.light`, and compares each `--rs-*` value against **Block 1**
  (`.rs-shell, [data-rulestead]`) of `rulestead_admin.css`. It **reuses the
  `check_synced_pair.py` style**: python3 stdlib only (`re` + brace-depth walk), strip
  comments first, extract `--rs-*` declarations. On match: prints `BRAND TOKENS SYNCED
  (N tokens)` and exits 0. On mismatch: prints a **per-token diff** (e.g.
  `--rs-primary: tokens.json=#3A6F8F  css=#2563eb`) and exits 1. Executable (`chmod +x`),
  composable with `check_synced_pair.py`.
- **D-08:** The check **must FAIL now** (exit 1) when run against the un-re-skinned admin
  CSS — Block 1 still ships generic `#2563eb` / `#9a3f12` / `#15803d` / `#b45309` /
  `#b91c1c` vs the mineral canonicals tokens.json encodes (`#3A6F8F` / `#9b5931` /
  `#2F7D57` / `#8f601a` / `#B44949`). This demonstrated failure is success criterion 3:
  the guard is proven before Phase 98 makes it pass. Comparing the light Block 1 is the
  default; dark Block 3 comparison is additive if planning wants it. tokens.css ↔
  tokens.json cross-check is NOT in scope this phase.

### brandbook/ Directory Layout
- **D-09:** Committed tree: `brandbook/{brand-book.md, tokens.json, tokens.css, README.md,
  docs/brand-usage.md}`. `README.md` (dir index stub cross-linking the others, REPO-01
  "self-contained + cross-linked") and `docs/brand-usage.md` (re-skin + `check_brand_tokens.py`
  usage notes) are created minimal-but-real now. `VOICE.md`, `RELEASE-TEMPLATE.md`,
  `BUDGET.md`, final README, and `assets/` are deferred to Phases 97/99/100.

### CI Lint Extension (lint.sh)
- **D-10:** Edits to `scripts/ci/lint.sh` are **strictly additive** — the existing lines
  are preserved verbatim, new lines appended. Append (a) `python3
  "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"` and (b) a **no-op-safe** SVG
  size-budget loop over `brandbook/assets/logo/*.svg` (≤20KB) and
  `brandbook/assets/specimens/*.svg` (≤50KB) using `shopt -s nullglob` so the empty glob
  does not error under `set -euo pipefail`; prints `SVG SIZE BUDGET OK` and exits 0 when
  zero SVGs exist (they arrive in Phases 97/99). The only intentional CI failure this
  phase is the token drift check.

### Brand-Book Relocation + §12 Rework
- **D-11:** Relocate via `git mv prompts/rulestead-brand-book.md brandbook/brand-book.md`
  (preserves history), then write a pointer comment into a fresh `prompts/rulestead-brand-book.md`
  stub referencing the new canonical location ("Moved to `brandbook/brand-book.md` —
  canonical as of Phase 96"). The existing working-tree edit (`M prompts/rulestead-brand-book.md`
  in git status) is committed/handled before the move.
- **D-12:** The §12 (color system) rework replaces the flagged §12 hex literals with the
  AA-verified canonicals from `95-PALETTE-RECONCILIATION.md` §4/§8 (the 15 signed-off
  replacements — e.g. Ember Copper `#B96A3A`→`#9b5931`, Warning `#B57A21`→`#8f601a`,
  Moss Grey `#6C7A73`→`#606d66`, Success/Danger dark, Stead Blue/Info dark, etc.) and adds
  a **Gap-2 per-surface note** (Success `#2d7753` / Danger `#b04848` on Stone Mist). Other
  hex mentions are reconciled only if they restate a changed palette value. **§8 tagline
  needs NO change** — it already reads "Runtime decisions, made clear."

### Claude's Discretion
- Exact DTCG `$type` choices per leaf (e.g. `color` vs `dimension` vs `fontFamily`),
  group/key casing, and `$description` wording — planner's choice, follow DTCG 2025.10.
- Whether `check_brand_tokens.py` additionally diffs dark Block 3 (D-08 allows it as
  additive; light Block 1 is the required minimum).
- Exact wording/structure of `README.md` and `docs/brand-usage.md` stubs.
- Pointer-comment syntax (HTML comment vs markdown blockquote) in the `prompts/` stub.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/95-brand-audit-palette-reconciliation/95-PALETTE-RECONCILIATION.md`
  — LOCKED palette (§4 canonical one-hex-per-role, §5 dark ramp slot mapping, §6 Signal
  Gold policy, §8 the 15 D-11-signed-off AA-adjusted hexes). The authoritative value source
  for tokens.json. Phase 96 encodes these verbatim.
- `.planning/phases/95-brand-audit-palette-reconciliation/95-BRAND-AUDIT.md` — pressure-test
  scorecard; §12 REWORK direction + ADD items (BRD-03 szTheory note scoped to Phase 100).
- `.planning/phases/95-brand-audit-palette-reconciliation/95-CONTEXT.md` — prior locked
  decisions (D-01..D-11) that frame this phase's inputs.
- `prompts/rulestead-brand-book.md` — THE brand book (working-tree state; `M` in git status).
  Source for the `git mv` relocation + §12 hex reconciliation. §8 tagline already correct.
- `rulestead_admin/priv/static/css/rulestead_admin.css` — the four cascade blocks; Block 1
  (`.rs-shell, [data-rulestead]`, ~lines 225–303) is the `check_brand_tokens.py` comparison
  target; invariant vs variant split documented ~lines 127–163. Source of the `--rs-*`
  token shape tokens.css/tokens.json mirror.
- `scripts/check_synced_pair.py` — the python3-stdlib drift-check pattern to mirror
  (comment-strip + brace-walk extraction, print-diff-then-exit-1). `check_brand_tokens.py`
  must be composable with it.
- `scripts/check_contrast.py` — Phase 95 verification script (per-surface checks treat
  `#2d7753`/`#b04848` separately; precedent for Gap-2 per-surface handling).
- `scripts/ci/lint.sh` — current lint surface (runs under `set -euo pipefail`); the
  additive-append target.
- `rulestead_admin/priv/static/design-system.html` — swatch fixture (var-referenced).
- `.planning/REQUIREMENTS.md` — TOK-01..TOK-04 (and REPO-01/REPO-02 context).
- `.planning/ROADMAP.md` — Phase 96 success criteria (authoritative) + Phase 98/99 gate
  messages (`BRAND TOKENS SYNCED (N tokens)`, `SVG SIZE BUDGET OK`, budgets).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/check_synced_pair.py` — the established stdlib drift-check pattern (strip
  comments → locate selector → brace-walk → extract sorted `--rs-*` decls → compare →
  print diff → exit code). `check_brand_tokens.py` mirrors this exactly.
- `scripts/check_contrast.py` — Phase 95 contrast verifier; the per-surface treatment of
  Gap-2 hexes is the precedent for how tokens encode Success/Danger on Stone Mist.
- `rulestead_admin.css` four-block cascade — the canonical `--rs-*` token shape and the
  invariant-vs-variant split that D-01/D-02/D-03 mirror in tokens.json/tokens.css.

### Established Patterns
- **Synced-pair invariant:** Blocks 1≡4 (light) and 2≡3 (dark) are byte-identical, guarded
  by `check_synced_pair.py` (currently guards only 2≡3). tokens.css's two-block mirror and
  the new token check must respect this so Phase 98's edits stay synced.
- **No third-party tooling / scripts-first CI:** python3 stdlib only; checks wired into
  `scripts/ci/lint.sh`. No Node, no Style Dictionary, no SCSS — mirror-not-generate.
- **Invariant vs variant tokens:** `:root` holds theme-insensitive scalars (typography,
  radius, spacing, control, z-index, motion, focus-structural); per-theme blocks hold
  neutral ramp, surface/border/text aliases, brand, status, shadows, focus-color.

### Integration Points
- tokens.json (`admin_css_mapping`) is the **input contract** Phase 98 re-skins toward —
  Phase 98 edits `rulestead_admin.css` Block 1/3 until `check_brand_tokens.py` exits 0.
- Phase 97 mark SVG fills and Phase 99 specimens consume the same locked hexes via
  tokens.json/brand-book.
- The committed `brandbook/brand-book.md` becomes the canonical brand reference all later
  phases (98–100) cross-link to.

### Token Inventory (high-value planner reference)
- **Cascade blocks:** Block 1 light `.rs-shell, [data-rulestead]`; Block 2 system-dark
  `@media (prefers-color-scheme: dark)`; Block 3 explicit-dark `[data-theme="dark"]`;
  Block 4 explicit-light `[data-theme="light"]`. Synced: 1≡4, 2≡3.
- **INVARIANT (`:root`) — NOT re-skinned, NOT in `admin_css_mapping`:** font families
  (`--rs-font-display/sans/mono`); type scale (`--rs-text-2xs`…`-2xl`); leading; weight;
  tracking; radius (`--rs-radius-sm/md/lg/xl/full`); layout/spacing (`--rs-shell-max`,
  `--rs-space-1`…`-10`, `--rs-section-gap`, `--rs-page-gap`); control
  (`--rs-control-h/-sm/-lg`, `--rs-control-px`, `--rs-touch-target-min`); focus-structural
  (`--rs-focus-ring-offset`, `--rs-disabled-opacity`); z-index (`--rs-z-*`); motion
  durations + easing (`--rs-motion-*`, `--rs-ease-*`).
- **VARIANT (per-theme; mapped + compared):** neutral ramp `--rs-neutral-0/25/50/100/200/
  300/400/500/600/900` (+ `--rs-neutral-700` light-only — a real per-theme asymmetry);
  aliases `--rs-bg`, `--rs-surface(-muted/-faint)`, `--rs-border(-subtle/-strong)`,
  `--rs-text(-muted/-placeholder)`; brand `--rs-primary(-hover/-soft)`, `--rs-on-primary`,
  `--rs-accent(-soft)`; success `--rs-success(-hover/-soft/-bg-subtle/-text/-border)`;
  warning `--rs-warning(-hover/-soft/-text/-border)`; error/critical
  `--rs-error(-hover/-soft/-bg-subtle/-text/-text-strong/-border/-border-strong)`,
  `--rs-critical`; shadows `--rs-shadow-sm/-shadow/-shadow-panel`; focus+disabled color
  `--rs-focus-ring-color/-focus-ring/-primary-ring/-disabled-bg/-disabled-text`;
  overlay `--rs-overlay-veil`, `--rs-scrim`.
- **No `--rs-info` family** in shipped CSS though `info` is a required tokens.json semantic
  (book §12 / reconciliation §4 define `#356E8C` light / `#55859e` dark) — expected gap;
  `admin_css_mapping` maps only existing `--rs-*` names.
- **Generic hexes guaranteeing the intended FAIL (Block 1 light):** `--rs-primary: #2563eb`,
  `--rs-primary-hover: #1d4ed8`, `--rs-accent: #9a3f12`, `--rs-success: #15803d`,
  `--rs-warning: #b45309`, `--rs-error: #b91c1c`.
</code_context>

<specifics>
## Specific Ideas

- tokens.json must carry an `admin_css_mapping` keyed on the EXACT `--rs-*` variant names
  so `check_brand_tokens.py`'s extraction (mirroring `check_synced_pair.py`) lines up
  1:1 with the CSS.
- The `--rs-neutral-700` light-only asymmetry and the missing `--rs-info` family are real
  edge cases the mapping must handle gracefully (map what exists; don't invent CSS names).
- The drift check failing is the deliverable, not a bug — verification must assert exit 1
  with a per-token diff, then Phase 98 flips it to exit 0.
- Gap-2 Success/Danger on Stone Mist are encoded as per-surface token values (D-11 Option 1),
  not a usage-policy-only note.
</specifics>

<deferred>
## Deferred Ideas

- Admin CSS re-skin to make `check_brand_tokens.py` pass — **Phase 98**.
- Logo/mark SVGs + the `brandbook/assets/logo/` directory the SVG budget loop guards —
  **Phase 97**.
- Specimen SVGs + `brandbook/assets/specimens/` — **Phase 99**.
- `VOICE.md`, `RELEASE-TEMPLATE.md`, `BUDGET.md`, final `README.md`, BRD-03 szTheory suite
  note — **Phase 100**.
- tokens.css ↔ tokens.json cross-check script — not this phase (primary guard targets
  admin CSS); revisit only if drift between the two mirrors becomes a real risk.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
