---
phase: 128-the-release-cut
plan: 02
subsystem: release
tags: [hex, publish, release-please, verify-trio]
requires:
  - phase: 128-the-release-cut
    provides: release PR #47 ready at 1.0.0 (from 128-01)
provides:
  - rulestead@1.0.0 and rulestead_admin@1.0.0 live on hex.pm
  - rulestead-v1.0.0 + rulestead_admin-v1.0.0 git tags on main
  - verify-trio green (exit 0) against the published 1.0.0
affects: [128-03, 129]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified: [.release-please-manifest.json, rulestead/mix.exs, rulestead_admin/mix.exs, rulestead/CHANGELOG.md, rulestead_admin/CHANGELOG.md]
key-decisions:
  - "Release PR #47 squash-merged (point-of-no-return) on explicit user go-ahead."
  - "verify-trio parity + docs-check robustness bugs fixed before declaring the trio green (carried into 128-03)."
status: complete
completed: 2026-06-18
---

# 128-02 — Hand-merge release PR, publish both packages, verify-trio green

**Goal met.** Release PR #47 squash-merged → release-please created tags `rulestead-v1.0.0`
and `rulestead_admin-v1.0.0` and dispatched `publish-hex.yml`. **Both packages published and
live on hex.pm at 1.0.0.** verify-trio (`scripts/ci/verify_published_release.sh 1.0.0`) now
exits 0: Hex visibility, workspace clean, fresh-consumer compile, release parity, and docs/OG
asset gates all pass for both packages.

## Deviations (significant)
- **No human approval pause at publish:** the `hex-publish` GitHub environment has **no required
  reviewer configured**, so after the release-PR merge the pipeline ran straight through the
  `approval` job to publish-core/publish-admin with no manual gate. The packages published as
  intended, but the designed manual approval did not actually hold. (Recommend adding a required
  reviewer to the `hex-publish` environment if a real gate is wanted.)
- **verify-trio initially failed (false positives, not package defects):**
  - `release_parity` flagged `brandbook/assets/specimens/readme-header.svg` as "extra" because
    its `git ls-tree` tag manifest was blind to the `brandbook` symlink (hex resolves it; git
    doesn't). The published tarball is correct. Fixed in 128-03.
  - `check_docs_published.sh` failed the OG/asset checks because HexDocs now 301-redirects
    `hexdocs.pm/<pkg>/...` to the per-package subdomain and the curl calls didn't follow
    redirects. The published docs/OG assets are correct. Fixed in 128-03.

## Verification
- `curl hex.pm/api/packages/{rulestead,rulestead_admin}/releases/1.0.0` → version 1.0.0.
- `bash scripts/ci/verify_published_release.sh 1.0.0` → exit 0 (after the 128-03 fixes).
