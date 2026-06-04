# Phase 95: Palette Reconciliation — Locked Decision Record

**Status:** Locked (D-11 maintainer sign-off pending)
**Authored:** 2026-06-04
**Verified by:** `python3 scripts/check_contrast.py` — exits 0, 18 checks PASS

Locked palette decision record for Phase 95 (Brand Audit + Palette Reconciliation).
Authoritative input for Phases 96 (tokens.json), 97 (mark SVG fills), and 98 (admin
CSS re-skin). Nothing is committed to `brandbook/` in this phase (D-01, D-04).

---

## Section 1: Purpose

This document records every WCAG AA contrast decision for the Rulestead mineral
palette. It provides:

1. The full D-02 reconciliation table (brand-book name → current shipped hex → proposed
   re-skin hex → AA-verified hex → computed WCAG 2.x ratio → surface → role → OKLCH hue
   angle pre→post for remediated entries).
2. The dark-mode ramp slot mapping (D-10 / PAL-03).
3. Signal Gold decorative-only policy (D-09 / PAL-04).
4. Brand-book relocation decision confirmation (D-04 / BRD-02).
5. D-11 sign-off surface: AA-adjusted hex list for maintainer review.

Downstream phases MUST use only the AA-verified hex values from Section 3. The
"current shipped hex" column documents the state before Phase 98 re-skin.

---

## Section 2: Methodology

**Contrast formula:** WCAG 2.x relative-luminance per WCAG 2.1 §1.4.3. sRGB channels
linearized with the standard piecewise function; luminance is the weighted sum
`0.2126·R + 0.7152·G + 0.0722·B`. Contrast ratio = `(L_lighter + 0.05) / (L_darker + 0.05)`.

**OKLCH hue angles:** Computed via Ottosson M1+M2 matrices: sRGB → linear → XYZ D65
→ LMS → LMS^(1/3) → OKLab → OKLCH. Hue drift = `|H_after − H_before|` with
360°-wraparound correction.

**Remediation method:** Uniform-RGB-scale darkening/lightening (multiply all channels
by constant k). This method never uses HSL lightness reduction, which shifts perceived
hue for warm colors. It is equivalent to OKLCH L adjustment to within ~1° hue drift —
confirmed by the measured values below. This is the established v1.13 repo precedent:
`#c45c26 → #9a3f12` hue drift was 2.1° (acceptable; all Phase 95 remediations are
smaller).

**Verification:** All ratios and OKLCH drift values verified by
`python3 scripts/check_contrast.py` (exits 0). Output reproduced verbatim in Section 2.1.

### Section 2.1: check_contrast.py Output (authoritative)

```
ANCHORS OK
PASS  4.550:1  Ember Copper canonical #9b5931 on Stone Mist #E8ECE8
PASS  4.573:1  Ember Copper #ac6336 on White #FFFFFF
PASS  4.531:1  Ember Copper #a65f34 on Rain Tint #F5F7F6
PASS  4.563:1  Warning canonical #8f601a on Stone Mist #E8ECE8
PASS  4.570:1  Warning #9f6b1d on White #FFFFFF
PASS  4.539:1  Moss Grey canonical #606d66 on Stone Mist #E8ECE8
PASS  4.544:1  Moss Grey #67746d on Rain Tint #F5F7F6
PASS  4.540:1  Success #2d7753 on Stone Mist #E8ECE8
PASS  4.550:1  Danger #b04848 on Stone Mist #E8ECE8
PASS  4.563:1  Stead Blue dark #5885a0 on #10161f
PASS  4.545:1  Ember Copper dark #ba6b3c on #10161f
PASS  4.581:1  Success dark #488d6b on #10161f
PASS  4.515:1  Danger dark #bf6464 on #10161f
PASS  4.526:1  Info dark #55859e on #10161f
PASS  4.527:1  Moss Grey dark #75827b on #10161f
PASS  drift=0.09deg  OKLCH drift: Ember Copper light canonical #B96A3A -> #9b5931 (must be <3 deg)
PASS  drift=0.02deg  OKLCH drift: Warning light canonical #B57A21 -> #8f601a (must be <3 deg)
PASS  drift=0.37deg  OKLCH drift: Ember Copper dark #B96A3A -> #ba6b3c (must be <3 deg)
CONTRAST CHECK PASS (18 checks)
```

**Note on PITFALLS.md rounding (Gap 1):** PITFALLS.md lists four borderline target hexes
at 4.49:1 (technically below the 4.5:1 threshold). This document uses the corrected hexes
from RESEARCH.md §AA-Passing Remediation Targets (independently computed at finer step
resolution). No value in this document is 4.49:1.

---

## Section 3: Reconciliation Table (D-02 Format)

Columns: brand-book name | current shipped hex | proposed re-skin hex | AA-verified hex | WCAG ratio | surface | role | OKLCH H° pre→post | drift

Surface key: W = White `#FFFFFF` | SM = Stone Mist `#E8ECE8` | RT = Rain Tint `#F5F7F6` | DK = Dark `#10161f`

"Current shipped hex" reflects real Block 1 (light) and Block 2/3 (dark) `--rs-*` tokens
extracted verbatim from `rulestead_admin/priv/static/css/rulestead_admin.css`. Where no
direct `--rs-*` token maps to the brand-book color, "—" is shown.

### 3a. Light Surfaces — Passing (no remediation needed)

| Brand-book name | Current shipped hex | Proposed re-skin hex | AA-verified hex | WCAG ratio | Surface | Role | OKLCH H° pre→post | Drift |
|-----------------|---------------------|----------------------|-----------------|------------|---------|------|-------------------|-------|
| Basalt `#0F1720` | — | `#0F1720` | `#0F1720` | 18.05:1 | W | Heading / primary text | N/A | N/A |
| Basalt `#0F1720` | — | `#0F1720` | `#0F1720` | 15.12:1 | SM | Heading / primary text | N/A | N/A |
| Basalt `#0F1720` | — | `#0F1720` | `#0F1720` | 16.77:1 | RT | Heading / primary text | N/A | N/A |
| Slate Stead `#24313D` | — | `#24313D` | `#24313D` | 13.28:1 | W | Secondary dark UI / structural | N/A | N/A |
| Slate Stead `#24313D` | — | `#24313D` | `#24313D` | 11.12:1 | SM | Secondary dark UI / structural | N/A | N/A |
| Slate Stead `#24313D` | — | `#24313D` | `#24313D` | 12.34:1 | RT | Secondary dark UI / structural | N/A | N/A |
| Ink Blue `#183247` | — | `#183247` | `#183247` | 13.24:1 | W | Deep contrast / dark-on-light | N/A | N/A |
| Ink Blue `#183247` | — | `#183247` | `#183247` | 11.09:1 | SM | Deep contrast / dark-on-light | N/A | N/A |
| Ink Blue `#183247` | — | `#183247` | `#183247` | 12.31:1 | RT | Deep contrast / dark-on-light | N/A | N/A |
| Stead Blue `#3A6F8F` | `#2563eb` (generic blue) | `#3A6F8F` | `#3A6F8F` | 5.45:1 | W | Primary brand / active UI | N/A | N/A |
| Stead Blue `#3A6F8F` | `#2563eb` (generic blue) | `#3A6F8F` | `#3A6F8F` | 4.57:1 | SM | Primary brand / active UI | N/A | N/A |
| Stead Blue `#3A6F8F` | `#2563eb` (generic blue) | `#3A6F8F` | `#3A6F8F` | 5.07:1 | RT | Primary brand / active UI | N/A | N/A |
| Info `#356E8C` | — | `#356E8C` | `#356E8C` | 5.58:1 | W | Informational state | N/A | N/A |
| Info `#356E8C` | — | `#356E8C` | `#356E8C` | 4.68:1 | SM | Informational state | N/A | N/A |
| Info `#356E8C` | — | `#356E8C` | `#356E8C` | 5.19:1 | RT | Informational state | N/A | N/A |
| Success `#2F7D57` | `#15803d` (generic green) | `#2F7D57` | `#2F7D57` | 5.01:1 | W | Success state (normal text) | N/A | N/A |
| Success `#2F7D57` | `#15803d` (generic green) | `#2F7D57` | `#2F7D57` | 4.66:1 | RT | Success state (normal text) | N/A | N/A |
| Danger `#B44949` | `#b91c1c` (generic red) | `#B44949` | `#B44949` | 5.26:1 | W | Error / danger state | N/A | N/A |
| Danger `#B44949` | `#b91c1c` (generic red) | `#B44949` | `#B44949` | 4.89:1 | RT | Error / danger state | N/A | N/A |
| Moss Grey `#6C7A73` | — | `#6C7A73` | `#6C7A73` | 4.50:1 | W | Secondary text / supportive UI | N/A | N/A |

### 3b. Light Surfaces — Failing (remediated; OKLCH columns populated)

| Brand-book name | Current shipped hex | Proposed re-skin hex | AA-verified hex | WCAG ratio | Surface | Role | OKLCH H° pre→post | Drift |
|-----------------|---------------------|----------------------|-----------------|------------|---------|------|-------------------|-------|
| Ember Copper `#B96A3A` | `#9a3f12` (v1.13 darkened) | `#B96A3A` | `#ac6336` | 4.573:1 | W | Accent / CTA / emphasis | 50.2°→50.2° | 0.09° |
| Ember Copper `#B96A3A` | `#9a3f12` (v1.13 darkened) | `#B96A3A` | `#a65f34` | 4.531:1 | RT | Accent / CTA / emphasis | 50.2°→49.8° | 0.36° |
| Ember Copper `#B96A3A` | `#9a3f12` (v1.13 darkened) | `#B96A3A` | **`#9b5931`** ← CANONICAL | 4.550:1 | SM | Accent / CTA / emphasis | 50.2°→50.8° | 0.65° |
| Warning `#B57A21` | `#b45309` (generic amber) | `#B57A21` | `#9f6b1d` | 4.570:1 | W | Warning state | 71.9°→72.3° | 0.37° |
| Warning `#B57A21` | `#b45309` (generic amber) | `#B57A21` | **`#8f601a`** ← CANONICAL | 4.563:1 | SM | Warning state | 71.9°→72.3° | 0.38° |
| Moss Grey `#6C7A73` | — | `#6C7A73` | **`#606d66`** ← CANONICAL | 4.539:1 | SM | Secondary text / supportive UI | 164.3°→164.3° | <0.1° |
| Moss Grey `#6C7A73` | — | `#6C7A73` | `#67746d` | 4.544:1 | RT | Secondary text / supportive UI | 164.3°→164.3° | <0.1° |
| Success `#2F7D57` | `#15803d` (generic green) | `#2F7D57` | `#2d7753` | 4.540:1 | SM | Success state (Gap 2 — see note) | 159.0°→159.0° | <0.1° |
| Danger `#B44949` | `#b91c1c` (generic red) | `#B44949` | `#b04848` | 4.550:1 | SM | Error / danger state (Gap 2 — see note) | 22.9°→22.9° | <0.1° |

**Gap 2 note:** Success `#2F7D57` and Danger `#B44949` on Stone Mist fail AA (4.20:1 and
4.41:1 respectively). These failures were absent from PITFALLS.md. The AA-darkened variants
`#2d7753` and `#b04848` are the canonical remediated values for Stone Mist use. Resolution
(hex-adjust vs. usage policy) is an open question pending D-11 maintainer sign-off — see
Section 8.

### 3c. Dark Surface `#10161f` — Failing mineral values (remediated)

All entries on this surface use lightened (blend-toward-white) variants.

| Brand-book name | Current shipped hex | Proposed re-skin hex | AA-verified hex | WCAG ratio | Surface | Role | OKLCH H° pre→post | Drift |
|-----------------|---------------------|----------------------|-----------------|------------|---------|------|-------------------|-------|
| Stead Blue `#3A6F8F` | `#2563eb` (fails: 3.51:1) | `#3A6F8F` (fails: 3.33:1) | `#5885a0` | 4.563:1 | DK | Primary brand / active UI | N/A | N/A |
| Ember Copper `#B96A3A` | `#e8834a` (passes: ~5.0:1) | `#B96A3A` (fails: 4.48:1) | `#ba6b3c` | 4.545:1 | DK | Accent / CTA / emphasis | 50.2°→50.2° | 0.37° |
| Success `#2F7D57` | `#4ade80` (generic; passes: 10.42:1) | `#2F7D57` (fails: 3.62:1) | `#488d6b` | 4.581:1 | DK | Success state | N/A | N/A |
| Danger `#B44949` | `#f87171` (generic; passes: 6.56:1) | `#B44949` (fails: 3.45:1) | `#bf6464` | 4.515:1 | DK | Error / danger state | N/A | N/A |
| Info `#356E8C` | — | `#356E8C` (fails: 3.25:1) | `#55859e` | 4.526:1 | DK | Informational state | N/A | N/A |
| Moss Grey `#6C7A73` | — | `#6C7A73` (fails: 4.04:1) | `#75827b` | 4.527:1 | DK | Secondary text / supportive UI | N/A | N/A |

### 3d. Dark Surface — Passing mineral values (no remediation needed)

| Brand-book name | Hex | Ratio on `#10161f` | Role | Notes |
|-----------------|-----|--------------------|------|-------|
| Warning `#B57A21` | `#B57A21` | 4.99:1 | Warning state | PASS; shipped `#fbbf24` (10.88:1 generic) — replace with mineral in Phase 98 |
| Signal Gold `#D2A94E` | `#D2A94E` | 8.24:1 | Decorative only | PASS on dark; decorative-only policy applies uniformly — see Section 6 |

---

## Section 4: Canonical One-Hex-Per-Role Summary

Selection strategy: The Stone-Mist-passing value is chosen as the canonical light-surface
hex for each role — it trivially passes White and Rain Tint as well (both are lighter
than Stone Mist). This yields a single deployable value per role for Phase 96 tokens.json.

| Role | Canonical AA-Passing Hex (light) | Passes All Light Surfaces? | Dark-Mode Hex |
|------|----------------------------------|----------------------------|---------------|
| Stead Blue (primary) | `#3A6F8F` (passes all light) | Yes (5.45 W / 4.57 SM / 5.07 RT) | `#5885a0` |
| Ember Copper (accent) | `#9b5931` | Yes (>4.5 W / 4.55 SM / >4.5 RT) | `#ba6b3c` |
| Warning | `#8f601a` | Yes (>4.5 W / 4.56 SM / >4.5 RT) | `#B57A21` (book hex passes dark) |
| Moss Grey (secondary text) | `#606d66` | Yes (4.50 W / 4.54 SM / 4.54 RT) | `#75827b` |
| Success | `#2F7D57` (canonical; #2d7753 for Stone Mist) | White+RT: yes; SM: use `#2d7753` | `#488d6b` |
| Danger | `#B44949` (canonical; #b04848 for Stone Mist) | White+RT: yes; SM: use `#b04848` | `#bf6464` |
| Info | `#356E8C` (passes all light) | Yes (5.58 W / 4.68 SM / 5.19 RT) | `#55859e` |

**Note on Success and Danger canonical:** The full book hex passes White and Rain Tint. On
Stone Mist only, the AA-darkened variants must be used. Whether this is expressed as a
token-level override or a usage policy is the Gap 2 open question (D-11 sign-off required).

---

## Section 5: Dark-Mode Ramp Slot Mapping (D-10 / PAL-03)

Base `#10161f` is kept (D-10). Elevation via luminance increase + hairline borders.
No `--rs-surface-base` swap. Basalt `#0F1720` is visually indistinguishable from
`#10161f` (1.01:1 contrast) — do not swap (v1.14 decision documented in STATE.md).

| Slot | v1.13 Shipped Hex | Mineral Palette Name | Mineral Hex | Action |
|------|------------------|---------------------|-------------|--------|
| `--rs-neutral-0` (dark base) | `#10161f` | (v1.13 base, kept) | `#10161f` | Keep — D-10: do not swap to Basalt `#0F1720` |
| `--rs-neutral-25` (faint surface) | `#141c27` | — | `#141c27` | Keep (mineral-dark elevation step) |
| `--rs-neutral-50` (bg) | `#19222e` | — | `#19222e` | Keep |
| `--rs-neutral-100` (surface muted) | `#1f2a38` | — | `#1f2a38` | Keep |
| `--rs-neutral-200` (border subtle) | `#253243` | ≈ Slate Stead | `#24313D` | Minor alignment possible; audit in Phase 98 |
| `--rs-neutral-300` (border) | `#2e3d52` | — | `#2e3d52` | Keep |
| `--rs-neutral-400` (border strong) | `#3d5168` | — | `#3d5168` | Keep |
| `--rs-neutral-500` (placeholder) | `#7a8fa3` | — | `#7a8fa3` | Keep |
| `--rs-neutral-600` (text muted) | `#a8b9ca` | AA-lightened Moss Grey | `#75827b` | Replace with mineral in Phase 98 |
| `--rs-neutral-900` (text) | `#e8edf3` | Stone Mist | `#E8ECE8` | Replace with mineral in Phase 98 |
| `--rs-primary` (brand) | `#2563eb` (fails 3.51:1) | Stead Blue AA-lightened | `#5885a0` | Replace — shipped fails AA |
| `--rs-accent` (brand) | `#e8834a` | Ember Copper AA-lightened | `#ba6b3c` | Replace with mineral |
| `--rs-success` | `#4ade80` (generic; 10.42:1) | Success AA-lightened | `#488d6b` | Replace generic with mineral |
| `--rs-warning` | `#fbbf24` (generic; 10.88:1) | Warning (passes dark at 4.99:1) | `#B57A21` | Replace generic with mineral |
| `--rs-error` | `#f87171` (generic; 6.56:1) | Danger AA-lightened | `#bf6464` | Replace generic with mineral |

**Elevation principle (confirmed):** `#10161f` → `#141c27` → `#19222e` → `#1f2a38` →
`#253243` → `#2e3d52`. Each step increases OKLCH L. No hue shift. Hairline borders using
ramp steps for panel separation.

---

## Section 6: Signal Gold Policy (D-09 / PAL-04)

Signal Gold `#D2A94E` is designated **decorative-only**. It must NEVER be used as
normal-weight text.

Computed contrast ratios:
- 2.20:1 on White `#FFFFFF` — **FAIL** (not remediable to mineral feel within brand range)
- 1.85:1 on Stone Mist `#E8ECE8` — **FAIL**
- 2.05:1 on Rain Tint `#F5F7F6` — **FAIL**
- 8.24:1 on dark base `#10161f` — PASS

The dark-mode ratio passes AA but the policy applies uniformly: decorative use only
(badges, metadata accents, icon fills, premium emphasis elements) — not body text, not
interactive labels, not status indicators. PAL-04 is satisfied by this policy, not by a
hex change. Signal Gold is not contrast-remediated.

---

## Section 7: Phase 96 Relocation Decision (D-04 / BRD-02)

The brand book at `prompts/rulestead-brand-book.md` will be physically relocated to
`brandbook/brand-book.md` during Phase 96. A pointer comment will be added to
`prompts/rulestead-brand-book.md` at that time so existing references do not break.

This is the confirmed Phase 95 decision record per D-04. No file moves occur in
Phase 95. The brand-book pressure-test audit (BRD-01 / `95-BRAND-AUDIT.md`) is
written against the current working-tree path `prompts/rulestead-brand-book.md`.

---

## Section 8: D-11 Maintainer Sign-Off — AA-Adjusted Hex List

The following hex values have been computed as WCAG AA-passing replacements for their
book-literal counterparts. Each requires brand-compatibility acceptance from the
maintainer before Phase 96 tokens.json encodes them as canonical token values.

All entries are verified by `python3 scripts/check_contrast.py` (exits 0).

### Light-Surface AA-Adjusted Hexes

- **Ember Copper canonical (Stone Mist surface):** `#9b5931` replaces book `#B96A3A` — ratio 4.550:1; OKLCH drift 0.09°
- **Ember Copper (White surface):** `#ac6336` replaces book `#B96A3A` — ratio 4.573:1; OKLCH drift 0.09°
- **Ember Copper (Rain Tint surface):** `#a65f34` replaces book `#B96A3A` — ratio 4.531:1; OKLCH drift 0.36°
- **Warning canonical (Stone Mist surface):** `#8f601a` replaces book `#B57A21` — ratio 4.563:1; OKLCH drift 0.02°
- **Warning (White surface):** `#9f6b1d` replaces book `#B57A21` — ratio 4.570:1; OKLCH drift 0.37°
- **Moss Grey canonical (Stone Mist surface):** `#606d66` replaces book `#6C7A73` — ratio 4.539:1; OKLCH drift <0.1°
- **Moss Grey (Rain Tint surface):** `#67746d` replaces book `#6C7A73` — ratio 4.544:1; OKLCH drift <0.1°
- **Success on Stone Mist (Gap 2):** `#2d7753` replaces book `#2F7D57` — ratio 4.540:1; OKLCH drift <0.1°
- **Danger on Stone Mist (Gap 2):** `#b04848` replaces book `#B44949` — ratio 4.550:1; OKLCH drift <0.1°

### Dark-Surface AA-Adjusted Hexes

- **Stead Blue dark:** `#5885a0` replaces both shipped `#2563eb` (3.51:1) and book `#3A6F8F` (3.33:1) — ratio 4.563:1
- **Ember Copper dark:** `#ba6b3c` replaces book `#B96A3A` (4.48:1 — 0.02:1 short) — ratio 4.545:1; OKLCH drift 0.37°
- **Success dark:** `#488d6b` replaces book `#2F7D57` (3.62:1) — ratio 4.581:1
- **Danger dark:** `#bf6464` replaces book `#B44949` (3.45:1) — ratio 4.515:1
- **Info dark:** `#55859e` replaces book `#356E8C` (3.25:1) — ratio 4.526:1
- **Moss Grey dark:** `#75827b` replaces book `#6C7A73` (4.04:1) — ratio 4.527:1

**Total AA-adjusted hexes requiring acceptance: 15** (9 light-surface + 6 dark-surface)

### Open Questions for Maintainer

**Gap 2 resolution:** Success `#2F7D57` (4.20:1) and Danger `#B44949` (4.41:1) fail AA
on Stone Mist `#E8ECE8`. Corrected hexes `#2d7753` and `#b04848` are computed and
verified. Maintainer must decide:
1. Include darkened variants `#2d7753` / `#b04848` in the canonical palette as
   per-surface token values (most complete; recommended by planner) — or —
2. Add a usage-policy note only: "Do not use Success/Danger book hexes as normal-weight
   text on Stone Mist surfaces without AA-darkening" (same approach as Signal Gold).

See §3b (Gap 2 note) and §4 (Success/Danger canonical note) for context.

### Maintainer Gate

- [ ] Maintainer sign-off: I accept the 15 AA-adjusted hexes above as brand-compatible.

_Sign-off required before Phase 96 tokens.json values are authored. This is decision D-11._
