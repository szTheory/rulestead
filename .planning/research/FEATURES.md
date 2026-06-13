# Feature Research: Rulestead v1.14 — Brand System Artifacts

**Domain:** OSS devtool brand-system collateral for a repo-committed `brandbook/`
**Researched:** 2026-06-04
**Confidence:** HIGH for table-stakes/anti-features (grounded in Oban, Phoenix, Livebook, Astro, Tailwind, Bun examples); MEDIUM for complexity estimates (repo-specific variables apply)

---

## Framing

"Features" here are brand-system artifacts: concrete files, copy, or surfaces that a credible
Elixir/OSS devtool ships. The milestone goal is a self-contained `brandbook/` plus admin re-skin.
The question for each artifact is: does it earn its place in the repo, or is it ego bloat?

Existing assets already locked (do NOT re-do in this milestone):
- Strategy/positioning/voice/messaging (brand book §1–10, 21–24, 26–27)
- Font choices (Sora/Inter/IBM Plex Mono)
- Shipped admin design system (v1.13) — token shape, spacing, radius, cascade

---

## Feature Landscape

### Table Stakes (Users Expect These)

Missing any of these leaves the brand incomplete and blocks downstream surfaces
(landing page, README, Hex.pm, HexDocs, social sharing).

| Artifact | Why Expected | Complexity | Notes |
|----------|--------------|------------|-------|
| **Logo/mark SVG — primary lockup (wordmark + mark)** | Every credible OSS devtool has a primary SVG lockup. Oban ships `assets/oban-logotype-light.png`; Bun has a logo in every README hero; Astro ships primary/gradient/mono variants. Without this nothing else can be assembled. | HIGH (design work) | Three concept directions (A/B/C path/frame/layer) already spec'd in brand book §14. User picks one direction; one round of refinement. |
| **Icon/mark SVG (standalone, no wordmark)** | Needed for favicon, social card, tiny contexts (32px, 16px). Inseparable from the logo set; always produced together. | LOW (derivative of primary) | Extract mark from primary lockup SVG; path-optimize for small sizes. |
| **Monochrome variant (single-color, on-dark + on-light)** | Required for contexts where color is unavailable: README on dark backgrounds, HexDocs sidebar, print, embossed. Astro ships monochrome. Oban ships a light logotype specifically for dark backgrounds. | LOW (derivative) | SVG `currentColor` fill or single-path; no new design work. |
| **Favicon set (`.ico` + `32x32.png` + `apple-touch-icon`)** | Required by any landing page or HexDocs custom theme. Missing favicon signals unfinished project. | LOW | Generated from mark SVG via tooling; commit PNGs alongside SVG source. |
| **Social preview card — static 1280×640 PNG** | GitHub repository Settings > Social preview requires a raster image at ≥640×320px (1280×640 optimal). Every top Elixir project (Oban, Livebook) has one set. Shared on Twitter/X, LinkedIn, Slack when someone pastes the repo URL. | MEDIUM | Design as SVG template (logo + tagline + palette), export PNG; commit both. GitHub requires raster; keep SVG source for re-export. |
| **Machine-readable design tokens — `tokens.json`** | Admin v1.13 already ships `--rs-*` CSS custom properties. A JSON token file makes the palette canonical and tooling-friendly. Downstream: CSS gen, specimen SVGs, re-skin verification. This is the single source of truth that the CI sync guard needs. | LOW | Mirror existing `--rs-*` token shape; add semantic + state roles from brand book §12. No net-new design decisions. |
| **CSS token file — `tokens.css`** | The re-skin CI guard (`check_synced_pair.py`) needs both packages in sync. A committed `tokens.css` in `brandbook/` becomes the reference that the admin CSS is verified against. | LOW (derived from tokens.json) | Build step or trivially hand-authored from tokens.json. |
| **Palette specimen SVG** | Needed to verify the brand book mineral palette against the shipped `#2563eb`/`#9a3f12` admin colors. Functions as a regression reference and a visual README asset. Real projects (Tailwind, Astro) publish color swatches on brand/press pages; for a library this is the repo-committed equivalent. | LOW | Single SVG with color swatches, hex values, names (Basalt, Stead Blue, Ember Copper, etc.). |
| **README hero image** | Logo in the README `<img>` tag is table stakes for any OSS library aiming to be taken seriously. Oban does it; Livebook does it; Bun's whole README opens with it. Without a README hero the project looks unfinished on GitHub and Hex.pm. | LOW | Wordmark on transparent or Rain Tint background, width-constrained SVG or PNG. |
| **Hex.pm package description (`:description` field in `mix.exs`)** | The `:description` value is what appears verbatim on hex.pm search results and the package page. Phoenix's is "Peace of mind from prototype to production." Oban's is "Robust job processing, backed by modern PostgreSQL, SQLite3, and MySQL." Searches use this text. Wrong, stale, or generic copy hurts discoverability. | LOW | One tight sentence; already drafted in brand book §7 one-liner. Needs final commit to `mix.exs`. |
| **HexDocs intro paragraph** | The first paragraph rendered in HexDocs module `@moduledoc` (typically the README or `Rulestead` module doc) is what every adopter reads first. Phoenix and Oban both open with a positioning sentence, then feature bullets. Missing or generic text signals an unprofessional library. | LOW | Copy from brand book §23 "Docs intro example"; verify it's the opening of `Rulestead` module doc. |

---

### Differentiators (Competitive Advantage)

These separate "has a logo" from "has a real brand system." Not required for any single surface
to work, but collectively make the project look like it was built by people who care.

| Artifact | Value Proposition | Complexity | Notes |
|----------|-------------------|------------|-------|
| **Typography specimen SVG** | Shows the Sora/Inter/IBM Plex Mono hierarchy in action: H1, H2, body, code label. Serves as a reference for anyone building landing page, blog, or docs theme. Well-branded devtools (Tailwind has a brand page; Pendo has a typography page) document this. For a library, a committed SVG is the lean equivalent. | LOW | One SVG, three typefaces, five scale levels. Google Fonts CDN-linked for web use is acceptable. |
| **UI component specimen SVG** | Shows a brand-accurate button, badge, input, and tag in both light and dark. Gives landing page builders or blog post authors accurate visual reference. Oban's docs show a consistent UI aesthetic because they went through the deliberate token work—a specimen makes that implicit work explicit and reusable. | MEDIUM | Draw from the shipped admin component CSS. One SVG per theme. Worth doing because admin re-skin is happening anyway. |
| **Code-block / terminal styling specimen** | IBM Plex Mono + mineral palette applied to a realistic `iex>` or `mix` snippet. Establishes the "how code looks in Rulestead marketing" standard. Livebook, Elixir-lang, and Phoenix all have distinctive code block treatments. Without a committed specimen every blog post or landing page reinvents this. | LOW | One SVG or HTML/CSS snippet. Basalt background, Stead Blue for keywords, Ember Copper for strings is a natural derivation. |
| **Voice/microcopy do-this/not-this reference** | A one-page committed `brandbook/VOICE.md` with 8–12 concrete examples (good/bad pairs from brand book §9, §19). Prevents drift as contributors write docs, release notes, admin UI copy, and issue responses. GitLab's doc style guide does this at scale; for an OSS library a concise committed file does the same job. | LOW | Distill brand book §9 and §19 into ~2 pages of concrete pairs. Not a "style guide PDF." |
| **Release announcement copy template** | A short committed `brandbook/RELEASE-TEMPLATE.md` with the scaffolding: opener, feature headlines, operator impact sentence, upgrade note, changelog link. Elixir's own release posts (e.g., v1.18 announcement) follow a consistent structure: context, feature sections, code examples, contributor acknowledgment. Having a template means every Rulestead release sounds like Rulestead. | LOW | One file, ~20 lines of scaffold. Grounded in brand book voice principles. |
| **GitHub repo description + topics** | The `About` field in GitHub repo settings (shown in search results and on the repo page) is frequently overlooked. "Elixir-native feature management and experimentation" with topics `elixir`, `phoenix`, `feature-flags`, `remote-config`, `hex` surfaces the project correctly in GitHub search and ecosystem directories. Not a committed file, but a deliberate brand act. | TRIVIAL | Edit in GitHub UI; document the chosen description + topic set in `brandbook/README.md`. |
| **Admin re-skin to mineral palette** | This is the most impactful brand artifact because it's what every adopter sees when they mount the admin. Replacing the shipped `#2563eb`/`#9a3f12` with the brand-book mineral palette (Stead Blue `#3A6F8F`, Ember Copper `#B96A3A`) makes the admin and the brand book coherent. CI-gated via `check_synced_pair.py`. | MEDIUM | Colors-only cascade change across 4 CSS blocks; WCAG-AA both themes; gated by sync guard and fixture. |
| **Repo size budget + token-sync CI guard** | Commits a `brandbook/BUDGET.md` (max sizes per file type) and a CI step that fails if `brandbook/tokens.json` diverges from `rulestead_admin` CSS custom properties. Prevents brand drift silently accumulating. No comparable OSS Elixir project does this explicitly, which is a differentiator in operational discipline. | LOW | `check_synced_pair.py` already exists for v1.13; extend scope to tokens.json. |

---

### Anti-Features (Bloat to Avoid)

These are commonly produced, almost never used, and add repo weight, maintenance debt,
or false signal of completeness.

| Artifact | Why Requested | Why It's Bloat | What to Do Instead |
|----------|---------------|----------------|-------------------|
| **PDF brand book / style guide PDF** | Looks professional; corporate brand teams always ship one. | A PDF committed to a git repo is a binary blob that can't be diffed, searched, or linked to specifically. It rots immediately after the first token change. No OSS devtool with a healthy brand ships one. Tailwind's brand page is HTML. Astro's is a web page. | Keep everything in `brandbook/*.md` and `*.svg`. Living markdown + SVGs are the brand book. |
| **Figma file as primary source of truth** | Designers work in Figma. | Figma is not source-controllable, not accessible to contributors without an account, and creates a private dependency for a public OSS brand. The brand system breaks when the Figma file is abandoned (and it always is). | Figma is a design tool for the creation process; SVGs and JSON are the outputs. Commit outputs. |
| **Animated logo / Lottie / video intro** | Adds polish; modern brands do motion identity. | OSS libraries are consumed in README views, Hex.pm, docs, and blog posts — not a website hero where a 3-second animation plays. Weight, accessibility issues, and maintenance cost are not worth the tiny % of surfaces where animation could play. | Ship static SVG. If a landing page is built later, add motion then as a website-only asset. |
| **Full icon library / icon set** | Brand cohesion across all icons. | The admin already uses an icon pattern (Heroicons or equivalent). Creating a custom Rulestead icon set requires sustained maintenance, adds thousands of SVG nodes to the repo, and is out of scope for an OSS library brand. | Document the icon style (outlined, geometric, 1.5px stroke) in `brandbook/VOICE.md` and use the existing admin icon pattern. |
| **Mascot / character design** | Gives brand personality; Elixir has the logo, Livebook has "Kino." | Mascots require consistent execution across ALL contexts (social, docs, marketing, merch). Without a dedicated designer maintaining the character, it degrades quickly. Rulestead's archetype (Architect + Steward) is deliberately non-mascot; a mascot would conflict with the "infrastructure-grade" positioning. | The brand's "character" is expressed through voice and palette, not a cartoon. |
| **Social media template kit (Canva/Figma templates)** | Enables anyone to make on-brand posts. | For an OSS library, social posts are rare and written by the maintainer. A Canva template never gets used; a Figma template needs a Figma account. | A committed 1280×640 SVG template with locked-down palette is sufficient. Export manually as needed. |
| **Dark mode landing page hero video** | Looks like Vercel or Linear. | Rulestead has no landing page yet. Producing video assets for a nonexistent page is premature. | Build a static landing page (future milestone); add motion then if warranted. |
| **Sticker / merchandise designs** | Community-building; gives contributors something to share. | Requires print vendor integration, ongoing inventory, and creates implicit brand obligations. Zero leverage for an early-stage OSS library. | If demand materializes after meaningful adoption, revisit. Do not produce speculatively. |
| **Accessibility statement PDF / formal VPAT** | Enterprise procurement often requires VPATs. | Rulestead is an OSS library, not an enterprise SaaS product. A committed `brandbook/ACCESSIBILITY.md` or section in HexDocs stating the WCAG-AA guarantee and what it covers is sufficient and honest. A formal VPAT is a procurement document that creates liability implications not warranted at this stage. | Add a brief `ACCESSIBILITY.md` noting the v1.13 WCAG-AA contract for the mounted admin; link from HexDocs. |
| **Brand guidelines "for partners" / co-branding guide** | Real brand systems have usage policies. | Rulestead has no commercial partnerships. A trademark usage policy is needed only when there are third parties building on the brand. | Add a one-paragraph usage note in `brandbook/README.md`: "Use the wordmark to link to the project. Do not embed it in your own brand or product name." |
| **Standalone documentation site (Mintlify, Docusaurus)** | Livebook has livebook.dev; Phoenix has phoenixframework.org. | HexDocs is the canonical home for Elixir library docs. A parallel docs site creates split-authority drift and maintenance overhead. The v1.14 milestone is about the brand system, not a website. | HexDocs + a well-structured README is the correct surface. A landing page is a future milestone if adoption justifies it. |

---

## Feature Dependencies

```
tokens.json
    └──derives──> tokens.css
    └──derives──> palette specimen SVG
    └──gates──> admin re-skin (check_synced_pair.py must validate)

Logo SVG (primary lockup)
    └──derives──> icon/mark SVG
                      └──derives──> favicon set
                      └──used-in──> social preview card
    └──used-in──> README hero
    └──used-in──> social preview card

voice/microcopy guide
    └──informs──> Hex.pm description
    └──informs──> HexDocs intro paragraph
    └──informs──> release announcement template

admin re-skin
    └──requires──> tokens.css (sync guard)
    └──requires──> WCAG-AA both themes verified
    └──requires──> design-system fixture passing
```

### Dependency Notes

- **tokens.json must exist before admin re-skin**: The CI sync guard verifies admin CSS against tokens.json. Tokens come first.
- **Logo primary lockup before all derivatives**: Mark, favicon, social card, and README hero all derive from the primary SVG. Cannot be parallelized with logo design.
- **Voice guide informs copy, not vice versa**: Hex.pm description and HexDocs intro should be written/reviewed against the voice guide to prevent drift at first commit.
- **admin re-skin is tokens-dependent but design-independent**: The re-skin work does not block on logo finalization. It only requires tokens.json and tokens.css to be canonical.

---

## MVP Definition (v1.14 Launch With)

Minimum artifact set that produces a coherent, credible brand presence across all active
surfaces (GitHub, Hex.pm, HexDocs, admin UI).

### Phase 95–96: Token + Palette Foundation
- [x] Pressure-test brand-book palette vs. shipped admin colors; pick winners
- [ ] `brandbook/tokens.json` — canonical mineral palette, semantic roles
- [ ] `brandbook/tokens.css` — CSS custom property output
- [ ] `brandbook/specimens/palette.svg` — color swatch reference

### Phase 97: Logo System
- [ ] Logo concept A/B/C SVG explorations (paths/layers/topology; no phoenix/flag/shield)
- [ ] User selection; final primary lockup SVG
- [ ] `brandbook/logo/rulestead-primary.svg`
- [ ] `brandbook/logo/rulestead-mark.svg` (standalone icon)
- [ ] `brandbook/logo/rulestead-mono-dark.svg` and `rulestead-mono-light.svg`
- [ ] `brandbook/logo/favicon/` — .ico, 32x32.png, apple-touch-icon.png

### Phase 98: Specimens + Copy Surfaces
- [ ] `brandbook/specimens/typography.svg`
- [ ] `brandbook/specimens/code-block.svg`
- [ ] `brandbook/specimens/ui-components-light.svg` and `ui-components-dark.svg`
- [ ] `brandbook/specimens/social-card.svg` + exported `social-card-1280x640.png`
- [ ] `brandbook/VOICE.md` — do-this/not-this guide (distilled from brand book §9, §19)
- [ ] `brandbook/RELEASE-TEMPLATE.md`
- [ ] `rulestead/mix.exs` `:description` updated; `rulestead_admin/mix.exs` `:description` updated
- [ ] `Rulestead` module `@moduledoc` opening paragraph verified against voice guide

### Phase 99: Admin Re-skin
- [ ] `rulestead_admin/priv/static/css/rulestead_admin.css` — mineral palette across all 4 cascade blocks
- [ ] WCAG-AA both themes passing
- [ ] `check_synced_pair.py` scope extended to tokens.json
- [ ] Design-system fixture passing

### Phase 100: Repo Hygiene + Accessibility
- [ ] `brandbook/BUDGET.md` — size limits per file type
- [ ] `brandbook/ACCESSIBILITY.md` — WCAG-AA claim + scope statement
- [ ] `brandbook/README.md` — artifact index, GitHub description/topics to set, usage note
- [ ] README hero updated in both packages

### Add After Validation (v1.x — if landing page milestone opens)
- [ ] Animated SVG elements or CSS motion for website hero
- [ ] Dark mode landing page treatment
- [ ] Social media template kit (only if regular social activity justifies it)

### Defer (v2+ or triggered by adoption)
- [ ] Standalone documentation site (HexDocs is sufficient while adoption is early)
- [ ] Mascot or character design
- [ ] Merchandise designs
- [ ] VPAT / formal accessibility conformance report

---

## Feature Prioritization Matrix

| Artifact | Adopter Value | Implementation Cost | Priority |
|----------|---------------|---------------------|----------|
| tokens.json + tokens.css | HIGH (gates sync CI, admin re-skin) | LOW | P1 |
| Primary logo SVG lockup | HIGH (blocks all other brand surfaces) | HIGH (design work) | P1 |
| Mark/icon SVG | HIGH (favicon, social card, README) | LOW (derivative) | P1 |
| Monochrome variants | MEDIUM (dark-bg README, HexDocs) | LOW | P1 |
| Favicon set | MEDIUM (any future landing page) | LOW | P1 |
| Social preview card 1280×640 PNG | HIGH (every GitHub link share) | MEDIUM | P1 |
| Palette specimen SVG | HIGH (audit gate, visual reference) | LOW | P1 |
| README hero | HIGH (GitHub + Hex.pm first impression) | LOW | P1 |
| Hex.pm `:description` | HIGH (search discoverability) | TRIVIAL | P1 |
| HexDocs intro paragraph | HIGH (every adopter reads this first) | TRIVIAL | P1 |
| Admin re-skin (mineral palette) | HIGH (most-seen brand surface) | MEDIUM | P1 |
| Typography specimen SVG | MEDIUM (landing page reference) | LOW | P2 |
| Code-block specimen SVG | MEDIUM (consistent marketing copy) | LOW | P2 |
| UI component specimens | MEDIUM (admin re-skin reference) | MEDIUM | P2 |
| Voice/microcopy guide | MEDIUM (contributor drift prevention) | LOW | P2 |
| Release announcement template | MEDIUM (consistent voice in releases) | LOW | P2 |
| GitHub repo description + topics | MEDIUM (discoverability) | TRIVIAL | P2 |
| Repo budget + CI sync guard | MEDIUM (operational discipline) | LOW | P2 |
| Accessibility statement | LOW (correctness signal) | LOW | P3 |
| PDF brand book | NONE (anti-feature) | — | DO NOT DO |
| Mascot | NONE at this stage | HIGH | DO NOT DO |
| Icon library | LOW (admin already has icons) | HIGH | DO NOT DO |

**Priority key:**
- P1: Ship in v1.14 — directly unblocks or is a major active surface
- P2: Ship in v1.14 — high value, no blockers, low cost
- P3: Ship if time allows; low regret if deferred
- DO NOT DO: Negative value or blocked by strategy constraint

---

## Reference: How Respected Projects Present Brand

| Project | Logo in README | Social Preview | Favicon | Design Tokens | Voice Guide | Palette Spec | Verdict |
|---------|----------------|---------------|---------|---------------|-------------|--------------|---------|
| **Oban** (Elixir) | Yes — logotype SVG in assets/ | Not visible in repo | Via website | No (website only) | No | No | Minimal but effective |
| **Livebook** (Elixir) | Yes — screenshot + logo | Not explicitly committed | Yes (website) | No (embedded) | No | No | Logo + product screenshot only |
| **Phoenix** (Elixir) | Logo on website; README is text-first | Not in repo | Website only | No | No | No | Text-first; brand on website |
| **Tailwind CSS** | Logo on brand page (mark + logotype + white) | N/A (it's a library) | Yes | Not in repo | No | No | Deliberate; brand page at `/brand` |
| **Astro** | Yes — primary/gradient/mono/logomark variants | Not in repo | Yes | Not in repo | No | No | Full lockup set; press page |
| **Bun** | Yes — logo in README hero | Not visible in repo | Yes (website) | No | No | No | Strong hero, minimal repo brand |

**Pattern:** Every credible project ships a logo in the README. Almost none commit design tokens or voice guides to the repo itself — for an OSS library, these are differentiators, not liabilities. The `brandbook/` approach Rulestead is taking is more systematic than any of these peers.

---

## Sources

- Oban GitHub: https://github.com/oban-bg/oban — logotype in assets/, README structure
- Oban HexDocs: https://oban.hexdocs.pm/Oban.html — logo-anchored intro, feature bullets
- Oban Hex.pm: https://hex.pm/packages/oban — "Robust job processing..." description pattern
- Livebook GitHub: https://github.com/livebook-dev/livebook — screenshot + minimal brand
- Phoenix Hex.pm: https://hex.pm/packages/phoenix — "Peace of mind from prototype to production" tagline
- Tailwind CSS brand: https://tailwindcss.com/brand — mark + logotype + white; trademark rules
- Astro press: https://astro.build/press/ — primary/gradient/mono lockup set; spacing + sizing guidelines
- Bun GitHub: https://github.com/oven-sh/bun — README hero pattern; no dedicated brand dir
- OpenHomeFoundation brand-assets: https://github.com/OpenHomeFoundation/brand-assets — naming conventions, screen/print split
- Elixir v1.18 release announcement: https://elixir-lang.org/blog/2024/12/19/elixir-v1-18-0-released/ — release announcement structure
- Markepear devtool branding: https://www.markepear.dev/blog/branding-developer-tools — brand dimensions, anti-patterns
- GitHub social preview docs: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview — 1280×640 requirement
- Open Source Guides accessibility: https://opensource.guide/accessibility-best-practices-for-your-project/ — ACCESSIBILITY.md pattern

---
*Brand artifact research for: Rulestead v1.14 Brand System Realization*
*Researched: 2026-06-04*
