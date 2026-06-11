# Rulestead Mark — Concept Review (Phase 97-01)

**Status:** ✅ RESOLVED — maintainer selected a derived mark (**G4c**) after an interactive design exploration. Gate is open; Phase 97-02 may proceed.
**Gate:** Phase 97-02 was blocked until one concept was selected.
**Selected mark:** `brandbook/assets/logo/concepts/rs-mark-concept-g4c.svg` (see "Selection Outcome" at the bottom).
**Instruction (original):** Reply with a single letter — **A**, **B**, or **C** — to select the concept that will become the canonical Rulestead mark.

---

## Context

Three mark concepts have been authored per brand book §14. Each is an icon-only mark (no wordmark text) at viewBox `0 0 64 64`, using only the locked mineral palette hexes from `brandbook/tokens.json`. The selected concept will graduate to `brandbook/assets/logo/rs-mark.svg` and form the basis of the full lockup system in Phase 97-02.

**The mark must read clearly at 36px** — the current demo renders `<img src="/images/logo.svg" width="36">` in the app layout. Favor the concept with the strongest visual weight and silhouette at that size.

---

## Concept A — Structured Path Mark

**Brand book §14 name:** Option A: Structured path mark

**File:** `brandbook/assets/logo/concepts/rs-mark-concept-a.svg`

**Metaphor encoded:**
Rule evaluation as a progressive, ordered process. Three horizontal bars decrease in width from top to bottom, connected by a vertical spine on the left. A second shorter spine branches to a terminal block at the lower right — the resolved decision node. The mark reads as a rule tree: entry → evaluation → resolution.

**Design rationale:**
- Ordered, stepped geometry directly references §14's "rule evaluation, decision flow, controlled progression"
- The two-color split (Stead Blue `#3A6F8F` bars + Ink Blue `#183247` spines/terminal) encodes structure vs. outcome
- Asymmetric stepping gives it directionality without becoming an arrow
- Reads as a tree or flowchart fragment at small sizes — strongly infrastructural

**Inline render:**

<img src="../../brandbook/assets/logo/concepts/rs-mark-concept-a.svg" alt="Concept A — Structured path mark" width="128" height="128">

---

## Concept B — Stead Frame

**Brand book §14 name:** Option B: Stead frame

**File:** `brandbook/assets/logo/concepts/rs-mark-concept-b.svg`

**Metaphor encoded:**
A calm rectangular enclosure — the "stead" — holding a single internal governed element. The outer frame (Stead Blue `#3A6F8F`) forms four sides: top bar, bottom bar, left pillar, right pillar. The interior holds a centered horizontal block in Slate Stead `#24313D`, suggesting a rule or operating boundary contained within governed space.

**Design rationale:**
- Architectural containment directly references §14's "stable operating ground, governed system boundaries, clarity and containment"
- The filled-corner frame is a recognizable ownable shape — not a shield, not a generic box
- The inner element anchors the composition and gives visual weight at small sizes
- Calm, minimal — consistent with §11 "stable infrastructure with a human pulse"

**Inline render:**

<img src="../../brandbook/assets/logo/concepts/rs-mark-concept-b.svg" alt="Concept B — Stead frame" width="128" height="128">

---

## Concept C — Layered Field

**Brand book §14 name:** Option C: Layered field

**File:** `brandbook/assets/logo/concepts/rs-mark-concept-c.svg`

**Metaphor encoded:**
Four horizontal bars arranged as a stacked contour field, wider at the bottom and narrowing toward the top. The two foreground layers (Stead Blue `#3A6F8F`) read as active rule environments; the two receding layers (Quarry `#C4CCD1`) suggest depth, prior state, or topology fading into the background. The overall shape reads as a landscape cross-section or layered rule stack.

**Design rationale:**
- Contour stacking directly references §14's "environments, rule layers, snapshots, topology of change"
- The two-tone palette (blue active / grey receding) encodes the depth metaphor without added complexity
- The pyramid-like silhouette creates a strong, ownable shape
- Naturalistic layering gives warmth while remaining geometric and infrastructural

**Inline render:**

<img src="../../brandbook/assets/logo/concepts/rs-mark-concept-c.svg" alt="Concept C — Layered field" width="128" height="128">

---

## Selection Criteria

When choosing, consider:

1. **Small-size legibility at 36px** — which concept retains a clear, distinct silhouette at the demo's current `width="36"` render size?
2. **Brand alignment** — which best encodes the Rulestead brand essence ("stable control over dynamic behavior", structured, governed, calm)?
3. **Ownable shape** — which feels most distinctive and least generic?
4. **Downstream flexibility** — the selected mark will also appear as a favicon (16px legibility), in social card, and in monochrome (`fill="currentColor"`) contexts.

---

## File That Downstream Plans Will Write

After selection, Phase 97-02 will produce the following file from the selected concept:

| File | Role |
|------|------|
| `brandbook/assets/logo/rs-mark.svg` | Icon-only, light — replaces the demo's phoenix-flame `logo.svg` at 36px |
| `brandbook/assets/logo/rs-mark-dark.svg` | Icon-only, dark variant |
| `brandbook/assets/logo/rs-mark-mono.svg` | Monochrome (`fill="currentColor"`) |
| `brandbook/assets/logo/rs-wordmark.svg` | Full lockup: mark + wordmark text as paths |
| `brandbook/assets/logo/rs-wordmark-dark.svg` | Full lockup, dark variant |
| `brandbook/assets/logo/rs-favicon.svg` | 16px-legible favicon |
| `brandbook/assets/logo/rs-social-card.svg` | 1200×630 OG card |

Phase 97-02 is gated on this selection and cannot begin until a letter is provided.

---

## Selection Outcome

The original A/B/C concepts did not land — at real sizes (rendered via a throwaway
`logo-studio.html` decision aid → PNG/PDF, headless Chrome) the maintainer found them
generic; **A was eliminated** outright. Four rounds of interactive iteration followed:

1. **Round 1 (A/B/C):** B carried the feature-flag *concept* (checkbox/toggle) but looked
   generic; C looked good but lacked flag *meaning*. A dropped.
2. **Round 2 (D–I, new directions):** toggles, refined checkbox, decision branch, variant
   stack, gate. Maintainer rejected the UI-control-like marks (D/E/F) as "not distinct brand
   marks" and chose the **decision branch (G)** as the only one that read as a concept, not a
   widget.
3. **Round 3 (G1–G8 form/color):** maintainer settled on the **three-way / multivariate**
   form (G4) as the strongest feature-flag read ("multiple variants, one selected").
4. **Round 4 (G4a–G4h color):** maintainer selected **G4c — lit route**.

### Selected mark: G4c — multivariate decision branch, lit route

- **File:** `brandbook/assets/logo/concepts/rs-mark-concept-g4c.svg`
- **Form:** one input node routes to **three** variant nodes (multivariate). viewBox `0 0 64 64`.
- **Geometry (bold weight):** node radius 6.5, connector thickness 7.5; variant nodes at
  y = 16 / 32 / 48; input at (12,32); junction column at x≈30.
- **Color (lit route):** structure + input + off-arms = **Stead Blue `#3a6f8f`**; the selected
  (top) route's **arm and node = Ember Copper `#9b5931`**; the two off variant nodes =
  **Quarry `#c4ccd1`**.
- **Meaning:** a feature flag evaluating to one of several variants; the chosen route is lit.

### Guidance for Phase 97-02 (full lockup)

- Graduate `rs-mark-concept-g4c.svg` → `brandbook/assets/logo/rs-mark.svg` (light).
- **Dark variant:** structure may use the dark-mode primary `#5885a0`; Quarry off-nodes read
  fine on `#10161f`. Copper active stays `#9b5931`/`#ba6b3c`.
- **Mono / favicon (`rs-mark-mono.svg`, `fill="currentColor"`):** the lit-route distinction is
  *color-based* and collapses in one ink. Use the studio's **G4f** treatment instead — active
  node **filled**, off nodes **hollow** (stroked outline) — so active-vs-off survives with no
  color. Verify legibility at 16px.
- Decision aid + all four rounds are preserved in `logo-studio.html` / `.pdf` /
  `logo-studio-full.png` (throwaway; rendered binaries are git-ignored).

**Selected: G4c** ✅
