---
phase: 125-version-truth-sweep-release-docs
verified: 2026-06-18T05:55:48Z
status: passed
score: 14/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: # No — initial verification
---

# Phase 125: Version-Truth Sweep + Release Docs Verification Report

**Phase Goal:** Every shipped file tells the truth about `1.x` — no stale `0.1.x` language anywhere in the public surface — and adopters have clear upgrade and maintainer-runbook docs ready before the cut.
**Verified:** 2026-06-18T05:55:48Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Criterion-1 stale-claim grep over the shipped surface returns zero hits (SC-1) | ✓ VERIFIED | Stale-claim grep (sanctioned `0.1.x → 1.0` arrow excluded) exits 1 (no match). Raw SC-1 grep shows only the 2 sanctioned occurrences: `open_feature_rulestead/README.md:27 ~> 0.1.3` (third-party pin) and `upgrading.md:12 ## Upgrading 0.1.x → 1.0` (criterion-4 heading). |
| 2 | Root README "Two version lines" callout deleted entirely (SC-2, D-01) | ✓ VERIFIED | `grep -c "Two version lines" README.md` = 0. Install snippets reframed: `grep -c '~> 1\.0' README.md` = 4. |
| 3 | Every shipped install snippet reads `~> 1.0` | ✓ VERIFIED | Sweep diff covers all 4 READMEs + cheatsheet + phoenix-integration-spine; root README shows 4 `~> 1.0` hits; drift guard confirms no bare `~> 0.1` remains. |
| 4 | `release_contract_test.exs` green after re-anchor; bidirectional guard still enforces version truth (D-10) | ✓ VERIFIED | `mix test test/rulestead/release_contract_test.exs` → 26 tests, 0 failures. `refute root_readme =~ "Two version lines"` at L235 (positive guard, no hole); exactly one `=~ "0.1.x"` assert remains (the demo survivor). |
| 5 | Legitimate third-party pin `{:open_feature, "~> 0.1.3"}` preserved verbatim (D-04) | ✓ VERIFIED | `grep -c 'open_feature, "~> 0.1.3"' open_feature_rulestead/README.md` = 1. Lookahead proof: `~> 0\.1(?![.\d])` does NOT match `~> 0.1.3`. |
| 6 | Demo README `0.1.x` assert (L265) unchanged — out of sweep scope (D-03) | ✓ VERIFIED | `examples/demo/README.md` still has `0.1.x` (grep = 1); not in phase diff; contract test survivor `demo_readme =~ "0.1.x"` count = 1. |
| 7 | `check_version_truth.py` exits 0 on the clean tree (SC-3) | ✓ VERIFIED | `python3 scripts/check_version_truth.py` → `VERSION TRUTH OK (33 files clean)`, exit 0. |
| 8 | Guard exits 1 when a stale `0.1.x` claim reappears (fail-closed) | ✓ VERIFIED | Adversarial seed of `Hex packages use 0.1.x semver today.` into `guides/cheatsheet.cheatmd` → guard exit 1, `VERSION TRUTH DRIFT DETECTED`. Seed reverted; tree clean. |
| 9 | Guard does NOT flag the third-party `~> 0.1.3` pin; arrow heading exempt line-scoped | ✓ VERIFIED | Lookahead proof passes; seeding `## Upgrading 0.1.x -> 1.0` keeps guard green; `UPGRADE_ARROW` pattern `0\.1\.x\s*(?:→\|->)\s*1\.0` is applied per-line only. |
| 10 | Guard wired into `lint.sh`; `bash scripts/ci/lint.sh` exits 0 | ✓ VERIFIED | `grep -c 'check_version_truth.py' scripts/ci/lint.sh` = 1; `bash scripts/ci/lint.sh` exit 0 (credo, docs, build, dialyzer, all guards incl. version-truth pass). Guard executable bit set. |
| 11 | upgrading.md has "Upgrading 0.1.x → 1.0" section — zero code changes / dep-pin bump / promotion-not-rewrite (SC-4, D-07) | ✓ VERIFIED | `grep -c "## Upgrading 0.1.x → 1.0"` = 1. Read content (L12-34): "**Promotion, not rewrite.**", "**zero breaking changes** and **no code changes**", single dependency-pin bump to `~> 1.0`. |
| 12 | MAINTAINING.md "Cutting a major (X.0.0)" runbook — Release-As, package sequence, deprecation-window, mandatory post-cut removal (SC-5, D-07) | ✓ VERIFIED | `grep -c "## Cutting a major (X.0.0)"` = 1. Read content: Release-As config-block mechanism, `rulestead`→`rulestead_admin` linked sequence, deprecation-window checklist tied to `api_stability.md`, explicit "Mandatory post-cut removal" subsection. |
| 13 | Runbook states `open_feature_rulestead` is NOT release-please managed (manual publish) — only rulestead + rulestead_admin linked (D-08) | ✓ VERIFIED | Runbook: "`open_feature_rulestead` is **NOT** release-please managed... published by a **separate manual step**... strictly **after** `rulestead@X.0.0` is live." |
| 14 | `brandbook/CHANGELOG-PREAMBLE-1.0.md` staged two-package "promotion, not rewrite" preamble, NOT in bot-managed CHANGELOGs (SC-6, D-09) | ✓ VERIFIED | File exists; content is a two-package ("`rulestead` and `rulestead_admin` graduate together") "Promotion, not rewrite" preamble with explicit "**Zero breaking changes.**" / "**No public API changes.**". Bot CHANGELOGs + release-please config untouched in phase diff. |

**Score:** 14/14 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `rulestead/test/rulestead/release_contract_test.exs` | Re-anchored bidirectional version-truth guard, contains `~> 1.0` | ✓ VERIFIED | 26 tests / 0 failures; re-anchored to positive `1.0`-truth strings; refute guard for "Two version lines"; demo survivor preserved. |
| `README.md` | Swept to 1.0 truth, callout deleted, contains `~> 1.0` | ✓ VERIFIED | "Two version lines" = 0; `~> 1.0` = 4; GA `v1.0.0` fact restored in Versioning section (documented coherence deviation, contract test L232 green). |
| `scripts/check_version_truth.py` | Fail-closed drift guard, contains `(?![.\d])` | ✓ VERIFIED | Exists, executable, exits 0 clean / 1 on stale claim; sibling `check_*.py` convention; lookahead protects `~> 0.1.3`. |
| `scripts/ci/lint.sh` | Guard wired, contains `check_version_truth.py` | ✓ VERIFIED | Wired exactly once in the Python-guard block; full lint exits 0. |
| `guides/introduction/upgrading.md` | "Upgrading 0.1.x → 1.0" section | ✓ VERIFIED | H2 present; substantive promotion-not-rewrite prose. |
| `MAINTAINING.md` | "Cutting a major (X.0.0)" runbook | ✓ VERIFIED | Substantive runbook covering all SC-5 elements + D-08. |
| `brandbook/CHANGELOG-PREAMBLE-1.0.md` | Staged two-package "Promotion, not rewrite" preamble | ✓ VERIFIED | Complete ready-to-paste artifact; bot CHANGELOGs untouched. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `release_contract_test.exs` | swept README/upgrading/MAINTAINING files | `File.read! + =~` re-anchored asserts | ✓ WIRED | 26 tests read real swept files and pass; positive `1.0`-truth anchors match swept prose. |
| `scripts/ci/lint.sh` | `scripts/check_version_truth.py` | `python3` invocation under `set -euo pipefail` | ✓ WIRED | Guard runs in lint lane fail-closed; lint exit 0, guard exit 0. |
| `MAINTAINING.md` runbook | `release-please-config.json` + `release-please.yml` | Documents Release-As mechanism + post-cut removal (does not execute) | ✓ WIRED | Runbook names config-block `release-as`, mandatory removal step, and historical workflow echo correctly. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Stale-claim freedom | criterion-1 grep (arrow-excluded) | exit 1 (no match) | ✓ PASS |
| Drift guard clean | `python3 scripts/check_version_truth.py` | `VERSION TRUTH OK (33 files clean)`, exit 0 | ✓ PASS |
| Guard fail-closed on stale claim | seed `0.1.x` claim → run guard | exit 1, DRIFT DETECTED | ✓ PASS |
| Guard arrow exemption | seed `0.1.x -> 1.0` heading → run guard | exit 0 (exempt) | ✓ PASS |
| Lookahead protects pin | `re.search('~> 0\.1(?![.\d])', '~> 0.1.3')` | no match | ✓ PASS |
| Lint lane | `bash scripts/ci/lint.sh` | exit 0 | ✓ PASS |
| Contract test | `mix test ...release_contract_test.exs` | 26 tests, 0 failures | ✓ PASS |

### Probe Execution

No phase-declared probes (`scripts/*/tests/probe-*.sh`). The authoritative gates are the drift guard, lint lane, and contract test — all run above. SKIPPED (no probe scripts declared/present).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| REL-02 | 125-01, 125-02 | Version-truth sweep reframes stale `0.1.x` files to 1.0, deletes README "two version lines" callout, adds CI drift guard to `lint.sh`; `.planning/`/`prompts/` untouched | ✓ SATISFIED | Truths 1-3, 5-10; sweep + callout delete + fail-closed guard wired; `.planning/`/`prompts/` absent from phase diff. |
| REL-03 | 125-03 | `1.0.0` CHANGELOG "promotion, not rewrite" preamble; upgrading.md `0.1.x→1.0` path; MAINTAINING.md "Cutting a major" runbook | ✓ SATISFIED | Truths 11-14; all three release docs present and substantive. |

Both requirement IDs from PLAN frontmatter (REL-02, REL-03) accounted for. No orphaned requirements — REQUIREMENTS.md maps only REL-02 and REL-03 to Phase 125, both claimed by plans.

### Anti-Patterns Found

None. No unreferenced `TBD`/`FIXME`/`XXX` debt markers in phase-modified files. No stub patterns (all three docs are complete prose; the staged preamble is intentionally pre-authored for Phase 128, a documented downstream consumer — not a stub).

### Scope Discipline

Phase diff (excluding `.planning/`) touches exactly the 16 declared files. NOT touched (correctly): `examples/demo/README.md`, `CONTRIBUTING.md`, `rulestead/CHANGELOG.md`, `rulestead_admin/CHANGELOG.md`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `prompts/`, `rulestead/doc/`.

### Documented Coherence Deviations (both legitimate, verified)

1. **Plan 01** restored the true `v1.0.0` GA fact in the root README `## Versioning` section after deleting the callout — keeps contract test L232 (`root_readme =~ "v1.0.0"`) green without resurrecting stale "Two version lines"/"future 1.0" framing. Criterion-1 grep stays at zero stale hits. Verified.
2. **Plan 02** ran `mix format` on `release_contract_test.exs` (Plan 01 left it unformatted, blocking lint's `mix format --check-formatted` step). Whitespace-only; documented in `deferred-items.md`. Verified — lint exit 0.

### SC-5 wording note (not a gap)

ROADMAP SC-5 says "the three-package sequence." The runbook documents a two-package release-please linked sequence (`rulestead`→`rulestead_admin`) PLUS the manual `open_feature_rulestead` third package — which is the *accurate* mechanism per locked decision D-08 (open_feature is NOT release-please managed). The runbook correctly covers all three packages with the correct mechanism for each. This honors the criterion's intent (the full three-package release picture) without misrepresenting release-please's scope.

### Gaps Summary

No gaps. All 6 ROADMAP success criteria, both requirements (REL-02, REL-03), all 14 must-have truths, all 7 artifacts, and all 3 key links verified against the actual codebase. The four authoritative gates (stale-claim grep clean, drift guard exit 0, lint exit 0, 26/26 contract tests) all pass. The drift guard was adversarially confirmed fail-closed and line-scoped. The phase goal — every shipped file tells the truth about `1.x`, no stale `0.1.x` language in the public surface, and adopters/maintainers have ready upgrade + runbook + CHANGELOG-preamble docs before the cut — is achieved.

---

_Verified: 2026-06-18T05:55:48Z_
_Verifier: Claude (gsd-verifier)_
