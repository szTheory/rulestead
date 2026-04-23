# Phase 1 Discussion Log

**Date:** 2026-04-23
**Mode:** discuss-all + subagent research (advisor mode)
**Participants:** User (principal), Claude (facilitator), 4 research subagents

## Process

User requested deep research across all 6 identified gray areas simultaneously, with explicit directive: *"think deeply one-shot a perfect set of recommendations so i dont have to think, all recommendations are coherent/cohesive with each other and move us toward the goals/vision of this project... using great software architecture/engineering, principle of least surprise and great UI/UX where applicable great dev experience."*

Four parallel research agents were dispatched in readonly mode:
1. **Cluster A** — monorepo layout + release-please shape + `rulestead_admin` Phase 1 content (treated as one coupled decision)
2. **CI lane breadth** — which `.github/workflows/*.yml` files ship day 1 vs later phases
3. **Dialyzer + PLT** — Phase 1 vs Phase 8 timing, flag set, matrix cell coverage
4. **Docs skeleton depth** — how much real content vs stubs vs deferred

Each agent was given: full project context, explicit options to evaluate, evaluation lenses (ecosystem idioms, DX, lessons from analogous libs, coherence with project vision, principle of least surprise), required output shape (executive recommendation + comparison tables + ecosystem evidence + footguns + deferrals), and instruction to be **opinionated** rather than hedge.

## Gray Areas Presented (before research)

1. **Monorepo layout shape** — sibling dirs day 1 (A), single-then-split (B), Mix umbrella (C)
2. **Release-please config shape** — linked-versions day 1 (A), single-package-then-migrate (B), separate-pull-requests (C)
3. **`rulestead_admin` Phase 1 content** — empty-publishable (A), skeleton-unpublished (B), no-dir-yet (C)
4. **CI lane breadth** — full surface day 1 stubbed (A), minimal gates (B), everything-except-verify (C), staggered (D)
5. **Dialyzer timing** — enable Phase 1 every cell (A), defer to Phase 8 (B), advisory Phase 1 (C), single-cell Phase 1 (D)
6. **Docs skeleton depth** — real skeleton everywhere (A), thin placeholders (B), mixed root-full-guides-thin (C), progressive per-phase (D)

## Resolutions

### 1+2+3 — Monorepo + Release-Please + Admin Content (treated as one coupled decision)

**Resolved to 1A + 2A + 3B** — true sibling directories from day 1, linked-versions release-please config from commit 1, `rulestead_admin` exists as skeleton but is never published to Hex until Phase 8 (when real UI from Phases 6–7 populates it).

**Key reasoning (synthesized from Research Agent 1):**

- PROJECT.md key decision table explicitly specifies "Sibling packages from day 1 with linked-versions release-please." The anchor doc's §3.1 "start lean" advice predates PROJECT.md's lock-in and is **superseded**.
- The same author already shipped this exact pattern in **accrue** (latest tag: `accrue_admin-v0.1.2`). The lockstep-fallback bash block for release-please is already debugged and proven. Rulestead is the second iteration, not the first.
- The coherent pairs are `(1A, 2A, 3B)` OR `(1B, 2B, 3C)` — everything else is incoherent. Between those, `(1A, 2A, 3B)` is strictly better because going from Phase-1-shape to Phase-8-shape is **linear feature addition** (just fill in `rulestead_admin/lib/` with LiveView code). The alternative pair requires a mid-milestone refactor: create sibling directory, rewrite both `mix.exs`, change `package.files` whitelist, migrate release-please config from single-package to linked-versions, bootstrap `release-please-manifest.json` with correct per-component versions, accept a tag-namespace discontinuity (`v0.x.y` → `rulestead-vX.Y.Z`), update every `source_url` / `source_ref`, audit every cross-reference.
- Option 3A (publish empty admin at v0.1.0) is **ruled out** by Hex.pm Code of Conduct: *"publishing an empty package to 'reserve' a name, is not allowed."* Option 3B respects this because the first admin publish happens at Phase 8 when the tarball contains real UI content.
- Known release-please linked-versions bugs (googleapis/release-please#1750, #2707, #1456, #1360) **do not bite** Elixir projects: `#2707` is node-workspace-plugin-specific; `#1750` is solved by `include-component-in-tag: true` (which anchor doc specifies); `#1456` is solved by setting both `group-pull-request-title-pattern` AND `pull-request-title-pattern` (accrue has this); `#1360` (empty-commits) is exactly what the lockstep-fallback bash block handles.
- Ecosystem convergence: Flipper Ruby (the de-facto Ruby feature-flag lib) uses the **same sibling-monorepo + linked-versions shape** with shared `lib/flipper/version.rb`. Validates the layout. Oban/ash each use *separate repos per package* (Oban+oban_web+oban_met in three GitHub repos) — works for a team, too much overhead for a solo-author OSS lib.

**Discipline rule locked for downstream phases:** NEVER merge a release-please PR during Phases 1–7. The PR stays open and advisory. First merge is the v0.1.0 ship at Phase 8. Defensive guard in `publish-hex.yml` ensures admin publish is skipped if `rulestead_admin/lib/rulestead_admin/router.ex` still contains the stub (not the real `defmacro rulestead_admin` body).

### 4 — CI Lane Breadth: Option C modified (7 workflow files day 1)

**Resolved:** seven workflows at Phase 1 — `ci.yml` (lint + test matrix + `release_gate` aggregator, with `integration-placeholder` echo job), `release-please.yml`, `publish-hex.yml` (inert `workflow_dispatch`), `pr-title.yml`, `dependabot-automerge.yml`, `dependency-review.yml`, `actionlint.yml`. Installer-specific jobs (`installer_path_gate`, `installer_golden`) land in Phase 5 alongside the installer. `verify-published-release.yml` daily drift cron lands in Phase 8 alongside the first publish.

**Key reasoning (synthesized from Research Agent 2):**

- **No false-green theater** — every day-1 workflow runs and gates something real. The two deferrals are exactly the two workflows whose gated feature doesn't exist yet (installer code at Phases 1–4, published Hex tarball at Phases 1–7).
- `release_gate` aggregator pattern is **the single most load-bearing stability property**: branch protection pins only to `release_gate`, and later phases grow its `needs:` array freely with zero branch-protection ripples.
- Shipping `release-please.yml` from day 1 avoids the known bootstrap pain: manifest backfill against live history, CHANGELOG retrofit, the `GITHUB_TOKEN`-won't-re-trigger-CI discovery (documented GHA limitation, surprises every first-time release-please user).
- Workflow count calibration: 1-of-3 Dashbit libs (Oban, Ecto, Broadway) ship a single `ci.yml` — minimum possible, but Dashbit house style is uniquely minimal. FunWithFlags (closest domain analog) ships 2 files. Tesla (closest release-engineering analog, release-please-driven) ships 5. Bandit ships 7 (each doing real work). **Seven is in range**; justified by the batteries-included release-engineering posture.
- Critical footguns avoided: use `dorny/paths-filter@v3` job-level `if:` conditionals, NOT workflow-level `paths-ignore`, for anything feeding `release_gate` (otherwise required-checks go permanent-Pending per GitHub docs). Seed `.release-please-manifest.json` + include `Release-As: 0.1.0` footer in bootstrap commit (otherwise release-please defaults to v1.0.0).

**One explicit user-deferred item:** `pr-title.yml` starts with `pull_request` trigger (simpler, safer for solo-maintainer phase). Switch to `pull_request_target` + locked-down permissions + no-checkout-step discipline when opening to external contributors (Phase 8-adjacent).

### 5 — Dialyzer: Modified Option D (strict single-cell in `lint` job, trimmed flags)

**Resolved:** Enable Dialyzer at Phase 1 as a blocking gate, but in the `lint` job (single-cell: Elixir 1.19.2 / OTP 28.1.2) — **not** in the `test` matrix. Use flags `[:error_handling, :extra_return, :missing_return]` (drop `:underspecs`). Drop `:iex` from `plt_add_apps`. Add `plt_core_path: "priv/plts"` + `ignore_warnings: ".dialyzer_ignore.exs"` + `list_unused_filters: true`. Commit empty `.dialyzer_ignore.exs`.

**Key reasoning (synthesized from Research Agent 3):**

- Ecosystem convergence: **Oban runs Dialyzer on one cell** (`if: ${{ matrix.lint }}`). Phoenix/Ecto/Broadway run no Dialyzer at all (Dashbit house style). Tesla runs on one pinned older cell. Bandit runs advisory with auto-evict. Absinthe (the outlier) runs every cell. Rulestead's philosophy is closer to Oban than Absinthe — **copy Oban**.
- Moving Dialyzer from `test` matrix to `lint` job saves ~2 CI min per PR with near-zero signal loss (OTP-26-only regressions are rare and caught by `test` matrix anyway).
- `:underspecs` is notoriously noisy on greenfield libraries (every `@spec` more permissive than inferred typing triggers it). OTP team guidance: it's a quality ratchet for mature APIs, not a baseline. Defer to v0.5 when `api_stability.md` surface is locked.
- `plt_core_path` is non-obvious but **load-bearing**: without it, Erlang/Elixir core PLTs live in `$MIX_HOME` and aren't covered by the `priv/plts` cache key — the single most common "my PLT cache isn't working" bug.
- `:ex_unit`, `:mix`, `:eex` in `plt_add_apps` are all real use-sites (test helpers reference `ExUnit.Callbacks`, Mix tasks reference `Mix.Project`/`Mix.Shell.IO`, installer renders templates via EEx). `:iex` has no current use site — drop YAGNI; re-add on warning.
- Retrofit risk at Phase 8 is real: landing Dialyzer on thousands of LOC historically produces hundreds of warnings + a "fix all or turn off strict" debate. Enable now when there's zero lib code; PLT pipeline is proven before real code arrives.

**Anchor doc drift captured as D-20:** `prompts/rulestead-release-engineering-and-ci.md` §2.4 specifies Dialyzer in the `test` matrix on every cell; this phase supersedes that. Update the anchor doc in Phase 8 as part of doc polish.

### 6 — Docs Skeleton Depth: "Option C-Plus"

**Resolved:** Root docs written in full (CONTRIBUTING, MAINTAINING, SECURITY, CODE_OF_CONDUCT, LICENSE, CLAUDE.md, AGENTS.md), README written in full with `⚠️ Pre-release` banner, guides scaffolded as minimal-but-valid stubs (3-minute "documented in Phase N" placeholders), Phase-8-only docs (`CONVENTIONS.md`, `cheatsheet.cheatmd`, `api_stability.md`, `extending-rulestead.md`) **deferred entirely — do not create as files**.

**Key reasoning (synthesized from Research Agent 4):**

- README pressure-tests the API design (Readme-Driven Development per Preston-Werner 2010 — uncontroversial OSS doctrine). Banner solves the honesty question. The one cascade cost (Phases 2–7 may tune the API requiring README edits) is worth the pressure-test value.
- Root docs are **policy docs** (not feature docs). Writing CONTRIBUTING/MAINTAINING/SECURITY at Phase 1 costs ~6 hours total and signals seriousness to Omar (OSS contributor persona) who may arrive at any commit.
- Phase-8-only docs document the **locked public surface** — creating them as stubs at Phase 1 either produces empty-looking broken docs OR speculative content that drifts through six phases of implementation. Both are strictly worse than silence. Wait until the surface exists.
- Guide stubs keep ExDoc IA locked (`mix docs --warnings-as-errors` green) at 3-minute cost per file; real writing lands in the phase that ships the feature (or Phase 8 for polish).
- Ecosystem evidence: **Oban v0.1.0 CHANGELOG literally reads "Initial release with base functionality."** Current guides forest (Testing, Troubleshooting, Upgrading, Reliability, Recipes, Smart Engines, Preparing for Production) evolved across 2.0 → 2.21. But **Oban's README has been dense and canonical since early releases**. This is exactly the C-Plus shape.
- Phase-1 doc workload: ~12–14 hours total, dominated by README (4h), CONTRIBUTING (2h), MAINTAINING (3h). Everything else is sub-20-minute stubs or zero.

**Full README shape locked in `<specifics>` section of CONTEXT.md** (drop-in template).

## Conflict Resolution

**One material conflict between research agents:**

- **Research Agent 1** (monorepo cluster): recommended linked-versions release-please from day 1.
- **Research Agent 2** (CI lane breadth): recommended single-package release-please now, migrate to linked-versions when admin is a separate Hex package ("footgun #10").

**Resolution: Research Agent 1 wins.**

Reasoning:
1. PROJECT.md key decision is explicit on linked-versions + sibling packages day 1 — authoritative.
2. Research Agent 1's argument is more ecosystem-grounded (cites accrue shipping the pattern successfully, cites specific release-please GitHub issues and confirms none apply to Elixir workspace plugin). Research Agent 2's critique is theoretical.
3. Research Agent 2's "separate CHANGELOGs will be backfilled twice" critique doesn't apply to our flow: both CHANGELOGs start empty at Phase 1, release PR stays unmerged until Phase 8, release-please populates both CHANGELOGs at the Phase 8 merge. No backfill happens.
4. The migration scar of switching tag namespace from `v0.1.0` to `rulestead-v0.1.0` later is concrete and expensive (breaks ExDoc `source_ref`, forces manifest surgery, creates CHANGELOG path discontinuity). The Phase 1 cost of shipping linked-versions-from-day-1 is small (copy accrue's proven config + lockstep-fallback bash).

Research Agent 2's overall CI structure recommendation (7 files, `release_gate` aggregator, deferred installer + verify workflows) is **fully compatible** with Research Agent 1's release-please decision — the only disagreement was the shape of `release-please-config.json` inside the workflow.

## Explicit User-Deferred Items (documented in CONTEXT.md `<deferred>` D-18, D-19 and above)

- `pr-title.yml` trigger mode (`pull_request` vs `pull_request_target`) — start simple, escalate when opening to external contributors.
- Release-please auth token (`GITHUB_TOKEN` vs fine-grained PAT) — start with default, escalate in Phase 8 if painful.
- `integration-placeholder` job inclusion — recommended YES to keep `release_gate.needs:` stable from Phase 1.

## Outcome

All 6 gray areas resolved with evidence-grounded recommendations. Zero genuine taste calls deferred to user.

`01-CONTEXT.md` written with full implementation decisions, canonical references (with MUST-READ flags), code context (empty — greenfield), specific ideas (README template + accrue/Oban/Tesla patterns to port), and deferred ideas (13 items with explicit phase targets).

**Ready to route to `plan-phase` workflow.**
