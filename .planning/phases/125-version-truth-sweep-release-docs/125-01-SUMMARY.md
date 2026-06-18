---
phase: 125-version-truth-sweep-release-docs
plan: 01
subsystem: release-docs
tags: [docs, version-truth, contract-test, release]
requires:
  - "Phase 124 release_contract_test.exs bidirectional doc↔code guard"
provides:
  - "Shipped doc surface swept to 1.0/1.x truth (REL-02 partial)"
  - "Root README 'Two version lines' callout deleted (SC-2)"
  - "Re-anchored release_contract_test.exs 1.0-truth guard (D-10)"
affects:
  - "README.md, rulestead/README.md, rulestead_admin/README.md, open_feature_rulestead/README.md"
  - "guides/ (cheatsheet, getting-started, phoenix-integration-spine, product-boundary, installation, upgrading, telemetry)"
  - "MAINTAINING.md, rulestead/test/rulestead/release_contract_test.exs"
tech-stack:
  added: []
  patterns:
    - "Bidirectional doc↔code lockstep (sweep + contract-test re-anchor in same plan)"
    - "Positive 1.0-truth re-anchor + refute guard (no version-truth hole)"
key-files:
  created: []
  modified:
    - README.md
    - rulestead/README.md
    - rulestead_admin/README.md
    - open_feature_rulestead/README.md
    - guides/cheatsheet.cheatmd
    - guides/introduction/getting-started.md
    - guides/introduction/phoenix-integration-spine.md
    - guides/introduction/product-boundary.md
    - guides/introduction/installation.md
    - guides/introduction/upgrading.md
    - guides/flows/telemetry.md
    - MAINTAINING.md
    - rulestead/test/rulestead/release_contract_test.exs
decisions:
  - "Restored the v1.0.0 GA fact in root README Versioning section after deleting the callout, so contract-test L232 (root_readme =~ v1.0.0) stays green without resurrecting 'Two version lines' framing"
  - "Used a refute guard for 'Two version lines' (instead of bare deletion) plus a positive 1.x assert, keeping version truth enforced (no hole)"
metrics:
  duration: "~6 min"
  completed: "2026-06-18"
  tasks: 3
  files_modified: 13
requirements:
  - REL-02
status: complete
---

# Phase 125 Plan 01: Version-Truth Sweep + Contract-Test Re-anchor Summary

Atomically swept the 12 in-scope shipped doc files from `0.1.x`/`~> 0.1` release language to `1.0`/`1.x`/`~> 1.0` truth (root README "Two version lines" callout deleted entirely) and re-anchored the 6 collision asserts in `release_contract_test.exs` in lockstep, so the bidirectional doc↔code guard stays green and still enforces version truth.

## What was built

- **Task 1 (commit f559005):** Swept 12 doc files. Deleted the "Two version lines" callout from root README + both package READMEs + getting-started + installation. Reframed all `~> 0.1` install snippets to `~> 1.0` (READMEs, cheatsheet, phoenix-integration-spine). Reframed `0.1.x`/`v0.1.x` package-line prose to `1.x` in upgrading, product-boundary (heading + body), telemetry, and MAINTAINING (3 sites). The legitimate third-party `{:open_feature, "~> 0.1.3"}` pin was preserved verbatim.
- **Task 2 (commit 44b6b96):** Re-anchored 6 contract-test asserts — L233 `root_readme =~ "0.1.x"` → `~> 1.0`; L234 `root_readme =~ "Two version lines"` → `refute … "Two version lines"` + positive `1.x` assert; L249 runtime, L254 admin, L262 upgrading → `~> 1.0`; L285 maintaining → `1.x`. The demo survivor (L265 `demo_readme =~ "0.1.x"`) was left unchanged.
- **Task 3:** `checkpoint:human-verify` — auto-approved under `--auto` (sweep coherence + green contract test confirmed via spot-checks).

## Verification

- Criterion-1 grep over the shipped surface (README, 3 package READMEs, guides/, MAINTAINING.md, CONTRIBUTING.md) returns **zero hits** (exit 1).
- `grep -c "Two version lines" README.md` = 0 (SC-2).
- `grep -c '~> 1\.0' README.md` = 3 (install snippets reframed).
- `cd rulestead && mix test test/rulestead/release_contract_test.exs` → **26 tests, 0 failures**.
- Third-party pin preserved: `grep -c 'open_feature, "~> 0.1.3"' open_feature_rulestead/README.md` = 1.
- Exactly one `=~ "0.1.x"` assert remains (the demo survivor, L265).
- `git diff --name-only` does NOT include `examples/demo/README.md`, `CONTRIBUTING.md`, `.planning/` (sweep), `prompts/`, or `rulestead/doc/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Coherence] Restored the `v1.0.0` GA fact in root README after the callout delete**
- **Found during:** Task 2 (contract test run)
- **Issue:** The root README "Two version lines" callout (deleted in Task 1) was the only place the root README mentioned `v1.0.0`. Deleting it made the pre-existing, in-scope assert L232 `assert root_readme =~ "v1.0.0"` go red. The plan explicitly says to "leave the `v1.0.0` GA facts intact wherever a reframed callout mentions them … L232 depends on them."
- **Fix:** Added the true GA fact to the root README `## Versioning` section ("Repo GA shipped in `v1.0.0` on 2026-05-21; the Hex packages install on the `1.x` line …") without resurrecting any "Two version lines"/"future 1.0" framing. Criterion-1 grep stays at zero hits.
- **Files modified:** README.md
- **Commit:** 44b6b96 (landed with the lockstep Task 2 change that depends on it)

## Known Stubs

None — this is a docs + test plan; no stub patterns introduced.

## Threat Flags

None — no new runtime/network/auth surface. The T-125-01 mitigation (preserve `~> 0.1.3` pin) and T-125-02 mitigation (lockstep re-anchor, contract test green) are both satisfied and grep-asserted.

## Self-Check: PASSED

- SUMMARY.md present at `.planning/phases/125-version-truth-sweep-release-docs/125-01-SUMMARY.md`
- Commit f559005 (Task 1 sweep) found in git history
- Commit 44b6b96 (Task 2 re-anchor + GA-fact restore) found in git history
