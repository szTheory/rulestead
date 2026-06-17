# Phase 124: API Surface Lock & Stability Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-17
**Phase:** 124-api-surface-lock-stability-contract
**Mode:** assumptions
**Areas analyzed:** Test-guard compatibility, Edit ordering vs. release gate, @doc/@spec inventory, Accidental public surface (Admin.Policy helpers)

## Methodology Lenses Applied

- **Recommendation-First** + **Research-Then-Recommend**: technical/mechanical phase → decisive
  single recommendations; the genuine cross-cutting decision (Policy helpers) was researched then
  resolved one-shot per the user's `research-then-decide` preference.
- **Architect-Default Discuss**: does NOT apply — no architectural fork; the *what* is locked by
  the milestone.

## Assumptions Presented

### A. Test-guard compatibility
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Edit `release_contract_test.exs:181` version-string assertion in lockstep with the api_stability.md rewrite | Confident | `release_contract_test.exs:181` hard-asserts the literal v0.1.0 opening line; criteria 3+4 collide otherwise |
| Other contract asserts (telemetry/exports/callbacks/facades, ~L904-961) preserved verbatim | Confident | Content lists unchanged by rewrite |
| Leave README/upgrading/demo `0.1.x` asserts untouched (L233-285) | Likely | Describe historical 0.1.x Hex line, not forward contract version |

### B. Edit ordering vs. `--warnings-as-errors` / docs gate
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Order: docs → mix.exs groups → api_stability.md → test assertion → run gates last | Confident | `scripts/ci/lint.sh:31-37` order |
| Zero `@deprecated` this phase; deprecations table is empty skeleton + docs-only worked example | Confident | Locked footgun: `@deprecated` + `mix compile --warnings-as-errors` breaks CI |
| Only live risk is broken autolinks in new `@doc` bodies (undefined-reference gate) | Confident | `mix.exs:147` skip lists absorb most internal-link risk |

### C. @doc/@spec inventory
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Work is `@doc`-only (+ 3 `@moduledoc` flips); every public symbol already has `@spec`/`@callback` | Confident | `context.ex:28,47`, `runtime.ex` 6 funs, `policy.ex` callbacks all specced; `mix dialyzer` already satisfied |
| Add `Rulestead.Runtime` to groups_for_modules, remove `Rulestead.Runtime.Snapshot` | Confident | `mix.exs:137` lists `@moduledoc false` Snapshot; Runtime absent; criterion 5 |

### D. Accidental public surface — `Rulestead.Admin.Policy.*_actions/0` (the one escalated decision)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Four `*_actions/0` helpers are public `def`s NOT in the contract; need a 1.0 decision | Confident (existence) | `policy.ex:110,113,116,119`; `api_stability.md:283-291` lists only 3 callbacks |

## Corrections Made

### D. Accidental public surface — RESOLVED VIA RESEARCH (not a correction, a delegated decision)
- **What Claude initially offered:** `@doc false` (hide) as the recommended option in the
  escalation question.
- **User instruction:** Do not pick for me — research pros/cons/tradeoffs/idiom/ecosystem-lessons/
  prompts-anchors via subagents and one-shot the best coherent recommendation.
- **Resolution:** Two parallel research agents.
  - *Ecosystem agent* defaulted to `@doc false` on SemVer-asymmetry grounds, **but stated: if
    concrete evidence shows hosts already depend on the presets, jump straight to PROMOTE; never
    leave rendered-but-uncontracted.**
  - *Codebase agent* found that exact evidence: the only shipped `@behaviour Rulestead.Admin.Policy`
    impl (demo policy) composes its buckets from all four helpers; the v2.0 research plan
    (`HEXDOCS.md:336-367`) already documents them and shows the host `can?/4` usage pattern; the
    helpers expose GA-frozen RBAC vocabulary (SEC-01..03); engineering-DNA L51 forbids Option 3.
- **Final decision:** **PROMOTE** the four helpers into the 1.x contract (real `@doc` + listed in
  `api_stability.md` under a read-only "role-vocabulary / introspection helpers" sub-group, distinct
  from the decision callbacks), and extend the contract test's Admin.Policy assertion accordingly.
  This is release-truth, not new API.

### A/B/C
- Locked as presented (user: "Yes, lock all three").

## External Research

- **Elixir/ecosystem idiom (web + knowledge):** `@doc false` = callable-but-unpromised; stability
  contracts scope to documented surface; Plug/Phoenix/Oban `@doc false` generated/internal machinery;
  Oban demonstrates deliberate *additive* promotion (`@doc since:`); FunWithFlags keeps a lean
  surface. SemVer asymmetry: expanding API later is a minor bump, removing is a major — bias to
  minimal-lock-and-expand UNLESS concrete demand exists.
  Sources: Elixir Writing Documentation + Library Guidelines, Plug.Builder, Oban.Worker HexDocs.
- **In-repo evidence (codebase agent):** demo policy at
  `examples/demo/backend/lib/rulestead_demo/admin_policy.ex:8,10,36`; planned moduledoc in
  `.planning/research/HEXDOCS.md:336-367`; internal callers `admin/authorizer.ex:12,159,162,168-169`,
  `lib/rulestead.ex:1907`; api_stability.md philosophy L9-18, L283-291, L457; engineering-DNA
  `prompts/rulestead-engineering-dna-from-prior-libs.md:51,150`.
- **Net:** the demand signal the ecosystem agent named as the flip condition is present → PROMOTE.
