# Phase 128: The Release Cut — Research

**Researched:** 2026-06-18
**Domain:** Release engineering — release-please config, GitHub Actions workflow chain, Hex publish pipeline
**Confidence:** HIGH (all findings read directly from repo files; no web research required)

---

## Summary

Phase 128 is a purely operational release cut: no new runtime code, no schema changes. The
entire phase is a sequence of config edits, human gates, and a CI pipeline that was purpose-built
for exactly this scenario. Every piece of the machinery — the `release-as` config key, the
linked-versions propagation, the `hex-publish` environment gate, the verify-trio script — already
exists and has been exercised. The plan's job is to walk through that machinery in the correct
order without skipping any gate.

The critical invariant: `"release-as": "1.0.0"` MUST be added to the `rulestead` block ONLY
(linked-versions propagates to `rulestead_admin` automatically) AND MUST be removed immediately
after the release PR merges, or release-please will re-propose `1.0.0` forever.

Auto-merge MUST be disabled before the `release-as` key lands. This ordering is mandatory because
once the config is committed and pushed, release-please will open or update the PR, and CI could
complete and auto-merge it before the human has a chance to eyeball the diff.

**Primary recommendation:** Follow the exact ordered sequence below. Every human-gated step is
marked `[HUMAN GATE]`. Do not reorder steps.

---

<user_constraints>
## User Constraints (from CONTEXT.md / STATE.md Locked Decisions)

### Locked Decisions
- All three packages publish at `1.0.0`; `rulestead` + `rulestead_admin` via release-please
  linked-versions; `open_feature_rulestead` is a SEPARATE manual publish in Phase 129 — NOT this phase.
- `"release-as": "1.0.0"` is the ONLY mechanism to force `1.0.0` under `bump-minor-pre-major: true`
  + `bump-patch-for-minor-pre-major: true`. A `feat!:` commit would yield only `0.2.0`.
- Zero breaking changes; "promotion, not rewrite" CHANGELOG framing. The preamble was pre-authored
  in Phase 125 and lives at `brandbook/CHANGELOG-PREAMBLE-1.0.md`.
- Human checkpoints (mandatory): disable auto-merge BEFORE adding `release-as`; hand-eyeball the
  release PR diff (both `@version`, manifest, CHANGELOG preamble); approve the `hex-publish`
  environment manually.
- POST-CUT: REMOVE `"release-as"` immediately or release-please re-proposes `1.0.0` forever.
- Do NOT touch `open_feature_rulestead` in this phase.
- Phases 124–127 (all pre-cut work) MUST be complete before Phase 128 starts.

### Claude's Discretion
- None noted for this phase — every step is prescribed.

### Deferred Ideas (OUT OF SCOPE)
- `open_feature_rulestead` publish (Phase 129).
- Any runtime API or schema changes.
- Any renames or "last clean break" refactors.
- v2 feature wedges (GOV-02-ext, ROL-08, ADM-06).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Add `"release-as": "1.0.0"` to the `rulestead` block in `release-please-config.json`; disable release-PR auto-merge for the cut; verify the release PR diff bumps BOTH linked packages to `@version "1.0.0"` before a deliberate hand-merge. | Exact config key and JSON placement documented below; automerge workflow mechanics documented; diff checklist provided. |
| REL-04 | `rulestead` and `rulestead_admin` published at `1.0.0` via the gated release-please pipeline; post-publish verify-trio (`scripts/ci/verify_published_release.sh 1.0.0`) green. | Full pipeline trigger chain documented; verify-trio internals documented; exact invocation commands provided. |
| REL-06 | Post-cut cleanup — remove `"release-as"` from config; re-enable release-PR auto-merge; document the now-no-op `bump-*-pre-major` flags. | Post-cut file targets and re-enable steps documented; no-op flag explanation sourced from MAINTAINING.md. |
</phase_requirements>

---

## Project Constraints (from CLAUDE.md)

- Preserve the sibling-package layout. Do not collapse work into a single package.
- `.planning/` is the active source of truth.
- `prompts/` is the pattern and policy reference set.
- Prefer narrow, auditable changes.
- Post-GA band (v1.1–v1.9) is feature-complete; v2 work requires an explicit new milestone.
- `rulestead_admin` is a mounted companion, not a standalone control plane.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Force version to 1.0.0 | Config (`release-please-config.json`) | — | `release-as` config key overrides commit-convention version calculation |
| Linked-versions propagation | release-please plugin | `release-please.yml` job | `linked-versions` plugin ensures both packages in the manifest move atomically |
| Auto-merge gate | `.github/workflows/release-pr-automerge.yml` | GitHub Actions `workflow_run` trigger | Workflow fires when `ci` completes on a `release-please--*` branch |
| Human approval gate | GitHub Actions Environment (`hex-publish`) | `publish-hex.yml` `approval` job | Environment requires manual approval before HEX_API_KEY is exposed |
| Hex publish (core) | `publish-hex.yml` job `publish-core` | — | Publishes `rulestead` first; idempotent (checks Hex API before publishing) |
| Hex publish (admin) | `publish-hex.yml` job `publish-admin` | — | Requires `publish-core` to complete; `RULESTEAD_ADMIN_HEX_RELEASE=1` set |
| Post-publish verification | `verify-published-release.yml` + `scripts/ci/verify_published_release.sh` | `scripts/ci/check_docs_published.sh` | Dispatched automatically by `handoff-post-publish` job after admin publishes |
| CHANGELOG preamble | Human manual step on release PR | `brandbook/CHANGELOG-PREAMBLE-1.0.md` | release-please manages CHANGELOG.md; preamble is hand-added to the PR |

---

## Current State Verification (Read Directly from Repo)

| File | Current Value | Expected After Release PR Merges |
|------|--------------|----------------------------------|
| `.release-please-manifest.json` `.rulestead` | `"0.1.7"` | `"1.0.0"` |
| `.release-please-manifest.json` `.rulestead_admin` | `"0.1.7"` | `"1.0.0"` |
| `rulestead/mix.exs` `@version` | `"0.1.7"` | `"1.0.0"` |
| `rulestead_admin/mix.exs` `@version` | `"0.1.7"` | `"1.0.0"` |
| `release-please-config.json` `rulestead` block | No `release-as` key | Add `"release-as": "1.0.0"` temporarily; remove after cut |

---

## Operational Sequence (Authoritative)

Each step below maps to a planner task. Steps marked `[HUMAN GATE]` cannot be automated.

### Step 1: Disable auto-merge [HUMAN GATE]

**What to do:** Disable the `release-pr-automerge` workflow in the GitHub repository UI so it
cannot fire while the 1.0.0 PR is open.

**How:** In the GitHub web UI, go to Actions → release-pr-automerge → disable workflow.

Alternatively (equivalent): add a temporary `if: false` condition to the `automerge` job in
`.github/workflows/release-pr-automerge.yml` and push to `main` before adding `release-as`.

**Why this step is first:** The `release-pr-automerge.yml` workflow triggers on `workflow_run`
when `ci` completes with `conclusion == 'success'` on a `release-please--branches--main` branch.
If auto-merge fires before the human eyeballs the diff, `1.0.0` would be cut and published without
the mandatory human review.

**Verify:** Confirm the workflow shows "Disabled" in the Actions UI before proceeding to Step 2.

---

### Step 2: Add `release-as` to config

**File:** `release-please-config.json`

**Exact JSON edit** — add `"release-as": "1.0.0"` inside the `"rulestead"` package block:

```json
"packages": {
  "rulestead": {
    "component": "rulestead",
    "release-type": "elixir",
    "package-name": "rulestead",
    "changelog-path": "rulestead/CHANGELOG.md",
    "include-component-in-tag": true,
    "release-as": "1.0.0"
  },
  "rulestead_admin": {
    ...
  }
}
```

**Do NOT add `release-as` to the `rulestead_admin` block.** The `linked-versions` plugin propagates
the version from `rulestead` to `rulestead_admin` automatically. Adding it to both blocks is
redundant at best and a landmine at worst (you'd have to remove both post-cut).

**Commit message:** Use a conventional commit that will be included in the release-please PR commit
bundle, e.g.:
```
chore: add release-as 1.0.0 for the major promotion cut
```

Push to `main`. This triggers `release-please.yml` on the `push: branches: [main]` event.

---

### Step 3: Wait for release-please to open (or update) the release PR

`release-please.yml` runs the `release-please` job, which calls the `googleapis/release-please-action`
action. With `release-as: "1.0.0"` in the `rulestead` block, it will:

1. Propose version `1.0.0` for `rulestead` (override from `release-as`).
2. Propagate `1.0.0` to `rulestead_admin` via the `linked-versions` plugin.
3. Update `.release-please-manifest.json` to `{"rulestead": "1.0.0", "rulestead_admin": "1.0.0"}` in the PR.
4. Rewrite `rulestead/mix.exs` `@version "0.1.7"` → `@version "1.0.0"`.
5. Rewrite `rulestead_admin/mix.exs` `@version "0.1.7"` → `@version "1.0.0"`.
6. Update both `CHANGELOG.md` files with a new `## 1.0.0` section from the accumulated
   `[Unreleased]` entries.

The PR head branch name will be: `release-please--branches--main`

After release-please opens the PR, `release-please.yml` also dispatches `release-pr-ci.yml`
(`dispatch-release-pr-ci` job), which in turn runs `ci.yml` on the release branch.

---

### Step 4: Hand-add the CHANGELOG preamble to the release PR [HUMAN GATE]

**Source file:** `brandbook/CHANGELOG-PREAMBLE-1.0.md`

The preamble text begins at the `## 1.0.0 — Promotion, not rewrite` heading. It is intentionally
NOT committed into either `CHANGELOG.md` — those are release-please managed. The preamble must
be manually edited into the release PR.

**How:** Push a commit to the `release-please--branches--main` branch that prepends the preamble
above the bot-generated `## [1.0.0]` heading in `rulestead/CHANGELOG.md` AND
`rulestead_admin/CHANGELOG.md`.

Note: pushing to the release PR branch triggers `release-pr-ci.yml` (on `push` to
`release-please--branches--main`), which redispatches `ci.yml` on that branch.

---

### Step 5: Eyeball the release PR diff [HUMAN GATE]

Before merging, confirm ALL of the following in the PR diff:

- [ ] `rulestead/mix.exs`: `@version "1.0.0"` (was `"0.1.7"`)
- [ ] `rulestead_admin/mix.exs`: `@version "1.0.0"` (was `"0.1.7"`)
- [ ] `.release-please-manifest.json`: both keys at `"1.0.0"` (was `"0.1.7"`)
- [ ] `rulestead/CHANGELOG.md`: new `## 1.0.0` section present; preamble text present above the bot bullets
- [ ] `rulestead_admin/CHANGELOG.md`: new `## 1.0.0` section present
- [ ] No files outside the expected set are touched (no source code, no runtime API changes)

**Note:** `release-please-config.json` itself (with the `release-as` key) is typically NOT in the
release PR diff — the config change lives on `main`; the PR is what release-please produces in
response to that config.

---

### Step 6: Verify `ci.yml` (release_gate) is green on the PR branch

`release-pr-automerge.yml` would normally do this automatically, but since we disabled it, check
manually that the `release_gate` job is green on `release-please--branches--main` before merging.

The `release_gate` job in `ci.yml` aggregates: `lint`, `test`, `integration-placeholder`,
`adopter contract (post-GA band)`, `mounted-proof`, and `openfeature-companion`.

---

### Step 7: Hand-merge the release PR [HUMAN GATE]

With auto-merge disabled, squash-merge the PR via the GitHub web UI.

The merge commit on `main` triggers `release-please.yml` again. This time release-please sees
both packages at the new version in the manifest and creates the paired git tags:
- `rulestead-v1.0.0`
- `rulestead_admin-v1.0.0`

And dispatches `publish-hex.yml` (`dispatch-publish` job in `release-please.yml`) with inputs:
- `core_tag`: `rulestead-v1.0.0`
- `admin_tag`: `rulestead_admin-v1.0.0`
- `release_version`: `1.0.0`

---

### Step 8: Monitor `publish-hex.yml` preflight and gate-ci-green

`publish-hex.yml` runs automatically. Its job sequence is:

1. **`preflight`** — checks out at `rulestead-v1.0.0`; runs `scripts/ci/admin_publish_guard.sh`;
   runs `scripts/ci/check_package_whitelist.sh` (`mix hex.build` dry-run for both packages);
   verifies `@version "1.0.0"` in both `mix.exs` files; re-runs the Phase 7 admin test slice.

2. **`gate-ci-green`** — resolves the SHA for `rulestead-v1.0.0`; polls (up to 30×30s = ~15 min)
   for a green `ci.yml` run on that SHA.

Both must succeed before the `approval` job becomes available.

---

### Step 9: Approve the `hex-publish` environment [HUMAN GATE]

Once `preflight` and `gate-ci-green` are green, GitHub pauses at the `approval` job, which
is gated by the `hex-publish` environment. A maintainer must click "Approve and deploy" in
the GitHub Actions UI for the `publish-hex.yml` run.

**How to find it:** Actions → publish-hex workflow run → `approval` job → "Review deployments".

---

### Step 10: Let `publish-core` and `publish-admin` run

After approval, the pipeline continues automatically:

- **`publish-core`** — checks out at `rulestead-v1.0.0`; runs `mix deps.get`; verifies
  `@version "1.0.0"` in `rulestead/mix.exs`; runs `mix hex.publish --dry-run` then
  `mix hex.publish --yes`. The step is idempotent: it first checks
  `https://hex.pm/api/packages/rulestead/releases/1.0.0` and skips if already published.

- **`publish-admin`** — checks out at `rulestead_admin-v1.0.0`; `RULESTEAD_ADMIN_HEX_RELEASE=1`
  is set (required for the admin package to build against the Hex version of rulestead rather
  than the path dep); verifies `@version "1.0.0"` in `rulestead_admin/mix.exs`; publishes.
  Also idempotent.

---

### Step 11: `handoff-post-publish` dispatches verify workflow

After `publish-admin` succeeds, the `handoff-post-publish` job dispatches
`verify-published-release.yml` with `release_version: "1.0.0"`.

---

### Step 12: Confirm the verify-trio passes

`verify-published-release.yml` calls `bash scripts/ci/verify_published_release.sh "1.0.0"`, which:

1. Queries `https://hex.pm/api/packages/rulestead` — asserts `1.0.0` is in the `.releases` list.
2. Queries `https://hex.pm/api/packages/rulestead_admin` — same check.
3. Runs `mix verify.workspace_clean` in `rulestead/` (workspace is clean, no dirty deps).
4. Runs `mix verify.release_publish "1.0.0"` in `rulestead/` (fresh consumer compiles against
   published `rulestead@1.0.0` from Hex).
5. Runs `mix verify.release_parity "1.0.0"` in `rulestead/` (tarball content matches tagged source).
6. Calls `bash scripts/ci/check_docs_published.sh "1.0.0"`:
   - Runs `RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors` in `rulestead_admin/`
     (admin docs build against published Hex core — only passable after core is live).
   - Asserts logo, favicon, and social card CDN URLs resolve with correct content-type.
   - Asserts the published README's `og:image` matches the expected CDN URL.

**Local fallback command:**
```bash
bash scripts/ci/verify_published_release.sh 1.0.0
```

Also useful for on-demand spot-check:
```bash
curl -fsS https://hex.pm/api/packages/rulestead/releases/1.0.0 | jq .version
curl -fsS https://hex.pm/api/packages/rulestead_admin/releases/1.0.0 | jq .version
```

---

### Step 13: Post-cut cleanup [HUMAN GATE partially]

**Step 13a — Remove `release-as` from config (CRITICAL):**

Edit `release-please-config.json` — remove the `"release-as": "1.0.0"` line from the `rulestead`
block. Commit and push to `main`.

If this is left in, release-please re-proposes `1.0.0` on every subsequent `push` to `main`,
which would create a spurious release PR that re-publishes `1.0.0` (idempotent due to the
`curl -fsS` guard in `publish-hex.yml`, but still wasteful and confusing).

**Step 13b — Re-enable auto-merge:**

Re-enable the `release-pr-automerge` workflow in the GitHub Actions UI. Future patch/minor
releases can flow automatically again.

**Step 13c — Document `bump-*-pre-major` flags as no-ops:**

The flags `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true` in
`release-please-config.json` are now no-ops — they only affect version calculation when the
current version is `< 1.0.0`. From `1.0.0` onward, ordinary semver applies. Add a comment
to `release-please-config.json` or update `MAINTAINING.md` to note this. MAINTAINING.md line
234 already documents this; confirm it is accurate post-cut (it is: the MAINTAINING.md
`## Cutting a major` section already states: "After the major lands, `bump-minor-pre-major` /
`bump-patch-for-minor-pre-major` become no-ops").

---

## Exact File/Line Targets

### Files edited in this phase

| File | Edit | When |
|------|------|------|
| `release-please-config.json` | Add `"release-as": "1.0.0"` to `packages.rulestead` block | Step 2 |
| `release-please-config.json` | Remove `"release-as": "1.0.0"` from `packages.rulestead` block | Step 13a (post-cut) |
| `rulestead/CHANGELOG.md` | Hand-add preamble from `brandbook/CHANGELOG-PREAMBLE-1.0.md` above bot-generated `## 1.0.0` heading | Step 4 (on release PR branch) |
| `rulestead_admin/CHANGELOG.md` | Hand-add preamble (same text) above bot-generated `## 1.0.0` heading | Step 4 (on release PR branch) |

### Files edited BY release-please (in the PR, do not pre-edit)

| File | Change |
|------|--------|
| `.release-please-manifest.json` | `"rulestead": "0.1.7"` → `"1.0.0"`, `"rulestead_admin": "0.1.7"` → `"1.0.0"` |
| `rulestead/mix.exs` | `@version "0.1.7"` → `@version "1.0.0"` |
| `rulestead_admin/mix.exs` | `@version "0.1.7"` → `@version "1.0.0"` |
| `rulestead/CHANGELOG.md` | New `## 1.0.0` section added with bot-generated bullets |
| `rulestead_admin/CHANGELOG.md` | New `## 1.0.0` section added with bot-generated bullets |

### Files NOT touched in this phase

- Any file under `lib/`, `test/`, `priv/` — no source changes.
- `open_feature_rulestead/` — out of scope (Phase 129).
- `.planning/` or `prompts/` — historically accurate; do not edit.
- `scripts/ci/verify_published_release.sh` — already correct.

---

## How `release-as` Propagates via `linked-versions`

The `linked-versions` plugin in `release-please-config.json` groups `rulestead` and
`rulestead_admin` under `"groupName": "rulestead-monorepo"`. When `release-as: "1.0.0"` is set
on `rulestead`, the plugin:

1. Reads the forced version (`1.0.0`) for the group's primary component (`rulestead`).
2. Applies the same version to the secondary component (`rulestead_admin`) regardless of its
   own accumulated commits.
3. Updates both `@version` lines and both `CHANGELOG.md` files in a single PR.
4. Updates both keys in `.release-please-manifest.json` to `"1.0.0"`.

The `release-please.yml` workflow's `lockstep` step (lines 41–81) manually reconciles the case
where release-please emits only `rulestead--release_created` (not `rulestead_admin--release_created`)
by checking if both manifest versions match and inferring the admin tag. This is a belt-and-suspenders
fix; with `linked-versions`, both should be emitted together.

---

## How Auto-merge Is Implemented (and How to Disable It)

`release-pr-automerge.yml` fires on:

```yaml
on:
  workflow_run:
    workflows: [ci]
    types: [completed]
```

The `automerge` job has an `if:` condition:
```yaml
if: >
  github.event_name == 'workflow_dispatch' ||
  (github.event.workflow_run.conclusion == 'success' &&
   startsWith(github.event.workflow_run.head_branch, 'release-please--'))
```

So it fires whenever `ci` completes successfully on a branch starting with `release-please--`.
It then verifies `release_gate` succeeded on the PR head SHA, finds the PR, and squash-merges it.

**To disable for the cut, choose ONE of:**

Option A (recommended — no code change): Disable the workflow in GitHub Actions UI:
`Actions → release-pr-automerge → "..." menu → Disable workflow`

Option B (requires a commit): Temporarily set the job-level `if: false` in the YAML. This
requires a push to `main` before the `release-as` commit, adding complexity.

Option A is cleaner because it leaves no temporary code change to revert and cannot be
accidentally committed with the wrong state.

**To re-enable:** Same UI path → "Enable workflow".

---

## `publish-hex.yml` — Environment Gate Details

The `approval` job:
```yaml
approval:
  name: approval
  needs:
    - preflight
    - gate-ci-green
  runs-on: ubuntu-24.04
  environment:
    name: hex-publish
  steps:
    - name: Await maintainer approval
      run: echo "Approval granted ..."
```

The `hex-publish` environment must be configured in GitHub repository Settings →
Environments → hex-publish → Required reviewers. This is a pre-existing configuration
(the pipeline has been in place since the repo's CI/CD work in Phase 119–123).

**HEX_API_KEY is only exposed to `publish-core` and `publish-admin` jobs** — it is NOT
available to `preflight`, `gate-ci-green`, or `approval`. Only the actual publish jobs
have `env: HEX_API_KEY: ${{ secrets.HEX_API_KEY }}`.

---

## The CHANGELOG Preamble — What It Is and Where It Goes

**File:** `brandbook/CHANGELOG-PREAMBLE-1.0.md`

**Content summary (from file):**
```
## 1.0.0 — Promotion, not rewrite

`rulestead` and `rulestead_admin` graduate to `1.0.0` together (linked versions).
This is the same battle-tested code that has been running in production — now
honestly versioned. Zero breaking changes.
[Three bullet points: no API changes, upgrade is dep-pin bump only, both sibling packages move together]
```

**Where it lands:** Hand-edited into the release PR branch. The target location in both
`CHANGELOG.md` files is **above** the bot-generated `## [1.0.0]` heading (or `## 1.0.0` —
confirm the bot's exact heading format when the PR opens).

**What it replaces:** Nothing. It is prepended above the bot's bullets.

**The bot-generated CHANGELOGs currently show** `## [Unreleased]` with accumulated entries:
- `rulestead/CHANGELOG.md`: adoption-lab feature, admin CSS fix, 3 documentation entries.
- `rulestead_admin/CHANGELOG.md`: admin CSS fix, 1 documentation entry.

Release-please will move these `[Unreleased]` entries under the new `## 1.0.0` heading.
The human then prepends the preamble above that heading.

---

## Verify Commands (Copy-Pasteable)

```bash
# 1. Pre-cut: dry-run release-please (offline mode; confirms contract checks pass)
bash scripts/ci/release_please_dry_run.sh

# 2. Pre-cut: run full local gate before adding release-as
bash scripts/ci/local.sh

# 3. Pre-cut: verify hex.build dry-run for both packages
cd rulestead && mix hex.build
cd ../rulestead_admin && RULESTEAD_ADMIN_HEX_RELEASE=1 mix hex.build

# 4. After merge: check Hex API for 1.0.0 (runs on live network)
curl -fsS https://hex.pm/api/packages/rulestead/releases/1.0.0 | jq .version
curl -fsS https://hex.pm/api/packages/rulestead_admin/releases/1.0.0 | jq .version

# 5. Post-publish: run the full verify-trio locally
bash scripts/ci/verify_published_release.sh 1.0.0

# 6. Post-publish: run the docs gate only
RULESTEAD_ADMIN_HEX_RELEASE=1 cd rulestead_admin && mix docs --warnings-as-errors

# 7. Confirm version in manifest post-cut cleanup
grep -r '"1.0.0"' .release-please-manifest.json release-please-config.json

# 8. Confirm release-as key is GONE from config post-cut
grep "release-as" release-please-config.json && echo "STILL PRESENT - REMOVE IT" || echo "clean"
```

---

## Landmines / Gotchas

### Landmine 1: Forgetting to remove `release-as` post-cut

**Impact:** CRITICAL. If `"release-as": "1.0.0"` is left in `release-please-config.json`,
every subsequent push to `main` causes release-please to re-open a `1.0.0` PR. The
`publish-hex.yml` idempotency guard (`curl -fsS` check) means a second publish would be
skipped, but the spurious PR and CI noise are severe. Maintainers might accidentally merge
the re-proposed PR and trigger another publish attempt.

**Prevention:** The post-cut cleanup step is the FIRST task in the cleanup wave. Add it as
a required verification step: `grep "release-as" release-please-config.json && echo STILL PRESENT`.

### Landmine 2: Adding `release-as` to BOTH package blocks

**Impact:** MEDIUM. Redundant but still works — however, you now have two keys to remove
post-cut, doubling the cleanup risk. More importantly, if you forget to remove one, the
behavior is the same as Landmine 1.

**Prevention:** Only add `"release-as": "1.0.0"` to the `rulestead` block. The
`linked-versions` plugin handles propagation.

### Landmine 3: Forgetting to disable auto-merge before adding `release-as`

**Impact:** HIGH. If auto-merge fires before the human eyeballs the diff, the release PR
is merged without the mandatory human review. The `1.0.0` tags are then created, and the
pipeline dispatches publish. By the time the mistake is noticed, the publish may be in
progress.

**Prevention:** Step 1 (disable auto-merge) must precede Step 2 (add `release-as`) with
no commits in between on `main`. Verify the workflow is disabled in the Actions UI before
committing the config change.

### Landmine 4: `RULESTEAD_ADMIN_HEX_RELEASE=1` missing for admin package builds

**Impact:** HIGH. The `rulestead_admin` package's `mix.exs` uses a conditional dep —
without `RULESTEAD_ADMIN_HEX_RELEASE=1`, it resolves `:rulestead` from the local path
(`../rulestead`), not from Hex. The `publish-admin` job already sets this env var. But
if anyone runs `mix hex.build` locally to preview the tarball, they must also set it:
`RULESTEAD_ADMIN_HEX_RELEASE=1 mix hex.build`.

### Landmine 5: The `@deprecated` + `--warnings-as-errors` footgun

**Impact:** LOW for this phase (no deprecations in scope). But note: the repo's `lint.sh`
runs `mix compile --warnings-as-errors`. If any `@deprecated` annotations were added to
the public surface without migrating internal callers, they would fail CI. The API audit
in Phase 124 found no warts — no new deprecations are being introduced in this phase. This
is a non-issue for Phase 128 specifically, but worth confirming the release PR's CI stays green.

### Landmine 6: Release-please dispatch-publish race condition

**Impact:** LOW (mitigated by `gate-ci-green` polling). When the release PR is hand-merged,
`release-please.yml` creates tags AND dispatches `publish-hex.yml` almost simultaneously.
There is a race where the publish workflow starts before `ci.yml` has run on the tagged SHA.
The `gate-ci-green` job mitigates this by polling up to 30 times × 30 seconds (~15 minutes)
for a `ci.yml` run on the tagged SHA. If `ci.yml` hasn't started in 15 minutes, it fails.

**Mitigation:** After merging the release PR, monitor the Actions tab. If `gate-ci-green`
polls and times out, manually dispatch `ci.yml` on the `rulestead-v1.0.0` tag ref:
```bash
gh workflow run ci.yml --ref rulestead-v1.0.0
```

### Landmine 7: `release_please_dry_run.sh` checks for `0.0.0` bootstrap manifest

**Impact:** LOW (not a blocker for the 1.0.0 cut). The `scripts/ci/release_please_dry_run.sh`
script has a bootstrap check that asserts the manifest contains `"rulestead": "0.0.0"`.
This was for the initial bootstrap and is no longer relevant (the manifest currently holds
`0.1.7`). The script exits early in offline mode if `RULESTEAD_RELEASE_PLEASE_TOKEN` is not
set — which is the expected behavior for local sanity checks. Do not use this script as a
gate for the 1.0.0 cut; it will fail on the `0.0.0` assertion. The pre-cut dry-run should
be a manual local `mix hex.build` + `bash scripts/ci/local.sh` instead.

### Landmine 8: linked-versions `lockstep` step in `release-please.yml`

**Impact:** LOW (awareness only). The `lockstep` step in `release-please.yml` manually
infers `rulestead_admin_release_created` if the `linked-versions` plugin emits only the
core's output. If both packages are in the same PR (which they should be with `linked-versions`),
both `rulestead--release_created` and `rulestead_admin--release_created` will be `"true"` from
the action's native output. The `lockstep` step is belt-and-suspenders. Watch the
`release-please.yml` run outputs to confirm `rulestead_admin_release_created=true` before
`dispatch-publish` runs.

---

## Code Examples

### Exact `release-please-config.json` After Edit (Step 2)

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "include-component-in-tag": true,
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "rulestead-monorepo",
      "components": ["rulestead", "rulestead_admin"]
    }
  ],
  "packages": {
    "rulestead": {
      "component": "rulestead",
      "release-type": "elixir",
      "package-name": "rulestead",
      "changelog-path": "rulestead/CHANGELOG.md",
      "include-component-in-tag": true,
      "release-as": "1.0.0"
    },
    "rulestead_admin": {
      "component": "rulestead_admin",
      "release-type": "elixir",
      "package-name": "rulestead_admin",
      "changelog-path": "rulestead_admin/CHANGELOG.md",
      "include-component-in-tag": true
    }
  }
}
```

### Exact `release-please-config.json` After Post-Cut Cleanup (Step 13a)

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "include-component-in-tag": true,
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "rulestead-monorepo",
      "components": ["rulestead", "rulestead_admin"]
    }
  ],
  "packages": {
    "rulestead": {
      "component": "rulestead",
      "release-type": "elixir",
      "package-name": "rulestead",
      "changelog-path": "rulestead/CHANGELOG.md",
      "include-component-in-tag": true
    },
    "rulestead_admin": {
      "component": "rulestead_admin",
      "release-type": "elixir",
      "package-name": "rulestead_admin",
      "changelog-path": "rulestead_admin/CHANGELOG.md",
      "include-component-in-tag": true
    }
  }
}
```

---

## Validation Architecture

Observable truths that prove the 1.0.0 cut succeeded. These map directly to verification tasks.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Mix tasks (`mix verify.*`) + Bash scripts |
| Config file | `rulestead/mix.exs` aliases; `scripts/ci/verify_published_release.sh` |
| Post-publish command | `bash scripts/ci/verify_published_release.sh 1.0.0` |
| Pre-cut local gate | `bash scripts/ci/local.sh` |

### Phase Requirements → Verification Map

| Req ID | Observable Truth | How to Verify | Automated? |
|--------|-----------------|---------------|-----------|
| REL-01 | `release-as` key is in `release-please-config.json` `rulestead` block | `grep "release-as" release-please-config.json` | Yes (grep) |
| REL-01 | Release PR diff shows `@version "1.0.0"` in BOTH `mix.exs` files | Human eyeball PR diff | HUMAN |
| REL-01 | Release PR diff shows `.release-please-manifest.json` both at `"1.0.0"` | Human eyeball PR diff | HUMAN |
| REL-01 | Release PR diff shows CHANGELOG preamble present | Human eyeball PR diff | HUMAN |
| REL-04 | `https://hex.pm/api/packages/rulestead/releases/1.0.0` returns HTTP 200 | `curl -fsS https://hex.pm/api/packages/rulestead/releases/1.0.0` | Yes (curl) |
| REL-04 | `https://hex.pm/api/packages/rulestead_admin/releases/1.0.0` returns HTTP 200 | `curl -fsS https://hex.pm/api/packages/rulestead_admin/releases/1.0.0` | Yes (curl) |
| REL-04 | Post-publish verify-trio green | `bash scripts/ci/verify_published_release.sh 1.0.0` | Yes (script) |
| REL-06 | `release-as` key is ABSENT from `release-please-config.json` | `grep "release-as" release-please-config.json \|\| echo clean` | Yes (grep) |
| REL-06 | `release-pr-automerge` workflow is re-enabled | Check GitHub Actions UI | HUMAN |

### Sampling Rate

- **Per step:** The verify commands listed in the Operational Sequence above.
- **Phase gate:** `bash scripts/ci/verify_published_release.sh 1.0.0` must exit 0 before this phase is marked verified.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Force version to 1.0.0 | Custom script to rewrite `mix.exs` directly | `"release-as": "1.0.0"` in `release-please-config.json` | release-please rewrite ensures CHANGELOG, manifest, and tags all update atomically |
| Publish packages to Hex | Manual `mix hex.publish` from a workstation | `publish-hex.yml` pipeline with `hex-publish` environment gate | Audit trail, idempotency guard, preflight checks, package whitelist verification, and Phase 7 admin slice re-run are all in the pipeline |
| Verify publish | Manual `mix deps.get && mix test` | `bash scripts/ci/verify_published_release.sh 1.0.0` | Full trio: Hex API visibility, workspace clean, release publish, release parity, docs CDN, admin hex-release docs |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `hex-publish` GitHub environment is already configured with required reviewers pointing at the maintainer account | Step 9: Approve hex-publish environment | If the environment has no required reviewers, `approval` job completes immediately without human intervention — the human gate disappears. Verify in Settings → Environments → hex-publish. |
| A2 | `RELEASE_PLEASE_TOKEN` secret is configured in the repo (otherwise `GITHUB_TOKEN` is used as fallback per the workflow `${{ secrets.RELEASE_PLEASE_TOKEN \|\| secrets.GITHUB_TOKEN }}`) | Steps 2-3 | With only `GITHUB_TOKEN`, bot-pushed commits to the release branch don't re-trigger PR checks natively. The `release-pr-ci.yml` workflow compensates by re-dispatching `ci.yml` on the branch. This is already the existing workaround. |
| A3 | `HEX_API_KEY` secret is configured in the repo and is a valid Hex.pm API key with publish rights | Step 10 | If the key is expired or missing, `publish-core` will fail. Check in Settings → Secrets → HEX_API_KEY before starting the cut. |

---

## Open Questions (RESOLVED — operational assumptions with embedded mitigations)

> All three are non-blocking: each is either answered inline or carries a documented
> fallback that the PLAN.md tasks already encode. No plan-blocking gaps remain.

1. **Is `hex-publish` environment configured?**
   - What we know: The workflow references `environment: name: hex-publish` and MAINTAINING.md
     says it requires "explicit maintainer approval."
   - What's unclear: Whether the environment is live with the correct reviewer(s) configured —
     the Phase 119 audit found branch protection was not applied (HTTP 404); the environment
     may have a similar gap.
   - Recommendation: Before Step 9, verify in GitHub Settings → Environments → hex-publish
     that at least one required reviewer is set.

2. **Does the `release-pr-ci.yml` `push` trigger fire for bot commits?**
   - What we know: The workflow triggers on `push` to `release-please--branches--main`. The
     header comment says "bot pushes do not re-fire pull_request" — that's why this workflow
     exists.
   - What's unclear: Whether the `push` trigger in `release-pr-ci.yml` fires for the
     release-please bot's commits (GITHUB_TOKEN-based pushes sometimes don't trigger other
     workflows).
   - Recommendation: After the release-please bot opens the PR in Step 3, check whether
     `ci.yml` is running on the branch. If not, manually dispatch it:
     `gh workflow run ci.yml --ref release-please--branches--main`

3. **`bump-*-pre-major` no-op documentation location**
   - What we know: MAINTAINING.md line 234 already states these become no-ops after 1.0.0.
   - What's unclear: Whether REL-06 requires a separate documentation commit or whether the
     existing MAINTAINING.md text is sufficient.
   - Recommendation: REL-06's documentation obligation is satisfied by the existing MAINTAINING.md
     text. No additional commit is required beyond confirming it is accurate (it is).

---

## Sources

All findings were read directly from the repo. No web research was performed. All claims are
`[VERIFIED]` from repo source files.

### Files Read

- `release-please-config.json` — config structure, `bump-*-pre-major` flags, package blocks
- `.release-please-manifest.json` — current versions (`0.1.7`)
- `.github/workflows/release-please.yml` — trigger chain, `lockstep` step, `dispatch-publish`
- `.github/workflows/release-pr-automerge.yml` — auto-merge trigger conditions, job logic
- `.github/workflows/release-pr-ci.yml` — release branch CI redispatch
- `.github/workflows/publish-hex.yml` — full publish pipeline: `preflight`, `gate-ci-green`,
  `approval` (environment gate), `publish-core`, `publish-admin`, `handoff-post-publish`
- `.github/workflows/verify-published-release.yml` — verify-trio dispatcher, drift issue management
- `scripts/ci/verify_published_release.sh` — actual verify-trio implementation
- `scripts/ci/check_docs_published.sh` — Phase 126 docs gate (called by verify-trio)
- `scripts/ci/release_gate.sh` — what the release_gate aggregator runs
- `scripts/ci/release_please_dry_run.sh` — offline contract mode + live dry-run tool
- `scripts/ci/local.sh` — local contributor gate
- `scripts/ci/admin_publish_guard.sh` — guards against router stub being published
- `scripts/ci/check_package_whitelist.sh` — cross-contamination guard
- `rulestead/mix.exs` — current `@version "0.1.7"`
- `rulestead_admin/mix.exs` — current `@version "0.1.7"`
- `rulestead/CHANGELOG.md` — current `[Unreleased]` state
- `rulestead_admin/CHANGELOG.md` — current `[Unreleased]` state
- `brandbook/CHANGELOG-PREAMBLE-1.0.md` — pre-authored 1.0.0 preamble text
- `MAINTAINING.md` — Cutting a major runbook (lines 189–260), gated publish choreography
- `.planning/STATE.md` — locked decisions, phase dependency map
- `.planning/REQUIREMENTS.md` — REL-01, REL-04, REL-06 definitions

---

## Metadata

**Confidence breakdown:**
- Operational sequence: HIGH — read directly from workflow files and MAINTAINING.md runbook
- Config edits: HIGH — exact JSON read from current repo state
- Verify commands: HIGH — extracted from shell scripts verbatim
- Environment gate state: MEDIUM (A1, A2, A3 are assumptions about secrets/env config, not readable from source)

**Research date:** 2026-06-18
**Valid until:** Indefinitely (repo-grounded; no external dependencies on third-party docs)
