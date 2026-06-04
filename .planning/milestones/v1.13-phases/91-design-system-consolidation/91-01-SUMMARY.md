---
phase: "91"
plan: "01"
subsystem: rulestead_admin
tags: [design-system, documentation, css, tokens]
dependency_graph:
  requires: []
  provides: [DSY-02-docs]
  affects: [rulestead_admin/priv/static/css/rulestead_admin.css, guides/flows/admin-ui.md]
tech_stack:
  added: []
  patterns: [SYNCED-PAIR, token-contract-comment, DRY-guide-link]
key_files:
  created: []
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
    - guides/flows/admin-ui.md
decisions:
  - Primary token-contract documentation lives in the CSS comment block (source of truth); guide links to CSS and does not duplicate the token list.
  - SYNCED-PAIR verification command embedded directly in the CSS header comment so it is co-located with the rule it enforces.
metrics:
  duration: "2 minutes"
  completed: "2026-06-04T09:21:24Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 91 Plan 01: Token-Contract Documentation Summary

CSS THEME LAYER header comment + admin-ui guide section documenting the invariant/variant split, 4-block cascade, SYNCED-PAIR rule with Python check, scale categories, and add-a-token recipe.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add token-contract header comment to CSS THEME LAYER | da77f0b | rulestead_admin/priv/static/css/rulestead_admin.css |
| 2 | Add "Design Token Contract" section to guides/flows/admin-ui.md | 585302c | guides/flows/admin-ui.md |

## Verification Results

| Check | Result |
|-------|--------|
| SYNCED PAIR python check | IDENTICAL (229 tokens) |
| Literal-scan component region | 0 one-off color values |
| mix compile --warnings-as-errors | OK (exit 0) |
| CSS: SYNCED-PAIR occurrences | 3 (>= 3 required) |
| CSS: HOW TO ADD TOKEN occurrence | 1 (>= 1 required) |
| CSS: python3 occurrence | 1 (>= 1 required) |
| Guide: Design Token Contract count | 1 |
| Guide: SYNCED-PAIR mentions | 3 (>= 1 required) |
| Guide: rulestead_admin.css references | 4 (>= 2 required) |
| Token values unchanged (spot-check) | --rs-neutral-900 light #1a2332, dark #e8edf3 confirmed |

## What Was Done

**Task 1 — CSS header comment (110 line insertion):**

Replaced the existing 6-line THEME LAYER comment with an expanded multi-section
token-contract header covering all six required sections:

1. **INVARIANT vs VARIANT SPLIT** — lists invariant categories (typography, radius,
   spacing, control, focus structural, z-index, motion) with token names, and variant
   categories (neutral ramp, surface/border/text aliases, brand, status success/warning/error,
   shadows, focus+disabled, overlay/scrim) with token names.
2. **CASCADE BLOCKS** — all 4 selectors listed (Block 1 light default, Block 2 system dark,
   Block 3 explicit dark pin, Block 4 explicit light pin) plus the `:not([data-theme])` precedence
   rule.
3. **SYNCED-PAIR RULE** — rule statement + verbatim Python verification command embedded in comment.
4. **SCALE CATEGORIES (invariant)** — token names by category.
5. **SCALE CATEGORIES (variant)** — token names by category.
6. **HOW TO ADD A TOKEN** — 4-step recipe (invariant path, variant path with both-pair update,
   run SYNCED-PAIR check, add to design-system fixture).

No token values were changed.

**Task 2 — Guide section (41 line insertion):**

Added `## Design Token Contract` section to `guides/flows/admin-ui.md` directly after
`## Stylesheet`. Covers:
- Two-level model description (invariant vs variant)
- 4-block cascade table with selectors and when-active descriptions
- SYNCED-PAIR rule paragraph referencing the CSS verification command
- Add-a-token micro-recipe (4 bullets matching the CSS recipe)
- Closing link to CSS as source of truth (no token list duplicated in guide)

## Deviations from Plan

None — plan executed exactly as written. Phase 88 cleanup was already complete;
literal-scan on the component region returned 0 before any edits.

## Known Stubs

None.

## Threat Flags

None. Changes are documentation-only (CSS comments + Markdown). No runtime surface altered.

## Self-Check: PASSED

- [x] rulestead_admin/priv/static/css/rulestead_admin.css modified and committed (da77f0b)
- [x] guides/flows/admin-ui.md modified and committed (585302c)
- [x] SYNCED PAIR IDENTICAL (229 tokens)
- [x] Literal scan: 0
- [x] mix compile: clean
