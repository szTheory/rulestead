# Phase 95: Brand-Book Pressure-Test Audit

**Status:** Complete (Phase 95 deliverable)
**Authored:** 2026-06-04
**Requirement:** BRD-01 (pressure-test audit + scorecard)
**Source:** `prompts/rulestead-brand-book.md` (working-tree state, 27 sections)

---

## Section 1: Purpose

Phase 95 pressure-test audit of `prompts/rulestead-brand-book.md` (27 sections).

**Rating framework:**

| Rating | Meaning |
|--------|---------|
| KEEP | Strong, ship as-is — no changes needed for Phase 96 |
| TIGHTEN | Good content, minor gap to close — specific action named |
| REWORK | Structural issue that blocks downstream use — must be resolved in Phase 96 |
| ADD | Missing content needed for completeness — new section or item required |
| REMOVE | Counterproductive or contradictory — remove in Phase 96 |

Audit conducted against the working-tree brand book at `prompts/rulestead-brand-book.md`.
Physical relocation to `brandbook/brand-book.md` occurs in Phase 96 per D-04.

---

## Section 2: Rating Table

| # | Section Title | Rating | Rationale |
|---|---------------|--------|-----------|
| 1 | Brand foundation | KEEP | Name meaning, category, and why-it-works narrative are precise, differentiated, and infrastructure-grade; no gaps. |
| 2 | Brand strategy | KEEP | Purpose, mission, vision, promise, and positioning are well-reasoned, BEAM-native, and operationally honest. |
| 3 | Brand essence | KEEP | Architect+Steward archetype blend is ownable; personality traits are calibrated and non-generic; emotional territory is actionable. |
| 4 | Product narrative | KEEP | Problem narrative is ops-aware; the Rulestead answer section is concrete; north-star message is memorable. |
| 5 | Audience | KEEP | Primary/secondary/tertiary breakdown with care-abouts is practical and maps directly to Elixir ecosystem segments. |
| 6 | Differentiation | KEEP | Core differentiators are explicit; the not-list and competitive language frame give clear negative space. |
| 7 | Messaging architecture | KEEP | One-liner, short/medium/long pitches, and messaging pillars are solid and consistent with brand essence. |
| 8 | Tagline directions | TIGHTEN | Multiple options present; "Runtime decisions, made clear." is the recommended selection. Lock the chosen tagline in Phase 96 and remove the options list from the shipped brand book. |
| 9 | Verbal identity | KEEP | Voice principles, profile scores, tone-by-context breakdown, and do/don't examples are practical and well-calibrated. |
| 10 | Naming conventions | KEEP | Preferred vocabulary, mental model framing, and contrast language enforce precise product vocabulary. |
| 11 | Visual identity overview | TIGHTEN | Strong concept and metaphor territory; A/B/C concept names are present but SVGs not yet rendered. TIGHTEN in Phase 97 (logo SVGs produced) with Phase 96 confirming concept names. |
| 12 | Color system | REWORK | Book-literal hexes contain AA failures: Ember Copper `#B96A3A` fails on all light surfaces (4.05:1 on white); Warning `#B57A21` fails on all light surfaces (3.64:1 on white); Moss Grey `#6C7A73` fails on Stone Mist and Rain Tint; Success `#2F7D57` and Danger `#B44949` fail on Stone Mist. Dark-mode: Stead Blue, Success, Danger, Info, and Moss Grey all fail on `#10161f`. Additionally, shipped CSS diverges from the mineral palette (`--rs-primary: #2563eb` generic blue, not Stead Blue). REWORK in Phase 96: replace all book-literal hex values with AA-verified values from `95-PALETTE-RECONCILIATION.md`. |
| 13 | Typography | KEEP | Sora/Inter/IBM Plex Mono is well-justified; hierarchy rules are actionable; CDN-only policy confirmed compatible with v1.14 font policy. |
| 14 | Logo direction | TIGHTEN | Strategy and A/B/C symbol directions are solid; wordmark guidance is clear. TIGHTEN in Phase 97: produce SVGs and trigger concept-selection checkpoint before finalizing. |
| 15 | Layout system | TIGHTEN | Strong grid, whitespace, shape language, border-radius, and shadow guidance. Slightly abstract without visual specimens. TIGHTEN in Phase 99: add layout specimens to make guidance concrete. |
| 16 | Iconography | TIGHTEN | Adequate style guidance and icon-theme list; no icon set delivered yet. BRD-04 (full custom icon library) is a deferred v2 item per REQUIREMENTS.md. Note this boundary explicitly in Phase 96. |
| 17 | Imagery | KEEP | Strong negative-space guidance; photography and illustration directions are specific; the never-use list is actionable. |
| 18 | Motion | TIGHTEN | Strong motion character and principles; good/bad pattern examples are useful. No concrete duration or easing values. Shipped CSS has `--rs-motion-fast: 150ms ease`, `--rs-motion-base: 220ms ease`, `--rs-motion-slow: 380ms ease`. Add these values to §18 in Phase 96 (see ADD-3). |
| 19 | UI writing standards | KEEP | Concrete verb guidance for buttons, empty states, errors, warnings, and success states — actionable and consistent with brand voice. |
| 20 | Documentation style | KEEP | Documentation philosophy, language preferences, and code-example guidance are production-capable and differentiated. |
| 21 | Open-source posture | KEEP | Brand behavior in OSS, maintainer tone, and community tone are well-differentiated for a serious BEAM-ecosystem library. |
| 22 | Content pillars | KEEP | Five pillars map to the product thesis; each is distinct and covers a real communication surface. |
| 23 | Copy examples | TIGHTEN | Good base of homepage hero options, explainer lines, and docs intro. szTheory suite brand-architecture note missing (ADD-2, BRD-03, Phase 100). Add cross-reference to suite note when Phase 100 delivers it. |
| 24 | Brand guardrails | KEEP | Never-position list, always-reinforce list, and forced-choice direction give clear negative constraints. |
| 25 | Practical implementation defaults | TIGHTEN | Good summary of default stack, interface styling, and illustration style. Color defaults (Stead Blue, Ember Copper, Stone Mist, Basalt) must be updated to AA-verified hexes from `95-PALETTE-RECONCILIATION.md` after Phase 96 palette lock (references §12 REWORK). |
| 26 | Internal LLM/design context summary | TIGHTEN | Useful compact brand statement for AI and design handoffs. Hex values and palette description should be updated after palette lock in Phase 96 to reflect the AA-verified mineral values. |
| 27 | Final brand mantra | KEEP | "Rulestead makes change feel governed, not chaotic." is memorable, aligned with brand essence, and suitable as a permanent closing statement. |

---

## Section 3: ADD Items

### ADD-1: Accessibility Section (Phase 96 target)

The brand book has no dedicated section on WCAG compliance, forced-colors/high-contrast
mode, or keyboard navigation principles. A brief accessibility policy section must be
added to `brandbook/brand-book.md` in Phase 96, with the following content:

- Reference the AA-verified palette from Phase 95 (`95-PALETTE-RECONCILIATION.md`) as
  the accessibility foundation.
- State that all text and interactive elements use AA-verified hexes (normal text ≥4.5:1;
  large text ≥3:1 per WCAG 2.1 §1.4.3).
- Note that A11Y-04 (forced-colors / high-contrast mode) is a deferred v2 item per
  REQUIREMENTS.md and is out of scope for v1.14.
- Note that keyboard navigation and focus-ring visibility are part of the admin UI token
  system (`--rs-focus-ring-color`), not a brand-book concern — cross-reference the CSS.

### ADD-2: szTheory Suite Brand-Architecture Note (BRD-03 — Phase 100 deliverable, scoped here)

Rulestead's relationship to sibling libraries (Parapet, Scoria, Cairnloop) is not defined
in the brand book. This note must define shared vs. unique brand attributes across the
szTheory suite.

**Phase 95 scope:** Flag the gap and provide the content outline below.
**Phase 100 scope:** Author the full note and integrate it into `brandbook/brand-book.md`.
This is the explicit scope boundary per REQUIREMENTS.md BRD-03.

**Content outline for Phase 100 execution:**

*Shared across the szTheory suite:*
- Voice principles: calm, rigorous, confident without swagger
- BEAM-native positioning and Elixir-first ergonomics
- Open-source posture: opinionated, transparent, production-minded
- Architect+Steward archetype territory
- Mineral neutral palette as a foundation (each library may use different brand accent colors)

*Unique to Rulestead:*
- Feature-management + experimentation domain
- Runtime evaluator positioning (deterministic, explainable, local)
- Admin UI companion (`rulestead_admin`) and operator-facing control plane
- Operational safety and SRE-trust narrative
- Mineral palette with Stead Blue primary + Ember Copper accent
- "Runtime decisions, made clear." tagline

*Distinguishing line:*
> "Rulestead is the rule-evaluation runtime. Parapet is the boundary enforcement layer.
> Scoria is the audit surface. Cairnloop is the feedback loop."

### ADD-3: Concrete Motion Timing Reference (Phase 96 target)

Section 18 Motion specifies principles without concrete duration or easing values. The
shipped CSS (`rulestead_admin.css`) provides these values:

```
--rs-motion-fast:   150ms ease
--rs-motion-base:   220ms ease
--rs-motion-slow:   380ms ease
```

Add these concrete values to §18 in `brandbook/brand-book.md` during Phase 96, alongside
the existing principles and pattern guidance. This closes the gap between the brand-book
motion policy and the live CSS implementation.

---

## Section 4: Overall Scorecard

| Rating | Count | Sections |
|--------|-------|---------|
| KEEP   | 17    | 1, 2, 3, 4, 5, 6, 7, 9, 10, 13, 17, 19, 20, 21, 22, 24, 27 |
| TIGHTEN | 8   | 8, 11, 14, 15, 16, 18, 23, 25, 26 |
| REWORK  | 1   | 12 |
| ADD     | 3   | ADD-1 (Accessibility), ADD-2 (szTheory suite), ADD-3 (Motion timing) |
| REMOVE  | 0   | — |

**Total sections rated:** 27 (plus 3 ADD items)
**Primary risk area:** §12 Color system (REWORK — blocks Phase 98 re-skin if not resolved in Phase 96)
**Phase 100 dependency:** ADD-2 szTheory suite note (BRD-03)

---

## Section 5: Priority Recommendations for Phase 96

The following items must be resolved in Phase 96 (brand-book reconciliation) for the
downstream phases (97–100) to proceed cleanly:

1. **REWORK §12 Color system:** Replace all book-literal hex values with AA-verified hexes
   from `95-PALETTE-RECONCILIATION.md`. This is the blocking item for Phase 98 (admin
   CSS re-skin) and Phase 97 (logo SVG fill colors). Do not proceed to Phase 98 without
   §12 reflecting the locked AA palette.

2. **ADD-1 Accessibility section:** Add a brief WCAG policy section to
   `brandbook/brand-book.md`. Reference the AA-verified palette, state the AA ≥4.5:1
   requirement for normal-weight text, and note A11Y-04 as deferred v2.

3. **TIGHTEN §8 Tagline:** Lock the tagline to "Runtime decisions, made clear." Remove
   the other options from the shipped brand book. Update §23 Copy examples and §26
   Internal summary to reference the locked tagline.

4. **ADD-3 Motion timing:** Add `--rs-motion-fast: 150ms ease`, `--rs-motion-base: 220ms ease`,
   `--rs-motion-slow: 380ms ease` to §18 Motion.

5. **TIGHTEN §25/§26:** Update color defaults in §25 and the palette description in §26
   to reflect AA-verified hexes after the §12 palette lock.

**Deferred to Phase 100:** szTheory suite brand-architecture note (ADD-2, BRD-03).
Phase 95 provides the content outline above; the full note is authored in Phase 100
after all prior brand system phases are complete.

---

*Consuming phases:*
- **Phase 96:** Acts on all REWORK, TIGHTEN, and ADD-1/ADD-3 items above to produce `brandbook/brand-book.md`
- **Phase 97:** References §11 Visual identity (logo A/B/C directions) and §12 AA-verified hexes for SVG fills
- **Phase 98:** References §12 AA-verified hexes for admin CSS re-skin
- **Phase 99:** References §15 Layout system for specimens
- **Phase 100:** Delivers ADD-2 szTheory suite note (BRD-03)
