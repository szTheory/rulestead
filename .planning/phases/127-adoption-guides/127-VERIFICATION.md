---
phase: 127-adoption-guides
verified: 2026-06-18T00:00:00Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 127: Adoption Guides Verification Report

**Phase Goal:** Adopters have a blame-free troubleshooting reference and four persona-grounded integration recipes that use ONLY shipped public 1.x seams, wired into the existing Recipes extras group.
**Verified:** 2026-06-18
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GUIDE-01: troubleshooting.md ships 7 symptom-indexed patterns in Symptom→Cause→Fix→Verify form, cross-linking footguns anchors without duplicating, blame-free tone | ✓ VERIFIED | `grep -c '^## '` == 7; Symptom/Cause/Fix/Verify each == 7; all 7 named domains present (install/migration, payload-vs-keyed runtime, snapshot boot race, context propagation, RBAC 403, change-request block, OpenFeature/Redis stale); 3 footguns anchor links all resolve to real headings; intro paragraph (L4) states blame-free intent and links footguns for the "why" |
| 2 | GUIDE-02: integrations-cookbook.md ships 4 persona/JTBD recipes on fixed Goal→For→Prerequisites→Steps→Verification→Gotchas→Related template, each with honest boundary, only public seams | ✓ VERIFIED | `grep -c '^### Goal'` == 4; all 7 template sections == 4 each; 4 `**Boundary:**` lines; every "For" line maps to a named persona+flow in user-flows-and-jtbd.md (Tech Lead/Flow 2, Support+SRE/Flow 5, Operator+Tech Lead/Flow 3, App Developer/Flow 1); all headlined symbols confirmed public |
| 3 | GUIDE-03: both guides wired into EXISTING Recipes extras group (cookbook early, troubleshooting last), no new group, getting-started untouched | ✓ VERIFIED | mix.exs L116 integrations-cookbook.md before testing.md (early); L124 troubleshooting.md after migrating-from-funwithflags.md (last in recipes block); single regex `"Recipes": ~r"guides/recipes/"` (L164) — no new group; getting-started.md (L101) last touched in phase 125, untouched by 127 |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `guides/recipes/troubleshooting.md` | 7-pattern blame-free reference | ✓ VERIFIED | 93 lines (min 90); 7 patterns × full 4-part structure; contains "Symptom" |
| `guides/recipes/integrations-cookbook.md` | 4 recipes on fixed template | ✓ VERIFIED | 326 lines (min 120); 4 recipes × full 7-section template; contains "## Goal" via "### Goal" ×4 |
| `rulestead/mix.exs` | extras wiring in correct order | ✓ VERIFIED | both files in extras list; correct positions; no new groups_for_extras entry |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| troubleshooting.md | footguns.md | anchor cross-links for the "why" | ✓ WIRED | 3 anchors (#missing-or-unstable-targeting_key, #payload-first-vs-keyed-runtime-confusion, #snapshot-cache-before-readiness) all resolve to real footguns headings |
| integrations-cookbook.md | user-flows-and-jtbd.md | each "For" names a canonical persona/flow | ✓ WIRED | 4 "For" lines map 1:1 to named personas + flows in the source |
| mix.exs | integrations-cookbook.md | extras entry before testing.md (early) | ✓ WIRED | L116 precedes L117 testing.md |
| mix.exs | troubleshooting.md | extras entry after migrating-from-funwithflags.md (last) | ✓ WIRED | L124, last recipe entry |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Docs build with no broken autolinks | `cd rulestead && mix docs --warnings-as-errors` | exit 0 | ✓ PASS |
| No pre-1.0 version drift | `python3 scripts/check_version_truth.py` | "VERSION TRUTH OK (36 files clean)" exit 0 | ✓ PASS |
| Troubleshooting pattern count | `grep -c '^## ' troubleshooting.md` | 7 | ✓ PASS |
| Cookbook recipe count | `grep -c '^### Goal' integrations-cookbook.md` | 4 | ✓ PASS |

### Prohibitions (negative checks)

| Prohibition | Status | Evidence |
|-------------|--------|----------|
| MUST NOT headline submit_change_request / Store.Redis / Store.Command.* as stable 1.x API | ✓ VERIFIED (did not happen) | `grep -REq 'submit_change_request\|Store\.Redis\|Store\.Command'` over both guides → clean. CR/promotion content routes through `Rulestead.Admin.Policy.change_request_required?/4` + `[:rulestead, :admin, :mutation, :stop]` telemetry in both guides, exactly as required |
| MUST NOT introduce pre-1.0 version drift (0.1.x / ~> 0.1) | ✓ VERIFIED (did not happen) | grep for `0.1.x \| ~> 0.1 \| 0.1.7` over both guides → clean; check_version_truth.py green |

All headlined API symbols cross-checked as public: `evaluate/3`, `Runtime.enabled?/3`, `Runtime.diagnostics/1`, `preview_audience_impact/3`, `apply_audience_mutation/2`, `list_audit_events/1`, `Telemetry.attach_many/4`, `Admin.Policy.*_actions/0`, `Context.new`, `Oban.Middleware.attach/2`, `Oban.Worker`, `Phoenix.context_from_conn/2`, `LiveView.assign_flags/3`, `mix rulestead.install`, `mix rulestead.redis.sync` — each present in api_stability.md catalog and/or defined in `rulestead/lib`.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| GUIDE-01 | 127-01-PLAN | troubleshooting.md, 7 patterns | ✓ SATISFIED | Truth 1 |
| GUIDE-02 | 127-02-PLAN | integrations-cookbook.md, 4 recipes | ✓ SATISFIED | Truth 2 |
| GUIDE-03 | 127-03-PLAN | wire both into Recipes extras | ✓ SATISFIED | Truth 3 |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none | — | "JTBD" link-text grep hits are false positives (Jobs-To-Be-Done), not debt markers |

### Human Verification Required

None. All must-haves are verifiable via grep/file inspection plus the green `mix docs` and version-truth gates; the editorial truths (4-part/7-section completeness, cross-link-not-duplicate, persona mapping, boundary lines) were confirmed by reading both files in full.

### Gaps Summary

No gaps. All three success criteria, both prohibitions, all artifacts, and all key links verify against the codebase. The phase goal is achieved.

---

_Verified: 2026-06-18_
_Verifier: Claude (gsd-verifier)_
