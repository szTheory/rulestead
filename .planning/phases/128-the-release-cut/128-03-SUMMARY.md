---
phase: 128-the-release-cut
plan: 03
subsystem: release
tags: [release-please, ci, hex, cleanup]
requires:
  - phase: 128-the-release-cut
    provides: 1.0.0 live on hex (from 128-02)
provides:
  - release-as removed from release-please-config.json (no perpetual 1.0.0 re-proposal)
  - release-pr-automerge re-enabled (normal patch/minor flow restored)
  - MAINTAINING.md no-op note confirmed accurate
  - verify-trio robustness fixes (parity symlink + HexDocs redirect)
affects: [129]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified: [release-please-config.json, rulestead/lib/mix/tasks/verify.release_parity.ex, scripts/ci/check_docs_published.sh]
key-decisions:
  - "Removed release-as immediately post-publish (Landmine 1) so release-please reverts to commit-convention versioning."
  - "Fixed both verify-trio false positives so the GA verification is genuinely green, not just accepted."
status: complete
completed: 2026-06-18
---

# 128-03 — Post-cut cleanup + verify-trio robustness fixes

**Goal met.** `release-as` removed (PR #52) — confirmed release-please no longer re-proposes
1.0.0 (no new release PR after the merge). `release-pr-automerge` re-enabled (`active`).
`MAINTAINING.md` already documents `bump-minor-pre-major` / `bump-patch-for-minor-pre-major`
as no-ops post-1.0 with `feat!:` driving the next major (no edit needed).

## Verify-trio fixes (folded in to reach a genuinely-green GA verification)
- **PR #52** — `verify.release_parity` now resolves symlinked directories (the `brandbook`
  symlink) so the tag manifest matches what hex packages; `readme-header.svg` no longer false-flags.
- **PR #53** — `check_docs_published.sh` curl calls now use `-L` to follow HexDocs' new
  per-package-subdomain (`<pkg>.hexdocs.pm`) 301 redirect.

After both: `bash scripts/ci/verify_published_release.sh 1.0.0` exits 0.

## Verification
- `grep '"release-as"' release-please-config.json` → absent.
- `gh workflow list` → release-pr-automerge `active`.
- `grep -i 'no-op' MAINTAINING.md` → present.
- verify-trio exit 0; no spurious 1.0.x release PR opened.
