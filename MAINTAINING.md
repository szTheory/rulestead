# Maintaining Rulestead

## Release posture

Rulestead ships as a linked-version sibling-package monorepo:

- `rulestead`
- `rulestead_admin`

The release machine is intentionally semi-automated:

- `release-please.yml` still owns release PRs and tags.
- `publish-hex.yml` owns the irreversible Hex publish step.
- One explicit maintainer approval in the protected `hex-publish`
  environment is required before `HEX_API_KEY` is exposed to a publish job.
- Publish order is fixed: `rulestead` first, then `rulestead_admin`.

## Branch protection settings

Document these settings exactly on `main`:

- Required status checks:
  - `release_gate` (aggregates `lint`, `test`, and `integration-placeholder`
    from `ci.yml`)
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

The release metadata is seeded so the linked tags stay predictable:

- `rulestead-vX.Y.Z`
- `rulestead_admin-vX.Y.Z`

When Release Please cuts a real release, it dispatches `publish-hex.yml`
with both tags and the shared release version.

## Manual reruns and GitHub token caveat

The default `GITHUB_TOKEN` used by Release Please does not trigger all
follow-on workflows in the same way a normal user action does. If the
dispatch from `release-please.yml` to `publish-hex.yml` fails, use the
manual recovery path below instead of trying to publish ad hoc from a
workstation.

If that becomes painful at release time, move to a dedicated release token
with the minimum write scope needed for the workflow.

## Gated publish choreography

The expected v0.1.0 release path is:

1. Merge the Release Please PR for the intended version.
2. Let `release-please.yml` create the linked tags and dispatch
   `publish-hex.yml`.
3. Let the publish preflight re-run the release gate and the fresh Phase 7
   sibling-package admin slice from `rulestead_admin`.
4. Review the `preflight` job output and approve the protected
   `hex-publish` environment.
5. Let `publish-core` publish `rulestead`.
6. Let `publish-admin` publish `rulestead_admin`.
7. Hand off to the separate post-publish verification wave. Do not claim
   live artifact proof before that follow-on verification completes.

The preflight rerun matters because the 2026-04-24 Phase 7 verification
work closed the actor-bearing simulation contract in `07-11`; release
readiness still has to re-run that sibling-package slice instead of trusting
stale reports.

## Manual recovery path

`publish-hex.yml` is also the manual recovery path if the automated handoff
fails after the release PR or tags are already correct.

When using the workflow manually:

1. Supply `core_tag`, `admin_tag`, and `release_version` from the linked
   release (`rulestead-vX.Y.Z` and `rulestead_admin-vX.Y.Z`).
2. Let `preflight` finish before approving `hex-publish`.
3. If `publish-core` succeeds and `publish-admin` fails, rerun
   `publish-hex.yml` with the same inputs and monitor the admin guard
   closely.
4. If a tag is wrong, stop and cut a corrected release rather than trying to
   publish from an untagged commit.

The admin guard is structural. It prevents empty-package squatting by
blocking publication while `rulestead_admin/lib/rulestead_admin/router.ex`
still contains the earlier guarded stub text. It is not a substitute for
human review of the publish run.

## Post-publish verification handoff

Hex publish completion is not the end of the release checklist.

After publish succeeds, continue into the dedicated post-publish verification
wave and run the live artifact checks there:

- `mix verify.release_publish <version>`
- `mix verify.release_parity <version>`

That wave is where live Hex / HexDocs proof belongs. This publish plan stops
at ordered publication plus the explicit handoff so the irreversible step and
the live verification step stay auditable.

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
