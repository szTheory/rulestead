---
phase: 126-hexdocs-front-door
plan: "02"
subsystem: docs
tags: [hexdocs, positioning, why-rulestead, brandbook, doc-04]
dependency_graph:
  requires: [126-01]
  provides: [guides/introduction/why-rulestead.md, DOC-04]
  affects: [126-05-PLAN.md (extras: wiring), Phase 130 announce]
tech_stack:
  added: []
  patterns: [brandbook-sourced prose, calm low-hype voice, no-vendor-matrix guardrail]
key_files:
  created:
    - guides/introduction/why-rulestead.md
  modified: []
decisions:
  - "D-17: why-rulestead.md sourced from brandbook §4/§6/§7 + POSITIONING.md; NOT a README quickstart duplicate"
  - "D-18: Competitive framing via in-house-build / outgrowing-booleans only; zero named vendor names; no comparison matrix"
metrics:
  duration: "1 minute"
  completed: "2026-06-18"
  tasks_completed: 1
  files_changed: 1
status: complete
---

# Phase 126 Plan 02: Why Rulestead? Positioning Page Summary

## One-liner

Brandbook-sourced `why-rulestead.md` positioning page — problem narrative, payload-first mental model, boundary block linking `product-boundary.md`, and a maintenance/longevity answer — with zero named vendors.

## What was built

Created `guides/introduction/why-rulestead.md` (159 lines), the first Introduction extra in the onboarding funnel (D-07 slot). Structure per D-17:

1. **Tagline + one-liner** — "Runtime decisions, made clear." + the locked one-liner from POSITIONING.md D1.
2. **Problem narrative** — lifted from brandbook §4; calm, not fear-mongering.
3. **Why the usual answers fall short** — roll-your-own, boolean toggles, external SaaS; each framed as honest tradeoffs.
4. **What you get** — proof-bullet prose + a "What you get at a glance" table.
5. **60-second mental model** — `Rulestead.evaluate/3` snippet + payload-first vs cached-lookup table.
6. **"What Rulestead is — and is not"** — boundary block above the fold linking `product-boundary.md` (D-17 key_link).
7. **Maintenance & longevity** — SemVer promise, deprecation policy, MAINTAINING.md runbook, verification trio, honest 1.0 promotion story.
8. **Next steps** — links to getting-started.md, phoenix-integration-spine.md, api_stability.md, product-boundary.md, upgrading.md.

## Verification passed

```
test -f guides/introduction/why-rulestead.md   => PASS
grep -q 'product-boundary.md' why-rulestead.md => PASS
diff README.md (not byte-identical)            => PASS
wc -l (159 lines >= 40)                        => PASS
no named competitor vendors                    => PASS
no comparison matrix                           => PASS
```

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author why-rulestead.md from brandbook narrative | 605988b | guides/introduction/why-rulestead.md |

## Deviations from Plan

None — plan executed exactly as written. All must_haves satisfied:
- D-17: Canonical positioning page exists, sourced from brandbook §4/§6/§7.
- NOT a byte-duplicate of README.md (entirely different structure and content).
- No competitor vendor names; no comparison matrix (D-18 guardrail held).
- Above-the-fold "What Rulestead is — and is not" section links `product-boundary.md`.

## Known Stubs

None — all links point to confirmed-existing files: `product-boundary.md`, `getting-started.md`, `api_stability.md`, `upgrading.md`, `MAINTAINING.md`, `../flows/evaluation.md`. No placeholder text or hardcoded empty values.

## Threat Flags

None — this is doc-only content. The T-126-04 threat (brand integrity / competitive framing) was mitigated: D-18 guardrail upheld throughout (no vendor names, no comparison matrix).

## Self-Check: PASSED

- [x] `guides/introduction/why-rulestead.md` exists on disk
- [x] Commit `605988b` present in git log
- [x] Links to `product-boundary.md`, `getting-started.md`, `api_stability.md`, `upgrading.md`
- [x] No named competitor vendors
- [x] 159 lines (>= 40 line minimum)
