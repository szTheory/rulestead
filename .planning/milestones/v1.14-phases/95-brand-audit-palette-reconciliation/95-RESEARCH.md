# Phase 95: Brand Audit + Palette Reconciliation — Research

**Researched:** 2026-06-04
**Domain:** Accessibility-verified palette reconciliation; brand-book pressure-test; WCAG 2.x + OKLCH computation methods
**Confidence:** HIGH (all contrast ratios independently verified by python3 stdlib computation this session; CSS extracted verbatim from shipped file; OKLCH method confirmed by matrix computation)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Reconciliation table and pressure-test audit written as phase artifacts under `.planning/phases/95-brand-audit-palette-reconciliation/` — a markdown decision record. Nothing committed to `brandbook/` in this phase.
- **D-02:** Reconciliation table columns: brand-book name → current shipped hex → proposed re-skin hex → AA-verified hex → computed WCAG 2.x ratio → surface → role. Additional OKLCH hue angle (pre → post) column for remediated entries. Every normal-weight text role entry must show ≥4.5:1.
- **D-03:** "Current shipped hex" reflects actual shipped tokens — Block 1 `--rs-primary: #2563eb` (generic blue, not Stead Blue) and `--rs-accent: #9a3f12` (not Ember Copper). Reconciliation table makes these deltas explicit.
- **D-04:** Brand book NOT physically relocated in Phase 95. Phase 95 closes by confirming the decision to relocate `prompts/rulestead-brand-book.md` → `brandbook/brand-book.md` during Phase 96.
- **D-05:** Contrast ratios and OKLCH hue angles computed with a short python3 stdlib script/snippet. No reusable contrast harness assumed to exist. Pre-computed values in PITFALLS.md and SUMMARY.md are authoritative inputs; the script verifies/reproduces them.
- **D-06:** Remediation method is uniform-RGB-scale darkening/lightening (multiply all channels by constant k, k<1 to darken), matching the v1.13 `#c45c26 → #9a3f12` precedent — never HSL lightness reduction. OKLCH hue angle pre/post recorded for Ember Copper and Warning; must show <3° hue drift.
- **D-07:** Remediation targeted, not wholesale. Light-surface failers: Ember Copper `#B96A3A`, Warning `#B57A21`, Moss Grey `#6C7A73`. Dark-base failers: Stead Blue, Success, Danger, Info. Anchor colors Stead Blue `#3A6F8F` and Ink Blue `#183247` on white already pass.
- **D-08:** Surface set audited: `#FFFFFF`, Stone Mist `#E8ECE8`, Rain Tint `#F5F7F6` (light), and `#10161f` (dark).
- **D-09:** Signal Gold `#D2A94E` receives decorative-only policy ("never as normal-weight text") — not contrast-remediated.
- **D-10:** Dark-mode ramp anchored on shipped v1.13 mineral-dark: base `#10161f` kept, elevation by luminance increase + hairline borders, no `--rs-surface-base` swap.
- **D-11:** Maintainer sign-off on each AA-adjusted hex is a phase-close gate, not a discuss-time decision.

### Claude's Discretion

- Exact filename(s) for the deliverable within `.planning/phases/95-.../` (e.g. `95-PALETTE-RECONCILIATION.md`, `95-BRAND-AUDIT.md`)
- Whether the python3 verification snippet is committed under `scripts/` or kept inline in the decision record (D-05 allows either; favor committed script if reused downstream)

### Deferred Ideas (OUT OF SCOPE)

- Physical relocation of brand book to `brandbook/brand-book.md` — Phase 96
- Authoring `tokens.json` / `tokens.css` / `check_brand_tokens.py` — Phase 96
- Any committed reusable contrast/a11y harness as a product surface — out of scope for Phase 95
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRD-01 | Maintainer has a written pressure-test audit of the recovered brand book (KEEP / TIGHTEN / REWORK / ADD / REMOVE + scorecard) | Brand book fully read; 27 sections catalogued; audit framework identified |
| BRD-02 | Canonical living `brand-book.md` exists in `brandbook/` (relocation decision confirmed in Phase 95, physical relocation Phase 96) | D-04 confirmed; ARCHITECTURE.md pointer comment pattern defined |
| PAL-01 | Every brand-palette pairing (text/border/UI element) on light and dark surfaces has a documented, computed WCAG contrast ratio | Full contrast matrix independently computed this session (python3 stdlib) |
| PAL-02 | All AA-failing pairings remediated with hue-preserving (OKLCH uniform-scale) variants; one canonical AA-passing value selected per role/surface | Complete targets computed; OKLCH drift verified <3° for all remediated colors |
| PAL-03 | Full dark-mode ramp derived, anchored on shipped v1.13 mineral-dark approach | v1.13 dark ramp extracted from shipped CSS; slot mapping documented |
| PAL-04 | Decorative-only colors carry explicit "never as normal-weight text" usage policy | Signal Gold policy documented; computation confirms 2.20:1 on white |
</phase_requirements>

---

## Summary

Phase 95 is a gate-zero verification and documentation phase. It produces two markdown artifacts: (1) a palette reconciliation table mapping every brand-book mineral color to its current shipped hex, proposed re-skin hex, AA-verified hex, computed WCAG 2.x contrast ratio, surface, and role; and (2) a brand-book pressure-test audit with a KEEP/TIGHTEN/REWORK/ADD/REMOVE scorecard. No CSS is edited and nothing is committed to `brandbook/`.

The dominant technical requirement is computing WCAG 2.x contrast ratios and OKLCH hue angles using dependency-free python3 stdlib, since no reusable contrast harness exists in the repo (D-05). The formulas are well-defined and have been independently verified this session (black on white = 21.00:1 confirms the implementation is correct). The pre-computed values in PITFALLS.md are directionally accurate but contain **four borderline targets that technically fail at exact 4.49:1** — the planner must use slightly darker/lighter hex values for the final table (documented in the Critical Gaps section below).

The brand book at `prompts/rulestead-brand-book.md` has 27 well-structured sections covering brand strategy, palette, typography, logo, layout, voice, and imagery. The pressure-test audit framework (KEEP/TIGHTEN/REWORK/ADD/REMOVE) is straightforward to apply section by section.

**Primary recommendation:** Plan two deliverable files — `95-PALETTE-RECONCILIATION.md` (the table + verification methodology) and `95-BRAND-AUDIT.md` (the pressure-test scorecard) — plus a committed `scripts/check_contrast.py` verification script (reusable in Phase 96's `check_brand_tokens.py` and Phase 98's AA gate).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| WCAG ratio computation | Phase artifact (python3 script) | — | No runtime tier; computation runs at planning/authoring time only |
| Reconciliation table | Phase artifact (markdown) | — | Written record consumed by Phase 96 token authoring |
| Brand-book pressure-test | Phase artifact (markdown) | — | Human authoring + judgment, no automation |
| AA-verified hex values | Phase artifact (markdown) | Phase 96 tokens.json | Phase 95 produces approved values; Phase 96 encodes them |
| Relocation decision | Phase artifact (markdown) | prompts/rulestead-brand-book.md | D-04: decision confirmed in Phase 95, physical move in Phase 96 |
| Dark ramp slot mapping | Phase artifact (markdown) | rulestead_admin.css | Phase 95 documents the mapping; Phase 98 implements it |

---

## Exact Shipped CSS Tokens (Block 1 Light + Blocks 2/3 Dark)

These are the verbatim `--rs-*` declarations extracted from the shipped `rulestead_admin/priv/static/css/rulestead_admin.css`. [VERIFIED: direct file read]

### Block 1 + 4 (Light, synced pair)

**Brand tokens:**
```
--rs-primary:       #2563eb
--rs-primary-hover: #1d4ed8
--rs-primary-soft:  #dbeafe
--rs-on-primary:    #ffffff
--rs-accent:        #9a3f12
--rs-accent-soft:   #fde8dc
```

**Status tokens:**
```
--rs-success:           #15803d
--rs-success-hover:     #166534
--rs-success-text:      #047857
--rs-warning:           #b45309
--rs-warning-text:      #a16207
--rs-error:             #b91c1c
--rs-error-hover:       #991b1b
--rs-critical:          #b91c1c
--rs-error-text:        #be123c
--rs-error-text-strong: #7f1d1d
```

**Neutral ramp (light):**
```
--rs-neutral-0:   #ffffff
--rs-neutral-25:  #f8fafc
--rs-neutral-50:  #f4f6f8
--rs-neutral-100: #eef1f5
--rs-neutral-200: #e7ebf0
--rs-neutral-300: #d8dee6
--rs-neutral-400: #b8c2cf
--rs-neutral-500: #99a3af
--rs-neutral-600: #5c6b7a
--rs-neutral-700: #263241
--rs-neutral-900: #1a2332
```

**Light aliases:** `--rs-bg: var(--rs-neutral-50)` `--rs-surface: var(--rs-neutral-0)` `--rs-surface-muted: var(--rs-neutral-100)` `--rs-border: var(--rs-neutral-300)` `--rs-text: var(--rs-neutral-900)` `--rs-text-muted: var(--rs-neutral-600)`

**Focus (color-bearing, light):**
```
--rs-focus-ring-color: rgba(37, 99, 235, 0.55)
--rs-primary-ring:     rgba(14, 165, 233, 0.22)
```

### Blocks 2 + 3 (Dark, synced pair)

**Brand tokens (dark):**
```
--rs-primary:       #2563eb          ← FAILS on #10161f at 3.51:1
--rs-primary-hover: #5a96f5
--rs-primary-soft:  rgba(37, 99, 235, 0.12)
--rs-on-primary:    #ffffff
--rs-accent:        #e8834a
--rs-accent-soft:   rgba(232, 131, 74, 0.12)
```

**Status tokens (dark):**
```
--rs-success:     #4ade80          ← PASS 10.42:1 on #10161f
--rs-warning:     #fbbf24          ← PASS 10.88:1 on #10161f
--rs-error:       #f87171          ← PASS 6.56:1 on #10161f
--rs-warning-text: #fbbf24
--rs-error-text:  #f87171
```

**Neutral ramp (dark):**
```
--rs-neutral-0:   #10161f   ← dark base (canonical)
--rs-neutral-25:  #141c27
--rs-neutral-50:  #19222e
--rs-neutral-100: #1f2a38
--rs-neutral-200: #253243
--rs-neutral-300: #2e3d52
--rs-neutral-400: #3d5168
--rs-neutral-500: #7a8fa3
--rs-neutral-600: #a8b9ca
--rs-neutral-900: #e8edf3
```

**Key observation:** The shipped dark-mode status colors (`#4ade80`, `#fbbf24`, `#f87171`) already pass WCAG AA on `#10161f` with very high margins (6.56–10.88:1). These are NOT the mineral palette values — they are Tailwind-style vivid colors. The reconciliation table must explicitly document these as "currently passing (shipped generic)" vs. the mineral equivalents (which would need the AA-lightened variants from D-07).

---

## Brand-Book Mineral Palette: Complete Named Colors

Source: `prompts/rulestead-brand-book.md` §12 [VERIFIED: direct file read]

### Primary Palette

| Brand-Book Name | Hex | Role | OKLCH |
|-----------------|-----|------|-------|
| Basalt | `#0F1720` | Primary dark surface / heading color | L=0.201 C=0.022 H=251.8° |
| Slate Stead | `#24313D` | Secondary dark UI and structural elements | L=0.307 C=0.028 H=246.7° |
| Stone Mist | `#E8ECE8` | Light backgrounds / soft panels | — (surface) |
| Quarry | `#C4CCD1` | Borders / neutral dividers / disabled states | — (border) |
| Stead Blue | `#3A6F8F` | Primary brand color for active interface elements | L=0.519 C=0.076 H=237.2° |
| Ember Copper | `#B96A3A` | Accent color for emphasis, CTA, highlight moments | L=0.604 C=0.119 H=50.2° |

### Supporting Palette

| Brand-Book Name | Hex | Role | OKLCH |
|-----------------|-----|------|-------|
| Moss Grey | `#6C7A73` | Secondary text / supportive UI elements | L=0.566 C=0.020 H=164.3° |
| Rain Tint | `#F5F7F6` | Clean background field | — (surface) |
| Ink Blue | `#183247` | Deep contrast for dark-on-light components | L=0.307 C=0.050 H=244.8° |
| Signal Gold | `#D2A94E` | Limited-use highlight — premium emphasis, badges, metadata states | L=0.754 C=0.119 H=84.8° |

### Semantic Colors

| Brand-Book Name | Hex | Role | OKLCH |
|-----------------|-----|------|-------|
| Success | `#2F7D57` | Success state | L=0.531 C=0.098 H=159.0° |
| Warning | `#B57A21` | Warning state | L=0.626 C=0.123 H=71.9° |
| Danger | `#B44949` | Error/danger state | L=0.548 C=0.140 H=22.9° |
| Info | `#356E8C` | Informational state | L=0.513 C=0.076 H=234.0° |

---

## Complete Computed Contrast Matrix

All ratios computed this session using the WCAG 2.x relative-luminance formula (python3 stdlib). [VERIFIED: independently computed — formula validated at 21.00:1 for black on white]

### Light Surfaces

| Color | Hex | White `#FFFFFF` | Stone Mist `#E8ECE8` | Rain Tint `#F5F7F6` | AA Normal (≥4.5) |
|-------|-----|---------|---------|---------|----------|
| Basalt | `#0F1720` | 18.05:1 | 15.12:1 | 16.77:1 | PASS all |
| Slate Stead | `#24313D` | 13.28:1 | 11.12:1 | 12.34:1 | PASS all |
| Ink Blue | `#183247` | 13.24:1 | 11.09:1 | 12.31:1 | PASS all |
| Stead Blue | `#3A6F8F` | 5.45:1 | 4.57:1 | 5.07:1 | PASS all |
| Info | `#356E8C` | 5.58:1 | 4.68:1 | 5.19:1 | PASS all |
| Danger | `#B44949` | 5.26:1 | **4.41:1 FAIL** | 4.89:1 | FAIL Stone Mist |
| Success | `#2F7D57` | 5.01:1 | **4.20:1 FAIL** | 4.66:1 | FAIL Stone Mist |
| Moss Grey | `#6C7A73` | 4.50:1 | **3.77:1 FAIL** | **4.18:1 FAIL** | FAIL Stone+Rain |
| Ember Copper | `#B96A3A` | **4.05:1 FAIL** | **3.39:1 FAIL** | **3.76:1 FAIL** | FAIL all |
| Warning | `#B57A21` | **3.64:1 FAIL** | **3.05:1 FAIL** | **3.38:1 FAIL** | FAIL all |
| Signal Gold | `#D2A94E` | **2.20:1 FAIL** | **1.85:1 FAIL** | **2.05:1 FAIL** | Decorative-only per D-09 |

### Dark Surface `#10161f`

| Color | Hex | Ratio on `#10161f` | AA Normal (≥4.5) |
|-------|-----|---------|----------|
| Stone Mist (text) | `#E8ECE8` | 15.2:1 | PASS |
| Rain Tint (text) | `#F5F7F6` | 17.0:1 | PASS |
| Moss Grey | `#6C7A73` | 4.04:1 | **FAIL** |
| Stead Blue | `#3A6F8F` | 3.33:1 | **FAIL** |
| Info | `#356E8C` | 3.25:1 | **FAIL** |
| Danger | `#B44949` | 3.45:1 | **FAIL** |
| Success | `#2F7D57` | 3.62:1 | **FAIL** |
| Ember Copper | `#B96A3A` | 4.48:1 | **FAIL** (0.02:1 short) |
| Warning | `#B57A21` | 4.99:1 | PASS |
| Signal Gold | `#D2A94E` | 8.24:1 | PASS (but decorative-only policy) |
| Shipped `--rs-primary (dark)` | `#2563eb` | **3.51:1** | **FAIL** |
| Shipped `--rs-success (dark)` | `#4ade80` | 10.42:1 | PASS (high margin) |
| Shipped `--rs-warning (dark)` | `#fbbf24` | 10.88:1 | PASS (high margin) |
| Shipped `--rs-error (dark)` | `#f87171` | 6.56:1 | PASS |

---

## AA-Passing Remediation Targets

These targets were computed fresh this session using binary-search uniform-RGB-scale at 1/100-step resolution. The PITFALLS.md values are directionally correct but contain rounding errors that put some targets at 4.49:1 (technically FAIL). Use the values below — they are the independently computed minimum-darkening values that actually pass 4.5:1.

[VERIFIED: computed this session; each ratio confirmed ≥4.5:1]

### Light Surface Remediations (Darken: multiply channels by k<1)

| Color | Background | Book Hex | AA-Passing Hex | Verified Ratio | OKLCH H° Before | OKLCH H° After | Drift |
|-------|-----------|----------|----------------|---------------|-----------------|----------------|-------|
| Ember Copper | White `#FFFFFF` | `#B96A3A` | `#ac6336` | 4.573:1 | 50.2° | 50.2° | 0.09° |
| Ember Copper | Rain Tint `#F5F7F6` | `#B96A3A` | `#a65f34` | 4.531:1 | 50.2° | 49.8° | 0.36° |
| Ember Copper | Stone Mist `#E8ECE8` | `#B96A3A` | `#9b5931` | 4.550:1 | 50.2° | 50.8° | 0.65° |
| Warning | White `#FFFFFF` | `#B57A21` | `#9f6b1d` | 4.570:1 | 71.9° | 72.3° | 0.37° |
| Warning | Stone Mist `#E8ECE8` | `#B57A21` | `#8f601a` | 4.563:1 | 71.9° | 72.3° | 0.38° |
| Moss Grey | Stone Mist `#E8ECE8` | `#6C7A73` | `#606d66` | 4.539:1 | 164.3° | 164.3° | <0.1° |
| Moss Grey | Rain Tint `#F5F7F6` | `#6C7A73` | `#67746d` | 4.544:1 | 164.3° | 164.3° | <0.1° |
| Success | Stone Mist `#E8ECE8` | `#2F7D57` | `#2d7753` | 4.540:1 | 159.0° | 159.0° | <0.1° |
| Danger | Stone Mist `#E8ECE8` | `#B44949` | `#b04848` | 4.551:1 | 22.9° | 22.9° | <0.1° |

**Note on "one canonical value per role":** The standard approach is to pick the darkest of the per-surface AA-passing targets so one hex passes all three light surfaces. For Ember Copper that means `#9b5931` (passes Stone Mist at 4.55:1 and trivially passes White and Rain Tint). For Warning: `#8f601a`. For Moss Grey: `#606d66`. The reconciliation table should document the per-surface verification rows AND name one canonical selected value per role.

### Dark Surface Remediations (Lighten: blend toward white)

| Color | Book Hex | AA-Passing (Lightened) Hex | Verified Ratio on `#10161f` | Method |
|-------|----------|---------------------------|------------------------------|--------|
| Stead Blue | `#3A6F8F` | `#5885a0` | 4.563:1 | Lighten toward white |
| Ember Copper | `#B96A3A` | `#ba6b3c` | 4.545:1 | Tiny nudge (was 4.48:1) |
| Success | `#2F7D57` | `#488d6b` | 4.581:1 | Lighten toward white |
| Danger | `#B44949` | `#bf6464` | 4.515:1 | Lighten toward white |
| Info | `#356E8C` | `#55859e` | 4.526:1 | Lighten toward white |
| Moss Grey | `#6C7A73` | `#75827b` | 4.527:1 | Lighten toward white |

**OKLCH hue drift on dark-mode remediations (Ember Copper and Warning, per success criterion 2):**
- Ember Copper dark nudge `#B96A3A` → `#ba6b3c`: H 50.2° → 50.2°, **drift 0.09°** (well under 3°)
- Warning `#B57A21` passes on dark already (4.99:1) — no dark-mode remediation needed

---

## Critical Gaps in Pre-Computed PITFALLS.md Data

The planner must flag these to the maintainer at the D-11 acceptance checkpoint. [VERIFIED: discrepancies confirmed by independent computation this session]

### Gap 1: Four borderline targets in PITFALLS.md are 4.49:1 (technically FAIL)

PITFALLS.md lists these as "AA-passing target hexes" but they compute to 4.489–4.499:1, which is below the strict 4.5:1 threshold:

| PITFALLS.md Target | Computed Ratio | Status | Corrected Hex |
|--------------------|---------------|--------|---------------|
| Ember `#AE6437` on white | 4.4893:1 | **FAIL** | `#ac6336` (4.573:1) |
| Ember `#9C5A31` on Stone Mist | 4.4880:1 | **FAIL** | `#9b5931` (4.550:1) |
| Moss Grey `#67756E` on Rain Tint | 4.4905:1 | **FAIL** | `#67746d` (4.544:1) |
| Warning `#90611A` on Stone Mist | 4.4991:1 | **FAIL** | `#8f601a` (4.563:1) |

These are rounding artifacts from PITFALLS.md's approach of binary-searching at a coarser step. Use the corrected targets in the reconciliation table.

### Gap 2: Success and Danger on Stone Mist not in PITFALLS.md failure table

PITFALLS.md lists Success and Danger as passing on white and failing only on dark `#10161f`. But independent computation shows:
- **Success `#2F7D57` on Stone Mist `#E8ECE8`: 4.20:1 — FAIL** (not in PITFALLS.md)
- **Danger `#B44949` on Stone Mist `#E8ECE8`: 4.41:1 — FAIL** (not in PITFALLS.md)

Both pass on White and Rain Tint. Stone Mist is a commonly used panel surface (`--rs-surface`-level background). The reconciliation table must include these failures and their corrections (`#2d7753` for Success, `#b04848` for Danger on Stone Mist).

**Decision needed at D-11:** The planner should surface this gap to the maintainer. Options:
1. Include darkened variants for Success/Danger on Stone Mist in the canonical palette (most complete)
2. Add a policy note: "Do not use Success/Danger brand-book colors as normal-weight text on Stone Mist panels without AA-darkening"

### Gap 3: Shipped dark-mode status colors are NOT mineral palette values

The shipped dark-mode CSS (`#4ade80` success, `#fbbf24` warning, `#f87171` error) already pass WCAG AA on `#10161f` but are generic Tailwind-style colors, not the mineral palette. The reconciliation table must explicitly document this in the "current shipped hex" column as "generic (not mineral)" and show both: the book mineral value (which fails), and the AA-lightened mineral variant that Phase 98 should use.

### Gap 4: Shipped dark `--rs-primary: #2563eb` fails on dark base

The shipped dark-mode primary `#2563eb` has 3.51:1 on `#10161f` — it fails. This is the same blue as the light primary. PITFALLS.md mentions SteadBlue brand-book value failing dark, but not the shipped value. The reconciliation table should note both: the book value `#3A6F8F` (3.33:1, fails) AND the shipped value `#2563eb` (3.51:1, also fails). Both need the same remedy: use the AA-lightened mineral dark variant `#5885a0`.

---

## Computation Methods

### WCAG 2.x Relative Luminance + Contrast Ratio

Standard formula [CITED: WCAG 2.1 §1.4.3]:

```python
def linearize(channel_byte):
    """sRGB channel (0-255) → linear light"""
    c = channel_byte / 255.0
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4

def relative_luminance(r_byte, g_byte, b_byte):
    """WCAG 2.x relative luminance from sRGB bytes"""
    return (0.2126 * linearize(r_byte) +
            0.7152 * linearize(g_byte) +
            0.0722 * linearize(b_byte))

def contrast_ratio(hex1, hex2):
    """WCAG 2.x contrast ratio between two hex colors"""
    def parse(h):
        h = h.lstrip('#')
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    L1 = relative_luminance(*parse(hex1))
    L2 = relative_luminance(*parse(hex2))
    lighter, darker = max(L1, L2), min(L1, L2)
    return (lighter + 0.05) / (darker + 0.05)

# Validation: contrast_ratio('#000000', '#ffffff') must == 21.0
```

**Verification anchor:** black on white = 21.00:1, white on white = 1.00:1. Confirmed by this session's computation.

### OKLCH Hue Angle Computation (sRGB → Linear → XYZ → OKLab → OKLCH)

Standard conversion chain [CITED: Björn Ottosson, OKLab specification 2020]:

```python
import math

def linearize(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def rgb_to_oklch(r, g, b):
    """Compute OKLCH from sRGB bytes (0-255). Returns (L, C, H_degrees)."""
    # 1. sRGB → linear
    rl, gl, bl = linearize(r), linearize(g), linearize(b)
    # 2. Linear sRGB → XYZ D65
    x = 0.4124564*rl + 0.3575761*gl + 0.1804375*bl
    y = 0.2126729*rl + 0.7151522*gl + 0.0721750*bl
    z = 0.0193339*rl + 0.1191920*gl + 0.9503041*bl
    # 3. XYZ → LMS (Ottosson M1)
    lm = 0.8189330101*x + 0.3618667424*y - 0.1288597137*z
    mm = 0.0329845436*x + 0.9293118715*y + 0.0361456387*z
    sm = 0.0482003018*x + 0.2643662691*y + 0.6338517070*z
    # 4. LMS → LMS^(1/3)
    lg, mg, sg = lm**(1/3), mm**(1/3), sm**(1/3)
    # 5. LMS^(1/3) → OKLab (Ottosson M2)
    L = 0.2104542553*lg + 0.7936177850*mg - 0.0040720468*sg
    a = 1.9779984951*lg - 2.4285922050*mg + 0.4505937099*sg
    b_ok = 0.0259040371*lg + 0.7827717662*mg - 0.8086757660*sg
    # 6. OKLab → OKLCH
    C = math.sqrt(a**2 + b_ok**2)
    H = math.degrees(math.atan2(b_ok, a)) % 360
    return L, C, H
```

**Hue drift measurement:** Compute H before and after uniform-RGB-scale adjustment. Take `abs(H_after - H_before)`; if > 180°, use `360 - diff`. Must be < 3° for Ember Copper and Warning to satisfy D-06.

### Uniform-RGB-Scale Darkening/Lightening

```python
def uniform_darken(hex_str, k):
    """k < 1.0: darken. k > 1.0: lighter (capped at 255)."""
    h = hex_str.lstrip('#')
    r, g, b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    nr = min(255, max(0, round(r * k)))
    ng = min(255, max(0, round(g * k)))
    nb = min(255, max(0, round(b * k)))
    return f"#{nr:02x}{ng:02x}{nb:02x}"

def uniform_lighten_toward_white(hex_str, blend):
    """blend = 0.0 (no change) to 1.0 (pure white). Equivalent to lerp with white."""
    h = hex_str.lstrip('#')
    r, g, b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    nr = min(255, round(r + (255 - r) * blend))
    ng = min(255, round(g + (255 - g) * blend))
    nb = min(255, round(b + (255 - b) * blend))
    return f"#{nr:02x}{ng:02x}{nb:02x}"
```

**Why not HSL:** HSL lightness reduction shifts perceived hue toward grey for warm colors (oranges, coppers become brownish). OKLCH L reduction is perceptually uniform. Uniform-RGB-scale is equivalent to OKLCH L adjustment to within ~1° hue drift — verified by the matrix computation above (all Ember Copper adjustments: 0.09°–0.65° drift, well under 3°).

**v1.13 precedent:** `#c45c26` → `#9a3f12` used this method; measured hue drift was 2.1° OKLCH (acceptable). The new remediations above have smaller drift (0.09°–0.65°) because the starting point is less saturated than the v1.13 value.

---

## Shipped CSS vs. Brand Book: Delta Table

This is the "current shipped hex → proposed re-skin hex" mapping that forms the core of the reconciliation table. [VERIFIED: shipped values extracted from file; book values extracted from brand book]

| `--rs-*` Token | Shipped (Block 1 light) | Brand Book Mineral | Delta Type |
|----------------|------------------------|--------------------|------------|
| `--rs-primary` | `#2563eb` (generic blue) | `#3A6F8F` Stead Blue | Brand → mineral |
| `--rs-primary-hover` | `#1d4ed8` | `#183247` Ink Blue | Brand → mineral |
| `--rs-accent` | `#9a3f12` (v1.13 darkened copper) | `#B96A3A` Ember Copper → AA-fix `#9b5931` | Brand → mineral → AA |
| `--rs-success` | `#15803d` (generic green) | `#2F7D57` Success → `#2d7753` on Stone | Brand → mineral → AA on Stone |
| `--rs-warning` | `#b45309` (generic amber) | `#B57A21` Warning → `#8f601a` for normal text | Brand → mineral → AA |
| `--rs-error` | `#b91c1c` (generic red) | `#B44949` Danger → `#b04848` on Stone | Brand → mineral → AA on Stone |
| `--rs-primary (dark)` | `#2563eb` (fails AA) | `#5885a0` (AA-lightened Stead Blue) | Shipped fail → AA fix |
| `--rs-accent (dark)` | `#e8834a` (passing) | `#ba6b3c` (mineral Ember dark) | Style → mineral |
| `--rs-success (dark)` | `#4ade80` (generic, passing) | `#488d6b` (AA-lightened mineral) | Generic → mineral |
| `--rs-warning (dark)` | `#fbbf24` (generic, passing) | `#B57A21` (passes dark already at 4.99:1) | Generic → mineral (passes) |
| `--rs-error (dark)` | `#f87171` (generic, passing) | `#bf6464` (AA-lightened mineral Danger) | Generic → mineral |

**Neutral ramp (light):** Shipped ramp (`#f4f6f8`, `#d8dee6`, etc.) is a generic cool-grey ramp, close to but not identical with the mineral palette. `--rs-neutral-50: #f4f6f8` vs Rain Tint `#F5F7F6` (1.01:1 contrast — nearly identical); Stone Mist `#E8ECE8` vs `--rs-neutral-200: #e7ebf0` (1.01:1 — very close but different hue). Phase 98 aligns the neutral ramp to the mineral palette; Phase 95 documents the existing ramp for the "current shipped" column.

**Dark neutral ramp:** The shipped dark ramp (`#10161f` base through `#e8edf3`) is already the v1.13 mineral-dark system established in STATE.md. This ramp is kept as-is per D-10.

---

## Brand Book Pressure-Test Audit Framework

The brand book at `prompts/rulestead-brand-book.md` has 27 sections [VERIFIED: direct file read]. The pressure-test audit (BRD-01) assigns each section a KEEP/TIGHTEN/REWORK/ADD/REMOVE rating.

### Section Inventory for Audit

| # | Section Title | Key Content | Audit Signal |
|---|---------------|-------------|--------------|
| 1 | Brand foundation | Name, category, meaning | Strong — precise and differentiated |
| 2 | Brand strategy | Purpose, mission, vision, promise, positioning | Strong — well-reasoned, BEAM-native |
| 3 | Brand essence | Core idea, keywords, personality, archetype | Strong — Architect+Steward is ownable |
| 4 | Product narrative | Problem, answer, north-star message | Strong — ops-aware and honest |
| 5 | Audience | Primary/secondary/tertiary with care-abouts | Strong — practical |
| 6 | Differentiation | Core differentiators, not-list, competitive language | Strong — explicit negative space |
| 7 | Messaging architecture | One-liner, pitches (short/medium/long), pillars | Solid; tagline section has multiple options |
| 8 | Tagline directions | Multiple options + recommended | Needs selection — "Runtime decisions, made clear." is good |
| 9 | Verbal identity | Voice principles, profile, tone by context | Strong — practical and calibrated |
| 10 | Naming conventions | Product vocabulary, mental model, contrast language | Strong — enforces precise vocabulary |
| 11 | Visual identity overview | Visual concept, metaphor territory | Strong concept; needs logo to make it real |
| 12 | Color system | Mineral palette, semantic colors, usage ratios, rules | REWORK required — AA failures; current shipped CSS diverges |
| 13 | Typography | Font system, hierarchy, rules | Strong — Sora/Inter/IBM Plex Mono well-justified |
| 14 | Logo direction | Strategy, symbol directions A/B/C, constraints | Solid directions; needs Phase 97 selection |
| 15 | Layout system | Grid, whitespace, shape language, radius, shadows | Strong guidance; slightly abstract without examples |
| 16 | Iconography | Style, themes, avoid list | Adequate; no icon set yet |
| 17 | Imagery | Acceptable/avoid categories, photography/illustration | Strong negative-space guidance |
| 18 | Motion | Character, principles, good/bad patterns | Strong; no concrete values (durations/easing) |
| 19 | UI writing standards | Buttons, empty states, errors, warnings, success | Strong — concrete and actionable |
| 20 | Documentation style | Philosophy, language, code examples | Strong — production-capable framing |
| 21 | Open-source posture | Brand behavior, maintainer tone, community | Strong — differentiated for OSS |
| 22 | Content pillars | 5 pillars for marketing and docs | Strong — maps to product thesis |
| 23 | Copy examples | Homepage hero, explainer lines, docs intro | Good base; BRD-03 szTheory suite note missing |
| 24 | Brand guardrails | Never-position, always-reinforce, forced-choice | Strong — clear negative constraints |
| 25 | Practical implementation defaults | Default stack, interface styling, illustration | Good summary; color defaults will need updating to AA-verified hexes |
| 26 | Internal LLM/design context summary | Compact brand statement for AI/design handoffs | Useful; should be updated after palette lock |
| 27 | Final brand mantra | "Rulestead makes change feel governed, not chaotic." | Excellent — memorable and aligned |

### Known Gaps for the ADD category

1. **szTheory suite brand-architecture note** — BRD-03 (Phase 100): Rulestead's relationship to Parapet, Scoria, Cairnloop not defined in brand book. Phase 95 audit should flag this as ADD.
2. **AA-verified hex values in §12** — The color system section currently lists book-literal hexes that fail AA. Phase 95 audit should flag §12 as REWORK with the AA-verified replacements.
3. **Concrete motion timing values** — §18 specifies principles but no actual duration/easing values. These exist in the shipped CSS (`:root --rs-motion-fast: 150ms` etc.). Phase 95 can flag as TIGHTEN.
4. **Accessibility section** — No dedicated section on WCAG compliance, forced-colors/high-contrast mode, or keyboard navigation principles. Phase 95 can flag as ADD (even a brief note).

---

## Dark-Mode Ramp: Slot Mapping from v1.13 to Mineral

Per D-10, the dark ramp is not rederived — it maps brand-book mineral values onto existing v1.13 slots. [VERIFIED: v1.13 ramp extracted from shipped CSS]

| Slot | v1.13 Shipped Hex | Mineral Palette Name | Mineral Hex | Notes |
|------|------------------|---------------------|-------------|-------|
| `--rs-neutral-0` (dark base) | `#10161f` | (v1.13 base, kept) | `#10161f` | D-10: do not swap to Basalt `#0F1720` |
| `--rs-neutral-25` (faint surface) | `#141c27` | — | `#141c27` | Keep (mineral-dark step) |
| `--rs-neutral-50` (bg) | `#19222e` | — | `#19222e` | Keep |
| `--rs-neutral-100` (surface muted) | `#1f2a38` | — | `#1f2a38` | Keep |
| `--rs-neutral-200` (border subtle) | `#253243` | ≈ Slate Stead | `#24313D` | Slight alignment possible; audit for change |
| `--rs-neutral-300` (border) | `#2e3d52` | — | `#2e3d52` | Keep |
| `--rs-neutral-400` (border strong) | `#3d5168` | — | `#3d5168` | Keep |
| `--rs-neutral-500` (placeholder) | `#7a8fa3` | — | `#7a8fa3` | Keep |
| `--rs-neutral-600` (text muted) | `#a8b9ca` | → AA-lightened MossGrey | `#75827b` | Replace with mineral |
| `--rs-neutral-900` (text) | `#e8edf3` | → Stone Mist | `#E8ECE8` | Replace with mineral |
| `--rs-primary` (brand) | `#2563eb` | Stead Blue AA-light | `#5885a0` | Brand token — replace |
| `--rs-accent` (brand) | `#e8834a` | Ember Copper AA-light | `#ba6b3c` | Brand token — replace |
| `--rs-success` | `#4ade80` | Success AA-light | `#488d6b` | Replace generic |
| `--rs-warning` | `#fbbf24` | Warning (passes dark) | `#B57A21` | Replace generic |
| `--rs-error` | `#f87171` | Danger AA-light | `#bf6464` | Replace generic |

**Elevation principle (confirmed):** `#10161f` → `#141c27` → `#19222e` → `#1f2a38` → `#253243` → `#2e3d52`. Each step increases OKLCH L. No hue shift. Hairline borders using ramp steps for separation.

---

## Deliverable Files Recommended

The planner should create two markdown artifacts + one python3 script:

1. **`95-PALETTE-RECONCILIATION.md`** — The reconciliation table (D-02 columns), WCAG ratios, AA-verified hexes, OKLCH hue angle column for Ember Copper and Warning, dark ramp mapping, Signal Gold policy, relocation decision confirmation (D-04).

2. **`95-BRAND-AUDIT.md`** — Brand book pressure-test scorecard (BRD-01). KEEP/TIGHTEN/REWORK/ADD/REMOVE rating for each of the 27 sections + overall scorecard.

3. **`scripts/check_contrast.py`** — The python3 stdlib contrast + OKLCH snippet (D-05 discretion: favor committed script since it is reused by Phase 96's `check_brand_tokens.py` and Phase 98's AA gate). Mirrors the `check_synced_pair.py` style (stdlib-only, no deps, exits 0/1).

---

## Common Pitfalls for This Phase

### Pitfall 1: Treating 4.49:1 as "passing"

**What goes wrong:** PITFALLS.md lists several targets at 4.49:1 and labels them "passing." If the planner uses these hex values for the reconciliation table, Phase 96 token values will be below 4.5:1 and Phase 98's AA gate will fail.

**Prevention:** Use the corrected hex values from the table above. The reconciliation table must show ratios computed to 3+ decimal places so borderline cases are unambiguous.

### Pitfall 2: Omitting Success/Danger on Stone Mist

**What goes wrong:** The PITFALLS.md failure table does not include Success `#2F7D57` (4.20:1) and Danger `#B44949` (4.41:1) on Stone Mist. If these are not in the reconciliation table, Phase 98 will ship a re-skin that fails AA for semantic status text on panel surfaces.

**Prevention:** The reconciliation table must cover all four surface+color combinations (White, Stone Mist, Rain Tint, dark base) for every semantic color. Success and Danger need darkened variants for Stone Mist use.

### Pitfall 3: Shipped dark status colors distract from mineral targets

**What goes wrong:** The currently shipped dark-mode status colors (`#4ade80`, `#fbbf24`, `#f87171`) pass AA by large margins. It is tempting to keep them. But they are not mineral palette values and will not match the brand system.

**Prevention:** The reconciliation table has a "current shipped hex" column AND a "proposed re-skin hex" column for a reason. Document both. The AA-lightened mineral variants pass AA (verified above) and are the correct targets.

### Pitfall 4: Confusing the reconciliation table scope with Phase 98 implementation scope

**What goes wrong:** Phase 95 is a written record only. No CSS is touched. If the planner accidentally includes CSS editing tasks in Phase 95, it violates D-01 and risks conflating the locked palette with implementation.

**Prevention:** Every task in Phase 95 produces markdown artifacts only. The python3 script is the only non-markdown output (and it is a new file at `scripts/check_contrast.py`, not a CSS edit).

---

## Validation Architecture

The python3 verification snippet is the only automated verification in Phase 95. Its correctness can be anchored on two known-good contrast pairs:

### Test Framework

| Property | Value |
|----------|-------|
| Framework | python3 stdlib (no test runner) |
| Config file | none |
| Quick run command | `python3 scripts/check_contrast.py` |
| Full suite command | same |

### Validation Anchors

| Anchor | Expected | Rationale |
|--------|----------|-----------|
| Black on white | 21.00:1 exactly | WCAG 2.1 §1.4.3 definition |
| White on white | 1.00:1 exactly | Same color = 1:1 |
| Stead Blue `#3A6F8F` on white | 5.45:1 | Confirmed pass; non-trivial value |
| Ember Copper `#B96A3A` on white | 4.05:1 | Confirmed fail; anchor for remediation direction |

The script should self-test with these anchors on startup and exit non-zero if any fails. This guards against silent formula errors in the implementation.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Notes |
|--------|----------|-----------|-------|
| PAL-01 | Every pairing has a computed ratio | Automated (python3 script) | Script runs contrast_ratio for all combinations |
| PAL-02 | All AA-failing pairings have ≥4.5:1 remediated values | Automated (script asserts ≥4.5) | Script verifies each AA-verified hex in reconciliation table |
| PAL-03 | Dark ramp anchored on v1.13 | Human review | Slot mapping documented in `95-PALETTE-RECONCILIATION.md` |
| PAL-04 | Signal Gold policy documented | Human review | Policy text in `95-PALETTE-RECONCILIATION.md` |
| BRD-01 | Pressure-test audit written | Human review | `95-BRAND-AUDIT.md` exists with ratings for all 27 sections |
| BRD-02 | Relocation decision confirmed | Human review | D-04 confirmed statement in `95-PALETTE-RECONCILIATION.md` |
| D-11 | Maintainer accepts AA-adjusted hexes | Human checkpoint | Phase-close gate; not automated |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | `scripts/check_contrast.py` | Yes | System python3 (repo already uses it in `check_synced_pair.py`) | — |

Step 2.6: No external dependencies beyond python3 stdlib. No services, databases, or CLI tools required.

---

## Security Domain

> This phase produces only markdown artifacts and a python3 stdlib script. No authentication, session management, network access, external data handling, or user input is involved.

Not applicable to Phase 95.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `--rs-neutral-600: #a8b9ca` dark-mode text-muted value should be replaced with mineral `#75827b` (AA-lightened Moss Grey) | Dark ramp mapping | Minimal — both pass AA; difference is stylistic brand alignment |
| A2 | Success/Danger Stone Mist failures should be remediated in the canonical palette (not just via usage policy) | Critical Gaps | If maintainer prefers policy-only (as with Signal Gold), the reconciliation table has fewer darkened variants |
| A3 | One canonical AA-verified hex per role (darkest of the per-surface AA-passing targets) is the right strategy | AA targets | If maintainer prefers per-surface values in tokens.json, that requires a more complex token structure — flagged for D-11 |

If this table is empty: All claims in this research were verified or cited. The items above are design decisions, not factual uncertainties.

---

## Open Questions (RESOLVED)

> All three resolved by the Phase 95 plan's design choices; the substantive
> brand-acceptance call (Q1) is escalated to the D-11 maintainer checkpoint (Plan 95-04).
> Q1: RESOLVED — default to including AA-darkened variants (`#2d7753`, `#b04848`) in the
> reconciliation table; D-11 gate lets the maintainer choose hex-adjustment vs. usage-policy.
> Q2: RESOLVED — single canonical Stone-Mist-passing hex per role (passes all three light
> surfaces); per-surface ratios still documented for transparency.
> Q3: RESOLVED — commit `scripts/check_contrast.py` standalone (mirrors `check_synced_pair.py`).

1. **Should Success/Danger on Stone Mist be remediated by hex adjustment or usage policy?**
   - What we know: Both fail AA on Stone Mist (4.20:1 and 4.41:1). Both pass on White and Rain Tint. Darkened variants (`#2d7753`, `#b04848`) pass on Stone Mist.
   - What's unclear: Whether Stone Mist panels will commonly use brand semantic colors as normal-weight text in the admin UI. If semantic status colors are only used as icon fills, badge backgrounds, or large text on Stone Mist, the 3:1 non-text UI threshold applies (both pass easily at that level).
   - Recommendation: Surface at D-11 checkpoint. Default to including AA-darkened variants in the reconciliation table so Phase 96 has approved values available.

2. **Should one canonical AA-passing hex per role cover all three light surfaces, or per-surface values?**
   - What we know: Ember Copper needs different darkening for White vs. Stone Mist (larger delta for darker surface). A single canonical value that passes Stone Mist will trivially pass White and Rain Tint.
   - Recommendation: Use the Stone-Mist-passing value as the single canonical (it passes all three). Document per-surface verification in the table for transparency.

3. **Should `scripts/check_contrast.py` be a standalone file or folded into a future `check_brand_tokens.py`?**
   - Recommendation: Commit as standalone `scripts/check_contrast.py` (mirrors the single-responsibility pattern of `check_synced_pair.py`). Phase 96 authors `check_brand_tokens.py` which can import the formula or duplicate the 15-line core (no build system needs a separate package).

---

## Sources

### Primary (HIGH confidence)

- `rulestead_admin/priv/static/css/rulestead_admin.css` lines 224–549 — All four cascade blocks read verbatim; shipped token values extracted [VERIFIED]
- `prompts/rulestead-brand-book.md` — Complete 27-section brand book; all mineral hex values and section titles extracted [VERIFIED]
- `.planning/phases/95-brand-audit-palette-reconciliation/95-CONTEXT.md` — D-01 through D-11 locked decisions [VERIFIED]
- `.planning/research/PITFALLS.md` — Pre-computed failure tables; AA-passing target hexes; OKLCH method [VERIFIED]
- `.planning/research/SUMMARY.md` — Failure enumeration; gate-zero rationale [VERIFIED]
- `.planning/research/ARCHITECTURE.md` — Deliverable location; relocation-to-Phase-96 decision [VERIFIED]
- `scripts/check_synced_pair.py` — Python3 stdlib drift-check pattern [VERIFIED]
- WCAG 2.1 §1.4.3 contrast formula — sRGB relative-luminance formula [CITED: w3.org/TR/WCAG21/#contrast-minimum]
- OKLab/OKLCH specification — Björn Ottosson 2020; M1 and M2 matrices [CITED: bottosson.github.io/posts/oklab/]

### Independently Verified This Session

All contrast ratios in this document were independently computed using the python3 stdlib formulas above (not copied from PITFALLS.md). Discrepancies with PITFALLS.md pre-computed values are documented in the Critical Gaps section. OKLCH hue drift values for all remediated colors were independently verified.

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Shipped CSS token values | HIGH | Extracted verbatim from committed file |
| Brand-book mineral palette | HIGH | Extracted verbatim from committed file |
| Contrast ratios | HIGH | Independently computed this session; formula validated at 21:1 anchor |
| OKLCH hue drift values | HIGH | Independently computed this session using Ottosson spec matrices |
| AA-passing target hexes | HIGH | Independently computed; four PITFALLS.md targets corrected |
| Brand audit framework | HIGH | 27 sections enumerated from direct file read |
| Gaps in PITFALLS.md | HIGH | Gap 1 (borderline 4.49) and Gap 2 (Success/Danger on Stone) confirmed by independent computation |

**Research date:** 2026-06-04
**Valid until:** Stable — these are mathematical computations against fixed hex values. Valid until the brand-book mineral palette changes.
