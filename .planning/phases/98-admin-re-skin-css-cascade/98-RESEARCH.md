# Phase 98: Admin Re-skin (CSS Cascade) - Research

**Researched:** 2026-06-05
**Domain:** CSS cascade editing, Python stdlib guard-script extension, WCAG-AA verification
**Confidence:** HIGH — all claims verified by direct file inspection in this session

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Four cascade blocks at confirmed line ranges: Block 1 light `.rs-shell, [data-rulestead]` (`:225-303`); Block 2 system-dark `@media (prefers-color-scheme: dark)` (`:305-386`); Block 3 explicit-dark `.rs-shell[data-theme="dark"]` (`:388-467`); Block 4 explicit-light `.rs-shell[data-theme="light"]` (`:469-549`). Light palette = Blocks 1+4; dark palette = Blocks 2+3. Synced-pair invariant is 1≡4 (light) and 2≡3 (dark).
- **D-02:** Edit Block 1 and Block 3 as source-of-truth, then mirror each verbatim into its partner — Block 1 → Block 4, Block 3 → Block 2. Preserves byte-identical pairs.
- **D-03:** Only `--rs-*` color declarations change. Every invariant scalar in `:root` (`:39-119`) is untouched. PR diff must contain zero non-color property changes (SC-1).
- **D-04:** Target values are `brandbook/tokens.json` `admin_css_mapping.light` and `admin_css_mapping.dark`. These are authoritative; the planner verifies the full changing-token set against them, not the hand-listed swaps.
  - Block 1 (light) — 7 declarations change: `--rs-primary` `#2563eb`→`#3A6F8F`; `--rs-primary-hover` `#1d4ed8`→`#2d5f7c`; `--rs-accent` `#9a3f12`→`#9b5931`; `--rs-success` `#15803d`→`#2d7753`; `--rs-warning` `#b45309`→`#8f601a`; `--rs-error` `#b91c1c`→`#B44949`; `--rs-critical` `#b91c1c`→`#B44949`.
  - Block 3 (dark) — 8 declarations change: `--rs-primary`→`#5885a0`; `--rs-primary-hover`→`#4a7d9c`; `--rs-accent`→`#ba6b3c`; `--rs-success`→`#488d6b`; `--rs-warning`→`#B57A21`; `--rs-error`/`--rs-critical`→`#bf6464`; **`--rs-success-border` `#166534`→`#166634`** (one-digit change, easy to miss).
  - Untouched: neutral ramp, soft tints, rgba/shadow composites, overlay/scrim — not in `admin_css_mapping`.
- **D-04a:** Comparison is case-insensitive (`check_brand_tokens.py:69`) — casing of encoded hex does not affect pass/fail; keep tokens.json casing for diff cleanliness.
- **D-04b:** Gap-2 per-surface canonicals already encoded in `tokens.json admin_css_mapping` per Phase 96 D-04/D-11. Phase 98 encodes verbatim.
- **D-05:** Extend both guard scripts additively so SC-2 and SC-4 are machine-verified:
  - (a) Extend `scripts/check_synced_pair.py` to also assert Block 1 ≡ Block 4 (light pair). Today guards only 2≡3.
  - (b) Extend `scripts/check_brand_tokens.py` to also diff Block 3 against `admin_css_mapping.dark`. Today diffs only Block 1 light.
  - Both edits must stay additive — preserve existing output/exit semantics; add new coverage alongside.
- **D-06:** `design-system.html` swatches are 100% `var(--rs-*)`-driven — auto-update when cascade blocks change. No manual swatch hex editing. Scaffold-chrome literals `#333` (`:57`) and `#888` (`:361`) are not palette — leave them.

### Claude's Discretion

- Exact diff implementation in `check_synced_pair.py` / `check_brand_tokens.py` (refactor the existing `decls()` extraction into a reusable two-call shape vs duplicate the block comparison) — planner's choice, keep additive and preserve current success/exit messages.
- Whether to emit a distinct success line for the new light-pair / dark-block coverage or fold counts into the existing line — planner's choice; keep `lint.sh` parsing stable.
- Order of CSS edits within the phase (light first vs dark first) — no functional impact.

### Deferred Ideas (OUT OF SCOPE)

- Driving `check_contrast.py` from the live CSS (instead of a hardcoded matrix) — a contrast-harness refactor, not this phase.
- Specimen SVGs + `brandbook/assets/specimens/` — Phase 99.
- Copy/voice/release-template/final README — Phase 100.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SKIN-01 | `rulestead_admin.css` re-skinned to canonical mineral palette across all 4 cascade blocks — colors only, invariant tokens untouched | Verified: 7 light + 8 dark token swaps identified; `:root` (`:39-119`) is untouched; block line ranges confirmed |
| SKIN-02 | Re-skin passes `check_synced_pair.py` and WCAG-AA in both light and dark themes; `design-system.html` updated | Verified: `check_contrast.py` passes 18 checks against mineral targets (CSS-independent matrix); swatches are var-driven (auto-reflect); guard extension (D-05a) adds Block 1≡4 coverage |
| SKIN-03 | Token-drift check (`check_brand_tokens.py`) verifies admin CSS palette matches `brandbook/tokens.json` | Verified: currently exits 1 on 7 mismatches (intentional); extension (D-05b) adds dark block diff |
</phase_requirements>

---

## Summary

Phase 98 is a precision, colors-only re-skin of `rulestead_admin/priv/static/css/rulestead_admin.css`. The canonical mineral hex values are already locked in Phase 95 and encoded in `brandbook/tokens.json` (Phase 96). This phase encodes them verbatim into 4 cascade blocks (7 light swaps in Block 1, 8 dark swaps in Block 3, then mirrors each to its synced partner). No hex is recomputed here.

The second major task is extending two Python guard scripts additively: `check_synced_pair.py` gains Block 1≡4 light-pair coverage (currently only guards 2≡3), and `check_brand_tokens.py` gains Block 3 dark-diff coverage (currently light-only). The existing brace-walk `decls()` / `extract_css_decls()` extraction functions are the direct pattern to reuse.

The WCAG-AA gate (`check_contrast.py`) already passes for all 18 mineral-target checks against a hardcoded matrix — it is CSS-independent and confirms the targets are AA-valid. After the CSS re-skin, the gate that confirms the CSS actually uses those values is `check_brand_tokens.py` (for light) and the new D-05b extension (for dark). The `design-system.html` swatches auto-reflect the cascade change with zero manual edits.

**Primary recommendation:** Edit Block 1, mirror to Block 4, edit Block 3, mirror to Block 2. Then extend both guard scripts additively. Run all four guards green. The phase is done when `check_synced_pair.py`, `check_brand_tokens.py`, `check_tokens_css.py`, and `check_contrast.py` all exit 0.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS cascade color re-skin | Static CSS file (client-side) | — | `rulestead_admin.css` is a static asset; no server-side logic involved |
| Guard-script extension (synced-pair) | CI / scripts | — | Python stdlib guard; runs in lint.sh; verifies CSS invariant |
| Guard-script extension (brand-token drift) | CI / scripts | — | Python stdlib guard; diffs CSS against tokens.json |
| WCAG-AA verification | CI / scripts | — | Hardcoded matrix in `check_contrast.py`; CSS-independent |
| Swatch auto-update | Browser / Client (var-driven) | — | `design-system.html` uses `var(--rs-*)` — reflects cascade without manual edit |
| Synced-pair invariant enforcement | CI / scripts | CSS (pair structure) | Guard script detects drift; mirror-not-generate discipline prevents it |

---

## Standard Stack

### Core (no new packages — stdlib only)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Python 3 (stdlib) | system python3 | Guard script extensions | Project constraint: scripts-first, no third-party tooling |
| CSS custom properties | n/a | Token cascade | Native; no preprocessor; no build step (Mirror-not-generate policy) |

**No new packages are installed in this phase.** All work is edits to existing files.

---

## Package Legitimacy Audit

No external packages are installed in Phase 98. The phase is purely:
- CSS file edits (colors only)
- Python stdlib guard script extensions
- No `npm install`, `pip install`, or `mix deps.get` changes

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
tokens.json (admin_css_mapping.light / .dark)
       │
       │  Phase 98 reads (authoritative targets)
       ▼
rulestead_admin.css
  ├── Block 1 (light default)  ← edit source
  │        │ mirror verbatim
  │        ▼
  ├── Block 4 (explicit light) ← mirror target
  │
  ├── Block 3 (explicit dark)  ← edit source
  │        │ mirror verbatim
  │        ▼
  └── Block 2 (system dark)   ← mirror target
       │
       ▼
design-system.html (var(--rs-*) swatches — auto-reflect, no edit)

Guard scripts (CI / lint.sh):
  check_synced_pair.py  → Block 2≡3 (existing) + Block 1≡4 (D-05a new)
  check_brand_tokens.py → Block 1 vs .light (existing) + Block 3 vs .dark (D-05b new)
  check_tokens_css.py   → tokens.css mirror vs tokens.json (unchanged, stays green)
  check_contrast.py     → hardcoded PALETTE_CHECKS matrix (unchanged, already passes)
```

### Recommended Project Structure

No structural changes. All work is in-place edits to:

```
rulestead_admin/priv/static/css/rulestead_admin.css  (colors only)
scripts/check_synced_pair.py                          (additive extension)
scripts/check_brand_tokens.py                         (additive extension)
```

### Pattern 1: Brace-Walk Selector Extraction (reuse across both guard extensions)

Both guard scripts share the same comment-strip + brace-walk pattern. `check_synced_pair.py` uses `decls(css, sel)` (returns a sorted list of `--rs-*` declarations as strings for equality comparison). `check_brand_tokens.py` uses `extract_css_decls(css, sel)` (returns a dict of `{name: value}` for per-token diff). `check_tokens_css.py` uses the same dict-returning form.

**The D-05a extension** reuses `decls()` exactly as-is: call it twice with the two light selectors and compare. The existing 2≡3 check is the direct pattern:

```python
# [VERIFIED: direct file inspection] check_synced_pair.py :42-58 — existing 2≡3 pattern
media = decls(css, "@media (prefers-color-scheme: dark)")
attr  = decls(css, '.rs-shell[data-theme="dark"]')
if media and media == attr:
    print(f"SYNCED PAIR IDENTICAL ({len(media)} tokens)")
    return 0
```

The D-05a addition follows the same shape with `.rs-shell,` and `.rs-shell[data-theme="light"],` selectors. The planner decides whether to merge the pass message (e.g., `SYNCED PAIR IDENTICAL (N light + M dark tokens)`) or emit two separate lines — either is fine as long as `lint.sh:18` parse point is not broken (it does not parse the output, only checks exit code).

**The D-05b extension** reuses `extract_css_decls()` exactly as-is: call it with `.rs-shell[data-theme="dark"],` to get the Block 3 dict, then diff against `tokens["admin_css_mapping"]["dark"]`. The existing main() light-diff loop is the direct pattern:

```python
# [VERIFIED: direct file inspection] check_brand_tokens.py :51-80 — existing light pattern
mapping  = tokens["admin_css_mapping"]["light"]
css_decls = extract_css_decls(css, ".rs-shell,")
# ... per-token diff loop with case-insensitive compare
```

The D-05b dark extension uses `tokens["admin_css_mapping"]["dark"]` and `extract_css_decls(css, '.rs-shell[data-theme="dark"]')`. Fold mismatches into the same list; exit logic is unchanged.

### Pattern 2: Comment-Strip Guard (Critical — Pitfall 3)

Both scripts strip comments before calling `find()`. Without this, `css.find(selector)` matches inside the CSS header comment that documents all four block selectors (`:186-193` in the CSS). This is already handled by both scripts; any extension MUST pass the comment-stripped string, not the raw file content.

```python
# [VERIFIED: direct file inspection] check_brand_tokens.py :54
css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first (Pitfall 3 guard)
```

### Pattern 3: Case-Insensitive Hex Comparison

`check_brand_tokens.py:69` uses `.lower()` on both sides. The D-05b extension inherits this behavior automatically if it reuses the existing diff loop. `tokens.json` uses mixed case (e.g., `#3A6F8F`, `#B44949`, `#B57A21`) — the comparison tolerates this.

### Anti-Patterns to Avoid

- **Raw string find without comment-strip:** `css.find(selector)` on uncommented CSS will match inside the header comment at `:186-193` that lists all four block selectors. Always strip comments first (re.sub pattern above).
- **Changing non-color properties:** The diff must touch zero non-color lines. Any whitespace normalization, comment rewording, or structural edit in the cascade blocks is a SC-1 violation.
- **Manually editing swatch hexes in `design-system.html`:** Swatches are fully `var(--rs-*)` — manual edits are both unnecessary and scope creep.
- **Adding new swatches to `design-system.html`:** SC-4 does not require new swatches; adding them is scope creep.
- **Recomputing hex values:** All hex targets are locked in Phase 95 and encoded in `tokens.json`. Phase 98 encodes verbatim — zero recomputation.
- **Breaking existing guard output strings:** `lint.sh` at lines 18, 22, 27 calls the scripts and only checks exit codes. The success strings (`SYNCED PAIR IDENTICAL`, `BRAND TOKENS SYNCED`, `TOKENS.CSS MIRROR SYNCED`) are stable contracts used in human output; keep them in the extended scripts. Only the token count in the parenthetical may change.

---

## The Exact Changing-Token Set (Verified Against `tokens.json`)

Confirmed by running `python3 scripts/check_brand_tokens.py` (live output) and cross-checking `brandbook/tokens.json admin_css_mapping` directly.

### Block 1 (light) — 7 tokens change [VERIFIED: direct file inspection + live script run]

| Token | Current CSS Value | Target (`tokens.json .light`) |
|-------|------------------|-------------------------------|
| `--rs-primary` | `#2563eb` | `#3A6F8F` |
| `--rs-primary-hover` | `#1d4ed8` | `#2d5f7c` |
| `--rs-accent` | `#9a3f12` | `#9b5931` |
| `--rs-success` | `#15803d` | `#2d7753` |
| `--rs-warning` | `#b45309` | `#8f601a` |
| `--rs-error` | `#b91c1c` | `#B44949` |
| `--rs-critical` | `#b91c1c` | `#B44949` |

All 30 other hex-literal tokens in Block 1 (neutral ramp, soft tints, error variants, success variants, etc.) already match `tokens.json .light` — confirmed by the script output showing exactly these 7 mismatches and nothing else.

### Block 3 (dark) — 8 tokens change [VERIFIED: direct file inspection of tokens.json + CSS]

| Token | Current CSS Value | Target (`tokens.json .dark`) |
|-------|------------------|-------------------------------|
| `--rs-primary` | `#2563eb` | `#5885a0` |
| `--rs-primary-hover` | `#5a96f5` | `#4a7d9c` |
| `--rs-accent` | `#e8834a` | `#ba6b3c` |
| `--rs-success` | `#4ade80` | `#488d6b` |
| `--rs-warning` | `#fbbf24` | `#B57A21` |
| `--rs-error` | `#f87171` | `#bf6464` |
| `--rs-critical` | `#f87171` | `#bf6464` |
| `--rs-success-border` | `#166534` | `#166634` | ← one-digit change (`3`→`6` in third hex digit pair) |

**The `--rs-success-border` change is the highest-risk edit:** `#166534` (current) → `#166634` (target). The difference is a single digit in the second hex pair (`53` → `66`). A character-level review of this specific line in the final diff is recommended.

Tokens NOT in `tokens.json .dark` (and therefore untouched in Block 3):
- `--rs-primary-soft`, `--rs-accent-soft`, `--rs-success-soft`, `--rs-success-bg-subtle`, `--rs-success-text`, `--rs-warning-soft`, `--rs-warning-text`, `--rs-warning-border`, `--rs-error-soft`, `--rs-error-bg-subtle`, `--rs-error-text`, `--rs-error-text-strong`, `--rs-error-border`, `--rs-error-border-strong` — these are rgba() composites or already-mineral values, excluded from `admin_css_mapping` by design (string comparison cannot resolve `rgba()`).

---

## Guard Script Concrete Structure

### `check_synced_pair.py` — Current State [VERIFIED: direct file inspection]

- **File:** `scripts/check_synced_pair.py`
- **CSS path:** hardcoded `CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"` (relative — must be run from repo root)
- **Core function:** `decls(css, sel)` — comment-stripped CSS + selector string → sorted list of `line.strip()` for every line starting with `--rs-`; uses brace-depth walk to find block boundaries
- **Current check:** Block 2 (`@media (prefers-color-scheme: dark)`) ≡ Block 3 (`.rs-shell[data-theme="dark"]`) only (`:42-58`)
- **Current success output:** `SYNCED PAIR IDENTICAL (56 tokens)` → exits 0
- **Current failure output:** `SYNCED PAIR MISMATCH` + per-token diff lines → exits 1
- **lint.sh wiring:** line 18 — `python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"` — exit code only, no output parsing

**D-05a extension target:** add a second pair check for Block 1 (`.rs-shell,`) ≡ Block 4 (`.rs-shell[data-theme="light"],`) using the same `decls()` call. The planner decides on merged vs separate success messages; lint.sh only checks exit codes.

### `check_brand_tokens.py` — Current State [VERIFIED: direct file inspection + live run]

- **File:** `scripts/check_brand_tokens.py`
- **Paths:** `TOKENS_JSON = "brandbook/tokens.json"`, `CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"` (relative — must be run from repo root)
- **Core function:** `extract_css_decls(css, sel)` — same comment-strip + brace-walk pattern, returns `dict[name: value]`
- **Current check:** Block 1 light only — `mapping = tokens["admin_css_mapping"]["light"]`, `css_decls = extract_css_decls(css, ".rs-shell,")`
- **Comparison:** case-insensitive (`:69` `css_val.lower() != expected.lower()`)
- **Current success output:** `BRAND TOKENS SYNCED (N tokens)` → exits 0
- **Current failure output:** `BRAND TOKEN DRIFT DETECTED` + per-token `name: tokens.json=X  css=Y` lines → exits 1
- **Currently exits 1** (intentionally, until Phase 98 re-skins the CSS) — 7 mismatches confirmed by live run
- **lint.sh wiring:** line 22 — `python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"` — exit code only

**D-05b extension target:** add dark block diff — `mapping_dark = tokens["admin_css_mapping"]["dark"]`, `css_dark = extract_css_decls(css, '.rs-shell[data-theme="dark"],')`. Fold mismatches into the same `mismatches` list. Increment `matched` for dark matches. The final success message may update the token count (now covers both light + dark tokens) or emit a second line — planner's discretion.

### `check_tokens_css.py` — Unchanged in Phase 98 [VERIFIED: direct file inspection + live run]

- Currently exits 0: `TOKENS.CSS MIRROR SYNCED (68 tokens)`
- Guards `brandbook/tokens.css` mirror against `tokens.json` for both light + dark
- **Must stay green** after Phase 98 — `tokens.css` is not edited in Phase 98 (the CSS re-skin is `rulestead_admin.css`, not `tokens.css`)
- lint.sh wiring: line 27

### `check_contrast.py` — Unchanged in Phase 98 [VERIFIED: direct file inspection + live run]

- Currently exits 0: `ANCHORS OK` + `CONTRAST CHECK PASS (18 checks)`
- Hardcoded `PALETTE_CHECKS` matrix (`:144-214`) — reads no CSS; CSS-independent
- Covers 9 light-surface pairings + 6 dark-surface pairings + 3 OKLCH drift assertions
- **Dark mineral targets already in the matrix**: `#5885a0`, `#ba6b3c`, `#488d6b`, `#bf6464`, `#55859e`, `#75827b` all verified AA on `#10161f`
- **Light mineral targets already in the matrix**: `#9b5931`, `#8f601a`, `#2d7753`, `#b04848` all verified AA on Stone Mist `#E8ECE8`
- SC-4 "WCAG-AA both themes" is proven by running this script; it does NOT verify the CSS uses these values (that gap is closed by the D-05b dark diff extension)

### `scripts/ci/lint.sh` — Parse Points [VERIFIED: direct file inspection]

| Line | Invocation | Parse method |
|------|-----------|--------------|
| 18 | `python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"` | Exit code only (`set -euo pipefail`) |
| 22 | `python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"` | Exit code only |
| 27 | `python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"` | Exit code only |

**`set -euo pipefail` at line 2** means any non-zero exit aborts lint.sh immediately. The guard script extensions must preserve exit-code semantics: 0 on full success, 1 on any mismatch. Output text is not parsed by lint.sh — any success-line wording changes are safe.

**Known CWD issue (from STATE.md):** lint.sh does `cd "${RULESTEAD_REPO}/rulestead"` at line 6 for the Elixir mix commands. The guard scripts use relative paths (`CSS = "rulestead_admin/..."`) that resolve from repo root — they are invoked with absolute paths (`${RULESTEAD_REPO}/scripts/...`) so the relative path inside the scripts must work from the CWD at time of invocation. STATE.md documents a "pre-existing CWD bug (check_synced_pair.py relative path fails after `cd rulestead/`) — fix before Phase 98 closes." However, reviewing `lint.sh` lines 18/22/27 — the scripts are already invoked with `"${RULESTEAD_REPO}/scripts/..."` absolute paths, but the scripts internally open files with relative paths like `"rulestead_admin/priv/..."`. If the CWD after line 6's `cd rulestead/` is still `rulestead_admin/` — the relative path would fail. **This CWD bug must be confirmed and fixed in Phase 98.** The fix is either: (a) add `cd "${RULESTEAD_REPO}"` before the guard script invocations in lint.sh, or (b) use absolute paths inside the scripts. Option (a) is the minimal, additive fix.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex comparison | Custom hex normalizer | Python `.lower()` (already in scripts) | Already implemented, case-insensitive per D-04a |
| Block extraction | New CSS parser | Existing `decls()` / `extract_css_decls()` | Both functions handle the brace-walk correctly; re-use them |
| WCAG ratio computation | New contrast formula | `check_contrast.py` `contrast_ratio()` | Phase 95 implementation; passes 4 self-test anchors; do not duplicate |
| Token targets | Recompute from brand book | `brandbook/tokens.json admin_css_mapping` | All hex locked in Phase 95; `tokens.json` is authoritative |

---

## Common Pitfalls

### Pitfall 1: `--rs-success-border` one-digit dark miss
**What goes wrong:** The change is `#166534` → `#166634` — third hex pair changes from `53` to `66`. A developer doing a find-replace on the color group misses this because it is in the `success-border` slot, not a brand/status primary. It also fails silently unless D-05b is in place (the dark diff).
**Why it happens:** The value is not in the 7-token light list and not in the obvious "primary/accent/success/warning/error" brand roles.
**How to avoid:** The D-05b extension directly catches this mismatch. Additionally, call it out explicitly in the CSS edit task instructions.
**Warning signs:** `check_synced_pair.py` passes (both dark blocks wrong-but-identical), `check_brand_tokens.py` light-only passes, `check_contrast.py` passes (CSS-independent) — a triple-green that conceals the wrong dark value. This is exactly why D-05b is required.

### Pitfall 2: Comment-strip not applied before `find()`
**What goes wrong:** The CSS header comment at lines 186-193 documents all four block selectors by name. Without stripping comments first, `css.find(".rs-shell,")` matches inside the comment, not the actual Block 1 rule.
**Why it happens:** The comment is a pedagogical description of the cascade structure — it names all four selectors explicitly.
**How to avoid:** Any new `find()` call in the guard script extensions must operate on the comment-stripped CSS (the `re.sub(r"/\*.*?\*/", "", raw, flags=re.S)` result). Both existing scripts already do this; extensions must reuse the stripped variable, not `raw`.
**Warning signs:** A guard extension appears to find a block but returns an empty or wrong token set.

### Pitfall 3: Non-color diff lines in the CSS PR
**What goes wrong:** A text editor auto-formats whitespace, normalizes comment indentation, or reflows a shadow composite while the color edits are being made.
**Why it happens:** CSS editors sometimes normalize alignment of colons in declaration blocks.
**How to avoid:** Review the final diff with `git diff rulestead_admin/priv/static/css/rulestead_admin.css` and confirm every changed line is a color hex swap. Zero tolerance for non-color changes per SC-1.
**Warning signs:** Any line in the diff that does not contain a hex value change is a violation.

### Pitfall 4: Dark block Block 2 edited directly instead of mirrored
**What goes wrong:** Developer edits Block 2 (system-dark, `@media`) directly rather than editing Block 3 (explicit-dark, `[data-theme="dark"]`) and mirroring to Block 2.
**Why it happens:** Block 2 appears first in the file (lines 305-386) before Block 3 (lines 388-467).
**How to avoid:** D-02 is explicit: Block 1 and Block 3 are source-of-truth; Block 4 and Block 2 are mirror targets. Edit Block 1, copy to Block 4. Edit Block 3, copy to Block 2.
**Warning signs:** `check_synced_pair.py` passes (pairs may still be identical if Block 2 was edited consistently) but Block 2 was the edit source — fragile for future maintenance.

### Pitfall 5: `design-system.html` manual hex edits
**What goes wrong:** Developer manually updates hex colors in design-system.html swatches after reading SC-4 "swatches updated."
**Why it happens:** SC-4's "swatches updated" is satisfied transitively by the CSS edit because all swatches use `var(--rs-*)` — no manual edits are needed or wanted.
**How to avoid:** D-06 is explicit: swatches are var-driven; auto-update once cascade changes. The only literal hexes in design-system.html (`#333` at line 57, `#888` at line 361) are scaffold chrome — not palette.
**Warning signs:** Any hex literal appearing in the diff for design-system.html that is not `#333` or `#888`.

### Pitfall 6: lint.sh CWD bug
**What goes wrong:** After `cd "${RULESTEAD_REPO}/rulestead"` at lint.sh line 6, the guard scripts' internal relative paths (`"rulestead_admin/priv/..."`) fail to resolve — `FileNotFoundError` at runtime.
**Why it happens:** The scripts are invoked with absolute paths (lines 18/22/27) but use relative file paths internally.
**How to avoid:** Add `cd "${RULESTEAD_REPO}"` before the guard script block in lint.sh (after line 15, before line 18). This is the minimal additive fix that restores CWD to repo root without affecting the Elixir commands above.
**Warning signs:** Guard scripts fail with `FileNotFoundError` or `No such file or directory` when run from lint.sh but succeed when run manually from repo root.

---

## Code Examples

### D-05a Extension — Block 1≡4 Light Pair Check

```python
# [VERIFIED: direct file inspection — mirrors existing 2≡3 pattern at :42-58]
# Add after the existing 2≡3 check in check_synced_pair.py main()

light_default = decls(css, ".rs-shell,")
light_pinned  = decls(css, '.rs-shell[data-theme="light"]')
if light_default and light_default == light_pinned:
    print(f"SYNCED PAIR IDENTICAL (light: {len(light_default)} tokens)")
    # (or fold into existing message — planner's choice)
else:
    print("SYNCED PAIR MISMATCH (light)")
    if light_default is not None and light_pinned is not None:
        only_default = [t for t in light_default if t not in light_pinned]
        only_pinned  = [t for t in light_pinned if t not in light_default]
        for t in only_default:
            print("  only in .rs-shell:", t)
        for t in only_pinned:
            print("  only in [data-theme=light]:", t)
    return 1
```

### D-05b Extension — Block 3 Dark Diff

```python
# [VERIFIED: direct file inspection — mirrors existing light diff at :51-80]
# Add to check_brand_tokens.py main() after existing light check

mapping_dark = tokens["admin_css_mapping"]["dark"]
css_dark = extract_css_decls(css, '.rs-shell[data-theme="dark"],')

if css_dark is None:
    print("ERROR: Block 3 selector '.rs-shell[data-theme=\"dark\"],' not found in CSS")
    return 1

for name, expected in sorted(mapping_dark.items()):
    if not name.startswith("--rs-"):
        continue
    css_val = css_dark.get(name)
    if css_val is None:
        mismatches.append(f"  [dark] {name}: tokens.json={expected}  css=<missing>")
    elif css_val.lower() != expected.lower():
        mismatches.append(f"  [dark] {name}: tokens.json={expected}  css={css_val}")
    else:
        matched += 1
```

### lint.sh CWD Fix

```bash
# [VERIFIED: direct file inspection of lint.sh]
# After line 15 (RULESTEAD_REPO whitelist check), before line 18 (check_synced_pair):
cd "${RULESTEAD_REPO}"

# Then the guard script invocations follow unchanged at lines 18/22/27
```

---

## Verification Gap Map (current vs. post-Phase-98)

| Invariant | Pre-Phase-98 | Post-Phase-98 |
|-----------|-------------|---------------|
| Block 2≡3 (dark pair identical) | Guarded by `check_synced_pair.py` | Unchanged — still guarded |
| Block 1≡4 (light pair identical) | **UNGUARDED** | Guarded by D-05a extension |
| Block 1 light hex correctness | Guarded by `check_brand_tokens.py` (exits 1) | Exits 0 after re-skin |
| Block 3 dark hex correctness | **UNGUARDED** | Guarded by D-05b extension |
| WCAG-AA both themes (targets valid) | Proven by `check_contrast.py` hardcoded matrix | Unchanged — still green |
| WCAG-AA both themes (CSS uses targets) | Block 1: guarded after re-skin; Block 3: UNGUARDED | Closed by D-05b |
| tokens.css mirror sync | Guarded by `check_tokens_css.py` (green) | Unchanged — stays green |

---

## Runtime State Inventory

This is a CSS colors-only edit phase. No data migrations, no live service config, no OS-registered state.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — CSS is a static file; no database records | None |
| Live service config | None — `rulestead_admin` is a mounted companion; no external service config | None |
| OS-registered state | None | None |
| Secrets/env vars | None — no env vars reference CSS token names | None |
| Build artifacts | `mix phx.digest` fingerprints `rulestead_admin.css` → a new fingerprint is generated | Run `mix phx.digest` in `rulestead_admin/` after CSS edit; no manual artifact removal needed |

**`mix phx.digest` note:** The CSS file is a static asset that Phoenix fingerprints. After editing `rulestead_admin.css`, `mix phx.digest` must be run in the `rulestead_admin/` package to regenerate the fingerprint manifest. This is the only build artifact concern.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Python 3 stdlib scripts (project's scripts-first CI pattern) |
| Config file | `scripts/ci/lint.sh` |
| Quick run command | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py` |
| Full suite command | `bash scripts/ci/lint.sh` (from repo root, requires Elixir env) or guards-only: `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_contrast.py` |

The guard scripts are the validation oracle for this phase. The CSS edits have no Elixir unit tests — correctness is proven by the guard scripts exiting 0 and by a final diff review (zero non-color lines changed).

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SKIN-01 | Block 1-4 use mineral hex; zero non-color diff | manual diff review + script | `git diff rulestead_admin/priv/static/css/rulestead_admin.css` | ✅ (CSS file exists) |
| SKIN-02 | `check_synced_pair.py` exits 0; WCAG-AA both themes pass | automated | `python3 scripts/check_synced_pair.py && python3 scripts/check_contrast.py` | ✅ |
| SKIN-02 | Block 1≡4 light pair identical (D-05a) | automated after extension | `python3 scripts/check_synced_pair.py` (post-extension) | ❌ Wave 0: extend script |
| SKIN-03 | `check_brand_tokens.py` exits 0 (Block 1 light) | automated | `python3 scripts/check_brand_tokens.py` | ✅ (exits 1 now → must exit 0 post-re-skin) |
| SKIN-03 | Block 3 dark hex matches tokens.json (D-05b) | automated after extension | `python3 scripts/check_brand_tokens.py` (post-extension) | ❌ Wave 0: extend script |

### Sampling Rate

- **Per task commit:** `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py` (exits 0 or shows specific mismatch — fast, no Elixir needed)
- **Per wave merge:** All four guard scripts: `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_contrast.py`
- **Phase gate:** Full lint.sh run (`bash scripts/ci/lint.sh` from repo root) — all four guard scripts green + full Elixir suite

### Wave 0 Gaps

The two guard script extensions are the only "test infrastructure" gaps:

- [ ] `scripts/check_synced_pair.py` — extend to also assert Block 1≡4 (D-05a)
- [ ] `scripts/check_brand_tokens.py` — extend to also diff Block 3 vs `admin_css_mapping.dark` (D-05b)

These extensions ARE the test infrastructure. They must exist and exit 0 before the phase closes. Creating them is part of the phase work, not a pre-condition.

*(All other test infrastructure — `check_contrast.py`, `check_tokens_css.py` — exists and passes already.)*

---

## Security Domain

This phase makes no changes to authentication, session management, access control, or cryptography. It is a static CSS file edit and Python stdlib script extension. No ASVS categories apply. `security_enforcement` is not explicitly set to false in config.json, but no security-relevant surfaces are touched.

| ASVS Category | Applies | Rationale |
|---------------|---------|-----------|
| V2 Authentication | No | No auth code changed |
| V3 Session Management | No | No session code changed |
| V4 Access Control | No | No access control changed |
| V5 Input Validation | No | No user input processed |
| V6 Cryptography | No | No crypto code changed |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 | Guard script extensions + validation | ✓ | system python3 | None needed |
| `brandbook/tokens.json` | Authoritative hex targets | ✓ | committed (Phase 96) | None — blocking if absent |
| `scripts/check_synced_pair.py` | D-05a base | ✓ | exists | None |
| `scripts/check_brand_tokens.py` | D-05b base | ✓ | exists | None |
| `scripts/check_contrast.py` | SC-4 AA gate | ✓ | exists, passes 18 checks | None |
| `scripts/check_tokens_css.py` | Must stay green | ✓ | exists, green | None |
| `scripts/ci/lint.sh` | CI wiring | ✓ | exists | None |
| `mix phx.digest` | CSS fingerprinting | ✓ (Elixir/Phoenix) | — | None |

**Missing dependencies with no fallback:** None — all dependencies are committed and available.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic Tailwind-blue primary (#2563eb) | Mineral Stead Blue (#3A6F8F) | Phase 98 | Admin UI reflects brand identity |
| Generic green success (#15803d) | Mineral success (#2d7753, AA-verified on Stone Mist) | Phase 98 | Closes Gap-2 from Phase 95 |
| Generic dark-mode generics (#4ade80, #fbbf24, #f87171) | Mineral dark-mode (#488d6b, #B57A21, #bf6464) | Phase 98 | Replaces v1.13 shipped non-mineral dark |
| Light pair (1≡4) unguarded | Machine-verified by check_synced_pair.py extension | Phase 98 | Closes verification gap documented in CONTEXT.md |
| Dark hex correctness unguarded | Machine-verified by check_brand_tokens.py extension | Phase 98 | Closes second verification gap |

---

## Assumptions Log

All claims in this research were verified by direct file inspection or live script execution in this session. No assumed claims.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

---

## Open Questions

1. **lint.sh CWD bug — confirmed present or already fixed?**
   - What we know: STATE.md documents "pre-existing CWD bug (check_synced_pair.py relative path fails after `cd rulestead/`) — fix before Phase 98 closes." lint.sh line 6 does `cd "${RULESTEAD_REPO}/rulestead"`. Guard scripts use relative paths internally and are invoked with absolute paths.
   - What's unclear: Whether the guard scripts can successfully open their relative-path files when the CWD is `${RULESTEAD_REPO}/rulestead` vs `${RULESTEAD_REPO}`. Running guard scripts manually from repo root works (confirmed by live run). Running via lint.sh may fail.
   - Recommendation: Plan 98-01 (or Wave 0) should include a lint.sh CWD fix: insert `cd "${RULESTEAD_REPO}"` before line 18. Low risk, one line.

2. **D-05a success message format — merged or separate line?**
   - What we know: CONTEXT.md says "planner's choice; keep lint.sh parsing stable." lint.sh only checks exit codes (no output parsing at lines 18/22/27).
   - What's unclear: Whether the Nyquist verification script or any other consumer parses the success string.
   - Recommendation: Safest option is to keep the existing dark-pair success line intact and add a second line for the light pair: e.g., `SYNCED PAIR IDENTICAL (dark: 56 tokens, light: N tokens)` or two separate prints. Either works.

---

## Sources

### Primary (HIGH confidence)

- Direct file inspection: `scripts/check_synced_pair.py` — full source read, all function signatures and line numbers verified
- Direct file inspection: `scripts/check_brand_tokens.py` — full source read, all function signatures and line numbers verified  
- Direct file inspection: `scripts/check_contrast.py` — `PALETTE_CHECKS` matrix at `:144-214` verified; dark targets confirmed
- Direct file inspection: `scripts/check_tokens_css.py` — full source read; confirmed green and unchanged in Phase 98
- Direct file inspection: `scripts/ci/lint.sh` — line numbers 18/22/27 for script invocations; `set -euo pipefail` exit semantics
- Direct file inspection: `rulestead_admin/priv/static/css/rulestead_admin.css` — block boundaries `:225-303`, `:305-386`, `:388-467`, `:469-549`; `:root` at `:39-119`; header comment at `:186-193`
- Direct file inspection: `brandbook/tokens.json` — `admin_css_mapping.light` at `:302-346`, `admin_css_mapping.dark` at `:348-387`
- Direct file inspection: `rulestead_admin/priv/static/design-system.html` — `var(--rs-*)` swatches confirmed at `:213-274`; scaffold literals `#333` at `:57`, `#888` at `:361`
- Live script run: `python3 scripts/check_brand_tokens.py` — confirmed 7 mismatches, matches D-04 hand-listed set exactly
- Live script run: `python3 scripts/check_synced_pair.py` — confirmed `SYNCED PAIR IDENTICAL (56 tokens)` (dark pair)
- Live script run: `python3 scripts/check_contrast.py` — confirmed `CONTRAST CHECK PASS (18 checks)` — all mineral targets AA-valid
- Live script run: `python3 scripts/check_tokens_css.py` — confirmed `TOKENS.CSS MIRROR SYNCED (68 tokens)`

### Secondary (MEDIUM confidence)

None — all claims derived from direct inspection.

### Tertiary (LOW confidence)

None.

---

## Metadata

**Confidence breakdown:**
- CSS block line ranges: HIGH — verified by direct read of file
- Changing-token set (light): HIGH — confirmed by live script run (7 mismatches match D-04 exactly)
- Changing-token set (dark): HIGH — verified by cross-checking tokens.json dark vs CSS Block 3 directly
- Guard script structure: HIGH — full source read; functions, exit codes, output strings verified
- lint.sh parse points: HIGH — verified line numbers 18/22/27 by direct inspection
- CWD bug: MEDIUM — STATE.md documents it; lint.sh structure confirms the risk; not confirmed to cause failure in actual CI run

**Research date:** 2026-06-05
**Valid until:** Stable — CSS and scripts are hand-authored; no version churn expected. Valid for the full Phase 98 planning window.
