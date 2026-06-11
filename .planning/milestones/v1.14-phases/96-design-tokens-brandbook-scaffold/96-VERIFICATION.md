---
phase: 96-design-tokens-brandbook-scaffold
verified: 2026-06-04T21:33:13Z
status: passed
score: 5/5
overrides_applied: 0
resolution:
  item: "'border' token group interpretation (TOK-03 / ROADMAP SC-1)"
  decision: "Accepted interpretation (a): the 'border' token group is realized as border-COLOR tokens — semantic `--rs-border`, `--rs-border-subtle`, `--rs-border-strong` and per-status `--rs-*-border`, all present in tokens.json semantic/state groups and `admin_css_mapping`. The shipped `rulestead_admin.css` has no literal border-width/border-style scalar to mirror, so a standalone invariant `border` group was deliberately omitted by 96-01-PLAN.md. Fabricating a border-width token absent from the shipped CSS would violate the locked mirror-not-generate principle (tokens.css must mirror the shipped `--rs-*` shape)."
  rationale: "Resolved in-orchestrator per the architect-default methodology (immaterial token-completeness nuance — not public API / security / release shape). Consistent with three existing signals: (1) owner marked TOK-03 [x] Complete in REQUIREMENTS.md; (2) planner deliberately omitted the invariant border scalar; (3) border colors are genuinely present. No artifact change required."
  resolved: 2026-06-04
---

# Phase 96: Design Tokens (`brandbook/` scaffold) — Verification Report

**Phase Goal:** The `brandbook/` directory tree is committed with machine-readable `tokens.json` (DTCG 2025.10), a hand-authored `tokens.css` mirror, the `check_brand_tokens.py` drift-check script, and additive CI lint extensions — and the drift check demonstrably FAILS on the un-re-skinned admin CSS, confirming the guard works before Phase 98 touches the cascade.
**Verified:** 2026-06-04T21:33:13Z
**Status:** passed (the single human-verification item — the 'border' token-group interpretation — was resolved in-orchestrator; see `resolution` in frontmatter)
**Re-verification:** No — initial verification, one flagged interpretation resolved by architect decision

> **Gate-Zero Framing (carried through entire report):** `python3 scripts/check_brand_tokens.py` exiting 1 is the PASS state for Phase 96. `scripts/ci/lint.sh` exiting non-zero (because it runs that check under `set -euo pipefail`) is the documented intended consequence of this gate-zero phase. Neither is a defect.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `brandbook/tokens.json` is valid DTCG 2025.10 JSON with `$value`/`$type`/`$description` leaves, primitive/light/dark/invariant/admin_css_mapping top-level groups | VERIFIED | `python3 -c "import json; json.load(open('brandbook/tokens.json'))"` exits 0; all required groups present; `$value` leaves confirmed in primitive and light/dark groups |
| 2 | `tokens.json` has light/dark group split (NOT `$extensions` modes) per D-02, with all 12 semantic+state roles in each (default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted) | VERIFIED | Light group keys: default, hover, active, focus, disabled, selected, success, success-stone-mist, warning, error, danger-stone-mist, info, subtle, muted — all 12 required roles present |
| 3 | `tokens.json` has `admin_css_mapping` with exactly 37 light `--rs-*` tokens and 31 dark `--rs-*` tokens; `--rs-neutral-700` in light only; `--rs-disabled-bg`/`--rs-disabled-text` in dark only | VERIFIED | 37 light `--rs-*` keys (excluding `$description` metadata); 31 dark `--rs-*` keys; asymmetries confirmed |
| 4 | `admin_css_mapping.light['--rs-primary']` = `#3A6F8F` (and 6 other primary mismatch tokens guarantee exit 1) | VERIFIED | `python3` assertion: `m['--rs-primary'].upper() == '#3A6F8F'` passes; all 7 mismatch tokens confirmed in mapping |
| 5 | `admin_css_mapping` maps only hex-literal `--rs-*` tokens; excludes `var()`, `rgba()`, and shadow composites | VERIFIED | All 37 light / 31 dark values are bare hex strings; no `var()` or `rgba()` values present |
| 6 | `brandbook/tokens.css` exists as valid CSS with `:root` invariant block + `.rs-shell`/`[data-rulestead]` light block + `[data-theme="dark"]` dark block + commented Tailwind excerpt | VERIFIED | File parses; `:root` block confirmed (no color tokens); light block has `--rs-primary: #3A6F8F`; dark block has `--rs-primary: #5885a0` (aligned spacing, functionally correct); `rs-stead-blue` in Tailwind comment block |
| 7 | `tokens.css` scope never uses `:root` or `<html>` for color (D-05) | VERIFIED | Python assertion: `--rs-primary` not in `:root` block; no `html` color scope found |
| 8 | `scripts/check_brand_tokens.py` exists, is executable, uses python3 stdlib only (`sys`, `re`, `json`) | VERIFIED | `test -x` passes; 3 imports confirmed (`sys`, `re`, `json`); `python3 -c "import ast; ast.parse(...)"` exits 0 |
| 9 | `check_brand_tokens.py` strips CSS comments BEFORE selector search (Pitfall 3) | VERIFIED | Line 54: `css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)` executes before `css.find(".rs-shell,")` on line 55 |
| 10 | `check_brand_tokens.py` exits 1 with "BRAND TOKEN DRIFT DETECTED" and ≥7 per-token diff lines against un-re-skinned CSS — **THIS IS THE PHASE PASS CONDITION** | VERIFIED | Exit code 1 confirmed; 7-token diff output: `--rs-primary`, `--rs-primary-hover`, `--rs-accent`, `--rs-success`, `--rs-warning`, `--rs-error`, `--rs-critical` |
| 11 | `scripts/ci/lint.sh` has brand-token check + SVG size-budget loop appended additively; all 15 original lines preserved | VERIFIED | Original lines 1–15 intact (shebang, set -euo pipefail, mix commands); appended: `check_synced_pair.py` call, `check_brand_tokens.py` call, `shopt -s nullglob` + two SVG budget loops + `echo "SVG SIZE BUDGET OK"` |
| 12 | SVG budget loop is no-op-safe when no SVGs exist (`shopt -s nullglob`), uses `wc -c` (not `stat`) | VERIFIED | `shopt -s nullglob` present; `wc -c` used in both loops; `stat` absent; manual bash run with no SVG dirs prints "SVG SIZE BUDGET OK" and exits 0 |
| 13 | `brandbook/docs/brand-usage.md` exists with check script usage + intentional CI failure note + synced-pair rule | VERIFIED | File exists; `check_brand_tokens.py` count: 5; `SYNCED PAIR`/`synced pair` count: 3; `intentional` count: 3; `Phase 98` count: 5 |
| 14 | `prompts/rulestead-brand-book.md` is a pointer stub under 10 lines referencing `brandbook/brand-book.md` | VERIFIED | 4 lines; pointer comment + link to `brandbook/brand-book.md` present (count: 2) |
| 15 | `brandbook/brand-book.md` relocated from `prompts/` via `git mv`; history preserved (≥2 commits); §12 has AA-verified canonicals | VERIFIED | 3 commits via `git log --oneline --follow`; `#B96A3A` absent (count: 0); `#9b5931` present (count: 2); `#8f601a` present; `#606d66` present; `#2d7753` present; `#b04848` present |
| 16 | §12 has Gap-2 per-surface notes for Success and Danger on Stone Mist; §8 tagline "Runtime decisions, made clear." intact | VERIFIED | `Gap 2` count: 2; `Runtime decisions, made clear` count: 3 |
| 17 | Regression: `check_synced_pair.py` exits 0 (Block 2≡3 invariant undisturbed) | VERIFIED | "SYNCED PAIR IDENTICAL (56 tokens)" — exit 0 |
| 18 | Regression: `check_contrast.py` exits 0 (Phase 95 AA palette intact) | VERIFIED | "CONTRAST CHECK PASS (18 checks)" — exit 0 |

**Score: 5/5 success criteria verified (plus 18 detailed truth checks, all VERIFIED)**

---

### Deferred Items

None — no truths identified as deferred to later phases.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/tokens.json` | DTCG 2025.10 canonical token record with `admin_css_mapping` | VERIFIED | Valid JSON; 37 light + 31 dark hex tokens; all DTCG structure confirmed |
| `brandbook/tokens.css` | CSS `--rs-*` reference mirror, light+dark, Tailwind excerpt | VERIFIED | `:root` invariant block + two-block light/dark + commented Tailwind excerpt |
| `scripts/check_brand_tokens.py` | Executable drift check, exits 1 against generic CSS | VERIFIED | Executable; exits 1; 7-token diff; stdlib only |
| `scripts/ci/lint.sh` | Extended with brand-token check + SVG budget loop (additive) | VERIFIED | 15 original lines preserved; 3 new sections appended |
| `brandbook/brand-book.md` | Canonical brand book (relocated from `prompts/` via git mv) | VERIFIED | History: 3 commits; §12 reconciled; Gap-2 notes present |
| `brandbook/README.md` | Directory index cross-linking brandbook/ files | VERIFIED | 23 lines; `tokens.json` reference present |
| `brandbook/docs/brand-usage.md` | Re-skin guide + check script usage notes | VERIFIED | All required sections present |
| `prompts/rulestead-brand-book.md` | Pointer stub, under 10 lines | VERIFIED | 4 lines; pointer to `brandbook/brand-book.md` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `brandbook/tokens.json admin_css_mapping.light` | `scripts/check_brand_tokens.py` | `json.load(TOKENS_JSON)['admin_css_mapping']['light']` | WIRED | Line 51 of check_brand_tokens.py; `admin_css_mapping` pattern confirmed |
| `scripts/check_brand_tokens.py` | `rulestead_admin/priv/static/css/rulestead_admin.css Block 1` | `extract_css_decls(css, ".rs-shell,")` | WIRED | `.rs-shell,` selector search confirmed; brace-walk extraction functional |
| `scripts/ci/lint.sh` | `scripts/check_brand_tokens.py` | `python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"` | WIRED | Line 22 of lint.sh; confirmed by grep count: 1 |
| `prompts/rulestead-brand-book.md` | `brandbook/brand-book.md` | pointer comment + markdown link | WIRED | Both pointer comment and link present; count: 2 |
| `brandbook/docs/brand-usage.md` | `scripts/check_brand_tokens.py` | usage instructions | WIRED | `check_brand_tokens.py` referenced 5× in brand-usage.md |

---

### Data-Flow Trace (Level 4)

Not applicable — phase produces static config files and a CLI drift-check script (no dynamic rendering components).

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Drift check exits 1 with per-token diff (gate-zero PASS) | `python3 scripts/check_brand_tokens.py; echo "exit: $?"` | "BRAND TOKEN DRIFT DETECTED" + 7-line diff + exit: 1 | PASS |
| Drift check output includes `--rs-primary` mismatch | `python3 scripts/check_brand_tokens.py 2>&1 \| grep -- '--rs-primary'` | `--rs-primary: tokens.json=#3A6F8F  css=#2563eb` | PASS |
| `check_synced_pair.py` exits 0 (regression guard) | `python3 scripts/check_synced_pair.py` | "SYNCED PAIR IDENTICAL (56 tokens)" + exit 0 | PASS |
| `check_contrast.py` exits 0 (regression guard) | `python3 scripts/check_contrast.py` | "CONTRAST CHECK PASS (18 checks)" + exit 0 | PASS |
| SVG budget loop is no-op when no SVGs exist | bash excerpt from lint.sh with `shopt -s nullglob` | "SVG SIZE BUDGET OK" + exit 0 | PASS |
| `tokens.json` parses as valid JSON | `python3 -c "import json; json.load(open('brandbook/tokens.json'))"` | exit 0 (no exception) | PASS |
| `check_brand_tokens.py` metadata key exclusion | `python3 << 'EOF'` (count `--rs-*` keys in mapping) | 37 light, 31 dark `--rs-*` keys | PASS |

---

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` files declared for this phase. Not applicable.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TOK-01 | 96-01, 96-03, 96-04 | `tokens.json` DTCG format with light and dark values | SATISFIED | Valid DTCG 2025.10 JSON; primitive/light/dark/invariant structure; `$value`/`$type`/`$description` leaves |
| TOK-02 | 96-01 | `tokens.css` CSS custom properties mirroring `--rs-*` shape for light and dark | SATISFIED | `:root` invariant block + `.rs-shell` light block + `[data-theme="dark"]` dark block; `--rs-primary: #3A6F8F` in light; `--rs-primary: #5885a0` in dark |
| TOK-03 | 96-01, 96-03, 96-04 | Semantic + state roles + spacing/radius/**border**/shadow/focus-ring/code-block/callout primitives | UNCERTAIN | Semantic+state roles: all 12 covered in light/dark groups. Invariant groups confirmed: spacing, radius, shadow, focus-ring, code-block, callout. **'border' is absent from invariant.** The `:root` CSS has no border invariant tokens (all `--rs-border*` tokens are variant, in per-theme blocks, using `var(--rs-neutral-*)` — not literal values). The 96-01 plan spec deliberately omitted border from invariant for this reason. See Human Verification item. |
| TOK-04 | 96-01 | Optional Tailwind token excerpt | SATISFIED | Commented-out Tailwind v3/v4 config excerpt at end of `tokens.css`; includes 10 `rs-*` color keys |

---

### Anti-Patterns Found

Phase-modified files scanned: `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/brand-book.md`, `brandbook/README.md`, `brandbook/docs/brand-usage.md`, `scripts/check_brand_tokens.py`, `scripts/ci/lint.sh`, `prompts/rulestead-brand-book.md`.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| _(none)_ | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` debt markers found in any phase-modified file. No stub patterns or empty implementations found.

One cosmetic inconsistency noted (not a stub): `brandbook/tokens.css` dark block uses aligned spacing (`--rs-primary:       #5885a0`) while the light block uses a single space. String equality check `'--rs-primary: #5885a0' in css` would fail, but all grep/regex-based checks pass. Functionally correct; noted in executor's SUMMARY.

---

### Human Verification Required

#### 1. TOK-03 `border` token group in `invariant`

**Test:** Review whether the omission of a standalone `border` token group in `brandbook/tokens.json`'s `invariant` section satisfies TOK-03 ("Tokens cover semantic + state roles … plus spacing, radius, **border**, shadow, focus-ring, code-block, and callout primitives") and ROADMAP SC-1.

**Expected:** One of:
- (a) Accept that the `--rs-border*` variant tokens captured in `admin_css_mapping` (e.g. `--rs-success-border`, `--rs-error-border`) fulfill the "border primitives" intent of TOK-03 — because the `:root` CSS block contains zero border-width or border-style invariant tokens to encode (all `--rs-border*` values are `var(--rs-neutral-*)` references, which are theme-dependent). In this reading, "border" in the requirement refers to the token shape category, which IS present in admin_css_mapping.
- (b) Decide a `border` group should be added to `invariant` anyway (e.g. `invariant.border.width: { "$value": "1px" }`) as a stub for future use, to satisfy the literal requirement wording.

**Why human:** Automated verification cannot determine which interpretation of "border primitives" the requirement author intended. The `:root` CSS has no border scalars. The 96-01-PLAN.md task spec omitted `border` from invariant explicitly after reading the CSS. The project owner marked TOK-03 `[x]` Complete in REQUIREMENTS.md. This is a spec-wording interpretation decision, not a missing feature.

---

### Gaps Summary

No blocking gaps found. The five ROADMAP success criteria (SC-1 through SC-5) are all verifiably satisfied in the codebase:

- **SC-1** (tokens.json DTCG structure + admin_css_mapping): VERIFIED
- **SC-2** (tokens.css `--rs-*` mirror + Tailwind excerpt): VERIFIED  
- **SC-3** (check_brand_tokens.py exits 1 — THE PASS CONDITION): VERIFIED, exit code 1 confirmed
- **SC-4** (lint.sh additive extensions + docs): VERIFIED
- **SC-5** (brand-book.md canonical relocation + §12 reconciliation): VERIFIED

The single human verification item is a `border` token group interpretation question on TOK-03. It does not block the core phase goal — the drift guard mechanism is proven, all artifacts are committed and functional, and all five roadmap success criteria pass. The status is `human_needed` solely because the requirement wording ambiguity requires a human interpretation call.

**Regressions:** None. `check_synced_pair.py` exits 0 (56 tokens). `check_contrast.py` exits 0 (18 checks). `rulestead_admin.css` was not touched.

---

_Verified: 2026-06-04T21:33:13Z_
_Verifier: Claude (gsd-verifier)_
