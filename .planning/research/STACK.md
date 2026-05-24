# Technology Stack: Rulestead v1.3.0 - Adopter Truth & Proof Closure

**Project:** Rulestead v1.3.0 - Adopter Truth & Proof Closure
**Researched:** 2026-05-24

## Recommended Stack

### Core Platform (Carry Forward)

| Technology | Current Repo Posture | Purpose | Milestone Guidance |
|------------|----------------------|---------|--------------------|
| Elixir / Phoenix / Ecto | Existing monorepo baseline | Runtime, admin mount, authored-state persistence | Keep the existing stack; this milestone is about truth and parity, not framework churn. |
| GitHub Actions | Existing CI surface | Release proof and support-truth verification | Prefer fixing current CI/test truth over adding new lanes or platform complexity. |
| ExUnit / LiveViewTest / contract tests | Existing proof surface | Public contract verification for core and mounted admin | Treat failing contract tests as milestone-defining evidence, not incidental test debt. |
| Docker Compose demo | Existing local proof path | Adopter-facing end-to-end proof | Preserve the demo as a release-truth surface and keep docs aligned with what it actually proves. |

### Companion Surfaces

| Surface | Classification | Purpose | Milestone Guidance |
|---------|----------------|---------|--------------------|
| `rulestead` | `core` | Runtime evaluator, installer, migration contract, lifecycle/ownership authored shape | This is the source of truth for install, schema, and release posture. |
| `rulestead_admin` | `companion` | Mounted operator UI and host-facing policy/session seam | Keep it mounted-only; do not widen into a standalone control plane. |
| `open_feature_rulestead` | `companion` | Optional OpenFeature bridge | Keep the bridge proof runnable and documented, but do not let it redefine core release posture. |
| `guides/` + package READMEs | `core support surface` | Adopter onboarding, release claims, lifecycle guidance | Docs must match the shipped post-`v1.0.0` state exactly. |

### Supporting Tooling To Favor

| Tooling | Why It Fits This Milestone |
|---------|----------------------------|
| Targeted contract tests | Fastest way to close drift between docs, migrations, and UI contract claims. |
| Existing Mix verification tasks | The repo already treats release parity and publish verification as support-truth gates. |
| Installer goldens / host-seam checks | Prevent docs and generator guidance from outrunning the actual host integration path. |

## Alternatives Rejected

| Option | Why Not Now |
|--------|-------------|
| New rollout or targeting features | Would widen scope before the current release story is coherent. |
| New CI platforms or hosted proof environments | Solves the wrong problem; the issue is drift in the existing truth surfaces. |
| Treating `open_feature_rulestead` as docs-only | Leaves a public companion surface in a half-supported state and preserves adopter confusion. |

## Milestone Stack Guidance

- Prefer additive migration backfills and installer parity over schema redesign.
- Prefer bounded verification recovery over expanding the release matrix.
- Prefer repo-local proof that a serious adopter can run today over aspirational future release language.

## Sources

- `.planning/threads/2026-05-24-next-milestone-assessment.md`
- `.planning/threads/2026-05-24-proof-posture-drift.md`
- `prompts/rulestead-release-engineering-and-ci.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `prompts/rulestead-host-app-integration-seam.md`
