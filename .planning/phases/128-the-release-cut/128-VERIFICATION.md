---
phase: 128-the-release-cut
status: passed
verified: 2026-06-18
requirements: [REL-01, REL-04, REL-06]
score: 5/5 must-haves
---

# Phase 128 Verification — The Release Cut

**Goal:** `rulestead` and `rulestead_admin` published at `1.0.0` via the gated release-please
pipeline, post-publish verify-trio green, post-cut cleanup complete.

**Verdict: PASSED.** Verified against the live hex.pm registry and the published tarballs.

## Must-haves

| # | Must-have | Evidence | Status |
|---|-----------|----------|--------|
| 1 | release-as 1.0.0 added (rulestead block only); auto-merge disabled; release PR diff shows @version 1.0.0 in both packages before hand-merge | PR #49; release PR #47 at 1.0.0; release-pr-automerge disabled during cut | ✅ |
| 2 | Release PR includes the "promotion, not rewrite" preamble in both CHANGELOGs; maintainer hand-merged after eyeballing the diff | preamble in both CHANGELOGs; 6-item diff checklist verified; #47 squash-merged on explicit go-ahead | ✅ |
| 3 | Both packages published at 1.0.0 via the gated hex-publish pipeline | `hex.pm/api/packages/{rulestead,rulestead_admin}/releases/1.0.0` → 1.0.0; tags `rulestead-v1.0.0` + `rulestead_admin-v1.0.0` | ✅ |
| 4 | Post-publish verify-trio green (workspace clean, fresh consumer compiles vs Hex 1.0.0, HexDocs reachable, tarball matches tagged source) | `scripts/ci/verify_published_release.sh 1.0.0` exits 0 | ✅ |
| 5 | Post-cut cleanup: release-as removed, auto-merge re-enabled, MAINTAINING.md no-op note | PR #52; release-pr-automerge `active`; MAINTAINING no-op note present | ✅ |

## Notes / deviations
- Pre-cut work (124-127) was unmerged on a local branch; landed via PR #48 before the cut.
- Pre-existing bugs fixed to reach green: format + stale `0.1.x` guards, ui-matrix prod-route
  gating, **changelog-path doubling** (#50), **parity symlink-blindness** (#52), **docs-check
  redirect** (#53).
- The `hex-publish` environment has **no required reviewer**, so the publish auto-proceeded with
  no manual approval pause. Outcome correct; the intended gate did not hold. Recommend adding a
  required reviewer to that environment.

## Human verification (optional)
- Browse https://hexdocs.pm/rulestead/1.0.0 and https://hexdocs.pm/rulestead_admin/1.0.0 to
  confirm the rendered front door (logo, "Why Rulestead?", module groups, badges).
