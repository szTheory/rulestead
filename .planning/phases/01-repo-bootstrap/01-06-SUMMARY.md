---
phase: 01-repo-bootstrap
plan: 06
subsystem: github-metadata
tags:
  - github
  - dependabot
  - issue-templates
  - codeowners
requires:
  - 01-04
  - 01-05
provides:
  - GitHub metadata for PR, issue, review, and dependency automation surfaces
affects:
  - .github/dependabot.yml
  - .github/pull_request_template.md
  - .github/CODEOWNERS
  - .github/ISSUE_TEMPLATE/bug_report.md
  - .github/ISSUE_TEMPLATE/feature_request.md
  - .github/ISSUE_TEMPLATE/release-parity-drift.md
tech_stack:
  - GitHub
  - Dependabot
decisions:
  - Keep release-parity issue intake dormant until Phase 8 so Phase 1 does not imply REL-03 or REL-04 already ship.
  - Route repository review ownership to the maintainer handle inferred from local git identity because no in-repo handle reference was present.
metrics:
  completed_at: 2026-04-23
---

# Phase 01 Plan 06: GitHub Metadata Summary

Added the repository metadata needed for Dependabot, pull requests, CODEOWNERS,
and issue intake while keeping the release-parity template explicitly dormant
until the Phase 8 workflow exists.

## Completed Work

- Added weekly Dependabot coverage for the `mix` and `github-actions`
  ecosystems with patch grouping and scoped commit prefixes.
- Added a pull request template that reminds contributors to use a
  Conventional Commit title and confirm validation/docs impact.
- Added CODEOWNERS pointing all paths at the maintainer account.
- Added bug report and feature request issue templates aligned with the
  current contributor surface.
- Added a release-parity drift template that clearly states it is reserved
  for Phase 8 and not yet backed by automation.

## Verification

- `bash -lc 'test -f .github/dependabot.yml && test -f .github/pull_request_template.md && test -s .github/CODEOWNERS && test -f .github/ISSUE_TEMPLATE/bug_report.md && test -f .github/ISSUE_TEMPLATE/feature_request.md && rg -n "package-ecosystem: \"mix\"|package-ecosystem: \"github-actions\"" .github/dependabot.yml && rg -n "Conventional Commit|conventional commit" .github/pull_request_template.md'`
- `bash -lc 'test -f .github/ISSUE_TEMPLATE/release-parity-drift.md && rg -n "Phase 8|release parity|reserved for" .github/ISSUE_TEMPLATE/release-parity-drift.md'`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Critical metadata completion] Added maintainer ownership via
   `@szTheory` using the local git identity because no existing in-repo
   maintainer handle reference was present. This preserves the CODEOWNERS
   routing requirement from the threat model without touching unrelated files.

## Known Stubs

None.

## Self-Check

PASSED
