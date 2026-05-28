# Thread: Release Readiness (2026-05-28)

## Status

- **Complete** for 0.1.1 — merge, Hex publish, verify trio all green (2026-05-28).
- Successor handoff: `.planning/threads/2026-05-28-post-0.1.1-handoff.md`

## What shipped in this pass

- **CI:** `adopter contract (post-GA band)` job runs `post_ga_band_closure` → `mix verify.phase76` on every merge (including docs-only via `release_gate`).
- **Publish:** `gate-ci-green` blocks Hex publish unless `ci.yml` succeeded on the tagged SHA; preflight no longer fakes `lint=success test=success`.
- **Post-publish:** `handoff-post-publish` dispatches `verify-published-release.yml` with `release_version`.
- **Docs:** README local demo section, v1.11 closure line, spine `environment_key: "dev"`, upgrading `mix verify.adopter`.

## Operator checklist (Wave 3)

### 1. Land CI hardening on `main`

```bash
# After commit/push of this pass:
git push origin main
```

Wait for green `ci.yml` including **adopter contract (post-GA band)**.

### 2. Release Please

- Let [release-please.yml](../../.github/workflows/release-please.yml) open/update the linked release PR.
- Expect **0.2.0** (or next minor) given volume since `0.1.0` — review both changelogs.
- **Before merge:** `workflow_dispatch` **ci.yml** on the release PR head ref if bot checks are missing (see ci.yml comment).

### 3. Merge release PR → publish

- Merge releases tags `rulestead-vX.Y.Z` / `rulestead_admin-vX.Y.Z`.
- `dispatch-publish` queues `publish-hex.yml`.
- Approve **`hex-publish`** environment after `preflight` + **`gate-ci-green`** are green.

### 4. Post-publish verify (release blocker)

```bash
bash scripts/ci/verify_published_release.sh <version>
```

Or manually:

```bash
cd rulestead && mix verify.workspace_clean
cd rulestead && mix verify.release_publish <version>
cd rulestead && mix verify.release_parity <version>
```

`verify-published-release.yml` should also run via handoff dispatch.

### 5. Optional smoke

```bash
scripts/demo/proof.sh
```

## Local proof (pre-push)

```bash
cd rulestead && mix verify.adopter
RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh
```

## Sources

- [2026-05-28-post-v1.11-milestone-next-step-assessment.md](2026-05-28-post-v1.11-milestone-next-step-assessment.md)
- [MAINTAINING.md](../../MAINTAINING.md)
