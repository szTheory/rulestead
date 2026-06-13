# Phase 98: Admin Re-skin (CSS Cascade) - Context

**Gathered:** 2026-06-05 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Third phase on the strict spine **95 → 96 → 98 → 99 → 100** (milestone v1.14,
Brand System Realization). Re-skin `rulestead_admin/priv/static/css/rulestead_admin.css`
to the canonical mineral palette across all four cascade blocks — **colors only** — so
that both CI drift checks (`check_synced_pair.py`, `check_brand_tokens.py`) and the
WCAG-AA contrast gate (`check_contrast.py`) pass in both light and dark themes, with
`design-system.html` swatches reflecting the mineral palette.

**In scope:** SKIN-01 (re-skin all 4 cascade blocks — Block 1 light, Block 2
system-dark, Block 3 explicit-dark, Block 4 explicit-light — colors only, invariant
`:root` tokens untouched); SKIN-02 (pass `check_synced_pair.py` + WCAG-AA both themes,
`design-system.html` updated); SKIN-03 (`check_brand_tokens.py` confirms admin palette
matches `brandbook/tokens.json`). Per the verification decision (D-05), this phase ALSO
extends both guard scripts additively so SC-2 and SC-4 are machine-verified.

**Out of scope (later phases / fixed by 95/96/97):** computing or re-deriving any hex
(all LOCKED in Phase 95, encoded in `tokens.json` in Phase 96 — Phase 98 encodes
verbatim); logo/mark SVGs (97, complete); specimen SVGs (99); copy/voice/release-template/
final README (100). **No non-color CSS property changes** — no spacing, typography,
border-radius, layout, or structural lines may appear in the diff. No new swatches added
to `design-system.html`. No re-skin of `:root` invariant scalars.
</domain>

<decisions>
## Implementation Decisions

### Cascade Block Identity & Edit Surface
- **D-01:** The four cascade blocks are at confirmed line ranges: **Block 1** light
  default `.rs-shell, [data-rulestead]` (`:225-303`); **Block 2** system-dark
  `@media (prefers-color-scheme: dark)` (`:305-386`); **Block 3** explicit-dark
  `.rs-shell[data-theme="dark"]` (`:388-467`); **Block 4** explicit-light
  `.rs-shell[data-theme="light"]` (`:469-549`). Light palette = Blocks **1+4**; dark
  palette = Blocks **2+3**. The synced-pair invariant is **1≡4** (light) and **2≡3**
  (dark), documented in the header comment (`:186-193`).
- **D-02:** Edit **Block 1** and **Block 3** as the source-of-truth blocks, then mirror
  each **verbatim** into its synced partner — Block 1 → Block 4, Block 3 → Block 2. This
  preserves byte-identical pairs.
- **D-03:** Only `--rs-*` **color** declarations change. Every invariant scalar (font
  families, type scale, leading/weight/tracking, radius, spacing/layout, control sizing,
  focus-structural, z-index, motion) lives in `:root` (`:39-119`) and is **untouched**.
  The PR diff must contain **zero non-color property changes** (SC-1).

### Exact Hex Swap Set (encode verbatim from tokens.json — recompute nothing)
- **D-04:** Target values are `brandbook/tokens.json` `admin_css_mapping.light`
  (`:302-346`) and `admin_css_mapping.dark` (`:348-387`). These are the authoritative
  per-block targets; Phase 98 makes the CSS match them.
  - **Block 1 (light) — 7 declarations change** (live-verified by `check_brand_tokens.py`):
    `--rs-primary` `#2563eb`→`#3A6F8F`; `--rs-primary-hover` `#1d4ed8`→`#2d5f7c`;
    `--rs-accent` `#9a3f12`→`#9b5931`; `--rs-success` `#15803d`→`#2d7753`;
    `--rs-warning` `#b45309`→`#8f601a`; `--rs-error` `#b91c1c`→`#B44949`;
    `--rs-critical` `#b91c1c`→`#B44949`.
  - **Block 3 (dark) — parallel mineral set** from `admin_css_mapping.dark`:
    `--rs-primary`→`#5885a0`; `--rs-primary-hover`→`#4a7d9c`; `--rs-accent`→`#ba6b3c`;
    `--rs-success`→`#488d6b`; `--rs-warning`→`#B57A21`; `--rs-error`/`--rs-critical`→`#bf6464`;
    **`--rs-success-border` `#166534`→`#166634`** (a real one-digit dark fix that is
    easy to miss — `tokens.json:370` vs shipped `css:350,432`).
  - **Untouched:** neutral ramp, soft tints, rgba/shadow composites, overlay/scrim — these
    are not in `admin_css_mapping` and stay as shipped (the mapping covers only the
    brand/status hexes that drift). The planner verifies the final set against
    `admin_css_mapping` rather than hand-listing — the dicts are authoritative if any
    token here is stale.
- **D-04a:** Comparison is **case-insensitive** (`check_brand_tokens.py:69`) — casing of
  the encoded hex (e.g. `#3A6F8F` vs `#3a6f8f`) does not affect pass/fail; keep tokens.json
  casing for diff cleanliness.
- **D-04b:** Gap-2 per-surface canonicals (Success `#2d7753` / Danger on Stone Mist) are
  already encoded in `tokens.json admin_css_mapping` per Phase 96 D-04/D-11. Phase 98
  encodes them verbatim — no per-surface recomputation.

### Verification-Coverage Strategy (extend both guard scripts — additive)
- **D-05:** **Make SC-2 and SC-4 machine-verified, not manual.** Two small, additive
  python3-stdlib guard extensions (mirroring the existing drift-check pattern; consistent
  with the milestone's scripts-first ethos):
  - **(a)** Extend `scripts/check_synced_pair.py` to **also** assert **Block 1 ≡ Block 4**
    (light pair). Today it guards only **2≡3** (verified: prints `SYNCED PAIR IDENTICAL
    (56 tokens)`, `:45-48`). This honors SC-2's clause "Blocks 1+4 light pair still
    identical" — currently UNGUARDED — and protects this phase's Block-1→Block-4 mirror.
  - **(b)** Extend `scripts/check_brand_tokens.py` to **also** diff **Block 3** against
    `admin_css_mapping.dark`. Today it diffs only Block 1 light (`:51` hardcodes
    `["admin_css_mapping"]["light"]`, `:55` extracts `.rs-shell,`). D-08 of Phase 96
    explicitly permits the dark diff as additive.
  - **Rationale:** Without (b), a wrong dark hex ships silently — `check_synced_pair`
    passes (both dark blocks wrong-but-identical), `check_brand_tokens` is light-only, and
    `check_contrast.py` reads a **hardcoded matrix** (`:144-214`) independent of the CSS,
    so it confirms the targets are AA-valid but NOT that the CSS uses them. Automated
    guards beat human diff for invariants this milestone treats as load-bearing.
  - **Scope note:** Extending CI guard scripts does **not** violate "colors only" — that
    constraint applies to the CSS color diff (SC-1). Scripts are guards, not the cascade.
    Both edits must stay additive (preserve existing output/exit semantics; add the new
    pair/block coverage alongside).

### design-system.html Swatch Update
- **D-06:** `design-system.html` swatches are **100% `var(--rs-*)`-driven** with
  token-name labels (`:213-270`) — they **auto-update** once the cascade blocks change.
  SC-4's "swatches updated" is satisfied **transitively** by the CSS edit. **No manual
  swatch hex editing.** The only literal hexes in the file (`#333` `:57`, `#888` `:361`)
  are scaffold chrome (heading color, outside-shell probe border), not palette — leave
  them. **No new swatches** are added (reading SC-4 as "add swatches" would be scope creep).

### Claude's Discretion
- Exact diff implementation in `check_synced_pair.py` / `check_brand_tokens.py` (refactor
  the existing `decls()` extraction into a reusable two-call shape vs duplicate the block
  comparison) — planner's choice, keep additive and preserve current success/exit messages.
- Whether to emit a distinct success line for the new light-pair / dark-block coverage
  (e.g. `SYNCED PAIR IDENTICAL (light + dark)`) or fold counts into the existing line —
  planner's choice; keep `lint.sh` parsing stable.
- Order of CSS edits within the phase (light first vs dark first) — no functional impact.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `rulestead_admin/priv/static/css/rulestead_admin.css` — the edit target. Block 1
  `:225-303`, Block 2 `:305-386`, Block 3 `:388-467`, Block 4 `:469-549`; synced-pair
  header comment `:186-193`; invariant `:root` `:39-119`.
- `brandbook/tokens.json` — authoritative targets: `admin_css_mapping.light` `:302-346`,
  `admin_css_mapping.dark` `:348-387` (incl. `--rs-success-border: #166634` `:370`).
- `scripts/check_brand_tokens.py` — light-only today (`:51`, `:55`, case-insensitive `:69`);
  D-05(b) extends it to also diff Block 3 vs `admin_css_mapping.dark`.
- `scripts/check_synced_pair.py` — guards 2≡3 only today (`:45-48`); D-05(a) extends it to
  also assert 1≡4. The stdlib comment-strip + brace-walk `decls()` extraction pattern to mirror.
- `scripts/check_contrast.py` — WCAG-AA harness; **hardcoded `PALETTE_CHECKS` matrix**
  `:144-214` (dark pairings `:183-201`), independent of the CSS — confirms targets are
  AA-valid, NOT that CSS uses them. Run to prove SC-4 AA both themes.
- `rulestead_admin/priv/static/design-system.html` — var-driven swatches `:213-270`;
  scaffold-chrome literals `#333` `:57`, `#888` `:361` (not palette).
- `scripts/ci/lint.sh` — wiring at `:18,22,27`; keep output parsing stable when extending checks.
- `.planning/phases/96-design-tokens-brandbook-scaffold/96-CONTEXT.md` — locked token
  structure, D-04/D-08/D-11, token inventory, generic→mineral swap list.
- `.planning/phases/95-brand-audit-palette-reconciliation/95-PALETTE-RECONCILIATION.md` —
  §4 canonical one-hex-per-role, §5 dark ramp slot mapping, §8 the 15 AA-signed-off hexes,
  Gap-2 per-surface Success/Danger.
- `.planning/ROADMAP.md` — Phase 98 success criteria (4, authoritative) + gate messages.
- `.planning/REQUIREMENTS.md` — SKIN-01, SKIN-02, SKIN-03.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/check_synced_pair.py` `decls()` — comment-strip + brace-walk `--rs-*`
  extractor. The pattern both guard extensions reuse (D-05).
- `scripts/check_brand_tokens.py` — already loads `tokens.json` and extracts a block's
  `--rs-*` decls; the dark-diff extension (D-05b) reuses its load + extract path against
  `admin_css_mapping.dark` and Block 3.
- `scripts/check_contrast.py` — `PALETTE_CHECKS` matrix; the SC-4 AA gate for both themes.

### Established Patterns
- **Synced-pair invariant:** 1≡4 (light) and 2≡3 (dark) must stay byte-identical. Today
  only 2≡3 is automated; D-05a closes the 1≡4 gap. Edit one block, mirror to its partner.
- **Invariant vs variant tokens:** `:root` holds theme-insensitive scalars (NOT touched);
  per-theme blocks hold the neutral ramp + surface/border/text aliases + brand/status +
  shadows + focus color. Only brand/status color hexes drift to mineral.
- **Scripts-first CI, no third-party tooling:** python3 stdlib only; checks wired in
  `scripts/ci/lint.sh`. Guard extensions stay additive and stdlib-only.
- **Mirror-not-generate:** all hexes locked in Phase 95, encoded in Phase 96. Phase 98
  encodes verbatim against `tokens.json` — recomputes nothing.

### Integration Points
- `tokens.json admin_css_mapping` is the input contract Phase 98 re-skins toward; Block 1
  → `.light`, Block 3 → `.dark`.
- `design-system.html` swatches consume the same `--rs-*` vars — auto-reflect the re-skin.
- Phase 99 specimens and the brand-book cross-link the same locked mineral hexes.

### Verification Gap Map (why D-05 matters)
- Light pair (1≡4): **unguarded today** → D-05a adds the guard.
- Dark Block 3 hex correctness: **unguarded today** (`check_brand_tokens` light-only,
  `check_contrast` matrix is CSS-independent) → D-05b adds the guard.
- Light Block 1 hex correctness: guarded by `check_brand_tokens.py` (light) — passes once
  the 7 swaps land.
- Dark pair (2≡3 identical): guarded by `check_synced_pair.py` today.
</code_context>

<specifics>
## Specific Ideas

- The `--rs-success-border` `#166534`→`#166634` dark change is a one-digit difference that
  is trivially missed — call it out explicitly in the plan and let D-05b's dark diff catch it.
- Guard-script extensions MUST be additive: preserve existing success strings / exit codes
  / `lint.sh` parse points; add the new coverage alongside.
- Verify the changing-token set against `tokens.json admin_css_mapping` at plan time rather
  than trusting the hand-listed swaps in D-04 — the dicts are authoritative.
- SC-1's "zero non-color diff" is a hard gate: review the final CSS diff to confirm no
  spacing/typography/radius/layout line appears.
</specifics>

<deferred>
## Deferred Ideas

- Driving `check_contrast.py` from the live CSS (instead of a hardcoded matrix) so AA is
  verified against actual declared values — a contrast-harness refactor, not this phase.
  Note for a future hardening pass if matrix/CSS drift ever becomes a real risk.
- Specimen SVGs + `brandbook/assets/specimens/` — Phase 99.
- Copy/voice/release-template/final README — Phase 100.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
