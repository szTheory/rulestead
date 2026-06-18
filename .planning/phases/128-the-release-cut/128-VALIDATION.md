---
phase: 128
slug: the-release-cut
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 128 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 128 is an OPERATIONAL release cut — "tests" are CI scripts, `grep`/`curl`
> assertions, and a small set of mandatory human gates. No new runtime code.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix tasks (`mix verify.*`) + Bash scripts + `grep`/`curl` assertions |
| **Config file** | `release-please-config.json`, `.release-please-manifest.json`, `scripts/ci/verify_published_release.sh` |
| **Quick run command** | `grep '"release-as"' release-please-config.json` (config-state check) |
| **Full suite command** | `bash scripts/ci/verify_published_release.sh 1.0.0` |
| **Estimated runtime** | verify-trio ~2–5 min (network: Hex API + HexDocs CDN) |

---

## Sampling Rate

- **After every config edit commit:** Run the relevant `grep` assertion on `release-please-config.json` / manifest.
- **Pre-cut gate (before opening the release PR):** `bash scripts/ci/local.sh` green; `release_contract_test.exs` green; `mix hex.build` tarball contains logo SVGs.
- **Post-publish gate:** `bash scripts/ci/verify_published_release.sh 1.0.0` must exit 0.
- **Max feedback latency:** verify-trio bounded by Hex/HexDocs CDN propagation (can lag minutes after publish).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 128-pre | — | 0 | gate | — | Pre-cut entry gate green before any cut step | script | `bash scripts/ci/local.sh` | ✅ | ⬜ pending |
| 128-01 | 01 | 1 | REL-01 | — | Auto-merge disabled BEFORE `release-as` lands | manual | GitHub Actions UI → `release-pr-automerge` → Disable | N/A | ⬜ pending |
| 128-01 | 01 | 1 | REL-01 | — | `release-as: 1.0.0` present in `rulestead` block only | grep | `grep -A1 '"release-as"' release-please-config.json` | ✅ | ⬜ pending |
| 128-01 | 01 | 1 | REL-01 | — | Release PR bumps BOTH `@version "1.0.0"` + manifest + preamble | manual | Human eyeball PR diff | N/A | ⬜ pending |
| 128-02 | 02 | 2 | REL-04 | — | Maintainer hand-merges PR; approves `hex-publish` env | manual | GitHub PR merge + environment approval | N/A | ⬜ pending |
| 128-02 | 02 | 2 | REL-04 | — | `rulestead@1.0.0` live on Hex | curl | `curl -fsS https://hex.pm/api/packages/rulestead/releases/1.0.0` | ✅ | ⬜ pending |
| 128-02 | 02 | 2 | REL-04 | — | `rulestead_admin@1.0.0` live on Hex | curl | `curl -fsS https://hex.pm/api/packages/rulestead_admin/releases/1.0.0` | ✅ | ⬜ pending |
| 128-02 | 02 | 2 | REL-04 | — | Post-publish verify-trio green | script | `bash scripts/ci/verify_published_release.sh 1.0.0` | ✅ | ⬜ pending |
| 128-03 | 03 | 3 | REL-06 | — | `release-as` REMOVED from config | grep | `grep '"release-as"' release-please-config.json \|\| echo clean` | ✅ | ⬜ pending |
| 128-03 | 03 | 3 | REL-06 | — | Auto-merge re-enabled | manual | GitHub Actions UI → `release-pr-automerge` → Enable | N/A | ⬜ pending |
| 128-03 | 03 | 3 | REL-06 | — | MAINTAINING.md documents `bump-*-pre-major` now no-ops | grep | `grep -i 'no-op' MAINTAINING.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — `scripts/ci/verify_published_release.sh`,
`scripts/ci/local.sh`, `release_contract_test.exs`, and the release-please/publish-hex workflow
chain already exist (built and exercised in prior phases). No test scaffolding to install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Disable release-PR auto-merge before the cut | REL-01 | GitHub Actions UI toggle; no commit | Actions → `release-pr-automerge.yml` → ⋯ → Disable workflow |
| Eyeball the release PR diff | REL-01 | Human judgment on irreversible publish | Confirm both `@version "1.0.0"`, manifest both `1.0.0`, CHANGELOG preamble present |
| Hand-merge the release PR | REL-04 | Deliberate human action (auto-merge disabled) | Merge only after diff eyeball passes |
| Approve the `hex-publish` environment | REL-04 | GitHub environment protection gate | Approve the pending deployment in the publish run |
| Re-enable auto-merge | REL-06 | GitHub Actions UI toggle | Actions → `release-pr-automerge.yml` → Enable workflow |

---

## Validation Sign-Off

- [ ] All tasks have an automated assertion OR a documented manual gate
- [ ] Sampling continuity: each task has a verify command or explicit human gate
- [ ] No watch-mode flags
- [ ] Post-cut cleanup (REL-06) has its own verify pass so `release-as` is provably removed
- [ ] `nyquist_compliant: true` set in frontmatter (after planner wires verify into PLAN.md)

**Approval:** pending
