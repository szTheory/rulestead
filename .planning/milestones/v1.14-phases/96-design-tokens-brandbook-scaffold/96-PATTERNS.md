# Phase 96: Design Tokens (`brandbook/` scaffold) — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 8
**Analogs found:** 6 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `brandbook/tokens.json` | config | batch (encode) | `95-PALETTE-RECONCILIATION.md` §4/§5/§8 (value source only) | no-code-analog |
| `brandbook/tokens.css` | config | batch (mirror) | `rulestead_admin/priv/static/css/rulestead_admin.css` lines 39–303 | role-match |
| `scripts/check_brand_tokens.py` | utility | request-response | `scripts/check_synced_pair.py` lines 1–63 | exact |
| `scripts/ci/lint.sh` | config | batch | `scripts/ci/lint.sh` lines 1–16 (append target) | exact |
| `brandbook/brand-book.md` | config | transform (git mv + §12 rework) | `prompts/rulestead-brand-book.md` (source file) | exact |
| `prompts/rulestead-brand-book.md` | config | transform (pointer stub) | None — trivial rewrite | no-code-analog |
| `brandbook/docs/brand-usage.md` | config | batch | `guides/introduction/product-boundary.md` | role-match |
| `brandbook/README.md` | config | batch | `guides/introduction/product-boundary.md` | role-match |

---

## Pattern Assignments

### `brandbook/tokens.json` (config, DTCG 2025.10 — no direct code analog)

**Value source:** `.planning/phases/95-brand-audit-palette-reconciliation/95-PALETTE-RECONCILIATION.md` §4/§5/§8

No existing JSON or token file exists in the repo to copy structure from. Use the skeleton in RESEARCH.md directly. Key rules:

**Top-level group layout:**
```json
{
  "primitive": { ... },
  "light":     { ... },
  "dark":      { ... },
  "invariant": { ... },
  "admin_css_mapping": { "light": { ... }, "dark": { ... } }
}
```

**DTCG leaf rule:** A token MUST have `"$value"`. A group MUST NOT have `"$value"`. They cannot coexist on the same object.

**Group-level `$type` inheritance pattern** (saves per-leaf repetition):
```json
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
  }
}
```

**Alias reference syntax** (curly-brace resolves to full `$value`):
```json
"light": {
  "$type": "color",
  "default": { "$value": "{primitive.stead-blue.base}" },
  "success-stone-mist": {
    "$value": "{primitive.success.stone-mist}",
    "$description": "Gap 2 — use on Stone Mist surface only"
  }
}
```

**admin_css_mapping scope rule:** Map ONLY tokens whose Block 1 CSS value is a literal hex string. Exclude `var()`, `rgba()`, and shadow composite tokens — the drift check does string comparison, not CSS resolution. This means 37 hex-literal tokens for `light`, 31 for `dark`.

**Light-only asymmetry:** `--rs-neutral-700: #263241` is in `admin_css_mapping.light` but absent from `admin_css_mapping.dark`. Do not invent a dark counterpart.

**Dark-only hex tokens:** `--rs-disabled-bg` and `--rs-disabled-text` are hex-literal in dark (include in `admin_css_mapping.dark`) but `var()` in light (exclude from `admin_css_mapping.light`).

**Missing `--rs-info` family:** `tokens.json` defines `info` as a semantic role but `admin_css_mapping` MUST NOT invent CSS names that do not exist in the shipped stylesheet.

**The six primary mismatch tokens** (guarantee exit 1 against current CSS):
| `admin_css_mapping.light` TARGET | Current Block 1 (generic) |
|---|---|
| `--rs-primary: #3A6F8F` | `#2563eb` |
| `--rs-primary-hover: #2d5f7c` | `#1d4ed8` |
| `--rs-accent: #9b5931` | `#9a3f12` |
| `--rs-success: #2d7753` | `#15803d` |
| `--rs-warning: #8f601a` | `#b45309` |
| `--rs-error: #B44949` | `#b91c1c` |
| `--rs-critical: #B44949` | `#b91c1c` |

**`invariant` group — `$type` varies by sub-group:**
```json
"invariant": {
  "spacing": { "$type": "dimension", "space-1": { "$value": "0.25rem" } },
  "radius":  { "$type": "dimension", "sm": { "$value": "6px" } },
  "shadow":  {
    "$type": "shadow",
    "sm": { "$value": { "color": "#1a2332", "offsetX": { "value": 0, "unit": "px" },
                        "offsetY": { "value": 1, "unit": "px" },
                        "blur":    { "value": 2, "unit": "px" },
                        "spread":  { "value": 0, "unit": "px" } } }
  },
  "focus-ring":  { "$type": "dimension", "offset": { "$value": "2px" } },
  "code-block":  { "font": { "$type": "fontFamily", "$value": "IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace" } },
  "callout":     { "radius": { "$type": "dimension", "$value": "10px" } }
}
```

---

### `brandbook/tokens.css` (config, CSS mirror)

**Analog:** `rulestead_admin/priv/static/css/rulestead_admin.css` (lines 39–303)

**Invariant `:root` block pattern** (analog lines 39–119 — copy token names verbatim, but include only the categories from CONTEXT.md D-01; this is a reference mirror, not the deployed cascade):
```css
:root {
  /* INVARIANT — theme-insensitive scalars */
  --rs-font-display: "Sora", "Inter", ui-sans-serif, system-ui, sans-serif;
  --rs-font-sans:    "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --rs-font-mono:    "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, monospace;
  /* ... (copy exact names + values from analog lines 46–119) */
}
```

**Two-block light/dark pattern** (D-05 — simplified vs. the four-block cascade):
```css
/* Light block — mineral palette */
.rs-shell,
[data-rulestead] {
  --rs-primary: #3A6F8F;
  /* ... (37 hex-literal tokens from admin_css_mapping.light TARGET values) */
}

/* Dark block — mineral palette */
.rs-shell[data-theme="dark"],
[data-rulestead][data-theme="dark"] {
  --rs-primary: #5885a0;
  /* ... (31 hex-literal tokens from admin_css_mapping.dark TARGET values) */
}
```

**Header comment pattern** (document the four-block cascade relationship, not replicate it):
```css
/* =========================================================
   Rulestead Design Tokens — Reference Mirror
   Source of truth: brandbook/tokens.json (DTCG 2025.10)
   Admin cascade: rulestead_admin/priv/static/css/rulestead_admin.css
   Note: the four-block @media + explicit-pin cascade is a live-app concern;
   see rulestead_admin.css for full Block 1–4 structure.
   Scope: .rs-shell / [data-rulestead] only — never :root or <html> for color.
   ========================================================= */
```

**TOK-04 Tailwind excerpt pattern** (D-06 — trailing commented-out block, stays valid CSS):
```css
/* =========================================================
   Optional Tailwind v3/v4 token excerpt — commented out.
   For downstream marketing/site reuse. Side-effect-free.
   Reference only; no --rs-* tokens are redefined here.
   =========================================================

module.exports = {
  theme: {
    extend: {
      colors: {
        'rs-stead-blue':    '#3A6F8F',
        'rs-ember-copper':  '#9b5931',
        'rs-stone-mist':    '#E8ECE8',
        'rs-basalt':        '#0F1720',
        'rs-signal-gold':   '#D2A94E',
        'rs-success':       '#2d7753',
        'rs-warning':       '#8f601a',
        'rs-danger':        '#B44949',
        'rs-info':          '#356E8C',
        'rs-moss-grey':     '#606d66',
      }
    }
  }
}

*/
```

---

### `scripts/check_brand_tokens.py` (utility, request-response)

**Analog:** `scripts/check_synced_pair.py` (lines 1–63) — exact match; mirror the full structure.

**Shebang + module docstring pattern** (analog lines 1–13):
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
```

**`decls()` brace-walk helper** (analog lines 20–39 — extract and adapt; return a dict instead of sorted list so name→value pairs are preserved for per-token diff):
```python
def extract_css_decls(css, sel):
    """Strip comments, locate selector, brace-walk, return --rs-* declarations dict."""
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
```

**Comment-strip pattern** (analog line 44 — MUST happen BEFORE any `css.find()`; pitfall: CSS header comment documents selectors and would match first):
```python
raw = open(CSS).read()
css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first
```

**Main loop: JSON load + comparison + exit code** (analog lines 42–58, adapted):
```python
def main():
    tokens = json.load(open(TOKENS_JSON))   # raises json.JSONDecodeError on malformed JSON — free validity check
    mapping = tokens["admin_css_mapping"]["light"]

    raw = open(CSS).read()
    css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)
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
        elif css_val.lower() != expected.lower():   # case-insensitive: #3A6F8F == #3a6f8f
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

**Expected exit-1 output** (Phase 96 — minimum 7 mismatches):
```
BRAND TOKEN DRIFT DETECTED
  --rs-accent: tokens.json=#9b5931  css=#9a3f12
  --rs-critical: tokens.json=#B44949  css=#b91c1c
  --rs-error: tokens.json=#B44949  css=#b91c1c
  --rs-primary: tokens.json=#3A6F8F  css=#2563eb
  --rs-primary-hover: tokens.json=#2d5f7c  css=#1d4ed8
  --rs-success: tokens.json=#2d7753  css=#15803d
  --rs-warning: tokens.json=#8f601a  css=#b45309
```

---

### `scripts/ci/lint.sh` (config, additive append)

**Analog:** `scripts/ci/lint.sh` lines 1–16 — preserve verbatim; append only.

**Current file** (lines 1–16, NEVER modify these):
```bash
#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

cd "${RULESTEAD_REPO}/rulestead"
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix hex.audit
mix compile --no-optional-deps --warnings-as-errors
RULESTEAD_REPO="${RULESTEAD_REPO}" "${RULESTEAD_REPO}/scripts/ci/check_package_whitelist.sh"
mix dialyzer --format github
```

**Lines to append** (exact bash from RESEARCH.md — portable, nullglob-safe):
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

**Key implementation details:**
- `wc -c < "$f" | tr -d ' '` — POSIX-portable byte count. DO NOT use `stat`; its flags differ between macOS (`-f%z`) and Linux (`-c%z`). CI runs Ubuntu 24.04; devs are on macOS.
- `shopt -s nullglob` — bash builtin (safe; shebang is `#!/usr/bin/env bash`). Causes an unmatched glob to expand to zero words so the `for` loop simply does not execute when `brandbook/assets/` does not yet exist. Without this, under `set -euo pipefail`, the loop would try to operate on the literal string `*.svg` and error.
- Budget constants: `20480` = 20 KB (logo); `51200` = 50 KB (specimens).
- The `check_brand_tokens.py` line will cause CI to exit 1 in Phase 96. This is the intentional success criterion. Add a comment above it noting "Intentionally exits 1 until Phase 98 re-skins rulestead_admin.css".

---

### `brandbook/brand-book.md` (config, transform via git mv + §12 rework)

**Source file:** `prompts/rulestead-brand-book.md` (currently `M` in git status — uncommitted working-tree changes)

**Relocation sequence** (D-11):
1. Commit the working-tree edit first: `git add prompts/rulestead-brand-book.md && git commit -m "chore: commit full brand-book content before Phase 96 relocation"`
2. Then: `git mv prompts/rulestead-brand-book.md brandbook/brand-book.md`

**§12 hex substitution table** (D-12 — replace these occurrences in the moved file):

| Old hex | New canonical | Section location |
|---|---|---|
| `#B96A3A` | `#9b5931` | `#### Ember Copper` body (2 occurrences: entry + Gradients section) |
| `#B57A21` | `#8f601a` | `#### Warning` body |
| `#6C7A73` | `#606d66` | `#### Moss Grey` body |
| `#2F7D57` | `#2d7753` | `#### Success` body + add Gap-2 note |
| `#B44949` | `#b04848` | `#### Danger` body + add Gap-2 note |

**Gap-2 note to add** after Success and Danger entries:
```markdown
> **Gap 2 (Stone Mist surfaces):** Use `#2d7753` on Stone Mist (`#E8ECE8`) only. Use `#2F7D57` on White (`#FFFFFF`) or Rain Tint (`#F5F7F6`) surfaces.
```
(Danger equivalent: `#b04848` on Stone Mist; `#B44949` on White/Rain Tint.)

**§8 tagline:** Already correct — "Runtime decisions, made clear." — NO change.

**Unchanged hexes** (already pass all surfaces or decorative): `#0F1720`, `#24313D`, `#E8ECE8`, `#C4CCD1`, `#3A6F8F`, `#F5F7F6`, `#183247`, `#D2A94E`, `#356E8C`.

---

### `prompts/rulestead-brand-book.md` (config, pointer stub — no analog)

Trivial rewrite. Replace the full brand-book content with a minimal pointer. No existing analog.

**Pattern (pointer stub):**
```markdown
<!-- Moved to `brandbook/brand-book.md` — canonical as of Phase 96. -->
<!-- This file is a pointer only. Do not edit here. -->

See [brandbook/brand-book.md](../brandbook/brand-book.md) for the canonical Rulestead Brand Book.
```

File should be under 10 lines. SC-5c verifies `wc -l < prompts/rulestead-brand-book.md` is < 20.

---

### `brandbook/docs/brand-usage.md` (config, usage notes doc)

**Analog:** `guides/introduction/product-boundary.md` — markdown structure with H2 sections, tables, and callout blocks.

**Content requirements** (from D-09, CONTEXT.md, RESEARCH.md Pitfall 1 + Pitfall 2):

The file must cover:
1. How to use `check_brand_tokens.py` (invocation, expected output in Phase 96 vs Phase 98)
2. The synced-pair rule: when editing `rulestead_admin.css`, update both members of each synced pair (Block 1 + Block 4 for light; Block 2 + Block 3 for dark)
3. Warning that CI exits 1 intentionally until Phase 98
4. How to add a new token (invariant vs variant decision; the four-block update requirement)

**Pattern (section structure from `product-boundary.md`):**
```markdown
# Brand Token Usage

## Check script

Run from repo root:

    python3 scripts/check_brand_tokens.py

...

## Synced-pair rule

`rulestead_admin.css` has four cascade blocks. Blocks 1 and 4 are a SYNCED PAIR
(light values). Blocks 2 and 3 are a SYNCED PAIR (dark values). When you edit
a token value in one block of a pair, you MUST update the partner block to the
same value before committing.

...

## Intentional CI failure (Phase 96 → Phase 98)

The token drift check will exit 1 against the current admin CSS. This is by
design — it proves the guard works. Phase 98 re-skins `rulestead_admin.css`
to make it pass.
```

---

### `brandbook/README.md` (config, directory index stub)

**Analog:** `guides/introduction/product-boundary.md` — minimal H1 + section prose + cross-link table.

**Pattern:**
```markdown
# brandbook/

Directory index for the Rulestead brand system (v1.14+).

| File | Purpose |
|---|---|
| `brand-book.md` | Canonical brand book — identity, palette, typography, voice |
| `tokens.json` | Machine-readable design tokens (DTCG 2025.10) |
| `tokens.css` | CSS custom-property reference mirror (`--rs-*` shape) |
| `docs/brand-usage.md` | Re-skin guide + `check_brand_tokens.py` usage |

...
```

Keep under 30 lines. This stub will be replaced in Phase 100.

---

## Shared Patterns

### Comment-strip before selector search
**Source:** `scripts/check_synced_pair.py` line 44
**Apply to:** `scripts/check_brand_tokens.py`
```python
css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first
```
The `rulestead_admin.css` header comment (~lines 167–170) documents all four block selectors. Without stripping, `css.find(".rs-shell,")` matches inside the comment, not the actual block.

### Brace-depth walk for CSS block extraction
**Source:** `scripts/check_synced_pair.py` lines 22–39
**Apply to:** `scripts/check_brand_tokens.py`
```python
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
```
Handles nested braces (e.g., `@media` blocks) correctly.

### Exit code idiom
**Source:** `scripts/check_synced_pair.py` lines 60–62 and `scripts/check_contrast.py` lines 258–260
**Apply to:** `scripts/check_brand_tokens.py`
```python
if __name__ == "__main__":
    sys.exit(main())
```

### Case-insensitive hex comparison
**Source:** `scripts/check_brand_tokens.py` (new pattern — no existing analog)
**Apply to:** `scripts/check_brand_tokens.py`
```python
elif css_val.lower() != expected.lower():
```
The locked palette uses mixed case (`#3A6F8F`, `#B44949`); CSS files may use lowercase. `.lower()` on both sides prevents false mismatches.

### Invariant vs variant token split
**Source:** `rulestead_admin/priv/static/css/rulestead_admin.css` lines 122–222 (comment block)
**Apply to:** `brandbook/tokens.css`, `brandbook/tokens.json`

The invariant/variant split is architecturally documented at lines 122–222 of `rulestead_admin.css`. The same split MUST be reproduced in `tokens.css` (`:root` for invariants; `.rs-shell/[data-rulestead]` blocks for variants) and `tokens.json` (separate `invariant` group vs `light`/`dark` groups).

### `--rs-*` token namespace and selector scope
**Source:** `rulestead_admin/priv/static/css/rulestead_admin.css` lines 224–303 (Block 1)
**Apply to:** `brandbook/tokens.css`

Scope is always `.rs-shell` / `[data-rulestead]`. Never `:root` or `<html>` for color tokens. The `--rs-` prefix is the exclusive namespace; do not invent non-`--rs-` custom properties in `tokens.css`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `brandbook/tokens.json` | config | batch (encode) | No JSON token file exists in repo; DTCG format is new to this project. Use RESEARCH.md skeleton + PALETTE-RECONCILIATION.md §4/§5/§8 as authoritative inputs. |
| `prompts/rulestead-brand-book.md` (pointer stub) | config | transform | Trivial file — 3–5 lines. No meaningful structural analog needed. |

---

## Metadata

**Analog search scope:** `scripts/`, `rulestead_admin/priv/static/css/`, `guides/`, `prompts/`
**Files scanned:** 6 (check_synced_pair.py, check_contrast.py, rulestead_admin.css, lint.sh, product-boundary.md, rulestead-brand-book.md)
**Pattern extraction date:** 2026-06-04
