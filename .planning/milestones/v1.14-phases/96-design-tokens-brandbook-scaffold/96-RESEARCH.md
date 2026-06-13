# Phase 96: Design Tokens (`brandbook/` scaffold) — Research

**Researched:** 2026-06-04
**Domain:** DTCG token format, Python 3 stdlib drift-check scripting, CSS custom-property extraction, brand-book relocation, additive CI extension
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `tokens.json` is DTCG 2025.10 three-tier model: `primitive` → `semantic` → `state`. Scalar groups (spacing, radius, border, shadow, focus-ring, code-block, callout) live in one shared **invariant** group.
- **D-02:** Light vs dark color values are expressed by a **top-level `light` / `dark` group split** — NOT `$extensions` modes.
- **D-03:** `tokens.json` includes a top-level **`admin_css_mapping`** dict with `light` and `dark` sub-objects, each mapping every **variant** `--rs-*` token name → its resolved value. Invariant `:root` tokens are excluded.
- **D-04:** All token values come verbatim from the LOCKED Phase 95 record (`95-PALETTE-RECONCILIATION.md`). Gap-2 per-surface canonicals (`#2d7753` Success, `#b04848` Danger on Stone Mist) are encoded as per-surface token values. Phase 96 **encodes, never recomputes**.
- **D-05:** `tokens.css` is a canonical reference mirror with a **simplified two-block light/dark pair** (`.rs-shell, [data-rulestead]` and `.rs-shell[data-theme="dark"], [data-rulestead][data-theme="dark"]`) + shared `:root` invariant block. Scope stays `.rs-shell` / `[data-rulestead]` only — never `:root`/`<html>` for color.
- **D-06:** TOK-04 Tailwind excerpt is embedded as a trailing **commented-out CSS block** in `tokens.css`.
- **D-07:** `scripts/check_brand_tokens.py` reads `brandbook/tokens.json`, extracts `admin_css_mapping.light`, compares each `--rs-*` value against Block 1 of `rulestead_admin.css`. Pass message: `BRAND TOKENS SYNCED (N tokens)`. Mismatch: per-token diff (`--rs-primary: tokens.json=#3A6F8F  css=#2563eb`) and exits 1. Executable, composable with `check_synced_pair.py`.
- **D-08:** The check **must FAIL now** (exit 1) against un-re-skinned admin CSS. This is success criterion 3. Light Block 1 is required minimum; dark Block 3 comparison is additive.
- **D-09:** Committed tree: `brandbook/{brand-book.md, tokens.json, tokens.css, README.md, docs/brand-usage.md}`.
- **D-10:** Edits to `scripts/ci/lint.sh` are **strictly additive**. Append (a) `python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"` and (b) no-op-safe SVG size-budget loop.
- **D-11:** Relocate via `git mv prompts/rulestead-brand-book.md brandbook/brand-book.md`. Handle the existing `M prompts/rulestead-brand-book.md` working-tree edit first. Leave pointer comment in `prompts/rulestead-brand-book.md`.
- **D-12:** §12 hex rework — replace flagged hex literals with AA-verified canonicals. §8 tagline "Runtime decisions, made clear." needs NO change.

### Claude's Discretion

- Exact DTCG `$type` choices per leaf, group/key casing, and `$description` wording — follow DTCG 2025.10.
- Whether `check_brand_tokens.py` additionally diffs dark Block 3.
- Exact wording/structure of `README.md` and `docs/brand-usage.md` stubs.
- Pointer-comment syntax in the `prompts/` stub.

### Deferred Ideas (OUT OF SCOPE)

- Admin CSS re-skin — Phase 98.
- Logo/mark SVGs — Phase 97.
- Specimen SVGs — Phase 99.
- `VOICE.md`, `RELEASE-TEMPLATE.md`, `BUDGET.md`, final `README.md`, BRD-03 szTheory note — Phase 100.
- tokens.css ↔ tokens.json cross-check script — not this phase.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOK-01 | `brandbook/tokens.json` expresses raw → semantic → state tokens in DTCG format with light and dark values | DTCG 2025.10 spec verified; exact $type values, group nesting, alias syntax documented below |
| TOK-02 | `brandbook/tokens.css` emits CSS custom properties mirroring the shipped `--rs-*` token shape for light and dark | Full Block 1/Block 3 token inventory extracted; 57 light / 56 dark tokens; CSS structure documented |
| TOK-03 | Tokens cover semantic + state roles plus spacing, radius, border, shadow, focus-ring, code-block, and callout primitives | Invariant `:root` token categories confirmed; semantic/state role list from CONTEXT.md D-01 |
| TOK-04 | Optional Tailwind token excerpt provided for downstream marketing/site reuse | Commented-out CSS block pattern specified; mineral hex references documented |
</phase_requirements>

---

## Summary

Phase 96 has no ambiguous architecture decisions — all structural choices were locked in CONTEXT.md D-01..D-12. The research job is to surface the exact implementation details the planner needs to produce unambiguous task descriptions: precise DTCG format rules, the exact check script algorithm, the exact lint.sh bash fragment, the exact §12 hex substitution table, and the concrete edge cases that will bite if not handled explicitly.

**DTCG 2025.10** is a stable W3C Community Group specification (published 2025-10-28). It uses a JSON object model where token leaves are objects containing `$value` (required) and optional `$type`, `$description`, `$deprecated`, `$extensions`. Groups are objects without `$value`. The `{group.token}` curly-brace alias syntax references the full `$value` of the target token. The `$type` property on a group is inherited by all descendant leaves that do not override it. Valid types: `color`, `dimension`, `fontFamily`, `fontWeight`, `duration`, `cubicBezier`, `number` (primitives) plus `strokeStyle`, `border`, `transition`, `shadow` (composites).

**check_brand_tokens.py** must mirror `check_synced_pair.py` exactly: strip CSS comments (`re.sub(r"/\*.*?\*/", "", raw, flags=re.S)`), locate Block 1 selector (`.rs-shell,`), brace-depth walk to extract all `--rs-*` declarations, compare against `admin_css_mapping.light` values from `tokens.json`. The script gets its JSON validity check for free (json.load raises on malformed JSON). The intentional exit-1 is caused by 6+ tokens where Block 1 has generic hexes (`#2563eb`, `#9a3f12`, `#15803d`, `#b45309`, `#b91c1c`) but `admin_css_mapping` encodes the mineral canonicals (`#3A6F8F`, `#9b5931`, `#2d7753`, `#8f601a`, `#B44949`).

The SVG budget loop in lint.sh must use `wc -c` (not `stat`) for cross-platform portability — CI runs on Ubuntu 24.04 where `stat -c%z` works but `stat -f%z` (macOS form) would break. `shopt -s nullglob` under `set -euo pipefail` safely makes the empty-glob case a no-op.

**Primary recommendation:** Implement in three waves: (1) tokens.json + tokens.css authored in one commit, (2) check_brand_tokens.py + lint.sh extension in one commit, (3) brand-book relocation + §12 rework + docs stubs in one commit. Wave 1 and Wave 2 are independent in authoring but Wave 2 depends on Wave 1 being present. Wave 3 is independent.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token canonical record (tokens.json) | `brandbook/` (repo artifact) | — | Human-readable source of truth, no build step; consumed by drift check and Phase 97/98/99 |
| CSS reference mirror (tokens.css) | `brandbook/` (repo artifact) | — | Hand-authored; mirrors `--rs-*` shape for documentation and TOK-04 Tailwind use |
| Drift check script (check_brand_tokens.py) | `scripts/` (CI surface) | — | Composable with check_synced_pair.py; wired into lint.sh |
| CI lint extension (lint.sh) | `scripts/ci/` | — | Strictly additive append; runs on Ubuntu 24.04 under set -euo pipefail |
| Brand book (brand-book.md) | `brandbook/` (repo artifact) | `prompts/` (pointer stub) | git mv preserves history; prompts/ keeps a pointer |
| Color scope enforcement | Frontend Server (admin CSS) | — | `.rs-shell`/`[data-rulestead]` only, never `:root`/`<html>` — existing discipline |

---

## DTCG 2025.10 Format Specifics

[CITED: https://www.designtokens.org/tr/2025.10/format/]

### Valid `$type` Values

Primitive types: `color`, `dimension`, `fontFamily`, `fontWeight`, `duration`, `cubicBezier`, `number`

Composite types: `strokeStyle`, `border`, `transition`, `shadow`

Note: `shadow` composite value shape is `{ color, offsetX, offsetY, blur, spread }` where dimension values are `{ value: number, unit: "px" | "rem" | … }`.

### Alias Reference Syntax

```
"{group.subgroup.token-name}"
```

The curly-brace syntax resolves to the complete `$value` of the referenced token. It cannot reference partial values or non-token paths. Example:

```json
"--rs-primary": {
  "$type": "color",
  "$value": "{primitive.stead-blue.base}"
}
```

### Group-level `$type` Inheritance

A `$type` property set on a group is inherited by all descendant leaves that do not override it. This means the `primitive.color` group can carry `"$type": "color"` and all color leaf tokens within it inherit `color` type without repeating it per-leaf.

### Token Leaf vs Group Rule

A token MUST have `$value`. A group MUST NOT have `$value`. They cannot coexist on the same object.

### Concrete JSON Skeleton (primitive → semantic → state, with top-level light/dark and admin_css_mapping)

```json
{
  "primitive": {
    "$type": "color",
    "stead-blue": {
      "base": {
        "$value": "#3A6F8F",
        "$description": "Stead Blue — primary brand; passes all light surfaces (5.45:1 W, 4.57:1 SM, 5.07:1 RT)"
      },
      "dark": {
        "$value": "#5885a0",
        "$description": "Stead Blue AA-lightened for dark surface #10161f — 4.563:1"
      }
    },
    "ember-copper": {
      "base": {
        "$value": "#9b5931",
        "$description": "Ember Copper canonical — Stone Mist passing (4.550:1); passes W and RT"
      },
      "dark": {
        "$value": "#ba6b3c",
        "$description": "Ember Copper AA-lightened for dark surface — 4.545:1; OKLCH drift 0.37deg"
      }
    },
    "neutral": {
      "ramp-0-light": { "$value": "#ffffff" },
      "ramp-900-light": { "$value": "#1a2332" }
    }
  },
  "light": {
    "$type": "color",
    "primary": {
      "$value": "{primitive.stead-blue.base}",
      "$description": "Brand primary in light mode"
    },
    "success": {
      "$value": "{primitive.success.canonical}",
      "$description": "Success canonical — use #2d7753 on Stone Mist (Gap 2)"
    }
  },
  "dark": {
    "$type": "color",
    "primary": {
      "$value": "{primitive.stead-blue.dark}",
      "$description": "Brand primary in dark mode"
    }
  },
  "invariant": {
    "spacing": {
      "$type": "dimension",
      "space-1": { "$value": "0.25rem", "$description": "--rs-space-1" }
    },
    "radius": {
      "$type": "dimension",
      "sm": { "$value": "6px" }
    }
  },
  "admin_css_mapping": {
    "light": {
      "--rs-primary": "#3A6F8F",
      "--rs-accent": "#9b5931"
    },
    "dark": {
      "--rs-primary": "#5885a0",
      "--rs-accent": "#ba6b3c"
    }
  }
}
```

---

## Token Inventory: What Goes in admin_css_mapping

[VERIFIED from live codebase extraction]

### Scope Decision

`admin_css_mapping` maps **only hex-literal tokens** from Block 1 (light) and Block 3 (dark). The `var()`-reference alias tokens (`--rs-bg: var(--rs-neutral-50)` etc.) and `rgba()`/shadow composite tokens are EXCLUDED because:

1. They use non-hex values that cannot be expressed as simple DTCG `color` tokens.
2. Phase 98 will not change `var()` references — they stay as-is after re-skin.
3. The drift check does a string comparison; including var() refs would require a CSS resolver, violating the stdlib-only constraint.

### Block 1 (Light) — 37 Hex-Literal Tokens for `admin_css_mapping.light`

```
--rs-neutral-0: #ffffff        --rs-neutral-25: #f8fafc      --rs-neutral-50: #f4f6f8
--rs-neutral-100: #eef1f5      --rs-neutral-200: #e7ebf0      --rs-neutral-300: #d8dee6
--rs-neutral-400: #b8c2cf      --rs-neutral-500: #99a3af      --rs-neutral-600: #5c6b7a
--rs-neutral-700: #263241      --rs-neutral-900: #1a2332
--rs-primary: #2563eb          --rs-primary-hover: #1d4ed8    --rs-primary-soft: #dbeafe
--rs-on-primary: #ffffff       --rs-accent: #9a3f12           --rs-accent-soft: #fde8dc
--rs-success: #15803d          --rs-success-hover: #166534    --rs-success-soft: #dcfce7
--rs-success-bg-subtle: #f7fff9 --rs-success-text: #047857   --rs-success-border: #86efac
--rs-warning: #b45309          --rs-warning-hover: #92400e    --rs-warning-soft: #fef3c7
--rs-warning-text: #a16207     --rs-warning-border: #fcd34d
--rs-error: #b91c1c            --rs-error-hover: #991b1b      --rs-error-soft: #fee2e2
--rs-error-bg-subtle: #fff7f7  --rs-error-text: #be123c       --rs-error-text-strong: #7f1d1d
--rs-error-border: #fca5a5     --rs-error-border-strong: #fecaca
--rs-critical: #b91c1c
```

`admin_css_mapping.light` stores the **Phase 98 TARGET** values (mineral canonicals from `95-PALETTE-RECONCILIATION.md §4`), not the current shipped generics.

### Block 3 (Dark) — 31 Hex-Literal Tokens for `admin_css_mapping.dark`

```
--rs-neutral-0: #10161f   --rs-neutral-25: #141c27   --rs-neutral-50: #19222e
--rs-neutral-100: #1f2a38  --rs-neutral-200: #253243   --rs-neutral-300: #2e3d52
--rs-neutral-400: #3d5168  --rs-neutral-500: #7a8fa3   --rs-neutral-600: #a8b9ca
--rs-neutral-900: #e8edf3
--rs-primary: #2563eb      --rs-primary-hover: #5a96f5
--rs-on-primary: #ffffff   --rs-accent: #e8834a
--rs-success: #4ade80      --rs-success-hover: #86efac  --rs-success-text: #4ade80
--rs-success-border: #166634
--rs-warning: #fbbf24      --rs-warning-hover: #fcd34d  --rs-warning-text: #fbbf24
--rs-warning-border: #78350f
--rs-error: #f87171        --rs-error-hover: #fca5a5    --rs-error-text: #f87171
--rs-error-text-strong: #fca5a5 --rs-error-border: #7f1d1d --rs-error-border-strong: #991b1b
--rs-critical: #f87171     --rs-disabled-bg: #253243    --rs-disabled-text: #6b84a0
```

### Light/Dark Asymmetries

**`--rs-neutral-700` is light-only** (in Block 1 / Block 4, absent from Block 2 / Block 3). This is a real architectural asymmetry. `admin_css_mapping.dark` simply omits it — do not invent a dark counterpart.

**Tokens in dark but NOT light (hex-value):** `--rs-disabled-bg` and `--rs-disabled-text` are hex-literal in dark (not var() references), but var() in light. Include in `admin_css_mapping.dark`; exclude from `admin_css_mapping.light`.

**No `--rs-info` family** exists in the shipped CSS. `tokens.json` defines `info` as a semantic role (`#356E8C` light / `#55859e` dark) but `admin_css_mapping` MUST NOT invent non-existent CSS names.

---

## Phase 98 Target Values for admin_css_mapping.light

[VERIFIED from 95-PALETTE-RECONCILIATION.md §4, §8 — maintainer-signed-off 2026-06-04]

These are the values tokens.json admin_css_mapping.light encodes. The current Block 1 has the generic hexes in the right column → mismatch → check exits 1.

| `--rs-*` name | `admin_css_mapping.light` TARGET | Block 1 CURRENT (generic) | Will cause FAIL? |
|---|---|---|---|
| `--rs-primary` | `#3A6F8F` | `#2563eb` | YES |
| `--rs-primary-hover` | (hover variant — planner must choose; e.g. `#2d5f7c` or darkened Stead Blue) | `#1d4ed8` | YES |
| `--rs-accent` | `#9b5931` | `#9a3f12` | YES |
| `--rs-success` | `#2d7753` | `#15803d` | YES |
| `--rs-warning` | `#8f601a` | `#b45309` | YES |
| `--rs-error` | `#B44949` | `#b91c1c` | YES |
| `--rs-critical` | `#B44949` | `#b91c1c` | YES |
| `--rs-neutral-*` ramp | (Phase 95 confirms ramp kept) | (same) | NO (ramp kept in Phase 98) |
| All soft/subtle/border variants | Phase 98 will derive these | (generic) | PLANNER NOTE: include canonical or current-kept values |

**Note on `--rs-primary-hover`:** The Phase 95 locked palette does not define a canonical hover variant for Stead Blue. The planner should use a darkened variant of `#3A6F8F` (approximately `#2d5f7c`) as the admin_css_mapping target. This is Claude's discretion per the context. [ASSUMED]

**Note on soft/subtle/border color tokens:** The `*-soft`, `*-bg-subtle`, `*-border` tokens in Block 1 (e.g. `--rs-success-soft: #dcfce7`) are generic Tailwind-derived values. Phase 98 will replace them with mineral-derived equivalents. The admin_css_mapping.light values should encode the expected Phase-98 mineral targets — or, if the mineral equivalents haven't been fully designed yet, they can be set to the same as the current CSS (so they don't contribute to the intentional fail count). The primary fail tokens are `--rs-primary`, `--rs-accent`, `--rs-success`, `--rs-warning`, `--rs-error`, `--rs-critical` — these six are sufficient to guarantee exit 1.

---

## Standard Stack

No new packages. Strictly stdlib Python 3 + bash.

| Tool | Version | Purpose | Provenance |
|------|---------|---------|-----------|
| `python3` | 3.x (any) | tokens.json authoring, check_brand_tokens.py | System Python |
| `re` (stdlib) | — | CSS comment strip + token extraction | [VERIFIED: stdlib] |
| `json` (stdlib) | — | tokens.json parsing (free validity check via json.load) | [VERIFIED: stdlib] |
| `sys` (stdlib) | — | exit codes | [VERIFIED: stdlib] |
| `bash` | POSIX | lint.sh SVG budget loop | [VERIFIED: CI environment] |
| `wc` | POSIX | File byte-size count (`wc -c < file`) | [VERIFIED: portable macOS+Linux] |

**No new packages to install.** Phase 96 is purely file-authoring + script-writing.

## Package Legitimacy Audit

> Not applicable — this phase installs zero external packages.

---

## Architecture Patterns

### System Architecture Diagram

```
prompts/rulestead-brand-book.md  ──git mv──►  brandbook/brand-book.md
         (M in git status)                      (§12 hexes reconciled)
                                                     │
                                         prompts/ stub with pointer comment
                                                     
95-PALETTE-RECONCILIATION.md §4/§8
  (LOCKED canonical hexes — input only)
         │
         ▼
brandbook/tokens.json  ──────────────────────────────►  admin_css_mapping.{light,dark}
  DTCG 2025.10                                              (Phase 98 target values)
  primitive/semantic/state                                        │
  light/dark groups                                               │
  invariant group                                                 ▼
         │                                           scripts/check_brand_tokens.py
         │                                             reads tokens.json admin_css_mapping
         ▼                                             extracts Block 1 of rulestead_admin.css
brandbook/tokens.css                                   compares value-by-value
  --rs-* mirror (2-block light/dark)                   exits 1 NOW (generic hexes ≠ mineral targets)
  + :root invariant block                              exits 0 AFTER Phase 98 re-skin
  + commented Tailwind excerpt (TOK-04)
         │
         ▼
scripts/ci/lint.sh  (ADDITIVE APPEND)
  ... existing lines ...
  python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"    ← NEW (exits 1 this phase)
  shopt -s nullglob; for svg loop ≤20KB/≤50KB budget           ← NEW (exits 0 this phase)
  echo "SVG SIZE BUDGET OK"
```

### Recommended Project Structure (New Files)

```
brandbook/
├── brand-book.md          # git mv from prompts/; §12 hex-reconciled
├── tokens.json            # DTCG 2025.10 machine-readable tokens
├── tokens.css             # hand-authored --rs-* CSS mirror
├── README.md              # directory index stub (cross-links others)
└── docs/
    └── brand-usage.md     # re-skin + check_brand_tokens.py usage notes

scripts/
├── check_brand_tokens.py  # NEW: token drift check (exits 1 against current CSS)
└── ci/
    └── lint.sh            # EDITED: 2 lines appended (additive only)

prompts/
└── rulestead-brand-book.md  # REPLACED with pointer comment stub
```

---

## check_brand_tokens.py Design

[VERIFIED: mirrors check_synced_pair.py pattern from codebase]

### Algorithm

```python
#!/usr/bin/env python3
"""Token-drift check: brandbook/tokens.json admin_css_mapping vs rulestead_admin.css Block 1.

Usage (from repo root):
    python3 scripts/check_brand_tokens.py
Exits 0 and prints "BRAND TOKENS SYNCED (N tokens)" on success; exits 1 on mismatch.
"""
import sys
import re
import json

TOKENS_JSON = "brandbook/tokens.json"
CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"

def extract_css_decls(css, sel):
    """Strip comments, locate selector, brace-walk, return sorted --rs-* declarations dict."""
    i = css.find(sel)
    if i < 0:
        return None
    j = css.find("{", i)
    depth = 0
    k = j
    while k < len(css):
        if css[k] == "{":
            depth += 1
        elif css[k] == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    result = {}
    for line in css[j + 1 : k].splitlines():
        line = line.strip()
        if line.startswith("--rs-") and ":" in line:
            name, _, val = line.partition(":")
            result[name.strip()] = val.strip().rstrip(";")
    return result

def main():
    tokens = json.load(open(TOKENS_JSON))  # raises on malformed JSON — free validity check
    mapping = tokens["admin_css_mapping"]["light"]

    raw = open(CSS).read()
    css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first
    css_decls = extract_css_decls(css, ".rs-shell,")
    if css_decls is None:
        print("ERROR: Block 1 selector '.rs-shell,' not found in CSS")
        return 1

    mismatches = []
    matched = 0
    for name, expected in sorted(mapping.items()):
        css_val = css_decls.get(name)
        if css_val is None:
            mismatches.append(f"  {name}: tokens.json={expected}  css=<missing>")
        elif css_val.lower() != expected.lower():
            mismatches.append(f"  {name}: tokens.json={expected}  css={css_val}")
        else:
            matched += 1

    if not mismatches:
        print(f"BRAND TOKENS SYNCED ({matched} tokens)")
        return 0

    print("BRAND TOKEN DRIFT DETECTED")
    for m in mismatches:
        print(m)
    return 1

if __name__ == "__main__":
    sys.exit(main())
```

### Key Implementation Notes

1. **`json.load()` provides free JSON validity** — if `tokens.json` is malformed, the script raises `json.JSONDecodeError` and exits non-zero. No separate JSON validation step needed.

2. **Case-insensitive hex comparison** — use `.lower()` on both sides to handle `#3A6F8F` vs `#3a6f8f` equivalence.

3. **Comparison only on names in admin_css_mapping** — tokens NOT in `admin_css_mapping` (e.g. `--rs-focus-ring`, `--rs-shadow-sm`) are ignored. This is correct and intentional.

4. **`--rs-neutral-700` light-only asymmetry** — this token IS in Block 1 and will be in `admin_css_mapping.light`. If it's in the mapping, it gets compared. If the target value matches the current `#263241`, no mismatch. The planner must decide whether neutral ramp values change in Phase 98 — per `95-PALETTE-RECONCILIATION.md §5`, the neutral ramp is largely kept.

5. **Missing `--rs-info` family** — NOT in CSS, NOT in admin_css_mapping, no comparison attempted. Tokens.json defines `info` under semantic groups but it's intentionally absent from admin_css_mapping.

6. **Selector search pitfall** — `check_synced_pair.py` uses `css.find(sel)` after comment stripping. The selector `.rs-shell,` (with trailing comma) is sufficient to uniquely locate Block 1. Do not search the raw CSS before comment stripping — the token section comment documents the selectors and would match first.

### Expected Output When Run Against Current CSS (Phase 96 → exit 1)

```
BRAND TOKEN DRIFT DETECTED
  --rs-accent: tokens.json=#9b5931  css=#9a3f12
  --rs-critical: tokens.json=#B44949  css=#b91c1c
  --rs-error: tokens.json=#B44949  css=#b91c1c
  --rs-primary: tokens.json=#3A6F8F  css=#2563eb
  --rs-primary-hover: tokens.json=#2d5f7c  css=#1d4ed8
  --rs-success: tokens.json=#2d7753  css=#15803d
  --rs-warning: tokens.json=#8f601a  css=#b45309
  [... additional soft/border variants if included ...]
```

---

## lint.sh Additive Append

[VERIFIED: current lint.sh is 16 lines; runs under `set -euo pipefail` on Ubuntu 24.04]

### Exact Bash to Append

```bash
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"

# SVG size budget: logo ≤20KB, specimens ≤50KB. No-op when dirs don't exist (Phase 97/99).
shopt -s nullglob
for f in "${RULESTEAD_REPO}/brandbook/assets/logo/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 20480 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 20480)"
    exit 1
  fi
done
for f in "${RULESTEAD_REPO}/brandbook/assets/specimens/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 51200 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 51200)"
    exit 1
  fi
done
echo "SVG SIZE BUDGET OK"
```

### Key Implementation Details

- **`wc -c < "$f"`** is POSIX-portable (macOS + Linux). Output may have leading spaces on macOS — strip with `| tr -d ' '` or `"${size//[[:space:]]/}"`. The `| tr -d ' '` pipe is cleaner.
- **`stat` is NOT portable** — `stat -f%z` is macOS-only; `stat -c%z` is GNU/Linux only. CI runs on Ubuntu 24.04, but devs are on macOS. Use `wc -c` exclusively.
- **`shopt -s nullglob`** causes a glob pattern that matches no files to expand to zero words (empty list) instead of the literal pattern string. Under `set -euo pipefail`, an unset nullglob would cause the for loop to try to operate on the literal string `*.svg`, which would fail. Nullglob makes the loop simply not execute when the `assets/` dir doesn't exist yet.
- **Budget constants:** `20480` = 20KB for logos; `51200` = 50KB for specimens.
- **`shopt -s nullglob` scope:** `shopt` is bash-specific and persistent within the script session. Since lint.sh is `#!/usr/bin/env bash` (shebang inferred from set -euo pipefail — confirm bash header), this is safe. If the shebang were `#!/bin/sh`, nullglob would not be available.
- **CI intentional behavior:** `check_brand_tokens.py` will exit 1 and abort the lint job — this is the intentional outcome of Phase 96. CI is expected to fail on this step until Phase 98.

### lint.sh shebang verification

The current lint.sh starts with `#!/usr/bin/env bash` — confirmed by reading the file. `shopt -s nullglob` is a bash builtin and safe to use.

---

## DTCG tokens.json Full Group Structure

[CITED: DTCG 2025.10 spec; values from 95-PALETTE-RECONCILIATION.md §4/§5/§8]

### Top-Level Group Layout

```json
{
  "primitive": { ... },        // raw named colors + neutral ramp slots
  "light": { ... },            // semantic aliases resolved for light theme
  "dark": { ... },             // semantic aliases resolved for dark theme
  "invariant": { ... },        // spacing, radius, border, shadow, focus-ring, code-block, callout
  "admin_css_mapping": { ... } // --rs-* → resolved values (light + dark sub-dicts)
}
```

### `primitive` Group

Key sub-groups: `stead-blue`, `ember-copper`, `ink-blue`, `slate-stead`, `basalt`, `signal-gold`, `moss-grey`, `stone-mist`, `rain-tint`, `quarry`, plus `success`, `danger`, `warning`, `info`, and `neutral-ramp`.

All leaves under `primitive` use `"$type": "color"` (can be set at group level and inherited).

Signal Gold carries a `$description` noting the decorative-only policy.

### `light` Group — Semantic + State Aliases

```json
"light": {
  "$type": "color",
  "default":   { "$value": "{primitive.stead-blue.base}" },
  "hover":     { "$value": "{primitive.stead-blue.hover}" },
  "active":    { "$value": "{primitive.stead-blue.base}" },
  "focus":     { "$value": "{primitive.stead-blue.base}" },
  "disabled":  { "$value": "{primitive.neutral-ramp.500}" },
  "selected":  { "$value": "{primitive.stead-blue.base}" },
  "success":   { "$value": "{primitive.success.canonical}" },
  "success-stone-mist": { "$value": "{primitive.success.stone-mist}", "$description": "Gap 2 — use on Stone Mist surface only" },
  "warning":   { "$value": "{primitive.warning.canonical}" },
  "error":     { "$value": "{primitive.danger.canonical}" },
  "danger-stone-mist": { "$value": "{primitive.danger.stone-mist}", "$description": "Gap 2 — use on Stone Mist surface only" },
  "info":      { "$value": "{primitive.info.base}" },
  "subtle":    { "$value": "{primitive.neutral-ramp.600}" },
  "muted":     { "$value": "{primitive.neutral-ramp.500}" }
}
```

### `invariant` Group — Scalars

```json
"invariant": {
  "spacing": {
    "$type": "dimension",
    "space-1": { "$value": "0.25rem", "$description": "--rs-space-1" },
    ...
    "space-10": { "$value": "2.5rem", "$description": "--rs-space-10" }
  },
  "radius": {
    "$type": "dimension",
    "sm": { "$value": "6px" }, "md": { "$value": "10px" }, "lg": { "$value": "14px" },
    "xl": { "$value": "18px" }, "full": { "$value": "999px" }
  },
  "shadow": {
    "$type": "shadow",
    "sm": { "$value": { "color": "#1a2332", "offsetX": { "value": 0, "unit": "px" }, ... } }
  },
  "focus-ring": {
    "$type": "dimension",
    "offset": { "$value": "2px" }
  },
  "code-block": {
    "font": { "$type": "fontFamily", "$value": "IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace" }
  },
  "callout": {
    "radius": { "$type": "dimension", "$value": "10px" }
  }
}
```

---

## tokens.css Structure

[VERIFIED from rulestead_admin.css structure; decisions D-05, D-06]

### Two-Block Light/Dark + Invariant :root

```css
/* =========================================================
   Rulestead Design Tokens — Reference Mirror
   Source of truth: brandbook/tokens.json (DTCG 2025.10)
   Admin cascade: rulestead_admin/priv/static/css/rulestead_admin.css
   Note: the four-block @media + explicit-pin cascade is a live-app concern;
   see rulestead_admin.css for full Block 1–4 structure.
   Scope: .rs-shell / [data-rulestead] only — never :root or <html> for color.
   ========================================================= */

:root {
  /* INVARIANT — theme-insensitive scalars */
  --rs-font-display: "Sora", "Inter", ui-sans-serif, system-ui, sans-serif;
  --rs-space-1: 0.25rem;
  /* ... */
}

.rs-shell,
[data-rulestead] {
  /* LIGHT — mineral palette */
  --rs-primary: #3A6F8F;
  /* ... */
}

.rs-shell[data-theme="dark"],
[data-rulestead][data-theme="dark"] {
  /* DARK — mineral palette */
  --rs-primary: #5885a0;
  /* ... */
}

/* =========================================================
   Optional Tailwind v3/v4 token excerpt — commented out.
   For downstream marketing/site reuse. Side-effect-free.
   Reference only; no --rs-* tokens are redefined here.
   =========================================================

module.exports = {
  theme: {
    extend: {
      colors: {
        'rs-stead-blue': '#3A6F8F',
        'rs-ember-copper': '#9b5931',
        'rs-stone-mist': '#E8ECE8',
        'rs-basalt': '#0F1720',
        'rs-signal-gold': '#D2A94E',
        'rs-success': '#2d7753',
        'rs-warning': '#8f601a',
        'rs-danger': '#B44949',
        'rs-info': '#356E8C',
        'rs-moss-grey': '#606d66',
      }
    }
  }
}

*/
```

---

## brand-book.md Relocation + §12 Rework

### Step-by-Step

1. **Handle the working-tree edit first.** The file is `M` (modified, not staged). The working tree contains the full 27-section brand book (the git diff is `+966 / -23` lines — the file was essentially replaced with the full content). This edit MUST be committed before `git mv` to avoid losing work.

   ```bash
   git add prompts/rulestead-brand-book.md
   git commit -m "chore: commit full brand-book content before Phase 96 relocation"
   ```

2. **`git mv` to preserve history.**

   ```bash
   git mv prompts/rulestead-brand-book.md brandbook/brand-book.md
   ```

   `git mv` is equivalent to: rename the file + `git add` the rename. History is preserved via `git log --follow`.

3. **Apply §12 hex replacements** in `brandbook/brand-book.md` (5 substitutions + gradient line):

   | Old hex | New canonical | Role |
   |---------|--------------|------|
   | `#B96A3A` | `#9b5931` | Ember Copper (all 2 occurrences in §12: entry + gradient) |
   | `#B57A21` | `#8f601a` | Warning |
   | `#6C7A73` | `#606d66` | Moss Grey |
   | `#2F7D57` | `#2d7753` | Success (Gap 2 canonical) |
   | `#B44949` | `#b04848` | Danger (Gap 2 canonical) |

   Add a Gap-2 note to the Success and Danger entries:
   ```markdown
   #### Success
   - `#2d7753` — WCAG AA canonical; use `#2F7D57` on White/Rain Tint surfaces only
   ```

4. **Write pointer stub** at `prompts/rulestead-brand-book.md`:

   ```markdown
   <!-- Moved to `brandbook/brand-book.md` — canonical as of Phase 96. -->
   <!-- This file is a pointer only. Do not edit here. -->

   See [brandbook/brand-book.md](../brandbook/brand-book.md) for the canonical Rulestead Brand Book.
   ```

5. **Commit the whole batch:**

   ```bash
   git add brandbook/brand-book.md prompts/rulestead-brand-book.md
   git commit -m "chore(96): relocate brand-book, reconcile §12 hexes to AA-verified canonicals"
   ```

### §8 Tagline Verification

Confirmed: §8 of the brand book already reads "Runtime decisions, made clear." — NO change needed.

---

## §12 Hex Reconciliation Table

[VERIFIED from 95-PALETTE-RECONCILIATION.md §4, §8 — all 5 replacements are D-11 signed-off]

| § Location | Token | Current §12 hex | Replacement | Rationale |
|---|---|---|---|---|
| `#### Ember Copper` body | accent | `#B96A3A` | `#9b5931` | Canonical (SM 4.550:1); drift 0.09° |
| `### Gradients` body | accent | `#B96A3A` | `#9b5931` | Same role — reconcile here too |
| `#### Moss Grey` body | muted text | `#6C7A73` | `#606d66` | Canonical (SM 4.539:1); drift <0.1° |
| `#### Warning` body | warning | `#B57A21` | `#8f601a` | Canonical (SM 4.563:1); drift 0.02° |
| `#### Success` body | success | `#2F7D57` | `#2d7753` | Gap 2 canonical (SM 4.540:1); add surface note |
| `#### Danger` body | danger | `#B44949` | `#b04848` | Gap 2 canonical (SM 4.550:1); add surface note |

Unchanged (already pass all surfaces or decorative): `#0F1720`, `#24313D`, `#E8ECE8`, `#C4CCD1`, `#3A6F8F`, `#F5F7F6`, `#183247`, `#D2A94E`, `#356E8C`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON schema validation | A custom schema validator | `json.load()` in check_brand_tokens.py | Free structural validity; no deps; schema-level validation would require jsonschema (forbidden) |
| Token build pipeline | Style Dictionary / Theo / custom transformer | Hand-authored tokens.css + drift check | Mirror-not-generate is the locked project policy |
| Hex normalization/comparison | Custom hex parser | `.lower()` string comparison | Hex values are already well-formed in the locked palette; case folding is sufficient |
| File size check | Python os.path.getsize | `wc -c` in bash | Already in a bash loop; `wc -c` is POSIX portable |
| Cross-platform stat | `stat -f%z` (macOS) or `stat -c%z` (Linux) | `wc -c < file \| tr -d ' '` | `stat` flags differ by OS; CI is Linux but devs are macOS |

---

## Common Pitfalls

### Pitfall 1: Synced-Pair Invariant Broken by tokens.css

**What goes wrong:** Phase 98 edits `rulestead_admin.css` Block 1 to match mineral tokens. If `check_synced_pair.py` then reports MISMATCH, Phase 98 did not update Block 4 (explicit light) to match Block 1.

**Why it happens:** `tokens.css` only has a two-block shape (light + dark), but `rulestead_admin.css` has four blocks. Phase 98's implementation agent might update only the block they find first.

**How to avoid:** `tokens.css` and `docs/brand-usage.md` must explicitly document the synced-pair rule and reference `check_synced_pair.py`. The Phase 98 plan must include "update Block 4 to match Block 1" as a mandatory step alongside the Block 1 edit.

**Warning signs:** `check_synced_pair.py` exits 1 after Phase 98 completes.

### Pitfall 2: Drift Check Failing Is the Deliverable (Not a Bug)

**What goes wrong:** The CI job fails because `check_brand_tokens.py` exits 1. A Phase 96 implementer treats this as a bug to fix by either (a) removing the check from lint.sh, or (b) updating the CSS.

**Why it happens:** The failure is the SUCCESS CRITERION. The check must fail to prove the guard mechanism works.

**How to avoid:** D-08 in CONTEXT.md is explicit. The `brand-usage.md` and lint.sh comments must state: "This check intentionally fails until Phase 98 re-skins the admin CSS."

### Pitfall 3: Selector Search Before Comment Strip

**What goes wrong:** `css.find(".rs-shell,")` finds the string `.rs-shell,` inside the CSS comment block that DOCUMENTS the selectors (lines ~167–170 of rulestead_admin.css). The brace-walk then starts from the wrong position.

**Why it happens:** The CSS documentation comment in `rulestead_admin.css` mentions all four block selectors. `check_synced_pair.py` avoids this by stripping comments first — the same pattern must be followed exactly.

**How to avoid:** `css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)` BEFORE any `css.find()`. This is the exact pattern from `check_synced_pair.py`.

### Pitfall 4: admin_css_mapping Including var() Tokens

**What goes wrong:** `admin_css_mapping.light` includes `"--rs-bg": "#f4f6f8"` (the resolved value of `var(--rs-neutral-50)`). After Phase 98, Block 1 still has `--rs-bg: var(--rs-neutral-50)` — the check comparison `"#f4f6f8" != "var(--rs-neutral-50)"` causes a false mismatch even after the re-skin.

**Why it happens:** D-03 says "every variant --rs-* token name → its resolved value" — but the check does a string-level comparison, not a CSS-resolution comparison.

**How to avoid:** `admin_css_mapping` ONLY maps tokens whose CSS Block 1 value is a literal hex string. Exclude all `var()`, `rgba()`, and `shadow` composite tokens from admin_css_mapping. The check can then go green after Phase 98 without a CSS variable resolver.

### Pitfall 5: git mv on Modified (Unstaged) File

**What goes wrong:** Running `git mv prompts/rulestead-brand-book.md brandbook/brand-book.md` while the file has uncommitted changes. The working tree changes are preserved in the renamed file, but the uncommitted changes are not staged separately — they move with the file. This is acceptable but must be understood.

**Why it happens:** The file is currently `M` (modified working tree, not staged). `git mv` will work, but the working tree changes travel with it.

**How to avoid:** The cleanest sequence is: commit the working-tree edit first (stage → commit), THEN `git mv`. This creates two clean, auditable commits. D-11 explicitly notes "The existing working-tree edit is committed/handled before the move."

### Pitfall 6: check_synced_pair.py Not in CI

**What goes wrong:** Phase 98 edits rulestead_admin.css, `check_brand_tokens.py` goes green, but `check_synced_pair.py` was never wired into lint.sh — the dark synced pair (Blocks 2≡3) breaks silently.

**Why it happens:** `check_synced_pair.py` is a local dev tool. It is NOT currently in `lint.sh` or any GitHub Actions workflow. Phase 96 D-10 lists only `check_brand_tokens.py` and the SVG loop as required additions — but the gap exists.

**How to avoid:** The planner should consider whether to also add `python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"` to lint.sh in this phase. D-10 says "Append (a) and (b)" — adding check_synced_pair.py would be strictly additive and composable (consistent with the phase's intent). Flag as a planning decision. [ASSUMED: this is a reasonable addition the planner may choose to include]

---

## Code Examples

### check_brand_tokens.py — Full Pattern

```python
#!/usr/bin/env python3
"""Verify brandbook/tokens.json admin_css_mapping matches rulestead_admin.css Block 1.

Mirrors check_synced_pair.py: strip comments first, brace-walk extraction, sorted diff.

Usage (from repo root):
    python3 scripts/check_brand_tokens.py
Exits 0 and prints "BRAND TOKENS SYNCED (N tokens)"; exits 1 on mismatch.
"""
import sys
import re
import json

TOKENS_JSON = "brandbook/tokens.json"
CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"


def extract_css_decls(css, sel):
    i = css.find(sel)
    if i < 0:
        return None
    j = css.find("{", i)
    depth = 0
    k = j
    while k < len(css):
        if css[k] == "{":
            depth += 1
        elif css[k] == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    result = {}
    for line in css[j + 1 : k].splitlines():
        line = line.strip()
        if line.startswith("--rs-") and ":" in line:
            name, _, val = line.partition(":")
            result[name.strip()] = val.strip().rstrip(";")
    return result


def main():
    tokens = json.load(open(TOKENS_JSON))
    mapping = tokens["admin_css_mapping"]["light"]

    raw = open(CSS).read()
    css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first
    css_decls = extract_css_decls(css, ".rs-shell,")

    if css_decls is None:
        print("ERROR: Block 1 selector not found in CSS")
        return 1

    mismatches = []
    matched = 0
    for name, expected in sorted(mapping.items()):
        css_val = css_decls.get(name)
        if css_val is None:
            mismatches.append(f"  {name}: tokens.json={expected}  css=<missing>")
        elif css_val.lower() != expected.lower():
            mismatches.append(f"  {name}: tokens.json={expected}  css={css_val}")
        else:
            matched += 1

    if not mismatches:
        print(f"BRAND TOKENS SYNCED ({matched} tokens)")
        return 0

    print("BRAND TOKEN DRIFT DETECTED")
    for m in mismatches:
        print(m)
    return 1


if __name__ == "__main__":
    sys.exit(main())
```

### lint.sh append (exact lines)

```bash
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"

# SVG size budget: logo ≤20KB, specimens ≤50KB. No-op when dirs don't exist (Phases 97/99).
shopt -s nullglob
for f in "${RULESTEAD_REPO}/brandbook/assets/logo/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 20480 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 20480)"
    exit 1
  fi
done
for f in "${RULESTEAD_REPO}/brandbook/assets/specimens/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 51200 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 51200)"
    exit 1
  fi
done
echo "SVG SIZE BUDGET OK"
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `python3` | check_brand_tokens.py | ✓ | 3.14.4 (local); Ubuntu 24.04 ships 3.12 | — |
| `re`, `json`, `sys` stdlib | check_brand_tokens.py | ✓ | stdlib | — |
| `bash` | lint.sh SVG loop (`shopt`) | ✓ | CI + macOS | — |
| `wc` | SVG budget check | ✓ | POSIX (both platforms) | — |
| `git mv` | brand-book relocation | ✓ | any git | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

`workflow.nyquist_validation: true` in `.planning/config.json` — this section is required.

### Phase 96 — All Success Criteria Are Mechanically Verifiable

| SC # | Behavior | Verification Command | Automated? |
|------|---------|---------------------|-----------|
| SC-1 | `brandbook/tokens.json` exists, valid DTCG 2025.10 | `python3 -c "import json; t=json.load(open('brandbook/tokens.json')); print('admin_css_mapping' in t)"` → True | Yes |
| SC-2 | `brandbook/tokens.css` exists with `--rs-primary` in light block | `grep -c '\-\-rs-primary:' brandbook/tokens.css` → ≥1 | Yes |
| SC-3 | `scripts/check_brand_tokens.py` exits 1 against un-re-skinned CSS | `python3 scripts/check_brand_tokens.py; echo "exit: $?"` → exit: 1 | Yes |
| SC-4a | `scripts/ci/lint.sh` contains `check_brand_tokens.py` call | `grep -c 'check_brand_tokens.py' scripts/ci/lint.sh` → 1 | Yes |
| SC-4b | `scripts/ci/lint.sh` contains `SVG SIZE BUDGET OK` | `grep -c 'SVG SIZE BUDGET OK' scripts/ci/lint.sh` → 1 | Yes |
| SC-4c | `brandbook/docs/brand-usage.md` exists | `test -f brandbook/docs/brand-usage.md && echo ok` → ok | Yes |
| SC-4d | `prompts/rulestead-brand-book.md` contains pointer comment | `grep -c 'brandbook/brand-book.md' prompts/rulestead-brand-book.md` → ≥1 | Yes |
| SC-5a | `brandbook/brand-book.md` exists | `test -f brandbook/brand-book.md && echo ok` → ok | Yes |
| SC-5b | `brandbook/brand-book.md` §12 has canonical Ember Copper | `grep -c '#9b5931' brandbook/brand-book.md` → ≥1 | Yes |
| SC-5c | `prompts/rulestead-brand-book.md` no longer contains full book | `wc -l < prompts/rulestead-brand-book.md` → < 20 | Yes |
| SC-5d | git history follows the mv | `git log --follow brandbook/brand-book.md \| grep -c commit` → ≥2 | Yes |

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Python 3 stdlib + bash (no test runner) |
| Config file | none |
| Quick run command | `python3 scripts/check_brand_tokens.py` |
| Full suite command | `bash scripts/ci/lint.sh` (intentionally exits 1 in Phase 96) |

### Wave 0 Gaps

None — this phase creates new files; no pre-existing test infrastructure needed. The "test" for Phase 96 IS the intentional exit-1 of `check_brand_tokens.py`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `--rs-primary-hover` canonical target in admin_css_mapping.light should be approximately `#2d5f7c` (darkened Stead Blue) | Phase 98 Target Values table | If Phase 98 uses a different hover value, the check won't go green in Phase 98 — but this is a Phase 98 concern, not Phase 96 |
| A2 | `check_synced_pair.py` addition to lint.sh (alongside check_brand_tokens.py) is a reasonable additive include per D-10's intent | Pitfall 6 | If omitted, the Blocks 2≡3 invariant has no CI guard |
| A3 | soft/subtle/border token target values in admin_css_mapping.light can be set to match current shipped CSS (no Phase 98 change expected for those) | Token inventory table | If Phase 98 changes those tokens too, the mapping would need updating — but the primary fail tokens guarantee exit 1 regardless |

---

## Open Questions

1. **`--rs-primary-hover` canonical target value**
   - What we know: Phase 95 defines Stead Blue canonical as `#3A6F8F` for all light surfaces. No explicit hover variant was computed.
   - What's unclear: Should the hover value in admin_css_mapping.light be a darkened `#3A6F8F` (e.g. `#2d5f7c`) or the same value?
   - Recommendation: The planner should use `#2d5f7c` (a moderate darkening of `#3A6F8F`) as an interim target. Phase 98 implementer can adjust the specific hover shade as long as it passes AA. The mismatch against current `#1d4ed8` is sufficient to guarantee the Phase 96 exit-1.

2. **Whether to add `check_synced_pair.py` to lint.sh in this phase**
   - What we know: It's not currently in CI. D-10 lists only check_brand_tokens.py and SVG loop as additions.
   - What's unclear: Is the omission intentional (not this phase's job) or an oversight?
   - Recommendation: Include it — it's one extra line, strictly additive, directly composable, and its absence creates a silent Phase 98 regression risk. The planner should confirm.

3. **Scope of admin_css_mapping.light for soft/subtle/border tokens**
   - What we know: These 15+ tokens have generic Tailwind-derived values that Phase 98 may or may not change.
   - What's unclear: If Phase 98 only changes the 6 primary brand/status hexes, mapping all 37 hex tokens and having 31+ mismatches would work (exit 1) but creates lots of noise.
   - Recommendation: Map ALL 37 hex-literal tokens in admin_css_mapping.light with their Phase-98 target values. For tokens Phase 98 keeps unchanged (neutral ramp, soft tints), use the current shipped value as the target. The check goes green in Phase 98 only for the tokens that actually change. This is the cleanest approach.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Style Dictionary / build pipeline | Mirror-not-generate (hand-authored + drift check) | v1.14 design decision (STATE.md) | Zero build dependency; tokens.css is human-readable source of truth |
| DTCG `$extensions.modes` for light/dark | Top-level `light`/`dark` group split (D-02) | Phase 96 decision | Easier to diff against 4-block CSS; no tooling needed to read |

**DTCG `$extensions.modes`** (the Style Dictionary approach for multi-theme tokens) is an alternative approach that some tools support but is NOT used here. D-02 explicitly rejects it. Do not use it.

---

## Project Constraints (from CLAUDE.md)

- **Sibling-package layout preserved:** All new files go in `brandbook/` (repo root level), `scripts/` (repo root), or modify `scripts/ci/lint.sh`. Zero changes to `rulestead/` or `rulestead_admin/` package internals this phase.
- **Scripts-first CI:** Python 3 stdlib only. All CI logic lives in `scripts/`. No Node, no SCSS, no Style Dictionary.
- **Mirror-not-generate:** `tokens.css` and `rulestead_admin.css` are hand-authored mirrors. No build step generates one from the other.
- **Narrow, auditable changes:** Each commit is one logical unit. The brand-book relocation is one commit; the token files are another; the scripts/CI extension is another.
- **Root docs honest:** `STATE.md` and `ROADMAP.md` must be updated to reflect Phase 96 completion.

---

## Sources

### Primary (HIGH confidence)
- DTCG 2025.10 spec (https://www.designtokens.org/tr/2025.10/format/) — valid `$type` values, alias syntax, group inheritance, token vs group distinction, shadow composite shape
- `rulestead_admin/priv/static/css/rulestead_admin.css` — live extraction of Block 1 (57 tokens, 37 hex-literal) and Block 3 (56 tokens, 31 hex-literal); asymmetries confirmed
- `scripts/check_synced_pair.py` — algorithm pattern (comment-strip → brace-walk → extract → compare → exit code)
- `.planning/phases/95-brand-audit-palette-reconciliation/95-PALETTE-RECONCILIATION.md` — all canonical hex values (§4 one-hex-per-role, §5 dark ramp, §8 15 D-11 signed-off hexes)
- `.planning/phases/96-design-tokens-brandbook-scaffold/96-CONTEXT.md` — all locked decisions D-01..D-12
- `.planning/config.json` — `nyquist_validation: true`, CI runner environment
- `.github/workflows/ci.yml` — confirms Ubuntu 24.04, `lint.sh` invocation

### Secondary (MEDIUM confidence)
- Python 3 stdlib docs (`json`, `re`, `sys`) — standard behavior confirmed by live execution
- `wc -c` portability — confirmed by live test on macOS + documented Linux behavior
- `shopt -s nullglob` behavior under `set -euo pipefail` — confirmed by live execution test

### Tertiary (LOW confidence)
- DTCG W3C Community Group announcement (https://www.designtokens.org/) — confirms 2025.10 is stable first version

---

## Metadata

**Confidence breakdown:**
- DTCG format specifics: HIGH — verified from spec
- check_brand_tokens.py algorithm: HIGH — derived from existing check_synced_pair.py + live token extraction
- lint.sh bash fragment: HIGH — tested on macOS; CI runs on Linux; wc/shopt POSIX-verified
- §12 hex replacements: HIGH — all from D-11 signed-off palette record
- admin_css_mapping scope: HIGH — confirmed by live CSS extraction

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable format spec; CSS changes if Phase 98 lands early)
