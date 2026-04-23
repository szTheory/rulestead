# Maintaining Rulestead

## Phase 1 posture

Rulestead is in Phase 1 of 8. The repository is intentionally front-loading
its release engineering and documentation spine before the implementation
surface exists.

Two operational rules follow from that:

- Release Please PRs are advisory during Phases 1 through 7.
- `rulestead_admin` must not be published while it is still the Phase 1
  guarded stub.

## Branch protection settings

Document these settings exactly on `main`:

- Required status checks:
  - `release_gate`
  - `Validate PR title`
  - `dependency-review`
- `actionlint` is not a required status check because it is path-filtered
  and would sit Pending on non-workflow pull requests.
- Require branches to be up to date before merging: off
- Require a pull request before merging: on
- Required approvals: 0
- Require linear history: on
- Require signed commits: off
- Do not allow bypassing the above settings: on
- Allow force pushes: off
- Allow deletions: off
- Require conversation resolution before merging: off

## Release Please flow

The repository uses a linked-version sibling-package setup:

- `rulestead`
- `rulestead_admin`

The release metadata is seeded from day one so the eventual Phase 8 release
PR opens with the right component tags and changelog paths. During Phases 1
through 7, do not merge the release PR.

Why this rule exists:

- the package layout is already final
- tags and changelog paths should not be migrated later
- `rulestead_admin` is intentionally only a skeleton early on

## Manual reruns and GitHub token caveat

The default `GITHUB_TOKEN` used by Release Please does not trigger all
follow-on workflows in the same way a normal user action does. Expect to
manually re-run CI on the release PR when needed.

If that becomes painful at release time, move to a dedicated release token
with the minimum write scope needed for the workflow.

## Publish recovery path

`publish-hex.yml` exists as the manual recovery path. When using it:

1. Confirm the release version matches the intended tag.
2. Dry-run Hex packaging first.
3. Publish `rulestead` only when the release PR or release tag is the one
   intended for the milestone.
4. Publish `rulestead_admin` only after the admin guard confirms the real
   macro implementation exists.

The admin guard is structural. It prevents empty-package squatting by
blocking publication while `rulestead_admin/lib/rulestead_admin/router.ex`
still contains the Phase 1 stub.

## Deferred Phase 8 artifacts

Do not create these early:

- `guides/api_stability.md`
- `guides/cheatsheet.cheatmd`
- `guides/flows/extending-rulestead.md`

These files describe the locked public surface and extension points. They
belong to Phase 8, not bootstrap.

Until that surface is real, internal modules should prefer `@moduledoc false`.

## Required references for maintainers and agents

When working in this repo, read:

- `.planning/` for roadmap, requirements, and active phase context
- `prompts/` for anchor docs and implementation guardrails
- `rulestead/` and `rulestead_admin/` as sibling packages, not nested apps
