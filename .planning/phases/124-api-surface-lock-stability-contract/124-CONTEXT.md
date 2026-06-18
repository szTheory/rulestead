# Phase 124: API Surface Lock & Stability Contract - Context

**Gathered:** 2026-06-17 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Render the three currently-hidden public modules on HexDocs, give every contracted
public symbol a real `@doc` (specs already exist), rewrite `api_stability.md` from the
"0.1.x contract" to the "1.x contract" with a full Versioning & Deprecation Policy, and
keep `release_contract_test.exs` green throughout.

**Requirements:** API-01, API-02, API-03.

**Hard scope guards (from milestone v2.0):**
- No new runtime APIs, no schema changes, **no renames** — the public surface is locked as-is.
- Documenting an already-existing, already-callable symbol is *not* "new API" — it is the
  release-truth this milestone exists to deliver.
- This phase touches docs/specs/config + `api_stability.md` only. It does NOT do the 14-file
  version-truth sweep (that is Phase 125), HexDocs front-door theming/logo (Phase 126), or
  guides (Phase 127).
</domain>

<decisions>
## Implementation Decisions

### A. Test-guard compatibility — the one real landmine (LOCKED)
- **D-01:** Edit `release_contract_test.exs:181` in **lockstep** with the `api_stability.md`
  rewrite. That line hard-asserts the literal `v0.1.0` opening sentence; criterion 3 (rewrite to
  "1.x contract") and criterion 4 (test stays green) collide unless the asserted anchor string is
  updated to the new "1.x"-contract opening sentence in the same change.
- **D-02:** All **other** contract assertions stay green untouched — telemetry events
  (~L904-909), root exports / store callbacks / config keys (~L912-937), and facades (~L939-961)
  are content lists the rewrite preserves verbatim. Carry the symbol catalogs forward unchanged.
- **D-03:** Do **not** touch the `"0.1.x"` assertions in the README/upgrading/demo asserts
  (`release_contract_test.exs:233,249,254,262,265,285`). Those describe the *historical* `0.1.x`
  Hex release line that GA docs intentionally preserve, not the forward contract version. Only the
  `api_stability.md` self-description flips to "1.x".

### B. Edit ordering vs. the `--warnings-as-errors` / docs gate (LOCKED)
- **D-04:** Safe edit order: (1) add `@moduledoc` + per-function `@doc` to the three modules;
  (2) update `rulestead/mix.exs` `groups_for_modules` (add `Rulestead.Runtime`, remove
  `Rulestead.Runtime.Snapshot`); (3) rewrite `api_stability.md`; (4) update the test assertion;
  then run `mix docs --warnings-as-errors` + `mix dialyzer` + the contract test **last**.
- **D-05:** Ship **zero `@deprecated`** this phase. The Versioning & Deprecation Policy lands with
  an **empty deprecations-table skeleton** plus a *worked* (documentation-only) soft-deprecation
  example. This deliberately dodges the locked `@deprecated` + `mix compile --warnings-as-errors`
  footgun (`scripts/ci/lint.sh:31-37`) — soft-deprecation is docs-only.
- **D-06:** The only live release-gate risk is **broken autolinks** in new `@doc`/`@moduledoc`
  bodies tripping `mix docs --warnings-as-errors` (the undefined-reference gate, criterion 2).
  Keep all `` `Module.fun/arity` `` cross-links pointed at already-public, now-rendered symbols.
  `mix.exs:147` `skip_undefined_reference_warnings_on` / `skip_code_autolink_to` already absorbs
  most internal-link risk.

### C. Work inventory is `@doc`-only, not `@spec` (LOCKED)
- **D-07:** Every public symbol in the three target modules **already carries a `@spec`/`@callback`**.
  `mix dialyzer` is therefore already satisfied on the public surface — **no new spec authoring**.
  The work is: 3 × `@moduledoc` flips (from `@moduledoc false`) + `@doc` on:
  - `Rulestead.Context`: `new/1`, `normalize/1`
  - `Rulestead.Runtime`: `evaluate/3`, `enabled?/3`, `get_value/4`, `get_variant/3`, `explain/3`, `diagnostics/1`
  - `Rulestead.Admin.Policy`: the 3 callbacks `can?/4`, `change_request_required?/4`, `allow_self_approval?/4`
- **D-08:** `@moduledoc` content style — 2-4 sentence intent paragraphs matching the contract's
  framing: Runtime = "supported keyed lookup facade for Phoenix apps using the snapshot cache";
  Context = "canonical runtime evaluation context + construction/normalization"; Admin.Policy =
  "host-owned authorization behaviour seam — hosts own auth." Use the planned moduledoc content in
  `.planning/research/HEXDOCS.md` as the source where it covers these modules.
- **D-09:** Criterion 5 is two coupled `mix.exs` edits: **add** `Rulestead.Runtime` to
  `groups_for_modules`, and **remove** `Rulestead.Runtime.Snapshot` from the "Extensibility" group
  (it is `@moduledoc false` and contractually non-public — leaving it is a dead/contradictory
  entry). `diagnostics/1` needs no change — `def diagnostics(opts \\ [])` satisfies the contract's
  `diagnostics/1` and the test's name-only match.

### D. Accidental public surface — `Rulestead.Admin.Policy.*_actions/0` → **PROMOTE** (LOCKED, researched)
- **D-10:** Promote the four read-only helpers — `governance_actions/0`, `viewer_actions/0`,
  `editor_actions/0`, `admin_actions/0` — into the public 1.x contract: add real `@doc` strings and
  list them in `api_stability.md` under the `Rulestead.Admin.Policy` entry as a **distinct
  "role-vocabulary / introspection helpers (read-only catalogs)" sub-group**, kept visually
  separate from the three decision callbacks so the *decision* seam stays "intentionally small."
- **D-11 (rationale — do not re-litigate):** Two parallel research agents resolved this. The
  ecosystem agent's default was `@doc false` (SemVer asymmetry: hide-now/expand-later is the
  cheap-reversible 1.0 move) **but it explicitly said: if concrete evidence shows hosts already
  depend on these presets, jump straight to promote; never leave them rendered-but-uncontracted.**
  That evidence exists:
  1. The **only** shipped `@behaviour Rulestead.Admin.Policy` implementation in the repo (the demo
     policy, `examples/demo/backend/lib/rulestead_demo/admin_policy.ex:8,10,36`) builds its role
     buckets directly from these four helpers — a host without them hand-copies ~37 action atoms
     and drifts against the library's vocabulary.
  2. The v2.0 milestone's **own** research plan (`.planning/research/HEXDOCS.md:336-367`) already
     documents them: the planned `@moduledoc` names them "introspectable" and shows a host calling
     `viewer_actions/0` inside `can?/4`, and says "Add `@doc` strings to `governance_actions/0` etc."
  3. They expose the **canonical RBAC vocabulary already frozen as 1.0 GA surface** (SEC-01..03,
     shipped v1.0.0) — freezing the introspection helpers adds zero new instability.
  4. `@doc false` (Option 1) would force a rewrite of the planned moduledoc and risk the ExDoc
     undefined-reference release gate (a moduledoc autolinking hidden funcs warns).
  5. "Rendered-but-uncontracted" (Option 3) is forbidden by
     `prompts/rulestead-engineering-dna-from-prior-libs.md:51` — "no ambiguous middle state."
- **D-12:** This promotion is **not** "new public API" (which the milestone forbids) — the functions
  already exist and are already depended upon; listing them is the release-truth the milestone
  delivers. `release_contract_test.exs` currently locks only the 3 callbacks; promoting the helpers
  means **adding their entries to both `api_stability.md` and the contract test's Admin.Policy
  assertion** so the bidirectional guard covers the now-contracted surface (coordinate with D-01).

### Claude's Discretion
- Exact prose of `@moduledoc`/`@doc` bodies (anchor to `.planning/research/HEXDOCS.md` where it
  covers a module; match the contract's framing otherwise).
- Exact section structure of the Versioning & Deprecation Policy (breaking-change table, telemetry
  stability rules, worked soft-deprecation example, empty deprecations skeleton) — structure per
  `prompts/rulestead-engineering-dna-from-prior-libs.md:150`; soft-deprecation worked example must
  avoid real `@deprecated` (D-05).

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `guides/api_stability.md` — the live public contract (the `rulestead/doc/api_stability.md` copy
  is generated; `mix.exs` and `release_contract_test.exs` both point at `guides/`). Rewrite target.
- `rulestead/test/rulestead/release_contract_test.exs` — bidirectional `api_stability.md` ↔ code
  guard; line 181 is the version-string assertion (D-01); ~L904-961 are the symbol catalogs (D-02);
  the Admin.Policy assertion must gain the four promoted helpers (D-12).
- `rulestead/mix.exs` — `docs()` (~L86-158), `groups_for_modules` (~L124-141, `Snapshot` at ~L137),
  `skip_undefined_reference_warnings_on`/`skip_code_autolink_to` (~L147), `dialyzer()` (~L159).
- `rulestead/lib/rulestead/context.ex` — `@moduledoc false`; `new/1`, `normalize/1` (specs present).
- `rulestead/lib/rulestead/runtime.ex` — `@moduledoc false`; 6 public funs (specs present).
- `rulestead/lib/rulestead/admin/policy.ex` — `@moduledoc false`; 3 callbacks + 4 `*_actions/0`
  helpers (~L109-140).
- `rulestead/lib/rulestead/runtime/snapshot.ex` — `@moduledoc false`; remove from the mix.exs group.
- `scripts/ci/lint.sh:31-37` — the release gate: `mix compile --warnings-as-errors`,
  `mix docs --warnings-as-errors`, `mix dialyzer`.
- `.planning/research/HEXDOCS.md` — v2.0 HexDocs research; planned `@moduledoc` content incl. the
  Admin.Policy introspection-helper framing (~L336-367).
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — public-surface philosophy (L51 "no
  ambiguous middle state"; L150 api_stability.md structure: list `@doc`-annotated arities + deviations).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- All public symbols in the three target modules **already have `@spec`/`@callback`** — only `@doc`
  + `@moduledoc` and the api_stability.md rewrite remain. Dialyzer is already wired (`lint.sh:37`).
- `mix.exs:147` already declares `skip_undefined_reference_warnings_on` / `skip_code_autolink_to`
  for `Rulestead.*` + `lib/` refs, absorbing most autolink risk for the new docs.
- The canonical RBAC vocabulary (the `*_actions/0` catalogs) is already a shipped, frozen GA
  contract (SEC-01..03) — promoting its introspection helpers is low-risk.

### Established Patterns
- `release_contract_test.exs` is a bidirectional guard: it asserts a literal opening sentence (L181)
  plus name-keyed symbol catalogs. Edits to `api_stability.md` must keep both sides in sync.
- Module-level docs are binary in this repo: full `@moduledoc` (public) or `@moduledoc false`
  (internal) — "no ambiguous middle state" (engineering DNA). This forbids Option 3 for the helpers.
- `@doc false` keeps a function callable but unpromised; the repo scopes the stability contract to
  the documented surface (standard Elixir idiom).

### Integration Points
- Internal callers of the `*_actions/0` helpers (must keep working): `admin/authorizer.ex:12,159,162,168-169`
  and `lib/rulestead.ex:1907`. Promotion does not change behavior — only documentation/contract status.
- The demo policy (`examples/demo/backend/lib/rulestead_demo/admin_policy.ex`) is the host-facing
  consumer pattern the promoted docs should reflect.
</code_context>

<specifics>
## Specific Ideas

- Frame the four promoted helpers in `api_stability.md` as a **read-only "role vocabulary /
  introspection helpers" sub-group** under the Admin.Policy entry, explicitly distinct from the
  three authorization **decision callbacks** — so the contract can still truthfully call the
  decision seam "intentionally small."
- The deprecation-policy **worked example** must be a soft (docs-only) deprecation — never a real
  `@deprecated` attribute — to stay green under `mix compile --warnings-as-errors`.
</specifics>

<deferred>
## Deferred Ideas

- Hard `@deprecated` attributes and any actual deprecations — out of scope; the deprecations table
  ships as an empty skeleton this phase (D-05). First real deprecation follows the documented policy
  in a future minor.
- The 14-file version-truth sweep, CI drift guard, `upgrading.md`, `MAINTAINING.md` major-bump
  runbook — Phase 125.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
