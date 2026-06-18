---
phase: 127-adoption-guides
plan: 02
subsystem: docs
tags: [docs, exdoc, recipes, adoption, guide-02]
requires:
  - guides/api_stability.md (locked 1.x seam catalog)
  - guides/introduction/user-flows-and-jtbd.md (personas/flows)
  - guides/introduction/product-boundary.md (boundary truth)
provides:
  - guides/recipes/integrations-cookbook.md (GUIDE-02, four persona-grounded recipes)
affects:
  - rulestead/mix.exs extras (auto-joins Recipes group; explicit wiring in Plan 03)
tech-stack:
  added: []
  patterns:
    - "Fixed cookbook template: Goal -> For -> Prerequisites -> Steps -> Verification -> Gotchas -> Related"
    - "Persona/flow-anchored 'For' lines from user-flows-and-jtbd.md"
    - "Honest boundary line per recipe (what host owns / what Rulestead does NOT do)"
    - "CR promotion framed by outcome via Admin.Policy.change_request_required?/4 + [:rulestead, :admin, :mutation, :stop] + list_audit_events/1"
key-files:
  created:
    - guides/recipes/integrations-cookbook.md
  modified: []
decisions:
  - "Routed staging->prod CR promotion entirely through the governance flow (change_request_required?/4 callback + admin mutation telemetry + list_audit_events/1); never headlined the uncataloged submit_change_request/1 or @moduledoc-false mix tasks (RESEARCH A1/A2 safe default)."
  - "Built the Stripe-tier mutation via the root facade map form apply_audience_mutation/2, not Rulestead.Store.Command.* internals."
  - "Confined telemetry to documented metadata keys only; stated redaction-by-default boundary for the Segment recipe."
metrics:
  duration: ~12m
  completed: 2026-06-18
status: complete
---

# Phase 127 Plan 02: Integrations Cookbook (GUIDE-02) Summary

Authored `guides/recipes/integrations-cookbook.md` with exactly four
persona/JTBD-grounded integration recipes on a fixed template, using only
locked 1.x public seams from `api_stability.md` and passing the docs autolink
gate plus the version-truth guard.

## What Shipped

A single new ExDoc extra (`guides/recipes/integrations-cookbook.md`, ~330 lines)
that auto-joins the existing "Recipes" group via the `~r"guides/recipes/"`
regex. One `# Integrations Cookbook` H1, a short intro stating the fixed
template and 1.x-seams-only guarantee, then four `## ` recipes — each carrying
the seven `### ` sub-sections **Goal → For → Prerequisites → Steps →
Verification → Gotchas → Related** in order, a canonical persona/flow "For"
line, and an honest boundary line.

| Recipe | Persona / Flow | Headline seams |
|--------|----------------|----------------|
| Gate a Stripe-tier audience | Tech Lead / Flow 2: Target The Right Audience | `Rulestead.apply_audience_mutation/2` (map form), `Rulestead.preview_audience_impact/3`, `%Rulestead.Context{attributes:}` |
| Stream eval telemetry to Segment | Support Engineer + SRE/On-call / Flow 5: Explain One User's Reality | `Rulestead.Telemetry.attach_many/4` on `[:rulestead, :eval, :decide, :stop]` + documented metadata keys |
| Promote staging→prod reviewably | Operator + Tech Lead / Flow 3: Preview Before You Regret It | `Rulestead.Admin.Policy.change_request_required?/4`, `[:rulestead, :admin, :mutation, :stop]`, `Rulestead.list_audit_events/1` |
| Gate an Oban background job | App Developer / Flow 1: Ship Behind A Flag | `Rulestead.Oban.Middleware.attach/2`, `use Rulestead.Oban.Worker` + `rulestead_context/1`, `Rulestead.Runtime.enabled?/3`, `config :rulestead, :host, oban:` |

## Constraint Compliance

- **Seam allow-list:** every backtick-referenced symbol resolves to a verified
  public seam in the RESEARCH "Verified Public Seams" table. `mix docs
  --warnings-as-errors` is green (no broken autolinks).
- **Landmine deny-list:** the negative grep
  `! grep -Eq 'submit_change_request|Store\.Redis|Store\.Command'
  guides/recipes/integrations-cookbook.md` returns no matches. The CR-promotion
  recipe routes by outcome through the governance callback + admin mutation
  telemetry + audit log; the uncataloged `submit_change_request/1` and the
  `@moduledoc false` mix tasks are never headlined.
- **Boundary truth:** each recipe states what the host owns / what Rulestead does
  NOT do (population truth & no authoritative affected-user count; telemetry
  redacted by default; not a hosted control plane; Oban seam carries bounded
  context only). The three `control plane` / `authoritative ... count` matches in
  the file are all negations (boundary lines), not promises.
- **Version truth:** `python3 scripts/check_version_truth.py` exits 0
  (36 files clean); the file uses `1.x` / `~> 1.0`, never `0.1.x` / `~> 0.1`.
- **Persona grounding:** all four "For" lines name a canonical persona and flow
  title verbatim from `user-flows-and-jtbd.md`.

## Verification Results

| Gate | Command | Result |
|------|---------|--------|
| Recipe count | `grep -c '^## ' …` | 4 ✓ |
| Template first sub-section | `grep -c '^### Goal' …` | 4 ✓ |
| Docs autolink gate | `cd rulestead && mix docs --warnings-as-errors` | exit 0 ✓ |
| Version-truth guard | `python3 scripts/check_version_truth.py` | exit 0 (36 files clean) ✓ |
| Landmine deny-list | `! grep -Eq 'submit_change_request|Store\.Redis|Store\.Command' …` | no matches ✓ |

## Deviations from Plan

None — plan executed exactly as written. Task 2 (gates) required no corrections
to the file authored in Task 1; both `mix docs --warnings-as-errors` and
`check_version_truth.py` passed on first run, so no separate Task 2 commit was
needed.

## Notes

- `.planning/STATE.md` is intentionally left modified in the working tree
  (orchestrator owns that write per the objective) — not committed or reverted.
- Generated `/doc/` output from `mix docs` is gitignored (parity with prior
  commit `e6def7c`) and was not committed.
- The `mix.exs` `extras:` ordering edit (GUIDE-03) is explicitly Plan 03's
  responsibility; the new file already auto-joins the Recipes group via regex.

## Self-Check: PASSED

- `guides/recipes/integrations-cookbook.md` — FOUND
- `.planning/phases/127-adoption-guides/127-02-SUMMARY.md` — FOUND
- Commit `c2f8fcb` (Task 1 authoring) — FOUND
