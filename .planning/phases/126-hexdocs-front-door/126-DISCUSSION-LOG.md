# Phase 126: HexDocs Front Door - Discussion Log (Assumptions Mode + Gray-Area Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 126-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-18
**Phase:** 126-hexdocs-front-door
**Mode:** assumptions → user requested deep multi-agent gray-area research before locking
**Areas analyzed:** module groups · extras funnel · why-rulestead · asset/files manifest ·
theming · README hero/badges/social-card · rulestead_admin parity

## Methodology applied
Recommendation-First / Architect-Default / Research-Then-Recommend lenses
(`.planning/METHODOLOGY.md`). Low-impact mechanical-wiring phase → decisive single recommendations;
escalate only genuinely high-impact (contract/release-shape) choices. User explicitly requested
subagent research on every area (pros/cons, idiomatic Elixir/ExDoc, lessons from successful libs,
DX/UX, brand-book + prompts inputs) and a one-shot cohesive set.

## Assumptions Presented (gsd-assumptions-analyzer)

| # | Assumption | Confidence | Evidence |
|---|-----------|-----------|----------|
| 1 | Module groups: 5-group `groups_for_modules` rewrite | Confident | mix.exs:122-142; HEXDOCS.md |
| 2 | Extras: 6 groups, funnel order; first-match regex risk | Confident/Likely | mix.exs:92-121 |
| 3 | Asset wiring + `files:` (`../brandbook/...` token form uncertain) | Confident/Unclear | mix.exs:81-82 |
| 4 | `before_closing_head_tag` re-tint (var names version-sensitive) | Confident/Likely | tokens.css; ex_doc |
| 5 | why-rulestead.md authored from brand narrative | Confident | brand-book.md |
| 6 | README hero + 5 badges + social-card rasterization (no helper exists) | Confident/Likely | README; scripts/ |
| 7 | rulestead_admin parity + Router @moduledoc | Confident | admin mix.exs; router.ex |

## Gray-area research (4 parallel gsd-advisor-researcher agents)

### Agent A — Docs IA (groups + extras + why) — surfaced 4 contract defects
- **F1:** `Rulestead.Rule` in mix.exs:126 does not exist (module is `Rulestead.Ruleset.Rule`);
  `Ruleset/Rule/Flag` not in stable list, `Context` absent. → delete/correct.
- **F2:** `Rulestead.TestHelpers` is a contracted facade (api_stability.md:97) but `@moduledoc false`
  → invisible. → [escalated to user].
- **F3:** `Rulestead.Tenancy` NOT in stable module list → do not group as public.
- **F4:** `Telemetry`/`Config` both `@moduledoc false` → un-hide (prerequisite for the group).
- Extras first-match-wins footgun real; Ash idiom = explicit file list for "API & Stability".
- Validated against live Ash + Oban mix.exs (group by mental model; positioning-first; upgrading late).

### Agent B — ExDoc branding/theming — surfaced version mismatch
- **Installed ex_doc = 0.40.3, not 0.38.** HEXDOCS.md §1.5 var names
  (`--main-color-darkened`/`--code-link-color`/`--main-background`) don't exist in 0.40 → no-op.
  Correct = re-tint `--main*` HSL family (grepped from compiled CSS). Drop manual focus block
  (0.40 already `outline: 2px solid var(--main)`). OG image must be PNG not SVG.
- Verified Oban/Ash/Phoenix don't re-tint vars at all → `--main*` re-tint is on-brand restraint.

### Agent C — Hex packaging/`files:` — empirically PROVEN
- Ran a real `mix hex.build`: `"../brandbook/..."` in `files:` leaks an ABSOLUTE tarball path
  (`Path.relative_to/2` for out-of-root files) → logo 404. Fix = committed symlink
  `rulestead/brandbook -> ../brandbook` + plain-relative `*.svg` globs + no-`../` `docs:` paths.
  Confirmed tarball then contains real 1216-byte SVG. Whitelist guard safe as-is. Fallback =
  copy-on-build alias.

### Agent D — admin parity + Router moduledoc
- Moduledoc skeleton with host-owns-auth "What you must provide" checklist — the section Oban Web +
  LiveDashboard both omit. `@doc false` on `__using__/1` + `live_session/3`; autolink only public
  symbols. (Draft snippet's old CSS vars + `../` files: reconciled to D-13/D-09.)

## Corrections / Escalations Made

### Module groups — TestHelpers (USER DECISION)
- **Question:** Render `Rulestead.TestHelpers` (→ 6 groups, deviates from ROADMAP criterion-2's
  literal "5") vs. keep literal 5 (facade stays invisible)?
- **User chose:** **Render it — 6 groups.** Captured as D-02; criterion-2 treated
  satisfied-with-correction; ROADMAP wording amendment deferred.

### Auto-locked corrections to HEXDOCS.md baseline (no user input needed — proven winners)
- D-04: delete non-existent `Rulestead.Rule` (latent bug).
- D-05: keep `Rulestead.Tenancy` out of groups (not in stable list).
- D-09: symlink + no-`../` `files:` (empirically proven; corrects HEXDOCS.md D6/D7/D9).
- D-13/D-14/D-15: ex_doc 0.40 `--main*` re-tint, drop manual focus block, OG image = PNG
  (corrects HEXDOCS.md §1.5).
- D-06: explicit-list "API & Stability" extras group (defuses first-match footgun).

## External Research
Library evidence gathered via WebSearch/WebFetch: Ash, Oban, Phoenix, LiveView, Oban Web,
Phoenix LiveDashboard mix.exs + HexDocs (IA idioms, theming restraint, mounted-router moduledoc
patterns), shields.io badge conventions, Hex `mix hex.build` `expand_paths/2` source (the `../`
defect). No open questions remained unresolved; two items flagged as implementation-time local
verifications (re-grep ex_doc 0.40 var names; `mix hex.build` tarball content assertion in CI).
</content>
