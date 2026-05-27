# Phase 56: Proof, Docs, And Support Truth — Research

**Gathered:** 2026-05-27  
**Status:** Ready for planning  
**Milestone:** v1.6.0 — Reusable Targeting Deepening  
**Requirements:** VER-01, VER-02, VER-03

---

## Executive Summary

Phase 56 is a **closure phase**, not a feature phase. Phases 53–55 shipped the reusable-targeting deepening surface (impact previews, dependency truth, mounted operator workflows). Phase 56 must **prove**, **document**, and **guard** that work under the existing linked sibling-package release model — without adding product capability, Phase 8-only docs, or standalone `rulestead_admin` publish prep.

The established v1.3–v1.5 pattern applies: a per-phase `mix verify.phaseNN` merge gate, `release_contract_test.exs` string drift guards mirroring the `guarded_rollout_foundations` block, in-place guide edits, optional `RULESTEAD_TEST_SCOPE` in `scripts/ci/test.sh`, and phase-close artifacts (`56-VERIFICATION.md`, `56-HANDOFF-CHECKLIST.md`). Upstream boundary contracts live in `54-HANDOFF-CHECKLIST.md` and `55-HANDOFF-CHECKLIST.md`; Phase 56 docs and plans must cite them, not re-derive semantics.

**Primary maintainer entrypoint (locked in CONTEXT D-06):** `cd rulestead && mix verify.phase56`

---

## 1. Phase Scope Summary

### Goal (from ROADMAP)

The reusable targeting deepening surface is verified, documented, and supportable without drifting beyond the linked sibling-package release model.

### In scope

| Area | Deliverable | Requirement |
|------|-------------|-------------|
| Proof gate | `mix verify.phase56` — union of Phase 54 + 55 test paths + Phase 53 gaps | VER-01 |
| Drift guards | Extend `release_contract_test.exs` for v1.6 support truth | VER-02 |
| Public docs | Root `README.md`, `MAINTAINING.md`, package READMEs | VER-02 |
| Operator guides | In-place edits to `rulesets.md`, `explainability.md`, `admin-ui.md`, `multi-env.md` | VER-02 |
| Package boundaries | Continue asserting core owns domain; admin owns presentation; no `RulesteadAdmin` in core | VER-03 |
| Phase artifacts | `56-VERIFICATION.md`, `56-HANDOFF-CHECKLIST.md` | D-10 |
| Optional CI | `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening` in `scripts/ci/test.sh` | D-06 |

### Explicitly out of scope

- New runtime, store, or LiveView product behavior
- Hex version bump / v1.6.0 release choreography (deferred to `.planning/PROJECT.md`)
- Phase 8-only artifacts (`guides/cheatsheet.cheatmd`, `guides/flows/extending-rulestead.md` expansion)
- Standalone `rulestead_admin` publish preparation
- Replacing or modifying `mix verify.phase54` / `mix verify.phase55` behavior (D-02)
- Full `mix test` in default CI for every doc-only PR (v1.5 pattern preserved)

### Success criteria mapping

1. **Maintainer can run repo-local proof** for dependency inventory, preview determinism, stale-token rejection, fail-closed missing/archive behavior, audit evidence, explain trace carry-through, and promotion/manifest blockers → `verify.phase56` + gap tests.
2. **Docs and release-contract checks describe the same supported scope** → guide edits + new `release_contract_test` block + README/MAINTAINING proof section.
3. **Linked sibling-package model intact** → existing + extended boundary assertions; no Phase 8 docs.

### Upstream contracts (must reference in plans)

- `54-HANDOFF-CHECKLIST.md` — core dependency truth, fail-closed blockers, scope semantics, redaction
- `55-HANDOFF-CHECKLIST.md` — mounted preview→confirm→audit, compare read-only, explain permalinks, policy-mediated used-by

---

## 2. `verify.phase56` Composition Strategy

### Design principle

Phase 56 **composes upward**: it is the v1.6.0 merge gate, not a replacement for phase-scoped gates. Prior tasks stay unchanged (D-02).

### Current gate inventories (verified in repo)

**`verify.phase54`** (`rulestead/lib/mix/tasks/verify.phase54.ex`) — 13 core paths:

```
test/rulestead/targeting/dependency_sort_property_test.exs
test/rulestead/store/audience_dependency_inventory_contract_test.exs
test/rulestead/store/compare_contract_test.exs
test/rulestead/store/publish_ruleset_dependency_contract_test.exs
test/rulestead/store/promotion_apply_contract_test.exs
test/rulestead/store/manifest_import_contract_test.exs
test/rulestead/store/audience_impact_contract_test.exs
test/rulestead/store/ecto_audience_impact_contract_test.exs
test/rulestead/manifest/export_test.exs
test/rulestead/manifest/import_test.exs
test/rulestead/manifest/validate_test.exs
test/rulestead/runtime/audience_snapshot_test.exs
test/rulestead/release_contract_test.exs
```

**`verify.phase55`** (`rulestead/lib/mix/tasks/verify.phase55.ex`) — core subset + admin shell:

Core (4 paths; 2 overlap phase54):

```
test/rulestead/admin/dependency_visibility_test.exs
test/rulestead/targeting/dependency_inventory_test.exs
test/rulestead/store/audience_impact_contract_test.exs          # overlap
test/rulestead/store/audience_dependency_inventory_contract_test.exs  # overlap
```

Admin (via `mix cmd` into `rulestead_admin`):

```
test/rulestead_admin/live/audience_live/          # 4 files: index, edit_preview, archive_confirm, delete_preview
test/rulestead_admin/live/flag_live/explain_test.exs
test/rulestead_admin/router_test.exs
test/rulestead_admin/live/environment_compare_live/index_test.exs
```

### Phase 53 gaps **not** in either gate (minimum per D-01)

| File | VER-01 coverage | In phase54? | In phase55? |
|------|-----------------|-------------|-------------|
| `test/rulestead/targeting/impact_preview_test.exs` | Preview fingerprints, basis, uncertainty, redaction, scoped payloads (IMP-01) | No | No |
| `test/rulestead/audience_mutation_audit_test.exs` | Accepted/blocked/denied audit reconstruction (IMP-04) | No | No |

Phase 53 verification also cited `evaluator_test.exs`, but audience runtime/explain trace proof is already covered by `audience_snapshot_test.exs` (in phase54) and `flag_live/explain_test.exs` (in phase55). **Do not require evaluator_test.exs** unless a gap appears during planning — it has no `segment_match` / audience cases today.

### Admin tests exist but are **outside** `verify.phase55` (planner discretion for phase56 union)

These support ADM-03/ADM-04 and should be strong candidates for phase56 inclusion without touching phase55:

- `test/rulestead_admin/live/environment_compare_live/show_test.exs`
- `test/rulestead_admin/live/flag_live/rules_test.exs`
- `test/rulestead_admin/live/flag_live/simulate_test.exs` (if simulate audience trace is part of VER-01 "explain trace carry-through")

### Recommended composition patterns (pick one in PLAN)

**Option A — Sequential delegation (lowest maintenance drift)**

```elixir
def run(_args) do
  Mix.Task.run("verify.phase54")
  Mix.Task.run("verify.phase55")
  Mix.Task.run("test", @phase53_gap_tests)
  # optional: @phase56_admin_completion_tests
end
```

Pros: automatically tracks phase54/55 list changes. Cons: duplicate runs of overlapping contract tests (~2 files run twice in core; release_contract runs once via phase54).

**Option B — Flat deduplicated union (fastest single command)**

Build `@phase56_tests` as ordered set-union of all phase54 paths + phase55-unique core paths + phase53 gaps + optional admin completion paths; single `Mix.Task.run("test", paths)` for core, then admin `mix cmd` block mirroring phase55.

Pros: one clear manifest; no duplicate core runs. Cons: must manually stay in sync when phase54/55 lists change (mitigate with comment: "union of verify.phase54 + verify.phase55 + gaps").

**Option C — Hybrid (recommended for PLAN)**

- Core: flat deduplicated union (Option B) including `release_contract_test.exs` once
- Admin: reuse phase55's `@admin_test_paths` plus optional completion paths
- Do **not** re-invoke full `verify.phase54`/`verify.phase55` tasks (avoids double release_contract and redundant overlap)

### `MixProject` wiring

Follow phase54:

```elixir
# rulestead/mix.exs cli/0
[preferred_envs: [{:"verify.phase54", :test}, {:"verify.phase56", :test}]]
```

Add `# credo:disable-for-this-file` on the task module (phase54/55 pattern).

### Expected proof surface after green gate

Roughly: phase54's ~93 tests + phase55 admin suite (~17 admin tests per 55-VERIFICATION) + impact_preview + audience_mutation_audit + any added admin completion tests. Exact count is recorded in `56-VERIFICATION.md` at phase close.

---

## 3. `release_contract_test` Drift Guard Design

### Model block

Mirror the existing test at `release_contract_test.exs` lines 282–336:

```elixir
test "guarded rollout support truth stays bounded across root package and maintainer docs" do
```

Add a sibling test (name suggestion):

```elixir
test "reusable targeting deepening support truth stays bounded across root package and maintainer docs" do
```

### Files under assertion (D-03)

| Path | Module attribute |
|------|------------------|
| Root `README.md` | `@root_readme_path` (exists) |
| `MAINTAINING.md` | `@maintaining_path` (exists) |
| `rulestead/README.md` | `@runtime_readme_path` (exists) |
| `rulestead_admin/README.md` | `@admin_readme_path` (exists) |

Optionally assert guide cross-links if README cites them; primary guide truth can stay in guide content reviewed manually with spot checks — but **proof commands must appear in README + MAINTAINING** for CI reruns.

### Required phrase clusters (planner finalizes exact strings)

Group assertions by support-truth theme; use `assert doc =~` fragments stable enough to avoid brittle full-paragraph matching:

**Scope and preview basis (VER-02, PITFALLS §13 false precision)**

- `preview basis` or `authored state` / `authored-state`
- `explicit sample` or `explicit samples`
- `environment` + scope language (`environment scope`, `environment_key`, or `?env=`)
- `tenant` scope language (`tenant scope`, `tenant_key`, explicit tenancy)
- `uncertainty` or `does not claim` / `no authoritative` affected-user / population count language
- `audprev_` or `preview fingerprint`

**Workflow truth (IMP-02, ADM-02)**

- `preview` + `confirm` + `audit` (or `preview → confirm → audit`)
- `fail closed` / `fails closed`
- `stale preview` or `stale token` or `preview fingerprint`

**Dependency and promotion truth (DEP-01–03, ADM-04)**

- `dependency` + (`inventory` or `findings` or `visibility`)
- `promotion` or `manifest` + (`blocker` or `fail closed` or `dependency`)
- `compare` + (`read-only` or `dependency findings`) — especially for multi-env guide alignment

**Package boundaries (VER-03, existing test at line 400)**

- Reuse or extend existing `dependency truth for promotion and manifest stays core-owned` test — do not duplicate `RulesteadAdmin` refute logic unless new core files added
- `mounted companion` / `mounted presentation`
- `host-owned` + (`identity` or `observability` or `metrics`)
- `rulestead` owns + (`domain` or `validation` or `contracts`)

**Proof entrypoints (VER-01, D-06)**

- `mix verify.phase56`
- `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh` (once CI scope ships)
- `reusable targeting` or `reusable audience` deepening

### Forbidden phrase list (extend guarded_rollout pattern)

Apply `refute doc =~ phrase` across `[root_readme, runtime_readme, admin_readme, maintaining]`:

| Forbidden | Why |
|-----------|-----|
| `standalone rulestead_admin` / `standalone control plane` | VER-03 |
| `graph visualizer` / `dependency graph` (as product promise) | Out of scope |
| `bulk automation` / `one-click bulk` | ADM/out-of-scope |
| `authoritative affected-user` / `real user population` (as Rulestead-owned) | IMP-01 / PITFALLS |
| `built-in observability` / `Rulestead dashboard` | PITFALLS §17 |
| `metrics ingestion` / `metrics warehouse` (as Rulestead-owned) | Host-owned boundary |
| `automatic progressive delivery platform` | Reuse from guarded_rollout guard |
| Operator-facing `segment library` / `manage segments` | PITFALLS §15 — prefer **Audience** externally |

**Terminology guard nuance:** Internal code/tests may say `segment_match`; operator docs should say **Audience**. Drift guard should ban operator-doc phrases like "segment management UI" while allowing technical references only in non-operator contexts if needed.

### Implementation sequencing

1. Update README/MAINTAINING/package READMEs + guides with required phrases **first** (or in same PR wave).
2. Add release_contract assertions **in the same change** so docs and guards stay coupled.
3. Run `cd rulestead && mix test test/rulestead/release_contract_test.exs` as fast feedback.

Existing test `"dependency truth for promotion and manifest stays core-owned without rulestead_admin leakage"` (line 400) already covers part of VER-03 for v1.6 core APIs — extend, don't fork.

---

## 4. Guide Update Targets And Required Phrases

In-place edits only (D-04). No new guide files.

### `guides/flows/rulesets.md`

**Current state:** Mentions reusable audiences in authoring checklist; no impact preview, dependency blockers, or tenant/environment scope for audience edits.

**Add sections or paragraphs covering:**

- Reusable **Audience** naming (not "segment" in operator copy)
- Before publish/archive of shared audiences: impact preview with **preview basis** (authored state ± explicit samples)
- **Fail closed** when references are missing, archived, incompatible, stale, or tenant-mismatched
- Explicit **environment** and **tenant** scope when same-name audiences differ
- Pointer to mounted `/admin/audiences` workflow (preview → confirm → audit) without documenting LiveView internals

### `guides/flows/explainability.md`

**Current state:** Generic explain/simulate; no audience trace steps.

**Add:**

- Audience trace steps in explain/simulate output: `matched`, `missed`, `missing from snapshot`, `archived`
- Snapshot-local evaluation — no live DB/admin/identity/observability lookup for audience resolution
- Support-safe explain permalinks (flag, environment, tenant, targeting key — not raw traits)
- Escalation path: explain + dependency inventory + audit (not observability dashboards)

### `guides/flows/admin-ui.md`

**Current state:** Flag-centric routes; no audience library.

**Add to stable mounted seam list:**

- `/admin/audiences`, `/admin/audiences/:key`, edit/archive preview/confirm routes (path-level only)
- Audience **used-by** tables with policy-aware redaction copy
- **Preview → confirm → audit** for audience mutations (parallel to cleanup flow already documented)
- Compare dependency findings as **read-only** (no Apply/Publish on compare)
- Reiterate: mounted companion renders core truth; core validates

### `guides/flows/multi-env.md`

**Current state:** Environment promotion pattern; no compare/promotion dependency findings or tenant scope.

**Add:**

- Compare and promotion surfaces show **audience dependency findings** with explicit env/tenant scope on links
- Promotion/manifest **fail closed** on missing/incompatible reusable targeting assets
- **Tenant** scope must not collapse across environments (same-name ≠ equivalent)
- Host owns tenant catalog and authorization; Rulestead carries scope on payloads only

### Cross-guide required vocabulary (PITFALLS §15–17)

| Use | Avoid in operator copy |
|-----|------------------------|
| Audience | segment (except internal `segment_match` in code citations if unavoidable) |
| preview basis, uncertainty | exact user counts, population impact |
| host-owned identity / observability | Rulestead-owned metrics, dashboards |
| audit / admin signals | telemetry as product observability |
| mounted companion | standalone admin product |

---

## 5. CI Scope `reusable_targeting_deepening` Design

### Pattern reference

`scripts/ci/test.sh` already defines:

- `guarded_rollout_foundations` — core tests + selective admin tests + `release_contract_test.exs`
- `mounted_admin_contract` — narrow lifecycle proof with failure categorization + MAINTAINING runbook citation

### Proposed `run_reusable_targeting_deepening/0`

```bash
run_reusable_targeting_deepening() {
  run_mix rulestead deps.get
  prepare_rulestead_test_db
  run_mix rulestead verify.phase56
  # OR: run_mix rulestead test <explicit paths> if verify task not yet available in CI checkout
  run_mix rulestead_admin deps.get
  # Admin paths already invoked inside verify.phase56 via mix cmd — omit duplicate unless task splits packages
}
```

**Design choices for PLAN:**

| Decision | Recommendation |
|----------|----------------|
| Invoke `mix verify.phase56` vs raw path list | Prefer **`mix verify.phase56`** — single source of truth (D-06) |
| DB prep | **Yes** — `audience_mutation_audit_test.exs` uses Ecto sandbox (async: false); mirror `guarded_rollout_foundations` |
| Include `release_contract_test` | **Yes** — already inside verify.phase56 core union |
| Default CI `all` scope | **No change required** until path-gated workflow warranted (D-06) |
| GitHub workflow job | Optional follow-on — `guarded_rollout_foundations` is **not** in `.github/workflows/ci.yml` today; same optional posture acceptable |

### Failure guidance block (mirror `print_mounted_failure_guidance`)

Add `print_reusable_targeting_failure_guidance/0` with:

- Category: setup/prerequisite vs contract regression vs docs drift (`release_contract_test` failure)
- Rerun: `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh`
- Maintainer runbook: `MAINTAINING.md` new section
- Remediation: `cd rulestead && mix verify.phase56`

### Doc citations to add

**Root `README.md` — "Proof today" section** (currently lists guarded_rollout, openfeature, mounted_admin only):

- Bullet for v1.6 reusable targeting deepening proof
- Cite `mix verify.phase56` and optional CI scope

**`MAINTAINING.md`** — new section parallel to "Guarded Rollout Foundations Proof" (~line 220):

- When to run (VER-01 reusable targeting changes, docs/support truth)
- Bounded claim: what it proves vs does not (no observability ownership, no graph viz, no bulk automation)
- Explicit VER-01 mapping for v1.6 milestone

---

## 6. Handoff / Verification Artifact Pattern

### `56-HANDOFF-CHECKLIST.md` (create at phase close)

Purpose: milestone closeout boundary for support/release comms and future milestones — mirrors 54/55 handoff pattern.

Suggested sections (checkboxes):

1. **Upstream contracts acknowledged** — links to `54-HANDOFF-CHECKLIST.md`, `55-HANDOFF-CHECKLIST.md`
2. **Proof gate** — `mix verify.phase56` green; optional CI scope documented
3. **Docs drift guards** — `release_contract_test.exs` reusable-targeting block green
4. **Guide alignment** — four flow guides updated; no Phase 8 artifacts added
5. **Package truth** — linked-version model; no standalone admin publish prep
6. **Support vocabulary** — Audience externally; telemetry/audit wording bounded
7. **Requirement closure** — VER-01, VER-02, VER-03 ready to mark complete in REQUIREMENTS.md / ROADMAP (follow-up sync)

### `56-VERIFICATION.md` (create at phase close)

Mirror frontmatter from `54-VERIFICATION.md` / `55-VERIFICATION.md`:

```yaml
---
status: passed
phase: 56-proof-docs-and-support-truth
verified: YYYY-MM-DD
score: N/N
---
```

**Must-have table:**

| Truth | Evidence |
|-------|----------|
| `mix verify.phase56` merge gate | Task file + exit 0 log with test counts |
| Phase 53 gaps in gate | `impact_preview_test.exs`, `audience_mutation_audit_test.exs` |
| Phase 54 + 55 coverage union | Path list matches or supersedes phase54/55 |
| Release-contract drift guards | New test name + green run |
| README/MAINTAINING proof citations | grep / release_contract asserts |
| Guide support truth | File list + key phrase spot-check |
| VER-03 package boundary | Existing + extended refute asserts |
| Handoff checklist | `56-HANDOFF-CHECKLIST.md` |

**Automated checks section:** record exact command output (`mix verify.phase56`, `mix test release_contract_test.exs`).

**Human verification:** likely none if drift guards cover doc phrases (same posture as 55-VERIFICATION).

### Plan wave suggestion (for planner)

| Plan | Focus |
|------|-------|
| 56-01 | `verify.phase56.ex` + gap/completion test union + `mix.exs` preferred_env |
| 56-02 | `release_contract_test.exs` + README/MAINTAINING/package README proof sections |
| 56-03 | Guide in-place updates (4 flow guides) |
| 56-04 | Optional `scripts/ci/test.sh` scope + `56-HANDOFF-CHECKLIST.md` + `56-VERIFICATION.md` + REQUIREMENTS/ROADMAP status sync |

---

## 7. Validation Architecture

Nyquist-facing proof map for plan-phase and phase validation artifacts.

### Test infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit (core + admin packages) |
| Core DB | Ecto SQL Sandbox manual mode; `prepare_rulestead_test_db` for audit/ecto suites |
| Primary phase gate | `cd rulestead && mix verify.phase56` |
| Fast core slice | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs test/rulestead/audience_mutation_audit_test.exs test/rulestead/release_contract_test.exs` |
| Phase54 regression | `cd rulestead && mix verify.phase54` (unchanged) |
| Phase55 regression | `cd rulestead && mix verify.phase55` (unchanged) |
| CI optional scope | `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh` |
| Doc drift only | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |

### Requirement → proof surface map

| Req ID | Behavior | Automated command | Primary test/doc surface |
|--------|----------|-------------------|--------------------------|
| VER-01 | Repo-local proof covers full v1.6 deepening surface | `mix verify.phase56` | Union of phase54 + phase55 + impact_preview + audience_mutation_audit (+ optional admin completion) |
| VER-01 | Dependency inventory | included via phase54/55 | `audience_dependency_inventory_contract_test.exs`, `dependency_inventory_test.exs` |
| VER-01 | Preview determinism / stale-token rejection | phase53 gaps + phase54 impact contracts | `impact_preview_test.exs`, `audience_impact_contract_test.exs`, `ecto_audience_impact_contract_test.exs` |
| VER-01 | Fail-closed missing/archive/incompatible | phase54 | `publish_ruleset_dependency_contract_test.exs`, promotion/manifest/compare contracts |
| VER-01 | Audit evidence | phase53 gap | `audience_mutation_audit_test.exs` |
| VER-01 | Explain trace carry-through | phase54 runtime + phase55 admin | `audience_snapshot_test.exs`, `flag_live/explain_test.exs`, optionally `rules_test.exs` / `simulate_test.exs` |
| VER-01 | Promotion/manifest blockers | phase54 | `promotion_apply_contract_test.exs`, `manifest/*_test.exs` |
| VER-02 | Public/package docs + drift guards | `release_contract_test.exs` + manual guide review | README, MAINTAINING, package READMEs, 4 flow guides |
| VER-03 | Sibling-package model | `release_contract_test.exs` | No `RulesteadAdmin` in core; no Phase 8 docs; mounted companion language |

### Sampling rate (execution discipline)

| When | Run |
|------|-----|
| Doc-only edit | `mix test test/rulestead/release_contract_test.exs` |
| verify task change | `mix verify.phase56` full |
| Guide + README wave | release_contract + verify.phase56 |
| Phase close | verify.phase56 + optional CI scope + write 56-VERIFICATION.md |

### Proof surfaces checklist (for 56-VALIDATION.md if created)

- [ ] `rulestead/lib/mix/tasks/verify.phase56.ex`
- [ ] `rulestead/test/rulestead/release_contract_test.exs` (new test block)
- [ ] `README.md`, `MAINTAINING.md`, `rulestead/README.md`, `rulestead_admin/README.md`
- [ ] `guides/flows/{rulesets,explainability,admin-ui,multi-env}.md`
- [ ] `scripts/ci/test.sh` (optional scope)
- [ ] `.planning/phases/56-proof-docs-and-support-truth/56-{VERIFICATION,HANDOFF-CHECKLIST}.md`

---

## 8. Risks And Pitfalls (Phase 56 — PITFALLS.md)

### Phase-specific warning (PITFALLS Phase-Specific Warning Map)

| Warning sign | Prevention |
|--------------|------------|
| Docs outrun tests | Land `verify.phase56` **before** or **with** README/guide expansions; release_contract guards block merge |
| Package docs disagree | Single PR wave updates root + sibling READMEs + MAINTAINING + release_contract asserts together |
| Phase 8-only docs appear | AGENTS.md / VER-03 — no cheatsheet.cheatmd or extending-rulestead expansion |
| Sibling-package mismatch | Extend existing core/refute tests; cite 54/55 handoff checklists in 56 plans |

### §15 Terminology drift (Audience vs segment)

- **Risk:** New docs/UI strings expose "segment" to operators.
- **Mitigation:** Guide edits use **Audience**; drift guard refutes operator-facing segment product language in the four README/MAINTAINING targets.

### §16 Versioned package truth falls out of sync

- **Risk:** `rulestead` documents preview APIs `rulestead_admin` doesn't mount; proof commands missing from one package README.
- **Mitigation:** Update all four README targets in one wave; `release_contract_test` cross-doc asserts; linked-version install blocks stay aligned.

### §17 Telemetry claims become observability claims

- **Risk:** Audit/telemetry docs imply Rulestead measures populations or rollout health.
- **Mitigation:** Document events as **admin/audit/support signals**; explicit host ownership of metrics stores, baselines, dashboards, identity resolution; forbidden phrase list in drift guard.

### Support-truth boundaries (carry into all doc work)

Rulestead **can** claim: authored dependency references, deterministic simulation, redacted sample previews, snapshot/explain traces, audit evidence.

Rulestead **cannot** claim: authoritative affected-user counts, host identity directory, tenant catalog ownership, observability-backed previews, graph visualizers, bulk automation, standalone admin control plane.

### Process pitfalls observed in prior milestones

- **ROADMAP/REQUIREMENTS status lag:** Phase 54/55 show "Pending" in ROADMAP traceability despite completion — Phase 56 close should include REQUIREMENTS.md + ROADMAP.md VER/DEP/ADM status sync (non-blocking for functional pass, blocking for milestone audit).
- **verify.phase55 incomplete vs full admin suite:** 55-VERIFICATION notes unrelated KillTest failure outside gate — Phase 56 must not claim "all admin green"; scope language must stay bounded like v1.5 guarded_rollout proof.
- **CI scope optionalism:** `guarded_rollout_foundations` is maintainer-documented but not in ci.yml — acceptable for first wave; document explicitly in 56-VERIFICATION if CI job deferred.

---

## Sources

### Primary

- `.planning/phases/56-proof-docs-and-support-truth/56-CONTEXT.md`
- `.planning/REQUIREMENTS.md` (VER-01–VER-03)
- `.planning/ROADMAP.md` (Phase 56 section)
- `.planning/STATE.md`
- `.planning/phases/54-dependency-truth-and-promotion-safety/54-HANDOFF-CHECKLIST.md`
- `.planning/phases/55-mounted-operator-workflows/55-HANDOFF-CHECKLIST.md`
- `.planning/phases/55-mounted-operator-workflows/55-VERIFICATION.md`
- `.planning/research/PITFALLS.md` (§15–17, Phase 56 row)
- `.planning/research/SUMMARY.md` (Phase 56 rationale)

### Code / CI patterns

- `rulestead/lib/mix/tasks/verify.phase54.ex`
- `rulestead/lib/mix/tasks/verify.phase55.ex`
- `rulestead/test/rulestead/release_contract_test.exs` (guarded_rollout block ~282–336)
- `scripts/ci/test.sh` (`guarded_rollout_foundations`, `mounted_admin_contract`)
- `rulestead/mix.exs` (`preferred_envs` for verify.phase54)

### Guides (edit targets)

- `guides/flows/rulesets.md`
- `guides/flows/explainability.md`
- `guides/flows/admin-ui.md`
- `guides/flows/multi-env.md`

---

## Open Questions For Plan-Phase (low risk — CONTEXT grants discretion)

1. **Composition style:** Sequential delegation vs flat union vs hybrid (Section 2 recommends hybrid).
2. **Admin completion tests:** Include `show_test.exs`, `rules_test.exs`, `simulate_test.exs` in phase56 union?
3. **CI first wave:** Ship `reusable_targeting_deepening` scope with phase56 task or defer until green locally?
4. **Exact forbidden/required phrase strings:** Finalize during 56-02 implementation to match edited doc prose.
5. **56-HANDOFF-CHECKLIST audience:** Milestone-only vs also for post-v1.6 support comms template.

---

## RESEARCH COMPLETE

**Phase directory:** `.planning/phases/56-proof-docs-and-support-truth/`  
**Ready for planning:** Yes — execute `/gsd-plan-phase 56` with this research and `56-CONTEXT.md` as inputs.
