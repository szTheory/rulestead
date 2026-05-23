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
- The first public Hex release target is **after `v0.6.0`**, with **`v1.0.0`**
  reserved for GA hardening and stronger stability promises.

The sibling-package publish decision is intentional:

- `rulestead_admin` is published on Hex alongside `rulestead`
- `rulestead_admin` remains the mounted admin companion, not a standalone
  control-plane product

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

The expected first public Hex release path after `v0.6.0` is:

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

The preflight rerun matters because publish readiness must re-run the
sibling-package release slice instead of trusting stale reports from earlier
milestones.

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

After `publish-hex.yml` completes and both sibling packages are visible on Hex,
transition immediately into the live post-publish verification wave:

```bash
bash scripts/ci/verify_published_release.sh <version>
```

That wrapper is the canonical REL-03 / REL-04 entrypoint. It first confirms
that `rulestead` and `rulestead_admin` expose the requested version on Hex,
then runs the required trio in order:

1. `mix verify.workspace_clean`
2. `mix verify.release_publish <version>`
3. `mix verify.release_parity <version>`

Capture durable evidence from the live run:

- the full command output from `bash scripts/ci/verify_published_release.sh <version>`
- the live package URLs for `rulestead` and `rulestead_admin`
- the versioned HexDocs URL for `rulestead`
- confirmation that the fresh `mix new` consumer proof passed
- confirmation that the fresh `mix phx.new` admin mount/boot proof passed

Treat any failure here as a release blocker, not informational drift. A failed
`verify.release_publish` run means the published artifacts do not satisfy the
documented install or mount contract yet. A failed `verify.release_parity` run
means the Hex tarball differs from the tagged source and must be investigated
before the release can be considered verified.

## Lifecycle Release Surface

Phase 38 adds a lifecycle release surface that maintainers must verify
explicitly when closing the milestone or preparing later lifecycle-sensitive
releases.

The machine-backed lifecycle release surface is:

- root and sibling README lifecycle discoverability
- the shared `guides/flows/flag-lifecycle.md` narrative
- `mix rulestead.lifecycle` contract coverage
- mounted host-seam verification through `admin_mount_test.exs`

Do not treat this as a prose-only checklist. The lifecycle closeout requires a
machine-backed evidence artifact at
`.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md`.

That artifact should point to the exact `mix test` commands, `rg` checks, and
pass outputs used to verify the lifecycle release surface.

## Timing expectations

Do not use the existence of the release workflows alone as the signal to ship.

The first public Hex release should happen only after:

1. `v0.6.0` is shipped and verified.
2. The multi-environment compare/promote and import/export seams are documented
   well enough for early adopters to use honestly.
3. The mounted-admin posture is clear in `README.md`, `rulestead/README.md`,
   and `rulestead_admin/README.md`.
4. The post-publish verification wave is ready to prove both sibling packages
   from live Hex artifacts.

`v1.0.0` remains the point for GA framing: RBAC, API lockdown, and hardening.

The recurring drift monitor lives in `.github/workflows/verify-published-release.yml`.
It reuses the same shell entrypoint on a daily cron and on manual dispatch,
resolves the latest shared stable sibling release from Hex, and opens or updates
one rolling GitHub issue only when published verification actually fails or the
sibling versions drift out of lockstep. Before the first live publish exists,
the workflow exits cleanly instead of opening a false-positive drift issue.

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
