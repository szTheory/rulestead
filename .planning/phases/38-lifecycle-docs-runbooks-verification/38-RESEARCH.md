# Phase 38: Lifecycle Docs, Runbooks, & Verification - Research

**Researched:** 2026-05-23
**Domain:** Lifecycle documentation architecture, release-surface verification, and milestone closeout evidence for the Rulestead sibling-package monorepo. [VERIFIED: codebase grep] [VERIFIED: repo docs]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Product shape and recommendation posture
- **D-01:** Phase 38 should stay recommendation-first and cohesive. Downstream agents should not reopen routine doc-IA, wording, or verification tradeoffs unless a choice would materially change public contract, security/governance posture, package boundaries, or milestone scope.
- **D-02:** The lifecycle story must remain anchored in the linked-version sibling-package shape: `rulestead` owns the shared lifecycle docs surface, while `rulestead_admin` remains documented as the mounted companion rather than a standalone control plane.
- **D-03:** Docs must preserve the prior milestone truth: operators author facts, Rulestead computes guidance, and archive/cleanup actions stay explicit, previewable, and audited.

### Documentation shape
- **D-04:** Use a **hybrid docs shape**: one narrative “birth to retirement” lifecycle guide as the primary spine, plus focused reference/runbook satellites rather than either a single giant page or a scattered set of lightly linked updates.
- **D-05:** The primary lifecycle story should live in the shared root docs/guides surface, not in `rulestead_admin/README.md`, because the lifecycle workflow spans runtime guidance, mounted-admin review, CLI reporting, and release verification.
- **D-06:** The spine guide should stay narrative and operator-oriented. Focused satellites should carry exact host-facing details for mounted-admin workflow, CLI/reporting surface, testing/verification, and release/maintainer posture.
- **D-07:** Prefer extending the existing guide architecture rather than inventing a parallel doc taxonomy. Phase 38 should fit into the established `guides/introduction`, `guides/flows`, and `guides/recipes` structure plus existing README surfaces.
- **D-08:** Root and sibling READMEs should advertise the lifecycle story clearly enough that a new reader can discover the canonical guide without hunting through unrelated rollout or explainability docs.

### Runbook emphasis and narrative order
- **D-09:** The main runbook spine should be **triage/review first**, not authoring-first and not cleanup-first. The canonical daily operator workflow is the mounted-admin workbench plus CLI parity from Phase 36/37.
- **D-10:** The recommended lifecycle narrative order is:
  - brief authored-defaults and ownership framing
  - primary triage/review workflow in mounted admin plus read-only CLI
  - explicit archive/cleanup execution workflow with preview, reason, and audit linkage
  - ownership-handoff / unknown-owner exception handling
  - support/SRE lookup appendix using explainability, lifecycle evidence, and audit history
- **D-11:** Archive execution deserves its own dedicated chapter immediately after triage because it is the highest-safety mutation path, but it must not become the conceptual center of the lifecycle story.
- **D-12:** Ownership handoff and support/SRE workflows are important but secondary. They should be documented as exception/appendix flows, not as the primary day-to-day runbook.
- **D-13:** Admin and CLI must use one vocabulary for lifecycle, readiness, evidence quality, unknowns, blockers, and recommended next action. The docs should not create a second naming dialect.

### Guidance tone and DX posture
- **D-14:** Use a **layered tone**: strongly opinionated guidance for the default Phoenix path, with explicit reference sections for advanced or exceptional cases.
- **D-15:** The primary docs should recommend least-surprise defaults clearly:
  - host owns identity, actor/session semantics, and owner truth
  - lifecycle defaults are advisory scaffolding, not hidden policy
  - temporary flags should be reviewed and retired deliberately
  - permanent operational/permission posture is exceptional and should be explicit
  - archive-readiness is advisory evidence, not permission
- **D-16:** Advanced seams should still be documented plainly, not buried:
  - no-admin installs
  - host-owned customization points
  - mounted-admin companion boundaries
  - exception cases such as permanent operational flags, owner handoff, and missing evidence
- **D-17:** Do not use a neutral, encyclopedic tone for the main lifecycle guide. This milestone exists to teach a coherent lifecycle posture, and neutral docs would force users to reconstruct Rulestead’s intended operating model themselves.
- **D-18:** Do not over-compress the docs into a “one true workflow” that hides real extension seams. The docs must remain honest that Rulestead is a library with host-owned seams, not a SaaS platform with full policy control.

### Verification and closeout evidence
- **D-19:** Phase 38 should use a **release-surface verification backbone with narrow behavioral backstops**, not docs-only proof and not a large new browser matrix.
- **D-20:** Required verification layers should include:
  - release-surface contract checks across root README, sibling READMEs, shared guides, and maintainer/release docs
  - `mix rulestead.lifecycle` public contract tests for text output, JSON schema/version, filter semantics, and read-only guarantees
  - one mounted-admin host-flow contract layer that proves public route/env semantics and host-facing mount behavior without stabilizing internal DOM structure
  - milestone evidence artifacts that map `LIF-05` to exact tests/checks and recorded pass outputs
- **D-21:** Existing publish/parity verification tasks remain supporting evidence, but they are not sufficient on their own because they prove publish/install parity rather than lifecycle-doc and runbook coherence.
- **D-22:** Avoid browser-heavy E2E expansion in this phase unless a concrete uncovered lifecycle seam appears during planning. Phoenix/LiveView contract tests are the idiomatic default for the mounted package boundary here.
- **D-23:** Release-surface tests should verify only public/package-facing semantics. They must not accidentally freeze internal LiveView modules, socket assigns, CSS classes, or DOM selectors that the READMEs explicitly leave non-public.
- **D-24:** Milestone closeout evidence should be machine-backed and traceable to actual checks, not a hand-written narrative detached from test/task output.

### Cohesion guardrails
- **D-25:** Every Phase 38 doc and verification artifact should reinforce the same operator truth:
  - create with explicit ownership and lifecycle intent
  - review through one canonical queue/workbench
  - treat archive-readiness as evidence, not truth
  - mutate only through explicit preview/confirm/audit flows
  - preserve support and maintainer trust through stable release-facing documentation
- **D-26:** Planning should prefer reusing and tightening existing docs/tests rather than creating many new surfaces. The phase should feel like one coherent closeout pass over lifecycle truth, not a documentation sprawl milestone.

### Claude's Discretion
- Exact guide filenames and ExDoc grouping, provided the hybrid spine-plus-satellites structure remains intact
- Exact chapter and section titles, provided the runbook order and layered tone remain intact
- Exact release-surface test module split, provided verification stays focused on public seams and avoids internal DOM/API lock-in
- Exact milestone evidence artifact layout, provided `LIF-05` traceability to concrete checks remains explicit

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Broader browser E2E expansion for lifecycle flows beyond the narrow public mounted-admin seam
- Standalone lifecycle control-plane documentation or separate admin product positioning
- New lifecycle product capabilities, automation, or policy engines beyond the already-locked Phase 35-37 semantics
- Global upstream changes to Codex/GSD defaults beyond the project-local methodology already recorded in `.planning/METHODOLOGY.md`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-05 | Docs and runbooks teach the “flag from birth to retirement” lifecycle clearly for Phoenix teams, including least-surprise defaults and host-owned integration expectations. | Put one new shared lifecycle spine in root `guides/`, tighten README and satellite guide discoverability, extend existing Mix-task and mounted-admin contract tests, and add machine-backed milestone evidence tied to those checks. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: CLAUDE.md]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout. Do not collapse work into a single package shape for convenience. [VERIFIED: CLAUDE.md]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md`. [VERIFIED: CLAUDE.md]
- `rulestead_admin` is intentionally a guarded stub until later phases. Do not introduce early publish flows that bypass that rule. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes. [VERIFIED: CLAUDE.md]
- Keep root docs honest about the current phase. [VERIFIED: CLAUDE.md]
- Use scripts-first CI surfaces where workflow logic gets non-trivial. [VERIFIED: CLAUDE.md]

## Summary

The repo already has the right documentation topology for Phase 38: the root `README.md` is the product front door, shared guides live at the monorepo root, `rulestead/README.md` is runtime-scoped, and `rulestead_admin/README.md` is intentionally limited to the mounted host contract. That means the lifecycle story should land in shared root docs with README discovery links, not in `rulestead_admin`-local docs. [VERIFIED: codebase grep] [VERIFIED: repo docs]

The verification spine also already exists. `rulestead` has a release contract test, publish/parity Mix-task tests, and a workspace-clean verifier; Phase 36 added a public read-only lifecycle Mix task with contract coverage; Phase 37 added mounted-admin lifecycle route tests that assert URL/session/env behavior without freezing internal DOM structure. Phase 38 should extend those surfaces rather than inventing a docs-only checker or a browser-heavy E2E lane. [VERIFIED: codebase grep] [VERIFIED: repo docs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html]

The main planning implication is to treat this as a three-part closeout pass: docs IA plus lifecycle spine, release-surface/doc-contract verification, and milestone evidence assembly. That keeps the phase narrow, satisfies `LIF-05`, and avoids widening into new product features or broad UI automation. [VERIFIED: repo docs] [VERIFIED: codebase grep]

**Primary recommendation:** Add one shared lifecycle spine guide under `guides/flows/`, route readers to it from the root and sibling READMEs plus existing intro/admin/testing/explainability guides, then verify coherence with targeted ExUnit doc-contract checks, the existing lifecycle Mix-task contract suite, one mounted-admin host-flow contract layer, and a machine-backed `LIF-05` evidence artifact. [VERIFIED: codebase grep] [VERIFIED: repo docs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lifecycle narrative and runbook spine | Shared docs / release surface | `rulestead` package docs | Shared guides already own cross-package concepts, while `rulestead_admin/README.md` stays mount-contract only. [VERIFIED: codebase grep] |
| README discoverability and package positioning | Root README + sibling READMEs | ExDoc extras | The repo already splits the 60-second root pitch from package-local READMEs and guide extras. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
| CLI public-seam verification | API / Backend | ExUnit contract tests | `mix rulestead.lifecycle` is a public Mix-task seam with versioned JSON/text output and existing tests. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] |
| Mounted-admin public-seam verification | Frontend Server (LiveView) | ExUnit LiveView tests | Public mounted behavior is route/session/env semantics, not internal DOM contracts. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Milestone closeout evidence | Planning/docs artifacts | Test output capture | The context explicitly requires machine-backed `LIF-05` traceability instead of narrative-only closeout. [VERIFIED: repo docs] |

## Standard Stack

### Core
| Library / Seam | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Shared root guides (`guides/`) | current repo seam | Own the cross-package lifecycle story and satellites. [VERIFIED: codebase grep] | `rulestead/guides/README.md` explicitly says the authoritative shared guides live at the monorepo root. [VERIFIED: codebase grep] |
| ExDoc extras via `rulestead/mix.exs` | current repo seam | Publish root README plus introduction/flows/recipes into the runtime package docs. [VERIFIED: codebase grep] | `rulestead/mix.exs` already includes shared guides in `extras` and groups them into Introduction, Flows, and Recipes. [VERIFIED: codebase grep] |
| `Mix.Tasks.Rulestead.Lifecycle` | current repo seam | Stable lifecycle CLI/reporting contract. [VERIFIED: codebase grep] | It already exposes versioned JSON, text rendering, mirrored filters, and explicit read-only usage. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] |
| `Phoenix.LiveView` + `Phoenix.LiveViewTest` | locked `1.1.28`. [VERIFIED: mix.lock] | Verify mounted-admin host behavior through route-backed LiveView tests. [VERIFIED: codebase grep] | Official LiveView guidance supports `handle_params/3` plus `push_patch/2` for same-view URL state and `live/2` for route-backed tests. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| ExUnit release contract tests | current repo seam | Assert release-facing docs and package boundaries. [VERIFIED: codebase grep] | `rulestead/test/rulestead/release_contract_test.exs` already treats docs and API stability as release surface. [VERIFIED: codebase grep] |

### Supporting
| Library / Seam | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `verify.release_publish` tests | current repo seam | Verify sibling-package publish posture and HexDocs reachability. [VERIFIED: codebase grep] | Reuse as supporting evidence for release truth, but not as the only lifecycle-doc proof. [VERIFIED: repo docs] |
| `verify.release_parity` tests | current repo seam | Prove tag vs tarball parity on shipped files. [VERIFIED: codebase grep] | Reuse for release-drift posture when lifecycle docs become package surface. [VERIFIED: codebase grep] |
| `verify.workspace_clean` tests | current repo seam | Check package file inclusion for docs/guides paths. [VERIFIED: codebase grep] | Use if Phase 38 changes package file lists or guide coverage. [VERIFIED: codebase grep] |
| Existing lifecycle LiveView tests | current repo seam | Reuse queue/detail/cleanup/preview/confirm fixtures and public route assertions. [VERIFIED: codebase grep] | Extend when docs need proof that the operator story matches actual mounted seams. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared guide spine in root `guides/flows/` | Put the lifecycle story in `rulestead_admin/README.md` | Rejected because the lifecycle story spans runtime defaults, CLI reporting, mounted admin, and release verification, not just admin mounting. [VERIFIED: repo docs] |
| ExUnit doc-contract tests | Browser-heavy E2E docs verification | Rejected because the context explicitly narrows verification to release-surface checks plus one mounted host-flow layer. [VERIFIED: repo docs] |
| Existing release contract suite | New standalone QA subsystem | Rejected because the repo already treats docs and package boundaries as release surface. [VERIFIED: codebase grep] |
| Satellite guide updates | One giant lifecycle mega-page | Rejected because the context locks a hybrid spine-plus-satellites shape. [VERIFIED: repo docs] |

**Installation:**
```bash
cd rulestead && mix deps.get
cd ../rulestead_admin && mix deps.get
```

**Version verification:** The workspace is running Elixir `1.19.5`, Erlang/OTP `28`, Mix `1.19.5`, Node `22.14.0`, npm `11.1.0`, and curl `8.7.1`. [VERIFIED: exec_command]

## Architecture Patterns

### System Architecture Diagram

```text
Root README / sibling READMEs
  -> link into shared lifecycle spine guide
  -> link into existing satellites
     -> admin-ui guide
     -> explainability guide
     -> testing guide
     -> maintainer / release docs

Shared lifecycle spine guide
  -> teaches authored defaults and ownership posture
  -> points to mounted-admin queue/detail/cleanup flow
  -> points to mix rulestead.lifecycle parity flow
  -> points to archive preview/confirm/audit flow
  -> points to support/SRE lookup surfaces

Release-surface verification
  -> release_contract_test.exs
  -> lifecycle Mix-task contract tests
  -> mounted-admin route/session/env contract tests
  -> milestone evidence artifact with LIF-05 traceability
```

The existing repo already separates docs entrypoints, public package seams, and verification layers in this shape. [VERIFIED: codebase grep]

### Recommended Project Structure
```text
guides/
├── introduction/
│   └── getting-started.md          # add lifecycle story routing
├── flows/
│   ├── lifecycle.md                # new primary spine
│   ├── admin-ui.md                 # mounted-admin host/surface satellite
│   └── explainability.md           # support/SRE satellite
└── recipes/
    └── testing.md                  # verification satellite

rulestead/test/rulestead/
├── release_contract_test.exs       # extend release-surface doc assertions
└── mix/tasks/
    └── rulestead_lifecycle_test.exs # extend CLI contract assertions if needed

rulestead_admin/test/rulestead_admin/
└── integration/admin_mount_test.exs # keep one narrow mounted host-flow contract

.planning/phases/38-lifecycle-docs-runbooks-verification/
└── 38-VERIFICATION.md or summary artifact updates  # machine-backed LIF-05 evidence
```

### Pattern 1: One Spine, Many Entry Points
**What:** Create one lifecycle guide as the canonical operator narrative, then route all other surfaces toward it. [VERIFIED: repo docs]
**When to use:** For root README, `rulestead/README.md`, `rulestead_admin/README.md`, getting-started, and admin/testing/explainability satellites.
**Example:**
```markdown
<!-- Source: repo doc architecture in README + mix.exs extras -->
- Root README: "Start with the lifecycle guide."
- rulestead README: "Runtime users who need lifecycle hygiene should continue here."
- rulestead_admin README: "Host contract plus link to the lifecycle operator guide."
```

### Pattern 2: Verify Public Vocabulary, Not Internal Markup
**What:** Assert stable route/query/session/env semantics and shared lifecycle vocabulary without freezing DOM/CSS internals. [VERIFIED: repo docs] [VERIFIED: codebase grep]
**When to use:** Mounted-admin contract tests and README/guide assertions.
**Example:**
```elixir
# Source: Phoenix.LiveViewTest docs + existing admin_mount_test.exs
{:ok, _view, html} = live(conn, "/admin/flags/ops-cleanup/cleanup?env=prod")
assert html =~ "Archive candidate"
assert html =~ "Evidence quality"
assert html =~ "Review cleanup"
```

### Pattern 3: Doc-Contract Tests Over Manual Checklist Drift
**What:** Read release-facing docs into tests and assert that links, anchors, vocabulary, and public-seam references stay aligned. [VERIFIED: repo docs]
**When to use:** Root README, sibling READMEs, lifecycle guide, admin/testing/explainability satellites, maintainer/release docs.
**Example:**
```elixir
# Source: release_contract_test.exs pattern
readme = File.read!("README.md")
guide = File.read!("guides/flows/lifecycle.md")

assert readme =~ "Lifecycle"
assert readme =~ "guides/flows/lifecycle.md"
assert guide =~ "archive-readiness is advisory evidence, not permission"
```

### Pattern 4: Milestone Evidence Must Point Back To Commands
**What:** Close the phase with an artifact that maps `LIF-05` to specific tests and commands, not prose-only claims. [VERIFIED: repo docs]
**When to use:** Phase verification and summary docs.
**Example:**
```text
LIF-05
  - mix test test/rulestead/release_contract_test.exs
  - mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs
  - mix test test/rulestead_admin/integration/admin_mount_test.exs
```

### Anti-Patterns to Avoid
- **README-only lifecycle docs:** This hides the cross-package story and breaks ExDoc discoverability. [VERIFIED: codebase grep]
- **Browser-first proof:** This widens scope and contradicts the locked verification posture. [VERIFIED: repo docs]
- **Internal selector lock-in:** The READMEs already state DOM/CSS internals are non-public. [VERIFIED: codebase grep]
- **Second lifecycle vocabulary:** The CLI, mounted admin, and docs already share readiness/evidence/unknowns/blockers language. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lifecycle docs index | A parallel docs taxonomy | Existing `guides/introduction`, `guides/flows`, `guides/recipes` split | `rulestead/mix.exs` already publishes and groups those extras. [VERIFIED: codebase grep] |
| Mounted-admin proof | Browser automation harness | `Phoenix.LiveViewTest.live/2` route-backed tests | Official docs and existing tests already use this pattern for public mounted behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: codebase grep] |
| CLI verification | A new shell script parser | Existing ExUnit tests around `Mix.Tasks.Rulestead.Lifecycle` | The Mix task already exposes a versioned machine contract. [VERIFIED: codebase grep] |
| Release-surface docs proof | A new custom QA framework | Extend `release_contract_test.exs` and existing verify-task tests | The repo already treats docs as package contract. [VERIFIED: codebase grep] |

**Key insight:** Phase 38 is mostly about tightening consistency across already-public seams, so reuse beats invention almost everywhere. [VERIFIED: codebase grep] [VERIFIED: repo docs]

## Common Pitfalls

### Pitfall 1: Putting the lifecycle story in the wrong package surface
**What goes wrong:** The docs drift toward `rulestead_admin`-specific positioning and stop teaching the shared runtime-plus-admin lifecycle loop. [VERIFIED: repo docs]
**Why it happens:** The mounted workbench is visually concrete, so it is easy to overweight it. [ASSUMED]
**How to avoid:** Keep the canonical guide under shared root `guides/` and let `rulestead_admin/README.md` remain host-contract-first. [VERIFIED: codebase grep]
**Warning signs:** The runtime README has no lifecycle link, or the admin README starts reading like a standalone control plane. [VERIFIED: codebase grep]

### Pitfall 2: Verifying copy without verifying public seams
**What goes wrong:** Docs say one thing, but route/env/session or CLI filter behavior differs. [VERIFIED: repo docs]
**Why it happens:** Manual proofreading catches prose drift, not contract drift. [ASSUMED]
**How to avoid:** Add doc-contract assertions plus targeted Mix-task and mounted-admin host-flow tests. [VERIFIED: codebase grep]
**Warning signs:** Tests stay green even when README links or stable vocabulary change unexpectedly. [ASSUMED]

### Pitfall 3: Freezing internal DOM through lifecycle tests
**What goes wrong:** The phase accidentally turns non-public markup into contract. [VERIFIED: repo docs]
**Why it happens:** LiveView tests can become selector-heavy when they should assert route and vocabulary only. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
**How to avoid:** Prefer public path, query param, link target, and stable operator-copy assertions. [VERIFIED: codebase grep]
**Warning signs:** Tests depend on CSS classes or component module names that the READMEs call non-public. [VERIFIED: codebase grep]

### Pitfall 4: Turning milestone evidence into hand-written theater
**What goes wrong:** The phase closes with prose claiming coherence but no exact commands or outputs. [VERIFIED: repo docs]
**Why it happens:** Docs phases often underinvest in machine-backed evidence. [ASSUMED]
**How to avoid:** Require a traceability artifact that names files, commands, and pass results for `LIF-05`. [VERIFIED: repo docs]
**Warning signs:** Verification docs mention “reviewed manually” without corresponding test or command output. [ASSUMED]

## Code Examples

Verified patterns from official sources and existing repo seams:

### Route-backed LiveView contract test
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
{:ok, _view, html} = live(conn, "/admin/flags?env=prod")
assert html =~ "Flag inventory"
```

### Same-LiveView URL-state updates
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
{:noreply, push_patch(socket, to: "/admin/flags?env=prod&owner=ops")}
```

### Existing lifecycle Mix-task contract shape
```elixir
# Source: rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs
output =
  capture_io(fn ->
    Lifecycle.run(["--env", "prod", "--format", "json"])
  end)

payload = Jason.decode!(output)
assert payload["schema_version"] == 1
assert payload["filters"]["env"] == "prod"
```

### Existing release-surface contract pattern
```elixir
# Source: rulestead/test/rulestead/release_contract_test.exs
contract = File.read!(@api_stability_path)
assert contract =~ "release contract"
assert contract =~ "Stable `rulestead_admin` Boundary"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Lifecycle guidance scattered across admin/runtime surfaces | One narrative lifecycle spine plus satellites | Locked in Phase 38 context on 2026-05-23. [VERIFIED: repo docs] | Planning should optimize for discoverability and coherence, not more surfaces. |
| Publish/parity proof only | Publish/parity proof plus lifecycle release-surface checks | Required by Phase 38 context on 2026-05-23. [VERIFIED: repo docs] | Existing release tests become supporting evidence, not the whole verification story. |
| Phase-36 advisory cleanup docs only | Phase-37 explicit preview/confirm/audit lifecycle semantics | Landed in current mounted-admin lifecycle tests. [VERIFIED: codebase grep] | The docs can now teach the full mutation path without inventing behavior. |
| Ad hoc UI assertions | Narrow route-backed LiveView contract tests | Current Phoenix LiveView guidance and repo practice. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: codebase grep] | Phase 38 can stay out of browser-heavy E2E. |

**Deprecated/outdated:**
- Docs that frame `rulestead_admin` as a standalone product are out of bounds for this phase. [VERIFIED: repo docs]
- Verification that depends only on publish/install parity is insufficient for `LIF-05`. [VERIFIED: repo docs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The best new spine filename is `guides/flows/lifecycle.md` rather than another flow/introduction path. [ASSUMED] | Recommended Project Structure | Low; planning can rename the file without changing scope or verification shape. |

## Open Questions (RESOLVED)

1. **Where should the maintainer-facing lifecycle release/runbook guidance live?**
   - **Resolved outcome:** keep the maintainer-facing lifecycle release checklist in `MAINTAINING.md`, then link to it from the lifecycle spine and phase-local verification artifact as needed.
   - **Why this is the right landing surface:** it matches the repo's existing maintainer/release posture, keeps operator-facing guides from absorbing release-checklist detail, and avoids creating a new standalone QA or release document just for Phase 38. [VERIFIED: repo docs]
   - **Planning implication:** `38-02-PLAN.md` should update `MAINTAINING.md`, while `38-03-PLAN.md` should capture the machine-backed evidence in `38-VERIFICATION.md`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks and ExUnit suites | ✓ | `1.19.5` | — |
| Erlang/OTP | Elixir runtime | ✓ | `28` | — |
| Mix | Lifecycle and release verification commands | ✓ | `1.19.5` | — |
| Node | ancillary tooling in repo workflow | ✓ | `22.14.0` | — |
| npm | CLI/doc tooling fallback | ✓ | `11.1.0` | — |
| curl | HexDocs/release reachability checks | ✓ | `8.7.1` | — |
| git | parity/release verification flows | ✓ | `2.41.0` | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: exec_command]

**Missing dependencies with fallback:**
- Context7 CLI quota is exhausted in this environment, so official HexDocs web sources were used directly instead. [VERIFIED: exec_command] [VERIFIED: web search]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView tests. [VERIFIED: codebase grep] |
| Config file | none; test setup is driven by each package `mix.exs`, `test/test_helper.exs`, and support files. [VERIFIED: codebase grep] |
| Quick run command | `cd rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/rulestead_lifecycle_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs` |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIF-05 | Root and sibling docs expose one coherent lifecycle story and preserve package boundaries | doc-contract / release-contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ |
| LIF-05 | `mix rulestead.lifecycle` stays aligned with documented lifecycle vocabulary and read-only posture | unit / contract | `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` | ✅ |
| LIF-05 | Mounted-admin public host seams match the documented operator story | integration / LiveView contract | `cd rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs` | ✅ |
| LIF-05 | Lifecycle guide and satellite link graph remain aligned | doc-contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` or new `docs_contract_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted commands above. [VERIFIED: codebase grep]
- **Per wave merge:** `cd rulestead && mix test && cd ../rulestead_admin && mix test`. [VERIFIED: codebase grep]
- **Phase gate:** full suite green plus a recorded `LIF-05` evidence artifact. [VERIFIED: repo docs]

### Wave 0 Gaps
- [ ] Add a dedicated doc-contract test file if `release_contract_test.exs` becomes too overloaded; likely `rulestead/test/rulestead/docs_contract_test.exs`. [ASSUMED]
- [ ] Add explicit assertions for lifecycle-guide discoverability across `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, and selected guide satellites. [VERIFIED: codebase grep]
- [ ] Add an artifact or verification doc entry that records the exact phase commands and pass outputs for `LIF-05`. [VERIFIED: repo docs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host authentication remains outside Rulestead docs scope, but the docs must keep that boundary explicit. [VERIFIED: repo docs] |
| V3 Session Management | yes | Preserve the documented mounted session contract: `"current_actor"`, `"rulestead_admin_environments"`, and `"rulestead_admin_last_env"`. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Keep `Rulestead.Admin.Policy.can?/4` and mounted host authorization as the stable seam in docs and tests. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Keep CLI filters bounded through `OptionParser` plus explicit allowed-atom validation. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| V6 Cryptography | no | Phase 38 does not introduce new crypto responsibilities. [VERIFIED: repo docs] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs imply `archive_candidate` is permission | Elevation of privilege | Repeat the advisory-only rule in the spine, satellites, and verification assertions. [VERIFIED: repo docs] |
| Docs or tests freeze non-public DOM/CSS internals | Tampering | Assert only public mount path, env query, session keys, and stable lifecycle vocabulary. [VERIFIED: codebase grep] |
| Mounted docs understate host-owned auth/session boundaries | Spoofing | Keep `rulestead_admin/README.md` and admin guide anchored to host-owned policy and session semantics. [VERIFIED: codebase grep] |
| CLI docs drift from actual filter/read-only behavior | Tampering | Extend `rulestead_lifecycle_test.exs` to prove documented flags and rejection paths. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Repo files via `rg`, `sed`, and direct reads:
  - `README.md`
  - `rulestead/README.md`
  - `rulestead_admin/README.md`
  - `guides/introduction/getting-started.md`
  - `guides/flows/admin-ui.md`
  - `guides/flows/explainability.md`
  - `guides/recipes/testing.md`
  - `guides/api_stability.md`
  - `rulestead/mix.exs`
  - `rulestead_admin/mix.exs`
  - `rulestead/lib/mix/tasks/rulestead.lifecycle.ex`
  - `rulestead/test/rulestead/release_contract_test.exs`
  - `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs`
  - `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs`
  - `rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs`
  - `rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs`
  - `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- Phase and project context:
  - `.planning/phases/38-lifecycle-docs-runbooks-verification/38-CONTEXT.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/ROADMAP.md`
  - `.planning/PROJECT.md`
  - `.planning/STATE.md`
  - `.planning/METHODOLOGY.md`
  - `CLAUDE.md`
  - `AGENTS.md`

### Secondary (MEDIUM confidence)
- Phoenix LiveView official docs:
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- Mix official docs:
  - https://hexdocs.pm/mix/main/Mix.Task.html
- Elixir official docs:
  - https://hexdocs.pm/elixir/OptionParser.html

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase reuses stable repo seams and official LiveView/Mix docs rather than adding new libraries. [VERIFIED: codebase grep] [VERIFIED: web search]
- Architecture: HIGH - the repo already shows the exact docs split, lifecycle CLI seam, and mounted-admin route contract that Phase 38 should extend. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - they are strongly supported by repo structure and locked context, but some are planning judgments about likely failure modes. [VERIFIED: repo docs] [ASSUMED]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22
