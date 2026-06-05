# Rulestead Mark — Concept Review (Phase 97-01)

**Status:** Awaiting maintainer selection
**Gate:** Phase 97-02 is blocked until one concept is selected
**Instruction:** Reply with a single letter — **A**, **B**, or **C** — to select the concept that will become the canonical Rulestead mark.

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

## Selection

**Please reply with: A, B, or C**
