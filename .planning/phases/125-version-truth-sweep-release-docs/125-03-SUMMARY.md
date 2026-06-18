---
phase: 125-version-truth-sweep-release-docs
plan: 03
subsystem: release-docs
tags: [release, docs, version-truth, maintaining, changelog, brandbook]
requires:
  - 125-01  # upgrading.md / MAINTAINING.md already swept (Wave 1)
  - 125-02  # check_version_truth.py drift guard exists and is wired into lint.sh
provides:
  - "Upgrading 0.1.x → 1.0 section in guides/introduction/upgrading.md"
  - "Cutting a major (X.0.0) runbook in MAINTAINING.md"
  - "brandbook/CHANGELOG-PREAMBLE-1.0.md staged release-PR artifact"
affects:
  - Phase 128 (the actual 1.0.0 cut consumes this runbook + preamble)
  - Phase 129 (open_feature_rulestead manual publish, referenced by the runbook)
tech-stack:
  added: []
  patterns:
    - "brandbook/ as the home for staged, ready-but-unapplied release text (sibling of RELEASE-TEMPLATE.md)"
    - "Documents-not-executes: the runbook describes Release-As; the cut is Phase 128"
key-files:
  created:
    - brandbook/CHANGELOG-PREAMBLE-1.0.md
  modified:
    - guides/introduction/upgrading.md
    - MAINTAINING.md
decisions:
  - "D-07: additive reframe-in-place sections, not restructures"
  - "D-08: runbook explicitly states open_feature_rulestead is a separate MANUAL publish (Phase 129), not release-please managed"
  - "D-09: CHANGELOG preamble staged in brandbook/, NOT committed into the bot-managed per-package CHANGELOGs"
metrics:
  duration: ~12m
  completed: 2026-06-18
  tasks: 3
  files: 3
status: complete
---

# Phase 125 Plan 03: Release Docs (upgrading section + major-cut runbook + staged CHANGELOG preamble) Summary

Authored the three release docs adopters and maintainers need *before* the Phase 128 `1.0.0` cut — all carrying the "promotion, not rewrite" through-line: a `1.0.0` that is the same battle-tested code, honestly versioned, with explicit zero breaking changes and only a dependency-pin bump.

## What was built

1. **`## Upgrading 0.1.x → 1.0` section in `guides/introduction/upgrading.md`** (Task 1) — inserted as the first H2 a reader hits (after the L5 intro, before "What to review before upgrading"). States explicit zero breaking changes / no code changes, a single dep-pin bump to `~> 1.0`, and "promotion, not rewrite" framing. The H2 title uses the exact Unicode-arrow form `0.1.x → 1.0` that the drift guard exempts; the dep-pin example only writes the forward `~> 1.0` token, so no bare `~> 0.1` was reintroduced.

2. **`## Cutting a major (X.0.0)` runbook in `MAINTAINING.md`** (Task 2) — inserted between `## Gated publish choreography` and `## Manual recovery path`, keeping all release-cut content contiguous. Covers: what release-please manages vs not, the `Release-As` config-block mechanism, the `rulestead` → `rulestead_admin` linked publish sequence, a deprecation-window checklist tied to `guides/api_stability.md`, the mandatory post-cut `release-as` removal step, and a sequence summary. Documents only — no release-please config / manifest / workflow files were edited.

3. **`brandbook/CHANGELOG-PREAMBLE-1.0.md`** (Task 3) — NEW staged two-package preamble sibling to `RELEASE-TEMPLATE.md`, meant to be pasted above release-please's generated `1.0.0` bullets during the major-cut PR. Inherits the operator-consequence-first microcopy: two-package "Promotion, not rewrite", explicit zero breaking changes / no public API change, points at `api_stability.md` and `upgrading.md`. The bot-managed per-package CHANGELOGs were left untouched.

## D-08 accuracy (runbook)

The runbook explicitly states `open_feature_rulestead` is **NOT** release-please managed — it is a separate **manual** publish (a later provider wave), strictly after `rulestead@X.0.0` is live. Only `rulestead` + `rulestead_admin` are linked-versions. This directly mitigates threat **T-125-04** (a wrong runbook misleading a future maintainer into a broken cut).

## T-125-05 mitigation (no tampering with bot-managed surfaces)

The preamble lives in `brandbook/` (D-09); `git diff` confirms neither `rulestead/CHANGELOG.md`, `rulestead_admin/CHANGELOG.md`, `release-please-config.json`, `.release-please-manifest.json`, nor `.github/workflows/release-please.yml` were modified by this plan.

## Deviations from Plan

None — plan executed exactly as written.

## Authentication Gates

None.

## Checkpoint (Task 4 — human-verify)

Task 4 was a `checkpoint:human-verify` gate. This run executed under `--auto`, so the non-blocking human-verify checkpoint was auto-approved after the full verification suite passed. It is not a `blocking-human` / package-legitimacy gate.

## Final-phase verification (this is the last plan of Phase 125)

All gates green and recorded:

| Gate | Result |
|------|--------|
| `python3 scripts/check_version_truth.py` | exit 0 — `VERSION TRUTH OK (33 files clean)` |
| `bash scripts/ci/lint.sh` | exit 0 (credo, docs, package build, dialyzer, brand-token + contrast + version-truth guards all pass) |
| `cd rulestead && mix test test/rulestead/release_contract_test.exs` | 26 tests, 0 failures |
| `grep -c "## Upgrading 0.1.x → 1.0" guides/introduction/upgrading.md` | 1 |
| `grep -q "Cutting a major" MAINTAINING.md` | present |
| `test -f brandbook/CHANGELOG-PREAMBLE-1.0.md` | exists |

The drift guard stayed green after every single doc addition (verified per-task, not just at the end).

## Known Stubs

None — all three docs are complete, ready-to-use prose; the preamble is a finished ready-to-paste artifact (intentionally staged for Phase 128, which is the documented downstream consumer, not a stub).

## Commits

- `c400892` docs(125-03): add 'Upgrading 0.1.x → 1.0' promotion-not-rewrite section
- `188b11e` docs(125-03): add 'Cutting a major (X.0.0)' runbook to MAINTAINING.md
- `8865d33` docs(125-03): stage brandbook/CHANGELOG-PREAMBLE-1.0.md

## Self-Check: PASSED

All created/modified files exist on disk; all three task commits found in git history.
